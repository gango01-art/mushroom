-- LC physical Duel session (BRIEF_HEROES 4). Owns the throne state and the champion unit and
-- drives core/heroes/lc_duel with game time. Every ending goes through M.finish (one cleanup
-- path): victory, champion_death, timeout, leash_break, target_lost, owner_disconnect,
-- owner_removed, match_finished.
local Duel = require("rift.core.heroes.lc_duel")
local Config = require("rift.core.config")
local B = require("rift.data.hero_balance").lc.duel_physical
local Mods = require("rift.engine.mods")
local Log = require("rift.engine.log")

local M = {}
M.owners = M.owners or {}     -- pid -> persistent owner state (earned permanent damage, pair history)
M.sessions = M.sessions or {} -- pid -> live session

local function gm() return GameRules.RiftArena end

function M.owner_state(pid)
  M.owners[pid] = M.owners[pid] or Duel.new_owner_state()
  return M.owners[pid]
end

function M.by_champion(unit)
  for _, s in pairs(M.sessions) do if s.champion == unit then return s end end
  return nil
end

-- Permanent damage on the hero follows the owner state (kept across death/respawn).
function M.sync_damage(pid, hero)
  hero = hero or PlayerResource:GetSelectedHeroEntity(pid)
  if not hero or hero:IsNull() then return end
  local stacks = math.floor(M.owner_state(pid).earned * 10 + 1e-6)
  if stacks <= 0 then return end
  local m = hero:FindModifierByName("modifier_rift_lc_duel_damage")
    or Mods.add(hero, hero, nil, "modifier_rift_lc_duel_damage", {})
  if m and m:GetStackCount() ~= stacks then m:SetStackCount(stacks) end
end

local function spawn_champion(owner, target)
  local pos = owner:GetAbsOrigin() + owner:GetForwardVector() * 120
  local u = CreateUnitByName(B.champion_unit, pos, true, owner, owner, owner:GetTeamNumber())
  if not u then return nil end
  u:SetOwner(owner)  -- damage and kills are credited to the LC player
  -- Snapshot: damage, armor, max HP (same HP percent), 90% of effective attacks per second.
  local dmg = owner:GetAverageTrueAttackDamage(nil)
  u:SetBaseDamageMin(dmg); u:SetBaseDamageMax(dmg)
  u:SetPhysicalArmorBaseValue(owner:GetPhysicalArmorValue(false))
  local max_hp = owner:GetMaxHealth()
  u:SetBaseMaxHealth(max_hp); u:SetMaxHealth(max_hp)
  u:SetHealth(math.max(1, max_hp * owner:GetHealth() / math.max(1, max_hp)))
  local aps = owner:GetAttacksPerSecond(false) * B.champion_attack_speed_factor
  if aps > 0 then u:SetBaseAttackTime(1 / aps) end
  u:SetBaseMoveSpeed(owner:GetIdealSpeed())
  u:SetIdleAcquire(false)
  Mods.add(u, owner, nil, "modifier_rift_lc_champion", {})
  Log.info("LC", string.format("champion snapshot dmg=%.0f armor=%.1f hp=%d/%d aps=%.2f", dmg,
    owner:GetPhysicalArmorValue(false), u:GetHealth(), max_hp, aps))
  return u
end

function M.start(owner, ability, target, rank)
  local pid = owner:GetPlayerOwnerID()
  if M.sessions[pid] then return false end
  local g = gm()
  local now = GameRules:GetGameTime()
  -- The carried event relic is dropped before invulnerability (mode rule).
  if g and g.relic then g.relic:ForceDrop(pid, owner:GetAbsOrigin(), g:Now(), "lc_throne") end
  local champion = spawn_champion(owner, target)
  if not champion then Log.error("LC", "champion unit missing: " .. B.champion_unit); return false end
  local state = M.owner_state(pid)
  local target_key = target:GetPlayerOwnerID()
  local enabled = not (g and g.scoring and g.scoring.anti_feed_enabled == false)
  local mult = Duel.pair_multiplier(state, target_key, now, Config.anti_feed, enabled)
  local s = { pid = pid, owner = owner, target = target, champion = champion, ability = ability,
              throne = owner:GetAbsOrigin(), duel = Duel.start(B, rank, state, target_key, now, mult) }
  M.sessions[pid] = s
  owner:Stop()
  Mods.add(owner, owner, ability, "modifier_rift_lc_throne", { duration = B.max_seconds + 2 })
  Log.info("LC", string.format("duel start pid=%d target=%d rank=%d mult=%.2f", pid, target_key, rank, mult))
  champion:SetContextThink("rift_lc_duel", function() return M.step(s) end, 0)
  return true
end

local function abort_reason(s)
  local g = gm()
  if s.owner:IsNull() then return "owner_removed" end
  if g and g.director and g.director.state:is("FINISHED") then return "match_finished" end
  if PlayerResource:GetConnectionState(s.pid) ~= DOTA_CONNECTION_STATE_CONNECTED
     and not (IsInToolsMode and IsInToolsMode()) then return "owner_disconnect" end
  if not s.owner:IsAlive() then return "owner_removed" end
  return nil
end

-- One session step. Returns the next think delay or nil when the session is over.
function M.step(s)
  if s.done then return nil end
  local now = GameRules:GetGameTime()
  local why = abort_reason(s)
  if why then M.finish(s, s.duel:abort(why)); return nil end
  local champion_dead = s.champion:IsNull() or not s.champion:IsAlive()
  local target_gone = s.target:IsNull()
  local target_dead = target_gone or not s.target:IsAlive()
  if champion_dead or target_dead then
    M.finish(s, s.duel:resolve_deaths(champion_dead, target_dead, target_gone and 0 or s.target:GetMaxHealth()))
    return nil
  end
  local dist = (s.target:GetAbsOrigin() - s.throne):Length2D()
  local out = s.duel:tick(now, dist)
  if out and out.payout and out.payout > 0 and not out.ended then M.sync_damage(s.pid, s.owner) end
  if out and out.ended then M.finish(s, out); return nil end
  -- The champion chases and attacks only the chosen target.
  if s.champion:GetAttackTarget() ~= s.target then s.champion:MoveToTargetToAttack(s.target) end
  return B.think_interval
end

-- The single cleanup path.
function M.finish(s, result)
  if s.done then return end
  s.done = true
  M.sessions[s.pid] = nil
  result = result or {}  -- already ended in core (double end): cleanup only
  local owner = s.owner
  if not s.champion:IsNull() then
    -- Expiry is not a kill: the unit is removed, no bounty, no death event for scoring.
    if s.champion:IsAlive() then UTIL_Remove(s.champion) end
  end
  if owner and not owner:IsNull() then
    owner:RemoveModifierByName("modifier_rift_lc_throne")
    M.sync_damage(s.pid, owner)
    if result.penalty and owner:IsAlive() then
      -- Real champion death only: 30% max HP pure damage credited to the champion's killer, then stun.
      local killer = s.champion_killer
      if not killer or killer:IsNull() then killer = owner end
      ApplyDamage({ victim = owner, attacker = killer, damage = owner:GetMaxHealth() * result.penalty.max_hp_fraction,
        damage_type = DAMAGE_TYPE_PURE, ability = s.ability,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION
          + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS })
      if owner:IsAlive() then owner:AddNewModifier(killer, nil, "modifier_stunned", { duration = result.penalty.stun }) end
    end
  end
  Log.info("LC", string.format("duel end pid=%d reason=%s session_paid=%.1f earned=%.1f", s.pid, tostring(result.reason),
    result.session_paid or 0, M.owner_state(s.pid).earned))
end

return M

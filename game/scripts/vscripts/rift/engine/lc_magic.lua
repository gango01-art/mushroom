-- LC magical direction, server state: earned spell amp points per player (survive death,
-- independent of modifiers) and live statue sessions. Rules: core/heroes/lc_magic.
local Magic = require("rift.core.heroes.lc_magic")
local B = require("rift.data.hero_balance").lc
local Mods = require("rift.engine.mods")
local Log = require("rift.engine.log")
local Cross = require("rift.core.cross_beam")

local M = {}
M.owners = M.owners or {}    -- pid -> owner state (earned points)
M.statues = M.statues or {}  -- pid -> live statue { unit, session, ability, shot }
M.by_id = M.by_id or {}      -- statue session id -> record (kept until its arrows land)
M.DIRECTION = "lc_duel_magical"
M.ULT = "lc_duel_magical"

function M.owner_state(pid)
  M.owners[pid] = M.owners[pid] or Magic.new_owner_state()
  return M.owners[pid]
end

-- Current spell amp percent of this hero (0 without the direction, at rank 0 or under Break).
function M.spell_amp(hero)
  local pid = hero:GetPlayerOwnerID()
  local ult = hero:FindAbilityByName(M.ULT)
  local rank = ult and ult:GetLevel() or 0
  return Magic.spell_amp(M.owner_state(pid), B.duel_magical, rank, hero:PassivesDisabled())
end

-- Called by the game mode after scoring resolved a real hero death (result r).
-- Only players on the LC magical direction earn points; anti-feed multiplier applies.
function M.on_hero_death(gm, r, token)
  local function credit(pid, kind, mult)
    if pid == nil or gm.upgrades:DirectionId(pid) ~= M.DIRECTION then return end
    local add = Magic.credit(M.owner_state(pid), B.duel_magical, kind, token .. ":" .. pid, mult)
    Log.info("LC", string.format("spell amp +%.2f pid=%d (%s) earned=%.2f", add, pid, kind, M.owner_state(pid).earned))
  end
  credit(r.killer, "kill", r.multiplier or 1)
  for _, a in ipairs(r.assists or {}) do credit(a.pid, "assist", r.multiplier or 1) end
end

---------------------------------------------------------------------------
-- Statue
---------------------------------------------------------------------------
local function remove_statue(rec)
  if rec.unit and not rec.unit:IsNull() then UTIL_Remove(rec.unit) end
  rec.session.alive = false
  if not next(rec.inflight) then M.by_id[rec.session.id]=nil end
end

function M.cleanup(now)
  for id,rec in pairs(M.by_id) do
    if now>rec.deadline or rec.owner:IsNull() or rec.ability:IsNull() then M.by_id[id]=nil end
  end
end

local function pick_target(rec)
  local u = rec.unit
  local found = FindUnitsInRadius(u:GetTeamNumber(), u:GetAbsOrigin(), nil, B.statue.attack_range,
    DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
      + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
  for _, e in ipairs(found) do
    if e:IsRealHero() and not e:IsInvulnerable() then return e end
  end
  return nil
end

local function step(rec)
  local u, owner = rec.unit, rec.owner
  if u:IsNull() or not u:IsAlive() then
    remove_statue(rec)
    if M.statues[rec.pid]==rec then M.statues[rec.pid]=nil end
    return nil
  end
  local now = GameRules:GetGameTime()
  if rec.session:expired(now) or owner:IsNull() or not owner:IsAlive() or rec.ability:IsNull() then
    remove_statue(rec); if M.statues[rec.pid]==rec then M.statues[rec.pid]=nil end
    return nil
  end
  for _, shot in ipairs(rec.session:due_shots(now)) do
    local target = pick_target(rec)
    local origin=u:GetAbsOrigin()
    local aim=target and (target:GetAbsOrigin()-origin) or owner:GetForwardVector()
    local rays=Cross.directions(aim)
    rec.inflight[shot]={}
    for ray,dir in ipairs(rays) do
      rec.inflight[shot][ray]=true
      local finish=origin+Vector(dir.x,dir.y,0)*B.statue.beam_range
      local width=require("rift.engine.area").radius(rec.owner,B.statue.beam_half_width)
      ProjectileManager:CreateLinearProjectile({
        Ability=rec.ability,Source=u,EffectName=B.statue.arrow_particle,
        vSpawnOrigin=origin+Vector(0,0,64),fDistance=B.statue.beam_range,
        fStartRadius=width,fEndRadius=width,
        vVelocity=Vector(dir.x,dir.y,0)*B.statue.arrow_speed,
        fExpireTime=now+B.statue.beam_range/B.statue.arrow_speed+0.5,
        bDeleteOnHit=false,bHasFrontalCone=false,bReplaceExisting=false,bProvidesVision=false,
        iUnitTargetTeam=DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType=DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags=DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        ExtraData={sid=rec.session.id,shot=shot,ray=ray},
      })
    end
    EmitSoundOn(B.statue.shot_sound,u)
    Log.debug("LC",string.format("statue salvo %d rays=4 aim=%s",shot,target and target:GetUnitName() or "forward"))
  end
  return 0.1
end

function M.summon(owner, ability, pos, level)
  M.cleanup(GameRules:GetGameTime())
  local pid = owner:GetPlayerOwnerID()
  local old = M.statues[pid]
  if old then remove_statue(old); M.statues[pid] = nil end  -- one live statue; replaced silently
  local u = CreateUnitByName(B.statue.unit, pos, true, owner, owner, owner:GetTeamNumber())
  if not u then Log.error("LC", "statue unit missing: " .. B.statue.unit); return false end
  u:SetOwner(owner)
  local session = Magic.Statue.new(B.statue, level, GameRules:GetGameTime())
  local hp = session:health()
  u:SetBaseMaxHealth(hp); u:SetMaxHealth(hp); u:SetHealth(hp)
  u:SetPhysicalArmorBaseValue(B.statue.armor)
  u:SetBaseMagicalResistanceValue(B.statue.magic_resistance)
  u:SetRenderColor(255, 255, 255) -- native stone-remnant materials already supply the stone appearance
  u:SetForwardVector(owner:GetForwardVector())
  Mods.add(u, owner, ability, "modifier_rift_lc_statue", { duration = B.statue.lifetime + 1 })
  local rec = { pid = pid, owner = owner, unit = u, session = session, ability = ability,
    inflight={},deadline=GameRules:GetGameTime()+B.statue.lifetime+B.statue.projectile_context_seconds }
  M.statues[pid] = rec
  M.by_id[session.id] = rec
  u:SetContextThink("rift_lc_statue", function() return step(rec) end, 0)
  Log.info("LC", string.format("statue summoned pid=%d level=%d hp=%d", pid, level, hp))
  return true
end

-- A salvo pierces all enemies in four directions. Each real enemy hero hit
-- grants 2 s CDR (owner request); overlapping rays still hit a victim once per salvo.
function M.on_beam_hit(ability, target, data)
  M.cleanup(GameRules:GetGameTime())
  if not data then return false end
  local rec = M.by_id[tonumber(data.sid) or -1]
  if not rec or rec.owner:IsNull() then return false end
  local shot=tonumber(data.shot) or -1
  local ray=tonumber(data.ray) or -1
  local live=rec.inflight[shot]
  if not live or not live[ray] then return false end
  if not target then
    live[ray]=nil
    if not next(live) then rec.inflight[shot]=nil end
    if not rec.session.alive and not next(rec.inflight) then M.by_id[rec.session.id]=nil end
    return false
  end
  if target:IsNull() or not target:IsAlive() or target:IsInvulnerable() then return false end
  local owner = rec.owner
  if target:GetTeamNumber()==owner:GetTeamNumber() then return false end
  local gm=GameRules.RiftArena
  if gm and gm.director and gm.director.state:is("FINISHED") then return false end
  local key=gm and gm.ids and gm.ids:victim_key(target:entindex()) or tostring(target:entindex())
  if not rec.session:claim_damage(shot,key) then return false end
  if not target:IsMagicImmune() and not target:IsDebuffImmune() then
    -- Spell damage of the owner: her spell amp applies once; not an attack, no item on-hit.
    local bonus = require("rift.engine.build_bonus").get(owner, "statue_arrow_bonus")
    ApplyDamage({ victim = target, attacker = owner, damage = rec.session:arrow_damage() + bonus,
      damage_type = DAMAGE_TYPE_MAGICAL, ability = ability })
  end
  local real = target:IsRealHero() and not target:IsIllusion()
  local cdr = rec.session:on_arrow_hit(tostring(shot)..":"..key, real)
  if cdr > 0 and not ability:IsNull() then
    local left = Magic.reduce_cooldown(ability:GetCooldownTimeRemaining(), cdr)
    ability:EndCooldown()
    if left > 0 then ability:StartCooldown(left) end
  end
  Log.debug("LC", string.format("statue arrow hit shot=%s cdr=%d total_cdr=%d", tostring(data.shot), cdr, rec.session.total_cdr))
  return false
end

return M

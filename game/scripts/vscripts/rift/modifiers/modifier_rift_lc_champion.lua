-- LC physical Duel champion: reports its landed hits on the duel target and its killer
-- to the session; 90% attack rate is already in the snapshotted base attack time.
modifier_rift_lc_champion = modifier_rift_lc_champion or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_champion:IsHidden() return false end
function modifier_rift_lc_champion:IsPurgable() return false end
function modifier_rift_lc_champion:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_champion:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_DEATH }
end
local function session(self)
  return require("rift.engine.lc_duel_session").by_champion(self:GetParent())
end
function modifier_rift_lc_champion:OnAttackLanded(params)
  if not IsServer() or params.attacker ~= self:GetParent() then return end
  local s = session(self)
  if s and params.target == s.target then s.duel:record_champion_hit(GameRules:GetGameTime(), params.damage or 0) end
end
function modifier_rift_lc_champion:OnDeath(params)
  if not IsServer() or params.unit ~= self:GetParent() then return end
  local s = session(self)
  if s then s.champion_killer = params.attacker end
end

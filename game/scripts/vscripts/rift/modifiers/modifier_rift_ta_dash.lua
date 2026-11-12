-- TA magical W dash (horizontal motion). Ends early on stun/root/blocked path:
-- interrupted dash creates no wave. Partial movement is kept (documented).
local B = require("rift.data.hero_balance").ta.waves_magical
modifier_rift_ta_dash = modifier_rift_ta_dash or ((type(class) == "function") and class({}) or {})
function modifier_rift_ta_dash:IsHidden() return true end
function modifier_rift_ta_dash:IsPurgable() return false end
function modifier_rift_ta_dash:OnCreated(kv)
  if not IsServer() then return end
  self.dir = Vector(kv.dx or 1, kv.dy or 0, 0)
  self.left = kv.distance or 300
  self.speed = self.left / math.max(0.05, self:GetDuration() - 0.05)
  self.done = false
  if not self:ApplyHorizontalMotionController() then self.interrupted = true; self:Destroy() end
end
function modifier_rift_ta_dash:UpdateHorizontalMotion(me, dt)
  if me:IsStunned() or me:IsRooted() or me:IsHexed() then self.interrupted = true; self:Destroy(); return end
  local step = math.min(self.left, self.speed * dt)
  local next = me:GetAbsOrigin() + self.dir * step
  if GridNav and GridNav.IsTraversable and not GridNav:IsTraversable(next) then
    self.interrupted = true; self:Destroy(); return
  end
  me:SetAbsOrigin(next)
  self.left = self.left - step
  if self.left <= 0.5 then self.done = true; self:Destroy() end
end
function modifier_rift_ta_dash:OnHorizontalMotionInterrupted() self.interrupted = true; self:Destroy() end
function modifier_rift_ta_dash:CheckState() return { [MODIFIER_STATE_COMMAND_RESTRICTED] = true } end
function modifier_rift_ta_dash:OnDestroy()
  if not IsServer() then return end
  local me = self:GetParent()
  me:RemoveHorizontalMotionController(self)
  FindClearSpaceForUnit(me, me:GetAbsOrigin(), false)
  if self.done and not self.interrupted and self:GetAbility() then
    require("rift.engine.ta_waves").fire(me, self:GetAbility(), me:GetAbsOrigin(), self.dir, B.w_base)
  end
end

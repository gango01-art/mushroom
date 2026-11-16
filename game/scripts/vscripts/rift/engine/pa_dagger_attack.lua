-- Per-target attack bonus is evaluated for the real attack itself, unlike a
-- temporary generic stat modifier (whose cached damage failed in OP-023).
local M={}
function M.current(caster)
  local s=M.active
  return s and s.caster==caster and s or nil
end
function M.perform(caster,target,base,factor)
  local attack=caster:GetAverageTrueAttackDamage(target)
  local previous=M.active
  local s={caster=caster,target=target,bonus=base+attack*(factor-1),landed=false}
  M.active=s
  -- Dagger is a spell-delivered attack: terrain uphill miss must not apply.
  local ok,err=pcall(caster.PerformAttack,caster,target,true,true,true,true,false,false,true)
  M.active=previous
  if not ok then require("rift.engine.log").error("PA","dagger attack: "..tostring(err)) end
  -- Never-miss spell attacks may dispatch OnAttackLanded after PerformAttack
  -- returns. Count a successfully issued attack unless the target is attack-immune.
  return ok and (s.landed or not target:IsAttackImmune())
end
return M

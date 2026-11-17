-- Damage-free meditation; movement and attack orders never enter this state.
local M={}
function M.values(cfg,level,now,last_damage)
 local ranks=math.max(0,level-1)
 local elapsed=math.max(0,now-last_damage-cfg.delay)
 local ramp=math.max(cfg.min_ramp,cfg.ramp+cfg.ramp_per_level*ranks)
 local fraction=math.min(1,elapsed/ramp)
 return fraction,(cfg.health_regen+cfg.health_per_level*ranks)*fraction,
  (cfg.mana_regen+cfg.mana_per_level*ranks)*fraction
end
function M.interrupt(damage)return type(damage)=="number"and damage>0 end
return M

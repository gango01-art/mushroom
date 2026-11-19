-- Pure talent/item resolution. Native ability levels and inventory flags are
-- supplied by the engine adapter. Never mutate shared balance tables.
local M={}
function M.can_learn(cfg,level,tier,opposite)
 if level<cfg.levels[tier]then return false end
 return not opposite or level>=cfg.opposite_levels[tier]
end
function M.total(def,learned,scepter,shard)
 local out={}
 local function add(values)for k,v in pairs(values or {})do out[k]=(out[k]or 0)+v end end
 for i,t in ipairs(def.talents)do if learned[i]then add(t)end end
 if scepter then add(def.scepter)end
 if shard then add(def.shard)end
 return out
end
function M.cooldown(base,bonus,cfg,flat)
 -- Build upgrades and branch talents/items share one budget, measured against
 -- the ORIGINAL cooldown. Native inventory CDR is applied by Dota afterwards.
 local pct=math.min(cfg.cooldown_cap_pct,math.max(0,bonus.ult_cooldown_pct or 0))/100
 return math.max(1,base*(1-cfg.cooldown_cap_pct/100),(base-math.max(0,flat or 0))*(1-pct))
end
function M.radius(base,bonus,cfg)
 return base+math.min(base*cfg.radius_cap_fraction,math.max(0,bonus.ult_radius or 0))
end
function M.profile(base,bonus,cfg)
 local out={};for k,v in pairs(base)do
  if type(v)=="table"then out[k]={};for i,x in pairs(v)do out[k][i]=x end else out[k]=v end
 end
 local scale=1+(bonus.ult_damage_pct or 0)/100
 for _,key in ipairs({"damage","attack","strength","agility","intellect","attack_speed_damage","mana_regen_damage"})do
  if type(out[key])=="table"then for i,v in ipairs(out[key])do out[key][i]=v*scale end
  elseif out[key]then out[key]=out[key]*scale end
 end
 if out.radius then out.radius=M.radius(out.radius,bonus,cfg)end
 if out.range and out.range>0 then out.range=out.range+(bonus.ult_cast_range or 0)end
 if out.ticks then out.ticks=out.ticks+math.min(2,math.max(0,bonus.ult_ticks or 0))end
 if type(out.duration)=="table"then for i,v in ipairs(out.duration)do out.duration[i]=v+(bonus.ult_duration or 0)end
 elseif out.duration then out.duration=out.duration+(bonus.ult_duration or 0)end
 if out.pull_distance then out.pull_distance=out.pull_distance+(bonus.pull_distance or 0)end
 return out
end
return M

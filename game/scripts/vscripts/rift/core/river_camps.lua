local M={}
function M.scale(cfg,elapsed)
 for _,p in ipairs(cfg.phases)do if elapsed<p.until_seconds then return p.scale end end
 return cfg.phases[#cfg.phases].scale
end
function M.ready(camp,now,elapsed,cfg)
 return elapsed>=cfg.first_spawn and (camp.remaining or 0)==0 and (not camp.ready_at or now>=camp.ready_at)
end
function M.killed(camp,now,cfg)
 if camp.remaining<=0 then return false end
 camp.remaining=camp.remaining-1
 if camp.remaining==0 then camp.ready_at=now+cfg.respawn_seconds end
 return true
end
return M

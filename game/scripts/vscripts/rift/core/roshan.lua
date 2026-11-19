local M={}
function M.pocket(cfg,elapsed)return math.floor(math.max(0,elapsed)/cfg.rotate_seconds)%2+1 end
function M.next_move(cfg,elapsed)return(math.floor(math.max(0,elapsed)/cfg.rotate_seconds)+1)*cfg.rotate_seconds end
function M.scale(cfg,elapsed)
 for _,p in ipairs(cfg.phases)do if elapsed<p.until_seconds then return p.scale end end
 return cfg.phases[#cfg.phases].scale
end
return M

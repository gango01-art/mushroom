-- Pure request/roster/placement policy for the single-player showcase.
local L = {}
L.ACTIONS = { start=true, select=true, gallery=true, clear=true, target=true, reset=true, free=true, rank=true }
L.PATHS = { base=true, physical=true, magical=true }
L.TARGETS = { immortal=true, mortal=true, immune=true }
function L.roster(registry)
  local out, known = {}, {}
  for _, d in ipairs(registry.directions) do
    if registry:hero_enabled(d.hero_id) and not known[d.hero_id] then
      known[d.hero_id] = true; out[#out+1] = d.hero_id
    end
  end
  table.sort(out)
  return out, known
end
function L.resolve_hero(name,known)
  if type(name)~="string" then return nil end
  local aliases={pa="phantom_assassin",ta="templar_assassin",lc="legion_commander",sf="nevermore",cm="crystal_maiden",wr="windrunner"}
  local full=known[name] and name or "npc_dota_hero_"..(aliases[name] or name)
  return known[full] and full or nil
end
function L.validate(args, known)
  if type(args) ~= "table" or not L.ACTIONS[args.action] then return false,"invalid_action" end
  if args.action == "select" and (type(args.hero) ~= "string" or not known[args.hero]) then return false,"invalid_hero" end
  if args.action == "select" or args.action == "gallery" then
    if not L.PATHS[args.path] then return false,"invalid_path" end
  end
  if args.action == "rank" and args.rank ~= 1 and args.rank ~= 2 and args.rank ~= 3 then return false,"invalid_rank" end
  if args.action == "target" and not L.TARGETS[args.kind] then return false,"invalid_target" end
  return true
end
function L.gallery(cfg, center, count)
  local out={}
  for i=1,count do
    local a=2*math.pi*(i-1)/math.max(1,count)
    out[i]={x=center.x+cfg.gallery_radius*math.cos(a), y=center.y+cfg.gallery_radius*math.sin(a), z=center.z or 0}
  end
  return out
end
-- Return a traversable, unoccupied point near a requested slot, or nil.
function L.walkable(cfg, goal, available, reserved)
  local function fits(p)
    if not available(p) then return false end
    for _,other in ipairs(reserved or {}) do
      if (p.x-other.x)^2+(p.y-other.y)^2 < cfg.placement_separation^2 then return false end
    end
    return true
  end
  if fits(goal) then return goal end
  for ring=1,cfg.nav_search_steps do
    for i=0,15 do
      local a=i/16*2*math.pi
      local p={x=goal.x+cfg.nav_step*ring*math.cos(a),y=goal.y+cfg.nav_step*ring*math.sin(a),z=goal.z}
      if fits(p) then return p end
    end
  end
  return nil
end
return L

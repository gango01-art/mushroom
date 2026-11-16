-- Regenerate native tooltip specials from the same Lua data used for damage.
-- Run from repository root: lua5.1 tools/sync_path_tooltips.lua [--check]
package.path = "game/scripts/vscripts/?.lua;" .. package.path
local E = require("rift.data.expansion")
local path = "game/scripts/npc/npc_abilities_custom.txt"
local f = assert(io.open(path,"r")); local source=f:read("*a");f:close()
local output=source
local function joined(v, scale)
  if type(v)~="table" then v={v} end
  local values={}
  for _,n in ipairs(v) do values[#values+1]=string.format("%g",n*(scale or 1)) end
  return table.concat(values," ")
end
local fields = {
  {"base_damage","damage"}, {"attack_pct","attack",100}, {"attack_speed_pct","attack_speed_damage",100}, {"strength_pct","strength",100},
  {"intellect_pct","intellect",100}, {"agility_pct","agility",100}, {"hits","ticks"},
  {"attacks","every"}, {"duration","duration"}, {"slow","slow"}, {"root","root"},
  {"radius","radius"}, {"range","range"}, {"interval","interval"}, {"delay","delay"},
  {"attack_speed","attack_speed"}, {"hit_cdr","hit_cdr"}, {"max_targets","max_targets"},
  {"pull_distance","pull_distance"}, {"stun","stun"}, {"expand","expand"},
  {"heal_pct","heal_fraction",100}, {"heal_cap_pct","heal_cap",100},
  {"distance_pct","distance_bonus",100}, {"ramp_pct","ramp",100},
}
local names={};for name in pairs(E.abilities) do names[#names+1]=name end;table.sort(names)
for _,name in ipairs(names) do
  local d=E.abilities[name]
  local original=assert(output:match('"'..name..'"%s*(%b{})'),name)
  local clean=original:gsub('%s*"AbilitySpecial"%s*%b{}',''):gsub('%s*"AbilityValues"%s*%b{}','')
  clean=clean:gsub('%s*"AbilityCooldown"%s*"[^"]*"',''):gsub('%s*"AbilityManaCost"%s*"[^"]*"','')
  clean=clean:gsub('%s*"AbilityBehavior"%s*"[^"]*"',''):gsub('%s*"AbilityCastRange"%s*"[^"]*"','')
  local behavior=d.target=="none" and "DOTA_ABILITY_BEHAVIOR_NO_TARGET" or d.target=="unit" and "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET" or "DOTA_ABILITY_BEHAVIOR_POINT"
  if d.target=="point" and d.mode~="line" then behavior=behavior.." | DOTA_ABILITY_BEHAVIOR_AOE" end
  clean=clean:sub(1,-2)..'\n\t\t"AbilityBehavior" "'..behavior..'"\n\t\t"AbilityCastRange" "'..d.range..'"\n\t\t"AbilityCooldown" "'..joined(d.cooldown)..'"\n\t\t"AbilityManaCost" "'..joined(d.mana)..'"\n\t}'
  local specials='\n\t\t"AbilityValues"\n\t\t{\n'
  local i=0
  for _,field in ipairs(fields) do
    if d[field[2]] then
      i=i+1
      specials=specials..string.format('\t\t\t"path_%s" "%s"\n',field[1],joined(d[field[2]],field[3]))
    end
  end
  specials=specials..'\t\t}\n\t'
  local replacement=clean:sub(1,-2):gsub('%s*$','')..specials..'}'
  local pattern='("'..name..'"%s*)%b{}'
  output=output:gsub(pattern,function(header) return header..replacement end,1)
end
output=output:gsub("[ \t]+\n","\n")
if arg[1]=="--check" then
  if source~=output then io.stderr:write("Path tooltip specials stale: run lua5.1 tools/sync_path_tooltips.lua\n");os.exit(1) end
  print("Path tooltip specials match server balance data")
else
  local out=assert(io.open(path,"w"));out:write(output);out:close()
  print("Updated 14 native ability tooltip special blocks")
end

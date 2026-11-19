local E=require("rift.data.expansion")
local function read(path) local f=assert(io.open(path,"r"));local s=f:read("*a");f:close();return s end
T.case("every expansion ability has a KV binding and correct targeting/damage type",function()
  local kv=read("game/scripts/npc/npc_abilities_custom.txt")
  for name,d in pairs(E.abilities) do
    local block=assert(kv:match('"'..name..'"%s*(%b{})'),name)
    T.ok(block:find('"rift/abilities/path_ultimate"',1,true),name.." script")
    local kind=({unit="UNIT_TARGET",point="POINT",none="NO_TARGET"})[d.target]
    T.ok(block:find("DOTA_ABILITY_BEHAVIOR_"..kind,1,true),name.." behavior")
    T.ok(block:find("DAMAGE_TYPE_"..d.path:upper(),1,true),name.." damage type")
    T.eq(#d.cooldown,3);T.eq(#d.mana,3);T.eq(#d.damage,3)
  end
end)
T.case("selectable roster matches the complete directions registry",function()
  local list=read("game/scripts/npc/herolist.txt")
  local reg=require("rift.core.upgrade_registry").new({},require("rift.data.ultimate_directions"))
  local n=0
  for hero in list:gmatch('"(npc_dota_hero_[^"]+)"%s*"1"') do T.ok(reg:hero_enabled(hero),hero);n=n+1 end
  T.eq(n,11)
end)
T.case("all path names/descriptions and ability tooltips exist in both languages",function()
  for _,lang in ipairs({"english","russian"}) do
    local s=read("game/resource/addon_"..lang..".txt")
    local tokens={}
    for key in s:gmatch('"([^"\n]+)"%s+"[^"\n]*"') do
      T.ok(not tokens[key],"duplicate localization token "..key);tokens[key]=true
    end
    for _,d in ipairs(require("rift.data.ultimate_directions")) do
      T.ok(tokens[d.loc_name],d.loc_name);T.ok(tokens[d.loc_desc],d.loc_desc)
    end
    for name in pairs(E.abilities) do
      T.ok(tokens["DOTA_Tooltip_ability_"..name]);T.ok(tokens["DOTA_Tooltip_ability_"..name.."_Description"])
    end
  end
end)

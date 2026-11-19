-- Native unit initialization and localized sanctuary explanation, one config.
package.path="game/scripts/vscripts/?.lua;"..package.path
local B=require("rift.core.config").sanctuary
local check=arg[1]=="--check"
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function save(p,s)
 local f=io.open(p,"rb");local old=f and f:read("*a")or"";if f then f:close()end
 if old:gsub("\r\n","\n")==s:gsub("\r\n","\n")then return end
 assert(not check,"sanctuary generated file out of sync: "..p)
 f=assert(io.open(p,"wb"));f:write(s);f:close()
end
local kv={'// Generated from core/config.lua by tools/sync_sanctuary.lua.','"DOTAUnits"','{',' "'..B.tower_unit..'"',' {'}
local values={BaseClass="npc_dota_tower",Model=B.tower_model,ModelScale=B.tower_scale,Level=1,
 AttackCapabilities="DOTA_UNIT_CAP_RANGED_ATTACK",AttackDamageMin=B.tower_damage,AttackDamageMax=B.tower_damage,
 AttackRate=B.tower_attack_rate,AttackAnimationPoint=.1,AttackRange=B.tower_range,AttackAcquisitionRange=B.tower_range,
 ProjectileModel="particles/base_attacks/ranged_tower_good.vpcf",ProjectileSpeed=1200,
 MovementCapabilities="DOTA_UNIT_CAP_MOVE_NONE",StatusHealth=B.tower_health,StatusMana=0,
 ArmorPhysical=B.tower_armor,MagicalResistance=B.tower_magic_resistance,
 VisionDaytimeRange=B.tower_vision,VisionNighttimeRange=B.tower_vision,BoundsHullName="DOTA_HULL_SIZE_TOWER",
 IsNeutralUnitType=0,BountyXP=0,BountyGoldMin=0,BountyGoldMax=0}
local keys={};for k in pairs(values)do keys[#keys+1]=k end;table.sort(keys)
for _,k in ipairs(keys)do kv[#kv+1]='  "'..k..'" "'..values[k]..'"'end
kv[#kv+1]=' }\n}\n';save("game/scripts/npc/npc_sanctuary_units.txt",table.concat(kv,"\n"))
local path="game/scripts/npc/npc_units_custom.txt";local units=read(path)
if not units:find('#base "npc_sanctuary_units.txt"',1,true)then units='#base "npc_sanctuary_units.txt"\n'..units end
save(path,units)
for _,lang in ipairs({"russian","english"})do
 local p="game/resource/addon_"..lang..".txt";local s=read(p)
 local function token(k,v)
  local line='"'..k..'" "'..v..'"';local pat='"'..k..'"%s*"[^"\n]*"'
  if s:find(pat)then s=s:gsub(pat,function()return line end)
  else s=s:gsub('%s*}%s*}%s*$',function()return '\n\t\t'..line..'\n\t}\n}\n'end)end
 end
 local ru=lang=="russian"
 token(B.tower_unit,ru and"Страж святилища"or"Sanctuary Guardian")
 token("DOTA_Tooltip_modifier_rift_sanctuary",ru and"Защита своей базы"or"Home sanctuary")
 token("DOTA_Tooltip_modifier_rift_sanctuary_Description",ru and
  string.format("Восстанавливает %g%% максимального здоровья и %g%% максимальной маны в секунду. Регулярное сильное развеивание. В своей зоне радиусом %g урон и вражеские эффекты блокируются в обе стороны, в том числе через подконтрольных существ. Атаки и способности временно недоступны. При выходе защита прекращается.",B.hp_regen_pct,B.mana_regen_pct,B.radius)or
  string.format("Restores %g%% max health and %g%% max mana per second. Repeated strong dispels. Inside your %g-radius home, damage and hostile effects are blocked in both directions, including through controlled units. Attacks and abilities are disabled. Protection ends on exit.",B.hp_regen_pct,B.mana_regen_pct,B.radius))
 save(p,s)
end
print("Sanctuary unit and RU/EN descriptions synchronized")

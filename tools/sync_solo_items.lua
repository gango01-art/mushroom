-- Generate native item overrides and descriptions from one balance source.
package.path="game/scripts/vscripts/?.lua;"..package.path
local B=require("rift.data.solo_items")
local check=arg[1]=="--check"
local Native=dofile("tools/solo_item_native_fields.lua")
local Titles=dofile("tools/solo_item_native_titles.lua")
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local function save(p,s)
 local f=io.open(p,"rb");local old=f and f:read("*a")or"";if f then f:close()end
 if old:gsub("\r\n","\n")==s:gsub("\r\n","\n")then return end
 assert(not check,"solo item generated file out of sync: "..p)
 f=assert(io.open(p,"wb"));f:write(s);f:close()
end
local function keys(t)local a={};for k in pairs(t)do a[#a+1]=k end;table.sort(a);return a end
local labels={
 all_stats={"ко всем атрибутам","all attributes"},strength={"силы","strength"},armor={"брони","armor"},
 health={"здоровья","health"},mana={"маны","mana"},health_regen={"здоровья/сек","health/sec"},mana_regen={"маны/сек","mana/sec"},
 attack_damage={"урона атаки","attack damage"},attack_speed={"скорости атаки","attack speed"},move_speed={"скорости передвижения","movement speed"},
 boots_speed={"скорости от ботинок (не складывается с другими ботинками)","boot movement speed (does not stack with other boots)"},
 magic_resistance={"% сопротивления магии","% magic resistance"},lifesteal={"% вампиризма атак; по крипам и иллюзиям 60% эффективности","% attack lifesteal; 60% effectiveness on creeps/illusions"},
 enemy_armor={"брони врагам рядом","armor to nearby enemies"},enemy_radius={"радиуса ослабления врагов","enemy debuff radius"},
 attack_block={"блокировки физического урона атаки","physical attack damage block"},block_chance={"% шанса блокировки","% block chance"},
 move_speed_pct={"% скорости передвижения","% movement speed"},barrier={"ед. барьера","barrier capacity"},
 hit_damage={"доп. физического урона следующей обычной попавшей атакой","bonus physical damage on the next ordinary landed attack"},
 break_duration={"сек. истощения следующей атакой","seconds Break on the next attack"},
 heal={"восстановленного здоровья","health restored"},restore_mana={"восстановленной маны","mana restored"},
 heal_max_health_pct={"% максимального здоровья дополнительно","% additional max health restored"},heal_pct_cap={"макс. дополнительного лечения","maximum additional healing"},
 heal_lockout={"сек. общего запрета повторного лечения Mekansm/Greaves","seconds shared Mekansm/Greaves heal lockout"},
}
local names={glimmer_cape={"Glimmer Cape","Glimmer Cape"},invis_sword={"Shadow Blade","Shadow Blade"},silver_edge={"Silver Edge","Silver Edge"},pipe={"Pipe of Insight","Pipe of Insight"},crimson_guard={"Crimson Guard","Crimson Guard"},pavise={"Pavise","Pavise"},solar_crest={"Solar Crest","Solar Crest"},mekansm={"Mekansm","Mekansm"},guardian_greaves={"Guardian Greaves","Guardian Greaves"},vladmir={"Vladmir's Offering","Vladmir's Offering"},assault={"Assault Cuirass","Assault Cuirass"},ancient_janggo={"Drum of Endurance","Drum of Endurance"},boots_of_bearing={"Boots of Bearing","Boots of Bearing"},headdress={"Headdress","Headdress"},buckler={"Buckler","Buckler"},ring_of_basilius={"Ring of Basilius","Ring of Basilius"},arcane_boots={"Arcane Boots","Arcane Boots"}}

local function describe(values,lang)
 local out={}
 for _,k in ipairs(keys(values))do
  local v=values[k]
  if labels[k]then out[#out+1]=string.format("%g %s",v,labels[k][lang])
  elseif k=="purge"then out[#out+1]=lang==1 and"базовое развеивание с владельца"or"basic dispel on owner"
  elseif k=="damage_type"then out[#out+1]=lang==1 and(v=="magical"and"барьер поглощает только магический урон"or"барьер поглощает только физический урон")or(v=="magical"and"barrier absorbs only magical damage"or"barrier absorbs only physical damage")
  elseif k~="duration"and k~="cooldown"and k~="mana"then error("missing item label "..k)end
 end
 return table.concat(out,"; ")
end
local loc={read("game/resource/addon_russian.txt"),read("game/resource/addon_english.txt")}
local function token(lang,k,v)
 local line='"'..k..'" "'..v..'"';local pattern='"'..k..'"%s*"[^"\n]*"'
 if loc[lang]:find(pattern)then loc[lang]=loc[lang]:gsub(pattern,function()return line end)
 else loc[lang]=loc[lang]:gsub('%s*}%s*}%s*$',function()return '\n\t\t'..line..'\n\t}\n}\n'end)end
end
-- The default item definitions are merged by the engine. Clear their old
-- AbilityValues, then publish only the real Lua stats as native +$ rows.
local stat_tokens={all_stats="+$all",strength="+$str",armor="+$armor",health="+$health",mana="+$mana",
 attack_damage="+$damage",attack_speed="+$attack_speed",health_regen="+$hp_regen",mana_regen="+$mp_regen",
 move_speed="+$move_speed",boots_speed="+$move_speed",magic_resistance="%+$spell_resist"}
local function specials(name,d)
 local values={};for _,key in ipairs(assert(Native[name]))do values[key]=0 end
 for k,v in pairs(d.stats)do values["solo_stat_"..k]=v end
 for k,v in pairs(d.active or{})do if type(v)=="number"and k~="mana"and k~="cooldown"then values["solo_active_"..k]=v end end
 local out={'  "AbilityValues"','  {'}
 for _,key in ipairs(keys(values))do out[#out+1]='   "'..key..'" "'..values[key]..'"'end
 out[#out+1]='  }';return table.concat(out,"\n")
end
local function detail_lines(values,prefix,lang,only_special)
 local out={}
 for _,k in ipairs(keys(values))do
  if labels[k]and k~="mana"and k~="duration"and(not only_special or not stat_tokens[k])then
   out[#out+1]='<b>%'..prefix..k..'%</b> '..labels[k][lang]
  elseif k=="purge"then out[#out+1]=lang==1 and"Базовое развеивание с владельца"or"Basic dispel on the owner"
  elseif k=="damage_type"then out[#out+1]=lang==1 and(values[k]=="magical"and"Поглощает только магический урон"or"Поглощает только физический урон")or(values[k]=="magical"and"Absorbs only magical damage"or"Absorbs only physical damage")end
 end
 return table.concat(out,"<br>")
end
local kv={'#base "npc_aghanim_items.txt"','// Generated by tools/sync_solo_items.lua. Native item IDs/shop entries retained.','"DOTAAbilities"','{'}

local doc={'# Предметы для одиночного FFA','','Числа — первый совместный баланс. Штатные названия ID сохранены для магазина и рецептов. Это полностью Lua-предметы: старые native инвиз/ауры этих предметов не применяются. Одна копия сильнейшего предмета каждой цепочки даёт пассивные свойства; рюкзак/тайник не учитываются. Активные эффекты применяются только к владельцу.','','| Предмет | Цена | Пассивно владельцу | Активно владельцу |','|---|---:|---|---|'}
for _,name in ipairs(keys(B.items))do
 local d=B.items[name];local short=name:gsub('^item_','');local a=d.active
 kv[#kv+1]=' "'..name..'"\n {\n  "BaseClass" "item_lua"\n  "ScriptFile" "rift/abilities/solo_items"\n  "AbilityTextureName" "'..short..'"\n  "AbilityBehavior" "'..(a and'DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE'or'DOTA_ABILITY_BEHAVIOR_PASSIVE')..'"\n  "AbilityUnitTargetTeam" "DOTA_UNIT_TARGET_TEAM_NONE"\n  "AbilityUnitTargetType" "DOTA_UNIT_TARGET_NONE"\n  "AbilityCastRange" "0"\n  "SpellDispellableType" "'..(a and a.duration and'SPELL_DISPELLABLE_YES'or'SPELL_DISPELLABLE_NO')..'"\n  "ItemCost" "'..d.cost..'"\n  "ItemQuality" "rare"\n  "ItemPurchasable" "1"\n  "ItemInitialCharges" "0"\n  "ItemRequiresCharges" "0"\n  "AbilityCooldown" "'..(a and a.cooldown or 0)..'"\n  "AbilityManaCost" "'..(a and a.mana or 0)..'"\n'..specials(name,d)..'\n }'
 for lang=1,2 do
  token(lang,'DOTA_Tooltip_ability_'..name,names[short][lang])
  for k in pairs(d.stats)do
   token(lang,'DOTA_Tooltip_ability_'..name..'_solo_stat_'..k,stat_tokens[k]or labels[k][lang])
  end
  local text=""
  if a then
   text="<h1>"..assert(Titles[short])[lang].."</h1>"..
    (lang==1 and"Действует только на владельца.<br><br>"or"Affects only the owner.<br><br>")..
    detail_lines(a,"solo_active_",lang,false)
   if name=="item_glimmer_cape"then text=text..(lang==1 and"<br>Невидимости нет."or"<br>Does not grant invisibility.")end
   if a.duration then text=text..(lang==1 and"<br><br>Длительность: <b>%solo_active_duration%</b> сек."or"<br><br>Duration: <b>%solo_active_duration%</b> seconds.")end
   if a.hit_damage then text=text..(lang==1 and"<br>Прохождение сквозь существ, без невидимости. Дополнительные атаки способностей не расходуют усиление."or"<br>Grants phased movement without invisibility. Extra spell attacks do not consume the boost.")end
  end
  local passive=detail_lines(d.stats,"solo_stat_",lang,true)
  if passive~=""then text=text..(lang==1 and"<h1>Пассивное</h1>"or"<h1>Passive</h1>")..passive
  elseif not a then text=lang==1 and"<h1>Пассивное</h1>Характеристики получает только владелец."or"<h1>Passive</h1>Only the owner receives these attributes."end
  token(lang,'DOTA_Tooltip_ability_'..name..'_Description',text)
  for n=1,9 do token(lang,'DOTA_Tooltip_ability_'..name..'_Note'..n,"")end
  token(lang,'DOTA_Tooltip_ability_'..name..'_Note0',lang==1 and"Эффекты DUALITY только для владельца. Пассивные свойства одинаковых предметов и их улучшений не складываются. Сопротивление магии складывается по обычным правилам Dota."or"DUALITY effects apply only to the owner. Passive bonuses from duplicate items and their upgrades do not stack. Magic resistance follows normal Dota stacking.")
 end
 doc[#doc+1]='| '..names[short][1]..' | '..d.cost..' | '..describe(d.stats,1)..' | '..(a and describe(a,1)..(a.duration and' / '..a.duration..' с'or'')..'; КД '..a.cooldown..'; мана '..a.mana or'—')..' |'
end
for _,name in ipairs(keys(B.recipes))do local r=B.recipes[name]
 kv[#kv+1]=' "'..name..'"\n {\n  "ItemCost" "'..r.cost..'"\n  "ItemRecipe" "1"\n  "ItemResult" "'..r.result..'"\n  "ItemRequirements" { "01" "'..table.concat(r.components,';')..'" }\n }'
end
kv[#kv+1]=' "item_shadow_amulet" { "ItemPurchasable" "0" "IsObsolete" "1" "BaseClass" "item_lua" "ScriptFile" "rift/abilities/solo_items" "AbilityBehavior" "DOTA_ABILITY_BEHAVIOR_PASSIVE" }\n}\n'
for lang=1,2 do token(lang,'rift_item_recovery_error',lang==1 and"Повторное лечение Mekansm/Greaves временно недоступно"or"Mekansm/Greaves healing is temporarily locked")end
local buff_names={glimmer_cape={"Защита Glimmer Cape","Glimmer Cape protection"},shadow_weapon={"Теневой натиск","Shadow assault"},pipe={"Защита Pipe of Insight","Pipe of Insight protection"},crimson_guard={"Защита Crimson Guard","Crimson Guard protection"},solar={"Физический барьер","Physical barrier"},drums={"Выносливость","Endurance"},recovery_lockout={"Повторное лечение недоступно","Recovery locked"},assault_debuff={"Ослабление брони","Armor reduced"},["break"]={"Истощение","Break"}}
for suffix,title in pairs(buff_names)do for lang=1,2 do
 token(lang,"DOTA_Tooltip_modifier_rift_item_"..suffix,title[lang])
 local descriptions={
 glimmer_cape={"Дополнительное сопротивление магии. Невидимость не предоставляется.","Additional magic resistance. Does not grant invisibility."},
 shadow_weapon={"Ускорение и прохождение сквозь существ. Следующая обычная попавшая атака расходует усиление.","Movement speed and phased movement. The next ordinary landed attack consumes the boost."},
 pipe={"Дополнительное сопротивление магии и магический барьер. Число на значке — оставшийся барьер.","Additional magic resistance and a magical barrier. The icon count shows the remaining barrier."},
 crimson_guard={"Блокировка физического урона атак. Пассивный блок предмета временно заменён усиленным.","Blocks physical attack damage. Temporarily replaces the item's passive block."},
 solar={"Поглощает физический урон. Число на значке — оставшийся барьер.","Absorbs physical damage. The icon count shows the remaining barrier."},
 drums={"Скорость атаки и передвижения увеличены.","Attack and movement speed are increased."},
 recovery_lockout={"Повторное лечение от Mekansm и Guardian Greaves недоступно до окончания эффекта.","Mekansm and Guardian Greaves healing is unavailable until this effect expires."},
 assault_debuff={"Броня снижена.","Armor is reduced."},
 ["break"]={"Пассивные способности отключены.","Passive abilities are disabled."}}
 token(lang,"DOTA_Tooltip_modifier_rift_item_"..suffix.."_Description",descriptions[suffix][lang])
end end
doc[#doc+1]='\nGlimmer: две Crown + Shawl + рецепт 800 = 2150. Shadow Blade: Claymore + Blitz Knuckles + две Crown = 3250. Обе пары Crown дают готовому предмету +10 ко всем атрибутам; Silver Edge сохраняет +10. Shadow Amulet нельзя купить.'
doc[#doc+1]='\nНе меняются сейчас: Veil (уже личный магический предмет), Urn/Vessel (в FFA сохраняют смысл лечения себя/давления на врага), Force Staff/Hurricane Pike (работают на себя и врагов). Wraith Pact — устаревший штатный предмет, его наличие в магазине проверять отдельно; не считать реализованной новой веткой. Геройские Meld/Blur этим проходом не меняются.'
doc[#doc+1]='\nФактические native проверки, ограничения и скриншоты — [TEST_RESULTS.md](TEST_RESULTS.md). Числа этой таблицы сами по себе не доказывают результат PvP.'
save('game/scripts/npc/npc_items_custom.txt',table.concat(kv,'\n'))
save('game/resource/addon_russian.txt',loc[1]);save('game/resource/addon_english.txt',loc[2])
save('docs/SOLO_ITEMS.md',table.concat(doc,'\n')..'\n')
print('Solo item KV / RU / EN / reference synchronized (17 items, 2 recipes)')

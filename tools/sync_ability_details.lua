-- Native Dota tooltip data/localization; no custom imitation of the tooltip UI.
package.path="game/scripts/vscripts/?.lua;"..package.path
local B=require("rift.data.hero_balance")
local E=require("rift.data.expansion")
local function read(p) local f=assert(io.open(p,"r"));local s=f:read("*a");f:close();return s end
local function save(p,old,new)
  new=new:gsub("[ \t]+\n","\n")
  if arg[1]=="--check" then assert(old==new,"stale native tooltip: "..p)
  else local f=assert(io.open(p,"w"));f:write(new);f:close() end
end
local function joined(v,scale)
  if type(v)~="table" then v={v} end
  local a={};for _,n in ipairs(v) do a[#a+1]=string.format("%g",n*(scale or 1)) end
  return table.concat(a," ")
end
local function scaled(v,scale) local r={};for i,n in ipairs(v)do r[i]=n*scale end;return r end
local extras={
 rift_lc_courage={attacks=B.lc.courage_physical.attacks,lifesteal=B.lc.courage_physical.lifesteal},
 lc_duel_physical={duration=10,damage_per_second=B.lc.duel_physical.per_second,damage_cap=B.lc.duel_physical.permanent_cap,leash=B.lc.duel_physical.leash_distance,champion_speed_pct=90},
 lc_duel_magical={spell_amp=B.lc.duel_magical.base_spell_amp,amp_cap=B.lc.duel_magical.cap_spell_amp,kill_amp=B.lc.duel_magical.per_kill,assist_amp=B.lc.duel_magical.per_assist},
 lc_statue={base_damage=B.lc.statue.arrow_damage,health=B.lc.statue.health,duration=B.lc.statue.lifetime,hit_cdr=B.lc.statue.cdr_per_hit,range=B.lc.statue.beam_range,radius=B.lc.statue.beam_half_width,cooldown_by_ult=B.lc.statue.cooldown},
 sf_requiem_physical={duration=B.sf.requiem_physical.duration,spheres=B.sf.requiem_physical.spheres,regen=B.sf.requiem_physical.sphere_regen,attack_pct=B.sf.requiem_physical.sphere_damage_fraction*100,raze_pct={40,60,80}},
 ta_psionic_crystal={radius=B.ta.crystal_physical.radius,duration=B.ta.crystal_physical.lifetime,health=B.ta.crystal_physical.durability},
 ta_meld_physical={base_damage=B.ta.meld_physical.bonus_damage},
 ta_psionic_blast={base_damage=B.ta.trap_magical.damage,radius=B.ta.trap_magical.radius,delay=B.ta.trap_magical.delay,slow=B.ta.trap_magical.slow,duration=B.ta.trap_magical.slow_duration},
 ta_refraction_magical={base_damage=B.ta.waves_magical.q_base,intellect_pct=B.ta.waves_magical.intellect_scaling*100,health=B.ta.refraction_magical.shield_per_instance,spheres=B.ta.refraction_magical.instances,duration=B.ta.refraction_magical.duration,range=B.ta.waves_magical.length,radius=B.ta.waves_magical.width/2},
 ta_meld_dash={base_damage=B.ta.waves_magical.w_base,intellect_pct=B.ta.waves_magical.intellect_scaling*100,dash=B.ta.waves_magical.w_dash,range=B.ta.waves_magical.length,radius=B.ta.waves_magical.width/2},
 ta_psi_wave={base_damage=B.ta.waves_magical.e_base,intellect_pct=B.ta.waves_magical.intellect_scaling*100,range=B.ta.waves_magical.length,radius=B.ta.waves_magical.width/2},
 pa_phantom_execution={range=B.pa.execution_physical.range,hit_cdr=B.passives.pa_dagger_cdr},
 pa_storm_charge={chance=scaled(B.pa.storm_magical.chain_chance,100),base_damage=B.pa.storm_magical.chain_damage,radius=B.pa.storm_magical.second_target_radius},
 pa_storm_dagger={radius=B.pa.storm_magical.second_target_radius,base_damage=B.pa.storm_magical.dagger_base_damage,attack_pct={30,45,60,75},slow=50,duration=B.pa.storm_magical.dagger_slow_duration},
 rift_sven_echo={echo_cooldown=B.passives.sven_echo_cooldown},
 rift_sven_mystic_cleave={radius_bonus=B.passives.sven_radius,debuff_amp=B.passives.sven_debuff},
 rift_juggernaut_spell_crit={chance=B.passives.jug_chance,crit_multiplier=B.passives.jug_multiplier},
}
local desc={
 rift_lc_courage={"Каждая %path_attacks%-я собственная попавшая атака вызывает быструю контратаку, которая лечит Legion Commander на %path_lifesteal%%% нанесённого урона. Атаки врагов не учитываются. Дополнительный удар не запускает сам себя.","Every %path_attacks% landed attacks trigger a quick counterattack that heals Legion Commander for %path_lifesteal%%% of its damage. Incoming attacks do not count. The counterattack cannot trigger itself."},
 rift_lina_physical={"Выпускает три летящих солнечных волны. Урон каждой: %path_attack_pct%%% от атаки + %path_attack_speed_pct%%% от показателя скорости атаки. Например, 100 скорости атаки дают 35 урона на третьем ранге. Волны пробивают врагов; эффекты атак не срабатывают.","Launches three traveling solar waves. Each deals %path_attack_pct%%% attack damage + %path_attack_speed_pct%%% of displayed attack speed. 100 attack speed adds 35 damage at rank 3. Waves pierce enemies without triggering attack effects."},
 rift_axe_physical={"Притягивает врагов вокруг Axe на %path_pull_distance% и наносит физический урон: %path_base_damage% + %path_attack_pct%%% урона атаки. Невосприимчивых к эффектам врагов не перемещает.","Pulls nearby enemies toward Axe and deals physical damage: %path_base_damage% + %path_attack_pct%%% attack damage. Debuff-immune enemies cannot be pulled."},
 rift_juggernaut_physical={"По очереди атакует каждого видимого врага в выбранной области, затем возвращается на исходное место. Во время серии неуязвим. Это обычные атаки: работают предметы, криты и уклонение. Каждое попадание по врагу, включая обычные атаки, сокращает оставшуюся перезарядку на %path_hit_cdr% сек. до нуля.","Attacks each visible enemy in the selected area once, then returns. Invulnerable during the sequence. Real attacks trigger items and critical strikes and can miss. Every landed attack against an enemy reduces the remaining cooldown by %path_hit_cdr% seconds, down to zero."},
 rift_juggernaut_magical={"Буря наносит %path_base_damage% + %path_agility_pct%%% ловкости магического урона за импульс и замедляет. Следует за героем; после смерти продолжает действовать на месте смерти до конца исходного срока.","A storm deals %path_base_damage% + %path_agility_pct%%% agility as magical damage per pulse and slows enemies. Follows the caster; after death it remains at the death location for the rest of its original duration."},
 rift_cm_physical={"Выпускает %path_hits% ледяных залпа во всех видимых врагов вокруг Crystal Maiden. Каждый снаряд наносит %path_base_damage% + %path_attack_pct%%% урона атаки физическим уроном и замедляет. Снаряд можно сбить; эффекты атак и предметов не срабатывают.","Fires %path_hits% icy volleys at all visible enemies around Crystal Maiden. Each projectile deals %path_base_damage% + %path_attack_pct%%% attack damage as physical damage and slows. Projectiles are disjointable and do not trigger attack or item effects."},
 pa_storm_charge={"Кинжал поражает всех видимых врагов рядом с основной целью. Один бросок на применение: если попали хотя бы два кинжала, молния наносит магический урон каждой поражённой цели один раз. Обычные криты Coup de Grace отключены.","Daggers target all visible enemies near the primary target. One roll per cast: if at least two daggers land, lightning damages each landed target once. Native Coup de Grace critical strikes are disabled."},
 pa_storm_dagger={"Бросает кинжалы во всех видимых врагов вокруг основной цели. Каждый совершает атаку с базовым уроном + долей урона атаки и замедляет. Работают эффекты атак предметов и критические удары. Кинжал не промахивается, но снаряд можно сбить. Одна цель получает один кинжал за применение.","Throws daggers at all visible enemies around the primary target. Each performs an attack with base damage plus a fraction of attack damage and slows. Item attack effects and critical strikes work. Cannot miss, but projectiles can be disjointed. One dagger per target per cast."},
 rift_sven_echo={"Вместо прорубающего урона: после попадания Sven быстро наносит второй обычный удар той же цели. Работают эффекты атак; дополнительный удар не запускает сам себя. Прерывается бессилием, оглушением или уходом цели из дальности атаки.","Replaces Great Cleave: a landed attack triggers a quick second normal attack against the same target. Triggers attack effects; cannot trigger itself. Interrupted by stun, disarm or the target leaving attack range."},
 rift_sven_mystic_cleave={"Вместо прорубающего урона: увеличивает радиус заклинаний и длительность исходящих отрицательных эффектов. Не увеличивает урон, число импульсов или дальность применения.","Replaces Great Cleave: increases spell radius and outgoing debuff duration. Does not increase damage, pulse count or cast range."},
 rift_juggernaut_spell_crit={"Вместо Blade Dance: магический урон способностей и предметов с вероятностью %path_chance%%% усиливается до %path_crit_multiplier%%% исходного значения. Например, при 120% урон 100 становится 120. Не усиливает физический, чистый урон и отражение Blade Mail. Отключается истощением.","Replaces Blade Dance: magical spell and item damage has a %path_chance%%% chance to deal %path_crit_multiplier%%% of its original value. At 120%, 100 damage becomes 120. Excludes physical, pure and Blade Mail reflected damage. Disabled by Break."},
}
local labels={
 attack_speed_pct={"УРОН ОТ СКОРОСТИ АТАКИ (%):","ATTACK SPEED DAMAGE (%):"},lifesteal={"ВАМПИРИЗМ КОНТРАТАКИ (%):","COUNTERATTACK LIFESTEAL (%):"},
 base_damage={"БАЗОВЫЙ УРОН:","BASE DAMAGE:"},attack_pct={"УРОН ОТ АТАКИ (%):","ATTACK DAMAGE (%):"},strength_pct={"УРОН ОТ СИЛЫ (%):","STRENGTH DAMAGE (%):"},intellect_pct={"УРОН ОТ ИНТЕЛЛЕКТА (%):","INTELLECT DAMAGE (%):"},agility_pct={"УРОН ОТ ЛОВКОСТИ (%):","AGILITY DAMAGE (%):"},
 hits={"ЧИСЛО ИМПУЛЬСОВ:","PULSES:"},attacks={"АТАК ДЛЯ ЭФФЕКТА:","ATTACKS PER PROC:"},duration={"ДЛИТЕЛЬНОСТЬ:","DURATION:"},slow={"ЗАМЕДЛЕНИЕ (%):","SLOW (%):"},root={"ОЦЕПЕНЕНИЕ:","ROOT DURATION:"},radius={"РАДИУС / ПОЛУШИРИНА:","RADIUS / HALF WIDTH:"},range={"ДАЛЬНОСТЬ:","RANGE:"},interval={"ИНТЕРВАЛ:","INTERVAL:"},delay={"ЗАДЕРЖКА:","DELAY:"},attack_speed={"СКОРОСТЬ АТАКИ:","ATTACK SPEED:"},hit_cdr={"СОКРАЩЕНИЕ КД:","COOLDOWN REDUCTION:"},max_targets={"МАКС. ЦЕЛЕЙ В СЕРИИ:","MAX SEQUENCE TARGETS:"},pull_distance={"ПРИТЯГИВАНИЕ:","PULL DISTANCE:"},stun={"ОГЛУШЕНИЕ:","STUN DURATION:"},expand={"РОСТ РАДИУСА ЗА ИМПУЛЬС:","RADIUS GROWTH PER PULSE:"},heal_pct={"ЛЕЧЕНИЕ ОТ УРОНА ГЕРОЯМ (%):","HERO DAMAGE HEAL (%):"},heal_cap_pct={"ЛИМИТ ЛЕЧЕНИЯ ЗА ИМПУЛЬС (% МАКС. ЗДОРОВЬЯ):","HEAL CAP PER PULSE (% MAX HEALTH):"},distance_pct={"МАКС. БОНУС УРОНА ЗА ДАЛЬНОСТЬ (%):","MAX DISTANCE DAMAGE BONUS (%):"},ramp_pct={"РОСТ УРОНА ЗА ИМПУЛЬС (%):","DAMAGE GROWTH PER PULSE (%):"},
 health={"ЗДОРОВЬЕ / ПРОЧНОСТЬ:","HEALTH / DURABILITY:"},spheres={"ЗАРЯДОВ:","CHARGES:"},regen={"ВОССТАНОВЛЕНИЕ СФЕРЫ:","SPHERE REPLENISH TIME:"},raze_pct={"БОНУС КОЙЛАМ ОТ АТАКИ (%):","RAZE ATTACK DAMAGE BONUS (%):"},chance={"ВЕРОЯТНОСТЬ (%):","CHANCE (%):"},crit_multiplier={"КРИТИЧЕСКИЙ УРОН (%):","CRITICAL DAMAGE (%):"},echo_cooldown={"ПЕРЕЗАРЯДКА ДВОЙНОГО УДАРА:","ECHO COOLDOWN:"},radius_bonus={"ДОП. РАДИУС:","BONUS RADIUS:"},debuff_amp={"ДЛИТЕЛЬНОСТЬ ЭФФЕКТОВ (%):","DEBUFF DURATION (%):"},damage_per_second={"ПОСТОЯННЫЙ УРОН ЗА СЕКУНДУ:","PERMANENT DAMAGE PER SECOND:"},damage_cap={"ПРЕДЕЛ ПОСТОЯННОГО УРОНА:","PERMANENT DAMAGE CAP:"},leash={"ДАЛЬНОСТЬ СВЯЗИ:","LEASH DISTANCE:"},champion_speed_pct={"СКОРОСТЬ АТАКИ ЧЕМПИОНА (%):","CHAMPION ATTACK SPEED (%):"},spell_amp={"УСИЛЕНИЕ ЗАКЛИНАНИЙ (%):","SPELL AMPLIFICATION (%):"},amp_cap={"ПРЕДЕЛ УСИЛЕНИЯ (%):","AMPLIFICATION CAP (%):"},kill_amp={"ЗА УБИЙСТВО (%):","PER KILL (%):"},assist_amp={"ЗА ПОМОЩЬ (%):","PER ASSIST (%):"},dash={"ДАЛЬНОСТЬ РЫВКА:","DASH DISTANCE:"},
}
local kvpath="game/scripts/npc/npc_abilities_custom.txt"
local original=read(kvpath);local kv=original
for name,values in pairs(extras) do
  local block=assert(kv:match('"'..name..'"%s*(%b{})'),name):gsub('%s*"AbilitySpecial"%s*%b{}',''):gsub('%s*"AbilityValues"%s*%b{}','')
  local fields={};for key in pairs(values) do fields[#fields+1]=key end;table.sort(fields)
  local specials='\n\t\t"AbilityValues"\n\t\t{\n'
  for _,key in ipairs(fields) do specials=specials..string.format('\t\t\t"path_%s" "%s"\n',key,joined(values[key])) end
  block=block:sub(1,-2):gsub('%s*$','')..specials..'\t\t}\n\t}'
  kv=kv:gsub('("'..name..'"%s*)%b{}',function(h)return h..block end,1)
end
save(kvpath,original,kv)
for lang,filename in ipairs({"russian","english"}) do
  local p="game/resource/addon_"..filename..".txt";local old=read(p);local s=old
  local function token(key,value)
    local pattern='("'..key..'"%s*)"[^"]*"'
    if s:find(pattern) then s=s:gsub(pattern,function(h)return h..'"'..value..'"' end,1)
    else s=s:gsub('%s*}%s*}%s*$', function()return '\n\t\t"'..key..'" "'..value..'"\n\t}\n}\n' end) end
  end
  for name,text in pairs(desc) do token("DOTA_Tooltip_ability_"..name.."_Description",text[lang]) end
  for name,text in pairs(desc) do
    if E.abilities[name] then
      local block=assert(kv:match('"'..name..'"%s*(%b{})'))
      local card=text[lang]:gsub('%%path_([^%%]+)%%',function(key)
        return (block:match('"path_'..key..'"%s*"([^"]+)"') or "?"):gsub(" "," / ")
      end):gsub('%%%%',function()return '%' end)
      token("rift_dir_"..name.."_desc",card)
    end
  end
  token("DOTA_Tooltip_ability_rift_axe_physical",lang==1 and "Железный вихрь" or "Iron Vortex")
  token("DOTA_Tooltip_ability_rift_cm_physical",lang==1 and "Осколочный залп" or "Frost Shrapnel")
  token("rift_dir_rift_axe_physical",lang==1 and "Железный вихрь" or "Iron Vortex")
  token("rift_dir_rift_cm_physical",lang==1 and "Осколочный залп" or "Frost Shrapnel")
  token("rift_menu_subtitle",lang==1 and "Выберите героя на стартовом экране DUALITY. Изучите ультимейт, затем определите свой путь." or "Choose a hero on the DUALITY selection screen. Learn your ultimate, then choose your path.")
  for name in pairs(extras) do
    if name:find("^rift_sven_") or name=="rift_juggernaut_spell_crit" or name=="rift_lc_courage" then
      local names={rift_lc_courage={"Момент отваги","Moment of Courage"},rift_sven_echo={"Эхо клинка","Echo Blade"},rift_sven_mystic_cleave={"Мистическое рассечение","Mystic Cleave"},rift_juggernaut_spell_crit={"Магический крит","Spell Critical Strike"}}
      token("DOTA_Tooltip_ability_"..name,names[name][lang])
    end
  end
  local abilities={};for n in pairs(E.abilities) do abilities[n]=true end;for n in pairs(extras) do abilities[n]=true end
  for name in pairs(abilities) do
    local block=assert(kv:match('"'..name..'"%s*(%b{})'))
    for key,label in pairs(labels) do
      if block:find('"path_'..key..'"',1,true) then token("DOTA_Tooltip_ability_"..name.."_path_"..key,label[lang]) end
    end
    local aoe=E.abilities[name] and E.abilities[name].radius>0 or extras[name] and extras[name].radius
    if aoe then token("DOTA_Tooltip_ability_"..name.."_Note0",lang==1 and "Shiva и Gleipnir: 50% бонуса области, максимум +25% исходного радиуса. Урон, число импульсов и длительность не увеличиваются." or "Shiva and Gleipnir: 50% area bonus effectiveness, capped at +25% base radius. No damage, pulse count or duration increase.") end
  end
  token("DOTA_Tooltip_modifier_rift_lc_duel_damage_Description",lang==1 and "Накопленный дополнительный урон: %fMODIFIER_PROPERTY_TOOLTIP%." or "Earned bonus attack damage: %fMODIFIER_PROPERTY_TOOLTIP%.")
  token("DOTA_Tooltip_modifier_rift_lc_spell_amp_Description",lang==1 and "Усиление магического урона: %fMODIFIER_PROPERTY_TOOLTIP%%%. Накоплено сверх базового: %fMODIFIER_PROPERTY_TOOLTIP2%%%." or "Spell amplification: %fMODIFIER_PROPERTY_TOOLTIP%%%. Earned above base: %fMODIFIER_PROPERTY_TOOLTIP2%%%.")
  token("DOTA_Tooltip_ability_lina_slow_burn_Note0",lang==1 and "DUALITY: урон от горения — 50% исходного урона заклинания." or "DUALITY: burning damage equals 50% of original spell damage.")
  token("DOTA_Tooltip_ability_lc_statue_path_cooldown_by_ult",lang==1 and "ПЕРЕЗАРЯДКА ПО РАНГУ УЛЬТЫ:" or "COOLDOWN BY ULTIMATE RANK:")
  token("DOTA_Tooltip_ability_nevermore_necromastery_Description",lang==1 and
    string.format("Shadow Fiend получает %g душу за попадание атакой и %g души за успешный Shadowraze. Один койл даёт души один раз за применение, независимо от числа целей. Души за убийства не начисляются. При смерти теряется %g%% душ. Урон за душу и максимальное число душ берутся из обычной Necromastery.",B.sf.souls.per_attack,B.sf.souls.per_raze,B.sf.souls.death_loss*100) or
    string.format("Shadow Fiend gains %g soul per landed attack and %g souls per successful Shadowraze. One raze grants souls once per cast regardless of target count. Kills grant no souls. Death loses %g%% of souls. Native damage per soul and soul capacity are preserved.",B.sf.souls.per_attack,B.sf.souls.per_raze,B.sf.souls.death_loss*100))
  token("DOTA_Tooltip_ability_pa_phantom_execution_Note0",lang==1 and "Каждое применение Stifling Dagger сокращает оставшуюся перезарядку на %path_hit_cdr% сек. Обычные криты Coup de Grace сохраняются." or "Each Stifling Dagger cast reduces the remaining cooldown by %path_hit_cdr% seconds. Native Coup de Grace critical strikes are preserved.")
  local ring=B.sf.requiem_magical
  token("DOTA_Tooltip_ability_nevermore_requiem_Note1",(lang==1 and "DUALITY, магический путь: 3 кольца радиусом 300/500/700 через 0.6/1.2/1.8 сек. Дополнительный урон за кольцо: " or "DUALITY magical path: 3 rings at radius 300/500/700 after 0.6/1.2/1.8 seconds. Bonus damage per ring: ")..joined(ring.ring_damage)..(lang==1 and ". Страх сквозь невосприимчивость: " or ". Fear through debuff immunity: ")..joined(ring.immune_fear).." s.")
  token("DOTA_Tooltip_ability_nevermore_requiem_Note2",lang==1 and "Круговые койлы накладывают накопительный эффект Shadowraze и учитывают его бонусный урон. Каждое попавшее кольцо даёт 2 души один раз, независимо от числа целей." or "Circular razes apply the stacking Shadowraze debuff and benefit from its bonus damage. Each successful ring grants 2 souls once, regardless of target count.")
  for name in pairs(abilities) do
    local value=s:match('"DOTA_Tooltip_ability_'..name..'_Description"%s*"([^"]*)"')
    if value then token("DOTA_Tooltip_ability_"..name.."_SummaryDescription",value) end
  end
  save(p,old,s)
end
print("Native ability details and RU/EN tokens synchronized")

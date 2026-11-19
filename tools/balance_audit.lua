-- Reproducible upper-bound ability audit, NOT a match win-rate simulator.
-- Optional first argument: directory with a saved rift/data tree (old balance).
package.path="game/scripts/vscripts/?.lua;"..package.path
local legacy=arg[1] and arg[1]~=""
if legacy then package.path=arg[1].."/?.lua;"..package.path end
local B=require("rift.data.hero_balance")
local E=require("rift.data.expansion")
local P=require("rift.core.progression")
local Math=require("rift.core.path_math")
local U=require("rift.data.upgrades")
local learned={true,true,true,true,true,true,true,true} -- level 30 ceiling
local heroes={};for hero in pairs(B.progression.heroes)do heroes[#heroes+1]=hero end;table.sort(heroes)
print("hero,path,rank,loadout,raw_path_damage,cooldown_before_items,cooldown_at_25pct_item_cdr,duration,extra,notes")
for _,hero in ipairs(heroes)do for _,path in ipairs({"physical","magical"})do
 local def=B.progression.heroes[hero][path]
 for rank=1,3 do for _,full in ipairs({false,true})do
  local bonus=full and P.total(def,learned,true,true)or{}
  if full then for _,u in ipairs(U)do
   if u.status=="implemented"and (u.hero==hero or u.hero=="universal")and(u.required_direction=="any"or u.required_direction==path)then
    for k,v in pairs(u.values_by_rank or{})do bonus[k]=(bonus[k]or 0)+v[#v]end
   end
  end end
  -- Fixed scenario for comparison: identical incoming stats for all paths.
  -- Does not include item attribute gains, native QWE, armor, MR or spell amp.
  local stats={attack=({100,180,300})[rank]+(bonus.attack_damage or 0),strength=({40,80,140})[rank],
   intellect=({40,80,140})[rank],agility=({40,80,140})[rank],attack_speed=({130,220,350})[rank]+(bonus.attack_speed or 0),
   mana_regen=({5,12,25})[rank]+(bonus.mana_regen or 0)}
  local aps=({1,1.8,3})[rank];local raw,cd,duration,extra,note=0,0,0,0,""
  local d=E.abilities[def.ult]
  local flat=0
  if d then
   d=P.profile(d,bonus,B.progression);cd=Math.rank(d.cooldown,rank)
   duration=d.duration and Math.rank(d.duration,rank)or((d.ticks or 1)-1)*(d.interval or 0)
   local hits=d.ticks or 1
   if d.mode=="stance"then hits=math.floor(duration*aps/d.every);note="bonus procs only; continuous hero attacks"
   elseif d.mode=="sleight"then hits=1;note="one real attack per victim; native attack procs excluded"
   elseif d.mode=="tether"then note="target stays within leash"
   else note="all pulses connect; line at maximum distance"end
   for i=1,hits do raw=raw+Math.damage(d,rank,stats,i,1)end
   extra=hits
  elseif def.ult=="sf_requiem_physical"then
   local q=B.sf.requiem_physical;cd=q.cooldown[rank];flat=bonus.requiem_cooldown_reduction or 0
   duration=q.duration+(bonus.sf_duration or 0)
   local regen=math.max(.5,q.sphere_regen[rank]-(bonus.sphere_regen_reduction or 0))
   extra=math.min(math.floor(aps*duration),q.spheres+math.floor((duration-.001)/regen))
   raw=extra*q.sphere_damage_fraction*stats.attack*(1+(bonus.sphere_damage_pct or 0)/100)
   note="sphere bonus only; no Shadowraze/native attacks"
  elseif def.ult=="nevermore_requiem"then
   cd=({120,110,100})[rank] -- installed 2026-11-16; native Scepter -30 kept separate below
   if full then cd=cd-30 end
   raw=3*(B.sf.requiem_magical.ring_damage[rank]+(bonus.ring_damage_bonus or 0));duration=1.8;extra=3
   note="ring bonus only; native Requiem and Shadowraze stacking excluded"
  elseif def.ult=="pa_phantom_execution"then
   cd=B.pa.execution_physical.cooldown[rank];flat=bonus.spirit_cooldown_reduction or 0
   raw=stats.attack*(B.pa.execution_physical.crit_fallback[rank]+(bonus.spirit_crit_bonus or 0))/100
   note="guaranteed spirit hit; attack and dagger CDR excluded"
  elseif def.ult=="pa_storm_charge"then
   local q=B.pa.storm_magical;cd=q.dagger_cooldown
   extra=math.min(q.chain_chance_cap or 1,q.chain_chance[rank]+(bonus.chain_chance_bonus_pct or 0)/100)
   raw=(q.chain_damage[rank]+(bonus.chain_damage_bonus or 0))*extra
   note="expected lightning per victim; requires both daggers; attacks excluded"
  elseif def.ult=="lc_duel_physical"then
   cd=B.lc.duel_physical.cooldown[rank];flat=bonus.duel_cooldown_reduction or 0;duration=10
   raw=math.floor(duration*aps*.9)*stats.attack*(1+(bonus.champion_damage_pct or 0)/100)
   extra=1+(bonus.champion_health_pct or 0)/100;note="warrior attacks; owner attacks absent; extra=HP multiplier"
  elseif def.ult=="lc_statue"then
   cd=B.lc.statue.cooldown[rank];flat=bonus.statue_cooldown_reduction or 0;duration=10
   raw=4*(B.lc.statue.arrow_damage[4]+(bonus.statue_arrow_bonus or 0));extra=4
   note="one ray per salvo per victim; hit refunds and earned amp excluded"
  elseif def.ult=="ta_psionic_crystal"then
   cd=B.ta.crystal_physical.cooldown[rank];flat=bonus.crystal_cooldown_reduction or 0
   duration=B.ta.crystal_physical.lifetime+(bonus.crystal_lifetime or 0);extra=B.ta.crystal_physical.durability+(bonus.crystal_durability or 0)
   raw=extra*stats.attack;note="all owner hits; max native Psi Blades; Meld/crits excluded"
  elseif def.ult=="ta_psionic_blast"then
   cd=B.ta.trap_magical.cooldown[rank];raw=B.ta.trap_magical.damage[rank]+(bonus.blast_damage_bonus or 0)
   note="blast only; QWE waves and Refraction excluded"
  else error("unhandled path "..def.ult)end
  if legacy then cd=P.cooldown(math.max(1,cd-flat),bonus,B.progression)
  else cd=P.cooldown(cd,bonus,B.progression,flat)end
  -- PA magical cooldown belongs to native-derived Q, not the passive R.
  if def.ult=="pa_storm_charge"then cd=B.pa.storm_magical.dagger_cooldown end
  print(string.format("%s,%s,%d,%s,%.2f,%.3f,%.3f,%.2f,%.3f,%s",hero:gsub("npc_dota_hero_",""),path,rank,full and"ceiling30"or"base",raw,cd,cd*.75,duration,extra,note))
 end end
end end

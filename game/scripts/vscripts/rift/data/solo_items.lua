-- Owner-authorized solo item redesign, 2026-11-16. Native prices/components
-- verified against the installed pak01 scripts/npc/items.txt. PD tuning.
local I={items={},recipes={}}
local function item(name,cost,family,stats,active)
 I.items["item_"..name]={cost=cost,family=family or name,stats=stats or{},active=active}
end
item("glimmer_cape",2150,nil,{all_stats=10,magic_resistance=18},
 {cooldown=20,mana=75,duration=6,magic_resistance=10})
item("invis_sword",3250,"shadow_weapon",{all_stats=10,attack_damage=25,attack_speed=35},
 {cooldown=25,mana=75,duration=6,move_speed_pct=20,hit_damage=120})
item("silver_edge",5700,"shadow_weapon",{all_stats=10,attack_damage=60,attack_speed=35},
 {cooldown=23,mana=75,duration=6,move_speed_pct=20,hit_damage=175,break_duration=4})
item("pipe",3725,nil,{magic_resistance=25,health_regen=12},
 {cooldown=45,mana=125,duration=8,magic_resistance=15,barrier=450,damage_type="magical"})
item("crimson_guard",3725,nil,{health=300,armor=7,health_regen=10,attack_block=40,block_chance=60},
 {cooldown=35,mana=75,duration=6,attack_block=70})
item("pavise",1350,"solar",{health=175,mana=175,armor=3},
 {cooldown=20,mana=50,duration=6,barrier=180,damage_type="physical"})
item("solar_crest",2575,"solar",{health=200,mana=200,armor=6,move_speed=20},
 {cooldown=22,mana=75,duration=6,barrier=250,damage_type="physical",attack_speed=35})
item("mekansm",1775,"recovery",{armor=5,health_regen=4},
 {cooldown=45,mana=100,heal=275,heal_lockout=20})
item("guardian_greaves",4450,"recovery",{armor=6,health_regen=6,mana=250,mana_regen=2,boots_speed=50},
 {cooldown=40,mana=0,heal=350,heal_max_health_pct=6,heal_pct_cap=250,restore_mana=200,purge=true,heal_lockout=20})
item("vladmir",2200,nil,{armor=4,mana_regen=1.5,attack_damage=20,lifesteal=15})
item("assault",5125,nil,{armor=13,attack_speed=55,enemy_armor=-4,enemy_radius=700})
item("ancient_janggo",1625,"drums",{strength=8,health_regen=3,move_speed=15},
 {cooldown=35,mana=50,duration=6,attack_speed=30,move_speed_pct=10})
item("boots_of_bearing",4225,"drums",{strength=8,health_regen=14,boots_speed=65},
 {cooldown=30,mana=50,duration=6,attack_speed=45,move_speed_pct=12})
item("headdress",425,nil,{health_regen=2.5})
item("buckler",425,nil,{armor=3})
item("ring_of_basilius",425,nil,{mana_regen=1.25})
item("arcane_boots",1500,nil,{boots_speed=45,mana=125,mana_regen=1.25},
 {cooldown=50,mana=0,restore_mana=150})
-- Both replacement components cost 450. Existing item prices stay unchanged.
I.recipes.item_recipe_glimmer_cape={cost=800,result="item_glimmer_cape",components={"item_crown","item_crown","item_shawl"}}
I.recipes.item_recipe_invis_sword={cost=0,result="item_invis_sword",components={"item_claymore","item_blitz_knuckles","item_crown","item_crown"}}
I.disabled={item_shadow_amulet=true}
I.lifesteal_creep_fraction=.6
return I

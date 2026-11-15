-- Seven new alpha heroes. All numbers are PLAYTEST_DEFAULT, not owner requirements.
-- Shared execution primitives; each profile defines a different combat loop.
-- Arrays are indexed by ultimate rank 1..3. Native Q/W/E remain available.
local E = { heroes = {}, abilities = {}, balance = {} }
local function hero(key, unit, ult, icon, physical, magical)
  local h = { key = key, unit = "npc_dota_hero_" .. unit, ultimate = ult, icon = icon }
  E.heroes[#E.heroes + 1] = h
  E.balance[key] = { physical = physical, magical = magical }
  for _, path in ipairs({ "physical", "magical" }) do
    local d = E.balance[key][path]
    d.id, d.hero, d.path = "rift_" .. key .. "_" .. path, h.unit, path
    d.icon = d.icon or icon
    E.abilities[d.id] = d
  end
end

hero("axe", "axe", "axe_culling_blade", "axe_culling_blade", {
  mode = "verdict", target = "unit", cooldown = { 38, 32, 26 }, mana = { 100, 125, 150 },
  damage = { 100, 160, 220 }, attack = { 1.6, 1.9, 2.2 }, radius = 300, range = 350,
  missing_health = 0.14, kill_refund = 0.5, cleave = 0.45, particle = "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf",
  sound = "Hero_Axe.Culling_Blade_Success",
}, {
  mode = "zone", target = "point", cooldown = { 55, 48, 41 }, mana = { 150, 175, 200 },
  damage = { 35, 50, 65 }, strength = 0.35, ticks = 6, interval = 0.8, delay = 0.6,
  radius = 420, range = 600, slow = 20, heal_fraction = 0.2, heal_cap = 0.025,
  particle = "particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", sound = "Hero_Axe.Berserkers_Call",
})
hero("lina", "lina", "lina_laguna_blade", "lina_laguna_blade", {
  mode = "line", target = "point", cooldown = { 45, 38, 31 }, mana = { 125, 150, 175 },
  damage = { 45, 65, 85 }, attack = { 0.65, 0.8, 0.95 }, ticks = 3, interval = 0.4, delay = 0.45,
  radius = 100, range = 1050, particle = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf",
  sound = "Hero_Lina.DragonSlave.Cast",
}, {
  mode = "zone", target = "point", cooldown = { 65, 55, 45 }, mana = { 175, 225, 275 },
  damage = { 100, 145, 190 }, intellect = 0.6, ticks = 3, interval = 0.65, delay = 0.9,
  radius = 330, range = 800, slow = 15, expand = 65,
  particle = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", sound = "Ability.LightStrikeArray",
})
hero("juggernaut", "juggernaut", "juggernaut_omni_slash", "juggernaut_omni_slash", {
  mode = "volley", target = "unit", cooldown = { 65, 55, 45 }, mana = { 150, 175, 200 },
  damage = { 20, 30, 40 }, attack = { 0.8, 0.95, 1.1 }, ticks = 5, interval = 0.28,
  radius = 425, range = 450, leash = 850, jump = true,
  particle = "particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_tgt.vpcf", sound = "Hero_Juggernaut.OmniSlash",
}, {
  mode = "orbit", target = "none", cooldown = { 50, 44, 38 }, mana = { 150, 175, 200 },
  damage = { 35, 50, 65 }, agility = 0.35, ticks = 10, interval = 0.5, radius = 375, range = 0, slow = 18,
  particle = "particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf", sound = "Hero_Juggernaut.BladeFuryStart",
})
hero("cm", "crystal_maiden", "crystal_maiden_freezing_field", "crystal_maiden_freezing_field", {
  mode = "stance", target = "none", cooldown = { 42, 36, 30 }, mana = { 100, 125, 150 },
  damage = { 40, 60, 80 }, attack = { 0.6, 0.8, 1.0 }, duration = 9, every = 3,
  radius = 260, range = 0, attack_range = 140, slow = 25, root = 0.7,
  particle = "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf", sound = "Hero_Crystal.CrystalNova",
}, {
  mode = "zone", target = "point", cooldown = { 70, 60, 50 }, mana = { 200, 250, 300 },
  damage = { 35, 50, 65 }, intellect = 0.3, ticks = 8, interval = 0.6, delay = 0.75,
  radius = 300, expand = 30, range = 650, slow = 30, root_every = 3, root = 0.65,
  particle = "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", sound = "Hero_Crystal.CrystalNova",
})
hero("wr", "windrunner", "windrunner_focusfire", "windrunner_focusfire", {
  mode = "stance", target = "none", cooldown = { 45, 38, 31 }, mana = { 100, 125, 150 },
  damage = { 15, 25, 35 }, attack = { 0.45, 0.6, 0.75 }, duration = 8, every = 2,
  line = true, radius = 100, range = 900,
  particle = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf", sound = "Ability.Powershot",
}, {
  mode = "line", target = "point", cooldown = { 50, 43, 36 }, mana = { 150, 175, 200 },
  damage = { 65, 95, 125 }, intellect = 0.55, ticks = 3, interval = 0.55, delay = 0.5,
  radius = 150, range = 1200, slow = 35, distance_bonus = 0.65,
  particle = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf", sound = "Ability.Powershot",
})
hero("sven", "sven", "sven_gods_strength", "sven_gods_strength", {
  mode = "stance", target = "none", cooldown = { 55, 48, 41 }, mana = { 125, 150, 175 },
  damage = { 40, 70, 100 }, attack = { 1.0, 1.2, 1.4 }, duration = 9, every = 3,
  radius = 340, range = 0,
  particle = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf", sound = "Hero_Sven.GreatCleave",
}, {
  mode = "zone", target = "point", cooldown = { 60, 52, 44 }, mana = { 150, 200, 250 },
  damage = { 70, 100, 130 }, strength = 0.65, ticks = 4, interval = 0.7, delay = 0.8,
  radius = 350, range = 650, stun = 0.75,
  particle = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf", sound = "Hero_Sven.StormBoltImpact",
})
hero("pudge", "pudge", "pudge_dismember", "pudge_dismember", {
  mode = "tether", target = "unit", cooldown = { 45, 38, 31 }, mana = { 125, 150, 175 },
  damage = { 55, 75, 95 }, attack = { 0.35, 0.45, 0.55 }, ticks = 6, interval = 0.5,
  radius = 0, range = 300, leash = 575, slow = 25, heal_fraction = 0.35, heal_cap = 0.04,
  particle = "particles/units/heroes/hero_pudge/pudge_dismember.vpcf", sound = "Hero_Pudge.Dismember",
}, {
  mode = "zone", target = "point", cooldown = { 60, 52, 44 }, mana = { 150, 175, 200 },
  damage = { 35, 50, 65 }, strength = 0.35, ticks = 7, interval = 0.65, delay = 0.6,
  radius = 425, range = 550, slow = 22, ramp = 0.12, heal_fraction = 0.25, heal_cap = 0.025,
  heal_inside = true,
  particle = "particles/units/heroes/hero_pudge/pudge_rot.vpcf", sound = "Hero_Pudge.Rot",
})

return E

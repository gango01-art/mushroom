-- Native inherited tooltip fields, verified in installed Dota 2026-11-16.
-- scripts/npc/items.txt SHA256 04c432155f6c89c7277a76c8cfb72ff96a6b0d908969a03efc15f41ac1694d6e
-- These fields are zeroed to remove stale vanilla stat/ability rows.
return {
 item_glimmer_cape={"initial_fade_delay","secondary_fade_delay","active_movement_speed","duration","bonus_magical_armor","barrier_block"},
 item_invis_sword={"bonus_damage","bonus_attack_speed","windwalk_duration","windwalk_movement_speed","windwalk_fade_time","windwalk_bonus_damage"},
 item_silver_edge={"bonus_damage","bonus_attack_speed","bonus_strength","bonus_intellect","bonus_mana_regen","windwalk_duration","windwalk_movement_speed","windwalk_fade_time","windwalk_bonus_damage","backstab_duration","max_movement_speed","visibility_radius"},
 item_pipe={"health_regen","magic_resistance","add_nostack_debuff","aura_health_regen","magic_resistance_aura","aura_radius","barrier_block","barrier_duration","barrier_radius","bonus_all_stats","barrier_block_creep"},
 item_crimson_guard={"bonus_health","bonus_health_regen","bonus_armor","block_damage_melee","block_damage_ranged","block_chance","duration","bonus_aoe_radius","block_damage_active","block_chance_active","block_penalty_ranged","max_hp_pct"},
 item_pavise={"bonus_armor","bonus_mana","bonus_health","duration","absorb_amount"},
 item_solar_crest={"bonus_armor","bonus_all_stats","self_movement_speed","bonus_mana","bonus_health","target_movement_speed","target_attack_speed","target_armor","duration","absorb_amount"},
 item_mekansm={"bonus_armor","aura_radius","aura_health_regen","heal_amount","heal_radius"},
 item_guardian_greaves={"bonus_movement","bonus_armor","bonus_mana","mana_regen","aura_health_regen","aura_mana_regen","aura_radius","aura_health_regen_bonus","aura_bonus_threshold","replenish_health","replenish_mana","replenish_radius","max_health_pct_heal_amount"},
 item_vladmir={"armor","mana_regen","armor_aura","mana_regen_aura","lifesteal_aura","damage_aura","lifesteal_self","damage_self","aura_radius","lifesteal_creeps_tooltip"},
 item_assault={"bonus_attack_speed","bonus_armor","aura_radius","aura_attack_speed","aura_positive_armor","aura_negative_armor"},
 item_ancient_janggo={"aura_movement_speed","aura_health_regen","bonus_str","bonus_int","bonus_attack_speed_pct","bonus_movement_speed_pct","duration","radius","charges_tooltip"},
 item_boots_of_bearing={"aura_movement_speed","aura_health_regen","bonus_str","bonus_int","bonus_attack_speed_pct","bonus_movement_speed_pct","duration","radius","bonus_movement_speed","bonus_health_regen","bonus_ms_duration"},
 item_headdress={"health_regen","aura_health_regen","aura_radius"},
 item_buckler={"armor","bonus_aoe_armor","bonus_aoe_radius"},
 item_ring_of_basilius={"mana_regen","aura_mana_regen","aura_radius"},
 item_arcane_boots={"bonus_movement","mana_regen","bonus_mana","aura_mana_regen","aura_radius","replenish_amount","replenish_radius"},
}

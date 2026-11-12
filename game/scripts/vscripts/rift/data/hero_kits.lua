-- Base hero kits applied when the hero first spawns (before any direction).
-- add:   native abilities missing from the current Dota kit that DUALITY keeps
-- order: required order of the first slots (hotkeys follow slot order: Q W E D F R)
return {
  npc_dota_hero_templar_assassin = {
    -- Owner decision 2026-11-12: Refraction stays exactly as in Dota (this client's kit lacks it,
    -- but the ability data exists - OP-006 dump).
    add = { "templar_assassin_refraction" },
    order = { "templar_assassin_refraction", "templar_assassin_meld", "templar_assassin_psi_blades" },
  },
}

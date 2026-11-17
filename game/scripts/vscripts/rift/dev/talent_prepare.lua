local gm=GameRules.RiftArena;local h=PlayerResource:GetSelectedHeroEntity(0)
assert(gm.dev and PlayerResource:GetPlayerCount()==1)
while h:GetLevel()<25 do h:HeroLevelUp(false)end
if not require("rift.engine.progression").definition(h)then
 for _,d in ipairs(require("rift.data.ultimate_directions"))do
  if d.hero_id==h:GetUnitName()and d.direction=="physical"then assert(gm.upgrades.offers:dev_set_direction(0,d.id));gm.upgrades:ProcessEvents();break end
 end
end
h:SetAbilityPoints(4)
print("[RIFT][TALENT_UI] fresh native talents prepared; select by real HUD click")

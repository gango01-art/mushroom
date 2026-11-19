-- Explicit native tooltip/VFX review scene, not part of normal gameplay.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local c=assert(PlayerResource:GetSelectedHeroEntity(gm.lab.owner));c:Stop()
for i=0,16 do local item=c:GetItemInSlot(i);if item then c:RemoveItem(item);UTIL_Remove(item)end end
for _,name in ipairs({"item_boots_of_bearing","item_glimmer_cape","item_pipe","item_solar_crest"})do
 c:AddItemByName(name)
end
print("[RIFT][TOOLTIP_SCENE] inventory slots: Boots / Glimmer / Pipe / Solar")

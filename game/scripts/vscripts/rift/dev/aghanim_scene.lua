-- Reload explicitly to advance screenshot scenes. Single-player lab only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local scenes={{"templar_assassin","magical"},{"templar_assassin","physical"},{"nevermore","magical"},{"legion_commander","magical"},{"axe","physical"}}
gm._rift_agh_scene=(gm._rift_agh_scene or 0)%#scenes+1
local s=scenes[gm._rift_agh_scene];local lab=gm.lab;lab:Clear();lab.free=false;assert(lab:Select("npc_dota_hero_"..s[1],s[2]))
local phase="load";local deadline=GameRules:GetGameTime()+40
GameRules:GetGameModeEntity():SetContextThink("rift_aghanim_scene",function()
 if GameRules:GetGameTime()>deadline then print("[RIFT][AGH_SCENE] ERROR timeout");return nil end
 if lab.loading then return .1 end
 local c=PlayerResource:GetSelectedHeroEntity(lab.owner)
 if phase=="load"then c:AddItemByName("item_ultimate_scepter");c:AddItemByName("item_aghanims_shard");phase="items";return .3 end
 local A=require("rift.engine.aghanim")
 if not A.scepter(c)or not A.shard(c)then return .1 end
 print("[RIFT][AGH_SCENE] READY "..s[1].." "..s[2].." nativeScepter="..tostring(c:HasScepter()));return nil
end,.1)

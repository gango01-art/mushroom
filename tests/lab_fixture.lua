-- Server fixture with real registry, offers, direction adapter and lab modules.
local S=require("engine_stub")
local F={}
local basic={
 npc_dota_hero_sven={"sven_storm_bolt","sven_warcry","sven_great_cleave"},
 npc_dota_hero_juggernaut={"juggernaut_blade_fury","juggernaut_healing_ward","juggernaut_blade_dance"},
 npc_dota_hero_phantom_assassin={"phantom_assassin_stifling_dagger","phantom_assassin_phantom_strike","phantom_assassin_blur"},
 npc_dota_hero_templar_assassin={"templar_assassin_refraction","templar_assassin_meld","templar_assassin_psi_blades"},
 npc_dota_hero_legion_commander={"legion_commander_overwhelming_odds","legion_commander_press_the_attack","legion_commander_moment_of_courage"},
 npc_dota_hero_nevermore={"nevermore_shadowraze1","nevermore_shadowraze2","nevermore_shadowraze3"},
}
function F.setup()
 local state={count=1,host=true,listeners={},messages={},selected={},published=0,summons={}}
 local stub=S.install()
 _G.PrecacheUnitByNameAsync=function(name,callback,pid)
  state.precaches=state.precaches or {};state.precaches[#state.precaches+1]={hero=name,pid=pid}
  if state.defer_precache then state.precache_callback=callback else callback() end
 end
 _G.ABILITY_TYPE_ULTIMATE=1
 local defs=require("rift.data.ultimate_directions")
 local ultimate,native={},{}
 for _,d in ipairs(defs) do
  native[d.hero_id]=d.ultimate_ability_id;ultimate[d.ultimate_ability_id]=true
  for _,swap in ipairs(d.swaps or {}) do if swap.from==d.ultimate_ability_id then ultimate[swap.to]=true end end
 end
 local function hero(name,pid,team,pos)
  local h=stub.hero(name,pid,team,pos or Vector(0,0,0),{Level=3,MaxHealth=2500,Health=2500,MaxMana=1500,Mana=1500})
  h._rift_lab_target,h._rift_lab_credited=false,false
  h.slots,h.inventory={},{}
  function h:GetAbilityCount() return 24 end
  function h:GetAbilityByIndex(i) return self.slots[i] end
  function h:AddAbility(n)
   local a=stub.ability(0);a.name=n;a.hidden=false
   function a:GetAbilityName() return self.name end
   function a:GetMaxLevel() return ultimate[n] and 3 or 4 end
   function a:GetAbilityType() return ultimate[n] and ABILITY_TYPE_ULTIMATE or 0 end
   function a:SetLevel(l) self.level=l end
   function a:SetActivated(v) self.active=v end
   function a:IsHidden() return self.hidden end
   function a:SetHidden(v) self.hidden=v end
   function a:GetCooldown() return 60 end
   function a:GetAbilityIndex() for i,x in pairs(h.slots) do if x==self then return i end end end
   for i=0,23 do if not h.slots[i] then h.slots[i]=a;break end end
   self.abilities[n]=a;return a
  end
  function h:RemoveAbility(n) local a=self.abilities[n];if a then self.slots[a:GetAbilityIndex()]=nil;self.abilities[n]=nil end end
  function h:SwapAbilities(n1,n2,e1,e2)
   local a,b=self.abilities[n1],self.abilities[n2];local i,j=a:GetAbilityIndex(),b:GetAbilityIndex()
   self.slots[i],self.slots[j]=b,a;a.hidden,b.hidden=not e1,not e2
  end
  function h:HeroLevelUp() self.props.Level=self.props.Level+1 end
  function h:GetItemInSlot(i) return self.inventory[i] end
  function h:RemoveItem(item) for i,v in pairs(self.inventory) do if v==item then self.inventory[i]=nil end end end
  function h:Purge() end
  function h:RespawnHero() self.dead=false end
  local names=basic[name] or {"native_q","native_w","native_e"}
  for _,n in ipairs(names) do h:AddAbility(n) end
  h:AddAbility("generic_hidden");h:AddAbility("generic_hidden2");h:AddAbility(native[name] or "axe_culling_blade")
  return h
 end
 state.make_hero=hero
 state.selected[0]=hero("npc_dota_hero_phantom_assassin",0,2)
 local p={GetPlayerID=function() return 0 end}
 _G.PlayerResource={
  GetPlayerCount=function() return state.count end,GetPlayer=function(_,pid) return pid==0 and p or nil end,
  GetSelectedHeroEntity=function(_,pid) return state.selected[pid] end,
  ReplaceHeroWith=function(_,pid,name) local h=hero(name,pid,2);state.selected[pid]=h;return h end,
  GetTeam=function() return 2 end,SetCameraTarget=function() end,
 }
 _G.CreateUnitByName=function(name,pos,_,_,_,team)
  local h=hero(name,-1,team,pos);stub.created[#stub.created+1]=h;return h
 end
 _G.GridNav={IsTraversable=function() return true end,IsBlocked=function() return false end}
 _G.Entities={FindAllByClassname=function() return state.summons end}
 _G.GameRules.PlayerHasCustomGameHostPrivileges=function() return state.host end
 _G.LoadKeyValues=function() return {auto_demo="0"} end
 _G.ListenToGameEvent=function() end;_G.Dynamic_Wrap=function() return function() end end
 _G.RandomInt=function() return 7 end
 _G.CustomGameEventManager={RegisterListener=function(_,name,fn) state.listeners[name]=fn end,
  Send_ServerToPlayer=function(_,_,name,msg) state.messages[#state.messages+1]={name=name,data=msg} end}
 _G.CustomNetTables={SetTableValue=function(_,table,key,value) state.last={table=table,key=key,value=value} end}
 _G.DOTA_TEAM_BADGUYS=3;_G.DOTA_TEAM_GOODGUYS=2
 local cfg=require("rift.core.config")
 local gm={dev=true,map={fallback=true},players={[0]={initialized=true}},ui={Publish=function() state.published=state.published+1 end},
  relic={DevEnd=function() state.relic_ended=true end},director={state=require("rift.core.match_state").new(cfg)}}
 function gm:Now() return stub.now end
 gm.director.state:advance("ACTIVE",0)
 gm.upgrades=require("rift.engine.upgrade_bridge").new(gm)
 gm.upgrades:AddPlayer(0,state.selected[0])
 gm.lab=require("rift.engine.laboratory").new(gm)
 _G.GameRules.RiftArena=gm
 state.gm,state.stub=gm,stub
 return state
end
return F

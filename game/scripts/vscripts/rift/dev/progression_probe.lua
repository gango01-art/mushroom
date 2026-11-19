-- Explicit native integration probe: 22 fresh hero/path instances, native
-- talent learning and real Scepter/Shard inventory. Single-player lab only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local P=require("rift.engine.progression")
local B=require("rift.data.hero_balance").progression
local C=require("rift.core.progression")
local cases={}
for hero in pairs(B.heroes)do for _,path in ipairs({"physical","magical"})do cases[#cases+1]={hero=hero,path=path}end end
-- Physical -> magical specifically exercises ReplaceHeroWith copying learned
-- default physical talent names before the new direction is initialized.
table.sort(cases,function(a,b)return a.hero==b.hero and a.path>b.path or a.hero<b.hero end)
local lab=gm.lab;lab:Clear();local index=0;local phase="next";local deadline,c,item,learning
local picks={1,3,5,7}
local function train(a)
 -- Unit-level/scripted TRAIN orders ignore custom attributes in this client.
 -- Exercise the native ability upgrade callback; spend the lab point explicitly.
 c:SetAbilityPoints(math.max(0,c:GetAbilityPoints()-1));a:UpgradeAbility(true)
end
GameRules:GetGameModeEntity():SetContextThink("rift_progression_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   index=index+1
   if not cases[index]then print("[RIFT][PROGRESSION] DONE 22/22");return nil end
   local x=cases[index];lab.rank=3;assert(lab:Select(x.hero,x.path));phase="load";deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"precache timeout")
   if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner)
   local x=cases[index];assert(c:GetUnitName()==x.hero,"wrong hero")
   local def,path=P.definition(c);assert(def and path==x.path,"path state missing")
   local attributes=0
   for slot=0,c:GetAbilityCount()-1 do
    local a=c:GetAbilityByIndex(slot)
    if a and a:GetAbilityType()==ABILITY_TYPE_ATTRIBUTES then attributes=attributes+1 end
   end
   assert(attributes==8,"native stat branch needs exactly 8 attributes, got "..attributes)
   local first
   for i=1,8 do
    local a=c:FindAbilityByName(P.name(x.hero,path,i));assert(a,"talent missing "..i)
    first=first or a:GetAbilityIndex()
    assert(a:GetAbilityIndex()==first+i-1,"talent order "..i.."="..a:GetAbilityIndex())
    assert(a:GetAbilityType()==ABILITY_TYPE_ATTRIBUTES,"not a native attribute talent")
   end
   if x.hero=="npc_dota_hero_nevermore"and x.path=="physical"then
    local a=c:FindAbilityByName(def.ult)
    for r=1,3 do a:SetLevel(r);print("[RIFT][PROGRESSION] SF R"..r.." cooldown="..a:GetCooldown(-1))end
    a:SetLevel(3)
   end
   c:SetAbilityPoints(4)
   learning=1;deadline=now+2;phase="learn"
   train(c:FindAbilityByName(P.name(x.hero,path,picks[learning])))
  elseif phase=="learn"then
   local x=cases[index];local a=c:FindAbilityByName(P.name(x.hero,x.path,picks[learning]))
   if a:GetLevel()~=1 then assert(now<deadline,"native upgrade failed "..picks[learning].." required="..a:GetHeroLevelRequiredToUpgrade().." hero="..c:GetLevel().." points="..c:GetAbilityPoints());return .1 end
   learning=learning+1
   if picks[learning]then
    deadline=now+2;train(c:FindAbilityByName(P.name(x.hero,x.path,picks[learning])));return .2
   end
   c:SetAbilityPoints(1)
   train(c:FindAbilityByName(P.name(x.hero,x.path,2)));phase="opposite";return .3
  elseif phase=="opposite"then
   local x=cases[index]
   assert(c:FindAbilityByName(P.name(x.hero,x.path,2)):GetLevel()==0,"opposite talent allowed at 25")
   assert(c:GetAbilityPoints()==1,"rejected talent consumed a point")
   c:AddItemByName("item_ultimate_scepter")
   item=c:AddItemByName("item_aghanims_shard")
   deadline=now+5;phase="items"
  elseif phase=="items"then
   if not require("rift.engine.aghanim").scepter(c)or not require("rift.engine.aghanim").shard(c)then assert(now<deadline,"native items missing");return .1 end
   local x=cases[index];local expected=C.total(B.heroes[x.hero][x.path],{true,false,true,false,true,false,true,false},true,true)
   local actual=P.totals(c)
   for k,v in pairs(expected)do assert(math.abs((actual[k]or 0)-v)<.00001,"bonus mismatch "..k)end
   print("[RIFT][PROGRESSION] PASS "..x.hero.." "..x.path.." talents=4 scepter=true shard=true")
   phase="next"
  end
  return .2
 end)
 if not ok then print("[RIFT][PROGRESSION] ERROR case="..index.." "..tostring(result));return nil end
 return result
end,.2)

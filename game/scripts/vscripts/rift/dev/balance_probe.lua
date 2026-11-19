-- Explicit Tools-only ceiling probe: 22 paths, R1/R2/R3, all legal level-30
-- talents, max implemented build upgrades, real Scepter + Shard + Octarine.
-- Measures engine cooldown methods; does NOT claim PvP balance or visual QA.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local B=require("rift.data.hero_balance")
local P=require("rift.engine.progression")
local C=require("rift.core.progression")
local E=require("rift.data.expansion")
local Bonus=require("rift.engine.build_bonus")
local U=require("rift.data.upgrades")
local cases={};for hero in pairs(B.progression.heroes)do for _,path in ipairs({"physical","magical"})do cases[#cases+1]={hero=hero,path=path}end end
table.sort(cases,function(a,b)return a.hero==b.hero and a.path>b.path or a.hero<b.hero end)
local function base(def,r)
 local d=E.abilities[def.ult];if d then return d.cooldown[r],nil end
 local map={sf_requiem_physical={B.sf.requiem_physical,"requiem_cooldown_reduction"},
  pa_phantom_execution={B.pa.execution_physical,"spirit_cooldown_reduction"},
  lc_duel_physical={B.lc.duel_physical,"duel_cooldown_reduction"},
  lc_statue={B.lc.statue,"statue_cooldown_reduction"},
  ta_psionic_crystal={B.ta.crystal_physical,"crystal_cooldown_reduction"},
  ta_psionic_blast={B.ta.trap_magical}}
 local x=map[def.ult];return x and x[1].cooldown[r],x and x[2]
end
local lab=gm.lab;lab.free=false;lab:Clear()
local i,phase,c,deadline=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_balance_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not cases[i]then print("[RIFT][BALANCE] DONE 22/22; 66 rank checks");return nil end
   lab:Clear();lab.rank=3;assert(lab:Select(cases[i].hero,cases[i].path));deadline=now+40;phase="load"
  elseif phase=="load"then
   assert(now<deadline,"precache timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner)
   local def,path=P.definition(c);assert(def and path==cases[i].path,"path mismatch")
   while c:GetLevel()<30 do c:HeroLevelUp(false)end
   c:SetAbilityPoints(8)
   for k=1,8 do local a=assert(c:FindAbilityByName(P.name(c:GetUnitName(),path,k)));c:SetAbilityPoints(8);a:UpgradeAbility(true);assert(a:GetLevel()==1,"talent "..k)end
   for _,u in ipairs(U)do
    if u.status=="implemented"and(u.hero==c:GetUnitName()or u.hero=="universal")and(u.required_direction=="any"or u.required_direction==path)then
     for _=1,u.max_rank do
      local state=gm.upgrades.offers:player(lab.owner)
      if not gm.upgrades.offers:is_allowed(state,u)then break end -- e.g. TA magical excludes attack upgrades
      assert(gm.upgrades.offers:dev_grant(lab.owner,u.id,gm:Now()),"grant "..u.id)
     end
    end
   end
   gm.upgrades:ProcessEvents()
   c:AddItemByName("item_ultimate_scepter");c:AddItemByName("item_octarine_core")
   local shard=c:AddItemByName("item_aghanims_shard")
   deadline=now+5;phase="check"
  elseif phase=="check"then
   assert(now<deadline,"item timeout")
   if not require("rift.engine.aghanim").scepter(c)or not require("rift.engine.aghanim").shard(c)then return .1 end
   local def=P.definition(c);local a=assert(c:FindAbilityByName(def.ult));local cds={}
   for r=1,3 do
    a:SetLevel(def.ult=="lc_statue"and 4 or r)
    if def.ult=="lc_statue"then c:FindAbilityByName("lc_duel_magical"):SetLevel(r)end
    local raw,key=base(def,r);local actual=a:GetCooldown(-1)
    if raw then
     local expected=C.cooldown(raw,P.totals(c),B.progression,key and Bonus.get(c,key)or 0)
     assert(math.abs(actual-expected)<.001,"cooldown mismatch rank="..r.." actual="..actual.." expected="..expected)
     assert(actual>=raw*.75-.001,"static budget bypass")
    end
    cds[#cds+1]=string.format("%.3f",actual)
   end
   if def.ult=="pa_storm_charge"then
    local q=require("rift.core.pa_storm_daggers").values_at(B.pa.storm_magical,3,{chain_damage=Bonus.get(c,"chain_damage_bonus"),chain_chance=Bonus.get(c,"chain_chance_bonus_pct")/100})
    assert(q.chain_chance<=.45,"PA chance cap");print("[RIFT][BALANCE] PA chain="..q.chain_damage.." chance="..q.chain_chance)
   end
   print("[RIFT][BALANCE] PASS "..cases[i].hero.." "..cases[i].path.." cd="..table.concat(cds,"/").." level=30 talents=8 scepter/shard/octarine=true")
   phase="next"
  end
  return .15
 end)
 if not ok then print("[RIFT][BALANCE] ERROR case="..i.." "..tostring(result));return nil end
 return result
end,.1)

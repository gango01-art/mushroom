-- Explicit native smoke runner. Console: script require("rift.dev.playtest").run()
-- Never runs in normal matches. Reports observations, not visual correctness.
local M={}
function M.run()
  local gm=GameRules.RiftArena
  assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player Tools laboratory required")
  assert(not M.running,"playtest already running")
  M.running=true
  M.previous_proc=require("rift.engine.pa_storm").store().force_proc
  local lab=gm.lab
  lab.free=false;lab:Clear()
  local defs=require("rift.data.ultimate_directions")
  local index,phase,deadline,spec,c,a,u,v,before,at=0,"next",0
  local function log(s) print("[RIFT][PLAYTEST] "..s) end
  local function order(ability,kind,target,point)
    ExecuteOrderFromTable({UnitIndex=c:entindex(),AbilityIndex=ability:entindex(),OrderType=kind,
      TargetIndex=target and target:entindex() or nil,Position=point,Queue=false})
  end
  local function step()
    if not M.running then return nil end
    local now=GameRules:GetGameTime()
    if phase=="next" then
      index=index+1;spec=defs[index]
      if not spec then M.stop();log("DONE "..#defs.." paths; inspect damage deltas and console errors separately");return nil end
      lab:Clear();lab.rank=3
      local ok,why=lab:Select(spec.hero_id,spec.direction)
      assert(ok,why);phase="loading";deadline=now+40
    elseif phase=="loading" then
      assert(now<deadline,"hero load timed out")
      if lab.loading then return .1 end
      c=PlayerResource:GetSelectedHeroEntity(lab.owner)
      assert(c and not c:IsNull() and c:GetUnitName()==spec.hero_id,"wrong hero")
      assert(gm.upgrades:DirectionId(lab.owner)==spec.id,"direction did not apply")
      c:SetForwardVector(Vector(1,0,0));c:Stop()
      assert(lab:Target("immortal"));assert(lab:Target("immortal"))
      u,v=lab.targets[1],lab.targets[2]
      FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(200,0,0),true)
      FindClearSpaceForUnit(v,c:GetAbsOrigin()+Vector(250,55,0),true)
      for _,x in ipairs({u,v}) do
        x:SetBaseMaxHealth(50000);x:CalculateStatBonus(true);x:SetHealth(x:GetMaxHealth())
      end
      before=u:GetHealth()+v:GetHealth()
      local name=spec.ultimate_ability_id
      for _,swap in ipairs(spec.swaps or {}) do if swap.from==name then name=swap.to;break end end
      if spec.id=="pa_storm_daggers" then name="pa_storm_dagger";require("rift.engine.pa_storm").store().force_proc=true end
      if spec.id=="lc_duel_magical" then name="lc_statue" end
      a=assert(c:FindAbilityByName(name),name)
      local radius=a:GetAOERadius()
      local shiva=CreateItem("item_shivas_guard",c,c);c:AddItem(shiva)
      local with_shiva=a:GetAOERadius()
      c:RemoveItem(shiva)
      local gleipnir=CreateItem("item_gungir",c,c);c:AddItem(gleipnir)
      local with_gleipnir=a:GetAOERadius();c:RemoveItem(gleipnir)
      log(string.format("BEGIN %s ability=%s rank=%d radius=%s shiva_radius=%s gleipnir_radius=%s cd=%s current_cd=%s mana=%s hp=%.0f",spec.id,name,a:GetLevel(),tostring(radius),tostring(with_shiva),tostring(with_gleipnir),tostring(a:GetCooldown(a:GetLevel()-1)),tostring(a:GetCooldown(-1)),tostring(a:GetManaCost(a:GetLevel()-1)),before))
      local behavior=a:GetBehaviorInt()
      if bit.band(behavior,DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)~=0 then order(a,DOTA_UNIT_ORDER_CAST_TARGET,u)
      elseif bit.band(behavior,DOTA_ABILITY_BEHAVIOR_POINT)~=0 then order(a,DOTA_UNIT_ORDER_CAST_POSITION,nil,u:GetAbsOrigin())
      else order(a,DOTA_UNIT_ORDER_CAST_NO_TARGET) end
      at=now;phase="casting"
    elseif phase=="casting" then
      if now-at<1 then return .1 end
      if spec.id=="ta_crystal_physical" then
        for _,x in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
          if x:GetUnitName()=="npc_rift_ta_crystal" and x:GetOwner()==c then c:MoveToTargetToAttack(x) end
        end
      elseif spec.id=="sf_requiem_physical" or (require("rift.data.expansion").abilities[a:GetAbilityName()] or {}).mode=="stance" then
        c:MoveToTargetToAttack(u)
      end
      phase="observe"
    elseif phase=="observe" and now-at>=6 then
      local delta=before-u:GetHealth()-v:GetHealth()
      log(string.format("END %s damage_delta=%.1f cooldown=%.2f alive=%s",spec.id,delta,a:GetCooldownTimeRemaining(),tostring(c:IsAlive())))
      c:Stop();phase="next"
    end
    return .1
  end
  GameRules:GetGameModeEntity():SetContextThink("rift_native_playtest",function()
    local ok,result=pcall(step)
    if not ok then M.stop();log("ERROR "..tostring(result));return nil end
    return result
  end,.1)
end
function M.stop() M.running=false;require("rift.engine.pa_storm").store().force_proc=M.previous_proc end
return M

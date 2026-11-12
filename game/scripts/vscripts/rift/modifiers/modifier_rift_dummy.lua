-- DEV ONLY test dummy: a motionless target. Cannot attack, cast, use passives, move or be
-- ordered. Never dies (min health 1, heals back) so it cannot respawn as a live enemy hero
-- without this modifier (OP-020: respawned dummies attacked and killed the tester).
modifier_rift_dummy = modifier_rift_dummy or ((type(class) == "function") and class({}) or {})

function modifier_rift_dummy:IsHidden() return false end
function modifier_rift_dummy:IsPurgable() return false end
function modifier_rift_dummy:IsPurgeException() return false end
function modifier_rift_dummy:RemoveOnDeath() return false end
function modifier_rift_dummy:IsPermanent() return true end
function modifier_rift_dummy:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_rift_dummy:GetTexture() return "item_ward_observer" end

function modifier_rift_dummy:CheckState()
  -- STUNNED: no AI/bot action of any kind. PASSIVES_DISABLED: no Counter Helix back to the tester.
  return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_SILENCED] = true,
           [MODIFIER_STATE_MUTED] = true, [MODIFIER_STATE_ROOTED] = true,
           [MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_PASSIVES_DISABLED] = true }
end

function modifier_rift_dummy:DeclareFunctions() return { MODIFIER_PROPERTY_MIN_HEALTH } end
function modifier_rift_dummy:GetMinHealth() return 1 end

function modifier_rift_dummy:OnCreated()
  if IsServer() then self:StartIntervalThink(3) end
end

-- Keep it a clean target: abilities unlearned, health restored between hits.
function modifier_rift_dummy:OnIntervalThink()
  local u = self:GetParent()
  if not u or u:IsNull() then return end
  for i = 0, u:GetAbilityCount() - 1 do
    local a = u:GetAbilityByIndex(i)
    if a and not a:IsNull() and a:GetLevel() > 0 then a:SetLevel(0) end
  end
  if u:IsAlive() and u:GetHealth() < u:GetMaxHealth() * 0.5 then u:SetHealth(u:GetMaxHealth()) end
end

local assets = {
    Asset("ANIM", "anim/fishbonecrown.zip"),
    Asset("ATLAS", "images/inventoryimages/fishbonecrown.xml"),
    Asset("IMAGE", "images/inventoryimages/fishbonecrown.tex"),
}

local prefabs = {
    "fishbonecrown_equipped",
    "fishbonecrownhatlight",
    "alterguardianhat_projectile",
}

local function onepickill(inst, data)
    if data and data.victim and data.victim:HasTag("epic") then
        local status = inst.components.fishbonecrownstatus
        local armor = inst.components.armor
        if not status or not armor then return end

        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        local lucky = 0
        if owner and owner.components.carneystatus then
            lucky = owner.components.carneystatus.lucky or 0
        end
        local bonus = 2 + math.random(0, math.min(10, lucky))

        local delta = status.CONDITION_PER_BOSS_KILL + bonus
        status:AddMaxCondition(delta)

        status:SyncAll()

        local new_condition = math.min(
                armor.condition + delta,
                status:GetMaxCondition()
        )
        armor:SetCondition(new_condition)

        if inst.components.fueled then
            inst.components.fueled.currentfuel = armor.condition
        end

        status:SyncAll()
    end
end

local function fishbonecrown_activate(inst, owner)
    if inst._is_active then
        return
    end
    inst._is_active = true

    if inst._front == nil then
        inst._front = SpawnPrefab("fishbonecrown_equipped")
        inst._front:OnActivated(owner, true)
    end

    if inst._light == nil then
        inst._light = SpawnPrefab("fishbonecrownhatlight")
        inst._light.entity:SetParent(owner.entity)
    end
end

local function fishbonecrown_deactivate(inst, owner)
    if not inst._is_active then
        return
    end
    inst._is_active = false

    if inst._light ~= nil then
        inst._light:Remove()
        inst._light = nil
    end

    if inst._front ~= nil then
        inst._front:OnDeactivated()
        inst._front = nil
    end
end

local function fishbonecrown_onattackother(inst, owner, data)
    local status = inst.components.fishbonecrownstatus
    if not status or status.lunar_seeds < 5 then return end
    if owner.components.carneystatus and owner.components.carneystatus.gestalt_attack_enabled == false then
        return
    end

    if owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead()) then
        local target = data.target
        if target and target ~= owner and target:IsValid()
                and target.prefab ~= "gestalt_guard_evolved"
                and (target.components.health == nil or not target.components.health:IsDead())
                and not target:HasAnyTag("structure", "wall") then

            if data.weapon ~= nil and data.projectile == nil
                    and (data.weapon.components.projectile ~= nil
                    or data.weapon.components.complexprojectile ~= nil
                    or data.weapon.components.weapon:CanRangedAttack()) then
                return
            end

            local x, y, z = target.Transform:GetWorldPosition()
            local gestalt = SpawnPrefab("alterguardianhat_projectile")

            local status = inst.components.fishbonecrownstatus
            if status then
                local base = gestalt.components.combat.defaultdamage
                local bonus = math.max(0, status.lunar_seeds - 5)
                local total = base + bonus

                local planar_mult = math.min(status.lunar_seeds, 5) / 5

                local planardamage = total * planar_mult
                local physicaldamage = total * (1 - planar_mult)

                gestalt.components.combat:SetDefaultDamage(physicaldamage)
                if planardamage > 0 then
                    gestalt:AddComponent("planardamage")
                    gestalt.components.planardamage:SetBaseDamage(planardamage)
                end
            end

            local r = GetRandomMinMax(3, 5)
            local delta_angle = GetRandomMinMax(-90, 90)
            local angle = (owner:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES
            gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
            gestalt:ForceFacePoint(x, y, z)
            gestalt:SetTargetPosition(Vector3(x, y, z))
            gestalt.components.follower:SetLeader(owner)

            if owner.components.sanity ~= nil then
                owner.components.sanity:DoDelta(-1, true)
            end
        end
    end
end

local function onequip(inst, owner)
    if inst._onepickill_fn ~= nil then
        inst:RemoveEventCallback("killed", inst._onepickill_fn, owner)
        inst._onepickill_fn = nil
    end

    owner.AnimState:OverrideSymbol("swap_hat", "fishbonecrown", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    owner.AnimState:Hide("HEAD")
    owner.AnimState:Show("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAIR")
    owner.AnimState:Show("HEAD_HAT_HAIR")
    owner.AnimState:Hide("HAIRFRONT")
    owner.AnimState:Show("HAIR_HAT_FRINGE")

    inst._onepickill_fn = function(src, data) onepickill(inst, data) end
    inst:ListenForEvent("killed", inst._onepickill_fn, owner)

    local status = inst.components.fishbonecrownstatus
    if status and status.alterguardianhatshards >= status.ALTERGUARDIANHATSHARD_MAX then
        fishbonecrown_activate(inst, owner)
    end

    inst._onattackother_fn = function(_owner, _data) fishbonecrown_onattackother(inst, _owner, _data) end
    inst:ListenForEvent("onattackother", inst._onattackother_fn, owner)
end

local function onunequip(inst, owner)

    fishbonecrown_deactivate(inst, owner)

    owner.AnimState:ClearOverrideSymbol("swap_hat")

    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner.AnimState:Show("HEAD_HAIR")
    owner.AnimState:Hide("HEAD_HAT_HAIR")
    owner.AnimState:Show("HAIRFRONT")
    owner.AnimState:Hide("HAIR_HAT_FRINGE")

    if inst._onepickill_fn ~= nil then
        inst:RemoveEventCallback("killed", inst._onepickill_fn, owner)
        inst._onepickill_fn = nil
    end

    if inst._onattackother_fn ~= nil then
        inst:RemoveEventCallback("onattackother", inst._onattackother_fn, owner)
        inst._onattackother_fn = nil
    end
end

local function SetupEquippable(inst)
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable.dapperness = -10 / 60
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function OnBroken(inst)
    if inst.components.equippable ~= nil then
        inst:RemoveComponent("equippable")
        inst:AddTag("broken")
        inst.components.inspectable.nameoverride = "BROKEN_FISHBONECROWN"
    end
end

local function OnRepaired(inst)
    if inst.components.equippable == nil then
        SetupEquippable(inst)
        inst:RemoveTag("broken")
        inst.components.inspectable.nameoverride = nil
    end
end

local function _onbroken(inst)
    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
    OnBroken(inst)
end

local function OnAddFuel(inst, fuel_item, fuel_value)
    local armor = inst.components.armor
    local status = inst.components.fishbonecrownstatus
    if not armor or not status then return end

    local repair_amount = armor.maxcondition * status.REPAIR_PERCENT_PER_FUEL
    armor:Repair(repair_amount)

    inst.components.fueled.currentfuel = armor.condition

    inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")

    if inst:HasTag("broken") and armor.condition > 0 then
        OnRepaired(inst)
    end

    if inst.components.fueled then
        inst.components.fueled.accepting = (armor:GetPercent() < 1)
    end

    status:SyncAll()
end

local function CustomArmorTakeDamage(self, damage, attacker, weapon, spdamage, ...)
    local old_condition = self.condition
    local ret = self._old_TakeDamage(self, damage, attacker, weapon, spdamage, ...)
    if self.inst.components.fueled and old_condition ~= self.condition then
        self.inst.components.fueled.currentfuel = self.condition
    end
    if self.inst.components.fueled then
        self.inst.components.fueled.accepting = (self:GetPercent() < 1)
    end
    return ret
end

local function ItemTradeTest(inst, item)
    local status = inst.components.fishbonecrownstatus
    if not status then return false end

    if item.prefab == "angelcrystal" then
        return not status:IsMaxAngelCrystals()
    elseif item.prefab == "alterguardianhatshard" then
        return not status:IsMaxAlterguardianhatshards()
    elseif item.prefab == "lunar_seed" then
        return not status:IsMaxLunarSeeds()
    end
    return false
end

local function OnGiven(inst, giver, item, count)
    if not inst or not item then return end
    local status = inst.components.fishbonecrownstatus
    if not status then return end

    local added = false

    if item.prefab == "angelcrystal" and not status:IsMaxAngelCrystals() then
        status:AddAngelCrystal(1)
        added = true
    elseif item.prefab == "alterguardianhatshard" and not status:IsMaxAlterguardianhatshards() then
        status:AddAlterguardianhatshard(1)
        added = true
    elseif item.prefab == "lunar_seed" and not status:IsMaxLunarSeeds() then
        status:AddLunarSeed(1)
        added = true
    end

    if added then
        inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
        status:SyncAll()

        if item.prefab == "alterguardianhatshard"
                and inst.components.equippable:IsEquipped()
                and status.alterguardianhatshards >= 5 then
            fishbonecrown_activate(inst, inst.components.inventoryitem.owner)
        end
    end

end

local function valuecheck(inst)
    local status = inst.components.fishbonecrownstatus
    if status then
        status:SyncAll()
    end
end

local function onsave(inst, data)
    if inst.components.armor then
        data.condition = inst.components.armor.condition
    end

    local status = inst.components.fishbonecrownstatus
    if status then
        data.max_condition = status.max_condition
        data.angel_crystals = status.angel_crystals
        data.alterguardianhatshards = status.alterguardianhatshards
        data.lunar_seeds = status.lunar_seeds
    end
end

local function onload(inst, data)
    local status = inst.components.fishbonecrownstatus
    if status and data then
        status.max_condition = data.max_condition or status.BASE_MAX_CONDITION
        status.angel_crystals = data.angel_crystals or 0
        status.alterguardianhatshards = data.alterguardianhatshards or 0
        status.lunar_seeds = data.lunar_seeds or 0
        status:SyncAll()
    end
    if data and data.condition and inst.components.armor then
        inst.components.armor:SetCondition(data.condition)
    end

    if inst.components.fueled and inst.components.armor then
        inst.components.fueled.currentfuel = inst.components.armor.condition
    end

    local armor = inst.components.armor
    if armor then
        if armor.condition <= 0 and not inst:HasTag("broken") then
            OnBroken(inst)
        elseif armor.condition > 0 and inst:HasTag("broken") then
            OnRepaired(inst)
        end

        if inst.components.fueled then
            inst.components.fueled.accepting = (armor:GetPercent() < 1)
        end
    end

    local status = inst.components.fishbonecrownstatus
    if status then
        status:SyncAll()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("fishbonecrown")
    inst.AnimState:SetBuild("fishbonecrown")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("planardefense")

    MakeInventoryFloatable(inst, "small", 0.15, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:AddSoundEmitter()

    inst._is_active = false
    inst._front = nil
    inst._back = nil
    inst._light = nil

    inst:AddComponent("fishbonecrownstatus")
    local status = inst.components.fishbonecrownstatus

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fishbonecrown.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(status.BASE_MAX_CONDITION, status.DEFENSE_NORMAL)

    local armor = inst.components.armor
    armor._old_TakeDamage = armor.TakeDamage
    armor.TakeDamage = CustomArmorTakeDamage

    armor:SetKeepOnFinished(true)
    armor:SetOnFinished(_onbroken)

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(status.DEFENSE_PLANAR_BASE)

    SetupEquippable(inst)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(status.BASE_MAX_CONDITION)
    inst.components.fueled.currentfuel = status.BASE_MAX_CONDITION
    inst.components.fueled.accepting = false
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGiven

    inst:DoTaskInTime(0, function() valuecheck(inst) end)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst.OnRemoveEntity = function(inst)
        if inst._front ~= nil and inst._front:IsValid() then
            inst._front:Remove()
            inst._front = nil
        end
    end

    return inst
end

local function fishbonecrownhatlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(0.6)
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(4.5)
    inst.Light:SetColour(30/255, 144/255, 255/255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("fishbonecrown", fn, assets, prefabs),
Prefab("fishbonecrownhatlight", fishbonecrownhatlightfn)
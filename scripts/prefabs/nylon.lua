local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_krampus_sack.zip"),
    Asset("ANIM", "anim/ui_nylon_2x5.zip"),
    Asset("ATLAS", "images/inventoryimages/nylon.xml"),
    Asset("ANIM", "anim/nylon.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "nylon", "swap_body")
    inst.components.container:Open(owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.container:Close(owner)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("nylon")
    inst.AnimState:SetBuild("nylon")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/krampuspack"

    inst:AddTag("backpack")
    inst.MiniMapEntity:SetIcon("backpack.png")
    inst:AddTag("waterproofer")
    MakeInventoryFloatable(inst, "med", 0.05, 0.75)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            if inst.replica.container then
                inst.replica.container:WidgetSetup("nylon_sack")
            end
        end
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/nylon.xml"

    local function onpickup(inst)
        if inst._upgrade_task then
            inst._upgrade_task:Cancel()
            inst._upgrade_task = nil
        end
        if inst._pulse_task then
            inst._pulse_task:Cancel()
            inst._pulse_task = nil
        end
        if inst._upgrading then
            inst._upgrading = false
            inst.AnimState:SetBloomEffectHandle("")
            inst.AnimState:SetMultColour(1, 1, 1, 1)
        end
    end
    inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(.2)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("nylon_sack")

    local function IsValidForUpgrade(inst)
        if not TheWorld.state.isfullmoon then return false end
        if inst.components.inventoryitem.owner then return false end
        local container = inst.components.container
        if not container then return false end
        for i = 1, container:GetNumSlots() do
            local item = container:GetItemInSlot(i)
            if not item or item.prefab ~= "voidcloth" then return false end
            if item.components.stackable and item.components.stackable.stacksize > 1 then return false end
        end
        return true
    end

    local function DoUpgrade(inst)
        if inst._upgrading then return end
        inst._upgrading = true

        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(0.75, 0.75, 1, 1)
        inst._pulse_task = inst:DoPeriodicTask(0.15, function()
            local flicker = 0.55 + math.random() * 0.45
            inst.AnimState:SetMultColour(flicker * 0.75, flicker * 0.75, flicker, 1)
        end)

        inst._upgrade_task = inst:DoTaskInTime(4, function()
            inst._upgrade_task = nil
            if inst._pulse_task then
                inst._pulse_task:Cancel()
                inst._pulse_task = nil
            end

            if not inst:IsValid() then
                inst._upgrading = false
                return
            end

            if not IsValidForUpgrade(inst) then
                inst.AnimState:SetBloomEffectHandle("")
                inst.AnimState:SetMultColour(1, 1, 1, 1)
                inst._upgrading = false
                return
            end

            inst:AddTag("NOCLICK")
            local x, y, z = inst.Transform:GetWorldPosition()
            local container = inst.components.container
            if container then
                if container:IsOpen() then container:Close() end
                for i = 1, container:GetNumSlots() do
                    local item = container:RemoveItemBySlot(i)
                    if item then item:Remove() end
                end
            end

            inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/close")
            inst.AnimState:PlayAnimation("upgrade")

            inst:DoTaskInTime(1, function()
                if inst:IsValid() then
                    inst.AnimState:SetBloomEffectHandle("")
                    inst.AnimState:SetMultColour(1, 1, 1, 1)
                end
            end)

            inst:ListenForEvent("animover", function()
                inst:Remove()
                local newpack = SpawnPrefab("nylon_plus")
                if newpack then newpack.Transform:SetPosition(x, y, z) end
            end)
        end)
    end

    inst:WatchWorldState("isfullmoon", function()
        if TheWorld.state.isfullmoon and IsValidForUpgrade(inst) then
            DoUpgrade(inst)
        end
    end)

    inst:ListenForEvent("ondropped", function()
        if inst._upgrade_task then
            inst._upgrade_task:Cancel()
            inst._upgrade_task = nil
        end
        if inst._pulse_task then
            inst._pulse_task:Cancel()
            inst._pulse_task = nil
        end
        if inst._upgrading then
            inst._upgrading = false
            inst.AnimState:SetBloomEffectHandle("")
            inst.AnimState:SetMultColour(1, 1, 1, 1)
        end

        if TheWorld.state.isfullmoon and IsValidForUpgrade(inst) then
            DoUpgrade(inst)
        end
    end)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("nylon", fn, assets)

local assets=
{
    Asset("ANIM", "anim/whiteberet_plus.zip"),
    Asset("ANIM", "anim/ui_beard_3x1.zip"),
    Asset("ATLAS", "images/inventoryimages/whiteberet_plus.xml"),
}

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_hat", "whiteberet_plus", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end

    --inst.components.container:Open(owner)
end

local function onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    inst.components.container:Close(owner)
end

--itemget: data = { slot = in_slot, item = item, src_pos = src_pos, }
--itemlose: data = { slot = slot, prev_item = item }

local function InsulatorCheck(inst, item)
    local amount = 0
    local furs = {
        "pigskin",
        "tentaclespots",
        "slurper_pelt",
        "furtuft",
        "bearger_fur",
        "dragon_scales",
        "shroom_skin",
        "manrabbit_tail",
        "beefalowool",
        "steelwool",
        "beardhair",
        "coontail",
        "goose_feather",
        "malbatross_feather",
        "feather_robin_winter",
        "feather_robin",
        "feather_crow",
        "feather_canary",
    }
    for _,v in pairs(inst.components.container.slots) do
        for k, fur in pairs(furs) do
            if v.prefab == fur then
                amount = amount + 1
                table.remove(furs, k)
                break
            end
        end
    end
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED*2 + amount*40)
end

--优化堆堆帽格子不允许堆叠
local function onitemget(inst, data)
    if not inst or not data then return end

    local item = data.item
    if not item then return end

    if item.components.stackable and item.components.stackable.stacksize > 1 then
        local overflow = item.components.stackable.stacksize - 1
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        item.components.stackable:SetStackSize(1)
        if overflow > 0 then
            local returnitem = SpawnPrefab(item.prefab)
            returnitem.components.stackable:SetStackSize(overflow)

            if owner and owner.components.inventory then
                owner.components.inventory:GiveItem(returnitem, nil, inst:GetPosition())
            else
                returnitem.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end
    end

    InsulatorCheck(inst, data.item)
end

local function onitemlose(inst, data)
    if not inst or not data then return end
    InsulatorCheck(inst, data.prev_item)
end

local function ondepleted(inst)
    inst.components.container:DropEverything()
    inst:Remove()
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
	inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    
    inst:AddTag("hat")
	
    anim:SetBank("whiteberet_plus")
    anim:SetBuild("whiteberet_plus")
    anim:PlayAnimation("anim")

    inst:AddComponent("inspectable")

    MakeInventoryFloatable(inst, "med", 0.05, 0.75)

    inst:AddTag("whiteberet_plus")
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst,...)
            inst.replica.container:WidgetSetup("whiteberet_plus")
        end
        return inst
    end
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("whiteberet_plus")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/whiteberet_plus.xml"
    inst.components.inventoryitem.imagename = "whiteberet_plus"
    inst:ListenForEvent("itemget", onitemget)
    inst:ListenForEvent("itemlose", onitemlose)

    --inst:AddComponent("preserver")
    --inst.components.preserver:SetPerishRateMultiplier(TUNING.FISH_BOX_PRESERVER_RATE)
    
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED*2
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED*2)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.WALRUSHAT_PERISHTIME)
    inst.components.fueled:SetDepletedFn(ondepleted)

    inst.OnLoad = InsulatorCheck
    
    return inst
end

return Prefab( "whiteberet_plus", fn, assets) 

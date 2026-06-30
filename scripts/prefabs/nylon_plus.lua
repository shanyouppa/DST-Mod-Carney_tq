local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    --Asset("ANIM", "anim/swap_krampus_sack.zip"),
    --Asset("ANIM", "anim/ui_krampusbag_2x5.zip"),
    Asset("ATLAS", "images/inventoryimages/nylon_plus.xml"),
    Asset("ANIM", "anim/nylon_plus.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "nylon_plus", "swap_body")
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


    inst.AnimState:SetBank("nylon_plus")
    inst.AnimState:SetBuild("nylon_plus")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/krampuspack"


    inst:AddTag("backpack")

    inst.MiniMapEntity:SetIcon("backpack.png")
    --inst.MiniMapEntity:SetIcon("nylon_plus.tex")

    --waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    inst.entity:SetPristine()

    MakeInventoryFloatable(inst, "med", 0.05, 0.75)

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("krampus_sack")
        end
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/nylon_plus.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(.2)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("krampus_sack")

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("nylon_plus", fn, assets)

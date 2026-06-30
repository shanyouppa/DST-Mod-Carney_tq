local assets =
{
    Asset("ANIM", "anim/angelcrystal.zip"),
}


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "med", 0.15, 0.7)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("angelcrystal")
    inst.AnimState:SetBuild("angelcrystal")
    inst.AnimState:PlayAnimation("idle")
    inst.pickupsound = "metal"

    inst:AddTag("molebait")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 20

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/angelcrystal.xml"
    inst.components.inventoryitem.imagename = "angelcrystal"
    inst.components.inventoryitem:SetSinks(false)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = 10
    
    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("angelcrystal", fn, assets)
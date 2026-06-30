local assets =
{
    Asset("ANIM", "anim/luckyfish.zip"),
    Asset("ANIM", "anim/luckyfish01.zip"),
    Asset("ANIM", "anim/fish01.zip"),
}

local prefabs =
{
    "fish_cooked",
    "fishmeat_small_dried",
    "crab_king_shine",
}

local function flop(inst)
    if not inst.components.inventoryitem.canbepickedup then
        if inst.flop_task ~= nil then
            inst.flop_task:Cancel()
            inst.flop_task = nil
        end
        return
    end

    local num = math.random(2)
    for i = 1, num do
        inst.AnimState:PushAnimation("idle", false)
    end

    inst.flop_task = inst:DoTaskInTime(math.random() * 2 + num * 2, flop)
end

local function ondropped(inst)
    if inst.flop_task ~= nil then
        inst.flop_task:Cancel()
    end
    inst.AnimState:PlayAnimation("idle", false)
    inst.flop_task = inst:DoTaskInTime(math.random() * 3, flop)
end

local function onpickup(inst)
    if inst.flop_task ~= nil then
        inst.flop_task:Cancel()
        inst.flop_task = nil
    end
end

local function spawnshine(inst)
    if not inst or not inst:IsValid() then return end

    if math.random(1, 100) <= 75 then
        local shine = SpawnPrefab("crab_king_shine")
        if shine then
            local scale = math.random(35, 100) / 100 * 0.4
            shine.Transform:SetScale(scale, scale, 1)
            local x, y, z = inst.Transform:GetWorldPosition()
            x = x - 0.03 + math.random(-40, 40) / 100
            y = y + math.random(0, 100) / 100
            z = z - 0.03 + math.random(-40, 40) / 100
            shine.Transform:SetPosition(x, y, z)
        end
    end
end

local function startshining(inst)
    if not inst.shinetask then
        inst.shinetask = inst:DoPeriodicTask(0.25, spawnshine)
    end
end

local function stopshining(inst)
    if inst.shinetask then
        inst.shinetask:Cancel()
        inst.shinetask = nil
    end
end

local function ondropped_lucky(inst)
    ondropped(inst)
    startshining(inst)
end

local function onpickup_lucky(inst)
    onpickup(inst)
    stopshining(inst)
end

local function OnEaten(inst, eater)
    if eater and eater.prefab == "carney" then
        if eater.components.carneystatus then
            eater.components.carneystatus:DoDeltaLucky(1)
        end
        --if eater.components.talker then
        --    eater.components.talker:Say("感觉变幸运了！")
        --end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("luckyfish")
    inst.AnimState:SetBuild("luckyfish")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("fish")
    inst:AddTag("pondfish")
    inst:AddTag("meat")
    inst:AddTag("catfood")
    inst:AddTag("smallcreature")

    --inst:AddTag("cookable")
    --inst:AddTag("dryable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.build = "luckyfish01"

    inst:AddComponent("bait")

    -- 可烹饪：烹饪后变成普通熟鱼
    --inst:AddComponent("cookable")
    --inst.components.cookable.product = "fish_cooked"

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped_lucky)
    inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup_lucky)
    inst.components.inventoryitem:SetSinks(true)

    inst.components.inventoryitem.atlasname = "images/inventoryimages/luckyfish.xml"
    inst.components.inventoryitem.imagename = "luckyfish"

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = 20
    inst.components.edible.hungervalue = 12.5
    inst.components.edible.sanityvalue = 5
    inst.components.edible:SetOnEatenFn(OnEaten)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = 10

    MakeHauntableLaunch(inst)

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 20

    --inst:AddComponent("dryable")
    --inst.components.dryable:SetProduct("fishmeat_small_dried")
    --inst.components.dryable:SetDryTime(TUNING.DRY_FAST)
    --inst.components.dryable:SetDriedBuildFile("meat_rack_food_tot")

    inst.data = {}
    inst.flop_task = inst:DoTaskInTime(math.random() * 2 + 1, flop)
    inst:ListenForEvent("on_loot_dropped", function(inst, data)
        startshining(inst)
    end)
    inst:ListenForEvent("oncaught", function(inst, data)
        startshining(inst)
    end)

    return inst
end

return Prefab("luckyfish", fn, assets, prefabs)

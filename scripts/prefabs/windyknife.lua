local assets=
{
	Asset("ANIM", "anim/windyknife.zip"),
	Asset("ATLAS", "images/inventoryimages/windyknife.xml"),
}

local prefabs = {
}

local function spawnshineprefab(inst, data)
    if not inst then return end
    
    local spawn = math.random(1,100) < 75
    if spawn then
        local fxs = {
            {prefab = "crab_king_shine", scale = 0.4}
        }
        local i = math.floor(math.random(1,#fxs)+0.5)
        local shine = SpawnPrefab(fxs[i].prefab)
        local scale = math.random(35, 100)/100
        shine.Transform:SetScale(fxs[i].scale*scale, fxs[i].scale*scale, 1)
        local x = -3+math.random(-40, 40)
        local y = -170+math.random(-20, 120)
        local z = 0.1
        if data and data.owner then
            shine.entity:AddFollower()
            shine.Follower:FollowSymbol(data.owner.GUID, "swap_object", x, y, z)
        else
            x,y,z = inst.Transform:GetWorldPosition()
            x = x-0.03+math.random(-40, 40)/100
            y = y+math.random(0, 100)/100
            z = z-0.03+math.random(-40, 40)/100
            shine.Transform:SetPosition(x,y,z)
        end
    end
end

local function starshining(inst, owner)
    if not inst.windyshining and inst.components.windyknifestatus.level >= 25 then
        if inst.components.inventoryitem.owner and not inst.components.equippable:IsEquipped() then
            return
        else
            inst.windyshining = inst:DoPeriodicTask(0.25, spawnshineprefab, nil, {owner = owner})
        end
    end
end

local function stopshining(inst, owner)
    if inst.windyshining then
        inst.windyshining:Cancel()
        inst.windyshining = nil
    end
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "windyknife", "swap_windyknife")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal")
    starshining(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    stopshining(inst, owner)
end

local function onattack(inst, attacker, target, skipsanity)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell")
    if not attacker then return end
    if not attacker.components.combat then return end
    if not target then return end
    if not target.components.combat then return end

    local mult =
        (   attacker.components.electricattacks ~= nil
        )
        and not (target:HasTag("electricdamageimmune") or
                (target.components.inventory ~= nil and target.components.inventory:IsInsulated()))
        and TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent() or (target:GetIsWet() and 1 or 0))
        or 1
    local damage = attacker.components.combat:CalcDamage(target, inst, mult) + inst.components.planardamage:GetDamage()

    local is_carney = attacker:HasTag("carney")
    local lucky = is_carney and attacker.components.carneystatus and attacker.components.carneystatus.lucky or 0
    local level = is_carney and attacker.components.carneystatus and attacker.components.carneystatus.level or 0
    local crit_chance = 5 + 25 * math.pow(lucky/(lucky+50), 0.5)
    local crit_damage_percent = 150 + 15 * math.pow(level/10, 0.65) + level/4
    if inst.components.finiteuses and inst.components.finiteuses.current <= 1 then crit_chance = 100 end

    local snap = SpawnPrefab("impact")
    --snap.Transform:SetScale(.5, .5, .5)
    snap.Transform:SetPosition(target.Transform:GetWorldPosition())
    --snap.entity:AddFollower()
    --snap.Follower:FollowSymbol(attacker.GUID, "swap_object", 30, -150, 0)

    if math.random(1,100) <= crit_chance and not target:HasTag("wall") then
        local extra_damage = damage * (crit_damage_percent / 100 - 1)
        target.components.combat:GetAttacked(attacker, extra_damage)
        if target.SoundEmitter ~= nil then
            target.SoundEmitter:PlaySound("dontstarve/common/whip_large")
        end
        local snap2 = SpawnPrefab("fx_ice_pop")
        snap2.Transform:SetScale(1.75, 1.75, 1.75)
        snap2.Transform:SetPosition(target.Transform:GetWorldPosition())
        local fxtab = {
            "slingshotammo_hitfx_freeze",
            "slingshotammo_hitfx_gold",
            "slingshotammo_hitfx_marble",
            "slingshotammo_hitfx_poop",
            "slingshotammo_hitfx_rock",
            "slingshotammo_hitfx_slow",
            "slingshotammo_hitfx_thulecite",
            "slingshotammo_hitfx_trinket_1",
        }
        local num = math.ceil(math.random(1, #fxtab))
        local snap3 = SpawnPrefab(fxtab[num])
        snap3.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function repair(inst, count)
    count = count or 1
    if count < 1 then count = 1 end
    local repair = inst.components.finiteuses.current/inst.components.finiteuses.total + .5*count
    if repair >= 1 then repair = 1 end
    inst.components.finiteuses:SetUses(math.floor(repair*inst.components.finiteuses.total))
    inst.SoundEmitter:PlaySound("wintersfeast2019/creatures/gingerbread_vargr/eat")
end

local function valuecheck(inst)
    if TUNING.wklimit then
        if inst.components.windyknifestatus.level >= 25 then
            inst.components.windyknifestatus.level = 25
            if inst.components.trader then
                inst:RemoveComponent("trader")
            end
        end
    end
    
    local level = inst.components.windyknifestatus.level
    inst.components.weapon:SetDamage(inst.cur_basedamage + level)
    inst.components.planardamage:SetBaseDamage(inst.cur_planardamage + level)

    local owner = inst.components.inventoryitem.owner
    starshining(inst, owner)
end

local function GiveOverItem(inst, giver, item, overcount)
    if inst and giver and item and inst.components and giver.components.inventory then
        local overitem = SpawnPrefab(item.prefab)
        if overcount and overitem.components and overitem.components.stackable then
            overitem.components.stackable:SetStackSize(overcount)
        end
        giver.components.inventory:GiveItem(overitem, nil, inst:GetPosition())
    end
end

local function ItemTradeTest(inst, item)
    if item == nil then
        return false
    elseif item.prefab ~= "angelcrystal" then
        return false
    end
    return true
end

local function OnGiven(inst, giver, item, count)
    if not inst or not item then return end
    local stacksize = item.components and item.components.stackable and item.components.stackable.stacksize
    count = count or stacksize or 1
    if item.prefab == "angelcrystal" then
        local overcount = 0
        if TUNING.wklimit then
            if inst.components.windyknifestatus.level < 25 then
                inst.components.windyknifestatus:DoDeltaLevel(count)
                if inst.components.windyknifestatus.level > 25 then
                    overcount = inst.components.windyknifestatus.level - 25
                    inst.components.windyknifestatus.level = 25
                    inst.components.trader.acceptstacks = false
                    if overcount > 0 and giver then
                        GiveOverItem(inst, giver, item, overcount)
                    end
                end
            end
        else
            inst.components.windyknifestatus:DoDeltaLevel(count)
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
        valuecheck(inst)
    end
end

local function onuse(inst, data)
    local slots = inst.components.container.slots
    local item = nil
    for k,v in pairs(slots) do
        if v then
            item = v
            break
        end
    end
    if inst.components.finiteuses:GetPercent() <= .02 and item then
        repair(inst, 2)
        if item.components.stackable then
            if item.components.stackable.stacksize > 1 then
                item.components.stackable:SetStackSize(item.components.stackable.stacksize - 1)
            else
                item:Remove()
            end
        else
            item:Remove()
        end
    end
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
	inst.entity:AddNetwork() 
    inst.entity:AddSoundEmitter()
	
    anim:SetBank("windyknife")
    anim:SetBuild("windyknife")
    anim:PlayAnimation("idle")

    inst:AddTag("windyknife")
    
    MakeInventoryFloatable(inst, "small", 0.15, 0.8)

	if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("thulecite_container")
        end
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("thulecite_container")

    inst:AddComponent("windyknifestatus")
	
	inst:AddComponent("tool")
	
    inst.cur_basedamage = 32
    inst.cur_planardamage = 10
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(inst.cur_basedamage)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(inst.cur_planardamage)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/windyknife.xml"
    inst.components.inventoryitem:SetOnDroppedFn(starshining)
    inst.components.inventoryitem:SetOnPutInInventoryFn(stopshining)

	inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
	inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(200)
    inst.components.finiteuses:SetUses(200)
    if inst.components.finiteuses.current > inst.components.finiteuses.total then
        inst.components.finiteuses:SetUses(inst.components.finiteuses.total)
    end
    inst:ListenForEvent("percentusedchange", onuse)

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGiven
    inst.components.trader:SetAcceptStacks()

    inst:DoTaskInTime(0, function() valuecheck(inst) end)
    
    return inst
end


return Prefab( "windyknife", fn, assets, prefabs) 
local assets =
{
    Asset("ANIM", "anim/lunarthrall_plant_gestalt.zip"),
}

local prefabs = {
}

local function RespawnCarneyTemp(inst, doer)
    if doer and doer.Transform then
        local ctemp = SpawnPrefab("carneytemp")

        local pt = Point(doer.Transform:GetWorldPosition())
        local angle = math.random()*2*PI
        local ctemp = SpawnPrefab("carneytemp")
        ctemp.Transform:SetPosition(pt.x,pt.y,pt.z)
        ctemp.Physics:SetVel(2*math.cos(angle), 10, 2*math.sin(angle))

        ctemp.components.carneytempstatus.exptotal = inst.components.carneytempstatus.exptotal
        ctemp.components.carneytempstatus.level = inst.components.carneytempstatus.level
        ctemp.components.carneytempstatus._userid = inst.components.carneytempstatus._userid
        ctemp.components.carneytempstatus._playername = inst.components.carneytempstatus._playername
        ctemp.components.finiteuses:SetMaxUses(ctemp.components.carneytempstatus.level)
        ctemp.components.finiteuses:SetUses(ctemp.components.carneytempstatus.exptotal)
        local _playername = ctemp.components.carneytempstatus._playername
        ctemp.components.named:SetName(_playername..STRINGS.CARNEYSTRINGS[3])
        local speektab = {
            STRINGS.CARNEYSTRINGS[4].._playername..STRINGS.CARNEYSTRINGS[5],
            STRINGS.CARNEYSTRINGS[6].._playername..STRINGS.CARNEYSTRINGS[7],
            STRINGS.CARNEYSTRINGS[8].._playername..STRINGS.CARNEYSTRINGS[9],
        }
        ctemp.components.talker:Say(speektab[math.ceil(math.random(1, #speektab))])
        --ctemp.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
    end
end

local function OnRightClick(inst, doer)
    if not inst or not inst.components or not inst.components.carneytempstatus or not doer then return end

    if doer.components.carneystatus and (inst.components.carneytempstatus._userid == nil or doer.userid == inst.components.carneytempstatus._userid) then
        local exptotal = (doer.components.carneystatus.exptotal or 0) + (inst.components.carneytempstatus.exptotal or 0)
        doer.components.carneystatus:DoDeltaExp(exptotal)
        if doer.components.talker then
            doer:DoTaskInTime(2, function()
                if doer and doer.components and doer.components.talker then
                    doer.components.talker:Say(STRINGS.CARNEYSTRINGS[2])
                end
            end)
        end
        --local fxuse = SpawnPrefab("wormwood_mutantproxy_fruitdragon")
        --fxuse.entity:SetParent(doer.entity)
        local fxuse = SpawnPrefab("channel_absorb_embers")
        fxuse.entity:SetParent(doer.entity)
        local fxuse2 = SpawnPrefab("fx_book_temperature")
        fxuse2.entity:SetParent(doer.entity)

        inst:Remove()
    else
        --RespawnCarneyTemp(inst,doer)
        if doer.components.talker then
            doer.components.talker:Say(STRINGS.CARNEYSTRINGS[11])
        end
    end
end

local function toground(inst, owner)
    if not inst.components.carneytempstatus._userid
    or owner.userid == inst.components.carneytempstatus._userid
    or owner.name == inst.components.carneytempstatus._playername
    then
        inst.components.carneytempstatus._userid = nil
    else
        inst.components.inventoryitem:OnDropped(true)
        local _playername = inst.components.carneytempstatus._playername
        local speektab = {
            STRINGS.CARNEYSTRINGS[4].._playername..STRINGS.CARNEYSTRINGS[5],
            STRINGS.CARNEYSTRINGS[6].._playername..STRINGS.CARNEYSTRINGS[7],
            STRINGS.CARNEYSTRINGS[8].._playername..STRINGS.CARNEYSTRINGS[9],
        }
        inst.components.talker:Say(speektab[math.ceil(math.random(1, #speektab))])
        --RespawnCarneyTemp(inst,owner)
        --inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBuild("lunarthrall_plant_gestalt")
    inst.AnimState:SetBank("lunarthrall_plant_gestalt")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1,1,1,.6)
    inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:UsePointFiltering(true)

    inst:AddTag("rightclickable")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.6, .7, .9)
    inst.components.talker.offset = Vector3(0, 0, 0)
    inst.components.talker.symbol = "swap_object"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages2.xml"
    inst.components.inventoryitem.imagename = "moonstorm_spark"

    inst:AddComponent("hauntable") --作祟
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("healer")
    inst.components.healer:SetOnHealFn(OnRightClick)
    inst.components.healer:SetHealthAmount(0)

    function inst.components.healer:Heal(target, doer, ...)
        if self.onhealfn ~= nil then
            self.onhealfn(self.inst, target, doer)
        end
        return true
    end

    --inst._playerid = doer.userid
    inst:AddComponent("named")
    inst:AddComponent("carneytempstatus")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetUses(inst.components.carneytempstatus.exptotal)
    inst.components.finiteuses:SetMaxUses(inst.components.carneytempstatus.level)

    inst:ListenForEvent("onputininventory", toground)

    return inst
end

return Prefab("carneytemp", fn, assets)

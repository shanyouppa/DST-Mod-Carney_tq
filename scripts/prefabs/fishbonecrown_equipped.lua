local assets =
{
    Asset("ANIM", "anim/fishbonecrown_equipped.zip"),
}

local function OnActivated(inst, owner, is_front)
    inst.entity:SetParent(owner.entity)
    inst.entity:AddFollower()
    inst.AnimState:SetFinalOffset(1)
    inst.AnimState:PlayAnimation("activate_loop", true)

    local function UpdateOffset()
        if not owner:IsValid() or not inst:IsValid() then
            if inst._update_task then
                inst._update_task:Cancel()
                inst._update_task = nil
            end
            return
        end

        local facing = owner.AnimState:GetCurrentFacing()
        local x, y, z
        if facing == 3 then
            x, y, z = 0, 100, 0      -- 正面：正中
        elseif facing == 1 then
            x, y, z = 0, 100, -0.1   -- 背面：正中，微调深度
        else
            x, y, z = 77, 100, 0     -- 侧面：偏侧
        end

        inst.Follower:StopFollowing()
        inst.Follower:FollowSymbol(owner.GUID, "hair", x, y, z)
    end

    UpdateOffset()
    inst._update_task = inst:DoPeriodicTask(0.1, UpdateOffset)
end

local function OnDeactivated(inst)
    if inst._update_task then
        inst._update_task:Cancel()
        inst._update_task = nil
    end
    inst:Remove()
end

-- 空函数，避免主代码调用时报错
local function SetSkin(inst, skin_build, GUID)
end

local function SetFlameLevel(inst, level, skin_build, parent_GUID)
    inst.level = level
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fishbonecrown_equipped")
    inst.AnimState:SetBuild("fishbonecrown_equipped")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSymbolLightOverride("p4_piece", 1)
    inst.AnimState:SetSymbolMultColour("p4_piece", 30/255, 144/255, 255/255, 1)

    inst.Transform:SetNoFaced()

    inst:AddTag("FX")
    inst:AddTag("DECOR")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.SetFlameLevel = SetFlameLevel
    inst.OnActivated = OnActivated
    inst.OnDeactivated = OnDeactivated

    return inst
end

return Prefab("fishbonecrown_equipped", fn, assets)
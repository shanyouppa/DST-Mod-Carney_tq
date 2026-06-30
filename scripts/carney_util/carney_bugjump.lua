local G = GLOBAL

local BUGJUMP_KEY = GetModConfigData("BugJumpKey") or G.KEY_K
local MOUSE_KEYS = {
    [1005] = 1005,
    [1006] = 1006,
}

local SEARCH_RADIUS =8
local SECTOR_HALF_ANGLE = 60
local JUMP_HEIGHT = 1.5
local PICKUP_RADIUS = 2
local JUMP_SPEED = TUNING.WILSON_WALK_SPEED * 3.3
local SKILL_COOLDOWN = 4
local ANTI_SPAM_TIME = 0.9

local CATCHABLE_TAGS = {"butterfly", "bee", "mosquito", "firefly", "killerbee", "lunarmoth"}

local function FindBugTarget(player)
    local px, py, pz = player.Transform:GetWorldPosition()

    local rot = player.Transform:GetRotation() * math.pi / 180
    local facingX = math.cos(rot)
    local facingZ = -math.sin(rot)  --我也不知道为什么方向是反的，测试没问题

    local cosHalfAngle = math.cos(SECTOR_HALF_ANGLE * math.pi / 180)

    local ents = G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, nil, {"INLIMBO", "player", "wall", "structure"})

    local closestDist = SEARCH_RADIUS
    local closestTarget = nil

    for _, ent in ipairs(ents) do
        for _, tag in ipairs(CATCHABLE_TAGS) do
            if ent:HasTag(tag) and ent:IsValid() then
                local ex, ey, ez = ent.Transform:GetWorldPosition()
                local dx = ex - px
                local dz = ez - pz
                local dist = math.sqrt(dx*dx + dz*dz)

                local inSector = false
                if dist > 0 then
                    local tx, tz = dx/dist, dz/dist
                    local dot = facingX * tx + facingZ * tz
                    if dot > cosHalfAngle then
                        inSector = true
                    end
                end

                if inSector and dist < closestDist then
                    closestDist = dist
                    closestTarget = ent
                end
            end
        end
    end

    return closestTarget
end

local function CheckPathClear(startPos, endPos)
    local dist = startPos:Dist(endPos)
    local steps = math.max(3, math.floor(dist / 1.5))
    for i = 1, steps - 1 do
        local t = i / steps
        local cx = startPos.x + (endPos.x - startPos.x) * t
        local cz = startPos.z + (endPos.z - startPos.z) * t
        if not G.TheWorld.Map:IsPassableAtPoint(cx, 0, cz) then
            return false
        end
        local obstacles = G.TheSim:FindEntities(cx, 0, cz, 0.8, nil, nil, {"wall", "structure"})
        if #obstacles > 0 then
            return false
        end
    end
    return true
end

local function DoBugCatch(player, target_guid)
    local target = G.Ents[target_guid]
    if not target or not target:IsValid() then
        if player.components.talker then
            player.components.talker:Say(G.STRINGS.CARNEYBUGJUMP.TARGET_LOST)
        end
        return false
    end
    local px, py, pz = player.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local dist = math.sqrt((px - tx)^2 + (pz - tz)^2)
    if dist > PICKUP_RADIUS then
        if player.components.talker then
            player.components.talker:Say(G.STRINGS.CARNEYBUGJUMP.MISS)
        end
        return false
    end
    local is_catchable = false
    for _, tag in ipairs(CATCHABLE_TAGS) do
        if target:HasTag(tag) then is_catchable = true break end
    end
    if not is_catchable then return false end

    local prefab = target.prefab
    local x, y, z = target.Transform:GetWorldPosition()
    target:Remove()

    player:DoTaskInTime(0, function()
        local item = G.SpawnPrefab(prefab)
        if item then
            item.Transform:SetPosition(x, y, z)
            if player.components.inventory then
                player.components.inventory:GiveItem(item)
            end
        end
        local fx = G.SpawnPrefab("collapse_small")
        if fx then fx.Transform:SetPosition(x, y, z) end
    end)

    if player.components.talker then
        player.components.talker:Say(G.STRINGS.CARNEYBUGJUMP.CATCH)
    end
    return true
end

local function OnAttackedDuringJump(inst, data)
    if inst.sg:HasStateTag("jumping") or inst.sg:HasStateTag("pouncing") then
        if inst.sg.statemem.jumptask then
            inst.sg.statemem.jumptask:Cancel()
            inst.sg.statemem.jumptask = nil
        end
        if inst.sg.statemem.catchtask then
            inst.sg.statemem.catchtask:Cancel()
            inst.sg.statemem.catchtask = nil
        end
        inst.AnimState:SetScale(1, 1)
        inst:RemoveEventCallback("attacked", OnAttackedDuringJump)

        local x, y, z = inst.Transform:GetWorldPosition()
        if y > 0.1 then
            inst.Transform:SetPosition(x, 0, z)
        end
        inst.sg:GoToState("idle")
    end
end

local function AddBugJumpStates(sg)
    local State = G.State
    local FRAMES = G.FRAMES

    if sg.states.bugjump_k then return end

    sg.states.bugjump_k = State{
        name = "bugjump_k",
        tags = {"busy", "jumping", "nopredict", "nomorph", "nointerrupt"},

        onenter = function(inst, data)
            local targetPos = data and data.targetPos
            local target_guid = data and data.target_guid

            if not targetPos then
                inst.sg:GoToState("idle")
                return
            end

            inst.components.locomotor:Stop()
            inst.sg.statemem.targetPos = targetPos
            inst.sg.statemem.target_guid = target_guid

            local sx, sy, sz = inst.Transform:GetWorldPosition()
            inst.sg.statemem.startPos = G.Vector3(sx, sy, sz)

            inst.AnimState:PlayAnimation("jump")
            inst.AnimState:SetScale(1.2, 0.8)
            inst:ForceFacePoint(targetPos)

            local dist = inst.sg.statemem.startPos:Dist(targetPos)
            inst.sg.statemem.duration = dist / JUMP_SPEED
            inst.sg.statemem.elapsed = 0

            inst.sg:SetTimeout(inst.sg.statemem.duration + 0.5)

            inst:ListenForEvent("attacked", OnAttackedDuringJump)

            inst.sg.statemem.jumptask = inst:DoPeriodicTask(0.033, function()
                local mem = inst.sg.statemem
                mem.elapsed = mem.elapsed + 0.033
                local t = math.min(mem.elapsed / mem.duration, 1)

                local nx = mem.startPos.x + (mem.targetPos.x - mem.startPos.x) * t
                local nz = mem.startPos.z + (mem.targetPos.z - mem.startPos.z) * t
                local ny = mem.startPos.y + math.sin(t * 3.14159265359) * JUMP_HEIGHT

                if not G.TheWorld.Map:IsPassableAtPoint(nx, 0, nz) then
                    if mem.jumptask then mem.jumptask:Cancel() end
                    inst.AnimState:SetScale(1, 1)
                    inst:RemoveEventCallback("attacked", OnAttackedDuringJump)
                    inst.sg:GoToState("idle")
                    return
                end

                inst.Transform:SetPosition(nx, ny, nz)

                if t >= 1 then
                    if mem.jumptask then mem.jumptask:Cancel() end
                    inst.sg:GoToState("bugjump_k_pounce", {
                        targetPos = mem.targetPos,
                        target_guid = mem.target_guid,
                    })
                end
            end)
        end,

        ontimeout = function(inst)
            if inst.sg.statemem.jumptask then
                inst.sg.statemem.jumptask:Cancel()
            end
            inst.AnimState:SetScale(1, 1)
            inst:RemoveEventCallback("attacked", OnAttackedDuringJump)
            inst.sg:GoToState("idle")
        end,

        onexit = function(inst)
            if inst.sg.statemem.jumptask then
                inst.sg.statemem.jumptask:Cancel()
                inst.sg.statemem.jumptask = nil
            end
            inst.AnimState:SetScale(1, 1)
            inst:RemoveEventCallback("attacked", OnAttackedDuringJump)
        end,
    }

    sg.states.bugjump_k_pounce = State{
        name = "bugjump_k_pounce",
        tags = {"busy", "pouncing", "nopredict", "nomorph", "nointerrupt"},

        onenter = function(inst, data)
            local target_guid = data and data.target_guid

            --inst.AnimState:ClearOverrideSymbol("swap_object")
            --inst.AnimState:Hide("ARM_carry")
            --inst.AnimState:Show("ARM_normal")

            inst.AnimState:PlayAnimation("give")

            inst.sg.statemem.target_guid = target_guid
            inst:ListenForEvent("attacked", OnAttackedDuringJump)

            inst.sg.statemem.catchtask = inst:DoTaskInTime(8 * FRAMES, function()
                DoBugCatch(inst, inst.sg.statemem.target_guid)
            end)

            inst.sg.statemem.finishtask = inst:DoTaskInTime(15 * FRAMES, function()
                inst:RemoveEventCallback("attacked", OnAttackedDuringJump)
                if inst.sg:HasStateTag("busy") then
                    inst.sg:GoToState("idle")
                end
            end)
        end,

        onexit = function(inst)
            if inst.sg.statemem.catchtask then
                inst.sg.statemem.catchtask:Cancel()
                inst.sg.statemem.catchtask = nil
            end
            if inst.sg.statemem.finishtask then
                inst.sg.statemem.finishtask:Cancel()
                inst.sg.statemem.finishtask = nil
            end
            inst:RemoveEventCallback("attacked", OnAttackedDuringJump)
        end,
    }
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst.prefab ~= "carney" then return end

        if inst.sg and inst.sg.sg and not inst.sg.sg.states.bugjump_k then
            AddBugJumpStates(inst.sg.sg)
        end

        if inst ~= G.ThePlayer then
            return
        end

        local function OnBugJumpTrigger()

            if inst.components.locomotor then
--                print(string.format("[虫跃] 当前速度 | walk: %.2f, run: %.2f",
--                        inst.components.locomotor.walkspeed,
--                        inst.components.locomotor.runspeed))
            end

            local screen = G.TheFrontEnd:GetActiveScreen()
            if not (screen and screen.name == "HUD") then
                return
            end
            if not inst:IsValid() then
                return
            end

            G.SendModRPCToServer(G.MOD_RPC["CarneyMod"]["BugJumpK"])
        end

        if MOUSE_KEYS[BUGJUMP_KEY] then
            G.TheInput:AddMouseButtonHandler(function(button, down, x, y)
                if button == MOUSE_KEYS[BUGJUMP_KEY] and down then
                    OnBugJumpTrigger()
                end
            end)
        else
            G.TheInput:AddKeyDownHandler(BUGJUMP_KEY, OnBugJumpTrigger)
        end
    end)
end)

AddModRPCHandler("CarneyMod", "BugJumpK", function(player)

    if not player or not player:IsValid() then
        return
    end
    if player:HasTag("playerghost") then
        return
    end

    if SKILL_COOLDOWN > 0 then
        local last_time = player._bugjump_last_time or 0
        local now = G.GetTime()
        local remain = SKILL_COOLDOWN - (now - last_time)
        if remain > 0 then
            if player.components.talker then
                player.components.talker:Say(G.string.format("CD %.1f s", remain))
            end
            return
        end
    end

    local status = player.components.carneystatus
    if status and status.missactioning == 1 then
        return
    end
    if status then status.missactioning = 1 end

    if player.sg:HasStateTag("busy") then
        if status then status.missactioning = 0 end
        return
    end
    if player.components.rider and player.components.rider:IsRiding() then
        if status then status.missactioning = 0 end
        return
    end

    local target = FindBugTarget(player)
    if not target then
        if status then status.missactioning = 0 end
        return
    end

    local tx, ty, tz = target.Transform:GetWorldPosition()
    local targetPos = G.Vector3(tx, ty, tz)
    local px, py, pz = player.Transform:GetWorldPosition()
    local startPos = G.Vector3(px, py, pz)
    local target_guid = target.GUID

    if not CheckPathClear(startPos, targetPos) then
        if status then status.missactioning = 0 end
        if player.components.talker then
            player.components.talker:Say(G.STRINGS.CARNEYBUGJUMP.BLOCKED)
        end
        return
    end

    if player.components.hunger then
        local current_hunger = player.components.hunger.current
        if current_hunger >= 20 then
            player.components.hunger:DoDelta(-3)
        else
            if status then status.missactioning = 0 end
            if player.components.talker then
            end
            return
        end
    end

    player._bugjump_last_time = G.GetTime()

    player.sg:GoToState("bugjump_k", {
        targetPos = targetPos,
        target_guid = target_guid,
    })

    player:DoTaskInTime(ANTI_SPAM_TIME, function()
        if status then status.missactioning = 0 end
    end)
end)
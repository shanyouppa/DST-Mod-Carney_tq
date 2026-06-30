local containers = require("containers")
local params = {}

--堆堆帽

params.whiteberet_plus =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x1",
        animbuild = "ui_chest_3x1",
        pos = Vector3(106, 40, 0),
    },
    type = "hand_inv",
}

for y = 0, 0 do
    for x = -1, 1 do
        table.insert(params.whiteberet_plus.widget.slotpos, Vector3(80 * x, 0*y, 0))
    end
end

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

function params.whiteberet_plus.itemtestfn(container, item, slot)
    local cangetitem = false
    for _, v in pairs(furs) do
        if item.prefab == v then
            cangetitem = true
            break
        end
    end
    if not cangetitem then return false end

    if item:HasTag("whiteberet_plus") or
            item:HasTag("irreplaceable") or
            item:HasTag("_container") then
        return false
    end

    if container.slots == nil then
        return true
    end

    local slots = container.slots
    local target_slot = slots[slot]

    if target_slot == nil then
        for k, v in pairs(slots) do
            if v and v.prefab == item.prefab then
                return false
            end
        end
        return true
    end

    if target_slot.prefab ~= item.prefab then
        for k, v in pairs(slots) do
            if k ~= slot and v and v.prefab == item.prefab then
                return false
            end
        end
        return true
    end

    return false
end

--铥矿修复容器
params.thulecite_container =
{
    widget =
    {
        slotpos =
        {
            Vector3(0,   32 + 4,  0),
        },
        slotbg =
        {
            { image = "Thulecite_background.tex", atlas = "images/inventoryimages/Thulecite_background.xml" },
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.thulecite_container.itemtestfn(container, item, slot)
    return item.prefab == "thulecite"
end

--尼龙背包 10格

params.nylon_sack =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_nylon_2x5",
        animbuild = "ui_nylon_2x5",
        pos = Vector3(-5, -130, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

for y = 0, 4 do
    table.insert(params.nylon_sack.widget.slotpos, Vector3(-162, -75 * y + 165, 0))
    table.insert(params.nylon_sack.widget.slotpos, Vector3(-162 + 75, -75 * y + 165, 0))
end



------------------------------------------------[[]]------------------------------------------------

local old_widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data, ...)
    local customprefab = nil
    for k,_ in pairs(params) do
        if prefab == k then
            customprefab = prefab
            break
        end
    end
    if customprefab and container then
        local t = params[customprefab]
        if t ~= nil then
            for k, v in pairs(t) do
                container[k] = v
            end
            container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
        end
    else
        old_widgetsetup(container, prefab, data, ...)
    end
end


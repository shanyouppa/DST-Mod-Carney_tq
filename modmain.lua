local _G = GLOBAL
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH

local LAN_ = GetModConfigData('Language')
if LAN_ == "zh" then
	require 'strings_carney_c'
	TUNING.carneylan = true
else
	require 'strings_carney_e'
	TUNING.carneylan = false
end
require("widgets/widgets_carney")

local limit = GetModConfigData('DaggerLimit')
if limit then
	TUNING.wklimit = true
else
	TUNING.wklimit = false
end
TUNING.crossedge = false

TUNING.CarneyLevelLimit = GetModConfigData('LevelLimit')

--选人信息
TUNING.CARNEY_HEALTH = 100
TUNING.CARNEY_HUNGER = 100
TUNING.CARNEY_SANITY = 100
if LAN_ then
	STRINGS.CHARACTER_SURVIVABILITY.carney = "有手就行"
else
	STRINGS.CHARACTER_SURVIVABILITY.carney = "Pretty Easy"
end
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.CARNEY = {"whiteberet"}
local c_startitem = {
	whiteberet = {
		atlas = "images/inventoryimages/whiteberet.xml",
		image = "whiteberet.tex",
	},
}
for k,v in pairs(c_startitem) do
	TUNING.STARTING_ITEM_IMAGE_OVERRIDE[k] = v
end

modimport("scripts/carney_util/carney_util.lua")
modimport("scripts/carney_util/angelcrystal_drop.lua")
modimport("scripts/carney_util/carney_fishing.lua")
if GetModConfigData("RemoveThuleciteTradable") then
	modimport("scripts/carney_util/remove_thulecite_tradable.lua")
end
modimport("scripts/carney_util/carney_bugjump.lua")
modimport("scripts/carney_util/carney_damage_bonus.lua")
modimport("scripts/carney_util/carney_gestalt_toggle.lua")

PrefabFiles = {
	"carney",
	"whiteberet",
	"whiteberet_plus",
	"angelcrystal",
	"windyknife",
	"nylon",
	"nylon_plus",
	"carneytemp",
	"luckyfish",
	"fishbonecrown",
	"fishbonecrown_equipped",
    }

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/carney.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/carney.xml" ),

    Asset( "IMAGE", "images/avatars/self_inspect_carney.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_carney.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/carney.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/carney.xml" ),
	
	Asset( "IMAGE", "images/names_carney.tex" ),
    Asset( "ATLAS", "images/names_carney.xml" ),

    Asset( "IMAGE", "bigportraits/carney.tex" ),
    Asset( "ATLAS", "bigportraits/carney.xml" ),
	
	Asset( "IMAGE", "images/map_icons/carney.tex" ),
	Asset( "ATLAS", "images/map_icons/carney.xml" ),
	
	Asset( "IMAGE", "images/map_icons/nylon.tex" ),
	Asset( "IMAGE", "images/map_icons/nylon.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_carney.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_carney.xml" ),

	Asset( "IMAGE", "images/avatars/avatar_ghost_carney.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_carney.xml" ),

	Asset( "ATLAS", "images/inventoryimages/whiteberet.xml"),
	Asset( "IMAGE", "images/inventoryimages/whiteberet.tex" ),

	Asset( "ATLAS", "images/inventoryimages/whiteberet_plus.xml"),
	Asset( "IMAGE", "images/inventoryimages/whiteberet_plus.tex" ),

	Asset( "ATLAS", "images/inventoryimages/windyknife.xml"),
	Asset( "IMAGE", "images/inventoryimages/windyknife.tex" ),

	Asset( "ATLAS", "images/inventoryimages/Thulecite_background.xml"),
	Asset( "IMAGE", "images/inventoryimages/Thulecite_background.tex" ),

	Asset( "ATLAS", "images/inventoryimages/nylon.xml"),
	Asset( "IMAGE", "images/inventoryimages/nylon.tex" ),

	Asset( "ATLAS", "images/inventoryimages/nylon_plus.xml"),
	Asset( "IMAGE", "images/inventoryimages/nylon_plus.tex" ),

	Asset( "ATLAS", "images/inventoryimages/angelcrystal.xml"),
	Asset( "IMAGE", "images/inventoryimages/angelcrystal.tex" ),

	Asset( "ATLAS", "images/hud/carneytab.xml"),
	Asset( "IMAGE", "images/hud/carneytab.tex" ),

	Asset("ATLAS", "images/inventoryimages/luckyfish.xml"),
	Asset("IMAGE", "images/inventoryimages/luckyfish.tex"),

	--[[鱼骨皇冠]]
	Asset("ANIM", "anim/fishbonecrown.zip"),
	Asset("ATLAS", "images/inventoryimages/fishbonecrown.xml"),
	Asset("IMAGE", "images/inventoryimages/fishbonecrown.tex"),
}


AddStategraphPostInit("wilson", function(self)
    for key,value in pairs(self.states) do
        if value.name == 'attack' then
            local original_attack_onenter = self.states[key].onenter
            self.states[key].onenter = function(inst)
	            if not inst
	            	or not inst.components
	            	or not inst.components.inventory
        			or not inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    				or not inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS):HasTag("windyknife")
	            	or not inst.components.rider
            		or inst.components.rider:IsRiding()
            		then
	            	return original_attack_onenter(inst)
            	end

            	if inst.components.combat:InCooldown() then
	                inst.sg:RemoveStateTag("abouttoattack")
	                inst:ClearBufferedAction()
	                inst.sg:GoToState("idle", true)
	                return
	            end
	            if inst.sg.laststate == inst.sg.currentstate then
	                inst.sg.statemem.chained = true
	            end
	            local buffaction = inst:GetBufferedAction()
	            local target = buffaction ~= nil and buffaction.target or nil
	            inst.components.combat:SetTarget(target)
	            inst.components.combat:StartAttack()
	            inst.components.locomotor:Stop()
	            
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                local cooldown = 11 * GLOBAL.FRAMES

	            inst.sg:SetTimeout(cooldown)

	            if target ~= nil then
	                inst.components.combat:BattleCry()
	                if target:IsValid() then
	                    inst:FacePoint(target:GetPosition())
	                    inst.sg.statemem.attacktarget = target
	                    inst.sg.statemem.retarget = target
	                end
	            end
	        end
        end
    end
end)

AddStategraphPostInit("wilson_client", function(self)
    for key,value in pairs(self.states) do
        if value.name == 'attack' then
            local original_attack_onenter = self.states[key].onenter
            self.states[key].onenter = function(inst)
	            if not inst
	            	or not inst.replica
	            	or not inst.replica.inventory
	            	or not inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	            	or not inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS):HasTag("windyknife")
	            	or not inst.replica.rider
	            	or inst.replica.rider:IsRiding() then
	            	return original_attack_onenter(inst)
	            end
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                local cooldown = 11 * GLOBAL.FRAMES

				local buffaction = inst:GetBufferedAction()
	            if buffaction ~= nil then
	                inst:PerformPreviewBufferedAction()

	                if buffaction.target ~= nil and buffaction.target:IsValid() then
	                    inst:FacePoint(buffaction.target:GetPosition())
	                    inst.sg.statemem.attacktarget = buffaction.target
	                    inst.sg.statemem.retarget = buffaction.target
	                end
	            end

                inst.sg:SetTimeout(cooldown)
	        end
        end
    end
end)


----------------------------------------------[[宠物不饿]]----------------------------------------------

local critters = {
	"critter_lamb",
	"critter_puppy",
	"critter_kitten",
	"critter_perdling",
	"critter_dragonling",
	"critter_glomling",
	"critter_lunarmothling",
	"critter_eyeofterror",
}
for _,v in pairs(critters) do
	AddPrefabPostInit(v, function(inst)
		if not GLOBAL.TheWorld.ismastersim then return end

		inst:DoTaskInTime(2, function()
			if inst
			and inst.components
			and inst.components.follower
			and inst.components.follower.leader
			and inst.components.follower.leader.components
			and inst.components.follower.leader.components.carneystatus
			and inst.components.perishable then
				inst.components.perishable:StopPerishing()
			end
		end)
	end)
end

----------------------------------------------[[保存经验]]----------------------------------------------

--生成经验球
local function SpawnCarneytemp(inst, player)
    if player and player.components then
    	if player.Transform and player.components.carneystatus then
	    	GLOBAL.SpawnPrefab("fx_book_sleep").Transform:SetPosition(player.Transform:GetWorldPosition())
	        local pt = Point(player.Transform:GetWorldPosition())
	        local angle = math.random()*2*GLOBAL.PI
	    	local ctemp = GLOBAL.SpawnPrefab("carneytemp")
	        ctemp.Transform:SetPosition(pt.x,pt.y,pt.z)
	        ctemp.Physics:SetVel(2*math.cos(angle), 10, 2*math.sin(angle))

	    	local exptotal = player.components.carneystatus:Findexptotal(player.components.carneystatus.exp, player.components.carneystatus.level)
	    	exptotal = math.max(exptotal, player.components.carneystatus.exptotal or 0)

	    	ctemp.components.carneytempstatus.exptotal = exptotal
	    	ctemp.components.carneytempstatus.level = player.components.carneystatus.level
	    	ctemp.components.carneytempstatus._userid = player.userid
	    	ctemp.components.carneytempstatus._playername = player.name
	    	ctemp.components.finiteuses:SetMaxUses(ctemp.components.carneytempstatus.level)
	    	ctemp.components.finiteuses:SetUses(ctemp.components.carneytempstatus.exptotal)
	        local _playername = ctemp.components.carneytempstatus._playername
	        ctemp.components.named:SetName(_playername..STRINGS.CARNEYSTRINGS[3])
	    end
    end
end

--人物重选事件-地上
AddPrefabPostInit("forest", function(inst)
	inst:ListenForEvent("ms_playerdespawnanddelete", SpawnCarneytemp)
end)

--人物重选事件-地下
AddPrefabPostInit("cave", function(inst)
	inst:ListenForEvent("ms_playerdespawnanddelete", SpawnCarneytemp)
end)



----------------------------------------------[[制作栏]]----------------------------------------------

local carneytab = AddRecipeTab(STRINGS.CARNEYTAB, 999, "images/hud/carneytab.xml", "carneytab.tex", "carney")

AddRecipe("luckyfish", {
	GLOBAL.Ingredient("pondfish", 1),
	GLOBAL.Ingredient("angelcrystal", 1, "images/inventoryimages/angelcrystal.xml")
}, carneytab, TECH.NONE, nil, nil, nil, nil, "carney",
		"images/inventoryimages/luckyfish.xml", "luckyfish.tex")

AddRecipe("whiteberet", {
	GLOBAL.Ingredient("manrabbit_tail", 2),
	GLOBAL.Ingredient("silk", 6)
}, carneytab, TECH.NONE, nil, nil, nil, nil, "carney",
"images/inventoryimages/whiteberet.xml", "whiteberet.tex" )

AddRecipe("whiteberet_plus", {
	GLOBAL.Ingredient("whiteberet", 1, "images/inventoryimages/whiteberet.xml"),
	GLOBAL.Ingredient("walrushat", 1)
}, carneytab, TECH.SCIENCE_TWO, nil, nil, nil, nil, "carney",
		"images/inventoryimages/whiteberet_plus.xml", "whiteberet_plus.tex" )

AddRecipe("nylon", {
	GLOBAL.Ingredient("bearger_fur", 1),
	GLOBAL.Ingredient("steelwool", 4),
	GLOBAL.Ingredient("tentaclespots", 4)
}, carneytab, TECH.SCIENCE_TWO, nil, nil, nil, nil, "carney",
		"images/inventoryimages/nylon.xml", "nylon.tex" )

AddRecipe("windyknife", {
	GLOBAL.Ingredient("walrus_tusk", 1),
	GLOBAL.Ingredient("dragon_scales", 1),
	GLOBAL.Ingredient("thulecite", 8)
}, carneytab, TECH.SCIENCE_TWO, nil, nil, nil, nil, "carney",
		"images/inventoryimages/windyknife.xml", "windyknife.tex" )

AddRecipe("fishbonecrown", {
	GLOBAL.Ingredient("angelcrystal", 1, "images/inventoryimages/angelcrystal.xml"),
	GLOBAL.Ingredient("fossil_piece", 2),
	GLOBAL.Ingredient("dreadstone", 4)
}, carneytab, TECH.SCIENCE_TWO, nil, nil, nil, nil, "carney",
		"images/inventoryimages/fishbonecrown.xml", "fishbonecrown.tex")

----------------------------------------------[[其他]]----------------------------------------------

STRINGS.CHARACTERS.CARNEY = require "speech_wilson"

AddMinimapAtlas("images/map_icons/carney.xml")
AddMinimapAtlas("images/map_icons/nylon.xml")
AddModCharacter("carney","FEMALE")

--[[鱼骨皇冠 - 字符串定义]]
STRINGS.NAMES.FISHBONECROWN = "鱼骨皇冠"
STRINGS.RECIPE_DESC.FISHBONECROWN = "来自深海的诅咒之力"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FISHBONECROWN = "这顶皇冠散发着诡异的鱼腥味。"


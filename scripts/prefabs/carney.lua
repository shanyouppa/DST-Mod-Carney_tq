local MakePlayerCharacter = require "prefabs/player_common"
local cst=STRINGS.CARNEYSTRINGS

local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wilson.fsb" ),
        Asset( "ANIM", "anim/beard.zip" ),

        Asset( "ANIM", "anim/carney.zip" ),
		Asset( "ANIM", "anim/ghost_carney_build.zip" ),
}
local prefabs = {}

local start_inv = {
	"whiteberet",
}

local function onkilledother(inst, data)
    local victim = data.victim

	if not victim.markbycarney then
		if inst.components
		and inst.components.carneystatus
		and victim.components.freezable
		or victim:HasTag("monster")
		and victim.components.health then
			local value = math.ceil(victim.components.health.maxhealth)
			inst.components.carneystatus:DoDeltaExp(value)
		end
	end
end

local function onbecamehuman(inst)
	inst.components.carneystatus:calvalue()
end

local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    if not inst:HasTag("playerghost") then
        onbecamehuman(inst)
    end
end

--[[local function oneat(inst, food)
	if food and food.components.edible then
		local cooking = require("cooking")
        local recipe = cooking.GetRecipe("cookpot", food.prefab)
        if recipe and recipe.ingredients then
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.type == "fish" then
                    inst.components.talker:Say("yes")
                end
            end
        end
    end
end]]

local function oneat(inst, food)
	local humblefood = {"fish", "fish_cooked", "eel", "eel_cooked", "fishmeat", "fishmeat_cooked", "fishmeat_small", "fishmeat_small_cooked", "yotp_food3"}
	local mediumfood = {"luckyfish", "surfnturf", "seafoodgumbo", "fishsticks", "californiaroll", "fishtacos", "ceviche", "unagi", "barnaclestuffedfishhead", "moqueca", "frogfishbowl"}
	local seniorfood = {}
	for i=1, #mediumfood do
		table.insert(seniorfood, i+#mediumfood*0, mediumfood[i].."_spice_chili")
	end
	for i=1, #mediumfood do
		table.insert(seniorfood, i+#mediumfood*1, mediumfood[i].."_spice_garlic")
	end
	for i=1, #mediumfood do
		table.insert(seniorfood, i+#mediumfood*2, mediumfood[i].."_spice_salt")
	end
	for i=1, #mediumfood do
		table.insert(seniorfood, i+#mediumfood*3, mediumfood[i].."_spice_sugar")
	end
	if food and food.components.edible then
		for i=1, #humblefood do
			if food.prefab == humblefood[i]
				then
				inst.components.carneystatus:DoDeltaExp(1000)
				inst.components.talker:Say("exp +1000")
				inst.components.sanity:DoDelta(5)
			end
		end
		for i=1, #mediumfood do
			if food.prefab == mediumfood[i]
				then
				inst.components.carneystatus:DoDeltaExp(2000)
				inst.components.talker:Say("exp +2000")
				inst.components.sanity:DoDelta(10)
			end
		end
		for i=1, #seniorfood do
			if food.prefab == seniorfood[i]
				then
				inst.components.carneystatus:DoDeltaExp(3000)
				inst.components.talker:Say("exp +3000")
				inst.components.sanity:DoDelta(20)
			end
		end
	end
end

local function updatemark(inst, target)
	if not inst or not target or not target.markbycarney then return end

	local ismark = false
	for k,v in pairs(target.markbycarney) do
		if v then
			if inst.userid == v.userid then
				ismark = true
				v.time = 5
				break
			end
		end
	end
	if not ismark then
		table.insert(target.markbycarney, {userid = inst.userid, time = 5})
	end
end

local function markcountdown(target)
	if not target or not target.markbycarney then return end

	for i=#target.markbycarney, 1, -1 do
		if target.markbycarney[i] then
			target.markbycarney[i].time = target.markbycarney[i].time - 1
			if target.markbycarney[i].time <= 0 then
				target.markbycarney[i] = nil
			end
		end
	end
end

local function targetondeath(target)
	if not target or not target.markbycarney then return end
	--if not target.markdeathofcarney then
		--target.markdeathofcarney = true
		for k,v in pairs(target.markbycarney) do
			for _, player in pairs(AllPlayers) do
				if v.userid == player.userid then
					if player.components
					and player.components.carneystatus
					and target.components.freezable
					or target:HasTag("monster")
					and target.components.health then
						local value = math.ceil(target.components.health.maxhealth)
						player.components.carneystatus:DoDeltaExp(value)
					end
				end
			end
		end
	--end
	target.markbycarney = {}
end

local function startmark(inst, data)
	if not inst or not data or not data.target then return end

	local target = data.target
	if not target.markbycarney then
		target.markbycarney = {
			--{userid = player.userid, time = 5},
		}
		target:ListenForEvent("death", targetondeath)
		--target:ListenForEvent("minhealth", targetondeath)
		target:DoPeriodicTask(1, markcountdown)
	end

	updatemark(inst, target)
end


--[[attacker:PushEvent("onhitother", {
	target = self.inst,
	damage = damage,
	damageresolved = damageresolved,
	stimuli = stimuli,
	spdamage = spdamage,
	weapon = weapon,
	redirected = damageredirecttarget
})]]

--self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })

local function hitother(inst, data)
	startmark(inst, data)
end





local function UpdateTemperature(inst)
	if TheWorld.state.temperature < 40 then
		inst.components.temperature:SetModifier("ctemp", -10)
	else
		inst.components.temperature:SetModifier("ctemp", 0)
	end
end

local common_postinit = function(inst)
	inst.clevel = net_shortint(inst.GUID,"clevel")
	inst.cexp = net_shortint(inst.GUID,"cexp")

	inst.MiniMapEntity:SetIcon( "carney.tex" )
	inst.soundsname = "willow"
	inst:AddTag("carney")
end

local master_postinit = function(inst)
	inst.components.eater:SetOnEatFn(oneat)

	inst:AddComponent("carneystatus")
	inst.components.carneystatus:OnLoad()

	inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE
	inst:DoPeriodicTask(60, UpdateTemperature)

	inst.components.locomotor.walkspeed = inst.components.carneystatus.speedwalk
	inst.components.locomotor.runspeed = inst.components.carneystatus.speedrun

	inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.15, "carney")

	inst:ListenForEvent("killed", onkilledother)
    inst:ListenForEvent("onhitother", hitother)

    inst:AddComponent("reader")
end

return MakePlayerCharacter("carney", prefabs, assets, common_postinit, master_postinit, start_inv)

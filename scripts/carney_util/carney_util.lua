local G = GLOBAL
local ThePlayer = G.ThePlayer
local TheInput = G.TheInput
local cst = G.STRINGS.CARNEYSTRINGS

local CHECK_KEY = GetModConfigData("CheckKey") or G.KEY_J

local MOUSE_KEYS = {
	[1005] = 1005,
	[1006] = 1006,
}

AddModRPCHandler(modname, "Check", function(player)
	if not player:HasTag("playerghost") and player.components.carneystatus then
		local status = player.components.carneystatus
		local lucky = status.lucky or 0
		local level = status.level or 0
		local crit_chance = 5 + 25 * math.pow(lucky/(lucky+50), 0.5)
		local crit_damage_percent = 150 + 15 * math.pow(level/10, 0.65) + level/4
		local gestalt_state = status.gestalt_attack_enabled and "Enabled" or "Disabled"
		player.components.talker:Say("lv "..(status.level).."\nexp "..(math.floor(status.exp)).."/"..(status.maxexp).."\nlucky "..(lucky).."\ncrit "..(string.format("%.2f", crit_chance)).."%".."  ".."critdmg "..(string.format("%.2f", crit_damage_percent)).."%\nFishbonecrown Gestalt Attack: "..gestalt_state)
	end
end)

local carney_handlers = {}
AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function()
		if inst == G.ThePlayer and inst.prefab == "carney" then
			local function OnCheckTrigger()
				local screen = G.TheFrontEnd:GetActiveScreen()
				local IsHUDActive = screen and screen.name == "HUD"
				if inst:IsValid() and IsHUDActive then
					SendModRPCToServer(MOD_RPC[modname]["Check"])
				end
			end

			if MOUSE_KEYS[CHECK_KEY] then
				carney_handlers[0] = TheInput:AddMouseButtonHandler(function(button, down, x, y)
					if button == MOUSE_KEYS[CHECK_KEY] and down then
						OnCheckTrigger()
					end
				end)
			else
				carney_handlers[0] = TheInput:AddKeyDownHandler(CHECK_KEY, OnCheckTrigger)
			end
		end
	end)
end)

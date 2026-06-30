local G = GLOBAL
local TheInput = G.TheInput

local GESTALT_KEY = GetModConfigData("GestaltAttackKey") or G.KEY_L

local MOUSE_KEYS = {
	[1005] = 1005,
	[1006] = 1006,
}

AddModRPCHandler(modname, "ToggleGestaltAttack", function(player)
	if player.components.carneystatus then
		player.components.carneystatus.gestalt_attack_enabled = not player.components.carneystatus.gestalt_attack_enabled
		local state = player.components.carneystatus.gestalt_attack_enabled and "Enabled" or "Disabled"
		player.components.talker:Say("Fishbonecrown Gestalt Attack: " .. state)
	end
end)

local gestalt_handlers = {}
AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function()
		if inst == G.ThePlayer and inst.prefab == "carney" then
			local function OnGestaltToggleTrigger()
				local screen = G.TheFrontEnd:GetActiveScreen()
				local IsHUDActive = screen and screen.name == "HUD"
				if inst:IsValid() and IsHUDActive then
					SendModRPCToServer(MOD_RPC[modname]["ToggleGestaltAttack"])
				end
			end

			if MOUSE_KEYS[GESTALT_KEY] then
				gestalt_handlers[0] = TheInput:AddMouseButtonHandler(function(button, down, x, y)
					if button == MOUSE_KEYS[GESTALT_KEY] and down then
						OnGestaltToggleTrigger()
					end
				end)
			else
				gestalt_handlers[0] = TheInput:AddKeyDownHandler(GESTALT_KEY, OnGestaltToggleTrigger)
			end
		end
	end)
end)
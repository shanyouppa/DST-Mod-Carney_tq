
local CARNEY_FISH_WAIT_MULT = 0.4      -- 淡水等待时间系数
local CARNEY_OCEAN_DRAIN_MULT = 2  -- 海钓，鱼体力消耗倍数

AddComponentPostInit("fishingrod", function(self)
	local old_WaitForFish = self.WaitForFish

	function self:WaitForFish()
		if self.fisherman and self.fisherman.prefab == "carney" then
			local old_min = self.minwaittime
			local old_max = self.maxwaittime
			self.minwaittime = self.minwaittime * CARNEY_FISH_WAIT_MULT
			self.maxwaittime = self.maxwaittime * CARNEY_FISH_WAIT_MULT

			old_WaitForFish(self)

			self.minwaittime = old_min
			self.maxwaittime = old_max
		else
			old_WaitForFish(self)
		end
	end
end)

AddPrefabPostInit("fishingrod", function(inst)
	if not GLOBAL.TheWorld.ismastersim then return end

	local old_Collect = inst.components.fishingrod.Collect

	function inst.components.fishingrod:Collect()
		if self.caughtfish then
			self.caughtfish:PushEvent("oncaught", {fisher = self.fisherman})
		end
		return old_Collect(self)
	end
end)

AddComponentPostInit("oceanfishable", function(self)
	local old_CalcStaminaDrainRate = self.CalcStaminaDrainRate

	function self:CalcStaminaDrainRate()
		local result = old_CalcStaminaDrainRate(self)
		local drain = -result
		local rod = self.rod
		if rod and rod.components.oceanfishingrod then
			local fisher = rod.components.oceanfishingrod.fisher
			if fisher and fisher.prefab == "carney" then
				drain = drain * CARNEY_OCEAN_DRAIN_MULT
			end
		end

		return -drain
	end
end)

--幸运鱼概率
-- 池塘/沼泽池塘/洞穴池塘：1%
-- 沙漠绿洲：4%
AddComponentPostInit("fishable", function(self)
	local old_HookFish = self.HookFish

	function self:HookFish(fisherman)
		if fisherman and fisherman.prefab == "carney" then
			local pond_type = self.inst.prefab
			local lucky_chance = 0

			if pond_type == "pond"
					or pond_type == "pond_mos"
					or pond_type == "pond_cave" then
				lucky_chance = 0.01

			elseif pond_type == "oasislake" then
				lucky_chance = 0.04
			end

			if lucky_chance > 0 and math.random() < lucky_chance then
				local fish = GLOBAL.SpawnPrefab("luckyfish")
				if fish ~= nil then
					self.hookedfish[fish] = fish
					self.inst:AddChild(fish)
					fish.entity:Hide()
					fish.persists = false
					if fish.DynamicShadow ~= nil then
						fish.DynamicShadow:Enable(false)
					end
					if fish.Physics ~= nil then
						fish.Physics:SetActive(false)
					end

					if fisherman ~= nil and fish.components.weighable ~= nil then
						fish.components.weighable:SetPlayerAsOwner(fisherman)
					end
					if self.fishleft > 0 then
						self.fishleft = self.fishleft - 1
					end
					return fish
				end
			end
		end

		return old_HookFish(self, fisherman)
	end
end)

--修改 SGwilson 收杆动画
AddStategraphPostInit("wilson", function(sg)
	local old_onenter = sg.states["catchfish"].onenter
	sg.states["catchfish"].onenter = function(inst, build)
		inst.AnimState:PlayAnimation("fish_catch")
		if build == "luckyfish" or build == "luckyfish01" then
			inst.AnimState:OverrideSymbol("fish01", "luckyfish01", "luckyfish01")
		else
			inst.AnimState:OverrideSymbol("fish01", build, "fish01")
		end
	end
end)
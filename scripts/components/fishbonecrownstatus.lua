
local fishbonecrownstatus = Class(
        function(self, inst)
            self.inst = inst

            -- 基础最大耐久（出生时/全新时的耐久）
            self.BASE_MAX_CONDITION = 315
            -- 普通防御百分比
            self.DEFENSE_NORMAL = 0.75
            -- 位面防御基础值
            self.DEFENSE_PLANAR_BASE = 5
            -- 耐久上限增长上限
            self.MAX_CONDITION_BONUS = 1500
            -- 每个噩梦燃料修复百分比
            self.REPAIR_PERCENT_PER_FUEL = 0.3
            -- 击杀boss增加的基础耐久值
            self.CONDITION_PER_BOSS_KILL = 2

            -- 天使水晶：最多20个，每个+0.5%物理防御
            self.ANGEL_CRYSTAL_MAX = 20
            self.ANGEL_CRYSTAL_DEFENSE_PERCENT = 0.005  -- 0.5%

            -- 启迪碎片：最多5个，每个+1位面防御，+2san/min
            self.ALTERGUARDIANHATSHARD_MAX = 5
            self.ALTERGUARDIANHATSHARD_PLANAR = 1
            self.ALTERGUARDIANHATSHARD_SANITY = 2 / 60

            -- 天体珠宝：最多10个，每个+0.5位面防御，+2san/min
            self.LUNAR_SEED_MAX = 10
            self.LUNAR_SEED_PLANAR = 0.5
            self.LUNAR_SEED_SANITY = 2 / 60

            -- 动态属性
            -- 当前最大耐久
            self.max_condition = self.BASE_MAX_CONDITION
            self.angel_crystals = 0
            self.alterguardianhatshards = 0
            self.lunar_seeds = 0

        end,
        nil,
        {}
)

function fishbonecrownstatus:OnSave()
    return {
        max_condition = self.max_condition,
        angel_crystals = self.angel_crystals,
        alterguardianhatshards = self.alterguardianhatshards,
        lunar_seeds = self.lunar_seeds,
    }
end

function fishbonecrownstatus:OnLoad(data)
    self.max_condition = data.max_condition or self.BASE_MAX_CONDITION
    self.angel_crystals = data.angel_crystals or 0
    self.alterguardianhatshards = data.alterguardianhatshards or 0
    self.lunar_seeds = data.lunar_seeds or 0
end

function fishbonecrownstatus:IsEquippable()
    local armor = self.inst.components.armor
    return armor ~= nil and armor.condition > 0
end

function fishbonecrownstatus:AddAngelCrystal(count)
    count = count or 1
    local old = self.angel_crystals
    self.angel_crystals = math.min(self.angel_crystals + count, self.ANGEL_CRYSTAL_MAX)
    self.inst:PushEvent("fishbonecrownupgrade")
    return self.angel_crystals - old
end

function fishbonecrownstatus:AddAlterguardianhatshard(count)
    count = count or 1
    local old = self.alterguardianhatshards
    self.alterguardianhatshards = math.min(self.alterguardianhatshards + count, self.ALTERGUARDIANHATSHARD_MAX)
    self.inst:PushEvent("fishbonecrownupgrade")
    return self.alterguardianhatshards - old
end

function fishbonecrownstatus:AddLunarSeed(count)
    count = count or 1
    local old = self.lunar_seeds
    self.lunar_seeds = math.min(self.lunar_seeds + count, self.LUNAR_SEED_MAX)
    self.inst:PushEvent("fishbonecrownupgrade")
    return self.lunar_seeds - old
end

function fishbonecrownstatus:AddMaxCondition(delta)
    delta = delta or 0
    local cap = self.BASE_MAX_CONDITION + self.MAX_CONDITION_BONUS
    self.max_condition = math.min(self.max_condition + delta, cap)
    self.inst:PushEvent("fishbonecrownupgrade")
end

function fishbonecrownstatus:GetNormalDefense()
    return self.DEFENSE_NORMAL
end

function fishbonecrownstatus:GetPlanarDefense()
    return self.defense_planar
end

function fishbonecrownstatus:GetMaxCondition()
    return self.max_condition
end

function fishbonecrownstatus:GetAngelCrystals()
    return self.angel_crystals
end

--升级物品上限检查
function fishbonecrownstatus:IsMaxAngelCrystals()
    return self.angel_crystals >= self.ANGEL_CRYSTAL_MAX
end

function fishbonecrownstatus:IsMaxAlterguardianhatshards()
    return self.alterguardianhatshards >= self.ALTERGUARDIANHATSHARD_MAX
end

function fishbonecrownstatus:IsMaxLunarSeeds()
    return self.lunar_seeds >= self.LUNAR_SEED_MAX
end


-- 所有属性同步
function fishbonecrownstatus:SyncAll()
    -- 获取所有需要同步的外部组件
    local armor = self.inst.components.armor
    local planardef = self.inst.components.planardefense
    local fueled = self.inst.components.fueled
    local equippable = self.inst.components.equippable

    if armor then
        armor.maxcondition = self.max_condition
        armor.absorb_percent = self.DEFENSE_NORMAL + self.angel_crystals * self.ANGEL_CRYSTAL_DEFENSE_PERCENT
    end

    if planardef then
        local planar = self.DEFENSE_PLANAR_BASE
                + self.alterguardianhatshards * self.ALTERGUARDIANHATSHARD_PLANAR
                + self.lunar_seeds * self.LUNAR_SEED_PLANAR
        planardef:SetBaseDefense(planar)
    end

    if equippable then
        local dapperness = -10 / 60
                + self.alterguardianhatshards * self.ALTERGUARDIANHATSHARD_SANITY
                + self.lunar_seeds * self.LUNAR_SEED_SANITY
        equippable.dapperness = dapperness
        if equippable:IsEquipped() and equippable.owner and equippable.owner.components.sanity then
            --equippable.owner.components.sanity.externalmodifiers:SetModifier(self.inst, dapperness)
            equippable.owner.components.sanity:Recalc(0)
        end
    end

    if fueled then
        fueled.maxfuel = self.max_condition
        fueled.currentfuel = armor and armor.condition or 0
    end

    -- ==========================================
    -- 启迪碎片达到5个：激活永久发光
    -- ==========================================
    --self.inst._should_glow = (self.alterguardianhatshards >= self.ALTERGUARDIANHATSHARD_MAX)
end

return fishbonecrownstatus
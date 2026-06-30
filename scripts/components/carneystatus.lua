local function oncurrentlevel(self,level) self.inst.clevel:set(level) end
local function oncurrentexp(self,exp) self.inst.cexp:set(exp) end
local carneystatus = Class(function(self, inst)
    self.inst = inst
    self.level = 0
    self.exp = 0
    self.exptotal = nil
    self.expmod = 1
    self.maxexp = 0
    self.damagemod = 1
    self.lucky = 0
    self.speedwalk = TUNING.WILSON_WALK_SPEED * 1.10
    self.speedrun = TUNING.WILSON_RUN_SPEED * 1.10
    self.chunger = 1
    self.csanity = 1
    self.chealth = 1
    self.gestalt_attack_enabled = true
end,
nil,
{
    level = oncurrentlevel,
    exp = oncurrentexp,
})

function carneystatus:OnSave()
    local data = {
        level = self.level,
        exp = self.exp,
        exptotal = self.exptotal,
        lucky = self.lucky,
        --chunger = math.ceil(self.inst.components.hunger.current),
        --csanity = math.ceil(self.inst.components.sanity.current),
        --chealth = math.ceil(self.inst.components.health.currenthealth),
        chunger = self.inst.components.hunger:GetPercent(),
        csanity = self.inst.components.sanity:GetPercent(),
        chealth = self.inst.components.health:GetPercent(),
        --chungermax = self.inst.components.hunger.max,
        --csanitymax = self.inst.components.hunger.max,
        --chealthmax = self.inst.components.hunger.maxhealth,
        gestalt_attack_enabled = self.gestalt_attack_enabled,
    }
    return data
end

function carneystatus:OnLoad(data)
    if not data then data = {} end
    self.level = data.level or 0
    self.exp = data.exp or 0
    self.lucky = data.lucky or 0

    self.chunger = data.chunger or 1
    self.csanity = data.csanity or 1
    self.chealth = data.chealth or 1
    self.exptotal = data.exptotal or self:Findexptotal(self.exp, self.level)
    
    local cal = self:CalLevel(self.exptotal)
    self.level = cal.lv

    if TUNING.CarneyLevelLimit and self.level >50 then
        self.level = 50
    end
    --[[self.inst.components.hunger.max = 100 + self.level*2
    self.inst.components.sanity.max = 100 + self.level*1
    self.inst.components.health.maxhealth = 100 + self.level*1
    self.inst.components.hunger:SetPercent(self.chunger / self.inst.components.hunger.max)
    self.inst.components.sanity:SetPercent(self.csanity / self.inst.components.sanity.max)
    self.inst.components.health:SetPercent(self.chealth / self.inst.components.health.maxhealth)]]
    self.inst.components.hunger.max = TUNING.CARNEY_HUNGER
    self.inst.components.sanity.max = TUNING.CARNEY_SANITY
    self.inst.components.health.maxhealth = TUNING.CARNEY_HEALTH
    if self.inst.components.hunger.max < 1 then self.inst.components.hunger.max = 1 end
    if self.inst.components.sanity.max < 1 then self.inst.components.sanity.max = 1 end
    if self.inst.components.health.maxhealth < 1 then self.inst.components.health.maxhealth = 1 end
    self:onlevelup(self.level)
    self.inst.components.hunger:SetPercent(self.chunger)
    self.inst.components.sanity:SetPercent(self.csanity)
    self.inst.components.health:SetPercent(self.chealth)
    self.gestalt_attack_enabled = data.gestalt_attack_enabled ~= false
end

function carneystatus:calvalue()
    local lv = self.level

    self.maxexp = lv * 200 + 100

    local hunger_percent = self.inst.components.hunger:GetPercent()
    self.inst.components.hunger.max = TUNING.CARNEY_HUNGER + lv*2
    self.inst.components.hunger:SetPercent(hunger_percent)

    local sanity_percent = self.inst.components.sanity:GetPercent()
    self.inst.components.sanity.max = TUNING.CARNEY_SANITY + lv*1
    self.inst.components.sanity:SetPercent(sanity_percent)

    local health_percent = self.inst.components.health:GetPercent()
    self.inst.components.health.maxhealth = TUNING.CARNEY_HEALTH + lv*1
    self.inst.components.health:SetPercent(health_percent)

    self.inst.components.locomotor.walkspeed = self.inst.components.carneystatus.speedwalk
    self.inst.components.locomotor.runspeed = self.inst.components.carneystatus.speedrun
end

function carneystatus:onlevelup(amount) --计算属性
    local lv = self.level
    amount = amount or 1
    local old_max = {
        hunger = self.inst.components.hunger.max,
        sanity = self.inst.components.sanity.max,
        health = self.inst.components.health.maxhealth,
    }

    self.maxexp = lv * 200 + 100

    local hunger_percent = self.inst.components.hunger:GetPercent()
    self.inst.components.hunger.max = old_max.hunger + amount*2
    self.inst.components.hunger:SetPercent(hunger_percent)

    local sanity_percent = self.inst.components.sanity:GetPercent()
    self.inst.components.sanity.max = old_max.sanity + amount
    self.inst.components.sanity:SetPercent(sanity_percent)

    local health_percent = self.inst.components.health:GetPercent()
    self.inst.components.health.maxhealth = old_max.health + amount
    self.inst.components.health:SetPercent(health_percent)

    self.inst.components.locomotor.walkspeed = self.inst.components.carneystatus.speedwalk
    self.inst.components.locomotor.runspeed = self.inst.components.carneystatus.speedrun
end

function carneystatus:levelup(amount)
    amount = amount or 1
    self.inst.components.talker:Say("Level UP!")

    self:onlevelup(amount)
    self.inst.components.health:DoDelta(self.inst.components.health.maxhealth/5)

    SpawnPrefab("wormwood_lunar_transformation_finish").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    SpawnPrefab("sleepbomb_burst").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    local fx = SpawnPrefab("spear_gungnir_lungefx")
    fx.entity:SetParent(self.inst.entity)
    --local fx2 = SpawnPrefab("abigail_retaliation")
    --fx2.entity:SetParent(self.inst.entity)
end

function carneystatus:Findexptotal(exp, lv)
    exp = exp or 0
    lv = lv or 0
    local exptotal = 0
    for i=1, lv do
        exptotal = exptotal + (i-1)*200 +100
    end
    return exptotal + exp
end

function carneystatus:CalLevel(exp, lv)
    if not lv then lv = 0 end
    local maxexp = lv * 200 + 100
    if exp - maxexp >= 0 then
        lv = lv + 1
        exp = exp - maxexp
        return self:CalLevel(exp, lv)
    else
        return {exp = exp, lv = lv}
    end
end

function carneystatus:DoDeltaExp(delta)
    if not self.inst then return end

    if not self.exptotal then self.exptotal = self:Findexptotal(self.exp, self.level) end
    self.exptotal = self.exptotal + delta*self.expmod

    local old_lv = self.level
    local cal = self:CalLevel(self.exptotal)
    self.level = cal.lv
    if TUNING.CarneyLevelLimit and self.level >50 then
        self.level = 50
    end
    self.exp = cal.exp
    if self.level > old_lv then
        local amount = self.level - old_lv
        self:levelup(amount)
    end
end

function carneystatus:DoDeltaLucky(delta)
    if not self.inst then return end
    self.lucky = (self.lucky or 0) + delta
end

return carneystatus
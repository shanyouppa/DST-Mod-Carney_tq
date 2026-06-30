local BONUS_TARGETS = {
    frog = 1.20,  --青蛙
    lunarfrog = 1.20,  --明眼青蛙
    toadstool = 1.20,  --毒菌蟾蜍
    toadstool_dark = 1.20,  --悲惨的毒菌蟾蜍
    merm = 1.20,  --鱼人
    shark = 1.20,  --岩石大白鲨
    gnarwail = 1.20,  --一角鲸
    hound = 0.80,  --猎犬
    moonhound = 0.80,  --猎犬（月亮石袭击）
    firehound = 0.80,  --火焰猎犬
    icehound = 0.80,  --寒冰猎犬
    warglet = 0.80,  --青年座狼
    warg = 0.80,  --座狼
    gingerbreadwarg = 0.80,  --姜饼座狼
    claywarg = 0.80,  --粘土座狼
    mutatedwarg = 0.80,  --附身座狼

}

AddPlayerPostInit(function(inst)
    if not inst:HasTag("carney") then return end
    if not inst.components.combat then return end

    local old = inst.components.combat.DoAttack
    inst.components.combat.DoAttack = function(self, target, weapon, projectile, stimuli, ...)
        if target and BONUS_TARGETS[target.prefab] then
            local orig = self.damagemultiplier
            self.damagemultiplier = (orig or 1) * BONUS_TARGETS[target.prefab]

            local ret = {old(self, target, weapon, projectile, stimuli, ...)}

            self.damagemultiplier = orig
            return
        end
        return old(self, target, weapon, projectile, stimuli, ...)
    end
end)
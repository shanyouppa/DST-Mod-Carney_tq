---天使水晶 boss 掉落逻辑
local ANGEL_CRYSTAL_LOOT = {

    -- 第一档：2% 概率掉落 1 个
    --精英怪
    --{"lordfruitfly",  0.02},  -- 果蝇王
    {"leif",  0.02},  -- 树精守卫
    {"leif_sparse",  0.02},  -- 树精守卫
    {"spiderqueen",  0.02},  -- 蜘蛛女王
    {"malbatross",  0.02},  -- 邪天翁
    {"warg",  0.02},  -- 座狼
    {"spat",  0.02},  -- 钢羊
    --{"shadow_knight",  0.02},  -- 暗影骑士bug
    --{"shadow_bishop",  0.02},  -- 暗影主教bug
    --{"shadow_rook",  0.02},  -- 暗影战车bug
    {"shadowthrall_hands",  0.02},  -- 躁动
    {"shadowthrall_wings",  0.02},  -- 尖叫
    {"shadowthrall_horns",  0.02},  -- 刮擦
    {"worm_boss",  0.02},  -- 巨大洞穴蠕虫
    --{"shadowthrall_centipede_controller",  0.02},  --涟漪bug
    {"rabbitking_aggressive",  0.02},  --暴戾兔王

    -- 第二档：10% 概率掉落 1 个
    --无固定领地/很弱boss
    {"eyeofterror",  0.1},  -- 恐怖之眼
    {"bearger",  0.1},  -- 熊獾
    {"deerclops",  0.1},  -- 独眼巨鹿
    {"antlion",  0.1},  -- 蚁狮
    {"moose",  0.1},  -- 麋鹿鹅

    -- 第三档：20% 概率掉落 1 个
    --固定领地/较强boss
    {"klaus",  0.2},  -- 克劳斯
    {"twinofterror1",  0.2},  -- 激光眼
    {"twinofterror2",  0.2},  -- 魔焰眼
    --{"vault_pillar_guard",  0.2},  -- 远古戍卫塔bug
    {"toadstool",  0.2},  -- 毒菌蟾蜍
    {"beequeen",  0.2},  -- 蜂王
    {"minotaur",  0.2},  -- 远古守护者
    {"dragonfly",  0.2},  -- 龙蝇

    {"shark",  0.2},  -- 岩石大白鲨
    {"gnarwail",  0.2},  -- 一角鲸

    -- 第四档：固定掉落 1 个
    --月后boss/很强boss
    --{"stalker_atrium",  1.00},  -- 远古织影者
    --{"alterguardian_phase1",  1.00},  -- 天体英雄一阶段
    --{"alterguardian_phase2",  1.00},  -- 天体英雄二阶段
    {"alterguardian_phase3",  1.00},  -- 天体英雄三阶段
    {"alterguardian_phase3",  0.50},
    {"alterguardian_phase1_lunarrift",  1.00},  -- 天体仇灵
    --{"wagboss_robot",  1.00},  -- 战争瓦器人bug
    --{"mutateddeerclops",  1.00},  -- 晶体独眼巨鹿
    --{"mutatedbearger",  1.00},  -- 装甲熊獾
    --{"mutatedwarg",  1.00},  -- 附身座狼
    {"toadstool_dark",  1.00},  -- 悲惨的毒菌蟾蜍

    -- 第五档：特殊boss
    --{"alterguardian_phase4_lunarrift",  1.00},  -- 天体后裔
    --{"alterguardian_phase4_lunarrift",  1.00},
    --{"alterguardian_phase4_lunarrift",  1.00},
    --{"alterguardian_phase4_lunarrift",  1.00},
}

for _, entry in ipairs(ANGEL_CRYSTAL_LOOT) do
    local prefab = entry[1]
    local chance = entry[2]

    AddPrefabPostInit(prefab, function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end

        if not inst.components.lootdropper then
            inst:AddComponent("lootdropper")
        end

        inst.components.lootdropper:AddChanceLoot("angelcrystal", chance)
    end)
end

--变异Boss统一处理
local LOOTSETUP_BOSSES = {
    {"lordfruitfly",  0.02},  -- 果蝇王bug
    {"stalker_atrium",  1.00},  -- 远古织影者
    {"stalker_atrium",  0.50},
    {"mutatedbearger",  1.00},  -- 装甲熊獾
    {"mutateddeerclops",  1.00},  -- 晶体独眼巨鹿
    {"mutatedwarg",  1.00},  -- 附身座狼
    {"alterguardian_phase4_lunarrift",  1.00},  -- 天体后裔
    {"alterguardian_phase4_lunarrift",  1.00},
    {"alterguardian_phase4_lunarrift",  1.00},
    {"alterguardian_phase4_lunarrift",  1.00},
}

for _, entry in ipairs(LOOTSETUP_BOSSES) do
    local prefab = entry[1]
    local chance = entry[2]

    AddPrefabPostInit(prefab, function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end

        if inst.components.lootdropper and inst.components.lootdropper.lootsetupfn then
            local old_setup = inst.components.lootdropper.lootsetupfn
            inst.components.lootdropper:SetLootSetupFn(function(lootdropper)
                old_setup(lootdropper)
                lootdropper:AddChanceLoot("angelcrystal", chance)
            end)
        end
    end)
end

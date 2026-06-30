local remove_tradable = GetModConfigData('RemoveThuleciteTradable')
if not remove_tradable then return end

AddPrefabPostInit("thulecite", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    if inst.components.tradable then
        inst:RemoveComponent("tradable")
    end
end)
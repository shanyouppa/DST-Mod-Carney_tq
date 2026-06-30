local windyknifestatus = Class(function(self, inst)
    self.inst = inst
    self.level = 0
    self.use = 200
end,
nil,
{
})

function windyknifestatus:OnSave()
    local data = {
        level = self.level,
        use = self.use,
    }
    return data
end

function windyknifestatus:OnLoad(data)
    self.level = data.level or 0
    self.use = data.use or 0
end

function windyknifestatus:DoDeltaLevel(delta)
    self.level = self.level + delta
    self.inst:PushEvent("DoDeltaLevelWindyKnife")
end

return windyknifestatus
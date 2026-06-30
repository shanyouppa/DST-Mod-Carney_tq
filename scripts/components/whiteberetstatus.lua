local whiteberetstatus = Class(function(self, inst)
    self.inst = inst
    self.level = 0
end,
        nil,
        {
        })

function whiteberetstatus:OnSave()
    local data = {
        level = self.level,
    }
    return data
end

function whiteberetstatus:OnLoad(data)
    self.level = data.level or 0
end

return whiteberetstatus
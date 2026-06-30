local carneytempstatus = Class(function(self, inst)
    self.inst = inst
    self.exptotal = 0
    self.level = 0
    self._userid = nil
    self._playername = ""
end,
nil,
{
})

function carneytempstatus:OnSave()
    local data = {
        exptotal = self.exptotal,
        level = self.level,
        _userid = self._userid,
        _playername = self._playername,
    }
    return data
end

function carneytempstatus:OnLoad(data)
    self.exptotal = data.exptotal or 0
    self.level = data.level or 0
    self._userid = data._userid or nil
    self._playername = data._playername or ""
    self.inst.components.finiteuses:SetUses(self.exptotal)
    self.inst.components.finiteuses:SetMaxUses(self.level)
    self.inst.components.named:SetName(self._playername..STRINGS.CARNEYSTRINGS[3])
end

return carneytempstatus
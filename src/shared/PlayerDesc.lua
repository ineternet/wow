local Global = require(script.Parent.Global)

local PlayerDesc = Global.use"Object".inherit"PlayerDesc"

--Contains active data about a player.

PlayerDesc.new = Global.Constructor(PlayerDesc, {
    player = nil, --Player instance

    party = nil, -- Ref to party object

    xp = 0, --TOTAL accumulated XP

    talents = Global.use"TalentTree".new,
}, function(self, player, dbEntry)
    self.player = player
    self.talents:Deserialize(dbEntry.talents)
    self.xp = dbEntry.xp
end)

PlayerDesc.gainXp = function(self, xp)
    self.xp = self.xp + xp
    --TODO: level up
end

PlayerDesc.saveToDb = function(self)
    --TODO
end



return PlayerDesc
setfenv(1, require(script.Parent.Global))

local PlayerDesc = use"Object".inherit"PlayerDesc"

--Contains active data about a player.

PlayerDesc.new = Constructor(PlayerDesc, {
    player = nil, --Player instance

    party = nil, -- Ref to party object

    xp = 0, --TOTAL accumulated XP

    talents = use"TalentTree".new,
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
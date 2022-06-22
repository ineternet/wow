setfenv(1, require(script.Parent.Global))

local PlayerUnit = use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Constructor(PlayerUnit, {
    player = nil, --Player instance
    
    party = nil, -- Ref to party object

    xp = 0, --TOTAL accumulated XP

    talents = use"TalentTree".new,

    unit = use"ResourceUnit".new,
}, function(self, player, dbEntry)
    self.player = player
    self.talents:Deserialize(dbEntry.talents)
    self.unit:Deserialize(dbEntry.unit)
    self.xp = dbEntry.xp
    self.unit.charsheet:Deserialize(dbEntry.charsheet)
end)

PlayerUnit.gainXp = function(self, xp)
    self.xp = self.xp + xp
    --TODO: level up
end

PlayerUnit.saveToDb = function(self)
    --TODO
end



return PlayerUnit
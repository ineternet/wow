setfenv(1, require(script.Parent.Global))

local Party = use"Object".inherit"Party"

--A spellbook is a collection of spells.

Party.new = Constructor(Party, {
    members = {}, --First is always leader
})

Party.isRaid = function(self)
    return #self.members > PartySize.Party
end

Party.disband = function(self)

end

Party.playerTryLeave = function(self, player)

end

Party.playerTryJoin = function(self, player)

end

Party.memberTryToInvitePlayer = function(self, partyMember, player)

end



return Party
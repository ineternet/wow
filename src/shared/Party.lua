setfenv(1, require(script.Parent.Global))

local Party = use"Object".inherit"Party"

--A spellbook is a collection of spells.

Party.new = Constructor(Party, {
    --Array
    members = {}, --First is always leader

    isRaid = false,
})

Party.leader = function(self)
    return self.members[1]
end

Party.isRaid = function(self)
    return self.isRaid
end

Party.convertToRaid = function(self)
    self.isRaid = true
end

Party.revertToParty = function(self)
    self.isRaid = false
end

Party.disband = function(self)
    for _, member in ipairs(self.members.noproxy) do
        self:playerTryLeave(member)
    end
    gc(self)
end

Party.playerTryLeave = function(self, player)
    for i, member in ipairs(self.members.noproxy) do
        if member == player then
            table.remove(self.members.noproxy, i)
            self.members.dirty = true --TODO
            return
        end
    end
end


Party.playerTryJoin = function(self, player)
    if #self.members.noproxy >= PartySize.Party and not self.isRaid then
        return false
    end
    replicatedInsert(self.members, player)
    return true
end

Party.memberTryToInvitePlayer = function(self, partyMember, player)
    
end



return Party
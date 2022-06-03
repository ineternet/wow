setfenv(1, require(script.Parent.Global))

local Spellbook = use"Object".inherit"Spellbook"

--A spellbook is a collection of spells.

Spellbook.new = Constructor(Spellbook, {
    spells = {},
})

Spellbook.learn = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")

    if not self:hasSpell(spell) then
        table.insert(self.spells, spell)
    end
end

Spellbook.hasSpell = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")
    
    for _, spellbookSpell in ipairs(self.spells) do
        if spellbookSpell.id == spell.id then
            return true
        end
    end
    return false
end

Spellbook.onSpellCritical = function(self, unit, spell, spellTarget, spellLocation) --Fired when spell damage is a critical hit.
    
    --Fire Mage: Proc Hot Streak on fire crits
    print("Critted")
    if self:hasSpell(Spells.HotStreak) then
        print"Streak learned"
        if spell.school and spell.school == Schools.Fire then
            print"Fire school"
            unit:cast(Spells.HotStreak, unit)
        end
    end

    
end

return Spellbook
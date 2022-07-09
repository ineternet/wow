setfenv(1, require(script.Parent.Global))

local Spellbook = use"Object".inherit"Spellbook"
local SpellbookEntry = use"Object".inherit"SpellbookEntry"

--A spellbook is a collection of spells.

Spellbook.new = Constructor(Spellbook, {
    spells = {},
})

SpellbookEntry.new = Constructor(SpellbookEntry, {
    spell = nil,

    charges = 0,
    rechargeNextAt = 0,
    readyAt = 0,

})

Spellbook.learn = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")

    if not self:hasSpell(spell) then
        local newSpellbookEntry = SpellbookEntry.new()
        newSpellbookEntry.spell = spell
        newSpellbookEntry.charges = spell.charges
        newSpellbookEntry.recharge = newSpellbookEntry.charges
        table.insert(self.spells, newSpellbookEntry)
        return true, ""
    end
    return false, "Spell already known"
end

Spellbook.unlearn = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            table.remove(self.spells, i)
            return true, ""
        end
    end
    return false, "Spell not known"
end

Spellbook.ready = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            --TODO: locked
            --TODO: silence/impaired
            local rdy = spellbookEntry.readyAt <= utctime()
            if spellbookEntry.spell.charges then
                rdy = rdy and spellbookEntry.charges > 0
            end
            return rdy
        end
    end
    return false, "Spell not known"
end

Spellbook.hasSpell = function(self, spell)
    assertObj(spell)
    spell:assertIs("Spell")
    
    for _, entry in ipairs(self.spells) do
        if entry.spell.id == spell.id then
            return true
        end
    end
    return false
end

Spellbook.tick = function(self, deltaTime)
    --Handle recharges
    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.charges then
            if spellbookEntry.charges < spellbookEntry.spell.charges and spellbookEntry.rechargeNextAt <= utctime() then
                spellbookEntry.charges = spellbookEntry.charges + 1
                spellbookEntry.rechargeNextAt = utctime() + spellbookEntry.spell.recharge
            end
        end
    end

    Spellbook.super.tick(self, deltaTime)
end

Spellbook.postCast = function(self, spell, unit)
    assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            if spellbookEntry.spell.charges then
                if spellbookEntry.spell.charges == spellbookEntry.spell.charges then
                    --If we just got off max charges, init recharge
                    spellbookEntry.rechargeNextAt = utctime() + spellbookEntry.spell.recharge
                end
                spellbookEntry.charges = spellbookEntry.charges - 1
            end
            spellbookEntry.readyAt = utctime() + resolveNumFn(spellbookEntry.spell.cooldown, unit.charsheet)
            return true
        end
    end
    return false
end

Spellbook.onDealDamage = function(self, unit, victim, damage, school, sourceSpellOrAura)
    --Fired when the spellbook owner deals damage.

    --Affliction Warlock: Generate Fel Energy from Agony damage
    if self:hasSpell(Spells.AfflictionFelEnergy) then
        if sourceSpellOrAura
        and sourceSpellOrAura.is
        and sourceSpellOrAura:is("AuraInstance")
        and sourceSpellOrAura.aura.id == Auras.Agony.id then
            --Every Agony beyond the first generates less FE
            local agonies = 0
            for _, castedAura in ipairs(unit.castAuras.noproxy) do
                if castedAura.aura.id == Auras.Agony.id then
                    agonies = agonies + 1
                end
            end
            local gained = 1.5 + 2.5 * math.max(1, agonies) ^ (-2/3)
            unit:deltaResourceAmount(Resources.FelEnergy, gained)
        end
    end
end

Spellbook.onSpellCritical = function(self, unit, spell, spellTarget, spellLocation)
    --Fired when spell damage is a critical hit.
    
    --Fire Mage: Proc Hot Streak on fire crits
    if self:hasSpell(Spells.HotStreak) then
        if spell.school and spell.school == Schools.Fire then
            unit:cast(Spells.HotStreak, unit)
        end
    end

    
end

return Spellbook
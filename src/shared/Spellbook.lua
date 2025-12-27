local Const = require(script.Parent.Const)
local Global = require(script.Parent.Global)
local Races = Const.Races
local Classes = Const.Classes
local Specs = Const.Specs
local CastType = Const.CastType
local Schools = Const.Schools
local Resources = Const.Resources
local Auras = Const.Auras
local Spells = Const.Spells

local Spellbook = Global.use"Object".inherit"Spellbook"

--A spellbook is a collection of learned spells and spell states.

Spellbook.new = Global.Constructor(Spellbook, {
    spells = {},
}, function(self, charsheet)
    self:updateRaceSpells(charsheet)
    self:updateClassSpells(charsheet)
    self:updateSpecSpells(charsheet)
end)

Spellbook.learn = function(self, spell)
    Global.assertObj(spell)
    spell:assertIs("Spell")

    if not self:hasSpell(spell) then
        local newSpellbookEntry = Global.use"SpellbookEntry".new()
        newSpellbookEntry.spell = spell
        newSpellbookEntry.charges = spell.charges
        newSpellbookEntry.recharge = newSpellbookEntry.charges
        table.insert(self.spells, newSpellbookEntry)
        return true, ""
    end
    return false, "Spell already known"
end

Spellbook.unlearn = function(self, spell)
    Global.assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            table.remove(self.spells, i)
            return true, ""
        end
    end
    return false, "Spell not known"
end

local raceSpellbooks = {
    [Races.None] = {},
    [Races.Werebeast] = {
        [Spells.Vicious] = 1,
    }
}

local classSpellbooks = {
    [Classes.Classless] = {},
    [Classes.Warlock] = {
        [Spells.StartAttack] = 1,
        [Spells.Corruption] = 1,
        [Spells.Agony] = 4,
        [Spells.DrainLife] = 1,
    }
}

local specSpellbooks = {
    [Specs.None] = {},
    [Specs.Affliction] = {
        [Spells.AfflictionFelEnergy] = 1
    }
}

local function genericLearnSpellbook(fromTable, check)
    return function(self, sheet)
        --Unlearn spells from other tables, and too high level spells
        for ch, book in pairs(fromTable) do
            for spell, level in ipairs(book) do
                if ch ~= sheet[check] or level > sheet.level then
                    self:unlearn(spell)
                end
            end
        end

        --Learn known spells
        for spell, level in pairs(fromTable[sheet[check]]) do
            if level <= sheet.level then
                self:learn(spell)
            end
        end
    end
end

Spellbook.updateRaceSpells = genericLearnSpellbook(raceSpellbooks, "race")
Spellbook.updateClassSpells = genericLearnSpellbook(classSpellbooks, "class")
Spellbook.updateSpecSpells = genericLearnSpellbook(specSpellbooks, "spec")

Spellbook.ready = function(self, spell)
    Global.assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            --TODO: locked
            --TODO: silence/impaired
            local rdy = spellbookEntry.readyAt <= Global.utctime()
            if spellbookEntry.spell.charges then
                rdy = rdy and spellbookEntry.charges > 0
            end
            return rdy
        end
    end
    return false, "Spell not known"
end

Spellbook.hasSpell = function(self, spell)
    Global.assertObj(spell)
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
            if spellbookEntry.charges < spellbookEntry.spell.charges and spellbookEntry.rechargeNextAt <= Global.utctime() then
                spellbookEntry.charges = spellbookEntry.charges + 1
                spellbookEntry.rechargeNextAt = Global.utctime() + spellbookEntry.spell.recharge
            end
        end
    end

    Spellbook.super.tick(self, deltaTime)
end

Spellbook.onCreateUnit = function(self, unit)
    for _, spellbookEntry in ipairs(self.spells) do
        local spell = spellbookEntry.spell
        if spell.castType == CastType.PermanentAura then
            Global.use"Spell".ApplyAura(spell, unit, spell.permanentAura, unit)
        end
    end
end

Spellbook.postCast = function(self, spell, unit)
    Global.assertObj(spell)
    spell:assertIs("Spell")

    for i, spellbookEntry in ipairs(self.spells) do
        if spellbookEntry.spell.id == spell.id then
            if spellbookEntry.spell.charges then
                if spellbookEntry.spell.charges == spellbookEntry.spell.charges then
                    --If we just got off max charges, init recharge
                    spellbookEntry.rechargeNextAt = Global.utctime() + spellbookEntry.spell.recharge
                end
                spellbookEntry.charges = spellbookEntry.charges - 1
            end
            spellbookEntry.readyAt = Global.utctime() + Global.resolveNumFn(spellbookEntry.spell.cooldown, unit.charsheet)
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

Spellbook.onEquipmentChange = function(self, unit)
    --Fired when equipment changes.

    --All classes: Apply or remove Armor Proficiency
    if self:hasSpell(Spells.WarlockArmorProficiency) then
        --TODO
    end
end

return Spellbook
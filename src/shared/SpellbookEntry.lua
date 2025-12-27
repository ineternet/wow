local Const = require(script.Parent.Const)
local Global = require(script.Parent.Global)

local SpellbookEntry = Global.use"Object".inherit"SpellbookEntry"

--An entry in a spellbook representing a spell state.

SpellbookEntry.new = Global.Constructor(SpellbookEntry, {
    spell = nil,

    charges = 0,
    rechargeNextAt = 0,
    readyAt = 0,
})

return SpellbookEntry

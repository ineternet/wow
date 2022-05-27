local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)

local tu = units.new()

tu.charsheet.class = const.Classes.Mage
tu.charsheet.race = const.Races.Werebeast
tu.charsheet.level = 16

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = tu.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)


print(("Level %d %s %s %s has %d Spell Power. Equipment: "):format(
    tu.charsheet.level,
    const.Specs[tu.charsheet.spec],
    const.Classes[tu.charsheet.class],
    const.Races[tu.charsheet.race],
    tu.charsheet:spellPower()
))
print(tu.charsheet.equipment)

--> 5
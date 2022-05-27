local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)

local char = units.new()

char.charsheet.class = const.Classes.Mage
char.charsheet.race = const.Races.Werebeast
char.charsheet.level = 16

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = char.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)


print(("Level %d %s %s %s has %d Spell Power. Equipment: "):format(
    char.charsheet.level,
    const.Specs[char.charsheet.spec],
    const.Classes[char.charsheet.class],
    const.Races[char.charsheet.race],
    char.charsheet:spellPower()
))
print(char.charsheet.equipment)

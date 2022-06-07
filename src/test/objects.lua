--Environment setup code
---@diagnostic disable-next-line: undefined-global
package.path = "./?/init.lua;" .. package.path

local lemur = require("lemur")
local habitat = lemur.Habitat.new()

local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")
local root = habitat:loadFromFs("src/shared", {
    loadInitModules = true
})
root.Parent = ReplicatedStorage
--End Environment setup code
local units = habitat:require(root.ResourceUnit)
local items = habitat:require(root.Item)
local const = habitat:require(root.Const)
local env = habitat:require(root.Global)

local tu = units.new()
tu.charsheet.class = const.Classes.Mage
tu.charsheet.race = const.Races.Werebeast
tu.charsheet.level = 17
tu:updateClassResources()
tu.primaryResourceAmount = tu.primaryResourceMaximum
tu.secondaryResourceAmount = tu.secondaryResourceMaximum

local enemy = units.new()
enemy.charsheet.class = const.Classes.Warrior
enemy.charsheet.spec = const.Specs.None
enemy.charsheet.race = const.Races.None
enemy.charsheet.level = 14
enemy.charsheet.healthRegen = const.NoResourceRegeneration
enemy.primaryResource = const.Resources.Health
enemy.primaryResourceMaximum = 400
enemy.primaryResourceAmount = 400

tu:target(enemy)

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = tu.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)

print("Spell Power:", tu.charsheet:spellPower(tu))

tu.spellbook:learn(const.Spells.FireBlast)
tu.spellbook:learn(const.Spells.Pyroblast)

print("Can cast Fire Blast:", tu:canCast(const.Spells.FireBlast))
print("Casting Fire Blast:", tu:wantToCast(const.Spells.FireBlast) and "success" or "fail")
print("Can cast Fire Blast:", tu:canCast(const.Spells.FireBlast))
print("Skipping 1 second")
env.UnreplicatedTimeTravel(1)
print("Can cast Fire Blast:", tu:canCast(const.Spells.FireBlast))
print("Casting Fire Blast:", tu:wantToCast(const.Spells.FireBlast) and "success" or "fail")
print("Skipping 12 seconds")
env.UnreplicatedTimeTravel(12)
print("Can cast Fire Blast:", tu:canCast(const.Spells.FireBlast))


--> 51
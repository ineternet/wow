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

tu:targetUnit(enemy)

local stamdagger = items.newOf(const.Items.StamDagger)
local stamdagger2 = items.newOf(const.Items.StamDagger)

local _ = tu.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)
local _ = tu.charsheet.equipment:swap(const.Slots.OffHand, stamdagger2)

print("Spell Power:", tu.charsheet:spellPower(tu))

tu.spellbook:learn(const.Spells.StartAttack)
tu.spellbook:learn(const.Spells.FireBlast)
tu.spellbook:learn(const.Spells.Pyroblast)

print("Enemy Hp:", enemy.primaryResourceAmount)
print("Casting Attack:", tu:wantToCast(const.Spells.StartAttack))
print("Enemy Hp:", enemy.primaryResourceAmount)
print("Skipping 5 seconds")
env.UnreplicatedTimeTravel(5)
print("Enemy Hp:", enemy.primaryResourceAmount)


--> 51
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

tu.charsheet.spellbook:learn(const.Spells.StartAttack)
tu.charsheet.spellbook:learn(const.Spells.FireBlast)
tu.charsheet.spellbook:learn(const.Spells.Pyroblast)
tu.charsheet.spellbook:learn(const.Spells.Spellsteal)
tu.charsheet.spellbook:learn(const.Spells.Kleptomancy)
--ll.ApplyAura = function(spell, toUnit, aura, causer, auraData)
env.use"Spell".ApplyAura(nil, enemy, const.Auras.ArcaneIntellect, nil, { duration = 60*60 })
env.use"Spell".ApplyAura(const.Spells.Corruption, enemy, const.Auras.Corruption, tu, { duration = 60*60 })

print("Enemy Aura Num:   ", #enemy.auras.noproxy)
print("Enemy Aura #1 Name:", enemy.auras.noproxy[1].aura.name)
print("Caster Aura Num:", #tu.auras.noproxy)
print("Caster Int:     ", tu.charsheet:intellect(tu))
print("Casting Spellsteal:", tu:wantToCast(const.Spells.Spellsteal))
print("Enemy Aura Num:   ", #enemy.auras.noproxy)
print("Caster Aura Num:", #tu.auras.noproxy)
print("Caster Int:     ", tu.charsheet:intellect(tu))

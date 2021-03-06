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
local playerdesc = habitat:require(root.PlayerDesc)
local playerunits = habitat:require(root.PlayerUnit)
local items = habitat:require(root.Item)
local const = habitat:require(root.Const)
local env = habitat:require(root.Global)

local plr = playerdesc.new(nil, "", { --Mock DB entry
    xp = 0,
    talents = {

    },
})

local tu = playerunits.new(nil, plr)
tu.charsheet.class = const.Classes.Warlock
tu.charsheet.spec = const.Specs.Affliction
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
const.Enchants.MinorStamina:applyToItem(stamdagger)
local hastering = items.newOf(const.Items.HasteRing)
local _ = tu.charsheet.equipment:swap(const.Slots.Ring1, hastering)

tu.charsheet.spellbook:learn(const.Spells.StartAttack)
tu.charsheet.spellbook:learn(const.Spells.FireBlast)
tu.charsheet.spellbook:learn(const.Spells.Pyroblast)
tu.charsheet.spellbook:learn(const.Spells.Spellsteal)
tu.charsheet.spellbook:learn(const.Spells.Kleptomancy)
tu.charsheet.spellbook:learn(const.Spells.Corruption)
tu.charsheet.spellbook:learn(const.Spells.Agony)
tu.charsheet.spellbook:learn(const.Spells.AfflictionFelEnergy)
tu.player.talents:change(tu.charsheet, const.TalentTier.Level10, const.TalentChoice.Left)

local function printTooltip(lines)
    local length = 0
    for _, line in ipairs(lines) do
        if #line > length then
            length = #line
        end
    end
    print(" " .. ("_"):rep(length) .. " ")
    for _, line in ipairs(lines) do
        print("|" .. line .. (" "):rep(length - #line) .. "|")
    end
    print("|" .. ("_"):rep(length) .. "|")
end

local function strtolines(str)
    local lines = {}
    for line in str:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

local testTooltip

local subject = const.Spells.Corruption
testTooltip = subject.tooltip(tu.charsheet)
testTooltip = strtolines(testTooltip)
table.insert(testTooltip, 1, subject.name)

printTooltip(testTooltip)

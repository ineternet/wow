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

local tu = units.new()
tu.charsheet.class = const.Classes.Mage
tu.charsheet.race = const.Races.Werebeast
tu.charsheet.level = 17

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = tu.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)

print(tu.charsheet:spellPower(tu))
--> 51
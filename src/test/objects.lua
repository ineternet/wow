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

local tu = units.new()

local stamdagger = items.newOf(2)

local _ = tu.charsheet.equipment:swap("MainHand", stamdagger)

print(tu.charsheet:stamina())
--> 5
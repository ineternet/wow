local Global = require(script.Parent.Global)
local Const = require(script.Parent.Const)
local Enchants = Const.Enchants

local Enchant = Global.use"Object".inherit"Enchant"

local logicalIncrement = 0
Enchant.new = Global.Constructor(Enchant, {
    icon = "rbxassetid://1337",

    --mod = {},
    --flat = {},

    slot = Const.Slots.None
}, function(self)
    --Automatically assign id to have a common reference point sides
    logicalIncrement = logicalIncrement + 1
    self.id = logicalIncrement
end)

Enchant.applyToItem = function(self, item)
    --Check if the enchant can be applied to the item
    local idef = item.item
    if self.slot == Const.Slots.None then
        return false, "Enchant does not go on equipped items"
    elseif not idef.equipSlot then
        return false, "Item is not equipable"
    elseif self.slot == Const.Slots.Any then
        --Pass (enchant can be applied to any slot)

    elseif
        (self.slot == Const.Slots.TwoHandWeapon and
            idef.equipSlot == Const.Slots.MainHand and idef.takeBothHands == true)
    then
        --Pass (special cases)

    elseif self.slot ~= idef.equipSlot then
        return false, "Enchant can't be applied to this slot"
    end

    --TODO: Before this, check for previous enchant
    item.enchant = self
    return true, ""
end

Enchants.MinorStamina = Enchant.new()
Enchants.MinorStamina:assign({
    name = "Weapon: Minor Stamina",
    tooltip = function(sheet)
        local str = "When applied to a main hand weapon, increases your Stamina by %s."
        return str
    end,
    flat = {
        stamina = 5
    },
    slot = Const.Slots.MainHand
})

return Enchant
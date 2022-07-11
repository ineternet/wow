setfenv(1, require(script.Parent.Global))

local Equipment = use"Object".inherit"Equipment"

--Equipment state

local itemStringConstructor = use"Item".newOf
Equipment.new = Constructor(Equipment, {
    slots = {
        --nil means empty slot
        [Slots.Head] = nil,
        [Slots.Neck] = nil,
        [Slots.Back] = nil,
        [Slots.Chest] = nil,
        [Slots.Hands] = nil,
        [Slots.Legs] = nil,
        [Slots.Feet] = nil,
        [Slots.Shirt] = nil,
        [Slots.Ring1] = nil,
        [Slots.Ring2] = nil,
        [Slots.Trinket1] = nil,
        [Slots.MainHand] = nil,
        [Slots.OffHand] = nil,
    },
})

local equippableSlots = {
    [Slots.Head] = true,
    [Slots.Neck] = true,
    [Slots.Back] = true,
    [Slots.Chest] = true,
    [Slots.Hands] = true,
    [Slots.Legs] = true,
    [Slots.Feet] = true,
    [Slots.Shirt] = true,
    [Slots.Ring1] = true,
    [Slots.Ring2] = true,
    [Slots.Trinket1] = true,
    [Slots.MainHand] = true,
    [Slots.OffHand] = true,
}

--[[
    Find out how many of a single stat this entire equipment set provides.
    @param stat The stat to check for.
    @return The added flat value of the stat.
    @return The added percentage value for the stat.
]]
function Equipment:aggregate(stat)
    local base = 0
    for _, item in pairs(self.slots.noproxy) do
        if item and item.item and item.item.flat and item.item.flat[stat] then
            base = base + item:flat(stat)
        end
    end
    local mod = 1
    for _, item in pairs(self.slots.noproxy) do
        if item and item.item and item.item.mod and item.item.mod[stat] then
            mod = mod * item:mod(stat)
        end
    end
    return base, mod
end

--[[
    Swap an item in a slot with another item.
    @param slot The slot to swap. Must be a valid slot (see equippableSlots).
    @param newItem The item to swap with. If nil, the slot will be emptied.
    @return The item that was previously in the slot. If the slot was empty, nil.
]]
Equipment.swap = function(self, slot, newItem)
    assertObj(newItem)
    newItem:assertIs("Item")

    if newItem.item.equipSlot ~= slot then
        if newItem.item.equipSlot == Slots.MainHand and newItem.item.twoHanded then
            if slot == Slots.OffHand then
                slot = Slots.MainHand --We assume this was the intended slot
            end
            if self[Slots.OffHand] ~= nil then
                return false, "Off-hand slot must be empty to equip a two-handed weapon."
                --This error is not game-relevant because the client will automatically unequip the off-hand weapon.
            end
        end
        if (slot == Slots.Ring1 or slot == Slots.Ring2) and newItem.item.equipSlot == Slots.Ring then
            --Ring1 and Ring2 accept Ring
        elseif slot == Slots.Trinket1 and newItem.item.equipSlot == Slots.Trinket then
            --Trinket1 accepts Trinket
        elseif slot == Slots.OffHand and newItem.item.equipSlot == Slots.MainHand and newItem.item.dualWieldable then
            --OffHand accepts MainHand if it can dual wield
        elseif newItem.item.equipSlot == Slots.Any then
            --Item can be equipped in any slot
        elseif newItem.item.equipSlot == Slots.None then
            return false, "Item cannot be equipped."
        elseif not equippableSlots[slot] then
            return false, "Invalid slot " .. Slots[slot] .. "."
        else
            return false, "Item cannot be equipped in " .. Slots[slot] .. "."
        end
    end

    local oldItem = self.slots[slot]
    self.slots[slot] = newItem
    return oldItem, ""
end

function Equipment:has(slot)
    return self.slots[slot] ~= nil and self.slots[slot] ~= Items.NullItem
end

function Equipment:get(slot)
    return self.slots[slot]
end

return Equipment
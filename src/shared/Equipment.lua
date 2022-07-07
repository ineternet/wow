setfenv(1, require(script.Parent.Global))

local Equipment = use"Object".inherit"Equipment"

--Equipment state

local itemStringConstructor = use"Item".newOf
Equipment.new = Constructor(Equipment, {
    slots = {
        --For now code everything to work with nil values AND "null items". Still unclear if this will use nil values or "null items".
        --[[[Slots.Head] = itemStringConstructor"NullItem",
        [Slots.Neck] = itemStringConstructor"NullItem",
        [Slots.Back] = itemStringConstructor"NullItem",
        [Slots.Chest] = itemStringConstructor"NullItem",
        [Slots.Hands] = itemStringConstructor"NullItem",
        [Slots.Legs] = itemStringConstructor"NullItem",
        [Slots.Feet] = itemStringConstructor"NullItem",
        [Slots.Shirt] = itemStringConstructor"NullItem",
        [Slots.Ring1] = itemStringConstructor"NullItem",
        [Slots.Ring2] = itemStringConstructor"NullItem",
        [Slots.Trinket1] = itemStringConstructor"NullItem",
        [Slots.MainHand] = itemStringConstructor"NullItem",
        [Slots.OffHand] = itemStringConstructor"NullItem",]]
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
    }
})

function Equipment:aggregate(stat)
    local base = 0
    for _, item in pairs(self.slots.noproxy) do
        if item and item:def() and item:def().flat and item:def().flat[stat] then
            base = base + item:flat(stat)
        end
    end
    local mod = 1
    for _, item in pairs(self.slots.noproxy) do
        if item and item:def() and item:def().mod and item:def().mod[stat] then
            mod = mod * item:mod(stat)
        end
    end
    return base, mod
end

function Equipment:swap(slot, newItem)
    assertObj(newItem)
    newItem:assertIs("Item")
    local oldItem = self.slots[slot]
    self.slots[slot] = newItem
    return oldItem
end

function Equipment:has(slot)
    return self.slots[slot] ~= nil and self.slots[slot] ~= Items.NullItem
end

function Equipment:get(slot)
    return self.slots[slot]
end

return Equipment
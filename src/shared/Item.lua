setfenv(1, require(script.Parent.Global))

local Item = use"Object".inherit"Item"

--Singular item

Item.new = Constructor(Item, {
    item = nil,

    durability = 0,

    rarityOverride = nil,

    enchant = nil,
    sockets = {},
})

Item.newOf = function(item)
    local newItem = Item.new()
    newItem.item = item
    return newItem
end

function Item:flat(stat)
    local value = self.item.flat[stat]
    if self.enchant and self.enchant.flat and self.enchant.flat[stat] then
        value = value + self.enchant.flat[stat]
    end
    return value
end

function Item:mod(stat)
    local value = self.item.mod[stat]
    if self.enchant and self.enchant.mod and self.enchant.mod[stat] then
        value = value + self.enchant.mod[stat]
    end
    return value
end

function Item:swingable()
    return self.item.attacksPerSecond and true or false
end

function Item:swingTimeout()
    return 1 / self.item.attacksPerSecond
end

return Item
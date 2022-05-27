setfenv(1, require(script.Parent.Global))

local Item = use"Object".inherit"Item"

--Singular item

Item.new = Constructor(Item, {
    itemId = 0,

    durability = 0,

    rarityOverride = nil,

    enchant = nil,
    sockets = {},
})

Item.newOfName = function(itemName)
    return Item.newOfId(Items[itemName].id)
end

Item.newOf = function(item)
    return Item.newOfId(item.id)
end

Item.newOfId = function(id)
    local newItem = Item.new()
    newItem.itemId = id
    return newItem
end

function Item:def()
    return Items[self.itemId]
end

function Item:flat(stat)
    return self:def().flat[stat]
end

function Item:percentage(stat)
    return self:def().percentage[stat]
end

return Item
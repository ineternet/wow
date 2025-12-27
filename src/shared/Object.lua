local Const = require(script.Parent.Const)
local Global = require(script.Parent.Global)

local Object = {}

-- Metamethods
setmetatable(Object, {
    __eq = function(a, b)
        return a:Equals(b)
    end
})

-- Constants

Object.super = Object
Object.type = "Object"
Global.__RegisterType(Object.type, Object)

-- Static getters



-- Static functions
local xinherit = function(superclass)
    return function(newname) return Object.inherit(newname, superclass) end
end

Object.inherit = function(newname, superclass)
    local generatedClass = {}
    generatedClass.type = newname
    generatedClass.super = superclass or Object
    generatedClass.inherit = xinherit(generatedClass)
    Global.__RegisterType(newname, generatedClass)
    return setmetatable(generatedClass, {__index = generatedClass.super})
end

Object.ReferenceEquals = function(refA, refB)
    return refA.ref == refB.ref
end

-- Constructors

Object.new = Global.AbstractClassConstructor

-- Functions

if Global.roblox then
    local downstreamRemote = Instance.new("RemoteFunction")
    Object.downstream = function(self) --This is called on clients and requests the server to update this object.
        local strobj = downstreamRemote.InvokeServer(Global.Remote, Const.Request.Downstream, Global.UniqueRequestId(), self.ref)

        self:Deserialize(strobj)

        return nil --Does not return the new object, only updates the given reference
    end
    if Global.isServer then
        Global.Retrieve.OnServerInvoke = function(player, request, requestId, dsRef) --This handles downstream requests
            if request ~= Const.Request.Downstream then return end
            local obj = Global.__FindByReference(dsRef)
            local objInfo = obj:RemoteSerialize()
            return objInfo --Give the object info back to the client
        end
    end
end

Object.Serialize = function(self) --Serialize the object into a string
    --[[local valTable = {}
    valTable.table = {}
    valTable.metatable = {}
    for k, v in pairs(self) do
        valTable.table[k] = v
    end
    for k, v in pairs(getmetatable(self)) do
        valTable.metatable[k] = v
    end
    return jsonEncode(valTable)]]
    return self --Roblox serialization may do this on its own
end

Object.Deserialize = function(self, str)
    --[[local valTable = jsonDecode(str)
    for k, v in pairs(valTable.table) do
        self[k] = v
    end
    for k, v in pairs(valTable.metatable) do
        getmetatable(self)[k] = v
    end]]
    for k, v in pairs(str) do
        self[k] = v
    end
    return nil
end

Object.RemoteSerialize = Object.Serialize
Object.DataStoreSerialize = Object.Serialize
Object.HttpSerialize = Object.Serialize

Object.tick = function(self, deltaTime)
    --self.dirty = true
end

Object.GetType = function(self)
    Global.assertObj(self)
    return self.type
end

Object.is = function(self, ofType)
    Global.assertObj(self)
    repeat
        if self:GetType() == ofType then
            return true
        end
        self = self.super
    until self.type == Object.type
    return ofType == Object.type
end

Object.assertIs = function(self, strType)
    Global.assertObj(self)
    assert(self:is(strType), "expected " .. strType .. ", got " .. self.type)
end

Object.Equals = Object.ReferenceEquals

Object.Finalize = Global.void

Object.assign = function(self, tbl)
    for k, v in pairs(tbl) do
        self[k] = v
    end
    return self
end

return Object
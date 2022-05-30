local Global = {}

local typeIndex = {}
local const = require(script.Parent.Const)

Global.void = function() end

Global.IsPrimitive = function(x)
    local t = type(x)
    return t == "string" or t == "number" or t == "boolean" or t == "nil"
end

local increment = 0 --TODO: Is there a better way to do this? Counterargument: how is predicting IDs possibly unsafe?
Global.UniqueRequestId = function()
    increment = increment + 1
    if increment > 1e100 then --Although this is highly unlikely
        _, increment = math.modf(increment)
        increment = increment + 0.01 --gives us more numbers to work with
    end
    return increment
end

Global.AbstractClassConstructor = function()
    error("Cannot instantiate object of abstract class")
end

Global.ValueEquals = function(a, b)
    for ak, av in pairs(a) do
        if ak ~= "ref" and ak ~= "eventConnections" and Global.IsPrimitive(av) then
            if b[ak] ~= av then
                return false
            end
        end
    end
    return true
end

local objectIndex = {}
Global.__FindByReference = function(ref)
    local obj = objectIndex[ref]
    if not obj and not game:GetService("RunService"):IsServer() then
        obj = Global.Retrieve:InvokeServer("getref", ref)
        if obj then
            Global.RestoreMt(obj)
            objectIndex[ref] = obj
        else
            error("Could not find object with reference " .. tostring(ref))
        end
    elseif not obj then
        error("Could not find object with reference " .. tostring(ref))
    end
    return obj
end

Global.__RegisterType = function(strType, typeDef)
    typeIndex[strType] = typeDef
    typeIndex[typeDef] = strType
end

local clientTypes = {
    Spell = true,
    Item = true,
    Aura = true,
    Timer = true
}
Global.__MakeObject = function(ofType)
    if not game:GetService("RunService"):IsServer() then
        --Create is allowed only for certain types
        if not clientTypes[ofType.type] then
            error("Cannot create object " .. tostring(ofType.type) .. " on client")
        end
    end
    local newobj = {}
    newobj.ref = tostring(newobj):sub(8)
    newobj.type = typeIndex[ofType]
    newobj.eventConnections = {}
    setmetatable(newobj, {
        __index = ofType,
        __tostring = function(t)
            return ("(%s@%s)"):format(t.type, t.ref)
        end
    })
    Global.__SetReference(newobj.ref, newobj)
    return newobj
end

Global.__SetReference = function(ref, obj)
    objectIndex[ref] = obj
end

Global.Constructor = function(ofType, withValues, postConstructor)
    --return setmetatable({}, { --Keeping this for future thoughts, but the current setup requires this be a function
    --    __call = function(t, sub, ...)
        return function(sub, ...)
            local mo = sub or Global.__MakeObject(ofType)
            local baseConstructor = ofType.super.new
            if baseConstructor and baseConstructor ~= Global.AbstractClassConstructor then
                mo = baseConstructor(mo)
            end
            if type(withValues) == "table" then
                for k, v in pairs(withValues) do
                    if type(v) == "table" then --We assume this is an empty table
                        mo[k] = {}
                    elseif type(v) == "function" then --We assume the constructor wants to call this function
                        mo[k] = v()
                    else
                        mo[k] = mo[k] or v
                    end
                end
            end
            if type(postConstructor) == "function" then
                postConstructor(mo, ...)
            end
            return mo
        end
    --})
end

Global.use = function(strType)
    local ftype = typeIndex[strType]
    if not ftype then
        require(script.Parent[strType])
        ftype = typeIndex[strType]
    end
    return typeIndex[strType]
end

Global.using = function(strType, funcOnX, ...)
    local newobj = Global.use(strType).new(...)
    funcOnX(newobj)
    newobj:Finalize()
end

Global.assertObj = function(d)
    assert(d and type(d) == "table" and d.is, "expected (Object), got " .. type(d) .. " (missing 'is')")
end

Global.Remote = game:GetService("ReplicatedStorage"):WaitForChild("Replicate")
Global.Retrieve = game:GetService("ReplicatedStorage"):WaitForChild("Retrieve")

local function setRefMt(obj)
    return setmetatable({ ref = obj.ref }, {
        __index = function(t, k)
            local obj = Global.__FindByReference(t.ref)
            if obj then
                return obj[k]
            end
        end,
        __newindex = function(t, k, v)
            local obj = Global.__FindByReference(t.ref)
            if obj then
                obj[k] = v
            end
        end,
    })
end

Global.ref = function(obj)
    assert(obj and type(obj) == "table" and obj.ref, "expected (Object), got " .. type(obj) .. " (missing 'ref')")
    if not pcall(function() assertObj(obj) end) then
        warn("Attempted to create reference to non-object. ref: " .. tostring(obj.ref))
    end

    return setRefMt(obj)
end

--TODO: For some reason this doesn't work, for now this code is in a server script
--[[if game:GetService("RunService"):IsServer() then
    print"Server"
    Global.Retrieve.OnServerInvoke = function(player, action, arg)
        print("Retrieve: " .. action)
        if action == "getref" then
            print("Retrieving reference: " .. arg, "for player: " .. player.Name)
            return Global.__FindByReference(arg)
        end
    end
end]]

Global.RestoreMt = function(obj)
    assert(not getmetatable(obj), "Object already has a metatable")
    
    --Set metatable to the object's type
    setmetatable(obj, {
        __index = use(obj.type)
    })

    --Restore ref MTs for first-level references
    for k, v in pairs(obj) do
        if type(v) == "table" and v.ref and not getmetatable(v) then
            setRefMt(v)
        end
    end

    return obj
end

local fenv = getfenv(1)
for k, v in pairs(Global) do
    fenv[k] = v
end
for k, v in pairs(const) do
    fenv[k] = v
end
if _VERSION ~= "Luau" then --Lua 5.1 support
    fenv.math.round = function(x)
        if x > 0 then
            return math.floor(x + 0.5)
        elseif x < 0 then
            return math.ceil(x - 0.5)
        end
        return 0
    end
    fenv.math.clamp = function(x, min, max)
        if x < min then
            return min
        elseif x > max then
            return max
        end
        return x
    end
    fenv.utctime = os.time
    fenv.jsonEncode = function(t)
        error("JSON encoding not supported")
    end
    fenv.jsonDecode = function(t)
        error("JSON decoding not supported")
    end
else --if Luau
    fenv.utctime = tick
    fenv.jsonEncode = function(t)
        return game:GetService("HttpService"):JSONEncode(t)
    end
    fenv.jsonDecode = function(t)
        return game:GetService("HttpService"):JSONDecode(t)
    end
end

return fenv

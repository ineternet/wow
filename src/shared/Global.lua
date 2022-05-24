local Global = {}

local typeIndex = {}
local const = require(script.Parent.Const)

Global.void = function() end

Global.IsPrimitive = function(x)
    local t = type(x)
    return t == "string" or t == "number" or t == "boolean" or t == "nil"
end

Global.AbstractClassConstructor = function()
    error("Cannot instantiate object of abstract class")
end

Global.ValueEquals = function(a, b)
    for ak, av in pairs(a) do
        if ak ~= "ref" and Global.IsPrimitive(av) then
            if b[ak] ~= av then
                return false
            end
        end
    end
    return true
end

Global.__RegisterType = function(strType, typeDef)
    typeIndex[strType] = typeDef
end

Global.__MakeObject = function(ofType)
    local newobj = {}
    newobj.ref = tostring(newobj):sub(8)
    setmetatable(newobj, {
        __index = ofType,
        __tostring = function(t)
            return ("(%s@%s)"):format(t.type, t.ref)
        end
    })
    return newobj
end

Global.Constructor = function(ofType, withValues)
    return setmetatable({}, {
        __call = function(t, sub)
            local mo = sub or Global.__MakeObject(ofType)
            local baseConstructor = ofType.super.new
            if baseConstructor and baseConstructor ~= Global.AbstractClassConstructor then
                mo = baseConstructor(mo)
            end
            if type(withValues) == "table" then
                for k, v in pairs(withValues) do
                    mo[k] = mo[k] or v
                end
            end
            return mo
        end
    })
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
    local newobj = use(strType).new(...)
    funcOnX(newobj)
    newobj:Finalize()
end

local fenv = getfenv(1)
for k, v in pairs(Global) do
    fenv[k] = v
end
for k, v in pairs(const) do
    fenv[k] = v
end
return fenv
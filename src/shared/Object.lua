setfenv(1, require(script.Parent.Global))

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
__RegisterType(Object.type, Object)

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
    __RegisterType(newname, generatedClass)
    return setmetatable(generatedClass, {__index = generatedClass.super})
end

Object.ReferenceEquals = function(refA, refB)
    return refA.ref == refB.ref
end

-- Constructors

Object.new = AbstractClassConstructor

-- Functions

Object.GetType = function(self)
    assertObj(self)
    return self.type
end

Object.is = function(self, ofType)
    assertObj(self)
    repeat
        if self:GetType() == ofType then
            return true
        end
        self = self.super
    until self.type == Object.type
    return ofType == Object.type
end

Object.assertIs = function(self, strType)
    assertObj(self)
    assert(self:is(strType), "expected " .. strType .. ", got " .. self.type)
end

Object.Equals = Object.ReferenceEquals

Object.Finalize = void

Object.assign = function(self, tbl)
    for k, v in pairs(tbl) do
        self[k] = v
    end
    return self
end

return Object
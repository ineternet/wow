local Global = {}

local typeIndex = {}
local const = require(script.Parent.Const)

local isServer = game:GetService("RunService"):IsServer()
if _VERSION ~= "Luau" then
    isServer = true
end

Global.void = function() end

Global.IsPrimitive = function(x)
    local t = type(x)
    return t == "string" or t == "number" or t == "boolean" or t == "nil"
end

local increment = 0 --TODO: Is there a better way to do this? Counterargument: how is predicting IDs possibly unsafe?
Global.UniqueRequestId = function()
    increment = increment + 1
    if increment > 1e100 then --Although this is highly unlikely
---@diagnostic disable-next-line: undefined-global
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
        if ak ~= "ref" and ak ~= "eventConnections" and ak ~= "type" and Global.IsPrimitive(av) then
            if b[ak] ~= av then
                return false
            end
        end
    end
    return true
end

local objectIndex = {}
local activeRetrievals = {}
Global.__FindByReference = function(ref)
    local obj = objectIndex[ref]
    if not obj and not isServer then
        if activeRetrievals[ref] then
            warn("Object reference " .. ref .. " is already being retrieved. Returning nil.")
            return nil
        end
        activeRetrievals[ref] = true
        obj = Global.Retrieve:InvokeServer("getref", ref)
        if obj then
            Global.__SetReference(ref, obj)
            Global.RestoreMt(obj)
            activeRetrievals[ref] = false
        else
            error("Could not find object with reference " .. tostring(ref))
        end
    elseif not obj then
        error("Could not find object with reference " .. tostring(ref))
    end
    return obj
end

local otherHeartbeatConnections = {}
local toUpdateObjects = {}
local toGc = {}
local function handleHeartbeat(dt)
    for _, ohc in pairs(otherHeartbeatConnections) do
        ohc(dt)
    end

    local count = 0
    local gccount = 0
    for ref, obj in pairs(objectIndex) do
        if obj.gc then
            toUpdateObjects[ref] = { gc = true }
            table.insert(toGc, ref)
            gccount = gccount + 1
        elseif obj.dirty then
            local nt = {}
            for _, dirtyKey in ipairs(obj.dirtyKeys) do
                if type(obj[dirtyKey]) == "table" and obj[dirtyKey].noproxy ~= nil then
                    nt[dirtyKey] = obj[dirtyKey].noproxy
                else
                    nt[dirtyKey] = obj[dirtyKey]
                end
            end
            toUpdateObjects[ref] = nt
            count = count + 1
            obj.dirty = false
            obj.dirtyKeys = {}
        end
    end

    if gccount > 0 then
        for _, ref in ipairs(toGc) do
            objectIndex[ref] = nil
        end
        toGc = {}
    end

    if count > 0 then
        Global.Remote:FireAllClients(Request.FullObjectDelta, Global.compress(toUpdateObjects))
        toUpdateObjects = {}
    end
end

Global.compress = function(tab)
    return tab
end

Global.decompress = function(tab)
    return tab
end

if isServer then
    game:GetService("RunService").Heartbeat:Connect(handleHeartbeat)
end

Global.__RegisterType = function(strType, typeDef)
    typeIndex[strType] = typeDef
    typeIndex[typeDef] = strType
end

local clientTypes = {
    --These types:
    -- - Can be created on client side
    -- - Do not get marked dirty
    --   -> do not get passed from server to client on change
    Spell = true,
    Item = true,
    Aura = true,
    Timer = true,
    Effect = true,
}

Global.__MakeObject = function(ofType) --Create object. EVERY created object calls this.
    if not isServer then
        --Client create is allowed only for certain types
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
    local proxy = { dirtyKeys = {}, dirty = false }
    setmetatable(proxy, {
        __index = function(t, k)
            if k == "noproxy_nonrecursive" then
                return newobj
            elseif k == "noproxy" then
                local clone = {}
                for k, v in pairs(newobj) do
                    if type(v) == "table" and v.dirty ~= nil and not v.__isRef then
                        local npx = v.noproxy
                        clone[k] = npx
                    else
                        clone[k] = v
                    end
                end
                --Metatable is not passed on recursion but required for container iterations
                setmetatable(clone, getmetatable(newobj))
                return clone
            end
            local ret = newobj[k]
            --if type(ret) == "table" and not ret.ref then --Containers

            --end
            return ret
        end,
        __newindex = function(t, k, v)
            newobj[k] = v
            if k ~= "dirty" --Prevent infinite recursion
            and isServer --Dirty updates go from server to client only
            and not clientTypes[ofType.type] --Dirty updates are only sent to client for certain types
            then
                table.insert(proxy.dirtyKeys, k)
                proxy.dirty = true
            end
        end,
        __tostring = function(t)
            return tostring(newobj)
        end
    })
    Global.__SetReference(newobj.ref, proxy)
    return proxy
end

local function setRefMt(obj)
    return setmetatable({ ref = obj.ref, type = obj.type }, {
        __index = function(t, k)
            if k == "__isRef" then
                return true
            end
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

Global.UpdateFromDelta = function(ref, obj)
    if obj.gc then
        objectIndex[ref] = nil
        return true
    end
    local existObj = objectIndex[ref]
    if existObj then
        for k, v in pairs(obj) do
            if type(v) == "table" and not v.ref then
                --Create Ref MT for container types
                for i, containedObject in ipairs(v) do
                    v[i] = setRefMt(containedObject)
                end
            end
            existObj[k] = v
        end
        return true
    end
    return false
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
                        local nt = {}
                        local proxytable = { dirty = false }
                        setmetatable(proxytable, { --Container proxy
                            __index = function(t, i)
                                if i == "noproxy" then
                                    --Return base table + all child refs have to be noproxy
                                    local clone = {}
                                    for k, v in pairs(nt) do
                                        if type(v) == "table" and rawget(v, "dirty") ~= nil then
                                            --Set metatable, this is required per side
                                            --clone[k] = setmetatable(v.noproxy, getmetatable(nt))
                                            clone[k] = v.noproxy
                                        else
                                            clone[k] = v
                                        end
                                    end
                                    return clone
                                end
                                return nt[i]
                            end,
                            __newindex = function(t, i, v)
                                nt[i] = v
                                mo.dirty = true
                                table.insert(mo.dirtyKeys, k)
                            end
                        })
                        mo[k] = proxytable
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

--Argument 1: Object array proxy
--Argument 2: The object value to insert
Global.replicatedInsert = function(tbl, val)
    Global.assertObj(val)
    tbl[#tbl.noproxy + 1] = ref(val)
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
    Global.gc(newobj)
end

Global.assertObj = function(d)
    assert(d and type(d) == "table" and d.is, "expected (Object), got " .. type(d) .. " (missing 'is')")
end

Global.assertIs = function(d, strType)
    Global.assertObj(d)
    d:assertIs(strType)
end

if _VERSION == "Luau" then --Handled by Rojo
    Global.Remote = game:GetService("ReplicatedStorage"):WaitForChild("Replicate")
    Global.Retrieve = game:GetService("ReplicatedStorage"):WaitForChild("Retrieve")
else --For bindings only
    local serverfns, clientfns = {}, {}
    Global.Remote = {
        FireClient = function(plr, ...)
            for _, fn in pairs(clientfns) do
                fn(...)
            end
        end,
        FireAllClients = function(...)
            for _, fn in pairs(clientfns) do
                fn(...)
            end
        end,
        FireServer = function(...)
            local plr = nil
            for _, fn in pairs(serverfns) do
                fn(plr, ...)
            end
        end,
        OnServerEvent = {
            Connect = function(_, fn)
                local i = #serverfns + 1
                serverfns[i] = fn
                return {
                    Disconnect = function()
                        serverfns[i] = nil
                    end
                }
            end
        },
        OnClientEvent = {
            Connect = function(_, fn)
                local i = #clientfns + 1
                clientfns[i] = fn
                return {
                    Disconnect = function()
                        clientfns[i] = nil
                    end
                }
            end
        }
    }
    local hbfns = {}
    Global.Heartbeat = {
        Connect = function(_, fn)
            local i = #hbfns + 1
            hbfns[i] = fn
            return {
                Disconnect = function()
                    hbfns[i] = nil
                end
            }
        end,
        Fire = function(...)
            for _, fn in pairs(hbfns) do
                fn(...)
            end
        end
    }
    Global.Retrieve = {
        InvokeClient = function(plr, ...)
            return Global.Retrieve.OnClientInvoke(...)
        end,
        InvokeServer = function(...)
            local plr = nil
            return Global.Retrieve.OnServerInvoke(plr, ...)
        end,
        OnServerInvoke = void,
        OnClientInvoke = void,
    }
end

Global.gc = function(obj)
    Global.assertObj(obj)
    obj:Finalize()
    rawset(obj, "gc", true)
end

Global.ConnectToHeartbeat = function(fn)
    local i = #otherHeartbeatConnections + 1
    otherHeartbeatConnections[i] = fn
    return {
        Disconnect = function()
            otherHeartbeatConnections[i] = nil
        end
    }
end

Global.ref = function(obj)
    assert(obj and type(obj) == "table" and obj.ref, "expected (Object), got " .. type(obj) .. " (missing 'ref')")
    if not pcall(function() assertObj(obj) end) then
        warn("Attempted to create reference to non-object. ref: " .. tostring(obj.ref))
    end

    return setRefMt(obj)
end

--TODO: For some reason this doesn't work, for now this code is in a server script
--[[if isServer then
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
    
    if obj.type == nil then
        warn("Attempted to use nil type when restoring MT, table follows")
        print(obj)
    end

    --Set metatable to the object's type
    setmetatable(obj, {
        __index = use(obj.type)
    })

    --Restore ref MTs for first-level references
    --TODO: So far no classes have nested references that matter.
    --      Should any be added, verify that this works for them.
    for k, v in pairs(obj) do
        if type(v) == "table" and v.ref and not getmetatable(v) then
            setRefMt(v)
        end
    end

    return obj
end

local timeShift = 0
Global.UnreplicatedTimeTravel = function(delta)
    timeShift = timeShift + delta
    --Cause 60*s Heartbeats
    for i = 1, delta*60 do
        handleHeartbeat(1/60)
    end
end

Global.resolveNumFn = function(x, ...)
    if type(x) == "function" then
        return x(...)
    else
        return x
    end
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
    fenv.utctime = function()
        return os.time() + timeShift
    end
    fenv.jsonEncode = function(t)
        error("JSON encoding not supported")
    end
    fenv.jsonDecode = function(t)
        error("JSON decoding not supported")
    end
    fenv.roblox = false
    fenv.table.find = function(t, obj)
        for i, v in pairs(t) do
            if v == obj then
                return i
            end
        end
    end
    fenv.wait = wait
    fenv.delay = delay
else --if Luau
    fenv.utctime = function()
        return tick() + timeShift
    end
    fenv.jsonEncode = function(t)
        return game:GetService("HttpService"):JSONEncode(t)
    end
    fenv.jsonDecode = function(t)
        return game:GetService("HttpService"):JSONDecode(t)
    end
    fenv.roblox = true
    fenv.wait = task.wait
    fenv.delay = task.delay
end

fenv.isServer = isServer

return fenv

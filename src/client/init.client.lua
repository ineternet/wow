local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)
local env = require(game.ReplicatedStorage.Common.Global)

local sg = game:GetService("Players").LocalPlayer.PlayerGui

--[[local fr = sg.ScreenGui.Frame

fr.Level.Text = "Level " .. char.charsheet.level
fr.Race.Text = "Race: " .. const.Races[char.charsheet.race]
fr.Class.Text = "Class: " .. const.Classes[char.charsheet.class]
fr.Spec.Text = "Specialization: " .. const.Specs[char.charsheet.spec]
fr.Stamina.Text = "Stamina: " .. char.charsheet:stamina()
fr.Intellect.Text = "Intellect: " .. char.charsheet:intellect()
fr.SpellPower.Text = "Spell Power: " .. char.charsheet:spellPower()
fr.MaxPrimary.Text = "Max Primary: " .. char.primaryResourceMaximum .. " (" .. const.Resources[char.primaryResource] .. ")"
fr.MaxSecondary.Text = "Max Secondary: " .. char.secondaryResourceMaximum .. " (" .. const.Resources[char.secondaryResource] .. ")"
fr.Mastery.Text = "Haste: " .. char.charsheet:haste()*100 .. "%"

--fr.Cast1.Text = "Cast Fireball"
fr.Cast1.Cover.Size = UDim2.new(0, 0, 1, 0)]]

local charframe = sg:WaitForChild("Hud"):WaitForChild("PlayerFrame")
local enemyframe = sg.Hud:WaitForChild("UnitFrame")

local function pround(a1, a2)
    return math.round(a1) .. " / " .. math.round(a2)
end

local function rawtostring(t)
    local m=getmetatable(t)
    local f=m.__tostring
    m.__tostring=nil
    local s=tostring(t)
    m.__tostring=f
    return s
 end

local pblast = game:GetService("ReplicatedFirst").Pyroblast:Clone()
local char, enemy
local hit = 0
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    --char:downstream()
    --enemy:downstream()

    if hit == 1 then
        
    end

    if not char then
        return end


    if char.lastSpell and char.lastSpell.castTime then
        local castRatio = (env.utctime() - char.actionBegin) / char.lastSpell.castTime
        castRatio = math.min(1, castRatio)
        --print(char.currentAction)
        local casting = char.currentAction == const.Actions.Cast
        sg.Hud.CastBar.Visible = casting
        sg.Hud.CastBar.Fill.Size = UDim2.new(castRatio, 0, 1, 0)
    end

    local gcdRatio = (1.5 - (char.gcdEnd - env.utctime())) / const.GCDTimeout[const.GCD.Standard]
    gcdRatio = math.min(1, gcdRatio)
    --print(char.currentAction)
    local gcding = char.gcdEnd > env.utctime()
    sg.Hud.GcdBar.Visible = gcding
    sg.Hud.GcdBar.Fill.Size = UDim2.new(gcdRatio, 0, 1, 0)

    local pamount = char.primaryResourceAmount
    local pmax = char.primaryResourceMaximum
    local pratio = pamount / pmax
    charframe.PrimaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    charframe.PrimaryResourceBar.Resource.Text = pround(pamount, pmax)
    charframe.PrimaryResourceBar.Resource.Shadow.Text = pround(pamount, pmax)

    local pamount = char.secondaryResourceAmount
    local pmax = char.secondaryResourceMaximum
    local pratio = pamount / pmax
    charframe.SecondaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    charframe.SecondaryResourceBar.Resource.Text = pround(pamount, pmax)
    charframe.SecondaryResourceBar.Resource.Shadow.Text = pround(pamount, pmax)

    if not enemy then
        return end

    enemyframe.UnitName.Text = enemy.display .. " (" .. enemy.charsheet.level .. ")"
    enemyframe.UnitName.Shadow.Text = enemy.display .. " (" .. enemy.charsheet.level .. ")"

    local pamount = enemy.primaryResourceAmount
    local pmax = enemy.primaryResourceMaximum
    local pratio = pamount / pmax
    enemyframe.PrimaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    enemyframe.PrimaryResourceBar.Resource.Text = pround(pamount, pmax)
    enemyframe.PrimaryResourceBar.Resource.Shadow.Text = pround(pamount, pmax)
    
    local pamount = enemy.secondaryResourceAmount
    local pmax = enemy.secondaryResourceMaximum
    local pratio = pamount / pmax
    enemyframe.SecondaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    enemyframe.SecondaryResourceBar.Resource.Text = pround(pamount, pmax)
    enemyframe.SecondaryResourceBar.Resource.Shadow.Text = pround(pamount, pmax)
    
    pblast.Parent = nil
    for i, aura in ipairs(enemy.auras) do
        if aura.aura then --Unsure what causes this, but it seems to work fine if we just ignore it.
            if aura.aura.name == "Pyroblast" then
                hit = hit + 1
                pblast.Parent = enemyframe.Auras
            end
        end
    end

    local acon = charframe.Spellbook
    for _, v in ipairs(acon:GetChildren()) do
        if v:IsA("GuiObject") then
            v:Destroy()
        end
    end
    local astencil = game.ReplicatedFirst.AuraText
    --print(char.auras)
    local printauras = math.random() > 0.99
    for i, aura in ipairs(char.auras) do
        if aura.aura then --Unsure what causes this, but it seems to work fine if we just ignore it.
            local a = astencil:Clone()
            a.Text = aura.aura.name .. " (" .. const.AuraTimer(
            aura:remainingTime()
        ) .. ")"
            a.Parent = acon
        end
    end
end)

--local myChar = const.Replicate:InvokeServer(Request.ThisUnit)

--print(myChar:spellPower())

--Global.Remote:FireAllClients(Request.FullObjectDelta, toUpdateObjects)

env.Remote.OnClientEvent:Connect(function(action, obj)
    if action == env.Request.FullObjectDelta then
        for ref, obj in pairs(env.decompress(obj)) do
            if not env.UpdateFromDelta(ref, obj) then --Try to update existing object
                --Object doesnt exist on this side.
                --TODO: Create new object from new request

                --print("Delta obj", obj)
                local cobj = env.__FindByReference(ref) --This will create the object
                if not cobj then --Nil means another task is creating the object
                    return
                end
                --Retry
                if not env.UpdateFromDelta(ref, obj) then
                    error("Could not resolve object reference " .. ref .. " even after retry.")
                else
                    local refobj = env.__FindByReference(ref)
                    if not enemy and refobj:is"Unit" then
                        enemy = refobj
                    end
                end
                
                --env.__SetReference(ref, obj)
                --env.RestoreMt(obj)
            end
        end
    end

    if action == "passchar" then
        env.__SetReference(obj.ref, obj)
        env.RestoreMt(obj)
        char = obj
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(io, gpc)
    if gpc then
        return
    end
    if io.UserInputType == Enum.UserInputType.Keyboard then
        if io.KeyCode == Enum.KeyCode.One then
            --Fireball
            env.Remote:FireServer(env.Request.CastSpell, env.Spells.Fireball.id)
        elseif io.KeyCode == Enum.KeyCode.Two then
            --Fire blast
            env.Remote:FireServer(env.Request.CastSpell, env.Spells.FireBlast.id)
        elseif io.KeyCode == Enum.KeyCode.Three then
            --Pyroblast
            env.Remote:FireServer(env.Request.CastSpell, env.Spells.Pyroblast.id)
        elseif io.KeyCode == Enum.KeyCode.Four then
            --Arcane Intellect
            env.Remote:FireServer(env.Request.CastSpell, env.Spells.ArcaneIntellect.id)
        end
    elseif io.UserInputType == Enum.UserInputType.MouseButton2 then
        if io.UserInputState == Enum.UserInputState.Begin then
            env.Remote:FireServer(env.Request.CastSpell, env.Spells.StartAttack.id)
        end
    end
end)
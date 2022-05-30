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

local pblast = game:GetService("ReplicatedFirst").Pyroblast:Clone()
local char, enemy
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    --char:downstream()
    --enemy:downstream()
    if not char then
        return end


    local castRatio = (env.utctime() - char.actionBegin) / const.Spells.Pyroblast.castTime
    castRatio = math.min(1, castRatio)

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
    for i, aura in pairs(enemy.auras) do
        if aura.aura.name == "Pyroblast" then
            pblast.Parent = enemyframe.Auras
        end
    end
end)

--local myChar = const.Replicate:InvokeServer(Request.ThisUnit)

--print(myChar:spellPower())

env.Remote.OnClientEvent:Connect(function(action, obj)
    if action == "updateref" then
        env.__SetReference(obj.ref, obj)
        env.RestoreMt(obj)
        print("From SINGLE REF:", obj)
    elseif action == "updaterefs" then
        for i, objx in pairs(obj) do
            env.__SetReference(objx.ref, objx)
            env.RestoreMt(objx)
            print("From REFS:", objx)
        end
    end

    if action == "passchar" then
        env.RestoreMt(obj)
        print("Got char:", obj)
        char = obj
    end

    --[[print(char)
    env.RestoreMt(char)
    print(char)
    print(getmetatable(char))
    print(char.charsheet:spellPower())]]
end)
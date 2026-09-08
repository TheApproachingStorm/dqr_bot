local Utils = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")


--// Queue up / create lobby
function Utils.QueueUp()
    local Event = remotes:WaitForChild("createLobby")

    return Event:InvokeServer(
        "Desert Temple",
        "Easy",
        0,
        true,
        false,
        false
    )
end


--// Start queued dungeon
function Utils.StartQueue()
    local Event = remotes:WaitForChild("startDungeon")

    Event:FireServer()
end


--// Use ability
--// ability = "q" or "e"
function Utils.UseAbility(ability)
    local abilityUsed = remotes:WaitForChild("abilityUsed")

    for _, item in pairs(player.Backpack:GetChildren()) do
        local slot = item:FindFirstChild("abilitySlot")

        if slot and slot.Value == ability then
            local localEvent = item:FindFirstChild("localEvent")

            if localEvent then
                localEvent:Fire()
                abilityUsed:FireServer(ability, item)
            end

            break
        end
    end
end


--// Change start value
function Utils.StartDungeon()
    local Event = remotes:WaitForChild("changeStartValue")

    Event:FireServer()
end


--// Replay dungeon
function Utils.ReplayDungeon()
    local Event = remotes:WaitForChild("replayDungeon")

    Event:FireServer()
end


--// Play game / load player character
function Utils.PlayGame()
    local playerGui = player:WaitForChild("PlayerGui")
    local camera = workspace.CurrentCamera

    -- GUIs enabled by the original Play button
    local guiNames = {
        "mainInterface",
        "leaderboard",
        "friendsList",
        "abilities",
        "playerStatus"
    }

    for _, name in ipairs(guiNames) do
        local gui = playerGui:FindFirstChild(name)

        if gui then
            gui.Enabled = true
        end
    end

    -- Remove BlurEffects
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") then
            effect:Destroy()
        end
    end

    -- Load player character
    local remote = remotes:WaitForChild("loadPlayerCharacter")
    remote:FireServer(nil, true)

    -- Restore camera
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
end

// noclip 
function Utils.Noclip()
    local character = player.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

return Utils

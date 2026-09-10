print("utils_module loaded.")
-- suppress prints
local print = function() end

local Utils = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")

--// Queue up / create lobby
function Utils.QueueUp()

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local remotes = ReplicatedStorage:WaitForChild("remotes")
    local Event = remotes:WaitForChild("createLobby")

    return Event:InvokeServer(
        "Volcanic Chambers",
        "Nightmare",
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

--// Start dungeon
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

-- keep track of what room we are in
function Utils.RoomTracker(Methods, onReady)

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer

    -- Wait for the game to finish loading
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- Wait for PlayerGui
    local playerGui = player:WaitForChild("PlayerGui")

    -- Give client-side objects time to initialize
    task.wait()
    task.wait()

    -- Wait for dungeon
    local dungeon = workspace:WaitForChild("dungeon")

    -- Wait for important dungeon objects
    local bossRoom = dungeon:WaitForChild("bossRoom")
    local dungeonFinished = bossRoom:WaitForChild("dungeonFinished")

    -- Give the dungeon time to populate its rooms
    task.wait()
    task.wait()
    --------------------------------------------------
    -- GUI
    --------------------------------------------------

    local oldGui = playerGui:FindFirstChild("RoomTracker")

    if oldGui then
        oldGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "RoomTracker"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 45)
    label.Position = UDim2.new(0, 20, 0, 20)
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    label.BackgroundTransparency = 0.15
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 20
    label.Font = Enum.Font.GothamBold
    label.Text = "Rooms: 0/0"
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    --------------------------------------------------
    -- Boss room signal
    --------------------------------------------------

    local signalFolder =
        ReplicatedStorage:FindFirstChild("dqr_bot_signals")

    if not signalFolder then
        signalFolder = Instance.new("Folder")
        signalFolder.Name = "dqr_bot_signals"
        signalFolder.Parent = ReplicatedStorage
    end

    local bossSignal =
        signalFolder:FindFirstChild("BossRoomReached")

    if not bossSignal then
        bossSignal = Instance.new("BindableEvent")
        bossSignal.Name = "BossRoomReached"
        bossSignal.Parent = signalFolder
    end

    --------------------------------------------------
    -- Dungeon finished
    --------------------------------------------------

    local bossRoom =
        dungeon:WaitForChild("bossRoom")

    local dungeonFinished =
        bossRoom:WaitForChild("dungeonFinished")

    local replayTriggered = false

    dungeonFinished:GetPropertyChangedSignal("Value"):Connect(function()

        if dungeonFinished.Value and not replayTriggered then

            replayTriggered = true

            print("RoomTracker: Dungeon finished.")
            print("RoomTracker: Replaying dungeon in 3 seconds...")

            task.wait(7)

            Utils.ReplayDungeon()

            print("RoomTracker: Replay fired.")

        end

    end)

    -- Handle it in case it was already true
    if dungeonFinished.Value and not replayTriggered then

        replayTriggered = true

        print("RoomTracker: Dungeon already finished.")
        print("RoomTracker: Replaying dungeon in 3 seconds...")

        task.wait(7)

        Utils.ReplayDungeon()

        print("RoomTracker: Replay fired.")

    end

    --------------------------------------------------
    -- Count total rooms
    --------------------------------------------------

    local totalRooms = 0

    for _, room in ipairs(dungeon:GetChildren()) do

        if room:FindFirstChild("enemyFolder") then
            totalRooms += 1
        end

    end

    --------------------------------------------------
    -- Room detection
    --------------------------------------------------

    local function getCurrentRoom()

        local character =
            player.Character

        if not character then
            return nil
        end

        local hrp =
            character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            return nil
        end

        local closestRoom = nil
        local closestDistance = math.huge

        for _, room in ipairs(dungeon:GetChildren()) do

            local enemyFolder =
                room:FindFirstChild("enemyFolder")

            if enemyFolder then

                local totalDistance = 0
                local enemyCount = 0

                for _, entity in ipairs(enemyFolder:GetChildren()) do

                    if entity:IsA("Model") then

                        local humanoid =
                            entity:FindFirstChildOfClass("Humanoid")

                        local enemyRoot =
                            entity:FindFirstChild("HumanoidRootPart")

                        if humanoid and enemyRoot then

                            totalDistance +=
                                (hrp.Position - enemyRoot.Position).Magnitude

                            enemyCount += 1

                        end

                    end

                end

                if enemyCount > 0 then

                    local averageDistance =
                        totalDistance / enemyCount

                    if averageDistance < closestDistance then

                        closestDistance = averageDistance
                        closestRoom = room

                    end

                end

            end

        end

        return closestRoom

    end

    --------------------------------------------------
    -- Tracker state
    --------------------------------------------------

    local currentStage = 0
    local lastRoom = nil
    local bossTriggered = false

    --------------------------------------------------
    -- Tracker ready
    --------------------------------------------------

    if onReady then
        onReady()
    end

    --------------------------------------------------
    -- Main tracker loop
    --------------------------------------------------

    while true do

        -- Stop tracking after dungeon completion
        if replayTriggered then
            break
        end

        local room = getCurrentRoom()

        if room and room ~= lastRoom then

            lastRoom = room

            --------------------------------------------------
            -- RESCAN ENEMIES
            --------------------------------------------------

            print("RoomTracker: New room detected.")
            print("RoomTracker: Current room:", room.Name)
            print("RoomTracker: Rescanning enemies...")

            Methods.LocateEnemies()

            print("RoomTracker: Enemy rescan complete.")

            --------------------------------------------------
            -- Boss room
            --------------------------------------------------

            if room.Name == "bossRoom" then

                currentStage = totalRooms

                label.Text =
                    "Rooms: "
                    .. currentStage
                    .. "/"
                    .. totalRooms

                if not bossTriggered then

                    bossTriggered = true

                    print("RoomTracker: Boss room reached.")

                    bossSignal:Fire()

                end

            --------------------------------------------------
            -- Normal room
            --------------------------------------------------

            else

                currentStage += 1

                if currentStage > totalRooms then
                    currentStage = totalRooms
                end

                label.Text =
                    "Rooms: "
                    .. currentStage
                    .. "/"
                    .. totalRooms

                print(
                    "RoomTracker: Room "
                    .. currentStage
                    .. "/"
                    .. totalRooms
                    .. " - "
                    .. room.Name
                )

            end

        end

        task.wait(1)

    end

end

-- listen to loots received in inventory
function Utils.LootListener(Methods)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Event = ReplicatedStorage.remotes.addItemToInvy
    local ReloadInvy = ReplicatedStorage.remotes.reloadInvy

    local Callback = getcallbackvalue(Event, "OnClientInvoke")

    local Loot = {}

    local function findItem(inv, itemType, uniqueId)

        local data
        local startPos

        if itemType == "weapon" then
            data = inv.weapons
            startPos = 8
        elseif itemType == "chest" then
            data = inv.chests
            startPos = 7
        elseif itemType == "helmet" then
            data = inv.helmets
            startPos = 8
        elseif itemType == "ability" then
            data = inv.abilities
            startPos = 9
        end

        if not data then
            return nil
        end

        uniqueId = tonumber(uniqueId)

        for key, item in pairs(data) do
            if tonumber(string.sub(key, startPos)) == uniqueId then
                return item
            end
        end

        return nil
    end

    Event.OnClientInvoke = function(...)

        local Args = table.pack(...)

        local itemType = Args[1]
        local uniqueId = Args[2]
        local rarity = Args[4]

        local inventory = ReloadInvy:InvokeServer()
        local item = findItem(inventory, itemType, uniqueId)

        local lootData = {
            type = itemType,
            name = item and item.name or "Unknown",
            rarity = rarity
        }

        table.insert(Loot, lootData)

        print("====================")
        print("Type:", lootData.type)
        print("Name:", lootData.name)
        print("Rarity:", lootData.rarity)
        print("====================")

        Methods.LootFilter(lootData)

        local Result = table.pack(
            Callback(table.unpack(Args, 1, Args.n))
        )

        return table.unpack(Result, 1, Result.n)
    end

    local mtHook

    mtHook = hookmetamethod(game, "__newindex", function(...)

        local self, key, value = ...

        if (
            rawequal(self, Event)
            and rawequal(key, "OnClientInvoke")
            and typeof(value) == "function"
            and not checkcaller()
        ) then
            Callback = value
        end

        return mtHook(...)
    end)

    return Loot
end

-- no map
function Utils.RemoveMap()

    local RunService = game:GetService("RunService")

    -- Disable 3D rendering
    RunService:Set3dRenderingEnabled(false)

end

return Utils

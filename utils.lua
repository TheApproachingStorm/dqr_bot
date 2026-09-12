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
        true,
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

-- whitelist player in dungeon
function Utils.AddPlayerToWhitelist(playerName)
    local Event = game:GetService("ReplicatedStorage").remotes.addPlayerToWhitelist

    Event:FireServer(playerName)
end

-- join someone's dungeon
function Utils.JoinDungeon(playerName)

    local Event = game:GetService("ReplicatedStorage").remotes.joinDungeon

    while true do
        print("Attempting to join dungeon:", playerName)

        Event:InvokeServer(playerName)

        task.wait(15)
    end

end

-- wait for alts
function Utils.WaitForWhitelistedPlayers(Whitelist)

    local Event = game:GetService("ReplicatedStorage").remotes.populateLobby
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    local seenPlayers = {}
    local remaining = 0

    -- Cache everyone we're waiting for
    for username in pairs(Whitelist) do
        if username ~= Players.LocalPlayer.Name then
            seenPlayers[username] = false
            remaining += 1
        end
    end

    if remaining == 0 then
        return
    end

    local finished = false

    local connection
    connection = Event.OnClientEvent:Connect(function()

        local player = Players.LocalPlayer

        for _, lobby in pairs(workspace.games.inLobby:GetChildren()) do
            if lobby:FindFirstChild(player.Name) then

                local roster = lobby:GetAttribute("Roster")

                if roster then
                    local data = HttpService:JSONDecode(roster)

                    for _, member in pairs(data) do

                        local username = member.n

                        if username
                            and seenPlayers[username] == false then

                            seenPlayers[username] = true
                            remaining -= 1

                            print("NEW PLAYER JOINED:", username)
                            print("Remaining:", remaining)

                            if remaining <= 0 then
                                finished = true
                                connection:Disconnect()
                                print("ALL WHITELISTED PLAYERS JOINED")
                                return
                            end
                        end
                    end
                end

                break
            end
        end
    end)

    -- Wait until every whitelisted player has appeared
    while not finished do
        task.wait(0.1)
    end
end

-- play game from lobby
function Utils.PlayLobby()

    print("[PlayLobby] 1 - starting first PlayGame")
    Utils.PlayGame()

    print("[PlayLobby] 2 - first PlayGame finished")

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    print("[PlayLobby] 3 - PlayerGui found")

    local mainInterface = playerGui:WaitForChild("mainInterface")

    print("[PlayLobby] 4 - mainInterface found")
    print("[PlayLobby] Enabled:", mainInterface.Enabled)

    repeat
        task.wait()
    until not mainInterface.Enabled

    print("[PlayLobby] 5 - menu detected")

    Utils.PlayGame()

    print("[PlayLobby] 6 - second PlayGame finished")
    print("[PlayLobby] lobby spawn complete.")
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

-- return to lobby
function Utils.ReturnToLobby()

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local ReturnToLobbyEvent =
        ReplicatedStorage
            :WaitForChild("remotes")
            :WaitForChild("ReturnToLobbyEvent")

    ReturnToLobbyEvent:FireServer()

    print("Utils: ReturnToLobby fired.")

end

-- no map
function Utils.RemoveMap()

    local RunService = game:GetService("RunService")

    -- Disable 3D rendering
    RunService:Set3dRenderingEnabled(false)

end

-- sell items
function Utils.SellByRarity(rarity)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    rarity = string.lower(rarity)

    local inventory = ReplicatedStorage.remotes.reloadInvy:InvokeServer()

    local sellList = {
        weapon = {},
        ability = {},
        chest = {},
        helmet = {}
    }

    for key, item in pairs(inventory.weapons) do
        if item.equipped == false
            and string.lower(item.rarity) == rarity then

            table.insert(sellList.weapon, string.sub(key, 8))
        end
    end

    for key, item in pairs(inventory.abilities) do
        if item.equipped.q == false
            and item.equipped.e == false
            and string.lower(item.rarity) == rarity then

            table.insert(sellList.ability, string.sub(key, 9))
        end
    end

    for key, item in pairs(inventory.chests) do
        if item.equipped == false
            and string.lower(item.rarity) == rarity then

            table.insert(sellList.chest, string.sub(key, 7))
        end
    end

    for key, item in pairs(inventory.helmets) do
        if item.equipped == false
            and string.lower(item.rarity) == rarity then

            table.insert(sellList.helmet, string.sub(key, 8))
        end
    end

    print("Selling:", rarity)
    print("Weapons:", #sellList.weapon)
    print("Abilities:", #sellList.ability)
    print("Chests:", #sellList.chest)
    print("Helmets:", #sellList.helmet)

    ReplicatedStorage.remotes.sellItemEvent:FireServer(sellList)
end

-- count inventory
function Utils.GetTotalItems()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Inventory = ReplicatedStorage.remotes.reloadInvy:InvokeServer()

    local Total = 0

    for _, category in pairs(Inventory) do
        if type(category) == "table" then
            for _, item in pairs(category) do
                if type(item) == "table" and item.name then
                    Total += 1
                end
            end
        end
    end

    return Total
end

return Utils

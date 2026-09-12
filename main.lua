repeat task.wait() until game:IsLoaded()

local Config = ...

local WHITELIST = Config.Whitelist
local CARRY_ACCOUNT = Config.CarryAccount
local AUTOFARM = Config.AutoFarm

local Players = game:GetService("Players")
local player = Players.LocalPlayer

--==================================================
-- WHITELIST CHECK
--==================================================

if not WHITELIST[player.Name] then
    warn("User is not whitelisted: " .. player.Name)
    return
end

print("Whitelisted user: " .. player.Name)

--==================================================
-- WAIT FOR CHARACTER
--==================================================

repeat
    task.wait()
until player.Character
    and player.Character:FindFirstChild("Humanoid")
    and player.Character:FindFirstChild("HumanoidRootPart")

print("character spawned.")
warn("dqr_bot v10!")

--==================================================
-- LOAD MODULES
--==================================================

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/utils.lua"))()
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/methods.lua"))()

-- optimize alt accounts
    if player.Name ~= CARRY_ACCOUNT then

        Utils.RemoveMap()

        if setfpscap then
            setfpscap(5)
        end

    end

--==================================================
-- DUNGEON
--==================================================

if game.PlaceId == 85776757589518
    and player.Name == CARRY_ACCOUNT then

    print("dungeon detected.")

    -- retry logic
    Methods.DeathRetry(Utils)

    -- begin dungeon
    Utils.StartDungeon()

    task.wait(6)

    task.spawn(function()

        Methods.RoomTracker(Utils, function()

            print("tracking room..")

        end)

    end)

    Utils.LootListener(Methods)

    task.wait(1)

    print("starting farm!")
    Methods.PathFind(Utils)

    print("dungeon finished..")

elseif game.PlaceId == 85776757589518
    and player.Name ~= CARRY_ACCOUNT then

    local Players = game:GetService("Players")

    -- Wait until the carry account actually joins
    local carryPlayer = Players:FindFirstChild(CARRY_ACCOUNT)

    if not carryPlayer then
        carryPlayer = Players.PlayerAdded:Wait()

        -- If the player who joined isn't the carry account,
        -- keep waiting for the carry account
        while carryPlayer.Name ~= CARRY_ACCOUNT do
            carryPlayer = Players.PlayerAdded:Wait()
        end
    end

    print("Carry account detected:", CARRY_ACCOUNT)
    print("Monitoring carry account...")

    -- ONLY triggers when the carry account leaves
    carryPlayer.AncestryChanged:Connect(function(_, parent)

        if parent == nil then

            print("Carry account left the dungeon.")
            print("Returning to lobby...")

            Utils.ReturnToLobby()

        end

    end) 

elseif game.PlaceId == 77649408247578 then -- lobby

    print("lobby detected.")

    -- play game
        Utils.PlayLobby()
        
        task.wait(1.5)
        
        Methods.SellAllRarities(Utils)
        
        task.wait(1)


    if player.Name == CARRY_ACCOUNT and AUTOFARM then

        print("carry account detected.")

        -- Create the dungeon/lobby
        Utils.QueueUp()

        -- Dungeon is now created
        print("lobby created.")
        task.wait(1)

        -- Add whitelist players
        for playerName in pairs(WHITELIST) do
            print("adding " .. playerName .. " to lobby whitelist.")

            Utils.AddPlayerToWhitelist(playerName)

        end


        print("waiting for other players")
        -- Start listening
        Utils.WaitForWhitelistedPlayers(WHITELIST)
        print("all whitelisted players joined.")

        -- Start the queue
        Utils.StartQueue()

    elseif AUTOFARM then

        print("normal whitelisted account detected.")

        print("joining carry account: " .. CARRY_ACCOUNT)

        Utils.JoinDungeon(CARRY_ACCOUNT)

    end


else -- webhook

    Utils.LootListener(Methods)

end

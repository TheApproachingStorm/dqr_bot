repeat task.wait() until game:IsLoaded()

-- Wait until the player is actually spawned
local Players = game:GetService("Players")
local player = Players.LocalPlayer

repeat
    task.wait()
until player.Character
    and player.Character:FindFirstChild("Humanoid")
    and player.Character:FindFirstChild("HumanoidRootPart")

print("character spawned.")

warn("dqr_bot v10!")
    -- load modules
    local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/utils.lua"))()
    local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/methods.lua"))()

if game.PlaceId == 85776757589518 then -- dungeon

    print("dungeon detected.")

    -- start dungeon
    Methods.DeathRetry(Utils)
    Utils.StartDungeon()
    --Utils.RemoveMap()
    task.wait(6)

    -- begin tracking the rooms
    task.spawn(function()
        Utils.RoomTracker(Methods, function()
            print("tracking room..")
        end)
    end)

    -- Initialize loot listener ONCE
    Utils.LootListener(Methods)

    task.wait(1)
    -- Start autofarm path
    print("starting farm!")
    Methods.PathFind(Utils)
    print("dungeon finished..")

elseif game.PlaceId == 77649408247578 then -- lobby

    print("lobby detected.")

    -- play game
    Utils.PlayGame()

    local playerGui = player:WaitForChild("PlayerGui")
    local mainInterface = playerGui:WaitForChild("mainInterface")

    -- Wait until the game puts us back into the menu
    repeat
        task.wait()
    until not mainInterface.Enabled

    print("menu detected. playing again.")
    -- play game 2nd time
    Utils.PlayGame()

    print("queing up")

    -- start dungeon 
    Utils.QueueUp()
    task.wait(1)
    Utils.StartQueue()

end

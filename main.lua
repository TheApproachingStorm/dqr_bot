print("dqr_bot v2!")

local Utils = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/utils.lua?t=" .. os.time()
))()

local Methods = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/methods.lua?t=" .. os.time()
))()

if game.PlaceId ~= 85776757589518 then
    return
end

print("Correct place detected.")

Utils.StartDungeon()

task.wait(6)

Methods.AirSuspend()

while true do
    local clusters = Methods.LocateEnemies()

    if #clusters > 0 then
        for _, cluster in ipairs(clusters) do
            local walk = Methods.WalkTo(cluster.center)

            walk.Completed:Wait()

            task.wait(6)
        end
    else
        task.wait(1)
    end
end

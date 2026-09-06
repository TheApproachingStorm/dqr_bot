print("dqr_bot loaded!")

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

Methods.AirSuspend()

while true do
    local clusters = Methods.LocateEnemies()

    if #clusters > 0 then
        for _, cluster in ipairs(clusters) do
            local tween = Methods.Tween(cluster.center)

            tween.Completed:Wait()

            task.wait(6)
        end
    else
        task.wait(1)
    end
end

print("dqr_bot !")

local utilsUrl = "https://raw.githubusercontent.com/TheApproachingStorm/dqr_bot/main/Utils.lua"

local utilsSource = game:HttpGet(utilsUrl)

print("Utils length:", #utilsSource)
print("Utils response:", utilsSource)

local utilsLoader = loadstring(utilsSource)

print("Utils loader:", utilsLoader)

local Utils = utilsLoader()

print("Utils module:", Utils)
print("StartDungeon:", Utils and Utils.StartDungeon)
print("AirSuspend:", Utils and Utils.AirSuspend)

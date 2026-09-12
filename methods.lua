print("methods_module loaded.")
-- suppress prints
local print = function() end
local warn = function() end

local INVENTORY_LIMIT = 290

local Methods = {}

-- LOCATE ENEMIES
local MIN_CLUSTER_SIZE = 1
local CLUSTER_DISTANCE = 30

-- TRIGGER SPELLS ON ENEMIES
local ENVELOPMENT_MARGIN = 10

local WebhookURL = "https://discord.com/api/webhooks/1547296212250525751/k4A4GF8CbExrzBysWmLjwlPt3_GbyEUJPPzoiPJAIdOutkQmR7q7HtdIXYK19otRuZBi"

local wantedNames = {
        "Enhanced Inner Rage",
        "Enhanced Inner Focus"
}


-- LOCATE ENEMIES
function Methods.LocateEnemies(minClusterSize, clusterDistance)

    minClusterSize = minClusterSize or MIN_CLUSTER_SIZE
    clusterDistance = clusterDistance or CLUSTER_DISTANCE

    local dungeon = workspace:FindFirstChild("dungeon")

    if not dungeon then
        warn("workspace.dungeon not found")
        return {}
    end

    --------------------------------------------------
    -- Visualization
    --------------------------------------------------

    local visualizationFolder =
        workspace:FindFirstChild("ClusterVisualization")

    if not visualizationFolder then
        visualizationFolder = Instance.new("Folder")
        visualizationFolder.Name = "ClusterVisualization"
        visualizationFolder.Parent = workspace
    end

    visualizationFolder:ClearAllChildren()

    --------------------------------------------------
    -- Find room containing CURRENT NPCs
    --------------------------------------------------

    local enemyFolder = nil
    local selectedRoom = nil
    local highestEnemyCount = 0

    for _, room in ipairs(dungeon:GetChildren()) do

        local folder = room:FindFirstChild("enemyFolder")

        if folder then

            local npcCount = 0

            for _, entity in ipairs(folder:GetChildren()) do

                if entity:IsA("Model") then

                    local humanoid =
                        entity:FindFirstChildOfClass("Humanoid")

                    if humanoid then
                        npcCount += 1
                    end
                end
            end

            print(
                "[ROOM]",
                room.Name,
                "| NPCs:",
                npcCount
            )

            if npcCount > highestEnemyCount then
                highestEnemyCount = npcCount
                enemyFolder = folder
                selectedRoom = room
            end
        end
    end

    if not enemyFolder or highestEnemyCount == 0 then
        warn("No room currently contains NPCs")
        return {}
    end

    print("================================")
    print("ACTIVE ROOM:", selectedRoom.Name)
    print("ENEMY FOLDER:", enemyFolder:GetFullName())
    print("NPC COUNT:", highestEnemyCount)
    print("================================")

    --------------------------------------------------
    -- Get NPC position
    --------------------------------------------------

    local function getPosition(entity)

        if not entity:IsA("Model") then
            return nil
        end

        local root =
            entity:FindFirstChild("HumanoidRootPart")

        if root and root:IsA("BasePart") then
            return root.Position
        end

        if entity.PrimaryPart then
            return entity.PrimaryPart.Position
        end

        local part =
            entity:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        if part then
            return part.Position
        end

        return nil
    end

    --------------------------------------------------
    -- Collect CURRENT NPCs
    --------------------------------------------------

    local enemies = {}

    for _, entity in ipairs(enemyFolder:GetChildren()) do

        if entity:IsA("Model") then

            local position = getPosition(entity)

            if position then

                table.insert(enemies, {
                    object = entity,
                    position = position
                })

            end
        end
    end

    print("Actual NPCs:", #enemies)

    if #enemies == 0 then
        warn("No NPCs with valid positions")
        return {}
    end

    --------------------------------------------------
    -- Cluster detection
    --------------------------------------------------

    local visited = {}
    local clusters = {}

    for i, enemy in ipairs(enemies) do

        if not visited[i] then

            local cluster = {}
            local queue = {i}

            visited[i] = true

            while #queue > 0 do

                local currentIndex =
                    table.remove(queue, 1)

                local current =
                    enemies[currentIndex]

                table.insert(cluster, current)

                for j, other in ipairs(enemies) do

                    if not visited[j] then

                        local dx =
                            current.position.X -
                            other.position.X

                        local dz =
                            current.position.Z -
                            other.position.Z

                        local distance =
                            math.sqrt(
                                dx * dx +
                                dz * dz
                            )

                        if distance <= clusterDistance then

                            visited[j] = true

                            table.insert(
                                queue,
                                j
                            )

                        end
                    end
                end
            end

            print(
                "Detected group:",
                #cluster,
                "NPCs"
            )

            if #cluster >= minClusterSize then
                table.insert(clusters, cluster)
            end
        end
    end

    print("Valid clusters:", #clusters)

    --------------------------------------------------
    -- Process clusters
    --------------------------------------------------

    local results = {}

    for clusterIndex, cluster in ipairs(clusters) do

        --------------------------------------------------
        -- Calculate center
        --------------------------------------------------

        local center = Vector3.zero

        for _, enemy in ipairs(cluster) do
            center += enemy.position
        end

        center /= #cluster

        --------------------------------------------------
        -- Calculate radius
        --------------------------------------------------

        local radius = 0

        for _, enemy in ipairs(cluster) do

            local dx =
                enemy.position.X -
                center.X

            local dz =
                enemy.position.Z -
                center.Z

            local distance =
                math.sqrt(
                    dx * dx +
                    dz * dz
                )

            radius = math.max(
                radius,
                distance
            )
        end

        radius += 3

        --------------------------------------------------
        -- Print
        --------------------------------------------------

        print(
            "Cluster",
            clusterIndex,
            "| Size:",
            #cluster,
            "| Center:",
            center,
            "| X:",
            center.X,
            "| Y:",
            center.Y,
            "| Z:",
            center.Z,
            "| Radius:",
            radius
        )

        --------------------------------------------------
        -- Red circle
        --------------------------------------------------

        local circle = Instance.new("Part")

        circle.Name =
            "ClusterCircle_" ..
            clusterIndex

        circle.Shape =
            Enum.PartType.Cylinder

        circle.Size = Vector3.new(
            0.25,
            radius * 2,
            radius * 2
        )

        circle.CFrame =
            CFrame.new(
                center.X,
                center.Y + 0.5,
                center.Z
            )
            *
            CFrame.Angles(
                0,
                0,
                math.rad(90)
            )

        circle.Anchored = true
        circle.CanCollide = false
        circle.CanTouch = false
        circle.CanQuery = false

        circle.Transparency = 0.45

        circle.Color =
            Color3.fromRGB(255, 0, 0)

        circle.Material =
            Enum.Material.Neon

        circle.Parent =
            visualizationFolder

        --------------------------------------------------
        -- Yellow center point
        --------------------------------------------------

        local point = Instance.new("Part")

        point.Name =
            "ClusterCenter_" ..
            clusterIndex

        point.Shape =
            Enum.PartType.Ball

        point.Size =
            Vector3.new(2, 2, 2)

        point.Position =
            Vector3.new(
                center.X,
                center.Y + 2,
                center.Z
            )

        point.Anchored = true
        point.CanCollide = false
        point.CanTouch = false
        point.CanQuery = false

        point.Color =
            Color3.fromRGB(255, 255, 0)

        point.Material =
            Enum.Material.Neon

        point.Parent =
            visualizationFolder

        --------------------------------------------------
        -- Store result for Tween
        --------------------------------------------------

        table.insert(results, {
            center = center,
            radius = radius,
            enemies = cluster
        })
    end

    return results
end

-- PLAYBACK WALK RECORDING
function Methods.WalkPlayback()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer

    local character =
        player.Character or player.CharacterAdded:Wait()

    local hrp =
        character:WaitForChild("HumanoidRootPart")

    --==================================================
    -- CONFIG
    --==================================================

    local RECORDING_FILE = "recording.lua"

    local LOOK_AHEAD = 3
    local REACH_DISTANCE = 2

    --==================================================
    -- LOAD FILE
    --==================================================

    if not isfile or not isfile(RECORDING_FILE) then
        warn("recording.lua not found.")
        return
    end

    local content = readfile(RECORDING_FILE)

    --==================================================
    -- PARSE ROUTE
    --==================================================

    local route = {}

    for time, x, y, z in content:gmatch(
        "{time%s*=%s*([%d%.%-]+),%s*position%s*=%s*Vector3%.new%(([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)%)"
    ) do

        table.insert(route, {
            time = tonumber(time),
            position = Vector3.new(
                tonumber(x),
                tonumber(y),
                tonumber(z)
            )
        })

    end

    print("================================")
    print("WALK RECORDING LOADED")
    print("Movement points:", #route)
    print("================================")

    if #route == 0 then
        warn("WalkPlayback: No movement points found.")
        return
    end

    --==================================================
    -- PLAYER CONTROLLER
    --==================================================

    local playerModule = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    )

    local controls = playerModule:GetControls()
    local keyboard = controls:GetActiveController()

    if not keyboard then
        warn("WalkPlayback: No active controller.")
        return
    end

    local oldCameraRelative = controls.cameraRelative
    controls.cameraRelative = false

    --==================================================
    -- STOP MOVEMENT
    --==================================================

    local function StopMovement()

        keyboard.moveVector = Vector3.zero

        keyboard.forwardValue = 0
        keyboard.backwardValue = 0
        keyboard.leftValue = 0
        keyboard.rightValue = 0

        keyboard:UpdateMovement(
            Enum.UserInputState.End
        )

    end

    --==================================================
    -- MOVE TOWARD
    --==================================================

    local function MoveToward(targetPosition)

        local offset = Vector3.new(
            targetPosition.X - hrp.Position.X,
            0,
            targetPosition.Z - hrp.Position.Z
        )

        if offset.Magnitude <= REACH_DISTANCE then
            return true
        end

        local direction = offset.Unit

        keyboard.moveVector = Vector3.new(
            direction.X,
            0,
            direction.Z
        )

        return false
    end

    --==================================================
    -- PLAY ROUTE
    --==================================================

    local routeIndex = 1

    while true do

        --==================================================
        -- PAUSED BY PATHFIND
        --==================================================

        if Methods._PathPaused then

            StopMovement()

            RunService.Heartbeat:Wait()

            continue
        end

        --==================================================
        -- ROUTE FINISHED
        --==================================================

        if not route[routeIndex] then

            StopMovement()

            controls.cameraRelative = oldCameraRelative

            print("================================")
            print("WALK REPLAY FINISHED")
            print("================================")

            break
        end

        --==================================================
        -- LOOK AHEAD
        --==================================================

        local targetIndex = math.min(
            routeIndex + LOOK_AHEAD,
            #route
        )

        local targetPosition =
            route[targetIndex].position

        --==================================================
        -- MOVE
        --==================================================

        local reached =
            MoveToward(targetPosition)

        if reached then
            routeIndex += 1
        end

        RunService.Heartbeat:Wait()

    end

    StopMovement()

end

-- SPELL CIRCLE
function Methods.SpellRange()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer

    local character =
        player.Character or player.CharacterAdded:Wait()

    local hrp =
        character:WaitForChild("HumanoidRootPart")

    local RADIUS = 90

    local circle = Instance.new("Part")

    circle.Name = "SpellRange"
    circle.Shape = Enum.PartType.Cylinder

    circle.Size = Vector3.new(
        0.1,
        RADIUS * 2,
        RADIUS * 2
    )

    circle.Anchored = true
    circle.CanCollide = false
    circle.CanTouch = false
    circle.CanQuery = false

    circle.Material = Enum.Material.Neon
    circle.Color = Color3.fromRGB(224, 224, 47)
    circle.Transparency = 0.9

    circle.Parent = workspace

    local connection

    connection = RunService.RenderStepped:Connect(function()

        if not hrp or not hrp.Parent then
            connection:Disconnect()
            circle:Destroy()
            return
        end

        circle.CFrame =
            hrp.CFrame
            * CFrame.new(0, -3, 0)
            * CFrame.Angles(
                0,
                0,
                math.rad(90)
            )

    end)

    return circle
end

-- PATHFIND (autofarm)
function Methods.PathFind(Utils)

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer

    local character =
        player.Character or player.CharacterAdded:Wait()

    local hrp =
        character:WaitForChild("HumanoidRootPart")

    --==================================================
    -- RESET STATE
    --==================================================

    Methods._PathPaused = false

    --==================================================
    -- LOCATE ENEMIES
    --==================================================

    print("================================")
    print("PATHFIND: LOCATING ENEMIES")
    print("================================")

    local clusters = Methods.LocateEnemies()

    if not clusters or #clusters == 0 then
        warn("PathFind: No enemy clusters found.")
    else
        print(
            "PathFind: Found",
            #clusters,
            "enemy clusters."
        )
    end

    --==================================================
    -- START SPELL RANGE
    --==================================================

    local spellRange =
        Methods.SpellRange()

    if not spellRange then
        warn("PathFind: Failed to create SpellRange.")
        return
    end

    local spellRadius =
        spellRange.Size.Y / 2

    print(
        "PathFind: Spell radius:",
        spellRadius
    )

    --==================================================
    -- FLAME STRIKE COOLDOWN
    --==================================================

    local function GetCooldown()

        local backpack =
            player:FindFirstChild("Backpack")

        if not backpack then
            return 0
        end

        local flameStrike =
            backpack:FindFirstChild("Flame Strike")

        if not flameStrike then
            return 0
        end

        local cooldown =
            flameStrike:FindFirstChild("cooldown")

        if not cooldown then
            return 0
        end

        local value = cooldown.Value

        if typeof(value) == "number" then
            return value
        end

        return 0

    end

    --==================================================
    -- STATE
    --==================================================

    local edgeTriggered = {}

    --==================================================
    -- CHECK CLUSTERS
    --==================================================

    local function CheckClusters()

        local visualization =
            workspace:FindFirstChild(
                "ClusterVisualization"
            )

        if not visualization then
            return
        end

        for _, clusterCircle in ipairs(
            visualization:GetChildren()
        ) do

            if clusterCircle:IsA("BasePart")
                and clusterCircle.Name:match(
                    "^ClusterCircle_"
                )
            then

                --==========================================
                -- DISTANCE TO CLUSTER CENTER
                --==========================================

                local dx =
                    hrp.Position.X -
                    clusterCircle.Position.X

                local dz =
                    hrp.Position.Z -
                    clusterCircle.Position.Z

                local distance =
                    math.sqrt(
                        dx * dx +
                        dz * dz
                    )

                --==========================================
                -- CLUSTER RADIUS
                --==========================================

                local clusterRadius =
                    clusterCircle.Size.Y / 2

                --==========================================
                -- EDGE CONTACT
                --
                -- SpellRange has reached the outside
                -- edge of the cluster.
                --==========================================

                local touchingEdge =
                    distance <=
                    spellRadius + clusterRadius

                --==========================================
                -- FULL ENVELOPMENT
                --
                -- Entire cluster is inside SpellRange.
                --==========================================

                local fullyEnveloped =
                        distance + clusterRadius + ENVELOPMENT_MARGIN <=
                        spellRadius

                --==========================================
                -- EDGE HIT
                --==========================================

                if touchingEdge
                    and not fullyEnveloped
                    and not edgeTriggered[clusterCircle]
                then

                    edgeTriggered[clusterCircle] = true

                    Methods._PathPaused = true

                    local cooldown =
                        GetCooldown()

                    print("================================")
                    print(
                        "PathFind: CLUSTER EDGE REACHED"
                    )
                    print(
                        "Cluster:",
                        clusterCircle.Name
                    )
                    print(
                        "Flame Strike cooldown:",
                        cooldown
                    )
                    print("PathFind: WALK PAUSED")
                    print("================================")

                    --==================================
                    -- WAIT FOR COOLDOWN
                    --==================================

                    if cooldown > 0 then

                        print(
                            "PathFind: Waiting for Flame Strike cooldown..."
                        )

                        task.spawn(function()

                            while
                                clusterCircle.Parent
                                and GetCooldown() > 0
                            do

                                RunService.Heartbeat:Wait()

                            end

                            if clusterCircle.Parent then

                                Methods._PathPaused = false

                                print(
                                    "PathFind: Flame Strike cooldown reset."
                                )

                                print(
                                    "PathFind: WALK RESUMED"
                                )

                            end

                        end)

                    else

                        -- Already off cooldown
                        Methods._PathPaused = false

                        print(
                            "PathFind: Flame Strike already ready."
                        )

                        print(
                            "PathFind: WALK RESUMED"
                        )

                    end

                end

                --==========================================
                -- FULL CLUSTER ENVELOPED
                --==========================================

                if fullyEnveloped then

                    print("================================")
                    print(
                        "PathFind: FULL CLUSTER ENVELOPED"
                    )
                    print(
                        "Cluster:",
                        clusterCircle.Name
                    )
                    print(
                        "Distance:",
                        distance
                    )
                    print(
                        "Cluster Radius:",
                        clusterRadius
                    )
                    print(
                        "Spell Radius:",
                        spellRadius
                    )

                    --==================================
                    -- USE Q
                    --==================================

                    Utils.UseAbility("q")

                    print(
                        "PathFind: Q USED"
                    )

                    --==================================
                    -- RESUME WALKING
                    --==================================

                    Methods._PathPaused = false

                    print(
                        "PathFind: WALK RESUMED AFTER Q"
                    )

                    --==================================
                    -- CLEAR OLD STATE
                    --==================================

                    edgeTriggered[clusterCircle] = nil

                    --==================================
                    -- REFRESH ENEMY LOCATIONS
                    --==================================

                    print(
                        "PathFind: Refreshing enemy locations..."
                    )

                    Methods.LocateEnemies()

                    print(
                        "PathFind: Enemy locations refreshed."
                    )

                    print("================================")

                    -- The old cluster list is now invalid
                    -- because LocateEnemies() rebuilt it.
                    return

                end

            end

        end

    end

    --==================================================
    -- START WALK PLAYBACK
    --==================================================

    print(
        "PathFind: Starting WalkPlayback..."
    )

    task.spawn(function()
        Methods.WalkPlayback()
    end)

    --==================================================
    -- MOVEMENT WATCHDOG
    --==================================================

    local STUCK_DISTANCE = 20
    local STUCK_TIMEOUT = 45

    local lastMovementPosition = hrp.Position
    local lastMovementTime = tick()

    task.spawn(function()

        while true do

            if not hrp or not hrp.Parent then
                break
            end

            local currentPosition = hrp.Position

            local dx = currentPosition.X - lastMovementPosition.X
            local dz = currentPosition.Z - lastMovementPosition.Z

            local distance = math.sqrt(
                dx * dx +
                dz * dz
            )

            -- Moved at least 10 studs
            if distance >= STUCK_DISTANCE then

                lastMovementPosition = currentPosition
                lastMovementTime = tick()

                print("Movement watchdog: moved 10+ studs, timer reset.")

            end

            -- Haven't moved 10 studs in 45 seconds
            if tick() - lastMovementTime >= STUCK_TIMEOUT then

                warn("Movement watchdog: STUCK FOR 45 SECONDS")
                warn("Retrying dungeon...")

                Utils.RetryDungeon()

                -- Reset watchdog after retry
                lastMovementPosition = hrp.Position
                lastMovementTime = tick()

            end

            task.wait(1)

        end

    end)

    --==================================================
    -- MONITOR
    --==================================================

    print("================================")
    print("PATHFIND ACTIVE")
    print("================================")

    while true do

        if not hrp or not hrp.Parent then
            break
        end

        CheckClusters()

        RunService.Heartbeat:Wait()

    end

end

-- keep track of what room we are in
function Methods.RoomTracker(Utils, onReady)

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

    local replayTriggered = false

    local function handleDungeonFinished()

        if replayTriggered then
            return
        end

        replayTriggered = true

        print("RoomTracker: Dungeon finished.")
        print("RoomTracker: Checking inventory...")

        task.wait(5)

        local totalItems = Utils.GetTotalItems()

        print(
            "RoomTracker: Inventory:",
            totalItems,
            "/",
            INVENTORY_LIMIT
        )

        if totalItems >= INVENTORY_LIMIT then

            print("RoomTracker: Inventory limit reached.")
            print("RoomTracker: Returning to lobby...")

            Utils.ReturnToLobby()

        else

            print("RoomTracker: Inventory below limit.")
            print("RoomTracker: Replaying dungeon...")

            Utils.ReplayDungeon()

        end
    end

    --------------------------------------------------
    -- Listen for dungeonFinished
    --------------------------------------------------

    dungeonFinished:GetPropertyChangedSignal("Value"):Connect(function()

        if dungeonFinished.Value then
            task.spawn(handleDungeonFinished)
        end

    end)

    --------------------------------------------------
    -- Handle if already finished
    --------------------------------------------------

    if dungeonFinished.Value then
        task.spawn(handleDungeonFinished)
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

    local roomTimeoutId = 0

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
            -- 50 SECOND ROOM TIMEOUT
            --------------------------------------------------

            roomTimeoutId += 1
            local thisTimeout = roomTimeoutId
            local timeoutRoom = room

            task.spawn(function()

                task.wait(50)

                -- A newer room was detected, so this timer is obsolete
                if thisTimeout ~= roomTimeoutId then
                    return
                end

                -- Dungeon already finished/replay already triggered
                if replayTriggered then
                    return
                end

                -- Check what room we're actually in
                local currentRoom = getCurrentRoom()

                if currentRoom == timeoutRoom then

                    print(
                        "RoomTracker: Room "
                        .. timeoutRoom.Name
                        .. " has not changed for 50 seconds."
                    )

                    print("RoomTracker: Replaying dungeon...")

                    replayTriggered = true

                    Utils.ReplayDungeon()

                end

            end)

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

-- DEATH RETRY (loop)
function Methods.DeathRetry(Utils)

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local function setupCharacter(character)

        local humanoid = character:WaitForChild("Humanoid")

        humanoid.Died:Connect(function()

            print("Death detected. Replaying dungeon...")

            Utils.ReplayDungeon()

        end)

    end

    -- Current character
    if player.Character then
        setupCharacter(player.Character)
    end

    -- Future respawns
    player.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)

end

-- FILTER LOOT (loop)
function Methods.LootFilter(loot)

    if not loot then
        return
    end

    for _, wantedName in ipairs(wantedNames) do

        if loot.name == wantedName then

            print("WANTED LOOT FOUND:", loot.name)

            Methods.SendWebhook({
                loot
            })

            return true
        end

    end

    return false
end

-- SELL INVENTORY
function Methods.SellAllRarities(Utils)

    local rarities = {
        "common",
        "uncommon",
        "rare",
        "epic"
    }

    for _, rarity in ipairs(rarities) do
        print("Selling rarity:", rarity)

        Utils.SellByRarity(rarity)

        task.wait(1)
    end

end

-- WEBHOOK
function Methods.SendWebhook(FilteredLoot)

    if not FilteredLoot or #FilteredLoot == 0 then
        return
    end

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    local player = Players.LocalPlayer

    for _, loot in ipairs(FilteredLoot) do

        local payload = {
            content = nil,
            embeds = {
                {
                    title = tostring(loot.name) .. " obtained!",
                    description = "By player " .. player.Name,
                    color = 16772723,
                    thumbnail = {
                        url = "https://static.wikia.nocookie.net/ucp-internal-test-starter-commons/images/f/fe/Wiki_Character.jpeg/revision/latest/scale-to-width-down/1000?cb=20251205171914"
                    }
                }
            },
            attachments = {}
        }

        request({
            Url = WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })

    end
end



return Methods


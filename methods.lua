print("METHODS VERSION: FIXED")
local Methods = {}


-- STAY ABOVE NPCS
function Methods.AirSuspend()
    local player = game.Players.LocalPlayer

    if getgenv().__AirSuspended then
        getgenv().__AirSuspended = false
        return
    end

    getgenv().__AirSuspended = true

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root then
        local targetY = root.Position.Y + 3

        task.spawn(function()
            while getgenv().__AirSuspended do
                if root and root.Parent then
                    local pos = root.Position

                    root.CFrame = CFrame.new(
                        pos.X,
                        targetY,
                        pos.Z
                    ) * (root.CFrame - root.Position)

                    root.AssemblyLinearVelocity = Vector3.new(
                        root.AssemblyLinearVelocity.X,
                        0,
                        root.AssemblyLinearVelocity.Z
                    )
                end

                task.wait()
            end
        end)
    end
end

-- LOCATE ENEMIES
local MIN_CLUSTER_SIZE = 2
local CLUSTER_DISTANCE = 15


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

-- TWEEN TO CLUSTERS
function Methods.Tween(targetPosition, speed)
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    speed = speed or 24

    local PAUSE_DISTANCE = 50
    local PAUSE_TIME = 1

    local completed = Instance.new("BindableEvent")

    task.spawn(function()
        local startPosition = hrp.Position
        local totalDistance = (targetPosition - startPosition).Magnitude

        if totalDistance <= 0.1 then
            completed:Fire()
            completed:Destroy()
            return
        end

        local direction = (targetPosition - startPosition).Unit
        local travelled = 0

        while travelled < totalDistance do
            local chunkDistance = math.min(
                PAUSE_DISTANCE,
                totalDistance - travelled
            )

            travelled += chunkDistance

            local nextPosition =
                startPosition + direction * travelled

            local tween = TweenService:Create(
                hrp,
                TweenInfo.new(
                    chunkDistance / speed,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.Out
                ),
                {
                    CFrame = CFrame.new(nextPosition)
                }
            )

            tween:Play()
            tween.Completed:Wait()

            if travelled < totalDistance then
                task.wait(PAUSE_TIME)
            end
        end

        completed:Fire()
        completed:Destroy()
    end)

    return {
        Completed = completed.Event
    }
end

return Methods

-- WALK TO CLUSTERS
function Methods.WalkTo(targetPosition, speed)
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local playerModule = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    )

    local controls = playerModule:GetControls()
    local keyboard = controls:GetActiveController()

    if not keyboard then
        warn("No active controller")
        return
    end

    local completed = Instance.new("BindableEvent")

    task.spawn(function()
        local target = Vector3.new(
            targetPosition.X,
            hrp.Position.Y,
            targetPosition.Z
        )

        if (target - hrp.Position).Magnitude <= 1 then
            completed:Fire()
            completed:Destroy()
            return
        end

        keyboard.forwardValue = -1
        keyboard:UpdateMovement(Enum.UserInputState.Begin)

        while true do
            task.wait()

            local currentPosition = hrp.Position

            local distance = (
                Vector3.new(target.X, currentPosition.Y, target.Z)
                - currentPosition
            ).Magnitude

            if distance <= 2 then
                break
            end

            keyboard.forwardValue = -1
            keyboard:UpdateMovement(Enum.UserInputState.Begin)
        end

        keyboard.forwardValue = 0
        keyboard:UpdateMovement(Enum.UserInputState.End)

        completed:Fire()
        completed:Destroy()
    end)

    return {
        Completed = completed.Event
    }
end

return Methods


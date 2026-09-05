
-- STAY ABOVE NPCS
function Utils.AirSuspend()
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
function Utils.LocateEnemies(minClusterSize, clusterDistance)
    minClusterSize = minClusterSize or 2
    clusterDistance = clusterDistance or 15

    local dungeon = workspace:FindFirstChild("dungeon")

    if not dungeon then
        warn("workspace.dungeon not found")
        return {}
    end

    -- Find the room containing the most NPCs
    local enemyFolder = nil
    local selectedRoom = nil
    local highestEnemyCount = 0

    for _, room in ipairs(dungeon:GetChildren()) do
        local folder = room:FindFirstChild("enemyFolder")

        if folder then
            local npcCount = 0

            for _, entity in ipairs(folder:GetChildren()) do
                if entity:IsA("Model") then
                    local humanoid = entity:FindFirstChildOfClass("Humanoid")

                    if humanoid then
                        npcCount += 1
                    end
                end
            end

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

    -- Get NPC position
    local function getPosition(entity)
        if not entity:IsA("Model") then
            return nil
        end

        local root = entity:FindFirstChild("HumanoidRootPart")

        if root and root:IsA("BasePart") then
            return root.Position
        end

        if entity.PrimaryPart then
            return entity.PrimaryPart.Position
        end

        local part = entity:FindFirstChildWhichIsA("BasePart", true)

        if part then
            return part.Position
        end

        return nil
    end

    -- Collect current NPCs
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

    if #enemies == 0 then
        warn("No NPCs with valid positions")
        return {}
    end

    -- Cluster detection
    local visited = {}
    local clusters = {}

    for i, enemy in ipairs(enemies) do
        if not visited[i] then
            local cluster = {}
            local queue = {i}

            visited[i] = true

            while #queue > 0 do
                local currentIndex = table.remove(queue, 1)
                local current = enemies[currentIndex]

                table.insert(cluster, current)

                for j, other in ipairs(enemies) do
                    if not visited[j] then
                        local dx = current.position.X - other.position.X
                        local dz = current.position.Z - other.position.Z

                        local distance = math.sqrt(
                            dx * dx + dz * dz
                        )

                        if distance <= clusterDistance then
                            visited[j] = true
                            table.insert(queue, j)
                        end
                    end
                end
            end

            if #cluster >= minClusterSize then
                table.insert(clusters, cluster)
            end
        end
    end

    return clusters
end

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

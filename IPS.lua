-- Load Rayfield from official source
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Window
local Window = Rayfield:CreateWindow({
    Name = "In Plain Sight 2",
    LoadingTitle = "Meta Hub",
    LoadingSubtitle = "by Metta",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BigHub",
        FileName = "Config"
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key",
        Subtitle = "Key System",
        Note = "No key needed",
        FileName = "Key"
    }
})

-- Tabs
local PlayerTab = Window:CreateTab("Player", "user")
local EspTab = Window:CreateTab("ESP", "eye")
local LootTab = Window:CreateTab("Loot", "coins")
local CameraTab = Window:CreateTab("Camera", "video")

--=============================
-- PLAYER TAB
--=============================
PlayerTab:CreateInput({
    Name = "WalkSpeed",
    CurrentValue = "",
    PlaceholderText = "20",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local newSpeed = tonumber(Text)
        if newSpeed then
            local player = game.Players.LocalPlayer
            local function setSpeed(char)
                local hum = char:WaitForChild("Humanoid")
                hum.WalkSpeed = newSpeed
            end
            if player.Character then setSpeed(player.Character) end
            player.CharacterAdded:Connect(setSpeed)
        end
    end
})

--=============================
-- ESP TAB (Player & Camera)
--=============================
local PlayerESPConnections = {}
local PlayerESPHighlights = {}

EspTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local function isValidPlayer(p)
                return p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid")
            end

            local function createESP(player)
                if player == game.Players.LocalPlayer then return end
                local highlight = Instance.new("Highlight")
                highlight.Name = "PlayerESP_" .. player.Name
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.FillTransparency = 0.6
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.2
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = game.CoreGui
                PlayerESPHighlights[player] = highlight

                local charAdded
                charAdded = player.CharacterAdded:Connect(function()
                    task.wait(0.3)
                    if highlight and player.Character and isValidPlayer(player) then
                        highlight.Adornee = player.Character
                        highlight.Enabled = true
                    end
                end)
                local charRemove = player.CharacterRemoving:Connect(function()
                    if highlight then highlight.Enabled = false end
                end)
                PlayerESPConnections[player] = {charAdded, charRemove}
            end

            for _, p in ipairs(game.Players:GetPlayers()) do createESP(p) end
            local playerAdded
            playerAdded = game.Players.PlayerAdded:Connect(createESP)
            local playerRemoving = game.Players.PlayerRemoving:Connect(function(p)
                if PlayerESPHighlights[p] then
                    PlayerESPHighlights[p]:Destroy()
                    PlayerESPHighlights[p] = nil
                end
                if PlayerESPConnections[p] then
                    for _, conn in ipairs(PlayerESPConnections[p]) do conn:Disconnect() end
                    PlayerESPConnections[p] = nil
                end
            end)
            local heartbeat
            heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
                for player, highlight in pairs(PlayerESPHighlights) do
                    if isValidPlayer(player) then
                        highlight.Adornee = player.Character
                        highlight.Enabled = player.Character.Humanoid.Health > 0
                    else
                        highlight.Enabled = false
                    end
                end
            end)
            table.insert(PlayerESPConnections, playerAdded)
            table.insert(PlayerESPConnections, playerRemoving)
            table.insert(PlayerESPConnections, heartbeat)
        else
            for _, highlight in pairs(PlayerESPHighlights) do
                highlight:Destroy()
            end
            for _, conn in pairs(PlayerESPConnections) do
                if type(conn) == "table" then
                    for _, c in ipairs(conn) do c:Disconnect() end
                elseif conn then
                    conn:Disconnect()
                end
            end
            PlayerESPHighlights = {}
            PlayerESPConnections = {}
        end
    end
})

-- Camera ESP
local CameraESPData = {Highlights = {}, Connections = {}}
EspTab:CreateToggle({
    Name = "Camera ESP",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local function isCamera(model)
                return model:IsA("Model") and model.Name == "ActiveCamModel"
                    and model.Parent and model.Parent.Name == "RoundDebris"
                    and model.Parent.Parent == workspace
            end

            local function createCameraESP(cam)
                if not isCamera(cam) then return end
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(0, 0, 255)
                highlight.FillTransparency = 0.6
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.2
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = game.CoreGui
                CameraESPData.Highlights[cam] = highlight
            end

            local roundDebris = workspace:FindFirstChild("RoundDebris")
            if roundDebris then
                for _, obj in ipairs(roundDebris:GetDescendants()) do
                    if isCamera(obj) then createCameraESP(obj) end
                end
            end

            local addConn = workspace.DescendantAdded:Connect(function(obj)
                if isCamera(obj) then createCameraESP(obj) end
            end)
            local remConn = workspace.DescendantRemoving:Connect(function(obj)
                if CameraESPData.Highlights[obj] then
                    CameraESPData.Highlights[obj]:Destroy()
                    CameraESPData.Highlights[obj] = nil
                end
            end)
            local heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
                for cam, highlight in pairs(CameraESPData.Highlights) do
                    if cam and cam.Parent then
                        highlight.Adornee = cam
                        highlight.Enabled = true
                    else
                        highlight.Enabled = false
                    end
                end
            end)
            CameraESPData.Connections = {addConn, remConn, heartbeat}
        else
            for _, conn in ipairs(CameraESPData.Connections) do conn:Disconnect() end
            for _, highlight in pairs(CameraESPData.Highlights) do highlight:Destroy() end
            CameraESPData.Highlights = {}
            CameraESPData.Connections = {}
        end
    end
})

-- Camera Proximity Alert
local CameraAlertData = {Connections = {}, LastNotification = 0}
EspTab:CreateToggle({
    Name = "Camera Proximity Alert",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local function isCamera(model)
                return model:IsA("Model") and model.Name == "ActiveCamModel"
                    and model.Parent and model.Parent.Name == "RoundDebris"
                    and model.Parent.Parent == workspace
            end

            local function check()
                local char = game.Players.LocalPlayer.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local roundDebris = workspace:FindFirstChild("RoundDebris")
                if not roundDebris then return end

                for _, cam in ipairs(roundDebris:GetDescendants()) do
                    if isCamera(cam) then
                        local part = cam:FindFirstChildWhichIsA("BasePart")
                        if part and (root.Position - part.Position).Magnitude <= 30 then
                            if os.time() - CameraAlertData.LastNotification > 3 then
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "⚠️ CAMERA ALERT",
                                    Text = "Camera is within 30 studs!",
                                    Duration = 3
                                })
                                CameraAlertData.LastNotification = os.time()
                            end
                            break
                        end
                    end
                end
            end

            local heartbeat = game:GetService("RunService").Heartbeat:Connect(check)
            local addConn = workspace.DescendantAdded:Connect(function(obj)
                if isCamera(obj) then check() end
            end)
            CameraAlertData.Connections = {heartbeat, addConn}
        else
            for _, conn in ipairs(CameraAlertData.Connections) do conn:Disconnect() end
            CameraAlertData.Connections = {}
        end
    end
})

-- Camera Laser
local CameraLaserData = {Lasers = {}, Connections = {}, MaxLength = 100, VisibleRange = 80}
EspTab:CreateToggle({
    Name = "Camera Laser",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local function isCamera(model)
                return model:IsA("Model") and model.Name == "ActiveCamModel"
                    and model.Parent and model.Parent.Name == "RoundDebris"
                    and model.Parent.Parent == workspace
            end

            local function createLaser(cam)
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.BrickColor = BrickColor.new("Bright red")
                part.Size = Vector3.new(0.2, 0.2, 1)
                part.Transparency = 0.4
                part.Parent = workspace
                CameraLaserData.Lasers[cam] = part
            end

            local function updateLaser(cam, part)
                local char = game.Players.LocalPlayer.Character
                if not char then part.Transparency = 1; return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then part.Transparency = 1; return end
                local camPart = cam:FindFirstChildWhichIsA("BasePart")
                if not camPart then part.Transparency = 1; return end

                local dist = (root.Position - camPart.Position).Magnitude
                if dist > CameraLaserData.VisibleRange then
                    part.Transparency = 1
                    return
                end

                local rayOrigin = camPart.Position
                local rayDir = camPart.CFrame.LookVector * CameraLaserData.MaxLength
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {cam, char}
                rayParams.IgnoreWater = true

                local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)
                local endPos = hit and hit.Position or (rayOrigin + rayDir)
                local mid = (rayOrigin + endPos) / 2
                local len = (endPos - rayOrigin).Magnitude
                part.Size = Vector3.new(0.2, 0.2, len)
                part.CFrame = CFrame.lookAt(mid, endPos) * CFrame.Angles(0, math.rad(90), 0)
                part.Transparency = 0.4
            end

            local roundDebris = workspace:FindFirstChild("RoundDebris")
            if roundDebris then
                for _, obj in ipairs(roundDebris:GetDescendants()) do
                    if isCamera(obj) then createLaser(obj) end
                end
            end

            local addConn = workspace.DescendantAdded:Connect(function(obj)
                if isCamera(obj) then createLaser(obj) end
            end)
            local remConn = workspace.DescendantRemoving:Connect(function(obj)
                if CameraLaserData.Lasers[obj] then
                    CameraLaserData.Lasers[obj]:Destroy()
                    CameraLaserData.Lasers[obj] = nil
                end
            end)
            local heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
                for cam, part in pairs(CameraLaserData.Lasers) do
                    updateLaser(cam, part)
                end
            end)
            CameraLaserData.Connections = {addConn, remConn, heartbeat}
        else
            for _, conn in ipairs(CameraLaserData.Connections) do conn:Disconnect() end
            for _, part in pairs(CameraLaserData.Lasers) do part:Destroy() end
            CameraLaserData.Lasers = {}
            CameraLaserData.Connections = {}
        end
    end
})

EspTab:CreateSlider({
    Name = "Laser Length",
    Range = {20, 300},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(Value)
        CameraLaserData.MaxLength = Value
    end
})

EspTab:CreateSlider({
    Name = "Laser Visible Range",
    Range = {20, 200},
    Increment = 1,
    CurrentValue = 80,
    Callback = function(Value)
        CameraLaserData.VisibleRange = Value
    end
})

-- Camera Tracer
local TracerData = {Drawings = {}, Connections = {}, ActiveRange = 40}
EspTab:CreateToggle({
    Name = "Camera Tracer",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local Drawing = nil
            local success = pcall(function() Drawing = Drawing end)
            if not Drawing then
                warn("Drawing library missing – Tracer disabled")
                return
            end

            local function isCamera(model)
                return model:IsA("Model") and model.Name == "ActiveCamModel"
                    and model.Parent and model.Parent.Name == "RoundDebris"
                    and model.Parent.Parent == workspace
            end

            local function getScreenEdge(screenPos)
                local screenSize = workspace.CurrentCamera.ViewportSize
                local center = screenSize / 2
                local dir = screenPos - center
                if dir.Magnitude == 0 then return center end
                local tMin = math.huge
                local edge = center
                local function intersect(p1, p2)
                    local d = p2 - p1
                    local denom = dir.X * d.Y - dir.Y * d.X
                    if denom == 0 then return end
                    local t = ((p1.X - center.X) * d.Y - (p1.Y - center.Y) * d.X) / denom
                    local u = ((p1.X - center.X) * dir.Y - (p1.Y - center.Y) * dir.X) / denom
                    if t > 0 and u >= 0 and u <= 1 then
                        if t < tMin then
                            tMin = t
                            edge = center + t * dir
                        end
                    end
                end
                intersect(Vector2.new(0,0), Vector2.new(screenSize.X,0))
                intersect(Vector2.new(screenSize.X,0), screenSize)
                intersect(screenSize, Vector2.new(0,screenSize.Y))
                intersect(Vector2.new(0,screenSize.Y), Vector2.new(0,0))
                return edge
            end

            local function update()
                local char = game.Players.LocalPlayer.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local roundDebris = workspace:FindFirstChild("RoundDebris")
                if not roundDebris then return end

                local active = {}
                for _, cam in ipairs(roundDebris:GetDescendants()) do
                    if isCamera(cam) then
                        local part = cam:FindFirstChildWhichIsA("BasePart")
                        if part and (root.Position - part.Position).Magnitude <= TracerData.ActiveRange then
                            active[cam] = part
                        end
                    end
                end

                for cam, drawings in pairs(TracerData.Drawings) do
                    if not active[cam] then
                        drawings.line:Remove()
                        drawings.circle:Remove()
                        TracerData.Drawings[cam] = nil
                    end
                end

                for cam, part in pairs(active) do
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                    if not TracerData.Drawings[cam] then
                        local line = Drawing.new("Line")
                        line.Thickness = 2
                        line.Color = Color3.fromRGB(255, 80, 80)
                        line.Visible = false
                        local circle = Drawing.new("Circle")
                        circle.Radius = 8
                        circle.Filled = true
                        circle.Color = Color3.fromRGB(255, 0, 0)
                        circle.Visible = false
                        TracerData.Drawings[cam] = {line = line, circle = circle}
                    end
                    local d = TracerData.Drawings[cam]
                    if not onScreen then
                        local edgePoint = getScreenEdge(Vector2.new(screenPos.X, screenPos.Y))
                        d.line.From = edgePoint
                        d.line.To = edgePoint + (Vector2.new(screenPos.X, screenPos.Y) - edgePoint).Unit * 25
                        d.circle.Position = edgePoint
                        d.line.Visible = true
                        d.circle.Visible = true
                    else
                        d.line.Visible = false
                        d.circle.Visible = false
                    end
                end
            end

            local conn = game:GetService("RunService").RenderStepped:Connect(update)
            TracerData.Connections = {conn}
        else
            for _, conn in ipairs(TracerData.Connections) do conn:Disconnect() end
            for _, drawings in pairs(TracerData.Drawings) do
                drawings.line:Remove()
                drawings.circle:Remove()
            end
            TracerData.Drawings = {}
            TracerData.Connections = {}
        end
    end
})

EspTab:CreateSlider({
    Name = "Tracer Distance",
    Range = {15, 100},
    Increment = 1,
    CurrentValue = 40,
    Callback = function(Value)
        TracerData.ActiveRange = Value
    end
})

--=============================
-- LOOT TAB (High‑Value ESP)
--=============================
local LootESPData = {Highlights = {}, Connections = {}, MinValue = 200}
LootTab:CreateToggle({
    Name = "High-Value Loot ESP",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local function getLootValue(model)
                local val = model:FindFirstChild("Value")
                if val and val:IsA("NumberValue") then return val.Value end
                val = model:FindFirstChild("Worth")
                if val and val:IsA("NumberValue"
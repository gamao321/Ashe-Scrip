local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ashly",
   LoadingTitle = "Ashe script",
   LoadingSubtitle = "by Ashev",
   ToggleUIKeybind = "K",
   ConfigurationSaving = {Enabled = true, FolderName = "MyScript"}
})

local Tab = Window:CreateTab("Main", 4483362458)
Tab:CreateSection("ESP")
local ESPEnabled = false
local EnemyOnly = false

local Tab2 = Window:CreateTab("Aimbot", 4483362458)
Tab2:CreateSection("Aimbot")
local AimbotEnabled = true

local ESPObjects = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local AimbotTarget = nil

-- ģ Get closest enemy character (any descendant with HumanoidRootPart or equivalent)
local function GetCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char then return char end
    -- Try to find any model that belongs to the player
    for _, obj in pairs(player:GetChildren()) do
        if obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("Humanoid")) then
            return obj
        end
    end
    return nil
end

local function GetRootPart(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then return root end
    -- fallback: any Part
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(char)
    if not char then return false end
    local hum = GetHumanoid(char)
    if hum and hum.Health > 0 then return true end
    -- Some games use different health systems, fallback: check if char exists
    local root = GetRootPart(char)
    return root ~= nil
end

local function IsEnemy(player)
    if not player or not LocalPlayer then return false end
    local team1 = LocalPlayer.Team
    local team2 = player.Team
    if team1 and team2 then return team1 ~= team2 end
    return true
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Box then obj.Box:Remove() end
        if obj.Name then obj.Name:Remove() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
    end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Visible = false

    local nameText = Drawing.new("Text")
    nameText.Size = 16
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Outline = true
    nameText.Center = true
    nameText.Visible = false

    ESPObjects[player] = {Box = box, Name = nameText}
end

-- Refresh ESP for all players (call when a new character loads)
local function RefreshAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
end

-- äş Update loop — ESP + Aimbot target selection
RunService.RenderStepped:Connect(function()
    -- == ESP ==
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then
                if ESPObjects[player] then
                    ESPObjects[player].Box.Visible = false
                    ESPObjects[player].Name.Visible = false
                end
                continue
            end
            if EnemyOnly and not IsEnemy(player) then
                if ESPObjects[player] then
                    ESPObjects[player].Box.Visible = false
                    ESPObjects[player].Name.Visible = false
                end
                continue
            end
            if not ESPObjects[player] then CreateESP(player) end

            local char = GetCharacter(player)
            local root = GetRootPart(char)
            local alive = IsAlive(char)
            local obj = ESPObjects[player]

            if root and alive then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local size = Vector2.new(4000 / pos.Z, 6000 / pos.Z)
                    obj.Box.Size = size
                    obj.Box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                    obj.Box.Visible = true
                    obj.Name.Text = player.Name
                    obj.Name.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 20)
                    obj.Name.Visible = true
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                end
            else
                obj.Box.Visible = false
                obj.Name.Visible = false
                -- If character changed, re-create on next frame
                if char then
                    task.wait()
                    CreateESP(player)
                end
            end
        end
    else
        for _, obj in pairs(ESPObjects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
        end
    end

    -- == Aimbot Target Selection (always find closest) ==
    if AimbotEnabled then
        local closestDist = math.huge
        local closestPlayer = nil
        local mousePos = UserInputService:GetMouseLocation()

        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if EnemyOnly and not IsEnemy(player) then continue end
            local char = GetCharacter(player)
            local root = GetRootPart(char)
            if root and IsAlive(char) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
        AimbotTarget = closestPlayer
    end
end)

-- Player/Character tracking
local function OnCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        OnCharacterAdded(player)
    else
        OnCharacterAdded(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
        OnCharacterAdded(player)
    else
        OnCharacterAdded(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
        ESPObjects[player] = nil
    end
end)

-- == Aimbot keybind: press Shift to lock on ==
local AimbotHolding = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = false
    end
end)

-- Aimbot (lock camera/aim only while Shift held)
RunService.RenderStepped:Connect(function()
    if AimbotEnabled and AimbotHolding and AimbotTarget then
        local char = GetCharacter(AimbotTarget)
        local root = GetRootPart(char)
        if root then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        end
    end
end)

-- == UI: Toggles ==
Tab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            for _, obj in pairs(ESPObjects) do
                obj.Box.Visible = false
                obj.Name.Visible = false
            end
        end
    end
})

Tab:CreateToggle({
    Name = "Enemy Only",
    CurrentValue = false,
    Flag = "Enemy_Only",
    Callback = function(Value)
        EnemyOnly = Value
    end
})

Tab2:CreateToggle({
    Name = "Aimbot",
    CurrentValue = true,
    Flag = "Aimbot_Toggle",
    Callback = function(Value)
        AimbotEnabled = Value
    end
})

Tab2:CreateSection("Hold Shift to aimbot")
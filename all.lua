-- DRAG FOV
local dragFovSize = 150
local circleColordragFov = Color3.new(1, 1, 1)

-- Получаем сервисы
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Создаем круг FOV
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DragFovGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local dragFovCircle = Instance.new("Frame")
dragFovCircle.Size = UDim2.new(0, dragFovSize * 2, 0, dragFovSize * 2)
dragFovCircle.Position = UDim2.new(0.59, -dragFovSize, 0.67, -dragFovSize)
dragFovCircle.AnchorPoint = Vector2.new(0.59, 0.67)
dragFovCircle.BackgroundTransparency = 1
dragFovCircle.Visible = false 
dragFovCircle.Parent = screenGui

local dragFovCirclecorner = Instance.new("UICorner")
dragFovCirclecorner.CornerRadius = UDim.new(1, 0)
dragFovCirclecorner.Parent = dragFovCircle

local dragFovCirclestroke = Instance.new("UIStroke")
dragFovCirclestroke.Thickness = 2
dragFovCirclestroke.Color = circleColordragFov
dragFovCirclestroke.Parent = dragFovCircle

--------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Эту переменную теперь будет управлять UI-скрипт
local aimbotEnabled = false
local currentTarget = nil
local closestDistance = math.huge

-- Переменная для хранения клавиши-бинда
local aimbotBind = nil
local keyIsPressed = false

-- Функция для нахождения ближайшего игрока (оставляем без изменений)
local function findClosestPlayer()
    if not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localRoot = localPlayer.Character.HumanoidRootPart
    local closestPlayer = nil
    closestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local distance = (humanoidRootPart.Position - localRoot.Position).Magnitude
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Функция для получения позиции головы (оставляем без изменений)
local function getTargetHeadPosition(targetPlayer)
    if targetPlayer and targetPlayer.Character then
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            return head.Position
        end
    end
    return nil
end

-- Функция для плавного прицеливания (оставляем без изменений)
local function smoothAim(targetPosition)
    if not targetPosition then return end
    
    local currentCameraCFrame = camera.CFrame
    local direction = (targetPosition - currentCameraCFrame.Position).Unit
    local targetCFrame = CFrame.new(currentCameraCFrame.Position, currentCameraCFrame.Position + direction)
    
    local smoothingFactor = 0.15 
    local maxSmoothingDistance = 5
    local smoothing = smoothingFactor * math.min(1, closestDistance / maxSmoothingDistance)
    
    camera.CFrame = currentCameraCFrame:Lerp(targetCFrame, 1 - smoothing)
end

-- Главный цикл aimbot'а (оставляем без изменений)
local function aimbotUpdate()
    if not aimbotEnabled then return end
    
    if not currentTarget or not currentTarget.Character or 
       not currentTarget.Character:FindFirstChild("Humanoid") or 
       currentTarget.Character.Humanoid.Health <= 0 then
        currentTarget = findClosestPlayer()
    else
        local newClosest = findClosestPlayer()
        if newClosest and newClosest ~= currentTarget then
            currentTarget = newClosest
        end
    end
    
    if currentTarget then
        local headPosition = getTargetHeadPosition(currentTarget)
        if headPosition then
            smoothAim(headPosition)
        end
    end
end

-- Управление aimbot'ом через RenderStep
RunService:BindToRenderStep("AimbotUpdate", Enum.RenderPriority.Input.Value, aimbotUpdate)

--------------------------------------------------------------------------------------------------------------------------------


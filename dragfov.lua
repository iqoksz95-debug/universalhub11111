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

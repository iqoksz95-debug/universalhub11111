-- Создаем ScreenGui
local qzcscreenGui = Instance.new("ScreenGui")
qzcscreenGui.Name = "qzcGui"
qzcscreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Создаем главное окно
local qzcradeWindow = Instance.new("Frame")
qzcradeWindow.Name = "qzcradeWindow"
qzcradeWindow.Size = UDim2.new(0, 200, 0, 200)
qzcradeWindow.Position = UDim2.new(0.851, 0, 0.035, 0)
qzcradeWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
qzcradeWindow.BackgroundTransparency = 0.45
qzcradeWindow.Active = true
qzcradeWindow.Draggable = true
qzcradeWindow.Parent = qzcscreenGui

-- Добавляем обводку к главному окну
local qzcradeguiStroke = Instance.new("UIStroke")
qzcradeguiStroke.Thickness = 1
qzcradeguiStroke.Color = Color3.fromRGB(255, 255, 255)
qzcradeguiStroke.Parent = qzcradeWindow

-- Закругление окна
local qzcradeuiCorner = Instance.new("UICorner")
qzcradeuiCorner.CornerRadius = UDim.new(0, 6)
qzcradeuiCorner.Parent = qzcradeWindow

local parent = qzcradeWindow
local qzcLines = {}

qzcLines.System1 = {}
for i = 1, 9 do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 1, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = parent
    frame.Name = "qzcLineSystem1_" .. i
    frame.Visible = true
    table.insert(qzcLines.System1, frame)
end

qzcLines.System2 = {}
for i = 1, 9 do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 1)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = parent
    frame.Name = "qzcLineSystem2_" .. i
    frame.Visible = true
    table.insert(qzcLines.System2, frame)
end

function qzcAddLine(system, lineIndex, position)
    if system == 1 and lineIndex >= 1 and lineIndex <= 9 then
        local frame = qzcLines.System1[lineIndex]
        frame.Position = position
        frame.Visible = true
        return frame
    elseif system == 2 and lineIndex >= 1 and lineIndex <= 9 then
        local frame = qzcLines.System2[lineIndex]
        frame.Position = position
        frame.Visible = true
        return frame
    else
        warn("qzcAddLine: Invalid system or line index specified.")
        return nil
    end
end

qzcAddLine(1, 1, UDim2.new(0.1, 0, 0, 0))
qzcAddLine(1, 2, UDim2.new(0.2, 0, 0, 0))
qzcAddLine(1, 3, UDim2.new(0.3, 0, 0, 0))
qzcAddLine(1, 4, UDim2.new(0.4, 0, 0, 0))
qzcAddLine(1, 5, UDim2.new(0.5, 0, 0, 0))
qzcAddLine(1, 6, UDim2.new(0.6, 0, 0, 0))
qzcAddLine(1, 7, UDim2.new(0.7, 0, 0, 0))
qzcAddLine(1, 8, UDim2.new(0.8, 0, 0, 0))
qzcAddLine(1, 9, UDim2.new(0.9, 0, 0, 0))

qzcAddLine(2, 1, UDim2.new(0, 0, 0.1, 0))
qzcAddLine(2, 2, UDim2.new(0, 0, 0.2, 0))
qzcAddLine(2, 3, UDim2.new(0, 0, 0.3, 0))
qzcAddLine(2, 4, UDim2.new(0, 0, 0.4, 0))
qzcAddLine(2, 5, UDim2.new(0, 0, 0.5, 0))
qzcAddLine(2, 6, UDim2.new(0, 0, 0.6, 0))
qzcAddLine(2, 7, UDim2.new(0, 0, 0.7, 0))
qzcAddLine(2, 8, UDim2.new(0, 0, 0.8, 0))
qzcAddLine(2, 9, UDim2.new(0, 0, 0.9, 0))

-- 📌 Новая функциональность радара
local qzcUserInputService = game:GetService("UserInputService")
local qzcLocalPlayer = game.Players.LocalPlayer
local qzcenabledRadareSp = false
local qzcMaxRadarDistance = 2000
local qzcCurrentRadarDistance = qzcMaxRadarDistance  -- Новая переменная для текущего масштаба
local qzcPlayersOnRadar = {}
local qzcUpdateLoop

-- 📍 Создаем UI-элемент для локального игрока в центре радара
local qzcLocalPlayerDot = Instance.new("Frame")
qzcLocalPlayerDot.Name = "qzcLocalPlayerDot"
qzcLocalPlayerDot.Size = UDim2.new(0, 8, 0, 8)
qzcLocalPlayerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
qzcLocalPlayerDot.BorderSizePixel = 0
qzcLocalPlayerDot.AnchorPoint = Vector2.new(0.5, 0.5)
qzcLocalPlayerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
qzcLocalPlayerDot.Parent = qzcradeWindow
Instance.new("UICorner", qzcLocalPlayerDot).CornerRadius = UDim.new(1, 0)

-- ⚙️ Функция для обновления позиции игрока на радаре
local function qzcUpdatePlayerDot(dot, player)
    local localCharacter = qzcLocalPlayer.Character
    local otherCharacter = player.Character

    if not localCharacter or not otherCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") or not otherCharacter:FindFirstChild("HumanoidRootPart") then
        dot.Visible = false
        return
    end

    local localPos = localCharacter.HumanoidRootPart.Position
    local otherPos = otherCharacter.HumanoidRootPart.Position

    local direction = otherPos - localPos
    local distance = direction.Magnitude

    -- Используем текущий радиус для проверки дистанции
    if distance > qzcCurrentRadarDistance then
        dot.Visible = false
        return
    end

    -- Нормализация позиции для отображения на UI
    local relativePos = direction / qzcCurrentRadarDistance
    local xOffset = relativePos.X
    local zOffset = relativePos.Z

    -- Позиционирование на радаре
    local screenX = 0.5 + xOffset / 2
    local screenY = 0.5 + zOffset / 2

    dot.Position = UDim2.new(screenX, 0, screenY, 0)
    dot.Visible = true
end

-- 🏃 Функция для создания UI-элемента для другого игрока
local function qzcCreatePlayerDot(player)
    local dot = Instance.new("Frame")
    dot.Name = "qzcPlayerDot_" .. player.Name
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    dot.BorderSizePixel = 0
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Parent = qzcradeWindow
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    return dot
end

-- ♻️ Главный цикл обновления радара
local function qzcUpdateRadar()
    if not qzcenabledRadareSp then return end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= qzcLocalPlayer and player.Character then
            if not qzcPlayersOnRadar[player] then
                -- Создаем точку для нового игрока
                local dot = qzcCreatePlayerDot(player)
                qzcPlayersOnRadar[player] = dot
            end
            qzcUpdatePlayerDot(qzcPlayersOnRadar[player], player)
        else
            -- Убираем точку, если игрок не существует или это локальный игрок
            if qzcPlayersOnRadar[player] then
                qzcPlayersOnRadar[player]:Destroy()
                qzcPlayersOnRadar[player] = nil
            end
        end
    end
end

-- ⏯️ Функция для включения/выключения радара
function qzcToggleRadar(state)
    qzcenabledRadareSp = state
    qzcradeWindow.Visible = state
    if qzcenabledRadareSp then
        -- Начинаем цикл обновления
        if not qzcUpdateLoop then
            qzcUpdateLoop = game:GetService("RunService").Heartbeat:Connect(qzcUpdateRadar)
        end
    else
        -- Останавливаем цикл и убираем все точки, кроме локального игрока
        if qzcUpdateLoop then
            qzcUpdateLoop:Disconnect()
            qzcUpdateLoop = nil
        end
        for _, dot in pairs(qzcPlayersOnRadar) do
            if dot then
                dot:Destroy()
            end
        end
        qzcPlayersOnRadar = {}
    end
end

-- Добавляем обработчик для колесика мыши
qzcUserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
    if not qzcenabledRadareSp or gameProcessedEvent then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local delta = input.Position.Z
        qzcCurrentRadarDistance = qzcCurrentRadarDistance + delta * 200
        -- Устанавливаем лимиты
        qzcCurrentRadarDistance = math.clamp(qzcCurrentRadarDistance, 200, qzcMaxRadarDistance)
    end
end)

-- Устанавливаем начальное состояние (выключен)
qzcToggleRadar(false)

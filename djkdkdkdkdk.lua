local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

--------------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TestService = game:GetService("TestService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Light = game:GetService("Lighting")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--------------------------------------------------------------------------------------------------------------------------------

local le = loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/universalhub11111/refs/heads/main/hitbox.lua'))()

le.LISTEN_FOR_INPUT = false

local limbs = {}

local limbExtenderData = getgenv().limbExtenderData

--------------------------------------------------------------------------------------------------------------------------------

local xklUserInputService = game:GetService("UserInputService")
local xklMouse = localPlayer:GetMouse()

-- DRAG FOV (existing code with xkl prefix)
local xklDragFovSize = 150
local xklCircleColordragFov = Color3.new(1, 1, 1)

-- Создаем круг FOV
local xklScreenGui = Instance.new("ScreenGui")
xklScreenGui.Name = "xklDragFovGui"
xklScreenGui.ResetOnSpawn = false
xklScreenGui.Parent = CoreGui

local xklDragFovCircle = Instance.new("Frame")
xklDragFovCircle.Size = UDim2.new(0, xklDragFovSize * 2, 0, xklDragFovSize * 2)
xklDragFovCircle.Position = UDim2.new(0.59, -xklDragFovSize, 0.67, -xklDragFovSize)
xklDragFovCircle.AnchorPoint = Vector2.new(0.59, 0.67)
xklDragFovCircle.BackgroundTransparency = 1
xklDragFovCircle.Visible = false 
xklDragFovCircle.Parent = xklScreenGui

local xklDragFovCirclecorner = Instance.new("UICorner")
xklDragFovCirclecorner.CornerRadius = UDim.new(1, 0)
xklDragFovCirclecorner.Parent = xklDragFovCircle

local xklDragFovCirclestroke = Instance.new("UIStroke")
xklDragFovCirclestroke.Thickness = 2
xklDragFovCirclestroke.Color = xklCircleColordragFov
xklDragFovCirclestroke.Parent = xklDragFovCircle

-- DRAGFOV AIM VARIABLES
local xklDragFovAimEnabled = false
local xklDragFovEnabled = false
local xklCurrentTarget = nil
local xklTargetConnection = nil
local xklKeybind = nil
local xklKeybindConnection = nil

-- Helper function to get player's head position
local function xklGetPlayerHead(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        return player.Character.Head
    end
    return nil
end

-- Helper function to check if a player is alive
local function xklIsPlayerAlive(player)
    if not player or not player.Character then
        return false
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Helper function to get screen position from world position
local function xklWorldToScreen(worldPos)
    local screenPos, onScreen = camera:WorldToScreenPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Helper function to check if a point is within the dragfov circle
local function xklIsInDragFov(screenPos)
    if not xklDragFovCircle.Visible then
        return false
    end
    
    local circleCenter = Vector2.new(
        xklDragFovCircle.AbsolutePosition.X + xklDragFovCircle.AbsoluteSize.X / 2,
        xklDragFovCircle.AbsolutePosition.Y + xklDragFovCircle.AbsoluteSize.Y / 2
    )
    
    local distance = (screenPos - circleCenter).Magnitude
    return distance <= xklDragFovSize
end

-- Function to get all valid targets within dragfov
local function xklGetValidTargets()
    local validTargets = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and xklIsPlayerAlive(player) then
            local head = xklGetPlayerHead(player)
            if head then
                local screenPos, onScreen = xklWorldToScreen(head.Position)
                if onScreen and xklIsInDragFov(screenPos) then
                    local distance = (head.Position - camera.CFrame.Position).Magnitude
                    table.insert(validTargets, {
                        player = player,
                        head = head,
                        distance = distance
                    })
                end
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(validTargets, function(a, b)
        return a.distance < b.distance
    end)
    
    return validTargets
end

-- Function to smoothly aim at target
local function xklAimAtTarget(targetHead)
    if not targetHead or not localPlayer.Character then
        return
    end
    
    local targetPosition = targetHead.Position
    local currentCFrame = camera.CFrame
    local direction = (targetPosition - currentCFrame.Position).Unit
    local newCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)
    
    -- Smooth aiming transition
    camera.CFrame = currentCFrame:Lerp(newCFrame, 0.3)
end

-- Main targeting function
local function xklUpdateTarget()
    if not xklDragFovAimEnabled or not xklDragFovEnabled then
        xklCurrentTarget = nil
        return
    end
    
    local validTargets = xklGetValidTargets()
    
    if #validTargets == 0 then
        xklCurrentTarget = nil
        return
    end
    
    -- Check if current target is still valid
    local currentTargetValid = false
    if xklCurrentTarget then
        for _, targetData in pairs(validTargets) do
            if targetData.player == xklCurrentTarget then
                currentTargetValid = true
                break
            end
        end
    end
    
    -- If current target is not valid or we don't have one, get the closest
    if not currentTargetValid then
        xklCurrentTarget = validTargets[1].player
    end
    
    -- Aim at the current target
    if xklCurrentTarget then
        local head = xklGetPlayerHead(xklCurrentTarget)
        if head then
            xklAimAtTarget(head)
        end
    end
end

-- Function to toggle dragfov aim
local function xklToggleDragFovAim(state)
    xklDragFovAimEnabled = state
    
    if xklTargetConnection then
        xklTargetConnection:Disconnect()
        xklTargetConnection = nil
    end
    
    if xklDragFovAimEnabled and xklDragFovEnabled then
        xklTargetConnection = RunService.Heartbeat:Connect(xklUpdateTarget)
    end
    
    if not xklDragFovAimEnabled then
        xklCurrentTarget = nil
    end
end

-- Function to set custom keybind
local function xklSetKeybind(input)
    local key = string.upper(input)
    
    -- Validate input (single English letter)
    if #key ~= 1 or not string.match(key, "[A-Z]") then
        if WindUI then
            WindUI:Notify({
                Title = "Keybind Error",
                Content = "Please enter a single English letter",
                Icon = "x",
                Duration = 3
            })
        end
        return
    end
    
    -- Remove old keybind connection
    if xklKeybindConnection then
        xklKeybindConnection:Disconnect()
    end
    
    xklKeybind = Enum.KeyCode[key]
    
    -- Create new keybind connection
    xklKeybindConnection = xklUserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == xklKeybind then
            local newState = not xklDragFovAimEnabled
            xklToggleDragFovAim(newState)
            
            -- Also update the toggle UI if it exists
            if featureToggle and featureToggle.SetValue then
                featureToggle:SetValue(newState)
            end
        end
    end)
    
    if WindUI then
        WindUI:Notify({
            Title = "Keybind Set",
            Content = "DragFov Aim keybind set to: " .. key,
            Icon = "check",
            Duration = 3
        })
    end
end

-- UI Integration (assuming TabHandles.Aim exists)
if TabHandles and TabHandles.Aim then
    local featureToggle = TabHandles.Aim:Toggle({
        Title = "DragFov Aim",
        Value = false,
        Callback = function(state) 
            xklToggleDragFovAim(state)
        end
    })

    TabHandles.Aim:Input({
        Title = "DragFov Aim Bind",
        Placeholder = "Enter your bind (A-Z)",
        Callback = function(input) 
            xklSetKeybind(input)
        end
    })
end

-- Monitor dragfov state changes
local function xklMonitorDragFov()
    local lastVisible = xklDragFovCircle.Visible
    
    RunService.Heartbeat:Connect(function()
        local currentVisible = xklDragFovCircle.Visible
        
        if currentVisible ~= lastVisible then
            xklDragFovEnabled = currentVisible
            lastVisible = currentVisible
            
            -- If dragfov is disabled, also disable dragfov aim
            if not xklDragFovEnabled and xklDragFovAimEnabled then
                xklToggleDragFovAim(false)
            end
        end
    end)
end

xklMonitorDragFov()

-- Handle player removal
Players.PlayerRemoving:Connect(function(player)
    if xklCurrentTarget == player then
        xklCurrentTarget = nil
    end
end)

-- Handle character removal/death
Players.PlayerAdded:Connect(function(player)
    player.CharacterRemoving:Connect(function(character)
        if xklCurrentTarget == player then
            xklCurrentTarget = nil
        end
    end)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        player.CharacterRemoving:Connect(function(character)
            if xklCurrentTarget == player then
                xklCurrentTarget = nil
            end
        end)
    end
end

--------------------------------------------------------------------------------------------------------------------------------

local slk_aimbotEnabled = false
local slk_currentTarget = nil
local slk_closestDistance = math.huge

-- Переменная для хранения клавиши-бинда
local slk_aimbotBind = nil
local slk_keyIsPressed = false

-- Функция для нахождения ближайшего игрока (оставляем без изменений)
local function findClosestPlayer()
    if not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local localRoot = localPlayer.Character.HumanoidRootPart
    local closestPlayer = nil
    slk_closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")

            if humanoidRootPart and head then
                local distance = (humanoidRootPart.Position - localRoot.Position).Magnitude

                if distance < slk_closestDistance then
                    slk_closestDistance = distance
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
    local smoothing = smoothingFactor * math.min(1, slk_closestDistance / maxSmoothingDistance)

    camera.CFrame = currentCameraCFrame:Lerp(targetCFrame, 1 - smoothing)
end

-- Главный цикл aimbot'а (оставляем без изменений)
local function aimbotUpdate()
    if not slk_aimbotEnabled then return end

    if not slk_currentTarget or not slk_currentTarget.Character or
        not slk_currentTarget.Character:FindFirstChild("Humanoid") or
        slk_currentTarget.Character.Humanoid.Health <= 0 then
        slk_currentTarget = findClosestPlayer()
    else
        local newClosest = findClosestPlayer()
        if newClosest and newClosest ~= slk_currentTarget then
            slk_currentTarget = newClosest
        end
    end

    if slk_currentTarget then
        local headPosition = getTargetHeadPosition(slk_currentTarget)
        if headPosition then
            smoothAim(headPosition)
        end
    end
end

-- Управление aimbot'ом через RenderStep
RunService:BindToRenderStep("AimbotUpdate", Enum.RenderPriority.Input.Value, aimbotUpdate)

--------------------------------------------------------------------------------------------------------------------------------

-- Переменные для хранения исходных настроек освещения
local originalAmbient = Light.Ambient
local originalColorShiftBottom = Light.ColorShift_Bottom
local originalColorShiftTop = Light.ColorShift_Top
local originalFogEnd = Light.FogEnd

-- Флаг для отслеживания состояния fullbright
local isFullbrightActive = false

function dofullbright()
    Light.Ambient = Color3.new(1, 1, 1)
    Light.ColorShift_Bottom = Color3.new(1, 1, 1)
    Light.ColorShift_Top = Color3.new(1, 1, 1)
    Light.FogEnd = 100000
    isFullbrightActive = true
end

function disablefullbright()
    Light.Ambient = originalAmbient
    Light.ColorShift_Bottom = originalColorShiftBottom
    Light.ColorShift_Top = originalColorShiftTop
    Light.FogEnd = originalFogEnd
    isFullbrightActive = false
end

--------------------------------------------------------------------------------------------------------------------------------

local espEnabled = false
local espColor = Color3.fromRGB(255, 255, 255)

local function applyESP(character, player)
    if not character:FindFirstChild("ESP") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP"
        highlight.FillTransparency = 1
        highlight.OutlineColor = espColor
        highlight.Parent = character
    end
    
    if not character:FindFirstChild("ESPName") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPName"
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = character

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 20
        nameLabel.Parent = billboard
    end
end

local function removeESP(character)
    if character then
        local esp = character:FindFirstChild("ESP")
        if esp then
            esp:Destroy()
        end
        local espName = character:FindFirstChild("ESPName")
        if espName then
            espName:Destroy()
        end
    end
end

local function onCharacterAdded(character, player)
    if espEnabled then
        applyESP(character, player)
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            removeESP(character)
        end)
    end
end

local function createESP(player)
    if player ~= game.Players.LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(character, player)
        end)
        if player.Character then
            onCharacterAdded(player.Character, player)
        end
    end
end

local function toggleESP(state)
    espEnabled = state
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if espEnabled then
            createESP(player)
        else
            removeESP(player.Character)
        end
    end
end

game.Players.PlayerAdded:Connect(createESP)
game.Players.PlayerRemoving:Connect(function(player)
    removeESP(player.Character)
end)

for _, player in ipairs(game.Players:GetPlayers()) do
    createESP(player)
end

--------------------------------------------------------------------------------------------------------------------------------

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCamera = Workspace.CurrentCamera
    if newCamera then
        Camera = newCamera
    end
end)

local FFlagUserExitFreecamBreaksWithShiftlock
do
    local success, result = pcall(function()
        return UserSettings():IsUserFeatureEnabled("UserExitFreecamBreaksWithShiftlock")
    end)
    FFlagUserExitFreecamBreaksWithShiftlock = success and result
end

local FFlagUserShowGuiHideToggles
do
    local success, result = pcall(function()
        return UserSettings():IsUserFeatureEnabled("UserShowGuiHideToggles")
    end)
    FFlagUserShowGuiHideToggles = success and result
end

-----------

local FREECAM_ENABLED_ATTRIBUTE_NAME = "FreecamEnabled"
local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300

local PITCH_LIMIT = rad(90)

local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = 1.0
local FOV_STIFFNESS = 4.0

-----------

local Spring = {} do
    Spring.__index = Spring

    function Spring.new(freq, pos)
        local self = setmetatable({}, Spring)
        self.f = freq
        self.p = pos
        self.v = pos*0
        return self
    end

    function Spring:Update(dt, goal)
        local f = self.f*2*pi
        local p0 = self.p
        local v0 = self.v

        local offset = goal - p0
        local decay = exp(-f*dt)

        local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
        local v1 = (f*dt*(offset*f - v0) + v0)*decay

        self.p = p1
        self.v = v1

        return p1
    end

    function Spring:Reset(pos)
        self.p = pos
        self.v = pos*0
    end
end

-----------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

-----------

local Input = {} do
    local thumbstickCurve do
        local K_CURVATURE = 2.0
        local K_DEADZONE = 0.15

        local function fCurve(x)
            return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
        end

        local function fDeadzone(x)
            return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
        end

        function thumbstickCurve(x)
            return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
        end
    end

    local gamepad = {
        ButtonX = 0,
        ButtonY = 0,
        DPadDown = 0,
        DPadUp = 0,
        ButtonL2 = 0,
        ButtonR2 = 0,
        Thumbstick1 = Vector2.new(),
        Thumbstick2 = Vector2.new(),
    }

    local keyboard = {
        W = 0,
        A = 0,
        S = 0,
        D = 0,
        E = 0,
        Q = 0,
        U = 0,
        H = 0,
        J = 0,
        K = 0,
        I = 0,
        Y = 0,
        Up = 0,
        Down = 0,
        LeftShift = 0,
        RightShift = 0,
    }

    local mouse = {
        Delta = Vector2.new(),
        MouseWheel = 0,
    }

    local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
    local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
    local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
    local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
    local FOV_WHEEL_SPEED    = 1.0
    local FOV_GAMEPAD_SPEED  = 0.25
    local NAV_ADJ_SPEED      = 0.75
    local NAV_SHIFT_MUL      = 0.25

    local navSpeed = 1

    function Input.Vel(dt)
        navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

        local kGamepad = Vector3.new(
            thumbstickCurve(gamepad.Thumbstick1.X),
            thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
            thumbstickCurve(-gamepad.Thumbstick1.Y)
        )*NAV_GAMEPAD_SPEED

        local kKeyboard = Vector3.new(
            keyboard.D - keyboard.A + keyboard.K - keyboard.H,
            keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
            keyboard.S - keyboard.W + keyboard.J - keyboard.U
        )*NAV_KEYBOARD_SPEED

        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

        return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
    end

    function Input.Pan(dt)
        local kGamepad = Vector2.new(
            thumbstickCurve(gamepad.Thumbstick2.Y),
            thumbstickCurve(-gamepad.Thumbstick2.X)
        )*PAN_GAMEPAD_SPEED
        local kMouse = mouse.Delta*PAN_MOUSE_SPEED
        mouse.Delta = Vector2.new()
        return kGamepad + kMouse
    end

    function Input.Fov(dt)
        local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
        local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
        mouse.MouseWheel = 0
        return kGamepad + kMouse
    end

    do
        local function Keypress(action, state, input)
            keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
            return Enum.ContextActionResult.Sink
        end

        local function GpButton(action, state, input)
            gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
            return Enum.ContextActionResult.Sink
        end

        local function MousePan(action, state, input)
            local delta = input.Delta
            mouse.Delta = Vector2.new(-delta.y, -delta.x)
            return Enum.ContextActionResult.Sink
        end

        local function Thumb(action, state, input)
            gamepad[input.KeyCode.Name] = input.Position
            return Enum.ContextActionResult.Sink
        end

        local function Trigger(action, state, input)
            gamepad[input.KeyCode.Name] = input.Position.z
            return Enum.ContextActionResult.Sink
        end

        local function MouseWheel(action, state, input)
            mouse[input.UserInputType.Name] = -input.Position.z
            return Enum.ContextActionResult.Sink
        end

        local function Zero(t)
            for k, v in pairs(t) do
                t[k] = v*0
            end
        end

        function Input.StartCapture()
            ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
                Enum.KeyCode.W, Enum.KeyCode.U,
                Enum.KeyCode.A, Enum.KeyCode.H,
                Enum.KeyCode.S, Enum.KeyCode.J,
                Enum.KeyCode.D, Enum.KeyCode.K,
                Enum.KeyCode.E, Enum.KeyCode.I,
                Enum.KeyCode.Q, Enum.KeyCode.Y,
                Enum.KeyCode.Up, Enum.KeyCode.Down
            )
            ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
            ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
            ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
            ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
            ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
        end

        function Input.StopCapture()
            navSpeed = 1
            Zero(gamepad)
            Zero(keyboard)
            Zero(mouse)
            ContextActionService:UnbindAction("FreecamKeyboard")
            ContextActionService:UnbindAction("FreecamMousePan")
            ContextActionService:UnbindAction("FreecamMouseWheel")
            ContextActionService:UnbindAction("FreecamGamepadButton")
            ContextActionService:UnbindAction("FreecamGamepadTrigger")
            ContextActionService:UnbindAction("FreecamGamepadThumbstick")
        end
    end
end

-----------

local function StepFreecam(dt)
    local vel = velSpring:Update(dt, Input.Vel(dt))
    local pan = panSpring:Update(dt, Input.Pan(dt))
    local fov = fovSpring:Update(dt, Input.Fov(dt))

    local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

    cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
    cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
    cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

    local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
    cameraPos = cameraCFrame.p

    Camera.CFrame = cameraCFrame
    Camera.Focus = cameraCFrame
    Camera.FieldOfView = cameraFov
end

local function CheckMouseLockAvailability()
    local devAllowsMouseLock = Players.LocalPlayer.DevEnableMouseLock
    local devMovementModeIsScriptable = Players.LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
    local userHasMouseLockModeEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
    local userHasClickToMoveEnabled =  GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
    local MouseLockAvailable = devAllowsMouseLock and userHasMouseLockModeEnabled and not userHasClickToMoveEnabled and not devMovementModeIsScriptable

    return MouseLockAvailable
end

-----------

local PlayerState = {} do
    local mouseBehavior
    local mouseIconEnabled
    local cameraType
    local cameraFocus
    local cameraCFrame
    local cameraFieldOfView
    local screenGuis = {}
    local coreGuis = {
        Backpack = true,
        Chat = true,
        Health = true,
        PlayerList = true,
    }
    local setCores = {
        BadgesNotificationsActive = true,
        PointsNotificationsActive = true,
    }

    -- Save state and set up for freecam
    function PlayerState.Push()
        for name in pairs(coreGuis) do
            coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
        end
        for name in pairs(setCores) do
            setCores[name] = StarterGui:GetCore(name)
            StarterGui:SetCore(name, false)
        end
        local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playergui then
            for _, gui in pairs(playergui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    screenGuis[#screenGuis + 1] = gui
                    gui.Enabled = false
                end
            end
        end

        cameraFieldOfView = Camera.FieldOfView
        Camera.FieldOfView = 70

        cameraType = Camera.CameraType
        Camera.CameraType = Enum.CameraType.Custom

        cameraCFrame = Camera.CFrame
        cameraFocus = Camera.Focus

        mouseIconEnabled = UserInputService.MouseIconEnabled
        UserInputService.MouseIconEnabled = false

        if FFlagUserExitFreecamBreaksWithShiftlock and CheckMouseLockAvailability() then
            mouseBehavior = Enum.MouseBehavior.Default
        else
            mouseBehavior = UserInputService.MouseBehavior
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end

    -- Restore state
    function PlayerState.Pop()
        for name, isEnabled in pairs(coreGuis) do
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
        end
        for name, isEnabled in pairs(setCores) do
            StarterGui:SetCore(name, isEnabled)
        end
        for _, gui in pairs(screenGuis) do
            if gui.Parent then
                gui.Enabled = true
            end
        end

        Camera.FieldOfView = cameraFieldOfView
        cameraFieldOfView = nil

        Camera.CameraType = cameraType
        cameraType = nil

        Camera.CFrame = cameraCFrame
        cameraCFrame = nil

        Camera.Focus = cameraFocus
        cameraFocus = nil

        UserInputService.MouseIconEnabled = mouseIconEnabled
        mouseIconEnabled = nil

        UserInputService.MouseBehavior = mouseBehavior
        mouseBehavior = nil
    end
end

local function StartFreecam()
    if FFlagUserShowGuiHideToggles then
        script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, true)
    end

    local cameraCFrame = Camera.CFrame
    cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
    cameraPos = cameraCFrame.p
    cameraFov = Camera.FieldOfView

    velSpring:Reset(Vector3.new())
    panSpring:Reset(Vector2.new())
    fovSpring:Reset(0)

    PlayerState.Push()
    RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
    Input.StartCapture()
end

local function StopFreecam()
    if FFlagUserShowGuiHideToggles then
        script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, false)
    end

    Input.StopCapture()
    RunService:UnbindFromRenderStep("Freecam")
    PlayerState.Pop()
end

-----------

do
    local enabled = false

    local function ToggleFreecam()
        if enabled then
            StopFreecam()
        else
            StartFreecam()
        end
        enabled = not enabled
    end

    local function CheckMacro(macro)
        for i = 1, #macro - 1 do
            if not UserInputService:IsKeyDown(macro[i]) then
                return
            end
        end
        ToggleFreecam()
    end

    local function HandleActivationInput(action, state, input)
        if state == Enum.UserInputState.Begin then
            if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
                CheckMacro(FREECAM_MACRO_KB)
            end
        end
        return Enum.ContextActionResult.Pass
    end

    ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])

    if FFlagUserShowGuiHideToggles then
        script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, enabled)
        script:GetAttributeChangedSignal(FREECAM_ENABLED_ATTRIBUTE_NAME):Connect(function()
            local attributeValue = script:GetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME)

            if typeof(attributeValue) ~= "boolean" then
                script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, enabled)
                return
            end

            -- If the attribute's value and `enabled` var don't match, pick attribute value as
            -- source of truth
            if attributeValue ~= enabled then
                if attributeValue then
                    StartFreecam()
                    enabled = true
                else
                    StopFreecam()
                    enabled = false
                end
            end
        end)
    end
end

local hds_FreecamEnabled = false
local hds_currentBind = Enum.KeyCode.P
local hds_isPlayerAlive = true

-- Получение сервисов и игрока
local LocalPlayer = Players.LocalPlayer
local Player = Players.LocalPlayer
local hds_Humanoid

local function hds_EnableFreecam()
    if not hds_isPlayerAlive then
        WindUI:Notify({
            Title = "FreeCam",
            Content = "You must be alive to use Freecam.",
            Icon = "x",
            Duration = 2
        })
        return
    end

    if not hds_FreecamEnabled then
        StartFreecam()
        hds_FreecamEnabled = true
        featureToggle:SetValue(true)
        WindUI:Notify({
            Title = "FreeCam",
            Content = "FreeCam Enabled",
            Icon = "check",
            Duration = 2
        })
    end
end

local function hds_DisableFreecam()
    if hds_FreecamEnabled then
        StopFreecam()
        hds_FreecamEnabled = false
        featureToggle:SetValue(false)
        WindUI:Notify({
            Title = "FreeCam",
            Content = "FreeCam Disabled",
            Icon = "x",
            Duration = 2
        })
    end
end

--------------------------------------------------------------------------------------------------------------------------------

-- Глобальные переменные и настройки
_G.ayl_ESPEnabled = false
_G.ayl_TeamCheck = false
_G.ayl_TextColor = Color3.fromRGB(255, 255, 255)
_G.ayl_TextSize = 14
_G.ayl_Center = true
_G.ayl_Outline = true
_G.ayl_OutlineColor = Color3.fromRGB(0, 0, 0)
_G.ayl_TextTransparency = 0.9
_G.ayl_TextFont = Drawing.Fonts.UI

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Таблица для хранения ESP-объектов для каждого игрока
local playerESPs = {}
local renderConnection = nil
local playerConnections = {}

-- Проверка доступности API
local function isDrawingAPIAvailable()
    return Drawing ~= nil
end

if not isDrawingAPIAvailable() then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Exunys Developer";
        Text = "ESP script could not be loaded because your exploit is unsupported.";
        Duration = math.huge;
        Button1 = "OK"
    })
    return
end

-- Функция для создания или получения Drawing объекта для игрока
local function getOrCreatePlayerESP(player)
    if player == Players.LocalPlayer then return nil end

    if not playerESPs[player] then
        local espDrawing = Drawing.new("Text")
        playerESPs[player] = espDrawing

        -- Добавляем обработчик, который удаляет ESP при выходе игрока
        playerConnections[player] = player.CharacterRemoving:Connect(function()
            if playerESPs[player] then
                playerESPs[player]:Remove()
                playerESPs[player] = nil
            end
        end)
    end
    return playerESPs[player]
end

-- Функция для обновления всех ESP-объектов
local function updateESPs()
    for _, player in ipairs(Players:GetPlayers()) do
        local espDrawing = getOrCreatePlayerESP(player)
        if not espDrawing then continue end

        local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            espDrawing.Visible = false
            continue
        end

        local head = player.Character:FindFirstChild("Head")
        local vector, onScreen = Camera:WorldToViewportPoint(head.Position)

        espDrawing.Size = _G.ayl_TextSize
        espDrawing.Center = _G.ayl_Center
        espDrawing.Outline = _G.ayl_Outline
        espDrawing.OutlineColor = _G.ayl_OutlineColor
        espDrawing.Color = _G.ayl_TextColor
        espDrawing.Transparency = _G.ayl_TextTransparency
        espDrawing.Font = _G.ayl_TextFont

        local isTeamMate = _G.ayl_TeamCheck and Players.LocalPlayer.Team == player.Team

        if onScreen and not isTeamMate and _G.ayl_ESPEnabled then
            local localPlayerRootPart = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = 0
            if localPlayerRootPart then
                distance = (humanoidRootPart.Position - localPlayerRootPart.Position).Magnitude
            end

            espDrawing.Position = Vector2.new(vector.X, vector.Y - 25)
            espDrawing.Text = string.format("(%d) %s [%d]", math.floor(distance), player.Name, player.Character.Humanoid.Health)
            espDrawing.Visible = true
        else
            espDrawing.Visible = false
        end
    end
end

-- Функции для включения и выключения ESP
function aylEnableEsp()
    if _G.ayl_ESPEnabled then return end
    _G.ayl_ESPEnabled = true
    
    -- Запускаем единственный цикл обновления
    if not renderConnection then
        renderConnection = RunService.RenderStepped:Connect(updateESPs)
    end
end

function aylDisableEsp()
    if not _G.ayl_ESPEnabled then return end
    _G.ayl_ESPEnabled = false

    -- Отключаем цикл обновления
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    -- Скрываем все существующие ESP-объекты
    for _, esp in pairs(playerESPs) do
        esp.Visible = false
    end
end

--------------------------------------------------------------------------------------------------------------------------------

-- Settings
local alpboxSettings = {
    alpBox_Color = Color3.fromRGB(255, 255, 255),
    alpBox_Thickness = 2,
    alpTeam_Check = false,
    alpTeam_Color = false,
    alpAutothickness = true
}

--Locals
local alpSpace = game:GetService("Workspace")
local alpPlayer = game:GetService("Players").LocalPlayer
local alpCamera = alpSpace.CurrentCamera
local connections = {}
local drawings = {}
local parts = {}
local espEnabled = false

-- Locals
local function alpNewLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function alpVis(lib, state)
    for i, v in pairs(lib) do
        v.Visible = state
    end
end

local function alpColorize(lib, color)
    for i, v in pairs(lib) do
        v.Color = color
    end
end

local alpBlack = Color3.fromRGB(0, 0, 0)

-- Main Draw Function
local function alpMain(plr)
    repeat wait() until plr.Character ~= nil and plr.Character:FindFirstChild("Humanoid") ~= nil
    local R15

    if plr.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
        R15 = true
    else
        R15 = false
    end

    local alpLibrary = {
        alpTL1 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpTL2 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpTR1 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpTR2 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpBL1 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpBL2 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpBR1 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness),
        alpBR2 = alpNewLine(alpboxSettings.alpBox_Color, alpboxSettings.alpBox_Thickness)
    }

    local alporipart = Instance.new("Part")
    alporipart.Parent = alpSpace
    alporipart.Transparency = 1
    alporipart.CanCollide = false
    alporipart.Size = Vector3.new(1, 1, 1)
    alporipart.Position = Vector3.new(0, 0, 0)

    drawings[plr] = alpLibrary
    parts[plr] = alporipart

    --Updater Loop
    local function alpUpdater()
        if not espEnabled then
            alpVis(alpLibrary, false)
            return
        end
        if plr.Character ~= nil and plr.Character:FindFirstChild("Humanoid") ~= nil and plr.Character:FindFirstChild("HumanoidRootPart") ~= nil and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("Head") ~= nil then
            local alpHum = plr.Character
            local alpHumPos, vis = alpCamera:WorldToViewportPoint(alpHum.HumanoidRootPart.Position)
            if vis then
                alporipart.Size = Vector3.new(alpHum.HumanoidRootPart.Size.X, alpHum.HumanoidRootPart.Size.Y * 1.5, alpHum.HumanoidRootPart.Size.Z)
                alporipart.CFrame = CFrame.new(alpHum.HumanoidRootPart.CFrame.Position, alpCamera.CFrame.Position)
                local alpSizeX = alporipart.Size.X
                local alpSizeY = alporipart.Size.Y
                local alpTL = alpCamera:WorldToViewportPoint((alporipart.CFrame * CFrame.new(alpSizeX, alpSizeY, 0)).p)
                local alpTR = alpCamera:WorldToViewportPoint((alporipart.CFrame * CFrame.new(-alpSizeX, alpSizeY, 0)).p)
                local alpBL = alpCamera:WorldToViewportPoint((alporipart.CFrame * CFrame.new(alpSizeX, -alpSizeY, 0)).p)
                local alpBR = alpCamera:WorldToViewportPoint((alporipart.CFrame * CFrame.new(-alpSizeX, -alpSizeY, 0)).p)

                if alpboxSettings.alpTeam_Check then
                    if plr.TeamColor == alpPlayer.TeamColor then
                        alpColorize(alpLibrary, Color3.fromRGB(0, 255, 0))
                    else
                        alpColorize(alpLibrary, Color3.fromRGB(255, 0, 0))
                    end
                end

                if alpboxSettings.alpTeam_Color then
                    alpColorize(alpLibrary, plr.TeamColor.Color)
                end
                local alpratio = (alpCamera.CFrame.p - alpHum.HumanoidRootPart.Position).magnitude
                local alpoffset = math.clamp(1 / alpratio * 750, 2, 300)
                alpLibrary.alpTL1.From = Vector2.new(alpTL.X, alpTL.Y)
                alpLibrary.alpTL1.To = Vector2.new(alpTL.X + alpoffset, alpTL.Y)
                alpLibrary.alpTL2.From = Vector2.new(alpTL.X, alpTL.Y)
                alpLibrary.alpTL2.To = Vector2.new(alpTL.X, alpTL.Y + alpoffset)
                alpLibrary.alpTR1.From = Vector2.new(alpTR.X, alpTR.Y)
                alpLibrary.alpTR1.To = Vector2.new(alpTR.X - alpoffset, alpTR.Y)
                alpLibrary.alpTR2.From = Vector2.new(alpTR.X, alpTR.Y)
                alpLibrary.alpTR2.To = Vector2.new(alpTR.X, alpTR.Y + alpoffset)
                alpLibrary.alpBL1.From = Vector2.new(alpBL.X, alpBL.Y)
                alpLibrary.alpBL1.To = Vector2.new(alpBL.X + alpoffset, alpBL.Y)
                alpLibrary.alpBL2.From = Vector2.new(alpBL.X, alpBL.Y)
                alpLibrary.alpBL2.To = Vector2.new(alpBL.X, alpBL.Y - alpoffset)
                alpLibrary.alpBR1.From = Vector2.new(alpBR.X, alpBR.Y)
                alpLibrary.alpBR1.To = Vector2.new(alpBR.X - alpoffset, alpBR.Y)
                alpLibrary.alpBR2.From = Vector2.new(alpBR.X, alpBR.Y)
                alpLibrary.alpBR2.To = Vector2.new(alpBR.X, alpBR.Y - alpoffset)
                alpVis(alpLibrary, true)

                if alpboxSettings.alpAutothickness then
                    local distance = (alpPlayer.Character.HumanoidRootPart.Position - alporipart.Position).magnitude
                    local value = math.clamp(1 / distance * 100, 1, 4)
                    for u, x in pairs(alpLibrary) do
                        x.Thickness = value
                    end
                else
                    for u, x in pairs(alpLibrary) do
                        x.Thickness = alpboxSettings.alpBox_Thickness
                    end
                end
            else
                alpVis(alpLibrary, false)
            end
        else
            alpVis(alpLibrary, false)
            if game:GetService("Players"):FindFirstChild(plr.Name) == nil then
                for i, v in pairs(alpLibrary) do
                    v:Remove()
                end
                alporipart:Destroy()
                if connections[plr] then
                    connections[plr]:Disconnect()
                    connections[plr] = nil
                end
                drawings[plr] = nil
                parts[plr] = nil
            end
        end
    end
    connections[plr] = game:GetService("RunService").RenderStepped:Connect(alpUpdater)
end

function AlpBoxEnableEsp()
    if not espEnabled then
        espEnabled = true
        for i, v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name ~= alpPlayer.Name then
                coroutine.wrap(alpMain)(v)
            end
        end

        connections["PlayerAdded"] = game:GetService("Players").PlayerAdded:Connect(function(newplr)
            if newplr.Name ~= alpPlayer.Name then
                coroutine.wrap(alpMain)(newplr)
            end
        end)
    end
end

function AlpBoxDisableEsp()
    if espEnabled then
        espEnabled = false
        for _, lib in pairs(drawings) do
            alpVis(lib, false)
        end
        if connections["PlayerAdded"] then
            connections["PlayerAdded"]:Disconnect()
            connections["PlayerAdded"] = nil
        end
    end
end

--------------------------------------------------------------------------------------------------------------------------------

-- Noclip функционал
local noclipEnabled = false

local function toggleNoclip(state)
    noclipEnabled = state
    if noclipEnabled then
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
        end
    end
end

-- Подключение событий для возрождения и смерти персонажа
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    -- Подключение события смерти персонажа
    character:WaitForChild("Humanoid").Died:Connect(onCharacterDied)
end)

-- Подключение события смерти для текущего персонажа
if character:FindFirstChild("Humanoid") then
    character.Humanoid.Died:Connect(onCharacterDied)
end

--------------------------------------------------------------------------------------------------------------------------------

if not Drawing then
    return warn("Drawing library is not available. This script requires an executor with Drawing support.")
end

local SKELET_COLOR = Color3.fromRGB(255, 255, 255)
local SKELET_THICKNESS = 3

local bonesR15 = {
    {"HumanoidRootPart", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"UpperTorso", "LeftUpperArm"},
    {"UpperTorso", "Head"},
    {"UpperTorso", "LowerTorso"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"LowerTorso", "RightUpperLeg"},
    {"LowerTorso", "LeftUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}
}

local bonesR6 = {
    {"HumanoidRootPart", "Torso"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Arm"},
    {"Torso", "Head"},
    {"Torso", "Right Leg"},
    {"Torso", "Left Leg"},
    {"Right Arm", "Right Leg"},
    {"Left Arm", "Left Leg"},
}

local playerLines = {}
local espConnection

-- Функция для получения списка костей
local function getSkelet(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local bones
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        bones = bonesR15
    elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
        bones = bonesR6
    else
        return
    end

    local partPairs = {}
    for _, bone in ipairs(bones) do
        local part1 = character:FindFirstChild(bone[1], true)
        local part2 = character:FindFirstChild(bone[2], true)

        if part1 and part2 then
            table.insert(partPairs, {part1, part2})
        end
    end
    return partPairs
end

-- Функция для очистки линий
local function clearLines(lines)
    if lines then
        for _, line in ipairs(lines) do
            line:Remove()
        end
    end
end

-- Основной цикл отрисовки ESP
local function updateESP()
    for player, lines in pairs(playerLines) do
        clearLines(lines)
    end
    playerLines = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local skelet = getSkelet(player.Character)
            if skelet then
                local currentLines = {}
                local camera = Workspace.CurrentCamera
                if not camera then continue end

                for _, boneParts in ipairs(skelet) do
                    local part1 = boneParts[1]
                    local part2 = boneParts[2]

                    local screenPoint1, onScreen1 = camera:WorldToViewportPoint(part1.Position)
                    local screenPoint2, onScreen2 = camera:WorldToViewportPoint(part2.Position)

                    if onScreen1 and onScreen2 then
                        local line = Drawing.new("Line")
                        line.From = Vector2.new(screenPoint1.X, screenPoint1.Y)
                        line.To = Vector2.new(screenPoint2.X, screenPoint2.Y)
                        line.Color = SKELET_COLOR
                        line.Thickness = SKELET_THICKNESS
                        line.Transparency = 1
                        line.Visible = true
                        table.insert(currentLines, line)
                    end
                end
                playerLines[player] = currentLines
            end
        end
    end
end

-- Функция включения ESP
local function enableESP()
    if espConnection then return end
    espConnection = RunService.RenderStepped:Connect(updateESP)
    -- Подключаем обработчик на случай выхода игрока
    Players.PlayerRemoving:Connect(function(player)
        local lines = playerLines[player]
        clearLines(lines)
        playerLines[player] = nil
    end)
end

-- Функция выключения ESP
local function disableESP()
    if not espConnection then return end
    espConnection:Disconnect()
    espConnection = nil
    for player, lines in pairs(playerLines) do
        clearLines(lines)
    end
    playerLines = {}
end

--------------------------------------------------------------------------------------------------------------------------------

local Drawing = Drawing
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local tracerTyping = false
local tracerTracers = {}
local tracerIsEnabled = false

-- Локальные переменные для настроек
local tracerFromMouse = false
local tracerFromCenter = false
local tracerFromBottom = true
local tracerVisible = true
local tracerThickness = 3
local tracerTransparency = 0.9
local tracerModeSkipKey = Enum.KeyCode.E
local tracerDisableKey = Enum.KeyCode.Q

local function tracerCheckAPI()
    if Drawing == nil then
        return "No"
    else
        return "Yes"
    end
end

local tracerAPI_Required = tracerCheckAPI()

if tracerAPI_Required == "No" then
    return
end

-- Функция для получения единого цвета трейсера
local function getTracerColor()
    return Color3.fromRGB(255, 255, 255)
end

-- Функция для создания одного трейсера
local function createSingleTracer(player)
    if player.Name == Players.LocalPlayer.Name then return end

    local TracerLine = Drawing.new("Line")
    local connection = RunService.RenderStepped:Connect(function()
        if tracerIsEnabled and workspace:FindFirstChild(player.Name) ~= nil and workspace[player.Name]:FindFirstChild("HumanoidRootPart") ~= nil then
            local humanoidRootPart = workspace[player.Name].HumanoidRootPart
            local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.CFrame * CFrame.new(0, -humanoidRootPart.Size.Y, 0).p)
            
            TracerLine.Thickness = tracerThickness
            TracerLine.Transparency = tracerTransparency
            TracerLine.Color = getTracerColor()

            if tracerFromMouse then
                TracerLine.From = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
            elseif tracerFromCenter then
                TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            elseif tracerFromBottom then
                TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            end

            TracerLine.To = Vector2.new(vector.X, vector.Y)
            TracerLine.Visible = onScreen and tracerVisible
        else
            TracerLine.Visible = false
        end
    end)
    
    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(playerRemoving)
        if playerRemoving == player then
            TracerLine.Visible = false
            connection:Disconnect()
            playerRemovingConnection:Disconnect()
        end
    end)

    return TracerLine, connection, playerRemovingConnection
end

-- Функция для создания всех трейсеров
local function createTracers()
    if not tracerIsEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local tracer, connection, playerRemovingConnection = createSingleTracer(player)
        if tracer then
            tracerTracers[player.Name] = { Tracer = tracer, Connection = connection, PlayerRemoving = playerRemovingConnection }
        end
    end
end

-- Функция для удаления всех трейсеров
local function destroyTracers()
    for playerName, data in pairs(tracerTracers) do
        data.Tracer.Visible = false
        data.Connection:Disconnect()
        data.PlayerRemoving:Disconnect()
        data.Tracer:Destroy()
    end
    tracerTracers = {}
end

-- Обработка добавления нового игрока
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    local tracer, connection, playerRemovingConnection = createSingleTracer(player)
    if tracer then
        tracerTracers[player.Name] = { Tracer = tracer, Connection = connection, PlayerRemoving = playerRemovingConnection }
    end
end)

UserInputService.TextBoxFocused:Connect(function()
    tracerTyping = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    tracerTyping = false
end)

UserInputService.InputBegan:Connect(function(Input)
    if not tracerIsEnabled then return end
    if Input.KeyCode == tracerModeSkipKey and tracerTyping == false then
        if tracerFromMouse and tracerVisible then
            tracerFromMouse = false
            tracerFromCenter = false
            tracerFromBottom = true
        elseif tracerFromBottom and tracerVisible then
            tracerFromMouse = false
            tracerFromCenter = true
            tracerFromBottom = false
        elseif tracerFromCenter and tracerVisible then
            tracerFromMouse = true
            tracerFromCenter = false
            tracerFromBottom = false
        end
    elseif Input.KeyCode == tracerDisableKey and tracerTyping == false then
        tracerVisible = not tracerVisible
    end
end)

-- Теперь это функция, которую можно вызвать для инициализации трейсеров
local function enableTracers()
    tracerIsEnabled = true
    createTracers()
end

local function disableTracers()
    tracerIsEnabled = false
    destroyTracers()
end

--------------------------------------------------------------------------------------------------------------------------------

local isXjxFrozen = false

local function setXjxFrozen(state)
    local xjxPlayers = game:GetService("Players")
    local xjxCharacter = xjxPlayers.LocalPlayer.Character

    if xjxCharacter then
        local xjxHumanoidRootPart = xjxCharacter:FindFirstChild("HumanoidRootPart")
        if xjxHumanoidRootPart then
            isXjxFrozen = state
            xjxHumanoidRootPart.Anchored = isXjxFrozen
        end
    end
end

isXjxFrozen = false

--------------------------------------------------------------------------------------------------------------------------------

local wallhackTransparency = 0.6
local wallhackActive = false

-- Функция для установки прозрачности
local function setWallsTransparency()
    local targetTransparency = wallhackActive and wallhackTransparency or 0

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = targetTransparency
        end
    end
end

-- Основной цикл обновления
local function wallhackLoop()
    while wallhackActive do
        setWallsTransparency()
        wait(1)
    end
    setWallsTransparency()
end

-- Обработка новых объектов
workspace.DescendantAdded:Connect(function(part)
    if part:IsA("BasePart") and wallhackActive then
        part.LocalTransparencyModifier = wallhackTransparency
    end
end)

--------------------------------------------------------------------------------------------------------------------------------

WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

local function gradient(text, startColor, endColor)
    local result = ""
    for i = 1, #text do
        local t = (i - 1) / (#text - 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text:sub(i, i))
    end
    return result
end

local Window = WindUI:CreateWindow({
    Title = "WindUI",
    Icon = "palette",
    Author = "Welcome to WindUI!",
    Folder = "WindUI_Example",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "User Profile",
                Content = "User profile clicked!",
                Duration = 3
            })
        end
    },
    SideBarWidth = 200,
    KeySystem = { 
        Key = { "Hi", "Hello" },
        Note = "Example Key System. With platoboost, etc.",
        URL = "https://t.me/bio_by_iqoksz95",
        humbnail = {
           Image = "rbxassetid://",
           Title = "Thumbnail",
        },
        SaveKey = true,
    },
})

Window:Tag({
    Title = "v1.6.4",
    Color = Color3.fromHex("#000000")
})
Window:Tag({
    Title = "Beta",
    Color = Color3.fromHex("#000000")
})
local TimeTag = Window:Tag({
    Title = "00:00",
    Color = Color3.fromHex("#000000")
})

task.spawn(function()
	while true do
		local now = os.date("*t")
		local hours = string.format("%02d", now.hour)
		local minutes = string.format("%02d", now.min)
		
		TimeTag:SetTitle(hours .. ":" .. minutes)
		TimeTag:SetColor(Color3.fromHex("#000000"))

		task.wait(0.06)
	end
end)

Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
    WindUI:Notify({
        Title = "Theme Changed",
        Content = "Current theme: "..WindUI:GetCurrentTheme(),
        Duration = 2
    })
end, 990)

--------------------------------------------------------------------------------------------------------------------------------

-- Configuration
local APQ_INVENTORY_SLOTS_COUNT = 9

-- GUI Creation
local apqInventoryScreenGui = Instance.new("ScreenGui")
apqInventoryScreenGui.Name = "apqInventoryGui"
apqInventoryScreenGui.Parent = PlayerGui

local apqInventoryMainWindow = Instance.new("Frame")
apqInventoryMainWindow.Name = "apqMainWindow"
apqInventoryMainWindow.Size = UDim2.new(0, 540, 0, 60)
apqInventoryMainWindow.Position = UDim2.new(0.325, 0, 0.358, 0)
apqInventoryMainWindow.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
apqInventoryMainWindow.BackgroundTransparency = 0.45
apqInventoryMainWindow.Active = true
apqInventoryMainWindow.Draggable = true
apqInventoryMainWindow.Parent = apqInventoryScreenGui
apqInventoryMainWindow.Visible = false

local apqUIStroke = Instance.new("UIStroke")
apqUIStroke.Thickness = 1
apqUIStroke.Color = Color3.fromRGB(0, 0, 0)
apqUIStroke.Parent = apqInventoryMainWindow

local apqUICorner = Instance.new("UICorner")
apqUICorner.CornerRadius = UDim.new(0, 8)
apqUICorner.Parent = apqInventoryMainWindow

local apqInventorySlots = {}

for i = 1, APQ_INVENTORY_SLOTS_COUNT do
    local slot = Instance.new("Frame")
    slot.Name = "apqSlot_" .. i
    slot.Size = UDim2.new(1 / APQ_INVENTORY_SLOTS_COUNT, -1, 1, -1)
    slot.Position = UDim2.new((i - 1) / APQ_INVENTORY_SLOTS_COUNT, 1, 0, 1)
    slot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    slot.BackgroundTransparency = 0.45
    slot.BorderSizePixel = 0
    slot.Parent = apqInventoryMainWindow

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 5)
    uiCorner.Parent = slot

    local itemImage = Instance.new("ImageLabel")
    itemImage.Name = "apqItemImage"
    itemImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    itemImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemImage.BackgroundTransparency = 1
    itemImage.Parent = slot
    
    local itemName = Instance.new("TextLabel")
    itemName.Name = "apqItemName"
    itemName.Size = UDim2.new(1, 0, 0, 15)
    itemName.Position = UDim2.new(0, 0, 1, -15)
    itemName.BackgroundTransparency = 1
    itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemName.Font = Enum.Font.SourceSans
    itemName.TextSize = 10
    itemName.TextWrapped = true
    itemName.TextXAlignment = Enum.TextXAlignment.Center
    itemName.Parent = slot

    table.insert(apqInventorySlots, slot)
end

-- Script Logic
local apqInventoryCheckEnabled = false
local currentTarget = nil
local updateConnection = nil
local humanoidConnection = nil

local function getTargetPlayer()
    local origin = LocalPlayer.Character and LocalPlayer.Character.Head and LocalPlayer.Character.Head.Position
    local direction = LocalPlayer.Character and LocalPlayer.Character.Head and LocalPlayer.Character.Head.CFrame.LookVector
    if not origin or not direction then return nil end

    local ray = Ray.new(origin, direction * 5000) -- Raycast a long distance
    local hit, position, normal = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)

    if hit and hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
        local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        if hitPlayer and hitPlayer ~= LocalPlayer then
            return hitPlayer
        end
    end
    return nil
end

local function updateInventoryDisplay(targetPlayer)
    if not targetPlayer then
        apqInventoryMainWindow.Visible = false
        return
    end

    local itemsContainer = targetPlayer:FindFirstChild("Backpack") or targetPlayer:FindFirstChild("StarterGear")
    if not itemsContainer then
        apqInventoryMainWindow.Visible = false
        return
    end

    apqInventoryMainWindow.Visible = true

    for i, slot in ipairs(apqInventorySlots) do
        local itemImage = slot:FindFirstChild("apqItemImage")
        local itemName = slot:FindFirstChild("apqItemName")

        if itemImage and itemName then
            local item = itemsContainer:GetChildren()[i]
            if item and item:IsA("Tool") then
                itemImage.Image = item.TextureId
                itemName.Text = item.Name
                itemImage.Visible = true
                itemName.Visible = true
            else
                itemImage.Image = ""
                itemName.Text = ""
                itemImage.Visible = false
                itemName.Visible = false
            end
        end
    end
end

local function onPlayerDied()
    apqInventoryMainWindow.Visible = false
end

local function runUpdateLoop()
    while apqInventoryCheckEnabled do
        local target = getTargetPlayer()
        if target ~= currentTarget then
            currentTarget = target
        end
        updateInventoryDisplay(currentTarget)
        wait(0.1)
    end
end

function apqInventoryCheckEnabled()
    if apqInventoryCheckEnabled then return end
    apqInventoryCheckEnabled = true
    spawn(runUpdateLoop)
    humanoidConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid").Died:Connect(onPlayerDied)
    end)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Died:Connect(onPlayerDied)
    end
end

function apqInventoryCheckDisabled()
    if not apqInventoryCheckEnabled then return end
    apqInventoryCheckEnabled = false
    apqInventoryMainWindow.Visible = false
    if humanoidConnection then humanoidConnection:Disconnect() end
end

function InventoryPlayersCheckShow(state)
    if state then
        apqInventoryCheckEnabled()
    else
        apqInventoryCheckDisabled()
    end
end

--------------------------------------------------------------------------------------------------------------------------------

local Tabs = {
    Main = Window:Section({ Title = "Main", Opened = true }),
    Another = Window:Section({ Title = "Another", Opened = true }),
    Settings = Window:Section({ Title = "Settings", Opened = true }),
}

local TabHandles = {
    Aim = Tabs.Main:Tab({ Title = "Aim", Icon = "layout-grid" }),
    Esp = Tabs.Main:Tab({ Title = "Visual", Icon = "layout-grid" }),
    Player = Tabs.Main:Tab({ Title = "Player", Icon = "layout-grid" }),

    Scripts = Tabs.Another:Tab({ Title = "Scripts", Icon = "layout-grid" }),

    Info = Tabs.Settings:Tab({ Title = "Info", Icon = "layout-grid" }),
    Appearance = Tabs.Settings:Tab({ Title = "Appearance", Icon = "brush" }),
}

--------------------------------------------------------------------------------------------------------------------------------

local toggleState = false

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Aim:Paragraph({
    Title = "Aim Components",
    Desc = "Explore Aim's powerful functions",
    Image = "component",
    ImageSize = 20,
    Color = "White"
})

TabHandles.Aim:Divider()

local featureToggle = TabHandles.Aim:Toggle({
    Title = "AimBot",
    Value = false,
    Callback = function(state) 
        slk_aimbotEnabled = state
        if not state then
            slk_currentTarget = nil
        end

        WindUI:Notify({
            Title = "AimBot",
            Content = state and "AimBot Enabled" or "AimBot Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

TabHandles.Aim:Input({
    Title = "Bind",
    Placeholder = "Enter your bind",
    Callback = function(input) 
        local key = Enum.KeyCode[input:upper()]
        if key then
            slk_aimbotBind = key
            print("Aimbot bind set to: " .. input)
        else
            print("Invalid bind key: " .. input)
        end
    end
})

-- Обработка нажатия клавиши-бинда
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == slk_aimbotBind and not slk_keyIsPressed then
        slk_keyIsPressed = true
        local slk_toggleState = not slk_aimbotEnabled -- Используем slk_aimbotEnabled для получения текущего состояния
        featureToggle:Set(slk_toggleState)

        slk_aimbotEnabled = slk_toggleState
        if not slk_toggleState then
            slk_currentTarget = nil
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == slk_aimbotBind then
        slk_keyIsPressed = false
    end
end)

TabHandles.Aim:Divider()

local featureToggle = TabHandles.Aim:Toggle({
    Title = "DragFov",
    Value = false,
    Callback = function(state) 
        xklDragFovCircle.Visible = state

        WindUI:Notify({
            Title = "DragFov",
            Content = state and "DragFov Enabled" or "DragFov Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        
        })
    end
})

local featureToggle = TabHandles.Aim:Toggle({
    Title = "Aim",
    Value = false,
    Callback = function(state) 
        xklToggleDragFovAim(state)

        WindUI:Notify({
            Title = "DragFovAim",
            Content = state and "DragFovAim Enabled" or "DragFovAim Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        
        })
    end
})

TabHandles.Aim:Input({
    Title = "Bind",
    Placeholder = "Enter your bind",
    Callback = function(input) 
        xklSetKeybind(input)
    end
})

TabHandles.Aim:Divider()

local featureToggle = TabHandles.Aim:Toggle({
    Title = "HitBox",
    Value = false,
    Callback = function(state) 
        le.toggleState(Value)
        WindUI:Notify({
            Title = "HitBox",
            Content = state and "HitBox Enabled" or "HitBox Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        
        })
    end
})

local featureToggle = TabHandles.Aim:Toggle({
    Title = "TeamCheck",
    Value = false and le.TEAM_CHECK,
    Callback = function(state) 
        le.TEAM_CHECK = state

        WindUI:Notify({
            Title = "TeamCheck",
            Content = state and "TeamCheck Enabled" or "TeamCheck Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

-- ForceField Check
local featureToggle = TabHandles.Aim:Toggle({
    Title = "ForceField Check",
    Value = false and le.FORCEFIELD_CHECK,
    Callback = function(state)
        le.FORCEFIELD_CHECK = state
        WindUI:Notify({
            Title = "ForceField Check",
            Content = state and "ForceField Check Enabled" or "ForceField Check Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

-- Limb Collisions
local featureToggle = TabHandles.Aim:Toggle({
    Title = "Limb Collisions",
    Value = false and le.LIMB_CAN_COLLIDE,
    Callback = function(state) 
        le.LIMB_CAN_COLLIDE = state
        WindUI:Notify({
            Title = "Limb Collisions Check",
            Content = state and "Limb Collisions Enabled" or "Limb Collisions Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

-- Limb Transparency Slider
local transparencySlider = TabHandles.Aim:Slider({
    Title = "Limb Transparency",
    Value = { Min = 0, Max = 1, Default = le.LIMB_TRANSPARENCY },
    Step = 0.1,
    Callback = function(value)
        le.LIMB_TRANSPARENCY = value
    end
})

-- Limb Size Slider
local transparencySlider = TabHandles.Aim:Slider({
    Title = "Limb Size",
    Value = { Min = 5, Max = 50, Default = le.LIMB_SIZE },
    Step = 0.1,
    Callback = function(value)
        le.LIMB_SIZE = value
    end
})

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Esp:Paragraph({
    Title = "Esp Components",
    Desc = "Everything related to esp players",
    Image = "component",
    ImageSize = 20,
    Color = "White"
})

TabHandles.Esp:Divider()

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Players Inventory",
    Value = false,
    Callback = function(state) 
        InventoryPlayersCheckShow()

        WindUI:Notify({
            Title = "Players Inventory",
            Content = state and "Players Inventory Enabled" or "Players Inventory Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

TabHandles.Esp:Divider()

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Players Esp",
    Value = false,
    Callback = function(state) 
        toggleESP(state)

        WindUI:Notify({
            Title = "Players Esp",
            Content = state and "Players Esp Enabled" or "Players Esp Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Tracer Esp",
    Value = false,
    Callback = function(state) 
        tracerIsEnabled = state
        if state then
            createTracers()
        else
            destroyTracers()
        end

        WindUI:Notify({
            Title = "Tracer Esp",
            Content = state and "Tracer Esp Enabled" or "Tracer Esp Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Skelet Esp",
    Value = false,
    Callback = function(state) 
        if state then
            enableESP()
        else
            disableESP()
        end

        WindUI:Notify({
            Title = "Skelet Esp",
            Content = state and "Skelet Esp Enabled" or "Skelet Esp Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Box Esp",
    Value = false,
    Callback = function(state) 
        if state then
            AlpBoxEnableEsp()
        else
            AlpBoxDisableEsp()
        end

        WindUI:Notify({
            Title = "Box Esp",
            Content = state and "Box Esp Enabled" or "Box Esp Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Name Esp",
    Value = false,
    Callback = function(state) 
        if state then
            aylEnableEsp()
        else
            aylDisableEsp()
        end

        WindUI:Notify({

            Title = "Name Esp",
            Content = state and "Name Esp Enabled" or "Name Esp Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

TabHandles.Esp:Divider()

TabHandles.Esp:Button({
    Title = "Radar",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/universalhub11111/refs/heads/main/radar2.lua'))()

        WindUI:Notify({
            Title = "Radar",
            Content = "Radar runed",
            Icon = "bell",
            Duration = 2
        })
    end
})

TabHandles.Esp:Divider()

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Brightness",
    Value = false,
    Callback = function(state) 
        if state then
            dofullbright()
        else
            disablefullbright()
        end

        WindUI:Notify({
            Title = "Brightness",
            Content = state and "Brightness Enabled" or "Brightness Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

TabHandles.Esp:Divider()

local featureToggle = TabHandles.Esp:Toggle({
    Title = "FreeCam",
    Value = false,
    Callback = function(state) 
        if state then
            hds_EnableFreecam()
        else
            hds_DisableFreecam()
        end

        WindUI:Notify({
            Title = "FreeCam",
            Content = "You must be alive to use Freecam.",
            Icon = "x",
            Duration = 2
        })
    end
})

TabHandles.Esp:Input({
    Title = "Bind",
    Placeholder = "Enter your bind",
    Callback = function(input) 
        local key = Enum.KeyCode[input:upper()]
        if key and Enum.KeyCode[key.Name] then
            hds_currentBind = key
            print("Freecam bind set to: " .. input)
            WindUI:Notify({
                Title = "FreeCam",
                Content = "Bind set to: " .. input,
                Icon = "check",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "FreeCam",
                Content = "Invalid bind key: " .. input,
                Icon = "x",
                Duration = 2
            })
        end
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == hds_currentBind and not hds_FreecamEnabled then
        hds_EnableFreecam()
    elseif input.KeyCode == hds_currentBind and hds_FreecamEnabled then
        hds_DisableFreecam()
    end
end)

local function onCharacterAdded(character)
    hds_Humanoid = character:WaitForChild("Humanoid")
    hds_isPlayerAlive = true

    hds_Humanoid.Died:Connect(function()
        hds_isPlayerAlive = false
        hds_DisableFreecam()
    end)
end

-- Начальная проверка, если персонаж уже загружен
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

-- Отслеживание каждого нового персонажа после смерти/возрождения
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

TabHandles.Esp:Divider()

local featureToggle = TabHandles.Esp:Toggle({
    Title = "Wallhack",
    Value = false,
    Callback = function(state) 
        wallhackActive = state
        if wallhackActive then
            wallhackLoop()
        end

        WindUI:Notify({
            Title = "Wallhack",
            Content = state and "Wallhack Enabled" or "Wallhack Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Player:Paragraph({
    Title = "Player Components",
    Desc = "Everything related to players",
    Image = "component",
    ImageSize = 20,
    Color = "White"
})

TabHandles.Player:Divider()

local featureToggle = TabHandles.Player:Toggle({
    Title = "Freez",
    Value = false,
    Callback = function(state) 
        setXjxFrozen(state)

        WindUI:Notify({
            Title = "Freez",
            Content = state and "Freez Enabled" or "Freez Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

TabHandles.Player:Divider()

local featureToggle = TabHandles.Player:Toggle({
    Title = "NoClip",
    Value = false,
    Callback = function(state)
        toggleNoclip(state)

        WindUI:Notify({
            Title = "NoClip",
            Content = state and "NoClip Enabled" or "NoClip Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

Player.CharacterAdded:Connect(function(newCharacter)
    if noclipEnabled then
        toggleNoclip(true)
    end
end)

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Scripts:Paragraph({
    Title = "Another Scripts",
    Desc = "Here are other scripts",
    Image = "component",
    ImageSize = 20,
    Color = "White"
})

TabHandles.Scripts:Divider()

TabHandles.Scripts:Button({
    Title = "InfiniteYield",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()

        WindUI:Notify({
            Title = "InfiniteYield",
            Content = "InfiniteYield runed",
            Icon = "bell",
            Duration = 3
        })
    end
})

TabHandles.Scripts:Button({
    Title = "Dex",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()

        WindUI:Notify({
            Title = "Dex",
            Content = "Dex runed",
            Icon = "bell",
            Duration = 3
        })
    end
})

TabHandles.Scripts:Button({
    Title = "OldDex",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/IqokczHubMM2/refs/heads/main/Old%20dex.lua'))()

        WindUI:Notify({
            Title = "OldDex",
            Content = "OldDex runed",
            Icon = "bell",
            Duration = 3
        })
    end
})

TabHandles.Scripts:Button({
    Title = "AntiAfk",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/IqokczHubMM2/refs/heads/main/Anti%20afk.lua'))()

        WindUI:Notify({
            Title = "AntiAfk",
            Content = "AntiAfk runed",
            Icon = "bell",
            Duration = 3
        })
    end
})

TabHandles.Scripts:Button({
    Title = "Rejoin server",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/IqokczHubMM2/refs/heads/main/Rejoin%20Server.lua'))()
    
        WindUI:Notify({
            Title = "Rejoin server",
            Content = "Rejoined server",
            Icon = "bell",
            Duration = 3
        })
    end
})

TabHandles.Scripts:Button({
    Title = "Stats",
    Icon = "bell",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/iqoksz95-debug/Statsssss/refs/heads/main/stats.lua'))()

        WindUI:Notify({
            Title = "Stats Pc",
            Content = "Stats Pc runed",
            Icon = "bell",
            Duration = 3
        })
    end
})

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Info:Paragraph({
    Title = "Created with ",
    Desc = "t.me/bio_by_iqoksz95",
    Image = "Telegram",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "Copy Link",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("https://t.me/bio_by_iqoksz95")
                WindUI:Notify({
                    Title = "Copied!",
                    Content = "Telegram link copied to clipboard",
                    Duration = 2
                })
            end
        }
    }
})

--------------------------------------------------------------------------------------------------------------------------------

TabHandles.Appearance:Paragraph({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    Image = "palette",
    ImageSize = 20,
    Color = "White"
})

TabHandles.Appearance:Divider()

local themes = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

local themeDropdown = TabHandles.Appearance:Dropdown({
    Title = "Select Theme",
    Values = themes,
    Value = "Dark",
    Callback = function(theme)
        WindUI:SetTheme(theme)
        WindUI:Notify({
            Title = "Theme Applied",
            Content = theme,
            Icon = "palette",
            Duration = 2
        })
    end
})

local transparencySlider = TabHandles.Appearance:Slider({
    Title = "Window Transparency",
    Value = { Min = 0, Max = 1, Default = 0.2 },
    Step = 0.1,
    Callback = function(value)
        Window:ToggleTransparency(tonumber(value) > 0)
        WindUI.TransparencyValue = tonumber(value)
    end
})

local canchangetheme = true

local ThemeToggle = TabHandles.Appearance:Toggle({
    Title = "Enable Dark Mode",
    Desc = "Use dark color scheme",
    Value = true,
    Callback = function(state)
        if canchangetheme then
            WindUI:SetTheme(state and "Dark" or "Light")
        end
        themeDropdown:Select(state and "Dark" or "Light")
    end
})

WindUI:OnThemeChange(function(theme)
    canchangetheme = false
    ThemeToggle:Set(theme == "Dark")
    canchangetheme = true
end)

Window:OnDestroy(function()
    print("Window destroyed")
end)

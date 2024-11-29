local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil
local ClickInterval = 0.10
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil
local isScriptActive = false  -- Флаг, активен ли скрипт
local isMenuVisible = true  -- Флаг, показывается ли меню

-- Клавиша для скрытия/отображения меню (по умолчанию клавиша "M")
local toggleMenuKey = Enum.KeyCode.M

-- Функция для проверки видимости лобби
local function isLobbyVisible()
    return localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

-- Функция для нахождения ближайшего игрока к мыши
local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Функция для фиксации камеры на голове выбранного игрока
local function lockCameraToHead()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local head = targetPlayer.Character.Head
        local headPosition = camera:WorldToViewportPoint(head.Position)
        if headPosition.Z > 0 then
            local cameraPosition = camera.CFrame.Position
            local direction = (head.Position - cameraPosition).Unit
            camera.CFrame = CFrame.new(cameraPosition, head.Position)
        end
    end
end

-- Функция для автоматического клика
local function autoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if isLeftMouseDown or isRightMouseDown then
            if not isLobbyVisible() then
                mouse1click()
            end
        else
            autoClickConnection:Disconnect()
        end
    end)
end

-- Функция для активации/деактивации скрипта
local function toggleScript()
    isScriptActive = not isScriptActive  -- Переключение состояния скрипта
    if isScriptActive then
        print("Скрипт активирован")
    else
        print("Скрипт деактивирован")
    end
end

-- Создаем GUI с кнопкой для активации скрипта
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = localPlayer.PlayerGui
screenGui.Name = "AutoClickerGui"

-- Меню
local menuFrame = Instance.new("Frame")
menuFrame.Parent = screenGui
menuFrame.Size = UDim2.new(0, 300, 0, 150)
menuFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
menuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
menuFrame.Visible = isMenuVisible  -- Управляем видимостью меню

local toggleButton = Instance.new("TextButton")
toggleButton.Parent = menuFrame
toggleButton.Size = UDim2.new(0, 250, 0, 50)
toggleButton.Position = UDim2.new(0.5, -125, 0.3, -25)
toggleButton.Text = "Активировать скрипт"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Событие нажатия на кнопку
toggleButton.MouseButton1Click:Connect(function()
    toggleScript()  -- Переключение состояния скрипта
    if isScriptActive then
        toggleButton.Text = "Деактивировать скрипт"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    else
        toggleButton.Text = "Активировать скрипт"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Обработчик для горячей клавиши
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.KeyCode == toggleMenuKey then
        isMenuVisible = not isMenuVisible  -- Переключаем видимость меню
        menuFrame.Visible = isMenuVisible  -- Обновляем видимость меню
    end
end)

-- Обработка нажатий на мышь
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if not isScriptActive then return end  -- Если скрипт не активен, игнорировать ввод

    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            autoClick()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        if not isRightMouseDown then
            isRightMouseDown = true
            autoClick()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if not isScriptActive then return end  -- Если скрипт не активен, игнорировать ввод

    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not isProcessed then
        isRightMouseDown = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not isScriptActive then return end  -- Если скрипт не активен, не выполняем основную логику

    if not isLobbyVisible() then
        targetPlayer = getClosestPlayerToMouse()
        if targetPlayer then
            lockCameraToHead()
        end
    end
end)

--[[
    First Person Visual
    Compatible structure: R6 + R15
    Place this LocalScript in:
    StarterPlayer > StarterPlayerScripts

    Controls:
    - PC: Move the mouse to look around.
    - Mobile: Drag on the right half of the screen to look around.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- SETTINGS
local CAMERA_OFFSET = Vector3.new(0, 0.95, 0)
local SENSITIVITY = 1.5
local MIN_PITCH = math.rad(-85)
local MAX_PITCH = math.rad(85)

local ACCESSORY_TRANSPARENCY = 1
local BODY_TRANSPARENCY = 0

local RENDER_STEP_NAME = "FirstPersonVisual"

-- STATE
local character
local humanoid
local head
local rootPart

local cameraRotation = Vector2.zero
local activeTouch = nil
local characterConnections = {}

local function FirstPersonVisual_SetObjectVisibility(object)
    if object:IsA("BasePart") then
        if object.Name == "Head" then
            object.LocalTransparencyModifier = 0
            object.CastShadow = true
        elseif object.Name == "HumanoidRootPart" then
            object.LocalTransparencyModifier = 1
        elseif object:FindFirstAncestorOfClass("Accessory") then
            object.LocalTransparencyModifier = ACCESSORY_TRANSPARENCY
            object.CastShadow = true
        else
            object.LocalTransparencyModifier = BODY_TRANSPARENCY
        end
    elseif object:IsA("Decal") and object.Parent == head then
        object.Transparency = 1
    end
end

local function FirstPersonVisual_SetCharacterVisibility(char)
    for _, object in ipairs(char:GetDescendants()) do
        FirstPersonVisual_SetObjectVisibility(object)
    end
end

local function FirstPersonVisual_ApplyLookDelta(deltaX, deltaY)
    cameraRotation = Vector2.new(
        math.clamp(
            cameraRotation.X - deltaY * SENSITIVITY,
            MIN_PITCH,
            MAX_PITCH
        ),
        cameraRotation.Y - deltaX * SENSITIVITY
    )
end

local function FirstPersonVisual_UpdateCamera()
    if not character or not character.Parent
        or not head or not head.Parent
        or not rootPart or not rootPart.Parent
        or not humanoid or humanoid.Health <= 0 then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local cameraCFrame =
        CFrame.new(head.Position)
        * CFrame.Angles(0, cameraRotation.Y, 0)
        * CFrame.Angles(cameraRotation.X, 0, 0)
        * CFrame.new(CAMERA_OFFSET)

    camera.CFrame = cameraCFrame
    camera.Focus = cameraCFrame * CFrame.new(0, 0, -12)

    rootPart.CFrame =
        CFrame.new(rootPart.Position)
        * CFrame.Angles(0, cameraRotation.Y, 0)
end

local function FirstPersonVisual_HandleInputChanged(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        FirstPersonVisual_ApplyLookDelta(input.Delta.X, input.Delta.Y)
    end
end

local function FirstPersonVisual_AddConnection(connection)
    table.insert(characterConnections, connection)
end

local function FirstPersonVisual_Cleanup()
    RunService:UnbindFromRenderStep(RENDER_STEP_NAME)

    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end

    table.clear(characterConnections)
    activeTouch = nil
end

local function FirstPersonVisual_ShowStartupNotice()
    local playerGui = player:WaitForChild("PlayerGui")

    local oldGui = playerGui:FindFirstChild("FirstPersonVisual_StartupGui")
    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FirstPersonVisual_StartupGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 20
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Notice"
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.Position = UDim2.new(0, 14, 1, -14)
    frame.Size = UDim2.fromOffset(285, 42)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.ZIndex = 20
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(145, 105, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = frame

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Position = UDim2.fromOffset(0, 0)
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = Color3.fromRGB(145, 105, 255)
    accent.BorderSizePixel = 0
    accent.ZIndex = 21
    accent.Parent = frame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 8)
    accentCorner.Parent = accent

    local label = Instance.new("TextLabel")
    label.Name = "Message"
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -22, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = "First Person Visual script are work"
    label.TextColor3 = Color3.fromRGB(245, 245, 250)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 22
    label.Parent = frame

    task.delay(3.5, function()
        if not screenGui.Parent then
            return
        end

        local fadeInfo = TweenInfo.new(
            0.45,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )

        TweenService:Create(frame, fadeInfo, {
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(stroke, fadeInfo, {
            Transparency = 1
        }):Play()

        TweenService:Create(accent, fadeInfo, {
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(label, fadeInfo, {
            TextTransparency = 1
        }):Play()

        task.delay(0.5, function()
            if screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end)
end

local function FirstPersonVisual_SetupCharacter(newCharacter)
    FirstPersonVisual_Cleanup()

    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    head = character:WaitForChild("Head")
    rootPart = character:WaitForChild("HumanoidRootPart")

    cameraRotation = Vector2.zero
    humanoid.AutoRotate = false

    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
    end

    if UserInputService.TouchEnabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    FirstPersonVisual_SetCharacterVisibility(character)

    FirstPersonVisual_AddConnection(
        character.DescendantAdded:Connect(function(object)
            task.defer(function()
                if character and character.Parent and object.Parent then
                    FirstPersonVisual_SetObjectVisibility(object)
                end
            end)
        end)
    )

    FirstPersonVisual_AddConnection(
        UserInputService.InputChanged:Connect(
            FirstPersonVisual_HandleInputChanged
        )
    )

    -- Mobile camera: drag from the right half of the screen.
    -- Touches consumed by Roblox UI (for example, jump) are ignored.
    FirstPersonVisual_AddConnection(
        UserInputService.TouchStarted:Connect(function(input, gameProcessed)
            if gameProcessed or activeTouch then
                return
            end

            local currentCamera = workspace.CurrentCamera
            if not currentCamera then
                return
            end

            if input.Position.X >= currentCamera.ViewportSize.X * 0.45 then
                activeTouch = input
            end
        end)
    )

    FirstPersonVisual_AddConnection(
        UserInputService.TouchMoved:Connect(function(input)
            if input == activeTouch then
                FirstPersonVisual_ApplyLookDelta(
                    input.Delta.X,
                    input.Delta.Y
                )
            end
        end)
    )

    FirstPersonVisual_AddConnection(
        UserInputService.TouchEnded:Connect(function(input)
            if input == activeTouch then
                activeTouch = nil
            end
        end)
    )

    RunService:BindToRenderStep(
        RENDER_STEP_NAME,
        Enum.RenderPriority.Camera.Value,
        FirstPersonVisual_UpdateCamera
    )
end

FirstPersonVisual_ShowStartupNotice()

player.CharacterAdded:Connect(FirstPersonVisual_SetupCharacter)

if player.Character then
    FirstPersonVisual_SetupCharacter(player.Character)
end

--[[
    Realistic First Person Character Camera
    R6 + R15
    LocalScript
    StarterPlayer > StarterPlayerScripts

    Camera follows the animated Head position.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- SETTINGS
local CAMERA_OFFSET = Vector3.new(0, 0.95, 0)
local SENSITIVITY = 0.003
local MIN_PITCH = math.rad(-85)
local MAX_PITCH = math.rad(85)

local ACCESSORY_TRANSPARENCY = 1
local BODY_TRANSPARENCY = 0

local RENDER_STEP_NAME = "RealisticFirstPersonCamera"

-- STATE
local character
local humanoid
local head
local rootPart
local cameraRotation = Vector2.zero
local inputConnection
local characterDescendantConnection

local function setCharacterTransparency(char)
	for _, object in ipairs(char:GetDescendants()) do
		if object:IsA("BasePart") then
			if object.Name == "Head" then
				object.LocalTransparencyModifier = 0
				object.CastShadow = true
			elseif object:FindFirstAncestorOfClass("Accessory") then
				object.LocalTransparencyModifier = ACCESSORY_TRANSPARENCY
				object.CastShadow = true
			elseif object.Name == "HumanoidRootPart" then
				object.LocalTransparencyModifier = 1
			else
				object.LocalTransparencyModifier = BODY_TRANSPARENCY
			end
		elseif object:IsA("Decal") and object.Parent == char:FindFirstChild("Head") then
			object.Transparency = 1
		end
	end
end

local function updateCamera()
	if not character or not character.Parent
		or not head or not head.Parent
		or not rootPart or not rootPart.Parent
		or not humanoid or humanoid.Health <= 0 then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then return end

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

local function onInputChanged(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta

		cameraRotation = Vector2.new(
			math.clamp(
				cameraRotation.X - delta.Y * SENSITIVITY,
				MIN_PITCH,
				MAX_PITCH
			),
			cameraRotation.Y - delta.X * SENSITIVITY
		)
	end
end

local function cleanup()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	if characterDescendantConnection then
		characterDescendantConnection:Disconnect()
		characterDescendantConnection = nil
	end
end

local function setupCharacter(newCharacter)
	cleanup()

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

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	setCharacterTransparency(character)

	characterDescendantConnection = character.DescendantAdded:Connect(function(object)
		task.defer(function()
			if not character or not character.Parent or not object.Parent then
				return
			end

			if object:IsA("BasePart") then
				if object.Name == "Head" then
					object.LocalTransparencyModifier = 0
					object.CastShadow = true
				elseif object:FindFirstAncestorOfClass("Accessory") then
					object.LocalTransparencyModifier = ACCESSORY_TRANSPARENCY
					object.CastShadow = true
				elseif object.Name == "HumanoidRootPart" then
					object.LocalTransparencyModifier = 1
				else
					object.LocalTransparencyModifier = BODY_TRANSPARENCY
				end
			elseif object:IsA("Decal") and object.Parent == head then
				object.Transparency = 1
			end
		end)
	end)

	inputConnection = UserInputService.InputChanged:Connect(onInputChanged)

	RunService:BindToRenderStep(
		RENDER_STEP_NAME,
		Enum.RenderPriority.Camera.Value,
		updateCamera
	)
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
	setupCharacter(player.Character)
end

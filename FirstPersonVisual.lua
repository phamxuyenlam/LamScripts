--[[
    First Person Body v2
    R6 + R15
    LocalScript
    StarterPlayer > StarterPlayerScripts

    Features:
    - Không ép First Person
    - Body hiện khi camera ở First Person
    - Hỗ trợ R6 / R15
    - Tool / Item vẫn hiển thị
    - Tool animation vẫn hoạt động
    - Particle / Trail / Beam / Effects vẫn hoạt động
    - Head được ẩn để tránh camera nằm trong đầu
    - Head accessories có thể ẩn
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

-- Không khóa camera First Person
local FORCE_FIRST_PERSON = false

-- Ẩn đầu khi First Person
local HIDE_HEAD = true

-- Ẩn accessory nằm trên đầu khi First Person
local HIDE_HEAD_ACCESSORIES = true

-- Khoảng cách nhận biết First Person
local FIRST_PERSON_DISTANCE = 1

--==================================================
-- VARIABLES
--==================================================

local Character
local Humanoid
local Head

--==================================================
-- FIRST PERSON CHECK
--==================================================

local function IsFirstPerson()
	if not Character or not Head then
		return false
	end

	local Camera = workspace.CurrentCamera

	if not Camera then
		return false
	end

	-- Không ép First Person
	if not FORCE_FIRST_PERSON then
		local distance = (Camera.CFrame.Position - Head.Position).Magnitude

		return distance <= FIRST_PERSON_DISTANCE
	end

	return true
end

--==================================================
-- CHECK HEAD ACCESSORY
--==================================================

local function IsHeadAccessory(object)
	if not HIDE_HEAD_ACCESSORIES then
		return false
	end

	if not object:IsA("Accessory") then
		return false
	end

	local handle = object:FindFirstChild("Handle")

	if not handle then
		return false
	end

	-- Accessory attachment names thường gặp trên đầu
	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("Attachment") then
			local name = child.Name:lower()

			if name:find("hat") then
				return true
			end

			if name:find("hair") then
				return true
			end

			if name:find("face") then
				return true
			end

			if name:find("head") then
				return true
			end
		end
	end

	-- Một số accessory không có attachment rõ ràng
	-- Dựa vào parent của Accessory
	return false
end

--==================================================
-- SET BODY
--==================================================

local function UpdateBody()
	if not Character or not Character.Parent then
		return
	end

	if not Humanoid or Humanoid.Health <= 0 then
		return
	end

	local FirstPerson = IsFirstPerson()

	for _, object in ipairs(Character:GetDescendants()) do

		--==============================================
		-- BODY PARTS / MESH PARTS / TOOL HANDLE
		--==============================================

		if object:IsA("BasePart") then

			-- RootPart không bao giờ cần nhìn thấy
			if object.Name == "HumanoidRootPart" then

				object.LocalTransparencyModifier = 1

			-- Head
			elseif object == Head then

				if FirstPerson and HIDE_HEAD then
					object.LocalTransparencyModifier = 1
				else
					object.LocalTransparencyModifier = 0
				end

			else
				--========================================
				-- FIRST PERSON
				--========================================

				if FirstPerson then

					-- Body
					object.LocalTransparencyModifier = 0

					-- Tool Handle
					if object.Parent and object.Parent:IsA("Tool") then
						object.LocalTransparencyModifier = 0
					end

					-- Accessory
					local accessory = object:FindFirstAncestorOfClass("Accessory")

					if accessory then

						if IsHeadAccessory(accessory) then
							object.LocalTransparencyModifier = 1
						else
							object.LocalTransparencyModifier = 0
						end
					end

				--========================================
				-- THIRD PERSON
				--========================================

				else
					-- Trả về trạng thái bình thường
					object.LocalTransparencyModifier = 0
				end
			end
		end
	end
end

--==================================================
-- CHARACTER SETUP
--==================================================

local function SetupCharacter(newCharacter)

	Character = newCharacter

	Humanoid = Character:WaitForChild("Humanoid")
	Head = Character:WaitForChild("Head")

	-- Không ép First Person
	Player.CameraMode = Enum.CameraMode.Classic

	UpdateBody()
end

--==================================================
-- CHARACTER
--==================================================

if Player.Character then
	SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(newCharacter)
	SetupCharacter(newCharacter)
end)

--==================================================
-- TOOL / ITEM MONITOR
--==================================================

CharacterAdded = Player.CharacterAdded

Player.Backpack.ChildAdded:Connect(function(tool)

	if not tool:IsA("Tool") then
		return
	end

	-- Khi Tool được equip, nó sẽ được parent vào Character.
	-- Render update sẽ tự xử lý Handle.
	tool.AncestryChanged:Connect(function()
		if Character then
			task.defer(UpdateBody)
		end
	end)
end)

--==================================================
-- RENDER UPDATE
--==================================================

RunService:BindToRenderStep(
	"FirstPersonBody",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not Character then
			return
		end

		if not Character.Parent then
			return
		end

		if not Head then
			return
		end

		UpdateBody()
	end
)
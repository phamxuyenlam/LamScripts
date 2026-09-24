-- Standalone Roblox Studio diagnostic.
-- Tests ShiftLock asset 94251318161622 via ImageLabel and Decal.
-- Does not modify ReSave or execute external scripts.

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("ShiftLockAssetPipelineTest")
if old then old:Destroy() end

local URI = "rbxassetid://94251318161622"

local gui = Instance.new("ScreenGui")
gui.Name = "ShiftLockAssetPipelineTest"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromOffset(720, 500)
root.Position = UDim2.new(.5, -360, .5, -250)
root.BackgroundColor3 = Color3.fromRGB(24,22,30)
root.BorderSizePixel = 0
root.Parent = gui

Instance.new("UICorner", root).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-60,0,42)
title.Position = UDim2.fromOffset(12,4)
title.BackgroundTransparency = 1
title.Text = "ShiftLock Asset Pipeline Test"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36,36)
close.Position = UDim2.new(1,-44,0,4)
close.BackgroundTransparency = 1
close.Text = "-"
close.TextColor3 = Color3.new(1,1,1)
close.TextSize = 24
close.ZIndex = 20
close.Parent = root
close.Activated:Connect(function() gui:Destroy() end)

local function makePanel(x, label)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(335,190)
	f.Position = UDim2.fromOffset(x,55)
	f.BackgroundColor3 = Color3.fromRGB(15,14,20)
	f.BorderSizePixel = 0
	f.Parent = root
	Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,0,25)
	l.BackgroundTransparency = 1
	l.Text = label
	l.TextColor3 = Color3.new(1,1,1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 13
	l.Parent = f
	return f
end

local imagePanel = makePanel(12, "ImageLabel")
local decalPanel = makePanel(373, "Decal.ColorMapContent")

local image = Instance.new("ImageLabel")
image.Name = "ShiftLockImage"
image.Size = UDim2.new(1,-12,1,-37)
image.Position = UDim2.fromOffset(6,31)
image.BackgroundTransparency = 1
image.ScaleType = Enum.ScaleType.Fit
image.Image = URI
image.Parent = imagePanel

-- Decal is tested on a Part inside a ViewportFrame so both results are visible.
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1,-12,1,-37)
viewport.Position = UDim2.fromOffset(6,31)
viewport.BackgroundTransparency = 1
viewport.Parent = decalPanel

local world = Instance.new("WorldModel")
world.Parent = viewport

local part = Instance.new("Part")
part.Size = Vector3.new(8,4.33,.2)
part.Anchored = true
part.Parent = world

local decal = Instance.new("Decal")
decal.Face = Enum.NormalId.Front
decal.ColorMapContent = Content.fromUri(URI)
decal.Parent = part

local camera = Instance.new("Camera")
camera.CFrame = CFrame.new(0,0,9)
camera.Parent = viewport
viewport.CurrentCamera = camera

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-24,0,190)
status.Position = UDim2.fromOffset(12,260)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.Code
status.TextSize = 14
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = root

local function report(prefix)
	local s = string.format(
		"%s\nImageLabel.Image = %s\nImageLabel.IsLoaded = %s\nDecal.ColorMapContent = %s\n\nIf ImageLabel=false and Decal also blank -> asset/content access is the likely issue.\nIf Decal displays -> ImageLabel pipeline is the thing to investigate.",
		prefix, image.Image, tostring(image.IsLoaded), tostring(decal.ColorMapContent)
	)
	status.Text = s
	print("[ShiftLock Pipeline Test] "..s:gsub("\n"," | "))
end

image:GetPropertyChangedSignal("IsLoaded"):Connect(function()
	report("ImageLabel IsLoaded changed")
end)

task.spawn(function()
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync({image, decal})
	end)
	report(ok and "PreloadAsync finished" or ("PreloadAsync ERROR: "..tostring(err)))
end)

report("Initial state")
print("[ShiftLock Pipeline Test] Target:", URI)
print("[ShiftLock Pipeline Test] Started. Compare the two panels.")

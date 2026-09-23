-- ReSave Script Hub Preview Diagnostic
-- Standalone Studio test: does NOT modify the ReSave source.
-- Purpose: isolate ShiftLock preview loading/layout from the rest of ReSave.

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHIFTLOCK_ASSET = "rbxassetid://94251318161622"

-- Remove only our previous diagnostic UI.
local old = playerGui:FindFirstChild("ReSavePreviewDiagnostic")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ReSavePreviewDiagnostic"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "ScriptHubTest"
window.Size = UDim2.fromOffset(620, 430)
window.Position = UDim2.new(0.5, -310, 0.5, -215)
window.BackgroundColor3 = Color3.fromRGB(25, 22, 33)
window.BorderSizePixel = 0
window.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 42)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "Script Hub — Preview Diagnostic"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = window

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -42, 0, 3)
close.BackgroundTransparency = 1
close.Text = "-"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 24
close.Font = Enum.Font.GothamBold
close.ZIndex = 20
close.Parent = window

close.Activated:Connect(function()
	gui:Destroy()
end)

local list = Instance.new("Frame")
list.Size = UDim2.new(0, 190, 1, -60)
list.Position = UDim2.fromOffset(12, 52)
list.BackgroundColor3 = Color3.fromRGB(31, 28, 40)
list.BorderSizePixel = 0
list.Parent = window

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 10)
listCorner.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 8)
listPad.PaddingLeft = UDim.new(0, 8)
listPad.PaddingRight = UDim.new(0, 8)
listPad.Parent = list

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -222, 1, -60)
content.Position = UDim2.fromOffset(210, 52)
content.BackgroundColor3 = Color3.fromRGB(31, 28, 40)
content.BorderSizePixel = 0
content.Parent = window

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = content

local previewHolder = Instance.new("Frame")
previewHolder.Name = "PreviewHolder"
previewHolder.Size = UDim2.new(1, -20, 0, 180)
previewHolder.Position = UDim2.fromOffset(10, 10)
previewHolder.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
previewHolder.BorderSizePixel = 0
previewHolder.ClipsDescendants = true
previewHolder.Parent = content

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = previewHolder

-- This is the actual ImageLabel being tested.
local preview = Instance.new("ImageLabel")
preview.Name = "ShiftLockPreview"
preview.Size = UDim2.new(1, -10, 1, -10)
preview.Position = UDim2.fromOffset(5, 5)
preview.BackgroundTransparency = 1
preview.BorderSizePixel = 0
preview.ScaleType = Enum.ScaleType.Fit
preview.Image = SHIFTLOCK_ASSET
preview.Parent = previewHolder

-- Keep the source image's 512:277 aspect ratio.
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 512 / 277
aspect.DominantAxis = Enum.DominantAxis.Width
aspect.Parent = preview

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 120)
status.Position = UDim2.fromOffset(10, 202)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 14
status.Font = Enum.Font.Code
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "Loading ShiftLock asset..."
status.Parent = content

local function report(prefix)
	local text = string.format(
		"%s\nImage: %s\nIsLoaded: %s\nAbsoluteSize: %.0fx%.0f\nScaleType: %s",
		prefix,
		preview.Image,
		tostring(preview.IsLoaded),
		preview.AbsoluteSize.X,
		preview.AbsoluteSize.Y,
		preview.ScaleType.Name
	)

	print("[ReSave Preview Test] " .. text:gsub("\n", " | "))
	status.Text = text
end

-- Immediate state.
report("Initial state")

-- Observe the actual ImageLabel state.
preview:GetPropertyChangedSignal("IsLoaded"):Connect(function()
	report("IsLoaded changed")
end)

preview:GetPropertyChangedSignal("Image"):Connect(function()
	report("Image changed")
end)

-- Preload the exact rbxassetid, without rbxthumb and without HTTP.
task.spawn(function()
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync({preview})
	end)

	if ok then
		report("PreloadAsync finished")
	else
		report("PreloadAsync ERROR: " .. tostring(err))
	end
end)

-- Simulate selecting different Script Hub entries.
local scripts = {
	"DEX",
	"RemoteSpy",
	"Unnamed ESP",
	"Script Dumper",
	"ShiftLock",
}

for index, scriptName in ipairs(scripts) do
	local button = Instance.new("TextButton")
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(43, 38, 54)
	button.BorderSizePixel = 0
	button.Text = scriptName
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 14
	button.Font = Enum.Font.Gotham
	button.Parent = list

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 7)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		if scriptName == "ShiftLock" then
			-- Deliberately ONLY rbxassetid.
			preview.Image = SHIFTLOCK_ASSET
			preview.ScaleType = Enum.ScaleType.Fit

			-- Re-test loading after selection.
			task.spawn(function()
				local ok, err = pcall(function()
					ContentProvider:PreloadAsync({preview})
				end)

				if ok then
					report("ShiftLock selected + preload finished")
				else
					report("ShiftLock selected + preload ERROR: " .. tostring(err))
				end
			end)
		else
			-- These are placeholders; this diagnostic does not execute external scripts.
			preview.Image = ""
			status.Text = scriptName .. " selected.\nPreview intentionally disabled for this diagnostic."
			print("[ReSave Preview Test] " .. scriptName .. " selected")
		end
	end)
end

print("==============================================")
print("[ReSave Preview Test] Diagnostic started")
print("[ReSave Preview Test] Target:", SHIFTLOCK_ASSET)
print("[ReSave Preview Test] Source ratio:", 512 / 277)
print("[ReSave Preview Test] Click ShiftLock in the left list.")
print("==============================================")

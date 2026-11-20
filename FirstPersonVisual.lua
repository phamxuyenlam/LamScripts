--[[
    First Person Body v4
    R6 + R15
    LocalScript
    StarterPlayer > StarterPlayerScripts

    Fixes:
    - Re-apply LocalTransparencyModifier every frame in first person.
    - Do not cache visibility while Roblox camera transparency controller may overwrite it.
    - Detect first person using the neutral head position (not animated Head.Position).
    - Apply animated head translation after the default camera update.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- SETTINGS
local FORCE_FIRST_PERSON = false
local HIDE_HEAD = true
local HIDE_HEAD_ACCESSORIES = true
local FIRST_PERSON_DISTANCE = 1.5

-- Follow head translation from animation, but preserve player's look direction.
local FOLLOW_ANIMATED_HEAD_POSITION = true
local MAX_ANIMATION_OFFSET = 0.75

local RENDER_BIND_NAME = "FirstPersonBody_v4"

local Character
local Humanoid
local Head
local Neck
local LastFirstPerson = false

local function FindNeck()
    Neck = nil
    if not Character or not Head then return end

    for _, object in ipairs(Character:GetDescendants()) do
        if object:IsA("Motor6D") and object.Name == "Neck" then
            if object.Part0 and object.Part1 and
                (object.Part0 == Head or object.Part1 == Head) then
                Neck = object
                return
            end
        end
    end
end

-- Calculates where the head would be without the Neck's animation Transform.
local function GetNeutralHeadCFrame()
    if not Neck or not Neck.Parent or not Head then return nil end

    local part0 = Neck.Part0
    local part1 = Neck.Part1
    if not part0 or not part1 then return nil end

    if part1 == Head then
        return part0.CFrame * Neck.C0 * Neck.C1:Inverse()
    elseif part0 == Head then
        return part1.CFrame * Neck.C1 * Neck.C0:Inverse()
    end

    return nil
end

local function IsFirstPerson()
    if FORCE_FIRST_PERSON then return true end

    local camera = workspace.CurrentCamera
    if not camera or not Head then return false end

    local neutral = GetNeutralHeadCFrame()
    local referencePosition = neutral and neutral.Position or Head.Position

    return (camera.CFrame.Position - referencePosition).Magnitude <= FIRST_PERSON_DISTANCE
end

local function IsHeadAccessory(accessory)
    if not HIDE_HEAD_ACCESSORIES or not accessory:IsA("Accessory") then
        return false
    end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return false end

    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") then
            local name = child.Name:lower()
            if name:find("hat") or name:find("hair")
                or name:find("face") or name:find("head") then
                return true
            end
        end
    end

    return false
end

local function SetPartVisibility(firstPerson)
    if not Character or not Character.Parent or not Humanoid
        or Humanoid.Health <= 0 then
        return
    end

    -- Run every render frame in first person because Roblox's camera
    -- transparency controller can also modify LocalTransparencyModifier.
    for _, object in ipairs(Character:GetDescendants()) do
        if object:IsA("BasePart") then
            if object.Name == "HumanoidRootPart" then
                object.LocalTransparencyModifier = 1

            elseif firstPerson then
                if object == Head then
                    object.LocalTransparencyModifier = HIDE_HEAD and 1 or 0
                else
                    local accessory = object:FindFirstAncestorOfClass("Accessory")
                    if accessory and IsHeadAccessory(accessory) then
                        object.LocalTransparencyModifier = 1
                    else
                        -- Body parts, layered clothing parts and equipped tool handles.
                        object.LocalTransparencyModifier = 0
                    end
                end

            elseif LastFirstPerson then
                -- Reset when leaving first person; outside FP let Roblox
                -- handle its normal transparency and occlusion behavior.
                object.LocalTransparencyModifier = 0
            end
        end
    end
end

local function ApplyAnimatedHeadOffset()
    if not FOLLOW_ANIMATED_HEAD_POSITION then return end

    local camera = workspace.CurrentCamera
    if not camera or not Head or not Neck then return end
    if camera.CameraType == Enum.CameraType.Scriptable then return end

    local neutral = GetNeutralHeadCFrame()
    if not neutral then return end

    local offset = Head.Position - neutral.Position
    if offset.Magnitude > MAX_ANIMATION_OFFSET then return end

    -- Apply once to the freshly calculated camera frame after the default camera.
    local adjustment = CFrame.new(offset)
    camera.CFrame = adjustment * camera.CFrame
    camera.Focus = adjustment * camera.Focus
end

local function UpdateRender()
    if not Character or not Character.Parent or not Head then return end

    local firstPerson = IsFirstPerson()
    SetPartVisibility(firstPerson)

    if firstPerson then
        ApplyAnimatedHeadOffset()
    end

    LastFirstPerson = firstPerson
end

local function SetupCharacter(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    Head = Character:WaitForChild("Head")
    Neck = nil
    LastFirstPerson = false

    Player.CameraMode = Enum.CameraMode.Classic
    FindNeck()

    Character.DescendantAdded:Connect(function(object)
        if object:IsA("Motor6D") and (object.Name == "Neck" or not Neck) then
            task.defer(FindNeck)
        end
    end)
end

if Player.Character then
    SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(SetupCharacter)

RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
RunService:BindToRenderStep(
    RENDER_BIND_NAME,
    Enum.RenderPriority.Last.Value,
    UpdateRender
)

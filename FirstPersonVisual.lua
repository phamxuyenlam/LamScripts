--[[
    First Person Body v3 - Animated Head Camera Fix
    R6 + R15 (Motor6D + AnimationConstraint)
    LocalScript
    StarterPlayer > StarterPlayerScripts

    Features:
    - Không ép First Person
    - Body hiện khi camera ở First Person
    - Hỗ trợ R6 / R15
    - Hỗ trợ Motor6D và AnimationConstraint (Avatar Joint Upgrade)
    - Camera bám theo chuyển động animation của khớp cổ
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

-- true: camera bám cả vị trí và góc xoay của animation cổ.
-- false: chỉ bám vị trí, giữ nguyên hướng ngắm của người chơi (khuyến nghị).
local FOLLOW_HEAD_ROTATION = false

-- Giới hạn độ lệch để tránh camera bị kéo quá xa nếu rig/joint có dữ liệu bất thường.
local MAX_ANIMATION_OFFSET = 1.5

--==================================================
-- VARIABLES
--==================================================

local Character
local Humanoid
local Head
local NeckJoint
local LastFirstPersonState = nil
local GetNeutralHeadCFrame

local RENDER_BIND_NAME = "FirstPersonVisual_AnimatedCamera"

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

    if not FORCE_FIRST_PERSON then
        -- Dùng vị trí đầu ở trạng thái neutral để animation cổ không làm
        -- khoảng cách vượt ngưỡng trong chốc lát rồi vô tình hiện lại Head.
        local referencePosition = Head.Position
        if GetNeutralHeadCFrame then
            local neutralHeadCFrame = GetNeutralHeadCFrame()
            if neutralHeadCFrame then
                referencePosition = neutralHeadCFrame.Position
            end
        end

        local distance = (Camera.CFrame.Position - referencePosition).Magnitude
        return distance <= FIRST_PERSON_DISTANCE
    end

    return true
end

--==================================================
-- FIND NECK JOINT
--==================================================

local function IsSupportedJoint(object)
    return object:IsA("Motor6D") or object:IsA("AnimationConstraint")
end

local function FindNeckJoint()
    NeckJoint = nil

    if not Character or not Head then
        return
    end

    local fallbackJoint = nil

    for _, object in ipairs(Character:GetDescendants()) do
        if IsSupportedJoint(object) then
            local part0 = object.Part0
            local part1 = object.Part1

            if part0 == Head or part1 == Head then
                if object.Name == "Neck" then
                    NeckJoint = object
                    return
                end

                fallbackJoint = fallbackJoint or object
            end
        end
    end

    NeckJoint = fallbackJoint
end

--==================================================
-- GET NEUTRAL HEAD CFRAME
--==================================================

-- Tính vị trí đầu nếu khớp cổ không có animation Transform.
-- So sánh nó với Head.CFrame thực tế sẽ cho biết animation đã
-- dịch chuyển đầu bao nhiêu trong frame hiện tại.
GetNeutralHeadCFrame = function()
    local joint = NeckJoint
    if not joint or not joint.Parent or not Head then
        return nil
    end

    local part0 = joint.Part0
    local part1 = joint.Part1
    if not part0 or not part1 then
        return nil
    end

    local c0
    local c1

    -- C0/C1 có trên cả Motor6D và AnimationConstraint.
    local success = pcall(function()
        c0 = joint.C0
        c1 = joint.C1
    end)

    if not success or not c0 or not c1 then
        return nil
    end

    if part1 == Head then
        return part0.CFrame * c0 * c1:Inverse()
    elseif part0 == Head then
        return part1.CFrame * c1 * c0:Inverse()
    end

    return nil
end

--==================================================
-- ANIMATED CAMERA FOLLOW
--==================================================

local function UpdateAnimatedCamera()
    local Camera = workspace.CurrentCamera
    if not Camera or not Head or not NeckJoint then
        return
    end

    if not IsFirstPerson() then
        return
    end

    -- Không can thiệp vào camera do một hệ thống khác điều khiển.
    if Camera.CameraType == Enum.CameraType.Scriptable then
        return
    end

    local neutralHeadCFrame = GetNeutralHeadCFrame()
    if not neutralHeadCFrame then
        return
    end

    local animatedHeadCFrame = Head.CFrame
    local animationOffset = animatedHeadCFrame.Position - neutralHeadCFrame.Position

    -- Bảo vệ camera trước những rig có joint offset bất thường.
    if animationOffset.Magnitude > MAX_ANIMATION_OFFSET then
        return
    end

    local cameraAdjustment

    if FOLLOW_HEAD_ROTATION then
        -- Dùng toàn bộ biến đổi của đầu: cả vị trí lẫn góc xoay.
        cameraAdjustment = animatedHeadCFrame * neutralHeadCFrame:Inverse()
    else
        -- Chỉ dịch chuyển camera theo animation, không làm lệch hướng ngắm.
        cameraAdjustment = CFrame.new(animationOffset)
    end

    -- Dịch cả CFrame và Focus để camera không bị đổi hướng ngoài ý muốn.
    Camera.CFrame = cameraAdjustment * Camera.CFrame
    Camera.Focus = cameraAdjustment * Camera.Focus
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

    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Attachment") then
            local name = child.Name:lower()

            if name:find("hat")
                or name:find("hair")
                or name:find("face")
                or name:find("head") then
                return true
            end
        end
    end

    return false
end

--==================================================
-- SET BODY
--==================================================

local function UpdateBody(forceUpdate)
    if not Character or not Character.Parent then
        return
    end

    if not Humanoid or Humanoid.Health <= 0 then
        return
    end

    local firstPerson = IsFirstPerson()

    -- Chỉ quét toàn bộ nhân vật khi trạng thái First Person thay đổi,
    -- trừ khi có part/accessory/tool mới được thêm vào.
    if not forceUpdate and firstPerson == LastFirstPersonState then
        return
    end

    LastFirstPersonState = firstPerson

    for _, object in ipairs(Character:GetDescendants()) do
        if object:IsA("BasePart") then
            if object.Name == "HumanoidRootPart" then
                object.LocalTransparencyModifier = 1

            elseif object == Head then
                object.LocalTransparencyModifier = (firstPerson and HIDE_HEAD) and 1 or 0

            elseif firstPerson then
                object.LocalTransparencyModifier = 0

                local accessory = object:FindFirstAncestorOfClass("Accessory")
                if accessory and IsHeadAccessory(accessory) then
                    object.LocalTransparencyModifier = 1
                end
            else
                object.LocalTransparencyModifier = 0
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
    NeckJoint = nil
    LastFirstPersonState = nil

    -- Không ép người chơi vào First Person.
    Player.CameraMode = Enum.CameraMode.Classic

    FindNeckJoint()
    UpdateBody(true)

    -- Đề phòng rig/joint/accessory được thêm sau khi Character xuất hiện.
    Character.DescendantAdded:Connect(function()
        task.defer(function()
            if Character ~= newCharacter then
                return
            end

            if not NeckJoint or not NeckJoint.Parent then
                FindNeckJoint()
            end

            UpdateBody(true)
        end)
    end)
end

--==================================================
-- CHARACTER EVENTS
--==================================================

if Player.Character then
    SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(SetupCharacter)

--==================================================
-- TOOL / ITEM MONITOR
--==================================================

local Backpack = Player:WaitForChild("Backpack")

Backpack.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then
        return
    end

    tool.AncestryChanged:Connect(function()
        task.defer(function()
            UpdateBody(true)
        end)
    end)
end)

--==================================================
-- RENDER UPDATE
--==================================================

-- Camera mặc định chạy ở priority 200.
-- Dùng Last để lấy pose đầu sau khi animation/character đã cập nhật,
-- rồi mới áp phần dịch chuyển animation lên camera trong frame hiện tại.
RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
RunService:BindToRenderStep(
    RENDER_BIND_NAME,
    Enum.RenderPriority.Last.Value,
    function()
        if not Character or not Character.Parent or not Head then
            return
        end

        UpdateBody(false)
        UpdateAnimatedCamera()
    end
)

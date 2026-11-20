-- Avatar Copy Script with Custom Dark-Purple UI by Lam
-- Free/Open Source code at Github/XuyenLam/LamScripts
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local lastUsername = nil
local savedUsernames = {}
local SAVE_FILE_NAME = "LamAvatarCopy_Saved.json"
-- ==========================================
-- HÀM HỖ TRỢ LƯU & TẢI DỮ LIỆU TỪ FILE (NẾU EXECUTOR HỖ TRỢ)
-- ==========================================
local function saveToFile()
    if writefile then
        pcall(function()
            writefile(SAVE_FILE_NAME, HttpService:JSONEncode(savedUsernames))
        end)
    end
end
local function loadFromFile()
    if isfile and readfile and isfile(SAVE_FILE_NAME) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SAVE_FILE_NAME))
        end)
        if ok and type(data) == "table" then
            savedUsernames = data
            return
        end
    end
    -- Nếu chưa có file lưu, thêm sẵn 1 tên mẫu
    table.insert(savedUsernames, "Roblox")
end
loadFromFile()
-- ==========================================
-- PHẦN 1: LOGIC COPY AVATAR GỐC CỦA BẠN
-- ==========================================
local function apply_avatar(username)
    if not username or username == "" then return end
    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        local targetPlayer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == username:lower() then
                targetPlayer = p
                break
            end
        end
        local desc
        if targetPlayer and targetPlayer.Character then
            local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetHum then
                desc = targetHum:GetAppliedDescription()
            end
        end
        if not desc then
            local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
            if not ok then
                warn("[Avatar Copy] Không tìm thấy người chơi: " .. tostring(username))
                return
            end
            local ok2, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, userId)
            if not ok2 then
                warn("[Avatar Copy] Lỗi lấy thông tin Avatar")
                return
            end
            desc = d
        end
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Accessory") or c:IsA("Hat") or c:IsA("BodyColors") or
            c:IsA("CharacterMesh") or c:IsA("Shirt") or c:IsA("Pants") or
            c:IsA("ShirtGraphic") then
                c:Destroy()
            end
        end
        pcall(function()
            if hum.ApplyDescriptionClientServer then
                hum:ApplyDescriptionClientServer(desc)
            else
                hum:ApplyDescription(desc)
            end
        end)
        local bc = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
        bc.Parent = char
        bc.HeadColor3 = desc.HeadColor
        bc.TorsoColor3 = desc.TorsoColor
        bc.LeftArmColor3 = desc.LeftArmColor
        bc.RightArmColor3 = desc.RightArmColor
        bc.LeftLegColor3 = desc.LeftLegColor
        bc.RightLegColor3 = desc.RightLegColor
    end)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    if lastUsername then
        char:WaitForChild("Humanoid", 10)
        task.wait(0.65)
        apply_avatar(lastUsername)
    end
end)
local function startCopy(username)
    lastUsername = username
    apply_avatar(username)
end
-- ==========================================
-- PHẦN 2: KHỞI TẠO GIAO DIỆN (UI)
-- ==========================================
local Colors = {
MainBlack = Color3.fromRGB(15, 15, 18),       -- Màu đen chính của menu
CardDarkGray = Color3.fromRGB(24, 24, 30),    -- Màu đen hơi xám cho các khung con
InputDark = Color3.fromRGB(18, 18, 22),       -- Màu nền ô nhập liệu
PurpleMain = Color3.fromRGB(138, 43, 226),    -- Màu tím chủ đạo (Nút, viền)
PurpleHover = Color3.fromRGB(158, 63, 246),   -- Màu tím sáng khi di chuột
PurpleDim = Color3.fromRGB(90, 28, 150),      -- Màu tím trầm cho tab chưa chọn
TextWhite = Color3.fromRGB(245, 245, 250),    -- Chữ trắng sáng
TextGray = Color3.fromRGB(170, 170, 185),     -- Chữ xám phụ
RedDelete = Color3.fromRGB(210, 50, 70)       -- Màu đỏ cho nút xóa
}
local ICON_ID = "rbxassetid://116560656699364"
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("LamAvatarCopyUI") then
    parentGui:FindFirstChild("LamAvatarCopyUI"):Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LamAvatarCopyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui
local function addCornerAndStroke(instance, cornerRadius, strokeThickness, strokeColor)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 8)
    corner.Parent = instance
    if strokeThickness and strokeThickness > 0 then
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = strokeThickness
        stroke.Color = strokeColor or Colors.PurpleMain
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = instance
    end
end
-- Hàm kéo thả thông minh (Phân biệt được giữa Kéo thả và Click)
local function makeDraggable(topbarObject, objectToMove, onClickCallback)
    local dragging = false
    local hasMoved = false
    local dragInput, dragStart, startPos
    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = objectToMove.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not hasMoved and onClickCallback then
                        onClickCallback()
                    end
                end
            end)
        end
    end)
    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                hasMoved = true
            end
            objectToMove.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
-- 1. NÚT MỞ MENU (TOGGLE BUTTON)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "OpenMenuButton"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundColor3 = Colors.MainBlack
ToggleBtn.Image = ICON_ID
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui
addCornerAndStroke(ToggleBtn, 12, 2, Colors.PurpleMain)
-- 2. KHUNG MENU CHÍNH (MAIN FRAME)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 340)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -170)
MainFrame.BackgroundColor3 = Colors.MainBlack
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
addCornerAndStroke(MainFrame, 12, 2, Colors.PurpleMain)
-- THANH TIÊU ĐỀ (TOP BAR)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame
makeDraggable(TopBar, MainFrame)
local TitleIcon = Instance.new("ImageLabel")
TitleIcon.Size = UDim2.new(0, 26, 0, 26)
TitleIcon.Position = UDim2.new(0, 12, 0.5, -13)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Image = ICON_ID
TitleIcon.Parent = TopBar
addCornerAndStroke(TitleIcon, 6, 0)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 46, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Avatar Copy"
TitleLabel.TextColor3 = Colors.TextWhite
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -38, 0.5, -15)
MinimizeBtn.BackgroundColor3 = Colors.CardDarkGray
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Colors.TextWhite
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TopBar
addCornerAndStroke(MinimizeBtn, 8, 1.5, Colors.PurpleMain)
local TopDivider = Instance.new("Frame")
TopDivider.Size = UDim2.new(1, -20, 0, 1)
TopDivider.Position = UDim2.new(0, 10, 0, 42)
TopDivider.BackgroundColor3 = Colors.PurpleMain
TopDivider.BorderSizePixel = 0
TopDivider.Parent = MainFrame
-- VÙNG NỘI DUNG CHÍNH
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -20, 1, -56)
ContentContainer.Position = UDim2.new(0, 10, 0, 48)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame
-- 3. SIDEBAR BÊN TRÁI
local SidebarFrame = Instance.new("Frame")
SidebarFrame.Name = "SidebarFrame"
SidebarFrame.Size = UDim2.new(0.21, 0, 1, 0)
SidebarFrame.Position = UDim2.new(0, 0, 0, 0)
SidebarFrame.BackgroundColor3 = Colors.CardDarkGray
SidebarFrame.Parent = ContentContainer
addCornerAndStroke(SidebarFrame, 8, 1.5, Colors.PurpleMain)
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 8)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = SidebarFrame
local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 6)
SidebarPadding.PaddingRight = UDim.new(0, 6)
SidebarPadding.Parent = SidebarFrame
local TabCopyBtn = Instance.new("TextButton")
TabCopyBtn.Name = "TabCopyBtn"
TabCopyBtn.Size = UDim2.new(1, 0, 0, 38)
TabCopyBtn.BackgroundColor3 = Colors.PurpleMain
TabCopyBtn.Text = "Avatar\nCopy"
TabCopyBtn.TextColor3 = Colors.TextWhite
TabCopyBtn.Font = Enum.Font.GothamBold
TabCopyBtn.TextSize = 12
TabCopyBtn.TextWrapped = true
TabCopyBtn.LayoutOrder = 1
TabCopyBtn.Parent = SidebarFrame
addCornerAndStroke(TabCopyBtn, 6, 0)
local TabAboutBtn = Instance.new("TextButton")
TabAboutBtn.Name = "TabAboutBtn"
TabAboutBtn.Size = UDim2.new(1, 0, 0, 38)
TabAboutBtn.BackgroundColor3 = Colors.InputDark
TabAboutBtn.Text = "About\nScript"
TabAboutBtn.TextColor3 = Colors.TextGray
TabAboutBtn.Font = Enum.Font.GothamSemibold
TabAboutBtn.TextSize = 12
TabAboutBtn.TextWrapped = true
TabAboutBtn.LayoutOrder = 2
TabAboutBtn.Parent = SidebarFrame
addCornerAndStroke(TabAboutBtn, 6, 1, Colors.PurpleDim)
-- 4. KHUNG NỘI DUNG BÊN PHẢI
local RightArea = Instance.new("Frame")
RightArea.Name = "RightArea"
RightArea.Size = UDim2.new(0.77, 0, 1, 0)
RightArea.Position = UDim2.new(0.23, 0, 0, 0)
RightArea.BackgroundTransparency = 1
RightArea.Parent = ContentContainer
-- ==========================================
-- TAB 1: GIAO DIỆN AVATAR COPY
-- ==========================================
local CopyPage = Instance.new("Frame")
CopyPage.Name = "CopyPage"
CopyPage.Size = UDim2.new(1, 0, 1, 0)
CopyPage.BackgroundTransparency = 1
CopyPage.Visible = true
CopyPage.Parent = RightArea
local InputCard = Instance.new("Frame")
InputCard.Name = "InputCard"
InputCard.Size = UDim2.new(1, 0, 0, 95)
InputCard.Position = UDim2.new(0, 0, 0, 0)
InputCard.BackgroundColor3 = Colors.CardDarkGray
InputCard.Parent = CopyPage
addCornerAndStroke(InputCard, 8, 1.5, Colors.PurpleMain)
local UsernameBox = Instance.new("TextBox")
UsernameBox.Name = "UsernameBox"
UsernameBox.Size = UDim2.new(1, -20, 0, 36)
UsernameBox.Position = UDim2.new(0, 10, 0, 10)
UsernameBox.BackgroundColor3 = Colors.InputDark
UsernameBox.PlaceholderText = "Dán (Paste) tên người chơi vào đây..."
UsernameBox.PlaceholderColor3 = Colors.TextGray
UsernameBox.Text = ""
UsernameBox.TextColor3 = Colors.TextWhite
UsernameBox.Font = Enum.Font.Gotham
UsernameBox.TextSize = 13
UsernameBox.ClearTextOnFocus = false
UsernameBox.Parent = InputCard
addCornerAndStroke(UsernameBox, 6, 1, Colors.PurpleDim)
local CopyActionBtn = Instance.new("TextButton")
CopyActionBtn.Name = "CopyActionBtn"
CopyActionBtn.Size = UDim2.new(0.48, -5, 0, 32)
CopyActionBtn.Position = UDim2.new(0, 10, 0, 54)
CopyActionBtn.BackgroundColor3 = Colors.PurpleMain
CopyActionBtn.Text = "Copy"
CopyActionBtn.TextColor3 = Colors.TextWhite
CopyActionBtn.Font = Enum.Font.GothamBold
CopyActionBtn.TextSize = 14
CopyActionBtn.Parent = InputCard
addCornerAndStroke(CopyActionBtn, 6, 0)
local SaveActionBtn = Instance.new("TextButton")
SaveActionBtn.Name = "SaveActionBtn"
SaveActionBtn.Size = UDim2.new(0.48, -5, 0, 32)
SaveActionBtn.Position = UDim2.new(0.52, -5, 0, 54)
SaveActionBtn.BackgroundColor3 = Colors.PurpleMain
SaveActionBtn.Text = "Save"
SaveActionBtn.TextColor3 = Colors.TextWhite
SaveActionBtn.Font = Enum.Font.GothamBold
SaveActionBtn.TextSize = 14
SaveActionBtn.Parent = InputCard
addCornerAndStroke(SaveActionBtn, 6, 0)
local SavedCard = Instance.new("Frame")
SavedCard.Name = "SavedCard"
SavedCard.Size = UDim2.new(1, 0, 1, -105)
SavedCard.Position = UDim2.new(0, 0, 0, 105)
SavedCard.BackgroundColor3 = Colors.CardDarkGray
SavedCard.Parent = CopyPage
addCornerAndStroke(SavedCard, 8, 1.5, Colors.PurpleMain)
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -20, 0, 28)
SearchBox.Position = UDim2.new(0, 10, 0, 8)
SearchBox.BackgroundColor3 = Colors.InputDark
SearchBox.PlaceholderText = "🔍 Tìm kiếm tên đã lưu..."
SearchBox.PlaceholderColor3 = Colors.TextGray
SearchBox.Text = ""
SearchBox.TextColor3 = Colors.TextWhite
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.Parent = SavedCard
addCornerAndStroke(SearchBox, 6, 1, Colors.PurpleDim)
local SavedScroll = Instance.new("ScrollingFrame")
SavedScroll.Name = "SavedScroll"
SavedScroll.Size = UDim2.new(1, -20, 1, -48)
SavedScroll.Position = UDim2.new(0, 10, 0, 42)
SavedScroll.BackgroundTransparency = 1
SavedScroll.BorderSizePixel = 0
SavedScroll.ClipsDescendants = true
SavedScroll.ScrollBarThickness = 4
SavedScroll.ScrollBarImageColor3 = Colors.PurpleMain
SavedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SavedScroll.Parent = SavedCard
local SavedListLayout = Instance.new("UIListLayout")
SavedListLayout.Padding = UDim.new(0, 6)
SavedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SavedListLayout.Parent = SavedScroll
-- ==========================================
-- TAB 2: GIAO DIỆN ABOUT SCRIPT
-- ==========================================
local AboutPage = Instance.new("Frame")
AboutPage.Name = "AboutPage"
AboutPage.Size = UDim2.new(1, 0, 1, 0)
AboutPage.BackgroundColor3 = Colors.CardDarkGray
AboutPage.Visible = false
AboutPage.Parent = RightArea
addCornerAndStroke(AboutPage, 8, 1.5, Colors.PurpleMain)
local AboutIcon = Instance.new("ImageLabel")
AboutIcon.Size = UDim2.new(0, 72, 0, 72)
AboutIcon.Position = UDim2.new(0.5, -36, 0, 18)
AboutIcon.BackgroundColor3 = Colors.InputDark
AboutIcon.Image = ICON_ID
AboutIcon.Parent = AboutPage
addCornerAndStroke(AboutIcon, 14, 2, Colors.PurpleMain)
local AboutTitle = Instance.new("TextLabel")
AboutTitle.Size = UDim2.new(1, -20, 0, 26)
AboutTitle.Position = UDim2.new(0, 10, 0, 98)
AboutTitle.BackgroundTransparency = 1
AboutTitle.Text = "Avatar Copy Script"
AboutTitle.TextColor3 = Colors.TextWhite
AboutTitle.Font = Enum.Font.GothamBold
AboutTitle.TextSize = 18
AboutTitle.Parent = AboutPage
local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(1, -20, 0, 20)
CreditLabel.Position = UDim2.new(0, 10, 0, 124)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "Credit by Lam"
CreditLabel.TextColor3 = Colors.PurpleHover
CreditLabel.Font = Enum.Font.GothamBold
CreditLabel.TextSize = 14
CreditLabel.Parent = AboutPage
local DescLabel = Instance.new("TextLabel")
DescLabel.Size = UDim2.new(1, -30, 0, 110)
DescLabel.Position = UDim2.new(0, 15, 0, 150)
DescLabel.BackgroundTransparency = 1
DescLabel.Text = "Công cụ hỗ trợ sao chép nhanh ngoại hình (Avatar) của bất kỳ người chơi nào trong Roblox chỉ bằng Username.\n\n• Tự động giữ lại trang phục khi hồi sinh (Respawn).\n• Hỗ trợ lưu trữ và tìm kiếm danh sách yêu thích.\n• Mã nguồn mở tại: Github/XuyenLam/LamScripts"
DescLabel.TextColor3 = Colors.TextGray
DescLabel.Font = Enum.Font.Gotham
DescLabel.TextSize = 12
DescLabel.TextWrapped = true
DescLabel.TextYAlignment = Enum.TextYAlignment.Top
DescLabel.Parent = AboutPage
-- ==========================================
-- PHẦN 3: XỬ LÝ SỰ KIỆN & TƯƠNG TÁC UI
-- ==========================================
local function refreshSavedList()
    for _, child in ipairs(SavedScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    local filterText = SearchBox.Text:lower()
    local count = 0
    for index, savedName in ipairs(savedUsernames) do
        if filterText == "" or savedName:lower():find(filterText, 1, true) then
            count = count + 1
            local ItemFrame = Instance.new("Frame")
            ItemFrame.Size = UDim2.new(1, -6, 0, 32)
            ItemFrame.BackgroundColor3 = Colors.InputDark
            ItemFrame.LayoutOrder = index
            ItemFrame.Parent = SavedScroll
            addCornerAndStroke(ItemFrame, 6, 1, Colors.PurpleDim)
            local NameBtn = Instance.new("TextButton")
            NameBtn.Size = UDim2.new(1, -78, 1, 0)
            NameBtn.Position = UDim2.new(0, 8, 0, 0)
            NameBtn.BackgroundTransparency = 1
            NameBtn.Text = savedName
            NameBtn.TextColor3 = Colors.TextWhite
            NameBtn.Font = Enum.Font.GothamSemibold
            NameBtn.TextSize = 13
            NameBtn.TextXAlignment = Enum.TextXAlignment.Left
            NameBtn.Parent = ItemFrame
            NameBtn.MouseButton1Click:Connect(function()
                UsernameBox.Text = savedName
                startCopy(savedName)
            end)
            local QuickCopyBtn = Instance.new("TextButton")
            QuickCopyBtn.Size = UDim2.new(0, 36, 0, 22)
            QuickCopyBtn.Position = UDim2.new(1, -68, 0.5, -11)
            QuickCopyBtn.BackgroundColor3 = Colors.PurpleMain
            QuickCopyBtn.Text = "Use"
            QuickCopyBtn.TextColor3 = Colors.TextWhite
            QuickCopyBtn.Font = Enum.Font.GothamBold
            QuickCopyBtn.TextSize = 11
            QuickCopyBtn.Parent = ItemFrame
            addCornerAndStroke(QuickCopyBtn, 4, 0)
            QuickCopyBtn.MouseButton1Click:Connect(function()
                UsernameBox.Text = savedName
                startCopy(savedName)
            end)
            local DeleteBtn = Instance.new("TextButton")
            DeleteBtn.Size = UDim2.new(0, 24, 0, 22)
            DeleteBtn.Position = UDim2.new(1, -28, 0.5, -11)
            DeleteBtn.BackgroundColor3 = Colors.RedDelete
            DeleteBtn.Text = "X"
            DeleteBtn.TextColor3 = Colors.TextWhite
            DeleteBtn.Font = Enum.Font.GothamBold
            DeleteBtn.TextSize = 12
            DeleteBtn.Parent = ItemFrame
            addCornerAndStroke(DeleteBtn, 4, 0)
            DeleteBtn.MouseButton1Click:Connect(function()
                table.remove(savedUsernames, index)
                saveToFile()
                refreshSavedList()
            end)
        end
    end
    SavedScroll.CanvasSize = UDim2.new(0, 0, 0, count * 38)
end
CopyActionBtn.MouseButton1Click:Connect(function()
    local targetName = UsernameBox.Text:match("^%s*(.-)%s*$")
    if targetName and targetName ~= "" then
        startCopy(targetName)
        CopyActionBtn.Text = "Copied!"
        task.delay(1, function()
            if CopyActionBtn then CopyActionBtn.Text = "Copy" end
        end)
    end
end)
SaveActionBtn.MouseButton1Click:Connect(function()
    local targetName = UsernameBox.Text:match("^%s*(.-)%s*$")
    if targetName and targetName ~= "" then
        local exists = false
        for _, v in ipairs(savedUsernames) do
            if v:lower() == targetName:lower() then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(savedUsernames, targetName)
            saveToFile()
            refreshSavedList()
            SaveActionBtn.Text = "Saved!"
        else
            SaveActionBtn.Text = "Exists!"
        end
        task.delay(1, function()
            if SaveActionBtn then SaveActionBtn.Text = "Save" end
        end)
    end
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshSavedList()
end)
TabCopyBtn.MouseButton1Click:Connect(function()
    CopyPage.Visible = true
    AboutPage.Visible = false
    TabCopyBtn.BackgroundColor3 = Colors.PurpleMain
    TabCopyBtn.TextColor3 = Colors.TextWhite
    TabAboutBtn.BackgroundColor3 = Colors.InputDark
    TabAboutBtn.TextColor3 = Colors.TextGray
end)
TabAboutBtn.MouseButton1Click:Connect(function()
    CopyPage.Visible = false
    AboutPage.Visible = true
    TabAboutBtn.BackgroundColor3 = Colors.PurpleMain
    TabAboutBtn.TextColor3 = Colors.TextWhite
    TabCopyBtn.BackgroundColor3 = Colors.InputDark
    TabCopyBtn.TextColor3 = Colors.TextGray
end)
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)
-- Gắn kéo thả + mở menu khi click cho ToggleBtn
makeDraggable(ToggleBtn, ToggleBtn, function()
    ToggleBtn.Visible = false
    MainFrame.Visible = true
end)
refreshSavedList()

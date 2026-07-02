local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP, Aimbot, Menu, Fly, Noclip, Invisible, Spinbot
local Settings = {
    ESP = {
        Enabled = false, Box = false, Distance = false, Name = false, Skeleton = false,
        HeadCircle = false, Tracer = false, Chams = false, Color = Color3.fromRGB(0,255,255)
    },
    Aimbot = {
        Enabled = false, Silent = false, Mode = "Head", FOV = 120
    },
    Extra = {
        Noclip=false, Fly=false, Invisible=false, Spinbot=false,
        CameraMode="First", FlySpeed=4
    }
}

local GUI
local DrawingObjects = {}
local ChamAdorns = setmetatable({}, {__mode="k"})
local isMenuOpen, isAiming = false, false

local function getEnemies()
    local enemies = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            if (not LocalPlayer.Team or not plr.Team) or (LocalPlayer.Team ~= plr.Team) then
                if plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head")
                   and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    table.insert(enemies, plr)
                end
            end
        end
    end
    return enemies
end

local function WorldToScreen(pos)
    local v,vis = Camera.WorldToViewportPoint(Camera, pos)
    return Vector2.new(v.X, v.Y), vis
end

local function clearDrawings()
    for _,obj in pairs(DrawingObjects) do
        obj.Visible = false
        if typeof(obj) == "table" then
            if typeof(obj.Remove) == "function" then obj:Remove() elseif typeof(obj.Destroy) == "function" then obj:Destroy() end
        end
    end
    DrawingObjects = {}
end
local function clearChams()
    for plr,boxes in pairs(ChamAdorns) do
        for _,v in pairs(boxes) do pcall(function() v:Destroy() end) end
        ChamAdorns[plr] = nil
    end
end

local function drawBox(plr, color)
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local modelSize = Vector3.new(4, 7, 1.6)
    local cframe = root.CFrame
    local points = {}
    for _,vec in ipairs({
        Vector3.new(-modelSize.X/2,modelSize.Y/2,0), Vector3.new(modelSize.X/2,modelSize.Y/2,0),
        Vector3.new(modelSize.X/2,-modelSize.Y/2,0), Vector3.new(-modelSize.X/2,-modelSize.Y/2,0)
    }) do
        local wpos = (cframe * CFrame.new(vec)).Position
        local scr, onscr = WorldToScreen(wpos)
        if not onscr then return end table.insert(points, scr)
    end
    for i=1,#points do
        local ln = Drawing.new("Line")
        ln.From, ln.To = points[i], points[(i%#points)+1]
        ln.Color = color
        ln.Thickness, ln.Transparency, ln.Visible = 2, 1, true
        table.insert(DrawingObjects, ln)
    end
end

local function drawName(plr, color)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local pos, onscr = WorldToScreen(head.Position)
    if onscr then
        local txt = Drawing.new("Text")
        txt.Text = plr.Name
        txt.Position = Vector2.new(pos.X,pos.Y-24)
        txt.Size = 15
        txt.Color = color
        txt.Center, txt.Outline, txt.Visible = true, true, true
        table.insert(DrawingObjects, txt)
    end
end

local function drawDistance(plr, color)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude
    local pos, onscr = WorldToScreen(head.Position)
    if onscr then
        local txt = Drawing.new("Text")
        txt.Text = "["..math.floor(dist).."m]"
        txt.Position = Vector2.new(pos.X,pos.Y-12)
        txt.Size = 13
        txt.Color = color
        txt.Center, txt.Outline, txt.Visible = true, true, true
        table.insert(DrawingObjects, txt)
    end
end

local function drawSkeleton(plr, color)
    local char = plr.Character
    if not char then return end
    local skeleton = {
        {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
    }
    for _,seg in ipairs(skeleton) do
        local a,charA = char:FindFirstChild(seg[1]), char:FindFirstChild(seg[2])
        if a and charA then
            local p1,ok1 = WorldToScreen(a.Position)
            local p2,ok2 = WorldToScreen(charA.Position)
            if ok1 and ok2 then
                local ln = Drawing.new("Line")
                ln.From, ln.To = p1, p2
                ln.Color, ln.Thickness, ln.Transparency, ln.Visible = color, 2, 1, true
                table.insert(DrawingObjects, ln)
            end
        end
    end
end

local function drawHeadCircle(plr, color)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local pos, onscr = WorldToScreen(head.Position)
    if onscr then
        local cir = Drawing.new("Circle")
        cir.Position = pos
        cir.Color = color
        cir.Transparency = 1
        cir.Radius = 16 -- sabit boyut (uzaklığa göre değişmez)
        cir.Thickness = 2
        cir.NumSides = 30
        cir.Filled = false
        cir.Visible = true
        table.insert(DrawingObjects, cir)
    end
end

local function drawTracer(plr, color)
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos, onscr = WorldToScreen(root.Position)
    if onscr then
        local from = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        local ln = Drawing.new("Line")
        ln.From = from
        ln.To = pos
        ln.Color = color
        ln.Thickness = 2
        ln.Transparency = 1
        ln.Visible = true
        table.insert(DrawingObjects, ln)
    end
end

local function drawChams(plr, color)
    local char = plr.Character
    if not char then return end
    if not ChamAdorns[plr] then ChamAdorns[plr] = {} end
    for _,p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and not p:IsDescendantOf(LocalPlayer.Character) then
            if not ChamAdorns[plr][p] then
                local adorn = Instance.new("BoxHandleAdornment")
                adorn.Adornee = p
                adorn.Size = p.Size
                adorn.Color3 = color
                adorn.Transparency = .45
                adorn.AlwaysOnTop = true
                adorn.ZIndex = 10
                adorn.Parent = Workspace.CurrentCamera
                ChamAdorns[plr][p] = adorn
            else
                local ch = ChamAdorns[plr][p]
                ch.Color3 = color
                ch.Transparency = .45
                ch.Visible = true
            end
        end
    end
end

local function ESPDraw()
    clearDrawings()
    if not Settings.ESP.Enabled then clearChams() return end
    local color = Settings.ESP.Color
    for _,plr in ipairs(getEnemies()) do
        if Settings.ESP.Box then drawBox(plr, color) end
        if Settings.ESP.Name then drawName(plr, color) end
        if Settings.ESP.Distance then drawDistance(plr, color) end
        if Settings.ESP.Skeleton then drawSkeleton(plr, color) end
        if Settings.ESP.HeadCircle then drawHeadCircle(plr, color) end
        if Settings.ESP.Tracer then drawTracer(plr, color) end
        if Settings.ESP.Chams then drawChams(plr, color) else clearChams() end
    end
end
RunService:UnbindFromRenderStep("visitingmenu_ESPRender")
RunService:BindToRenderStep("visitingmenu_ESPRender", Enum.RenderPriority.Last.Value, ESPDraw)

local function getTarget()
    local best, bestD, mouse = nil, math.huge, UserInputService:GetMouseLocation()
    for _,plr in ipairs(getEnemies()) do
        local char = plr.Character
        local aimpart
        if Settings.Aimbot.Mode == "Head" then aimpart = char and char:FindFirstChild("Head")
        elseif Settings.Aimbot.Mode == "Body" then aimpart = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
        else
            local parts={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftHand","RightHand","LeftFoot","RightFoot"}
            local dist, testPart = math.huge, nil
            for _,nm in ipairs(parts) do
                local part = char and char:FindFirstChild(nm)
                if part then
                    local pos,ok = WorldToScreen(part.Position)
                    if ok then
                        local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                        if d < dist then dist,testPart = d,part end
                    end
                end
            end
            aimpart = testPart
        end
        if aimpart then
            local pos,ok = WorldToScreen(aimpart.Position)
            if ok then
                local fovDist = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                if fovDist <= Settings.Aimbot.FOV and fovDist < bestD then
                    bestD,best = fovDist,{plr=plr,part=aimpart}
                end
            end
        end
    end
    return best
end

local function AimbotProcess()
    if not (Settings.Aimbot.Enabled and isAiming) then return end
    local tar = getTarget()
    if tar and tar.part then
        local camPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.new(camPos, tar.part.Position)
    end
end
RunService:UnbindFromRenderStep("visitingmenu_Aimbot")
RunService:BindToRenderStep("visitingmenu_Aimbot", Enum.RenderPriority.Character.Value + 40, AimbotProcess)

do
    if getrawmetatable and setreadonly then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old; old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if not checkcaller() and Settings.Aimbot.Enabled and Settings.Aimbot.Silent then
                local tar = getTarget()
                if tar and tar.part then
                    local args = {...}
                    local m = getnamecallmethod()
                    if tostring(m):lower():find("fire") and tostring(self):lower():find("hit") then
                        for i,v in pairs(args) do
                            if typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=tar.part end
                            if typeof(v)=="Vector3" then args[i]=tar.part.Position end
                        end
                        return old(self, unpack(args))
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local FlyConn, NoclipConn, SpinConn = nil, nil, nil
local flyKeys = {F=false,B=false,L=false,R=false,U=false,D=false}
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.W then flyKeys.F=true end
    if i.KeyCode==Enum.KeyCode.S then flyKeys.B=true end
    if i.KeyCode==Enum.KeyCode.A then flyKeys.L=true end
    if i.KeyCode==Enum.KeyCode.D then flyKeys.R=true end
    if i.KeyCode==Enum.KeyCode.Space then flyKeys.U=true end
    if i.KeyCode==Enum.KeyCode.LeftControl then flyKeys.D=true end
end)
UserInputService.InputEnded:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.W then flyKeys.F=false end
    if i.KeyCode==Enum.KeyCode.S then flyKeys.B=false end
    if i.KeyCode==Enum.KeyCode.A then flyKeys.L=false end
    if i.KeyCode==Enum.KeyCode.D then flyKeys.R=false end
    if i.KeyCode==Enum.KeyCode.Space then flyKeys.U=false end
    if i.KeyCode==Enum.KeyCode.LeftControl then flyKeys.D=false end
end)
local function addNoclip(enable)
    if NoclipConn then NoclipConn:Disconnect() NoclipConn=nil end
    if enable then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            for _,v in ipairs(char and char:GetDescendants() or {}) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end)
    else
        local char = LocalPlayer.Character
        for _,v in ipairs(char and char:GetDescendants() or {}) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end
local function addFly(enable)
    if FlyConn then FlyConn:Disconnect() FlyConn=nil end
    if enable then
        FlyConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local cf = Camera.CFrame
            local move = Vector3.zero
            if flyKeys.F then move = move + cf.LookVector end
            if flyKeys.B then move = move - cf.LookVector end
            if flyKeys.L then move = move - cf.RightVector end
            if flyKeys.R then move = move + cf.RightVector end
            if flyKeys.U then move = move + cf.UpVector end
            if flyKeys.D then move = move - cf.UpVector end
            if move.Magnitude > 0 then move = move.Unit end
            root.Velocity = move * Settings.Extra.FlySpeed * 13
        end)
    end
end
local function setInvisible(enable)
    local char = LocalPlayer.Character
    for _,v in ipairs(char and char:GetDescendants() or {}) do
        if v:IsA("BasePart") then
            if enable then
                v.LocalTransparencyModifier=1 v.Transparency=1
            else
                v.LocalTransparencyModifier=0 v.Transparency=0
            end
        elseif v:IsA("Decal") then
            v.Transparency = enable and 1 or 0
        elseif v:IsA("Accessory") and v:FindFirstChildOfClass("BasePart") then
            v:FindFirstChildOfClass("BasePart").Transparency = enable and 1 or 0
        end
    end
    if char and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if enable then
                hum.NameDisplayDistance, hum.HealthDisplayDistance, hum.DisplayDistanceType = 0, 0, Enum.HumanoidDisplayDistanceType.None
            else
                hum.NameDisplayDistance, hum.HealthDisplayDistance, hum.DisplayDistanceType = 100, 100, Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end
local function addSpinbot(enable)
    if SpinConn then SpinConn:Disconnect() SpinConn=nil end
    if enable then
        SpinConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame * CFrame.Angles(0,math.rad(32),0) end
        end)
    end
end
local function setCamera(mode)
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if mode == "Third" then
        if hum then
            Camera.CameraSubject = hum
            Camera.CameraType = Enum.CameraType.Custom
            Camera.FieldOfView = 70
        end
    else
        if head then
            Camera.CameraSubject = head
            Camera.CameraType = Enum.CameraType.Attach
            Camera.FieldOfView = 70
        end
    end
    Settings.Extra.CameraMode = mode
end

local function handleExtras()
    addNoclip(Settings.Extra.Noclip)
    addFly(Settings.Extra.Fly)
    setInvisible(Settings.Extra.Invisible)
    addSpinbot(Settings.Extra.Spinbot)
    setCamera(Settings.Extra.CameraMode)
end

local function destroyGui()
    if GUI and GUI.Parent then GUI:Destroy() end
    for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do if g.Name=="visitingmenu" then g:Destroy() end end
end

local function showPassword(callback)
    destroyGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "pwdVstWnd"
    gui.Parent = game:GetService("CoreGui")
    local fr = Instance.new("Frame",gui)
    fr.Position = UDim2.new(0.41,0,0.35,0)
    fr.Size = UDim2.new(0,288,0,93)
    fr.BackgroundColor3 = Color3.fromRGB(24,34,48)
    fr.BorderSizePixel = 0
    local txt = Instance.new("TextLabel",fr)
    txt.Size = UDim2.new(1,0,0,30)
    txt.Position = UDim2.new(0,0,0,8)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBlack
    txt.Text = "Şifre Gerekli"
    txt.TextColor3 = Color3.fromRGB(0,255,255)
    txt.TextSize = 18
    local pass = Instance.new("TextBox",fr)
    pass.Size = UDim2.new(0.87,0,0,24)
    pass.Position = UDim2.new(0.06,0,0,39)
    pass.PlaceholderText = "258631"
    pass.BackgroundColor3 = Color3.fromRGB(37,46,61)
    pass.TextColor3 = Color3.fromRGB(255,255,255)
    pass.Font = Enum.Font.Gotham
    pass.TextSize = 17
    pass.ClearTextOnFocus = true
    local info = Instance.new("TextLabel",fr)
    info.Size = UDim2.new(1,0,0,15)
    info.Position = UDim2.new(0,0,1,-18)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextColor3 = Color3.fromRGB(255,64,64)
    info.TextSize = 14
    info.Text = ""
    local btn = Instance.new("TextButton",fr)
    btn.Text = "GİR"
    btn.Size = UDim2.new(0,60,0,20)
    btn.Position = UDim2.new(0.34,0,1,-30)
    btn.BackgroundColor3 = Color3.fromRGB(43,130,145)
    btn.Font = Enum.Font.GothamBlack
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 15
    btn.BorderSizePixel = 0
    local function check()
        if tostring(pass.Text) == "258631" then
            gui:Destroy()
            callback()
        else
            info.Text = "Hatalı şifre!"
        end
    end
    btn.MouseButton1Click:Connect(check)
    pass.FocusLost:Connect(function(enter) if enter then check() end end)
    UserInputService.InputBegan:Connect(function(inp,gp) if not gp and inp.KeyCode == Enum.KeyCode.Return then check() end end)
    gui.Enabled = true
end

local function openMenu()
    destroyGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "visitingmenu"
    gui.Parent = game:GetService("CoreGui")
    GUI = gui

    local fr = Instance.new("Frame")
    fr.Size = UDim2.fromOffset(594, 342)
    fr.Position = UDim2.new(0.26,0,0.18,0)
    fr.BackgroundColor3 = Color3.fromRGB(20,27,36)
    fr.BorderSizePixel = 0
    fr.Active = true
    fr.Draggable = true
    fr.Parent = gui

    local bar = Instance.new("Frame", fr)
    bar.Size = UDim2.new(1,0,0,36)
    bar.BackgroundColor3 = Color3.fromRGB(11,44,76)
    bar.Position = UDim2.new(0,0,0,0)

    local tx = Instance.new("TextLabel",bar)
    tx.Text = "visitingmenu"
    tx.Font = Enum.Font.GothamBlack
    tx.TextColor3 = Color3.fromRGB(0,255,255)
    tx.TextSize = 20
    tx.Size = UDim2.new(1,0,1,0)
    tx.BackgroundTransparency = 1

    local close = Instance.new("TextButton",bar)
    close.Text = "X"
    close.Font = Enum.Font.GothamBlack
    close.TextColor3 = Color3.fromRGB(255,60,60)
    close.TextSize = 16
    close.Size = UDim2.new(0,31,0,28)
    close.Position = UDim2.new(1,-36,0,4)
    close.BackgroundColor3 = Color3.fromRGB(33,22,18)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui.Enabled = false isMenuOpen=false end)

    -- ESP
    local yFrm, xFrm = 45, {ESP=0.024, Aimbot=0.38, Ex=0.66}
    local spacing = 29
    local function button(xx,yy,w,text,param,field,onToggle)
        local b = Instance.new("TextButton", fr)
        b.Size = UDim2.new(0,w,0,24)
        b.Position = UDim2.new(xx,0,0,yy)
        b.Text = text.." : "..(param[field] and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = param[field] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.BorderSizePixel = 0
        b.MouseButton1Click:Connect(function()
            param[field] = not param[field]
            b.Text = text.." : "..(param[field] and "AÇIK" or "KAPALI")
            b.BackgroundColor3 = param[field] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
            if onToggle then onToggle() end
        end)
    end

    button(xFrm.ESP, yFrm, 140, "ESP", Settings.ESP,"Enabled")
    button(xFrm.ESP, yFrm+spacing, 140, "Box", Settings.ESP,"Box")
    button(xFrm.ESP, yFrm+spacing*2, 140, "Mesafe", Settings.ESP,"Distance")
    button(xFrm.ESP, yFrm+spacing*3, 140, "İsim", Settings.ESP,"Name")
    button(xFrm.ESP, yFrm+spacing*4, 140, "İskelet", Settings.ESP,"Skeleton")
    button(xFrm.ESP, yFrm+spacing*5, 140, "HeadCircle", Settings.ESP,"HeadCircle")
    button(xFrm.ESP, yFrm+spacing*6, 140, "Tracer ESP", Settings.ESP,"Tracer")
    button(xFrm.ESP, yFrm+spacing*7, 140, "Chams ESP", Settings.ESP,"Chams")
    local clrLab = Instance.new("TextLabel",fr)
    clrLab.Size = UDim2.new(0,50,0,17)
    clrLab.Position = UDim2.new(xFrm.ESP,10,0,yFrm+spacing*8+1)
    clrLab.Text = "Renk:"
    clrLab.BackgroundTransparency = 1
    clrLab.Font = Enum.Font.GothamSemibold
    clrLab.TextColor3 = Color3.fromRGB(255,255,255)
    clrLab.TextSize = 13
    local clrBtn = Instance.new("TextButton",fr)
    clrBtn.Size = UDim2.new(0,29,0,17)
    clrBtn.Position = UDim2.new(xFrm.ESP,68,0,yFrm+spacing*8+1)
    clrBtn.Text = ""
    clrBtn.BackgroundColor3 = Settings.ESP.Color
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(60,255), math.random(60,255), math.random(60,255)
        Settings.ESP.Color=Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = Settings.ESP.Color
    end)

    -- Aimbot
    button(xFrm.Aimbot, yFrm, 140, "Aimbot", Settings.Aimbot, "Enabled")
    button(xFrm.Aimbot, yFrm+spacing, 140, "SilentAim", Settings.Aimbot, "Silent")
    local modes = {"Head","Body","ClosestPart"}
    local ab_mlbl = Instance.new("TextLabel", fr)
    ab_mlbl.Position = UDim2.new(xFrm.Aimbot,1,0,yFrm+spacing*2+3)
    ab_mlbl.Size = UDim2.new(0,60,0,17)
    ab_mlbl.Text = "Hedef:"
    ab_mlbl.Font = Enum.Font.GothamSemibold
    ab_mlbl.TextColor3 = Color3.fromRGB(255,255,255)
    ab_mlbl.TextSize = 13 ab_mlbl.BackgroundTransparency = 1
    local ab_mode = Instance.new("TextButton", fr)
    ab_mode.Position = UDim2.new(xFrm.Aimbot,64,0,yFrm+spacing*2+1)
    ab_mode.Size = UDim2.new(0,70,0,18)
    ab_mode.Text = Settings.Aimbot.Mode
    ab_mode.BackgroundColor3 = Color3.fromRGB(36,64,96)
    ab_mode.TextColor3 = Color3.fromRGB(255,255,255)
    ab_mode.Font = Enum.Font.GothamSemibold ab_mode.BorderSizePixel = 0 ab_mode.TextSize = 13
    ab_mode.MouseButton1Click:Connect(function()
        local i = table.find(modes,Settings.Aimbot.Mode) or 0
        Settings.Aimbot.Mode = modes[(i%#modes)+1]
        ab_mode.Text = Settings.Aimbot.Mode
    end)
    local fovLbl = Instance.new("TextLabel",fr)
    fovLbl.Position = UDim2.new(xFrm.Aimbot,1,0,yFrm+spacing*3+3)
    fovLbl.Size = UDim2.new(0,23,0,17)
    fovLbl.Text = "Fov:"
    fovLbl.Font = Enum.Font.GothamSemibold
    fovLbl.TextColor3 = Color3.fromRGB(255,255,255)
    fovLbl.TextSize = 13 fovLbl.BackgroundTransparency = 1

    local fovBox = Instance.new("TextBox",fr)
    fovBox.Position = UDim2.new(xFrm.Aimbot,40,0,yFrm+spacing*3+1)
    fovBox.Size = UDim2.new(0,45,0,18)
    fovBox.Text = tostring(Settings.Aimbot.FOV)
    fovBox.BackgroundColor3 = Color3.fromRGB(38,37,62)
    fovBox.TextColor3 = Color3.fromRGB(255,255,255)
    fovBox.Font = Enum.Font.GothamSemibold
    fovBox.BorderSizePixel = 0
    fovBox.TextSize = 13
    fovBox.ClearTextOnFocus = false
    fovBox.FocusLost:Connect(function()
        local v = tonumber(fovBox.Text)
        if v and v <= 650 and v >= 10 then
            Settings.Aimbot.FOV = v
        else
            fovBox.Text = tostring(Settings.Aimbot.FOV)
        end
    end)

    -- Extra
    button(xFrm.Ex, yFrm, 120, "NoClip", Settings.Extra, "Noclip", handleExtras)
    button(xFrm.Ex, yFrm+spacing, 120, "Fly", Settings.Extra, "Fly", handleExtras)
    button(xFrm.Ex, yFrm+spacing*2, 120, "Görünmez", Settings.Extra, "Invisible", handleExtras)
    button(xFrm.Ex, yFrm+spacing*3, 120, "Spinbot", Settings.Extra, "Spinbot", handleExtras)

    local camLbl = Instance.new("TextLabel",fr)
    camLbl.Position = UDim2.new(xFrm.Ex,0,0,yFrm+spacing*4)
    camLbl.Size = UDim2.new(0,60,0,16)
    camLbl.Text = "Kamera"
    camLbl.Font = Enum.Font.GothamSemibold
    camLbl.TextColor3 = Color3.fromRGB(255,255,255)
    camLbl.TextSize = 13 camLbl.BackgroundTransparency = 1
    local camBut = Instance.new("TextButton", fr)
    camBut.Position = UDim2.new(xFrm.Ex,66,0,yFrm+spacing*4-1)
    camBut.Size = UDim2.new(0,54,0,18)
    camBut.Text = (Settings.Extra.CameraMode=="First" and "1. Şahıs" or "3. Şahıs")
    camBut.Font = Enum.Font.GothamSemibold camBut.TextSize = 13 camBut.BackgroundColor3 = Color3.fromRGB(38,37,62)
    camBut.TextColor3 = Color3.fromRGB(255,255,255)
    camBut.BorderSizePixel = 0
    camBut.MouseButton1Click:Connect(function()
        if Settings.Extra.CameraMode == "First" then Settings.Extra.CameraMode = "Third" else Settings.Extra.CameraMode = "First" end
        camBut.Text = (Settings.Extra.CameraMode=="First" and "1. Şahıs" or "3. Şahıs")
        setCamera(Settings.Extra.CameraMode)
    end)

    local fLab = Instance.new("TextLabel",fr)
    fLab.Position = UDim2.new(xFrm.Ex,0,0,yFrm+spacing*5)
    fLab.Size = UDim2.new(0,63,0,16)
    fLab.Text = "Fly Hızı"
    fLab.Font = Enum.Font.GothamSemibold
    fLab.TextColor3 = Color3.fromRGB(255,255,255)
    fLab.TextSize = 13 fLab.BackgroundTransparency = 1

    local flySliderF = Instance.new("Frame", fr)
    flySliderF.Position = UDim2.new(xFrm.Ex,63,0,yFrm+spacing*5+2)
    flySliderF.Size = UDim2.new(0,56,0,8)
    flySliderF.BackgroundColor3 = Color3.fromRGB(60,60,60)
    flySliderF.BorderSizePixel = 0
    local Sknob = Instance.new("Frame", flySliderF)
    Sknob.Size = UDim2.new(0,10,1,0)
    Sknob.Position = UDim2.new((Settings.Extra.FlySpeed-1)/19,0,0,0)
    Sknob.BackgroundColor3 = Color3.fromRGB(0,255,255)
    Sknob.BorderSizePixel = 0
    Sknob.Active, Sknob.Draggable = true, true

    local flyval = Instance.new("TextBox", fr)
    flyval.Position = UDim2.new(xFrm.Ex,121,0,yFrm+spacing*5)
    flyval.Size = UDim2.new(0,33,0,16)
    flyval.Text = tostring(Settings.Extra.FlySpeed)
    flyval.BackgroundColor3 = Color3.fromRGB(38,37,62)
    flyval.TextColor3 = Color3.fromRGB(255,255,255)
    flyval.Font = Enum.Font.GothamSemibold
    flyval.BorderSizePixel = 0
    flyval.TextSize = 13
    flyval.ClearTextOnFocus = false
    flyval.FocusLost:Connect(function()
        local v = tonumber(flyval.Text)
        if v and v >= 1 and v <= 20 then
            Settings.Extra.FlySpeed = v
        else flyval.Text = tostring(Settings.Extra.FlySpeed) end
        Sknob.Position = UDim2.new((Settings.Extra.FlySpeed-1)/19,0,0,0)
    end)
    Sknob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local ucon, rend
            ucon = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    local mx = math.clamp((i.Position.X - flySliderF.AbsolutePosition.X) / flySliderF.AbsoluteSize.X,0,1)
                    Settings.Extra.FlySpeed = math.round(mx*19+1)
                    flyval.Text = tostring(Settings.Extra.FlySpeed)
                    Sknob.Position = UDim2.new((Settings.Extra.FlySpeed-1)/19,0,0,0)
                end
            end)
            rend = UserInputService.InputEnded:Connect(function(a)
                if a.UserInputType == Enum.UserInputType.MouseButton1 then
                    if ucon then ucon:Disconnect() end
                    if rend then rend:Disconnect() end
                end
            end)
        end
    end)
    gui.Enabled = true
    isMenuOpen = true
    handleExtras()
    setCamera(Settings.Extra.CameraMode)
end

showPassword(function() openMenu() end)

UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F4 then
        if not isMenuOpen or not GUI then openMenu() else GUI.Enabled = not GUI.Enabled end
    end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end
end)
UserInputService.InputEnded:Connect(function(inp,gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end
end)

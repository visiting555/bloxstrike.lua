local function SafeSetParent(obj, parent)
    local success, err = pcall(function()
        if obj then
            obj.Parent = parent
        end
    end)
    return success
end

local function ProtectGui(gui)
    -- Try to safely parent GUI in executor/anticheat friendly places
    if typeof(gethui) == "function" then
        if not SafeSetParent(gui, gethui()) then
            SafeSetParent(gui, game:GetService("CoreGui"))
        end
    elseif typeof(syn) == "table" and syn and syn.protect_gui then
        syn.protect_gui(gui)
        SafeSetParent(gui, game:GetService("CoreGui"))
    else
        if not SafeSetParent(gui, game:GetService("CoreGui")) then
            SafeSetParent(gui, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
        end
    end
end

local ESP = {
    enabled = false,
    box = false,
    distance = false,
    name = false,
    skeleton = false,
    headcircle = false,
    color = Color3.fromRGB(0,255,255),
}

local Aimbot = {
    enabled = false,
    targetmode = "Head",
    silent = false,
    fov = 120,
    target = nil,
}

local function IsEnemy(player)
    local lp = game.Players.LocalPlayer
    if not player or player == lp then return false end
    if player.Team and lp.Team and player.Team == lp.Team then return false end
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
        return true
    end
    return false
end

local function GetPlayers()
    local t = {}
    for _,plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if IsEnemy(plr) then
            table.insert(t, plr)
        end
    end
    return t
end

local function WorldToScreen(pos)
    local cam = workspace.CurrentCamera
    if not cam then return Vector3.zero, false end
    local screen, visible = cam:WorldToViewportPoint(pos)
    return screen, visible
end

local drawings = {}

local function ClearDrawings()
    for _, obj in ipairs(drawings) do
        pcall(function()
            obj.Visible = false
            if typeof(obj.Remove) == "function" then
                obj:Remove()
            elseif typeof(obj.Destroy) == "function" then
                obj:Destroy()
            end
        end)
    end
    drawings = {}
end

local function DrawBox(plr, color)
    if not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = plr.Character.HumanoidRootPart
    local size = Vector3.new(4,7,1.6)
    local corners = {
        Vector3.new(-size.X/2, size.Y/2, 0),
        Vector3.new(size.X/2, size.Y/2, 0),
        Vector3.new(size.X/2, -size.Y/2, 0),
        Vector3.new(-size.X/2, -size.Y/2, 0)
    }
    local points = {}
    for _, vec in ipairs(corners) do
        local pos, onscreen = WorldToScreen((hrp.CFrame * CFrame.new(vec)).Position)
        if onscreen then table.insert(points, pos) end
    end
    if #points == 4 then
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.From = Vector2.new(points[i].X, points[i].Y)
            l.To = Vector2.new(points[(i%4)+1].X, points[(i%4)+1].Y)
            l.Color = color
            l.Thickness = 2
            l.Transparency = 1
            l.Visible = ESP.enabled and ESP.box
            table.insert(drawings, l)
        end
    end
end

local function DrawName(plr, color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local screen, onscreen = WorldToScreen(head)
    if onscreen then
        local txt = Drawing.new("Text")
        txt.Text = plr.Name
        txt.Position = Vector2.new(screen.X, screen.Y-26)
        txt.Size = 16
        txt.Color = color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.name
        txt.Outline = true
        table.insert(drawings, txt)
    end
end

local function DrawDistance(plr, color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local lp = game.Players.LocalPlayer
    local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myhrp then return end
    local dist = (myhrp.Position - head).Magnitude
    local screen, onscreen = WorldToScreen(head)
    if onscreen then
        local txt = Drawing.new("Text")
        txt.Text = string.format("[%dm]", math.floor(dist))
        txt.Position = Vector2.new(screen.X, screen.Y-10)
        txt.Size = 13
        txt.Color = color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.distance
        txt.Outline = true
        table.insert(drawings, txt)
    end
end

local function DrawSkeleton(plr, color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local bones = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    for _, b in ipairs(bones) do
        local a = plr.Character:FindFirstChild(b[1])
        local c = plr.Character:FindFirstChild(b[2])
        if a and c then
            local apos, ao = WorldToScreen(a.Position)
            local cpos, co = WorldToScreen(c.Position)
            if ao and co then
                local l = Drawing.new("Line")
                l.From = Vector2.new(apos.X, apos.Y)
                l.To = Vector2.new(cpos.X, cpos.Y)
                l.Color = color
                l.Thickness = 2
                l.Transparency = 1
                l.Visible = ESP.enabled and ESP.skeleton
                table.insert(drawings, l)
            end
        end
    end
end

local function DrawHeadCircle(plr, color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local screen, onscreen = WorldToScreen(head)
    if onscreen then
        local cir = Drawing.new("Circle")
        cir.Position = Vector2.new(screen.X, screen.Y)
        cir.Color = color
        cir.Transparency = 1
        cir.Radius = 15
        cir.Thickness = 2
        cir.NumSides = 30
        cir.Filled = false
        cir.Visible = ESP.enabled and ESP.headcircle
        table.insert(drawings, cir)
    end
end

local function UpdateESP()
    ClearDrawings()
    if not ESP.enabled then return end
    for _, plr in ipairs(GetPlayers()) do
        if ESP.box then DrawBox(plr, ESP.color) end
        if ESP.name then DrawName(plr, ESP.color) end
        if ESP.distance then DrawDistance(plr, ESP.color) end
        if ESP.skeleton then DrawSkeleton(plr, ESP.color) end
        if ESP.headcircle then DrawHeadCircle(plr, ESP.color) end
    end
end
game:GetService("RunService").RenderStepped:Connect(UpdateESP)

local function GetClosestPart(character)
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local shortest, closest = math.huge, nil
    for _,partname in ipairs({"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftHand","RightHand","LeftFoot","RightFoot"}) do
        local part = character:FindFirstChild(partname)
        if part then
            local pos, onscreen = WorldToScreen(part.Position)
            if onscreen then
                local dist = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

local function GetAimbotTarget()
    local closest, minDist = nil, math.huge
    local mouse = game.Players.LocalPlayer:GetMouse()
    for _, plr in ipairs(GetPlayers()) do
        if plr.Character then
            local tpart
            if Aimbot.targetmode == "Head" then
                tpart = plr.Character:FindFirstChild("Head")
            elseif Aimbot.targetmode == "Body" then
                tpart = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("UpperTorso")
            elseif Aimbot.targetmode == "ClosestPart" then
                tpart = GetClosestPart(plr.Character)
            end
            if tpart then
                local pos, onScreen = WorldToScreen(tpart.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    if d < Aimbot.fov and d < minDist then
                        closest, minDist = plr, d
                    end
                end
            end
        end
    end
    return closest
end

local function AimbotLock()
    if not Aimbot.enabled then return end
    local target = GetAimbotTarget()
    if target and target.Character then
        local part
        if Aimbot.targetmode == "Head" then
            part = target.Character:FindFirstChild("Head")
        elseif Aimbot.targetmode == "Body" then
            part = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso")
        elseif Aimbot.targetmode == "ClosestPart" then
            part = GetClosestPart(target.Character)
        end
        if part then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, part.Position)
            Aimbot.target = target
        else
            Aimbot.target = nil
        end
    else
        Aimbot.target = nil
    end
end
game:GetService("RunService").RenderStepped:Connect(AimbotLock)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and Aimbot.enabled and Aimbot.silent and Aimbot.target and Aimbot.target.Character then
        local method = getnamecallmethod()
        if tostring(method) == "FireServer" and tostring(self) == "HitPart" then
            local args = {...}
            local part
            if Aimbot.targetmode == "Head" then
                part = Aimbot.target.Character and Aimbot.target.Character:FindFirstChild("Head")
            elseif Aimbot.targetmode == "Body" then
                part = Aimbot.target.Character and (Aimbot.target.Character:FindFirstChild("HumanoidRootPart") or Aimbot.target.Character:FindFirstChild("UpperTorso"))
            elseif Aimbot.targetmode == "ClosestPart" then
                part = GetClosestPart(Aimbot.target.Character)
            end
            if part and typeof(args[1]) == "Instance" and typeof(args[2]) == "Vector3" then
                args[1] = part
                args[2] = part.Position
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

local function CreatePasswordMenu(callback)
    for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name == "NebulaPasswordMenu" then pcall(function() g:Destroy() end) end
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaPasswordMenu"
    ProtectGui(gui)

    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.Position = UDim2.new(0.4,0,0.35,0)
    frame.Size = UDim2.new(0,330,0,138)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,44)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,0,0,8)
    title.Size = UDim2.new(1,0,0,23)
    title.Font = Enum.Font.GothamSemibold
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.Text = "NEBULA BLOXSTRIKE HİLE - Şifre"
    title.TextSize = 20

    local prompt = Instance.new("TextLabel")
    prompt.Parent = frame
    prompt.BackgroundTransparency = 1
    prompt.Position = UDim2.new(0,0,0,41)
    prompt.Size = UDim2.new(1,0,0,17)
    prompt.Font = Enum.Font.Gotham
    prompt.TextColor3 = Color3.fromRGB(180,220,255)
    prompt.Text = "Şifreyi giriniz:"
    prompt.TextSize = 16

    local input = Instance.new("TextBox")
    input.Parent = frame
    input.Position = UDim2.new(0.14,0,0,62)
    input.Size = UDim2.new(0.72,0,0,29)
    input.PlaceholderText = "Şifre"
    input.Font = Enum.Font.Gotham
    input.TextSize = 19
    input.BackgroundColor3 = Color3.fromRGB(38,44,60)
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.Text = ""
    input.ClearTextOnFocus = true
    input.BorderSizePixel = 0

    local info = Instance.new("TextLabel")
    info.Parent = frame
    info.Position = UDim2.new(0,0,1,-33)
    info.Size = UDim2.new(1,0,0,16)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 13
    info.TextColor3 = Color3.fromRGB(255,55,70)
    info.Text = ""

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.Position = UDim2.new(0.34,0,1,-31)
    btn.Size = UDim2.new(0.32,0,0,25)
    btn.BackgroundColor3 = Color3.fromRGB(52,160,190)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBlack
    btn.Text = "GİR"
    btn.TextSize = 16
    btn.BorderSizePixel = 0

    local accepted = false

    local function tryAccept()
        if tostring(input.Text) == "258631" and not accepted then
            accepted = true
            gui.Enabled = false
            gui:Destroy()
            if callback then callback() end
        else
            info.Text = "Hatalı şifre!"
        end
    end

    btn.MouseButton1Click:Connect(tryAccept)
    input.FocusLost:Connect(function(enter) if enter then tryAccept() end end)
    game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.Return then tryAccept() end
    end)

    gui.Parent = game:GetService("CoreGui")
    gui.Enabled = true
end

local function CreateMenu()
    for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name == "NebulaBloxstrikeMenu" then pcall(function() g:Destroy() end) end
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaBloxstrikeMenu"
    ProtectGui(gui)

    local main = Instance.new("Frame")
    main.Parent = gui
    main.Position = UDim2.new(0.32,0,0.14,0)
    main.Size = UDim2.new(0,460,0,523)
    main.BackgroundColor3 = Color3.fromRGB(14,17,31)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true

    local bar = Instance.new("Frame", main)
    bar.Size = UDim2.new(1, 0, 0, 42)
    bar.Position = UDim2.new(0,0,0,0)
    bar.BackgroundColor3 = Color3.fromRGB(16,34,62)
    bar.BorderSizePixel = 0

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1,0,0,42)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "[NEBULA] BLOXSTRIKE HİLE MENÜ"
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.TextSize = 18
    title.BackgroundTransparency = 1

    local close = Instance.new("TextButton", main)
    close.Size = UDim2.new(0,36,0,27)
    close.Position = UDim2.new(1,-40,0,7)
    close.Text = "✕"
    close.Font = Enum.Font.GothamBlack
    close.TextColor3 = Color3.fromRGB(255,40,46)
    close.TextSize = 20
    close.BackgroundColor3 = Color3.fromRGB(36,21,37)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local sep1 = Instance.new("Frame", main)
    sep1.Size = UDim2.new(0,3,0.83,0)
    sep1.Position = UDim2.new(0.5,-2,0.13,0)
    sep1.BackgroundColor3 = Color3.fromRGB(24,180,225)
    sep1.BorderSizePixel = 0

    local espsectitle = Instance.new("TextLabel", main)
    espsectitle.Text = "ESP (GÖRSEL) AYARLAR"
    espsectitle.Font = Enum.Font.GothamSemibold
    espsectitle.TextColor3 = Color3.fromRGB(0,255,255)
    espsectitle.TextSize = 17
    espsectitle.Position = UDim2.new(0.05,0,0.16,0)
    espsectitle.Size = UDim2.new(0.45,0,0,19)
    espsectitle.BackgroundTransparency = 1

    local aimsectitle = Instance.new("TextLabel", main)
    aimsectitle.Text = "AIMBOT / SİLAH AYARLARI"
    aimsectitle.Font = Enum.Font.GothamSemibold
    aimsectitle.TextColor3 = Color3.fromRGB(20,255,160)
    aimsectitle.TextSize = 17
    aimsectitle.Position = UDim2.new(0.53,0,0.16,0)
    aimsectitle.Size = UDim2.new(0.45,0,0,19)
    aimsectitle.BackgroundTransparency = 1

    local y0 = 84
    local yStep = 35
    local x1, x2 = 0.055, 0.56

    local function togglebtn(label, opt, ypos, section)
        local b = Instance.new("TextButton", main)
        b.Position = UDim2.new(section==1 and x1 or x2, 0, 0, ypos)
        b.Size = UDim2.new(0,163,0,26)
        b.Text = label.." : "..(((section==1 and ESP[opt]) or (section==2 and Aimbot[opt])) and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = (section==1 and (ESP[opt] and Color3.fromRGB(52,146,86) or Color3.fromRGB(52,45,62)))
          or (Aimbot[opt] and Color3.fromRGB(52,146,86) or Color3.fromRGB(52,45,62))
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamSemibold
        b.BorderSizePixel = 0
        b.TextSize = 15
        b.MouseButton1Click:Connect(function()
            if section == 1 then
                ESP[opt] = not ESP[opt]
                b.Text = label.." : "..(ESP[opt] and "AÇIK" or "KAPALI")
                b.BackgroundColor3 = ESP[opt] and Color3.fromRGB(52,146,86) or Color3.fromRGB(52,45,62)
            elseif section == 2 then
                Aimbot[opt] = not Aimbot[opt]
                b.Text = label.." : "..(Aimbot[opt] and "AÇIK" or "KAPALI")
                b.BackgroundColor3 = Aimbot[opt] and Color3.fromRGB(52,146,86) or Color3.fromRGB(52,45,62)
            end
        end)
        return b
    end

    togglebtn("ESP AKTİF", "enabled", y0, 1)
    togglebtn("Kutu (Box)", "box", y0+yStep, 1)
    togglebtn("Mesafe (Distance)", "distance", y0+2*yStep, 1)
    togglebtn("İsmi Göster", "name", y0+3*yStep, 1)
    togglebtn("Tüm İskelet", "skeleton", y0+4*yStep, 1)
    togglebtn("Head Circle", "headcircle", y0+5*yStep, 1)

    local clrLabel = Instance.new("TextLabel", main)
    clrLabel.Position = UDim2.new(x1,12,0,y0+6*yStep)
    clrLabel.Size = UDim2.new(0,92,0,23)
    clrLabel.Text = "ESP Rengi"
    clrLabel.Font = Enum.Font.GothamSemibold
    clrLabel.TextColor3 = Color3.fromRGB(255,255,255)
    clrLabel.TextSize = 14
    clrLabel.BackgroundTransparency = 1

    local clrBtn = Instance.new("TextButton", main)
    clrBtn.Position = UDim2.new(x1+0.29,0,0,y0+6*yStep)
    clrBtn.Size = UDim2.new(0,36,0,23)
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.Text = ""
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(60,255),math.random(60,255),math.random(60,255)
        ESP.color = Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    local targList = {"Head", "Body", "ClosestPart"}
    local tgLabel = Instance.new("TextLabel",main)
    tgLabel.Position = UDim2.new(x2,12,0,y0)
    tgLabel.Size = UDim2.new(0,68,0,24)
    tgLabel.Text = "Aimbot Hedef:"
    tgLabel.Font = Enum.Font.GothamSemibold
    tgLabel.TextColor3 = Color3.fromRGB(255,255,255)
    tgLabel.TextSize = 14
    tgLabel.BackgroundTransparency = 1

    local sel = Instance.new("TextButton",main)
    sel.Position = UDim2.new(x2+0.18,0,0,y0)
    sel.Size = UDim2.new(0,88,0,24)
    sel.Text = Aimbot.targetmode
    sel.BackgroundColor3 = Color3.fromRGB(32,80,96)
    sel.TextColor3 = Color3.fromRGB(255,255,255)
    sel.Font = Enum.Font.GothamSemibold
    sel.BorderSizePixel = 0
    sel.TextSize = 14
    sel.MouseButton1Click:Connect(function()
        local i = table.find(targList, Aimbot.targetmode) or 1
        i = (i % #targList) + 1
        Aimbot.targetmode = targList[i]
        sel.Text = Aimbot.targetmode
    end)

    togglebtn("Aimbot AKTİF", "enabled", y0+2*yStep, 2)
    togglebtn("SilentAim AKTİF", "silent", y0+3*yStep+5, 2)

    local fovl = Instance.new("TextLabel", main)
    fovl.Position = UDim2.new(x2,12,0,y0+5*yStep+2)
    fovl.Size = UDim2.new(0,55,0,22)
    fovl.BackgroundTransparency = 1
    fovl.Text = "FOV:"
    fovl.Font = Enum.Font.GothamSemibold
    fovl.TextColor3 = Color3.fromRGB(255,255,255)
    fovl.TextSize = 14

    local fovb = Instance.new("TextBox", main)
    fovb.Position = UDim2.new(x2+0.18,0,0,y0+5*yStep+0)
    fovb.Size = UDim2.new(0,54,0,22)
    fovb.Text = tostring(Aimbot.fov)
    fovb.BackgroundColor3 = Color3.fromRGB(46,39,60)
    fovb.TextColor3 = Color3.fromRGB(255,255,255)
    fovb.Font = Enum.Font.GothamSemibold
    fovb.ClearTextOnFocus = false
    fovb.BorderSizePixel = 0
    fovb.TextSize = 14
    fovb.FocusLost:Connect(function()
        local v = tonumber(fovb.Text)
        if v and v <= 650 and v >= 10 then
            Aimbot.fov = v
        else
            fovb.Text = tostring(Aimbot.fov)
        end
    end)

    local keylbl = Instance.new("TextLabel", main)
    keylbl.Text = "Menüyü aç/kapat: Insert tuşu"
    keylbl.Font = Enum.Font.GothamSemibold
    keylbl.TextColor3 = Color3.fromRGB(160,180,245)
    keylbl.TextSize = 13
    keylbl.Position = UDim2.new(0.04,0,1,-28)
    keylbl.Size = UDim2.new(0.93,0,0,17)
    keylbl.BackgroundTransparency = 1

    local notice = Instance.new("TextLabel", main)
    notice.Text = "Nebula Bloxstrike | discord.gg/nebula-hub"
    notice.Font = Enum.Font.GothamSemibold
    notice.TextColor3 = Color3.fromRGB(54,255,220)
    notice.TextSize = 12
    notice.Position = UDim2.new(0.10,0,1,-13)
    notice.Size = UDim2.new(0.82,0,0,13)
    notice.BackgroundTransparency = 1

    gui.Parent = game:GetService("CoreGui")
    gui.Enabled = true
end

CreatePasswordMenu(function()
    CreateMenu()
end)

game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        local main = game:GetService("CoreGui"):FindFirstChild("NebulaBloxstrikeMenu")
        if main then
            main.Enabled = not main.Enabled
        else
            CreateMenu()
        end
    end
end)

if type(syn) == "table" and syn.protect_gui then
    getgenv().ProtectGui = syn.protect_gui
else
    getgenv().ProtectGui = function(g) pcall(function() g.Parent = game:GetService("CoreGui") end) end
end

local bypass
bypass = hookfunction(debug.getupvalue, function(...) return true end)

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
    if player == game.Players.LocalPlayer then return false end
    if player.Team ~= nil and game.Players.LocalPlayer.Team ~= nil then
        if player.Team == game.Players.LocalPlayer.Team then return false end
    end
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    and player.Character:FindFirstChild("HumanoidRootPart")
    and player.Character:FindFirstChild("Head")
    and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
    then
        return true
    end
    return false
end

local function GetPlayers()
    local t = {}
    for _,plr in ipairs(game.Players:GetPlayers()) do
        if IsEnemy(plr) then
            table.insert(t,plr)
        end
    end
    return t
end

local function WorldToScreen(pos)
    local cam = workspace.CurrentCamera
    local screen, onScreen = cam:WorldToViewportPoint(pos)
    return screen,onScreen
end

local drawings = {}

local function ClearDrawings()
    for _,d in ipairs(drawings) do pcall(function() d.Visible = false d:Remove() end) end
    drawings = {}
end

local function DrawBox(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = plr.Character.HumanoidRootPart
    local size = Vector3.new(4,7,1.6)
    local corners = {
        hrp.CFrame * CFrame.new(-size.X/2,size.Y/2,0).Position,
        hrp.CFrame * CFrame.new(size.X/2,size.Y/2,0).Position,
        hrp.CFrame * CFrame.new(size.X/2,-size.Y/2,0).Position,
        hrp.CFrame * CFrame.new(-size.X/2,-size.Y/2,0).Position,
    }
    local points = {}
    for _,corner in ipairs(corners) do
        local pt,os = WorldToScreen(corner)
        if os then table.insert(points,pt) end
    end
    if #points==4 then
        local l1 = Drawing.new("Line")
        l1.From = Vector2.new(points[1].X, points[1].Y)
        l1.To   = Vector2.new(points[2].X, points[2].Y)
        l1.Color = color
        l1.Thickness = 2
        l1.Transparency = 1
        l1.Visible = ESP.enabled and ESP.box
        table.insert(drawings,l1)
        local l2 = Drawing.new("Line")
        l2.From = Vector2.new(points[2].X, points[2].Y)
        l2.To   = Vector2.new(points[3].X, points[3].Y)
        l2.Color = color
        l2.Thickness = 2
        l2.Transparency = 1
        l2.Visible = ESP.enabled and ESP.box
        table.insert(drawings,l2)
        local l3 = Drawing.new("Line")
        l3.From = Vector2.new(points[3].X, points[3].Y)
        l3.To   = Vector2.new(points[4].X, points[4].Y)
        l3.Color = color
        l3.Thickness = 2
        l3.Transparency = 1
        l3.Visible = ESP.enabled and ESP.box
        table.insert(drawings,l3)
        local l4 = Drawing.new("Line")
        l4.From = Vector2.new(points[4].X, points[4].Y)
        l4.To   = Vector2.new(points[1].X, points[1].Y)
        l4.Color = color
        l4.Thickness = 2
        l4.Transparency = 1
        l4.Visible = ESP.enabled and ESP.box
        table.insert(drawings,l4)
    end
end

local function DrawName(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local s,os = WorldToScreen(head)
    if os then
        local txt = Drawing.new("Text")
        txt.Text = plr.Name
        txt.Position = Vector2.new(s.X,s.Y-26)
        txt.Size = 16
        txt.Color = color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.name
        txt.Outline = true
        table.insert(drawings,txt)
    end
end

local function DrawDistance(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local plrpos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not plrpos then return end
    local dist = (plrpos.Position - head).Magnitude
    local s,os = WorldToScreen(head)
    if os then
        local txt = Drawing.new("Text")
        txt.Text = "["..math.floor(dist).."m]"
        txt.Position = Vector2.new(s.X,s.Y-10)
        txt.Size = 13
        txt.Color = color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.distance
        txt.Outline = true
        table.insert(drawings,txt)
    end
end

local function DrawSkeleton(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local bones = {
        {"Head","UpperTorso"},
        {"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    for _,pair in ipairs(bones) do
        local a = plr.Character:FindFirstChild(pair[1])
        local b = plr.Character:FindFirstChild(pair[2])
        if a and b then
            local aPos,ao = WorldToScreen(a.Position)
            local bPos,bo = WorldToScreen(b.Position)
            if ao and bo then
                local l = Drawing.new("Line")
                l.From = Vector2.new(aPos.X,aPos.Y)
                l.To = Vector2.new(bPos.X,bPos.Y)
                l.Color = color
                l.Thickness = 2
                l.Transparency = 1
                l.Visible = ESP.enabled and ESP.skeleton
                table.insert(drawings,l)
            end
        end
    end
end

local function DrawHeadCircle(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local s,os = WorldToScreen(head)
    if os then
        local cir = Drawing.new("Circle")
        cir.Position = Vector2.new(s.X,s.Y)
        cir.Color = color
        cir.Transparency = 1
        cir.Radius = 15
        cir.Thickness = 2
        cir.NumSides = 30
        cir.Filled = false
        cir.Visible = ESP.enabled and ESP.headcircle
        table.insert(drawings,cir)
    end
end

local function UpdateESP()
    ClearDrawings()
    if not ESP.enabled then return end
    for _,plr in ipairs(GetPlayers()) do
        if ESP.box then DrawBox(plr,ESP.color) end
        if ESP.name then DrawName(plr,ESP.color) end
        if ESP.distance then DrawDistance(plr,ESP.color) end
        if ESP.skeleton then DrawSkeleton(plr,ESP.color) end
        if ESP.headcircle then DrawHeadCircle(plr,ESP.color) end
    end
end

game:GetService("RunService").RenderStepped:Connect(UpdateESP)

local function GetClosestPart(character)
    local parts = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftHand","RightHand","LeftFoot","RightFoot"}
    local shortest = math.huge
    local best = nil
    local cam = workspace.CurrentCamera
    local mouse = game.Players.LocalPlayer:GetMouse()
    for _,partname in ipairs(parts) do
        local part = character:FindFirstChild(partname)
        if part then
            local pos,onScreen = WorldToScreen(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                if dist < shortest then
                    shortest = dist
                    best = part
                end
            end
        end
    end
    return best
end

local function GetAimbotTarget()
    local closest,dist = nil,math.huge
    local mouse = game.Players.LocalPlayer:GetMouse()
    for _,plr in ipairs(GetPlayers()) do
        if plr.Character then
            local targetPart
            if Aimbot.targetmode == "Head" then
                targetPart = plr.Character:FindFirstChild("Head")
            elseif Aimbot.targetmode == "Body" then
                targetPart = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("UpperTorso")
            elseif Aimbot.targetmode == "ClosestPart" then
                targetPart = GetClosestPart(plr.Character)
            end
            if targetPart then
                local pos,onScreen = WorldToScreen(targetPart.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                    if d < Aimbot.fov and d < dist then
                        closest = plr
                        dist = d
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
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position,part.Position)
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

local function CreatePasswordMenu(onSuccess)
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name == "NebulaPasswordMenu" then g:Destroy() end end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaPasswordMenu"
    ProtectGui(gui)
    gui.Enabled = true
    
    local frame = Instance.new("Frame",gui)
    frame.Position = UDim2.new(0.37,0,0.36,0)
    frame.Size = UDim2.new(0,290,0,161)
    frame.BackgroundColor3 = Color3.fromRGB(27,27,40)
    frame.BorderSizePixel = 0
    frame.Name = "PasswordFrame"
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel",frame)
    title.Text = "NEBULA Bloxstrike Hilesi"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.Size = UDim2.new(1,0,0,36)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1

    local label = Instance.new("TextLabel",frame)
    label.Text = "Şifre Giriniz:"
    label.Font = Enum.Font.SourceSansBold
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Size = UDim2.new(1, -20, 0, 26)
    label.TextSize = 19
    label.Position = UDim2.new(0,10,0,37)
    label.BackgroundTransparency = 1

    local input = Instance.new("TextBox",frame)
    input.Size = UDim2.new(0.75,0,0,30)
    input.Position = UDim2.new(0.13,0,0,68)
    input.PlaceholderText = "Şifre"
    input.Font = Enum.Font.SourceSansBold
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.BackgroundColor3 = Color3.fromRGB(40,40,46)
    input.BorderSizePixel = 0
    input.TextSize = 21
    input.ClearTextOnFocus = true

    local uis = game:GetService("UserInputService")

    local info = Instance.new("TextLabel",frame)
    info.Size = UDim2.new(1,0,0,23)
    info.Position = UDim2.new(0,0,1,-49)
    info.BackgroundTransparency = 1
    info.Text = ""
    info.Font = Enum.Font.SourceSans
    info.TextColor3 = Color3.fromRGB(255, 45, 45)
    info.TextSize = 17

    local btn = Instance.new("TextButton",frame)
    btn.Text = "Giriş Yap"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Size = UDim2.new(0.75,0,0,28)
    btn.Position = UDim2.new(0.13,0,1,-38)
    btn.BackgroundColor3 = Color3.fromRGB(38,140,170)
    btn.BorderSizePixel = 0

    local accepted = false

    btn.MouseButton1Click:Connect(function()
        if tostring(input.Text) == "258631" then
            accepted = true
            gui.Enabled = false
            gui:Destroy()
            onSuccess()
        else
            info.Text = "Hatalı şifre!"
        end
    end)
    input.FocusLost:Connect(function(e)
        if e and tostring(input.Text) == "258631" and not accepted then
            accepted = true
            gui.Enabled = false
            gui:Destroy()
            onSuccess()
        elseif e and not accepted then
            info.Text = "Hatalı şifre!"
        end
    end)
    uis.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.Return then
            if tostring(input.Text) == "258631" and not accepted then
                accepted = true
                gui.Enabled = false
                gui:Destroy()
                onSuccess()
            elseif not accepted then
                info.Text = "Hatalı şifre!"
            end
        end
    end)
end

local function CreateMenu()
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name == "NebulaBloxstrikeMenu" then g:Destroy() end end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaBloxstrikeMenu"
    ProtectGui(gui)
    gui.Enabled = true

    local main = Instance.new("Frame",gui)
    main.Position = UDim2.new(0.25,0,0.14,0)
    main.Size = UDim2.new(0,440,0,495)
    main.BackgroundColor3 = Color3.fromRGB(24,26,46)
    main.BorderSizePixel = 0
    main.Name = "Main"
    main.Active = true
    main.Draggable = true

    local bar = Instance.new("Frame", main)
    bar.Size = UDim2.new(1,0,0,41)
    bar.Position = UDim2.new(0,0,0,0)
    bar.BackgroundColor3 = Color3.fromRGB(30,52,80)
    bar.BorderSizePixel = 0

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1,0,0,39)
    title.Position = UDim2.new(0,0,0,2)
    title.Text = "[NEBULA] BLOXSTRIKE HİLE MENÜSÜ"
    title.Font = Enum.Font.FredokaOne
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.BackgroundTransparency = 1

    local close = Instance.new("TextButton",main)
    close.Size = UDim2.new(0,27,0,27)
    close.Position = UDim2.new(1,-31,0,7)
    close.Text = "✕"
    close.Font = Enum.Font.FredokaOne
    close.TextColor3 = Color3.fromRGB(255,40,46)
    close.TextSize = 24
    close.BackgroundColor3 = Color3.fromRGB(32,24,38)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local t1 = Instance.new("TextLabel",main)
    t1.Text = "ESP"
    t1.Font = Enum.Font.FredokaOne
    t1.TextColor3 = Color3.fromRGB(0,255,255)
    t1.TextSize = 19
    t1.Position = UDim2.new(0.05,0,0,60)
    t1.Size = UDim2.new(0,85,0,23)
    t1.BackgroundTransparency = 1

    local t2 = Instance.new("TextLabel",main)
    t2.Text = "AIMBOT"
    t2.Font = Enum.Font.FredokaOne
    t2.TextColor3 = Color3.fromRGB(0,255,175)
    t2.TextSize = 19
    t2.Position = UDim2.new(0.51,0,0,60)
    t2.Size = UDim2.new(0,110,0,23)
    t2.BackgroundTransparency = 1

    local y = 100
    local function btn(label, opt, ypos, section)
        local parent = main
        local b = Instance.new("TextButton", parent)
        b.Position = UDim2.new(section==1 and 0.05 or 0.5, 0, 0, ypos)
        b.Size = UDim2.new(0,165,0,34)
        b.Text = label..": "..((section==1 and ESP[opt]) or (section==2 and Aimbot[opt]) and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = section==1 and (ESP[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(59,47,70))
                           or (Aimbot[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(59,47,70))
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.FredokaOne
        b.BorderSizePixel = 0
        b.TextSize = 19
        b.MouseButton1Click:Connect(function()
            if section == 1 then
                ESP[opt] = not ESP[opt]
                b.Text = label..": "..(ESP[opt] and "AÇIK" or "KAPALI")
                b.BackgroundColor3 = ESP[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(59,47,70)
            elseif section == 2 then
                Aimbot[opt] = not Aimbot[opt]
                b.Text = label..": "..(Aimbot[opt] and "AÇIK" or "KAPALI")
                b.BackgroundColor3 = Aimbot[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(59,47,70)
            end
        end)
        return b
    end

    btn("ESP Aç/Kapat","enabled",y,1)
    btn("Kutu (Box)","box",y+42,1)
    btn("Mesafe (Distance)","distance",y+84,1)
    btn("İsim Göster","name",y+126,1)
    btn("Tüm İskelet","skeleton",y+168,1)
    btn("Head Circle","headcircle",y+210,1)

    local clrLabel = Instance.new("TextLabel",main)
    clrLabel.Position = UDim2.new(0.05,5,0,y+252)
    clrLabel.Size = UDim2.new(0,105,0,25)
    clrLabel.Text = "Renk Ayarla"
    clrLabel.Font = Enum.Font.FredokaOne
    clrLabel.TextColor3 = Color3.fromRGB(255,255,255)
    clrLabel.TextSize = 18
    clrLabel.BackgroundTransparency = 1

    local clrBtn = Instance.new("TextButton",main)
    clrBtn.Position = UDim2.new(0.20,0,0,y+252)
    clrBtn.Size = UDim2.new(0,43,0,25)
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.Text = ""
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(60,255),math.random(60,255),math.random(60,255)
        ESP.color = Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    local list = {"Head","Body","ClosestPart"}
    local lb = Instance.new("TextLabel",main)
    lb.Position = UDim2.new(0.5,5,0,y)
    lb.Size = UDim2.new(0,61,0,33)
    lb.Text = "Hedef:"
    lb.Font = Enum.Font.FredokaOne
    lb.TextColor3 = Color3.fromRGB(255,255,255)
    lb.TextSize = 17
    lb.BackgroundTransparency = 1

    local sel = Instance.new("TextButton",main)
    sel.Position = UDim2.new(0.59,0,0,y)
    sel.Size = UDim2.new(0,97,0,33)
    sel.Text = Aimbot.targetmode
    sel.BackgroundColor3 = Color3.fromRGB(30,75,90)
    sel.TextColor3 = Color3.fromRGB(255,255,255)
    sel.Font = Enum.Font.FredokaOne
    sel.BorderSizePixel = 0
    sel.TextSize = 17
    sel.MouseButton1Click:Connect(function()
        local i = table.find(list,Aimbot.targetmode) or 1
        i = i+1> #list and 1 or i+1
        Aimbot.targetmode = list[i]
        sel.Text = Aimbot.targetmode
    end)

    btn("Aimbot Aç/Kapat","enabled",y+54,2)
    btn("SilentAim Aç/Kapat","silent",y+108,2)

    local fovl = Instance.new("TextLabel",main)
    fovl.Position = UDim2.new(0.5,5,0,y+162)
    fovl.Size = UDim2.new(0,45,0,29)
    fovl.BackgroundTransparency = 1
    fovl.Text = "FOV:"
    fovl.Font = Enum.Font.FredokaOne
    fovl.TextColor3 = Color3.fromRGB(255,255,255)
    fovl.TextSize = 17

    local fovb = Instance.new("TextBox",main)
    fovb.Position = UDim2.new(0.62,0,0,y+162)
    fovb.Size = UDim2.new(0,77,0,29)
    fovb.Text = tostring(Aimbot.fov)
    fovb.BackgroundColor3 = Color3.fromRGB(44,38,60)
    fovb.TextColor3 = Color3.fromRGB(255,255,255)
    fovb.Font = Enum.Font.FredokaOne
    fovb.ClearTextOnFocus = false
    fovb.BorderSizePixel = 0
    fovb.TextSize = 17
    fovb.FocusLost:Connect(function()
        local v = tonumber(fovb.Text)
        if v and v <= 650 and v >= 10 then
            Aimbot.fov = v
        else
            fovb.Text = tostring(Aimbot.fov)
        end
    end)
end

CreatePasswordMenu(CreateMenu)

game:GetService("UserInputService").InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        local main = game.CoreGui:FindFirstChild("NebulaBloxstrikeMenu")
        if main then
            main.Enabled = not main.Enabled
        else
            CreateMenu()
        end
    end
end)

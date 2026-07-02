if type(syn) == "table" and syn.protect_gui then
    getgenv().ProtectGui = syn.protect_gui
else
    getgenv().ProtectGui = function(g) pcall(function() g.Parent = game:GetService("CoreGui") end) end
end

local bypass
bypass = hookfunction(debug.getupvalue, function(...)
    return true
end)

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

local function CreateMenu()
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name == "NebulaBloxstrikeMenu" then g:Destroy() end end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NebulaBloxstrikeMenu"
    ProtectGui(gui)
    
    local frame = Instance.new("Frame",gui)
    frame.Position = UDim2.new(0.08,0,0.13,0)
    frame.Size = UDim2.new(0,330,0,410)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel",frame)
    title.Text = "[NEBULA] BLOXSTRIKE HİLE MENÜSÜ"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.Size = UDim2.new(1,0,0,34)
    title.BackgroundTransparency = 1

    local sep1 = Instance.new("Frame",frame)
    sep1.Position = UDim2.new(0,10,0,40)
    sep1.Size = UDim2.new(0,310,0,2)
    sep1.BackgroundColor3 = Color3.fromRGB(0,255,255)
    sep1.BorderSizePixel = 0

    local x = 14
    local y = 56

    local espsec = Instance.new("TextLabel",frame)
    espsec.Text = "ESP Seçenekleri"
    espsec.Position = UDim2.new(0,x,0,y)
    espsec.Size = UDim2.new(0,145,0,20)
    espsec.Font = Enum.Font.SourceSansSemibold
    espsec.TextColor3 = Color3.fromRGB(0,255,255)
    espsec.TextXAlignment = Enum.TextXAlignment.Left
    espsec.BackgroundTransparency = 1

    y = y + 24
    local function ToggleButton(label, opt)
        local btn = Instance.new("TextButton",frame)
        btn.Position = UDim2.new(0,x,0,y)
        btn.Size = UDim2.new(0,135,0,25)
        btn.Text = label..": "..(ESP[opt] and "AÇIK" or "KAPALI")
        btn.BackgroundColor3 = ESP[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(90,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.SourceSansBold
        btn.MouseButton1Click:Connect(function()
            ESP[opt] = not ESP[opt]
            btn.Text = label..": "..(ESP[opt] and "AÇIK" or "KAPALI")
            btn.BackgroundColor3 = ESP[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(90,40,40)
        end)
        y = y + 27
        return btn
    end

    local _ = ToggleButton("ESP Aç/Kapat","enabled")
    ToggleButton("Kutu (Box)","box")
    ToggleButton("İsim Göster","name")
    ToggleButton("Mesafe","distance")
    ToggleButton("Tüm İskelet","skeleton")
    ToggleButton("Head Circle","headcircle")

    -- Color picker
    local clrLabel = Instance.new("TextLabel",frame)
    clrLabel.Position = UDim2.new(0,x,0,y)
    clrLabel.Size = UDim2.new(0,70,0,24)
    clrLabel.Text = "Renk Ayarla"
    clrLabel.Font = Enum.Font.SourceSans
    clrLabel.TextColor3 = Color3.fromRGB(255,255,255)
    clrLabel.BackgroundTransparency = 1

    local clrBtn = Instance.new("TextButton",frame)
    clrBtn.Position = UDim2.new(0,x+80,0,y)
    clrBtn.Size = UDim2.new(0,48,0,24)
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.Text = ""
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(80,255),math.random(80,255),math.random(80,255)
        ESP.color = Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    y = y + 34

    local sep2 = Instance.new("Frame",frame)
    sep2.Position = UDim2.new(0,x,0,y)
    sep2.Size = UDim2.new(0,270,0,2)
    sep2.BackgroundColor3 = Color3.fromRGB(0,255,255)
    sep2.BorderSizePixel = 0
    y = y + 15

    -- aimbot section
    local aimsec = Instance.new("TextLabel",frame)
    aimsec.Text = "AIMBOT Seçenekleri"
    aimsec.Position = UDim2.new(0,x,0,y)
    aimsec.Size = UDim2.new(0,145,0,20)
    aimsec.Font = Enum.Font.SourceSansSemibold
    aimsec.TextColor3 = Color3.fromRGB(0,255,255)
    aimsec.TextXAlignment = Enum.TextXAlignment.Left
    aimsec.BackgroundTransparency = 1
    y = y + 23

    local function AimbotToggleButton(label,opt)
        local b = Instance.new("TextButton",frame)
        b.Position = UDim2.new(0,x,0,y)
        b.Size = UDim2.new(0,135,0,25)
        b.Text = label..": "..(Aimbot[opt] and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = Aimbot[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(90,40,40)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.SourceSansBold
        b.MouseButton1Click:Connect(function()
            Aimbot[opt] = not Aimbot[opt]
            b.Text = label..": "..(Aimbot[opt] and "AÇIK" or "KAPALI")
            b.BackgroundColor3 = Aimbot[opt] and Color3.fromRGB(55,150,85) or Color3.fromRGB(90,40,40)
        end)
        y = y + 27
        return b
    end

    local __ = AimbotToggleButton("Aimbot Aç/Kapat","enabled")
    AimbotToggleButton("SilentAim Aç/Kapat","silent")

    -- Target mode selector
    local modes = {"Head","Body","ClosestPart"}
    local mlabel = Instance.new("TextLabel",frame)
    mlabel.Position = UDim2.new(0,x,0,y)
    mlabel.Size = UDim2.new(0,63,0,24)
    mlabel.Text = "Hedef:"
    mlabel.Font = Enum.Font.SourceSans
    mlabel.TextColor3 = Color3.fromRGB(255,255,255)
    mlabel.BackgroundTransparency = 1

    local modeBtn = Instance.new("TextButton",frame)
    modeBtn.Position = UDim2.new(0,x+58,0,y)
    modeBtn.Size = UDim2.new(0,78,0,24)
    modeBtn.Text = Aimbot.targetmode
    modeBtn.BackgroundColor3 = Color3.fromRGB(35,72,90)
    modeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    modeBtn.Font = Enum.Font.SourceSansBold
    modeBtn.MouseButton1Click:Connect(function()
        local i = table.find(modes,Aimbot.targetmode) or 1
        i = i+1> #modes and 1 or i+1
        Aimbot.targetmode = modes[i]
        modeBtn.Text = Aimbot.targetmode
    end)

    y = y + 32

    local fovLabel = Instance.new("TextLabel",frame)
    fovLabel.Position = UDim2.new(0,x,0,y)
    fovLabel.Size = UDim2.new(0,45,0,23)
    fovLabel.Text = "FOV:"
    fovLabel.Font = Enum.Font.SourceSans
    fovLabel.TextColor3 = Color3.fromRGB(255,255,255)
    fovLabel.BackgroundTransparency = 1

    local fovBox = Instance.new("TextBox",frame)
    fovBox.Position = UDim2.new(0,x+48,0,y)
    fovBox.Size = UDim2.new(0,56,0,23)
    fovBox.Text = tostring(Aimbot.fov)
    fovBox.BackgroundColor3 = Color3.fromRGB(44,38,60)
    fovBox.TextColor3 = Color3.fromRGB(255,255,255)
    fovBox.Font = Enum.Font.SourceSansBold
    fovBox.ClearTextOnFocus = false
    fovBox.FocusLost:Connect(function()
        local v = tonumber(fovBox.Text)
        if v and v <= 650 and v >= 10 then
            Aimbot.fov = v
        else
            fovBox.Text = tostring(Aimbot.fov)
        end
    end)
end

CreateMenu()

game:GetService("UserInputService").InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        local gui = game.CoreGui:FindFirstChild("NebulaBloxstrikeMenu")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end
end)

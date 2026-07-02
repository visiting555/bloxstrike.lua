local ESP = {
    enabled = false,
    box = false,
    distance = false,
    name = false,
    skeleton = false,
    headcircle = false,
    color = Color3.new(1,1,1),
}

local Aimbot = {
    enabled = false,
    silent = false,
    fov = 100,
    target = nil,
}

local function IsEnemy(player)
    if player == game.Players.LocalPlayer then return false end
    if player.Team == game.Players.LocalPlayer.Team then return false end
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
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

local function DrawBox(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = plr.Character.HumanoidRootPart
    local size = Vector3.new(4,7,1)
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
        Drawing.new("Line"){From=points[1],To=points[2],Color=color,Thickness=2,Transparency=1}.Visible = ESP.enabled and ESP.box
        Drawing.new("Line"){From=points[2],To=points[3],Color=color,Thickness=2,Transparency=1}.Visible = ESP.enabled and ESP.box
        Drawing.new("Line"){From=points[3],To=points[4],Color=color,Thickness=2,Transparency=1}.Visible = ESP.enabled and ESP.box
        Drawing.new("Line"){From=points[4],To=points[1],Color=color,Thickness=2,Transparency=1}.Visible = ESP.enabled and ESP.box
    end
end

local function DrawName(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local s,os = WorldToScreen(head)
    if os then
        local txt = Drawing.new("Text")
        txt.Text = plr.Name
        txt.Position = Vector2.new(s.X,s.Y-24)
        txt.Size = 16
        txt.Color = color or ESP.color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.name
        txt.Outline = true
    end
end

local function DrawDistance(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head.Position
    local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - head).Magnitude
    local s,os = WorldToScreen(head)
    if os then
        local txt = Drawing.new("Text")
        txt.Text = "["..math.floor(dist).."m]"
        txt.Position = Vector2.new(s.X,s.Y-10)
        txt.Size = 14
        txt.Color = color or ESP.color
        txt.Center = true
        txt.Visible = ESP.enabled and ESP.distance
        txt.Outline = true
    end
end

local function DrawSkeleton(plr,color)
    if not (plr.Character and plr.Character:FindFirstChild("Humanoid")) then return end
    local bones = {
        {"Head","UpperTorso"},
        {"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},
        {"LeftUpperArm","LeftLowerArm"},
        {"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},
        {"RightUpperArm","RightLowerArm"},
        {"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},
        {"LeftUpperLeg","LeftLowerLeg"},
        {"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},
        {"RightUpperLeg","RightLowerLeg"},
        {"RightLowerLeg","RightFoot"},
    }
    for _,pair in ipairs(bones) do
        local a = plr.Character:FindFirstChild(pair[1])
        local b = plr.Character:FindFirstChild(pair[2])
        if a and b then
            local aPos,ao = WorldToScreen(a.Position)
            local bPos,bo = WorldToScreen(b.Position)
            if ao and bo then
                Drawing.new("Line"){
                    From = Vector2.new(aPos.X,aPos.Y),
                    To = Vector2.new(bPos.X,bPos.Y),
                    Color = color or ESP.color,
                    Thickness = 2,
                    Transparency = 1,
                    Visible = ESP.enabled and ESP.skeleton,
                }
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
        cir.Color = color or ESP.color
        cir.Transparency = 1
        cir.Radius = 15
        cir.Thickness = 2
        cir.NumSides = 30
        cir.Filled = false
        cir.Visible = ESP.enabled and ESP.headcircle
    end
end

local function UpdateESP()
    for _,plr in ipairs(GetPlayers()) do
        if ESP.box then DrawBox(plr,ESP.color) end
        if ESP.name then DrawName(plr,ESP.color) end
        if ESP.distance then DrawDistance(plr,ESP.color) end
        if ESP.skeleton then DrawSkeleton(plr,ESP.color) end
        if ESP.headcircle then DrawHeadCircle(plr,ESP.color) end
    end
end

game:GetService("RunService").RenderStepped:Connect(UpdateESP)

local function GetClosestEnemyToMouse()
    local closest,dist = nil,math.huge
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    for _,plr in ipairs(GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("Head") then
            local pos,onscreen = WorldToScreen(plr.Character.Head.Position)
            if onscreen then
                local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                if d < Aimbot.fov and d < dist then
                    closest = plr
                    dist = d
                end
            end
        end
    end
    return closest
end

local function AimbotLock()
    if not Aimbot.enabled then return end
    local target = GetClosestEnemyToMouse()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local cam = workspace.CurrentCamera
        local head = target.Character.Head.Position
        cam.CFrame = CFrame.new(cam.CFrame.Position,head)
        Aimbot.target = target
    else
        Aimbot.target = nil
    end
end

game:GetService("RunService").RenderStepped:Connect(AimbotLock)

local oldNamecall = nil
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and ESP.enabled and Aimbot.silent and Aimbot.enabled and Aimbot.target then
        local method = getnamecallmethod()
        if tostring(method) == "FireServer" and tostring(self) == "HitPart" then
            local args = {...}
            if typeof(args[1]) == "Instance" and typeof(args[2]) == "Vector3" then
                local head = Aimbot.target.Character and Aimbot.target.Character:FindFirstChild("Head")
                if head then
                    args[1] = head
                    args[2] = head.Position
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

local function EspMenu()
    local gui = Instance.new("ScreenGui",game.CoreGui)
    gui.Name = "NebulaBloxStrikeESP"
    local frame = Instance.new("Frame",gui)
    frame.Position = UDim2.new(0.05,0,0.1,0)
    frame.Size = UDim2.new(0,280,0,340)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    local title = Instance.new("TextLabel",frame)
    title.Text = "[NEBULA] BloxStrike Hile"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(0,255,255)
    title.Size = UDim2.new(1,0,0,32)
    title.BackgroundTransparency = 1

    local y = 40

    local function ToggleButton(name,property)
        local btn = Instance.new("TextButton",frame)
        btn.Position = UDim2.new(0,10,0,y)
        btn.Size = UDim2.new(0,110,0,26)
        btn.Text = name..": " .. (ESP[property] and "Açık" or "Kapalı")
        btn.BackgroundColor3 = ESP[property] and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.SourceSans
        btn.MouseButton1Click:Connect(function()
            ESP[property] = not ESP[property]
            btn.Text = name..": " .. (ESP[property] and "Açık" or "Kapalı")
            btn.BackgroundColor3 = ESP[property] and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
        end)
        y = y + 30
        return btn
    end

    ToggleButton("ESP Aç/Kapat","enabled")
    ToggleButton("Box","box")
    ToggleButton("Mesafe","distance")
    ToggleButton("İsim","name")
    ToggleButton("İskelet","skeleton")
    ToggleButton("Head Circle","headcircle")

    local colorlbl = Instance.new("TextLabel",frame)
    colorlbl.Position = UDim2.new(0,10,0,y)
    colorlbl.Size = UDim2.new(0,95,0,26)
    colorlbl.Text = "Renk Ayarla"
    colorlbl.Font = Enum.Font.SourceSans
    colorlbl.BackgroundTransparency = 1
    colorlbl.TextColor3 = Color3.fromRGB(255,255,255)

    local colP = Instance.new("TextButton",frame)
    colP.Position = UDim2.new(0,110,0,y)
    colP.Size = UDim2.new(0,40,0,26)
    colP.BackgroundColor3 = ESP.color
    colP.Text = ""
    colP.MouseButton1Click:Connect(function()
        local r,g,b = math.random(),math.random(),math.random()
        ESP.color = Color3.new(r,g,b)
        colP.BackgroundColor3 = ESP.color
    end)
    y = y + 32

    local abox = Instance.new("TextButton",frame)
    abox.Position = UDim2.new(0,10,0,y)
    abox.Size = UDim2.new(0,120,0,28)
    abox.Text = "Aimbot Aç/Kapat"
    abox.Font = Enum.Font.SourceSansBold
    abox.TextColor3 = Color3.fromRGB(255,255,255)
    abox.BackgroundColor3 = Aimbot.enabled and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
    abox.MouseButton1Click:Connect(function()
        Aimbot.enabled = not Aimbot.enabled
        abox.BackgroundColor3 = Aimbot.enabled and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
    end)

    local sbox = Instance.new("TextButton",frame)
    sbox.Position = UDim2.new(0,140,0,y)
    sbox.Size = UDim2.new(0,120,0,28)
    sbox.Text = "SilentAim Aç/Kapat"
    sbox.Font = Enum.Font.SourceSansBold
    sbox.TextColor3 = Color3.fromRGB(255,255,255)
    sbox.BackgroundColor3 = Aimbot.silent and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
    sbox.MouseButton1Click:Connect(function()
        Aimbot.silent = not Aimbot.silent
        sbox.BackgroundColor3 = Aimbot.silent and Color3.fromRGB(55,155,55) or Color3.fromRGB(80,30,30)
    end)

end

EspMenu()

-- Anticheat bypass and menu/ESP/aim strategy: Full rewrite, minimal dependencies, menu always injects, no custom hooks outside standard exploits, only one main ScreenGui, robust fallback parenting

local LocalPlayer = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function ParentGui(gui)
    local goodParent = nil
    if typeof(gethui) == "function" then
        pcall(function()
            local h = gethui()
            if h and typeof(h)=="Instance" then goodParent = h end
        end)
    elseif typeof(syn) == "table" and syn and syn.protect_gui then
        syn.protect_gui(gui)
        goodParent = game:GetService("CoreGui")
    else
        goodParent = game:GetService("CoreGui")
    end
    if not goodParent and LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        goodParent = LocalPlayer.PlayerGui
    end
    if not goodParent then
        goodParent = game:GetService("Players").LocalPlayer
    end
    pcall(function() gui.Parent = goodParent end)
end

local ESP, Aimbot = {
    enabled = false,
    box = false,
    distance = false,
    name = false,
    skeleton = false,
    headcircle = false,
    color = Color3.fromRGB(0,255,255)
},{
    enabled = false,
    targetmode = "Head",
    silent = false,
    fov = 120,
    target = nil
}

local function IsEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then return false end
    if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChild("Head")
        and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
        return true
    end
    return false
end

local function GetEnemies()
    local arr = {}
    for _,p in ipairs(game:GetService("Players"):GetPlayers()) do
        if IsEnemy(p) then table.insert(arr, p) end
    end
    return arr
end

local function WorldToScreen(vec)
    local cam = workspace.CurrentCamera
    if not cam then return Vector3.zero, false end
    local pos,vis = cam:WorldToViewportPoint(vec)
    return pos, vis
end

local drawings = {}
local function RemoveDraws()
    for _,d in ipairs(drawings) do
        pcall(function()
            d.Visible = false
            if typeof(d.Remove)=="function" then d:Remove() elseif typeof(d.Destroy)=="function" then d:Destroy() end
        end)
    end
    table.clear(drawings)
end

local function DrawBox(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return end
    local hrp = chr.HumanoidRootPart
    local size = Vector3.new(4,7,1.6)
    local parts = {}
    for _,v in ipairs({
        Vector3.new(-size.X/2,size.Y/2,0), Vector3.new(size.X/2,size.Y/2,0),
        Vector3.new(size.X/2,-size.Y/2,0), Vector3.new(-size.X/2,-size.Y/2,0)
    }) do
        local p,onscreen = WorldToScreen((hrp.CFrame * CFrame.new(v)).Position)
        if onscreen then table.insert(parts,p) end
    end
    if #parts == 4 then
        for i=1,4 do
            local ln = Drawing.new("Line")
            ln.From = Vector2.new(parts[i].X,parts[i].Y)
            ln.To = Vector2.new(parts[(i%4)+1].X,parts[(i%4)+1].Y)
            ln.Color = color
            ln.Thickness = 2
            ln.Visible = ESP.enabled and ESP.box
            ln.Transparency = 1
            table.insert(drawings,ln)
        end
    end
end

local function DrawName(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("Head") then return end
    local pos,scr = WorldToScreen(chr.Head.Position)
    if scr then
        local txt = Drawing.new("Text")
        txt.Text = plr.Name
        txt.Position = Vector2.new(pos.X,pos.Y-24)
        txt.Size = 16
        txt.Color = color
        txt.Center = true
        txt.Outline = true
        txt.Visible = ESP.enabled and ESP.name
        table.insert(drawings,txt)
    end
end

local function DrawDistance(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("Head") then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - chr.Head.Position).Magnitude
    local pos,scr = WorldToScreen(chr.Head.Position)
    if scr then
        local txt = Drawing.new("Text")
        txt.Text = string.format("[%dm]", math.floor(dist))
        txt.Position = Vector2.new(pos.X,pos.Y-10)
        txt.Size = 13
        txt.Color = color
        txt.Center = true
        txt.Outline = true
        txt.Visible = ESP.enabled and ESP.distance
        table.insert(drawings,txt)
    end
end

local function DrawSkeleton(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("Head") then return end
    local bones = {
        {"Head", "UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    for _,b in ipairs(bones) do
        local a, c = chr:FindFirstChild(b[1]), chr:FindFirstChild(b[2])
        if a and c then
            local posA,onA = WorldToScreen(a.Position)
            local posC,onC = WorldToScreen(c.Position)
            if onA and onC then
                local ln = Drawing.new("Line")
                ln.From = Vector2.new(posA.X,posA.Y)
                ln.To = Vector2.new(posC.X,posC.Y)
                ln.Color = color
                ln.Thickness = 2
                ln.Visible = ESP.enabled and ESP.skeleton
                ln.Transparency = 1
                table.insert(drawings,ln)
            end
        end
    end
end

local function DrawHeadCircle(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("Head") then return end
    local pos,sc = WorldToScreen(chr.Head.Position)
    if sc then
        local cir = Drawing.new("Circle")
        cir.Position = Vector2.new(pos.X,pos.Y)
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

RunService.RenderStepped:Connect(function()
    RemoveDraws()
    if ESP.enabled then
        for _,plr in ipairs(GetEnemies()) do
            if ESP.box then DrawBox(plr,ESP.color) end
            if ESP.name then DrawName(plr,ESP.color) end
            if ESP.distance then DrawDistance(plr,ESP.color) end
            if ESP.skeleton then DrawSkeleton(plr,ESP.color) end
            if ESP.headcircle then DrawHeadCircle(plr,ESP.color) end
        end
    end
end)

local function ClosestPart(chr)
    local mouse = LocalPlayer:GetMouse()
    local best, small = nil, math.huge
    for _,pname in ipairs({"Head", "HumanoidRootPart","UpperTorso","LowerTorso","LeftHand","RightHand","LeftFoot","RightFoot"}) do
        local p = chr:FindFirstChild(pname)
        if p then
            local v,os = WorldToScreen(p.Position)
            if os then
                local dist = (Vector2.new(v.X,v.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                if dist < small then best, small = p, dist end
            end
        end
    end
    return best
end

local function AimbotTarget()
    local mouse = LocalPlayer:GetMouse()
    local dist, found = math.huge, nil
    for _,plr in ipairs(GetEnemies()) do
        local chr = plr.Character
        if chr then
            local tpart = nil
            if Aimbot.targetmode=="Head" then tpart = chr:FindFirstChild("Head")
            elseif Aimbot.targetmode=="Body" then tpart = chr:FindFirstChild("HumanoidRootPart") or chr:FindFirstChild("UpperTorso")
            elseif Aimbot.targetmode=="ClosestPart" then tpart = ClosestPart(chr) end
            if tpart then
                local v,ons = WorldToScreen(tpart.Position)
                if ons then
                    local d = (Vector2.new(v.X,v.Y) - Vector2.new(mouse.X,mouse.Y)).Magnitude
                    if d < Aimbot.fov and d < dist then dist,found = d, plr end
                end
            end
        end
    end
    return found
end

RunService.RenderStepped:Connect(function()
    if Aimbot.enabled then
        local trg = AimbotTarget()
        if trg and trg.Character then
            local part
            if Aimbot.targetmode=="Head" then part = trg.Character:FindFirstChild("Head")
            elseif Aimbot.targetmode=="Body" then part = trg.Character:FindFirstChild("HumanoidRootPart") or trg.Character:FindFirstChild("UpperTorso")
            elseif Aimbot.targetmode=="ClosestPart" then part = ClosestPart(trg.Character) end
            if part then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, part.Position)
                Aimbot.target = trg
            else
                Aimbot.target = nil
            end
        else
            Aimbot.target = nil
        end
    end
end)

if hookmetamethod and typeof(hookmetamethod)=="function" then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() and Aimbot.enabled and Aimbot.silent and Aimbot.target and Aimbot.target.Character then
            local method = getnamecallmethod()
            if tostring(method) == "FireServer" and tostring(self) == "HitPart" then
                local args = {...}
                local part = nil
                if Aimbot.targetmode=="Head" then part = Aimbot.target.Character:FindFirstChild("Head")
                elseif Aimbot.targetmode=="Body" then part = Aimbot.target.Character:FindFirstChild("HumanoidRootPart") or Aimbot.target.Character:FindFirstChild("UpperTorso")
                elseif Aimbot.targetmode=="ClosestPart" then part = ClosestPart(Aimbot.target.Character) end
                if part and typeof(args[1])=="Instance" and typeof(args[2])=="Vector3" then
                    args[1],args[2]=part,part.Position
                    return old(self, unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
end

local function ShowPassword(cb)
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name=="NBLX_PassWnd" then pcall(function() g:Destroy() end) end end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NBLX_PassWnd"
    ParentGui(gui)
    local fr = Instance.new("Frame",gui)
    fr.Position = UDim2.new(0.41,0,0.35,0)
    fr.Size = UDim2.new(0,290,0,100)
    fr.BackgroundColor3 = Color3.fromRGB(24,34,48)
    fr.BorderSizePixel = 0
    local txt = Instance.new("TextLabel",fr)
    txt.Size = UDim2.new(1,0,0,32)
    txt.Position = UDim2.new(0,0,0,8)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBlack
    txt.Text = "Şifre Gerekli"
    txt.TextColor3 = Color3.fromRGB(0,255,255)
    txt.TextSize = 19
    local pass = Instance.new("TextBox",fr)
    pass.Size = UDim2.new(0.88,0,0,26)
    pass.Position = UDim2.new(0.06,0,0,40)
    pass.PlaceholderText = "258631"
    pass.BackgroundColor3 = Color3.fromRGB(37,46,61)
    pass.TextColor3 = Color3.fromRGB(255,255,255)
    pass.Font = Enum.Font.Gotham
    pass.TextSize = 18
    pass.ClearTextOnFocus = true
    local info = Instance.new("TextLabel",fr)
    info.Size = UDim2.new(1,0,0,17)
    info.Position = UDim2.new(0,0,1,-22)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextColor3 = Color3.fromRGB(255,64,64)
    info.TextSize = 15
    info.Text = ""
    local btn = Instance.new("TextButton",fr)
    btn.Text = "GİR"
    btn.Size = UDim2.new(0.32,0,0,22)
    btn.Position = UDim2.new(0.34,0,1,-32)
    btn.BackgroundColor3 = Color3.fromRGB(43,130,145)
    btn.Font = Enum.Font.GothamBlack
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 15
    btn.BorderSizePixel = 0
    local function check()
        if tostring(pass.Text) == "258631" then
            gui:Destroy()
            cb()
        else
            info.Text = "Hatalı şifre!"
        end
    end
    btn.MouseButton1Click:Connect(check)
    pass.FocusLost:Connect(function(enter) if enter then check() end end)
    UIS.InputBegan:Connect(function(inp,gp) if not gp and inp.KeyCode == Enum.KeyCode.Return then check() end end)
    gui.Enabled = true
end

local MenuGuiName = "NBLX_MenuWnd"
local function MakeMenu()
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name==MenuGuiName then pcall(function() g:Destroy() end) end end
    local gui = Instance.new("ScreenGui")
    gui.Name = MenuGuiName
    ParentGui(gui)
    local fr = Instance.new("Frame",gui)
    fr.Size = UDim2.new(0,450,0,310)
    fr.Position = UDim2.new(0.34,0,0.18,0)
    fr.BackgroundColor3 = Color3.fromRGB(20,27,36)
    fr.BorderSizePixel = 0
    fr.Active = true
    fr.Draggable = true
    local bar = Instance.new("Frame",fr)
    bar.Size = UDim2.new(1,0,0,33)
    bar.BackgroundColor3 = Color3.fromRGB(11,44,76)
    bar.Position = UDim2.new(0,0,0,0)
    local tx = Instance.new("TextLabel",bar)
    tx.Text = "Nebula Bloxstrike Menü"
    tx.Font = Enum.Font.GothamBlack
    tx.TextColor3 = Color3.fromRGB(0,255,255)
    tx.TextSize = 17
    tx.Size = UDim2.new(1,0,1,0)
    tx.BackgroundTransparency = 1
    local close = Instance.new("TextButton",bar)
    close.Text = "✕"
    close.Font = Enum.Font.GothamBlack
    close.TextColor3 = Color3.fromRGB(255,50,60)
    close.TextSize = 16
    close.Size = UDim2.new(0,30,0,28)
    close.Position = UDim2.new(1,-36,0,3)
    close.BackgroundColor3 = Color3.fromRGB(35,20,33)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local y = 44
    local function Toggle(label, base, key, xpos)
        local b = Instance.new("TextButton", fr)
        b.Size = UDim2.new(0,156,0,25)
        b.Position = UDim2.new(xpos,0,0,y)
        b.Text = label.." : "..(base[key] and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = base[key] and Color3.fromRGB(50,146,86) or Color3.fromRGB(35,32,58)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.BorderSizePixel = 0
        b.MouseButton1Click:Connect(function()
            base[key] = not base[key]
            b.Text = label.." : "..(base[key] and "AÇIK" or "KAPALI")
            b.BackgroundColor3 = base[key] and Color3.fromRGB(50,146,86) or Color3.fromRGB(35,32,58)
        end)
        y = y + 31
        return b
    end
    local function Section(lbl, xpos, clr)
        local t = Instance.new("TextLabel", fr)
        t.Position = UDim2.new(xpos,0,0,33)
        t.Size = UDim2.new(0,155,0,13)
        t.Text = lbl
        t.TextColor3 = clr
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.BackgroundTransparency = 1
    end

    Section("ESP",0, Color3.fromRGB(0,255,255))
    y = 58
    Toggle("Aktif", ESP, "enabled", 0)
    Toggle("Box", ESP, "box", 0)
    Toggle("Mesafe", ESP, "distance", 0)
    Toggle("İsim", ESP, "name", 0)
    Toggle("İskelet", ESP, "skeleton", 0)
    Toggle("HeadCircle", ESP, "headcircle", 0)

    -- ESP color
    local clrLab = Instance.new("TextLabel",fr)
    clrLab.Size = UDim2.new(0,66,0,19)
    clrLab.Position = UDim2.new(0,15,0,y+3)
    clrLab.Text = "Renk:"
    clrLab.BackgroundTransparency = 1
    clrLab.Font = Enum.Font.GothamSemibold
    clrLab.TextColor3 = Color3.fromRGB(255,255,255)
    clrLab.TextSize = 13
    local clrBtn = Instance.new("TextButton",fr)
    clrBtn.Size = UDim2.new(0,32,0,19)
    clrBtn.Position = UDim2.new(0,82,0,y+3)
    clrBtn.Text = ""
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(64,255), math.random(64,255), math.random(64,255)
        ESP.color=Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    -- Aimbot sec
    local y2 = 58
    Section("Aimbot",.58,Color3.fromRGB(0,255,160))
    local Aimg = {}
    Toggle("Aktif",Aimbot,"enabled", .58)
    Aimg.silent = Toggle("Silent",Aimbot,"silent",.58)
    y2 = y2 + 62

    -- Aimbot target mode dropdown
    local tgLbl = Instance.new("TextLabel",fr)
    tgLbl.Position = UDim2.new(.58,10,0,y2)
    tgLbl.Size = UDim2.new(0,60,0,18)
    tgLbl.Text = "Hedef:"
    tgLbl.Font = Enum.Font.GothamSemibold
    tgLbl.TextColor3 = Color3.fromRGB(255,255,255)
    tgLbl.TextSize = 12
    tgLbl.BackgroundTransparency = 1
    local modes = {"Head","Body","ClosestPart"}
    local sel = Instance.new("TextButton",fr)
    sel.Position = UDim2.new(.58,70,0,y2)
    sel.Size = UDim2.new(0,78,0,19)
    sel.Text = Aimbot.targetmode
    sel.BackgroundColor3 = Color3.fromRGB(36,64,96)
    sel.TextColor3 = Color3.fromRGB(255,255,255)
    sel.Font = Enum.Font.GothamSemibold
    sel.BorderSizePixel = 0
    sel.TextSize = 12
    sel.MouseButton1Click:Connect(function()
        local i = table.find(modes,Aimbot.targetmode) or 0
        Aimbot.targetmode = modes[(i%#modes)+1]
        sel.Text = Aimbot.targetmode
    end)

    -- FOV setup
    local fovLbl = Instance.new("TextLabel",fr)
    fovLbl.Position = UDim2.new(.58,10,0,y2+23)
    fovLbl.Size = UDim2.new(0,23,0,17)
    fovLbl.Text = "Fov"
    fovLbl.Font = Enum.Font.GothamSemibold
    fovLbl.TextColor3 = Color3.fromRGB(255,255,255)
    fovLbl.TextSize = 12
    fovLbl.BackgroundTransparency = 1
    local fovBox = Instance.new("TextBox",fr)
    fovBox.Position = UDim2.new(.58,40,0,y2+22)
    fovBox.Size = UDim2.new(0,40,0,19)
    fovBox.Text = tostring(Aimbot.fov)
    fovBox.BackgroundColor3 = Color3.fromRGB(40,37,62)
    fovBox.TextColor3 = Color3.fromRGB(255,255,255)
    fovBox.Font = Enum.Font.GothamSemibold
    fovBox.BorderSizePixel = 0
    fovBox.TextSize = 12
    fovBox.ClearTextOnFocus = false
    fovBox.FocusLost:Connect(function()
        local v = tonumber(fovBox.Text)
        if v and v <= 650 and v >= 10 then
            Aimbot.fov = v
        else
            fovBox.Text = tostring(Aimbot.fov)
        end
    end)

    -- Instructions
    local ins = Instance.new("TextLabel",fr)
    ins.Text = "Menü: Insert tuşu | discord.gg/nebula-hub"
    ins.Font = Enum.Font.GothamSemibold
    ins.TextColor3 = Color3.fromRGB(90,225,246)
    ins.BackgroundTransparency = 1
    ins.Position = UDim2.new(0.03,0,1,-22)
    ins.Size = UDim2.new(0.93,0,0,18)
    ins.TextSize = 13

    gui.Enabled = true
end

ShowPassword(function()
    MakeMenu()
end)

UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        local gui = game:GetService("CoreGui"):FindFirstChild(MenuGuiName)
        if gui then gui.Enabled = not gui.Enabled else MakeMenu() end
    end
end)

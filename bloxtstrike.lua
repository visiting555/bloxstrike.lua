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

local Extra = {
    noclip = false,
    fly = false,
    invisible = false,
    spinbot = false
}

local noclipConn
local flyConn
local flySpeed = 4
local lastInvisible = false
local spinConn

local function IsEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team and #game:GetService("Teams"):GetTeams() > 1 then return false end
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

local function EnableNoclip(state)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(11)
            end
        end)
    end
end

local flyControls = {F=false,B=false,L=false,R=false,U=false,D=false}
local function SetupFlyKeys()
    UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==Enum.KeyCode.W then flyControls.F=true end
        if i.KeyCode==Enum.KeyCode.S then flyControls.B=true end
        if i.KeyCode==Enum.KeyCode.A then flyControls.L=true end
        if i.KeyCode==Enum.KeyCode.D then flyControls.R=true end
        if i.KeyCode==Enum.KeyCode.Space then flyControls.U=true end
        if i.KeyCode==Enum.KeyCode.LeftControl then flyControls.D=true end
    end)
    UIS.InputEnded:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==Enum.KeyCode.W then flyControls.F=false end
        if i.KeyCode==Enum.KeyCode.S then flyControls.B=false end
        if i.KeyCode==Enum.KeyCode.A then flyControls.L=false end
        if i.KeyCode==Enum.KeyCode.D then flyControls.R=false end
        if i.KeyCode==Enum.KeyCode.Space then flyControls.U=false end
        if i.KeyCode==Enum.KeyCode.LeftControl then flyControls.D=false end
    end)
end
SetupFlyKeys()

local function EnableFly(state)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if state then
        flyConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                hrp.Velocity = Vector3.new(0,0,0)
                local cam = workspace.CurrentCamera
                local cf = cam.CFrame
                local move = Vector3.new()
                if flyControls.F then move = move + cf.LookVector end
                if flyControls.B then move = move - cf.LookVector end
                if flyControls.L then move = move - cf.RightVector end
                if flyControls.R then move = move + cf.RightVector end
                if flyControls.U then move = move + cf.UpVector end
                if flyControls.D then move = move - cf.UpVector end
                if move.Magnitude > 0 then move = move.Unit else move=Vector3.zero end
                hrp.Velocity = move * flySpeed * 16
            end
        end)
    end
end

local function EnableInvisible(state)
    if LocalPlayer.Character then
        for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                v.Transparency = (state and 1 or 0)
                if v:IsA("BasePart") then v.CanCollide = not state end
            end
        end
        lastInvisible = state
    end
end

local function EnableSpinbot(state)
    if spinConn then spinConn:Disconnect() spinConn=nil end
    if state then
        spinConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0,math.rad(32),0)
            end
        end)
    end
end

local function HandleToggles()
    EnableNoclip(Extra.noclip)
    EnableFly(Extra.fly)
    EnableInvisible(Extra.invisible)
    EnableSpinbot(Extra.spinbot)
end

local MenuGuiName = "visitingmenu"
local function MakeMenu()
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name==MenuGuiName then pcall(function() g:Destroy() end) end end
    local gui = Instance.new("ScreenGui")
    gui.Name = MenuGuiName
    ParentGui(gui)
    local fr = Instance.new("Frame",gui)
    fr.Size = UDim2.new(0,510,0,310)
    fr.Position = UDim2.new(0.335,0,0.17,0)
    fr.BackgroundColor3 = Color3.fromRGB(20,27,36)
    fr.BorderSizePixel = 0
    fr.Active = true fr.Draggable = true

    local bar = Instance.new("Frame",fr)
    bar.Size = UDim2.new(1,0,0,33)
    bar.BackgroundColor3 = Color3.fromRGB(11,44,76)
    bar.Position = UDim2.new(0,0,0,0)
    local tx = Instance.new("TextLabel",bar)
    tx.Text = "visitingmenu"
    tx.Font = Enum.Font.GothamBlack
    tx.TextColor3 = Color3.fromRGB(0,255,255)
    tx.TextSize = 19
    tx.Size = UDim2.new(1,0,1,0)
    tx.BackgroundTransparency = 1

    local close = Instance.new("TextButton",bar)
    close.Text = "✕"
    close.Font = Enum.Font.GothamBlack
    close.TextColor3 = Color3.fromRGB(255,50,60)
    close.TextSize = 16
    close.Size = UDim2.new(0,30,0,28)
    close.Position = UDim2.new(1,-36,0,3)
    close.BackgroundColor3 = Color3.fromRGB(33,22,18)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    -- Satırların grid değerleri
    local x_col = {0.03, 0.36, 0.69} -- sol-orta-sağ kolon X
    local width = 150; local h_sp = 31; local y0 = 48

    -- ESP
    local labels = {
        {"ESP Aktif", ESP, "enabled"},
        {"ESP Box", ESP, "box"},
        {"ESP Mesafe", ESP, "distance"},
        {"ESP İsim", ESP, "name"},
        {"ESP İskelet", ESP, "skeleton"},
        {"ESP HeadCircle", ESP, "headcircle"}
    }
    for row,l in ipairs(labels) do
        local b = Instance.new("TextButton", fr)
        b.Size = UDim2.new(0,width,0,25)
        b.Position = UDim2.new(x_col[1],0,0,y0+(row-1)*h_sp)
        b.Text = l[1].." : "..(l[2][l[3]] and "AÇIK" or "KAPALI")
        b.BackgroundColor3 = l[2][l[3]] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.BorderSizePixel = 0
        b.MouseButton1Click:Connect(function()
            l[2][l[3]] = not l[2][l[3]]
            b.Text = l[1].." : "..(l[2][l[3]] and "AÇIK" or "KAPALI")
            b.BackgroundColor3 = l[2][l[3]] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
        end)
    end
    local clrLab = Instance.new("TextLabel",fr)
    clrLab.Size = UDim2.new(0,50,0,18)
    clrLab.Position = UDim2.new(x_col[1],10,0,y0+#labels*h_sp)
    clrLab.Text = "Renk:"
    clrLab.BackgroundTransparency = 1
    clrLab.Font = Enum.Font.GothamSemibold
    clrLab.TextColor3 = Color3.fromRGB(255,255,255)
    clrLab.TextSize = 13
    local clrBtn = Instance.new("TextButton",fr)
    clrBtn.Size = UDim2.new(0,32,0,18)
    clrBtn.Position = UDim2.new(x_col[1],68,0,y0+#labels*h_sp)
    clrBtn.Text = ""
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(64,255), math.random(64,255), math.random(64,255)
        ESP.color=Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    -- Aimbot
    local ab_row = 0
    local ab_active = Instance.new("TextButton", fr)
    ab_active.Size = UDim2.new(0,width,0,25)
    ab_active.Position = UDim2.new(x_col[2],0,0,y0+ab_row*h_sp)
    ab_active.Text = "Aimbot : "..(Aimbot.enabled and "AÇIK" or "KAPALI")
    ab_active.BackgroundColor3 = Aimbot.enabled and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
    ab_active.TextColor3 = Color3.fromRGB(255,255,255)
    ab_active.Font = Enum.Font.GothamSemibold
    ab_active.TextSize = 14 ab_active.BorderSizePixel = 0
    ab_active.MouseButton1Click:Connect(function()
        Aimbot.enabled = not Aimbot.enabled
        ab_active.Text = "Aimbot : "..(Aimbot.enabled and "AÇIK" or "KAPALI")
        ab_active.BackgroundColor3 = Aimbot.enabled and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
    end)
    ab_row = ab_row+1

    local ab_sil = Instance.new("TextButton", fr)
    ab_sil.Size = UDim2.new(0,width,0,25)
    ab_sil.Position = UDim2.new(x_col[2],0,0,y0+ab_row*h_sp)
    ab_sil.Text = "SilentAim : "..(Aimbot.silent and "AÇIK" or "KAPALI")
    ab_sil.BackgroundColor3 = Aimbot.silent and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
    ab_sil.TextColor3 = Color3.fromRGB(255,255,255)
    ab_sil.Font = Enum.Font.GothamSemibold
    ab_sil.TextSize = 14 ab_sil.BorderSizePixel = 0
    ab_sil.MouseButton1Click:Connect(function()
        Aimbot.silent = not Aimbot.silent
        ab_sil.Text = "SilentAim : "..(Aimbot.silent and "AÇIK" or "KAPALI")
        ab_sil.BackgroundColor3 = Aimbot.silent and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
    end)
    ab_row = ab_row+1

    local modes = {"Head","Body","ClosestPart"}
    local ab_mlbl = Instance.new("TextLabel", fr)
    ab_mlbl.Position = UDim2.new(x_col[2],1,0,y0+ab_row*h_sp+3)
    ab_mlbl.Size = UDim2.new(0,60,0,18)
    ab_mlbl.Text = "Hedef:"
    ab_mlbl.Font = Enum.Font.GothamSemibold
    ab_mlbl.TextColor3 = Color3.fromRGB(255,255,255)
    ab_mlbl.TextSize = 13 ab_mlbl.BackgroundTransparency = 1

    local ab_mode = Instance.new("TextButton", fr)
    ab_mode.Position = UDim2.new(x_col[2],64,0,y0+ab_row*h_sp+1)
    ab_mode.Size = UDim2.new(0,82,0,19)
    ab_mode.Text = Aimbot.targetmode
    ab_mode.BackgroundColor3 = Color3.fromRGB(36,64,96)
    ab_mode.TextColor3 = Color3.fromRGB(255,255,255)
    ab_mode.Font = Enum.Font.GothamSemibold ab_mode.BorderSizePixel = 0 ab_mode.TextSize = 13
    ab_mode.MouseButton1Click:Connect(function()
        local i = table.find(modes,Aimbot.targetmode) or 0
        Aimbot.targetmode = modes[(i%#modes)+1]
        ab_mode.Text = Aimbot.targetmode
    end)
    ab_row = ab_row + 1

    local fovLbl = Instance.new("TextLabel",fr)
    fovLbl.Position = UDim2.new(x_col[2],1,0,y0+ab_row*h_sp+3)
    fovLbl.Size = UDim2.new(0,23,0,18)
    fovLbl.Text = "Fov:"
    fovLbl.Font = Enum.Font.GothamSemibold
    fovLbl.TextColor3 = Color3.fromRGB(255,255,255)
    fovLbl.TextSize = 13 fovLbl.BackgroundTransparency = 1

    local fovBox = Instance.new("TextBox",fr)
    fovBox.Position = UDim2.new(x_col[2],40,0,y0+ab_row*h_sp+1)
    fovBox.Size = UDim2.new(0,45,0,19)
    fovBox.Text = tostring(Aimbot.fov)
    fovBox.BackgroundColor3 = Color3.fromRGB(38,37,62)
    fovBox.TextColor3 = Color3.fromRGB(255,255,255)
    fovBox.Font = Enum.Font.GothamSemibold
    fovBox.BorderSizePixel = 0
    fovBox.TextSize = 13
    fovBox.ClearTextOnFocus = false
    fovBox.FocusLost:Connect(function()
        local v = tonumber(fovBox.Text)
        if v and v <= 650 and v >= 10 then
            Aimbot.fov = v
        else
            fovBox.Text = tostring(Aimbot.fov)
        end
    end)

    -- Extra
    local btn_data = {
        {"NoClip", Extra, "noclip"},
        {"Fly", Extra, "fly"},
        {"Görünmez", Extra, "invisible"},
        {"Spinbot", Extra, "spinbot"}
    }
    for idx,ed in ipairs(btn_data) do
        local ex_btn = Instance.new("TextButton", fr)
        ex_btn.Size = UDim2.new(0,width,0,25)
        ex_btn.Position = UDim2.new(x_col[3],0,0,y0+(idx-1)*h_sp)
        ex_btn.Text = ed[1].." : "..(ed[2][ed[3]] and "AÇIK" or "KAPALI")
        ex_btn.BackgroundColor3 = ed[2][ed[3]] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
        ex_btn.TextColor3 = Color3.fromRGB(255,255,255)
        ex_btn.Font = Enum.Font.GothamSemibold
        ex_btn.TextSize = 14
        ex_btn.BorderSizePixel = 0
        ex_btn.MouseButton1Click:Connect(function()
            ed[2][ed[3]] = not ed[2][ed[3]]
            ex_btn.Text = ed[1].." : "..(ed[2][ed[3]] and "AÇIK" or "KAPALI")
            ex_btn.BackgroundColor3 = ed[2][ed[3]] and Color3.fromRGB(60,182,96) or Color3.fromRGB(36,41,68)
            HandleToggles()
        end)
    end

    -- Extra ayarlar: Fly hızı
    local fLab = Instance.new("TextLabel",fr)
    fLab.Position = UDim2.new(x_col[3],0,0,y0+#btn_data*h_sp+3)
    fLab.Size = UDim2.new(0,74,0,18)
    fLab.Text = "Fly Hızı:"
    fLab.Font = Enum.Font.GothamSemibold
    fLab.TextColor3 = Color3.fromRGB(255,255,255)
    fLab.TextSize = 13 fLab.BackgroundTransparency = 1

    local flySliderF = Instance.new("Frame", fr)
    flySliderF.Position = UDim2.new(x_col[3],74,0,y0+#btn_data*h_sp+8)
    flySliderF.Size = UDim2.new(0,63,0,8)
    flySliderF.BackgroundColor3 = Color3.fromRGB(60,60,60)
    flySliderF.BorderSizePixel = 0
    local Sknob = Instance.new("Frame", flySliderF)
    Sknob.Size = UDim2.new(0,11,1,0)
    Sknob.Position = UDim2.new((flySpeed-1)/19,0,0,0)
    Sknob.BackgroundColor3 = Color3.fromRGB(0,255,255)
    Sknob.BorderSizePixel = 0
    Sknob.Active = true
    Sknob.Draggable = true

    local flyval = Instance.new("TextBox", fr)
    flyval.Position = UDim2.new(x_col[3],145,0,y0+#btn_data*h_sp)
    flyval.Size = UDim2.new(0,40,0,17)
    flyval.Text = tostring(flySpeed)
    flyval.BackgroundColor3 = Color3.fromRGB(38,37,62)
    flyval.TextColor3 = Color3.fromRGB(255,255,255)
    flyval.Font = Enum.Font.GothamSemibold
    flyval.BorderSizePixel = 0
    flyval.TextSize = 13
    flyval.ClearTextOnFocus = false
    flyval.FocusLost:Connect(function()
        local v = tonumber(flyval.Text)
        if v and v >= 1 and v <= 20 then
            flySpeed = v
        else
            flyval.Text = tostring(flySpeed)
        end
        Sknob.Position = UDim2.new((flySpeed-1)/19,0,0,0)
    end)

    Sknob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local ucon, rend
            ucon = UIS.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    local mx = math.clamp((i.Position.X - flySliderF.AbsolutePosition.X) / flySliderF.AbsoluteSize.X,0,1)
                    flySpeed = math.round(mx*19+1)
                    flyval.Text = tostring(flySpeed)
                    Sknob.Position = UDim2.new((flySpeed-1)/19,0,0,0)
                end
            end)
            rend = UIS.InputEnded:Connect(function(a)
                if a.UserInputType == Enum.UserInputType.MouseButton1 then
                    if ucon then ucon:Disconnect() end
                    if rend then rend:Disconnect() end
                end
            end)
        end
    end)
    --
    gui.Enabled = true
end

local function ShowPassword(cb)
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name=="NBLX_PassWnd" then pcall(function() g:Destroy() end) end end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NBLX_PassWnd"
    ParentGui(gui)
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

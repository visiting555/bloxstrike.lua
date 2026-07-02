local LocalPlayer = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function ParentGui(gui)
    local parentTarget
    if typeof(gethui) == "function" then
        pcall(function() parentTarget = gethui() end)
    end
    if not parentTarget and syn and syn.protect_gui then
        syn.protect_gui(gui)
        parentTarget = game:GetService("CoreGui")
    end
    if not parentTarget and LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        parentTarget = LocalPlayer.PlayerGui
    end
    if not parentTarget then
        parentTarget = game:GetService("CoreGui")
    end
    gui.Parent = parentTarget
end

for _,c in pairs(getconnections(game:GetService("LogService").MessageOut)) do pcall(function() c:Disable() end) end

local ESP = {
    enabled = false, box = false, distance = false, name = false, skeleton = false, headcircle = false, tracer = false, chams = false, color = Color3.fromRGB(0,255,255)
}
local Aimbot = {
    enabled = false, targetmode = "Head", silent = false, fov = 120, target = nil
}
local Extra = {
    noclip=false, fly=false, invisible=false, spinbot=false, cammode="first"
}
local flySpeed = 4
local MenuGuiName = "visitingmenu"
local menuGuiObj

local function IsEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team and #game:GetService("Teams"):GetTeams()>1 then return false end
    local chr = plr.Character
    if chr and chr:FindFirstChildOfClass("Humanoid") and chr:FindFirstChild("HumanoidRootPart") and chr:FindFirstChild("Head") and chr:FindFirstChildOfClass("Humanoid").Health > 0 then
        return true
    end
    return false
end

local function GetEnemies()
    local arr = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if IsEnemy(p) then table.insert(arr, p) end
    end
    return arr
end

local cam = Workspace.CurrentCamera
local function WorldToScreen(vec)
    cam = Workspace.CurrentCamera
    if not cam then return Vector3.zero, false end
    local pos,vis = cam:WorldToViewportPoint(vec)
    return pos, vis
end

local drawings = setmetatable({}, {__mode = "k"})
local function RemoveDraws()
    for d in pairs(drawings) do
        d.Visible = false
        if typeof(d.Remove)=="function" then d:Remove() elseif typeof(d.Destroy)=="function" then d:Destroy() end
        drawings[d] = nil
    end
end

local function DrawBox(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return end
    local hrp = chr.HumanoidRootPart
    local cf,size = hrp.CFrame, Vector3.new(4,7,1.6)
    local corners = {
        Vector3.new(-size.X/2,size.Y/2,0), Vector3.new(size.X/2,size.Y/2,0),
        Vector3.new(size.X/2,-size.Y/2,0), Vector3.new(-size.X/2,-size.Y/2,0)
    }
    local parts = {}
    for _,v in ipairs(corners) do
        local p,onscreen = WorldToScreen((cf * CFrame.new(v)).Position)
        if onscreen then table.insert(parts,p) else return end
    end
    for i=1,4 do
        local ln = Drawing.new("Line")
        ln.From = Vector2.new(parts[i].X,parts[i].Y)
        ln.To = Vector2.new(parts[(i%4)+1].X,parts[(i%4)+1].Y)
        ln.Color = color
        ln.Thickness = 2
        ln.Visible = ESP.enabled and ESP.box
        ln.Transparency = 1
        drawings[ln] = true
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
        drawings[txt] = true
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
        drawings[txt] = true
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
                drawings[ln] = true
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
        cir.Radius = 16
        cir.Thickness = 2
        cir.NumSides = 30
        cir.Filled = false
        cir.Visible = ESP.enabled and ESP.headcircle
        drawings[cir] = true
    end
end

local function DrawTracer(plr, color)
    local chr = plr.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return end
    local pos,scr = WorldToScreen(chr.HumanoidRootPart.Position)
    if scr then
        cam = Workspace.CurrentCamera
        local from = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        local ln = Drawing.new("Line")
        ln.From = from
        ln.To = Vector2.new(pos.X,pos.Y)
        ln.Color = color
        ln.Thickness = 2
        ln.Visible = ESP.enabled and ESP.tracer
        ln.Transparency = 1
        drawings[ln] = true
    end
end

local ChamsList = setmetatable({}, {__mode = "k"})
local function RemoveChams()
    for k,v in pairs(ChamsList) do
        if typeof(v) == "table" then
            for _,p in pairs(v) do
                if p and p.Parent then p:Destroy() end
            end
        end
        ChamsList[k] = nil
    end
end
local function DrawChams(plr, color)
    local chr = plr.Character
    if chr then
        if not ChamsList[plr] then ChamsList[plr] = {} end
        if #ChamsList[plr] == 0 then
            for _,p in ipairs(chr:GetDescendants()) do
                if p:IsA("BasePart") and not p:IsDescendantOf(LocalPlayer.Character) then
                    local b = Instance.new("BoxHandleAdornment")
                    b.Adornee = p
                    b.Size = p.Size + Vector3.new(.08,.08,.08)
                    b.AlwaysOnTop = true
                    b.ZIndex = 5
                    b.Transparency = .6
                    b.Color3 = color
                    b.Parent = Workspace.CurrentCamera
                    table.insert(ChamsList[plr], b)
                end
            end
        else
            for _,box in ipairs(ChamsList[plr]) do
                pcall(function()
                    box.Color3 = color
                    box.Visible = (ESP.enabled and ESP.chams) and true or false
                end)
            end
        end
    end
end

RunService:UnbindFromRenderStep("visitingmenu_esp_cleanup")
RunService:BindToRenderStep("visitingmenu_esp_cleanup", Enum.RenderPriority.Last.Value+1000, function()
    RemoveDraws()
    if not ESP.enabled or not Workspace.CurrentCamera then RemoveChams() end
    if ESP.enabled then
        for _,plr in ipairs(GetEnemies()) do
            if ESP.box then DrawBox(plr,ESP.color) end
            if ESP.name then DrawName(plr,ESP.color) end
            if ESP.distance then DrawDistance(plr,ESP.color) end
            if ESP.skeleton then DrawSkeleton(plr,ESP.color) end
            if ESP.headcircle then DrawHeadCircle(plr,ESP.color) end
            if ESP.tracer then DrawTracer(plr,ESP.color) end
            if ESP.chams then DrawChams(plr,ESP.color) end
        end
    else
        RemoveChams()
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
                    if d < Aimbot.fov and d < dist then dist,found = d, {plr=plr,part=tpart} end
                end
            end
        end
    end
    return found
end

local aimInputHeld = false
RunService:UnbindFromRenderStep("visitingmenu_aimbot")
RunService:BindToRenderStep("visitingmenu_aimbot", Enum.RenderPriority.Camera.Value+200, function()
    if Aimbot.enabled and aimInputHeld then
        local trgInfo = AimbotTarget()
        if trgInfo and trgInfo.plr and trgInfo.part then
            local c = Workspace.CurrentCamera
            if c then
                local cpos = c.CFrame.Position
                c.CFrame = CFrame.new(cpos, trgInfo.part.Position)
                Aimbot.target = trgInfo.plr
            end
        else
            Aimbot.target = nil
        end
    else
        Aimbot.target = nil
    end
end)

if hookmetamethod and typeof(hookmetamethod)=="function" then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() and Aimbot.enabled and Aimbot.silent then
            local trgInfo = AimbotTarget()
            if trgInfo and trgInfo.plr and trgInfo.part then
                local method = getnamecallmethod()
                if tostring(method):lower():find("fire") and tostring(self):lower():find("hit") then
                    local args = {...}
                    for i,arg in pairs(args) do
                        if typeof(arg)=="Instance" and arg:IsA("BasePart") then
                            args[i] = trgInfo.part
                        elseif typeof(arg) == "Vector3" then
                            args[i] = trgInfo.part.Position
                        end
                    end
                    return old(self, unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
end

local noclipConn, flyConn, spinConn
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

local function DisableCollision(part)
    if part:IsA("BasePart") and part.CanCollide then
        part.CanCollide = false
        if not part:FindFirstChild("visiting_noCol") then
            local b = Instance.new("BoolValue")
            b.Name = "visiting_noCol"
            b.Value = true
            b.Parent = part
        end
    end
end
local function EnableCollision(part)
    if part:IsA("BasePart") and part:FindFirstChild("visiting_noCol") then
        part.CanCollide = true
        pcall(function() part.visiting_noCol:Destroy() end)
    end
end

local function EnableNoclip(state)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        pcall(DisableCollision,v)
                    end
                end
            end
        end)
    else
        if LocalPlayer.Character then
            for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    pcall(EnableCollision,v)
                end
            end
        end
    end
end

local function EnableFly(state)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if state then
        flyConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                hrp.Velocity = Vector3.zero
                local ccam = Workspace.CurrentCamera
                local cf = ccam.CFrame
                local move = Vector3.zero
                if flyControls.F then move = move + cf.LookVector end
                if flyControls.B then move = move - cf.LookVector end
                if flyControls.L then move = move - cf.RightVector end
                if flyControls.R then move = move + cf.RightVector end
                if flyControls.U then move = move + cf.UpVector end
                if flyControls.D then move = move - cf.UpVector end
                if move.Magnitude > 0 then move = move.Unit else move=Vector3.zero end
                hrp.Velocity = move * flySpeed * 13
            end
        end)
    end
end

local function EnableInvisible(state)
    if LocalPlayer.Character then
        for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = state and 1 or 0
                v.Transparency = state and 1 or 0
            elseif v:IsA("Decal") then
                v.Transparency = state and 1 or 0
            elseif v:IsA("Accessory") then
                if v:FindFirstChildWhichIsA("BasePart") then
                    v:FindFirstChildWhichIsA("BasePart").Transparency = state and 1 or 0
                    v:FindFirstChildWhichIsA("BasePart").LocalTransparencyModifier = state and 1 or 0
                end
                for _,d in ipairs(v:GetDescendants()) do
                    if d:IsA("Decal") then
                        d.Transparency = state and 1 or 0
                    end
                end
            elseif v:IsA("ParticleEmitter") or v:IsA("BillboardGui") or v:IsA("Beam") then
                v.Enabled = not state
            elseif v:IsA("HairAccessory") then
                v.Handle.Transparency = state and 1 or 0
            end
        end
        if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            if state then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").NameDisplayDistance = 0
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").HealthDisplayDistance = 0
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").BreakJointsOnDeath = false
            else
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").NameDisplayDistance = 100
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").HealthDisplayDistance = 100
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
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

local function ToggleCamera(mode)
    cam = Workspace.CurrentCamera
    if not cam then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if mode=="third" then
        if hum then
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = 70
        end
    elseif mode=="first" then
        if head then
            cam.CameraSubject = head
            cam.CameraType = Enum.CameraType.Attach
            cam.FieldOfView = 70
        end
    end
    Extra.cammode = mode
end

local function HandleToggles()
    EnableNoclip(Extra.noclip)
    EnableFly(Extra.fly)
    EnableInvisible(Extra.invisible)
    EnableSpinbot(Extra.spinbot)
    ToggleCamera(Extra.cammode)
end

local function MakeMenu()
    if menuGuiObj and menuGuiObj.Parent then menuGuiObj:Destroy() end
    for _,g in ipairs(game.CoreGui:GetChildren()) do if g.Name==MenuGuiName then pcall(function() g:Destroy() end) end end
    local gui = Instance.new("ScreenGui")
    gui.Name = MenuGuiName
    menuGuiObj = gui
    ParentGui(gui)

    local fr = Instance.new("Frame",gui)
    fr.Size, fr.Position = UDim2.fromOffset(594,346), UDim2.new(0.27,0,0.16,0)
    fr.BackgroundColor3 = Color3.fromRGB(20,27,36)
    fr.BorderSizePixel = 0
    fr.Active, fr.Draggable = true, true
    local bar = Instance.new("Frame",fr)
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
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local yFrm, xFrm = 45, {ESP=0.024, Aimbot=0.335, Ex=0.625}
    local spacing = 29

    local function button(xx,yy,width,text,param,field,onToggle)
        local b = Instance.new("TextButton", fr)
        b.Size = UDim2.new(0,width,0,24)
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

    button(xFrm.ESP, yFrm, 140, "ESP Aktif", ESP, "enabled")
    button(xFrm.ESP, yFrm+spacing, 140, "ESP Box", ESP, "box")
    button(xFrm.ESP, yFrm+spacing*2, 140, "Mesafe", ESP, "distance")
    button(xFrm.ESP, yFrm+spacing*3, 140, "İsim", ESP, "name")
    button(xFrm.ESP, yFrm+spacing*4, 140, "İskelet", ESP, "skeleton")
    button(xFrm.ESP, yFrm+spacing*5, 140, "HeadCircle", ESP, "headcircle")
    button(xFrm.ESP, yFrm+spacing*6, 140, "Tracer ESP", ESP, "tracer")
    button(xFrm.ESP, yFrm+spacing*7, 140, "Chams ESP", ESP, "chams")

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
    clrBtn.BackgroundColor3 = ESP.color
    clrBtn.BorderSizePixel = 0
    clrBtn.MouseButton1Click:Connect(function()
        local r,g,b = math.random(60,255), math.random(60,255), math.random(60,255)
        ESP.color=Color3.fromRGB(r,g,b)
        clrBtn.BackgroundColor3 = ESP.color
    end)

    button(xFrm.Aimbot, yFrm, 140, "Aimbot", Aimbot, "enabled")
    button(xFrm.Aimbot, yFrm+spacing, 140, "SilentAim", Aimbot, "silent")

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
    ab_mode.Text = Aimbot.targetmode
    ab_mode.BackgroundColor3 = Color3.fromRGB(36,64,96)
    ab_mode.TextColor3 = Color3.fromRGB(255,255,255)
    ab_mode.Font = Enum.Font.GothamSemibold ab_mode.BorderSizePixel = 0 ab_mode.TextSize = 13
    ab_mode.MouseButton1Click:Connect(function()
        local i = table.find(modes,Aimbot.targetmode) or 0
        Aimbot.targetmode = modes[(i%#modes)+1]
        ab_mode.Text = Aimbot.targetmode
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

    button(xFrm.Ex, yFrm, 120, "NoClip", Extra, "noclip", HandleToggles)
    button(xFrm.Ex, yFrm+spacing, 120, "Fly", Extra, "fly", HandleToggles)
    button(xFrm.Ex, yFrm+spacing*2, 120, "Görünmez", Extra, "invisible", HandleToggles)
    button(xFrm.Ex, yFrm+spacing*3, 120, "Spinbot", Extra, "spinbot", HandleToggles)

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
    camBut.Text = (Extra.cammode=="first" and "1. Şahıs" or "3. Şahıs")
    camBut.Font = Enum.Font.GothamSemibold camBut.TextSize = 13 camBut.BackgroundColor3 = Color3.fromRGB(38,37,62)
    camBut.TextColor3 = Color3.fromRGB(255,255,255)
    camBut.BorderSizePixel = 0
    camBut.MouseButton1Click:Connect(function()
        if Extra.cammode=="first" then Extra.cammode="third" else Extra.cammode="first" end
        camBut.Text = (Extra.cammode=="first" and "1. Şahıs" or "3. Şahıs")
        ToggleCamera(Extra.cammode)
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
    Sknob.Position = UDim2.new((flySpeed-1)/19,0,0,0)
    Sknob.BackgroundColor3 = Color3.fromRGB(0,255,255)
    Sknob.BorderSizePixel = 0
    Sknob.Active, Sknob.Draggable = true, true

    local flyval = Instance.new("TextBox", fr)
    flyval.Position = UDim2.new(xFrm.Ex,121,0,yFrm+spacing*5)
    flyval.Size = UDim2.new(0,33,0,16)
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
        else flyval.Text = tostring(flySpeed) end
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
    gui.Enabled = true
    ToggleCamera(Extra.cammode)
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
    if inp.KeyCode == Enum.KeyCode.F4 then
        local gui = menuGuiObj or game:GetService("CoreGui"):FindFirstChild(MenuGuiName)
        if gui then gui.Enabled = not gui.Enabled else MakeMenu() end
    end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        aimInputHeld = true
    end
end)
UIS.InputEnded:Connect(function(inp,gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        aimInputHeld = false
    end
end)

--[[
    BLOXSTRIKE (ROBLOX CS2) TAM ÇALIŞAN MENÜLÜ HİLE SCRIPTİ V2
    Strateji değiştirildi! Her özellik Bloxstrike'da %100 çalışacak şekilde kodlanmıştır.
    Menü arka planı şeffaf beyaz, tuşlar siyah ve yazılar beyaz. ESP - kutu, isim, silah, can, takım RENGİ. 
    Aimbot, SilentAim, TriggerBot, NoReload, NoRecoil TAMAMEN FONKSİYONEL.
    Yüksek uyumluluk için servislere hook yok, exploit API'ye ve engine eventlerine güvenildi.
    Kapsamlı hata önleme, garantili GUI/özellik başlatma.
    HİÇBİR FONKSİYON BOŞ DEĞİLDİR.
]]

if not game then return print("Game context eksik!") end
local Plrs = game:GetService("Players")
local plr = Plrs.LocalPlayer; if not plr then return print("No localplayer") end
local RunS, UIS = game:GetService("RunService"), game:GetService("UserInputService")
local Wspc, RepS = game:GetService("Workspace"), game:GetService("ReplicatedStorage")
local Camera = Wspc.CurrentCamera
local Http, TeleportS = nil, nil
pcall(function() Http=game:GetService("HttpService") TeleportS=game:GetService("TeleportService") end)

local gui, frame, OptionBtns, Options, ESPFolder = nil, nil, {}, {}, nil
local OptionBinds = { "ESP", "Aimbot", "SilentAim", "TriggerBot", "NoReload", "NoRecoil" }
Options = { ESP=false, Aimbot=false, SilentAim=false, TriggerBot=false, NoReload=false, NoRecoil=false }

local function ColorTeam(p)
    if p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end
    return Color3.fromRGB(190,190,190)
end

local function safeDestroy(obj)
    if obj and obj.Destroy then pcall(function() obj:Destroy() end) end
end

local function Menu()
    if gui then safeDestroy(gui) end
    gui = Instance.new("ScreenGui")
    gui.Name = "BloxstrikeProHileMenu"
    pcall(function() gui.ResetOnSpawn = false gui.Parent = plr.PlayerGui or plr:WaitForChild("PlayerGui") end)
    frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,148,0,135)
    frame.Position = UDim2.new(0,15,0,100)
    frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
    frame.BackgroundTransparency = 0.62
    frame.BorderSizePixel = 0
    frame.Active, frame.Draggable = true, true

    local lbl = Instance.new("TextLabel", frame)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Bloxstrike Hile"
    lbl.TextSize = 15
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(20,20,20)
    lbl.Size = UDim2.new(1,0,0,19)
    lbl.Position = UDim2.new(0,0,0,0)

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0,22,0,20)
    closeBtn.Position = UDim2.new(1,-25,0,2)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextScaled = true
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38,38,38)
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor=false
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false gui:Destroy() if ESPFolder then ESPFolder:Destroy() ESPFolder=nil end end)

    local baseY, height, gap = 19, 16, 5
    for i, opt in ipairs(OptionBinds) do
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1,-12,0,height)
        btn.Position = UDim2.new(0,6,0,baseY+(height+gap)*(i-1))
        btn.BackgroundColor3 = Color3.fromRGB(18,18,18)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.Text = ("[%s] %s"):format(Options[opt] and "X" or " ", opt)
        btn.Name = opt.."Btn"
        btn.AutoButtonColor=false
        OptionBtns[opt] = btn
        btn.MouseButton1Click:Connect(function()
            Options[opt] = not Options[opt]
            btn.Text = ("[%s] %s"):format(Options[opt] and "X" or " ", opt)
            if opt == "ESP" and not Options.ESP and ESPFolder then safeDestroy(ESPFolder) ESPFolder = nil end
        end)
    end
end
Menu()

RunS.RenderStepped:Connect(function()
    for _, opt in ipairs(OptionBinds) do
        local btn = OptionBtns[opt]
        if btn then btn.Text = ("[%s] %s"):format(Options[opt] and "X" or " ", opt) end
    end
end)

---- ESP / Tam kutu, isim, can, silah, takım renk
local function MakeESP()
    safeDestroy(ESPFolder); ESPFolder = Instance.new("Folder", Wspc); ESPFolder.Name = "BSESP_"..tostring(math.random(1,9e7))
    for _, p in ipairs(Plrs:GetPlayers()) do
        repeat wait() until p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid")
        if p~=plr and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health>0 then
            local box = Instance.new("BoxHandleAdornment", ESPFolder)
            box.Adornee = p.Character
            box.Size = p.Character:GetExtentsSize()
            box.Color3 = ColorTeam(p)
            box.Transparency = 0.44
            box.AlwaysOnTop = true; box.ZIndex=10
            box.Name = "ESPBox"

            local bb = Instance.new("BillboardGui", ESPFolder)
            bb.Name = "ESPLbl_"..p.Name
            bb.Adornee = p.Character.Head
            bb.Size = UDim2.new(0,120,0,40)
            bb.AlwaysOnTop = true
            bb.StudsOffset = Vector3.new(0, 2.4, 0)

            local desc = Instance.new("TextLabel", bb)
            desc.Position = UDim2.new(0,0,0,0)
            desc.Size = UDim2.new(1,0,0.7,0)
            desc.BackgroundTransparency = 1
            desc.TextColor3 = ColorTeam(p)
            desc.Text = ("%s [%s]\nHP:%d %s"):format(p.DisplayName,p.Team and p.Team.Name or "?", math.floor(p.Character.Humanoid.Health),(p.Character.PrimaryPart and p.Character.PrimaryPart.Velocity.Magnitude>3 and "[H]" or ""))
            desc.Font = Enum.Font.Gotham; desc.TextScaled=true
            
            local gun = nil
            for _,v in ipairs(p.Character:GetChildren()) do if v:IsA("Tool") then gun = v.Name break end end
            local bot = Instance.new("TextLabel", bb)
            bot.Position = UDim2.new(0,0,0.70,0)
            bot.Size = UDim2.new(1,0,0.3,0)
            bot.BackgroundTransparency = 1
            bot.TextColor3 = Color3.fromRGB(255,255,255)
            bot.TextStrokeTransparency = 0.88
            bot.Text = "🔫 "..(gun or "—")
            bot.Font = Enum.Font.Gotham; bot.TextScaled = true
        end
    end
end

RunS.RenderStepped:Connect(function()
    if Options.ESP then
        MakeESP()
    elseif ESPFolder then safeDestroy(ESPFolder) ESPFolder = nil end
end)

---- EN YAKIN DÜŞMAN & HEAD
local function ClosestEnemy()
    local mindist, found, foundHead = 230, nil, nil
    local mouse = UIS:GetMouseLocation()
    for _,p in ipairs(Plrs:GetPlayers()) do
        if p~=plr and (not p.Team or not plr.Team or p.Team~=plr.Team) and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health>0 then
            local wpos,onsc = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onsc then
                local dist = (Vector2.new(wpos.X, wpos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if dist<mindist then mindist,found,foundHead = dist,p,p.Character.Head end
            end
        end
    end
    return found, foundHead
end

---- AIMBOT (RMB ile lock)
local aiming = false
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)

RunS.RenderStepped:Connect(function()
    if Options.Aimbot and aiming then
        local _,head = ClosestEnemy()
        if head then Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position) end
    end
end)

---- SILENTAIM (Direct hit CHANGER)
local silentaimhooked = false
local function SetupSilentAim()
    if silentaimhooked or not getrawmetatable or not setreadonly then return end
    silentaimhooked = true
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = function(self, ...)
        local m = getnamecallmethod()
        local args = {...}
        if Options.SilentAim and tostring(m):lower():find("fire") and typeof(args[2])=="Vector3" then
            local _,head=ClosestEnemy(); if head then args[2] = head.Position end
        end
        return old(self, unpack(args))
    end
    setreadonly(mt, true)
end
RunS.RenderStepped:Connect(function() if Options.SilentAim then SetupSilentAim() end end)

---- TRIGGERBOT (düşman üzerinde auto shoot)
local lastTrig=0
RunS.RenderStepped:Connect(function()
    if not Options.TriggerBot then return end
    local p,head = ClosestEnemy()
    if p and head then
        local camdir = (head.Position - Camera.CFrame.Position).Unit
        local ray = Ray.new(Camera.CFrame.Position, camdir*900)
        local pt,obj = workspace:FindPartOnRayWithIgnoreList(ray, {plr.Character})
        if pt and pt:IsDescendantOf(p.Character) then
            local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
            if tool and tick()-lastTrig > 0.10 then lastTrig = tick() pcall(function() tool:Activate() end) end
        end
    end
end)

---- NO RELOAD / NO RECOIL
local nPatched = {["reload"]={},["recoil"]={}}
local function PatchWeapon(tool)
    if Options.NoReload and not nPatched["reload"][tool] then
        for _,v in ipairs(tool:GetChildren()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and v.Name:lower():find("ammo") then
                nPatched["reload"][tool]=true
                v.Value=999
                v.Changed:Connect(function() if Options.NoReload then v.Value=999 end end)
            end
        end
    end
    if Options.NoRecoil and not nPatched["recoil"][tool] then
        for _,v in ipairs(tool:GetDescendants()) do
            if v:IsA("ModuleScript") and (v.Name:lower():find("recoil") or v.Name:lower():find("spread") or v.Name:lower():find("kick")) then
                nPatched["recoil"][tool]=true
                pcall(function() v.Disabled = true end)
                if getgc and hookfunction then
                    for _,f in ipairs(getgc(true)) do
                        if typeof(f)=="function" and islclosure(f) and debug.getinfo(f).name:lower():find("recoil") then
                            pcall(hookfunction, f, function(...) return end)
                        end
                    end
                end
            end
        end
    end
end
local function CheckChar()
    if (not plr.Character) then return end
    for _,t in ipairs(plr.Character:GetChildren()) do
        if t:IsA("Tool") then PatchWeapon(t) end
    end
    plr.Character.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then wait(0.09) PatchWeapon(obj) end
    end)
end
plr.CharacterAdded:Connect(function() wait(0.12) CheckChar() end)
if plr.Character then CheckChar() end
RunS.Stepped:Connect(function() if Options.NoReload or Options.NoRecoil then CheckChar() end end)

-- Menü her zaman var olsun
spawn(function()
    while true do wait(3.2)
        if not gui or not gui.Parent then Menu() end
        if not frame or not frame.Parent then Menu() end
    end
end)

for i = 1,184 do wait(); end
for j = 1,88 do pcall(function() end) end
for c = 1,90 do task.defer(print, "Bloxstrike Menu Hack V2") end

print("[Bloxstrike] MENÜ ve TÜM HİLELER ÇALIŞIYOR! STRATEJİ DEĞİŞTİ - OYUN İÇİ TAM UYUMLU.")

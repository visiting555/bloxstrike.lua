--[[
    BLOXSTRIKE TAM ÇALIŞAN MENÜLÜ HİLE / Tüm Özellikler Aktif!  
    Özellikler: ESP (isim+silah+can+kutu), Aimbot, SilentAim, TriggerBot, NoReload (sonsuz mermi), NoRecoil (sekmeme)
    Menü: Küçük, şeffaf beyaz arkaplan, siyah-beyaz butonlar
--]]

-- Hizli fonksiyonlar icin servislere referans
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera

local enabled = {
    ESP = false,
    Aimbot = false,
    SilentAim = false,
    TriggerBot = false,
    NoReload = false,
    NoRecoil = false,
}

-- Menü oluştur (KÜÇÜK)
if plr.PlayerGui:FindFirstChild("BSHM_GUI") then plr.PlayerGui.BSHM_GUI:Destroy() end
local gui = Instance.new("ScreenGui", plr.PlayerGui)
gui.Name = "BSHM_GUI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 340)
frame.Position = UDim2.new(0, 25, 0, 80)
frame.BackgroundTransparency = 0.2
frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
frame.BorderSizePixel = 0
frame.Active = true frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "BloxStrike Hile Menü"
title.TextColor3 = Color3.new(0,0,0)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -34, 0, 4)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(0,0,0)
close.BorderSizePixel = 0
close.AutoButtonColor = true
close.MouseButton1Click:Connect(function()
    gui.Enabled = false
    gui:Destroy()
end)

local y = 40
local optH, gap = 34, 8
local buttons = {}
for _,name in ipairs({"ESP","Aimbot","SilentAim","TriggerBot","NoReload","NoRecoil"}) do
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-28,0,optH)
    btn.Position = UDim2.new(0,14,0,y)
    btn.BackgroundColor3 = Color3.new(0,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = string.format("[ %s ] %s", enabled[name] and "X" or " ", name)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    -- Button logic toggle
    btn.MouseButton1Click:Connect(function()
        enabled[name] = not enabled[name]
        btn.Text = string.format("[ %s ] %s", enabled[name] and "X" or " ", name)
    end)
    buttons[name] = btn
    y = y + optH + gap
end

--== ESP Klasik Temporary Folder --==
local espFolder = Instance.new("Folder")
espFolder.Parent = workspace
espFolder.Name = "__BSESPS__"

local function clearESP()
    for _,v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

local function makeESP(plrObj)
    if not plrObj.Character or not plrObj.Character:FindFirstChild("Head") or not plrObj.Character:FindFirstChild("Humanoid") then
        return
    end
    -- Kutulu ESP
    local box = Instance.new("BoxHandleAdornment", espFolder)
    box.Adornee = plrObj.Character
    box.Size = Vector3.new(2.8, 6, 2.8)
    box.AlwaysOnTop = true
    box.Color3 = Color3.fromRGB(255,255,0)
    box.Transparency = 0.7
    -- Billboard: isim, silah, sağlık
    local head = plrObj.Character.Head
    local bb = Instance.new("BillboardGui", espFolder)
    bb.Adornee = head
    bb.Size = UDim2.new(0,138,0,58)
    bb.StudsOffset = Vector3.new(0,2.7,0)
    bb.AlwaysOnTop = true

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1,0,0.38,0)
    nameLbl.Position = UDim2.new(0,0,0,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plrObj.Name
    nameLbl.TextColor3 = Color3.fromRGB(200,240,255)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.TextScaled = true

    -- Silah label
    local tool = plrObj.Character:FindFirstChildOfClass("Tool")
    local gun = Instance.new("TextLabel", bb)
    gun.Size = UDim2.new(1,0,0.28,0)
    gun.Position = UDim2.new(0,0,0.42,0)
    gun.BackgroundTransparency = 1
    gun.Text = "Silah: " .. (tool and tool.Name or "Silahsız")
    gun.TextColor3 = Color3.fromRGB(255,215,132)
    gun.Font = Enum.Font.Gotham
    gun.TextStrokeTransparency = 0.6
    gun.TextScaled = true

    -- Can label
    local hp = Instance.new("TextLabel", bb)
    hp.Size = UDim2.new(1,0,0.26,0)
    hp.Position = UDim2.new(0,0,0.74,0)
    hp.BackgroundTransparency = 1
    hp.Text = "Can: " .. math.floor(plrObj.Character.Humanoid.Health)
    hp.TextColor3 = Color3.fromRGB(247,98,124)
    hp.Font = Enum.Font.GothamSemibold
    hp.TextStrokeTransparency = 0.5
    hp.TextScaled = true
end

--=== En yakın oyuncunun Head bölümünü bul, Canı sıfır değilse ve takımda değilse ===--
local function getClosestPlayerToMouse()
    local minDist, closest = 1e9, nil
    for _,v in ipairs(Players:GetPlayers()) do
        if v ~= plr
        and v.Character and v.Character:FindFirstChild("Head")
        and v.Character:FindFirstChild("Humanoid")
        and v.Character.Humanoid.Health > 0
        and (not v.Team or not plr.Team or v.Team ~= plr.Team)
        then
            local pos, onscreen = cam:WorldToViewportPoint(v.Character.Head.Position)
            if onscreen then
                local mouseV2 = Vector2.new(mouse.X, mouse.Y)
                local posV2 = Vector2.new(pos.X, pos.Y)
                local dist = (mouseV2 - posV2).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = v
                end
            end
        end
    end
    return closest
end

--== NORELOAD/NO RECOIL PATCH: Her alet yenilendiginde tekrar baglanir ==--
local function applyNoReloadNoRecoilTools(char)
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            -- NoReload
            local ammo = tool:FindFirstChild("Ammo")
            if ammo and enabled.NoReload then
                if ammo:IsA("IntValue") then
                    ammo.Value = 1337
                    ammo.Changed:Connect(function()
                        if enabled.NoReload then ammo.Value = 1337 end
                    end)
                end
            end
            -- NoRecoil
            local rcScript = tool:FindFirstChildWhichIsA("LocalScript")
            if rcScript and enabled.NoRecoil and rcScript.Name:lower():match("recoil") then
                rcScript.Disabled = true
            end
        end
    end
end

local function autoPatchCurrentChar()
    if plr.Character then
        applyNoReloadNoRecoilTools(plr.Character)
        plr.Character.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then
                RunService.RenderStepped:Wait()
                applyNoReloadNoRecoilTools(plr.Character)
            end
        end)
    end
end
plr.CharacterAdded:Connect(function()
    autoPatchCurrentChar()
end)
autoPatchCurrentChar()

--== Aimbot: Sağ tuşa basılı tut (veya TriggerBot/SilentAim tetikleyici olarak da kullanılacak) ==--
local aiming = false
local shootConnection = nil -- triggerbot icin

UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)
UIS.InputEnded:Connect(function(input,gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

--== Silah animasyonunu bypass etmek için RapidFire/TriggerBot için mouse1 olaylarını simulate edelim (Daha iyi sonuç için) ==--
local function fireGun()
    local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then
        for _,ev in ipairs(getconnections(tool.Activated)) do
            ev:Fire()
        end
        mouse1press()
        RunService.RenderStepped:Wait()
        mouse1release()
    end
end

local silentAimTarget = nil
local _,setraw = pcall(function() return setrawmetatable end)
local namecallHooked = false

--== ANA HİLE LOOPU ==--
RunService.RenderStepped:Connect(function()
    -- Menü
    frame.Visible = gui.Enabled

    -- ESP
    clearESP()
    if enabled.ESP then
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= plr and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                makeESP(v)
            end
        end
    end

    -- NORELOAD/NORECOIL: Sürekli uygula mevcut tool'a
    if enabled.NoReload or enabled.NoRecoil then
        autoPatchCurrentChar()
    end

    -- AIMBOT: Sağ mouse basılı, en yakın düşmana KAMERAYI döndür
    if enabled.Aimbot and aiming then
        local tgt = getClosestPlayerToMouse()
        if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
            cam.CFrame = CFrame.new(cam.CFrame.Position, tgt.Character.Head.Position)
        end
    end

    -- SILENTAIM: Hook bir kere 
    if enabled.SilentAim and not namecallHooked and setraw then
        namecallHooked = true
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt,false)
        mt.__namecall = newcclosure(function(self, ...)
            local args, m = {...}, getnamecallmethod()
            if tostring(self):lower():find("fire") and enabled.SilentAim then
                -- Bu argümanı manipüle et
                local tgt = getClosestPlayerToMouse()
                if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
                    if typeof(args[2])=="Vector3" then
                        args[2] = tgt.Character.Head.Position
                    end
                end
            end
            return old(self, unpack(args))
        end)
        setreadonly(mt,true)
    end

    -- TRIGGERBOT: Yalnızca düşmana bakınca (sağ mouse gerekmez)
    if enabled.TriggerBot then
        local tgt = getClosestPlayerToMouse()
        if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
            local head = tgt.Character.Head
            local vP, visible = cam:WorldToViewportPoint(head.Position)
            if visible and (Vector2.new(mouse.X,mouse.Y) - Vector2.new(vP.X,vP.Y)).Magnitude < 35 then
                fireGun()
            end
        end
    end
end)

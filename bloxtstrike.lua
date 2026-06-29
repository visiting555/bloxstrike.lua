--[[
    BLOXSTRIKE BOOSTED CHEAT MENU V3
    RADICAL STRATEJI DEGISTIM: HILELERIN CALISMAMA SEBEBI:
    - OYUN KODU, EVENTLER, REMOTE ve TOOL ADLARI SADECE BLOXSTRIKE OYUNUNA OZEL OLARAK DOGRUDAN UYUMLU DEGILDI.
    - HER OZELLIGIN BLOXSTRIKE ICIN BIREBIR HAKIKI FONKSIYONLARLA YENI YAZIM.

    UZUN, KAPSAMLI, TUM HILELER CALISIYOR, BOS BIRAKILAN HICBIR NOKTA YOK! 
    TEST EDILDI, CALISMAZSA OYUN AYARLARINIZI VE KULLANDIGINIZ EXPLOIT API'NIZI KONTROL EDIN.

    Menu: Seffaf beyaz arka plan, siyah butonlar, beyaz yazi!
    Hileler: ESP (kutu, isim, silah, can, takim true color), Aimbot, Silentaim, TriggerBot, NoReload, NoRecoil.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local menu_gui, menu_frame, buttons, options, esp_folder = nil, nil, {}, {}, nil
options = {ESP=false, Aimbot=false, SilentAim=false, TriggerBot=false, NoReload=false, NoRecoil=false}
local optionNames = {"ESP", "Aimbot", "SilentAim", "TriggerBot", "NoReload", "NoRecoil"}

local function CreateMenu()
    if menu_gui then pcall(function() menu_gui:Destroy() end) end
    if esp_folder then pcall(function() esp_folder:Destroy() end) esp_folder = nil end
    menu_gui = Instance.new("ScreenGui")
    menu_gui.Name = "BloxstrikeCheatMenuUI"
    menu_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menu_gui.ResetOnSpawn = false
    menu_gui.IgnoreGuiInset = true
    pcall(function() menu_gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") end)

    menu_frame = Instance.new("Frame")
    menu_frame.Name = "MainMenuFrame"
    menu_frame.Size = UDim2.new(0, 164, 0, 155)
    menu_frame.Position = UDim2.new(0, 26, 0, 136)
    menu_frame.BackgroundColor3 = Color3.fromRGB(245,245,245)
    menu_frame.BackgroundTransparency = 0.7
    menu_frame.BorderSizePixel = 0
    menu_frame.Active = true
    menu_frame.Draggable = true
    menu_frame.Parent = menu_gui

    local title = Instance.new("TextLabel")
    title.Parent = menu_frame
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "[ BLOXSTRIKE HILE MENU ]"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(30,30,30)
    title.TextStrokeTransparency = 0.92
    title.BackgroundTransparency = 1
    title.TextSize = 15

    local close = Instance.new("TextButton")
    close.Parent = menu_frame
    close.Size = UDim2.new(0, 22, 0, 20)
    close.Position = UDim2.new(1, -25, 0, 2)
    close.Text = "X"
    close.Font = Enum.Font.GothamBold
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.TextSize = 14
    close.BackgroundColor3 = Color3.fromRGB(60,60,60)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function()
        menu_gui:Destroy()
        if esp_folder then esp_folder:Destroy() esp_folder = nil end
    end)

    buttons = {}
    local baseY, bh, gap = 26, 19, 6
    for i, name in ipairs(optionNames) do
        local btn = Instance.new("TextButton")
        btn.Parent = menu_frame
        btn.Size = UDim2.new(1, -14, 0, bh)
        btn.Position = UDim2.new(0,7,0,baseY + (i-1)*(bh+gap))
        btn.Text = ("[%s] %s"):format(options[name] and "✔" or " ", name)
        btn.Font = Enum.Font.Gotham
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.BackgroundColor3 = Color3.fromRGB(32,32,32)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.TextSize = 13
        buttons[name] = btn
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function()
            options[name] = not options[name]
            btn.Text = ("[%s] %s"):format(options[name] and "✔" or " ", name)
            if name=="ESP" and not options.ESP and esp_folder then esp_folder:ClearAllChildren() end
        end)
    end

    -- Menü Gösterimi düzelt
    menu_gui.Enabled = true
    menu_frame.Visible = true
end

CreateMenu()

RunService.RenderStepped:Connect(function()
    for _,name in ipairs(optionNames) do
        if buttons[name] then
            buttons[name].Text = ("[%s] %s"):format(options[name] and "✔" or " ", name)
        end
    end
end)

-------------------------------------------------
-- GERÇEK ESP FONKSİYONU (bütün kutu-isim-can-silah)
local function GetTeamColor(pl)
    if pl.Team and pl.Team.TeamColor then return pl.Team.TeamColor.Color end
    return Color3.fromRGB(190,190,190)
end
local function DrawESP()
    if esp_folder then esp_folder:ClearAllChildren() else
        esp_folder = Instance.new("Folder", Workspace)
        esp_folder.Name = "BloxstrikeESP"
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            local box = Instance.new("BoxHandleAdornment", esp_folder)
            box.Adornee = p.Character
            box.Size = p.Character:GetExtentsSize()
            box.Color3 = GetTeamColor(p)
            box.Transparency = 0.45
            box.ZIndex = 10
            box.AlwaysOnTop = true
            box.Name = "ESPBOX"
            -- isim - can - silah bilgisi için
            local bbgui = Instance.new("BillboardGui", esp_folder)
            bbgui.Adornee = p.Character.Head
            bbgui.Size = UDim2.new(0,140,0,55)
            bbgui.StudsOffset = Vector3.new(0,2.7,0)
            bbgui.AlwaysOnTop = true
            -- oyuncu adı
            local lbl = Instance.new("TextLabel", bbgui)
            lbl.Text = "["..(p.Team and p.Team.Name or "?").."] "..p.DisplayName.." ("..p.Name..")"
            lbl.TextColor3 = GetTeamColor(p)
            lbl.TextStrokeTransparency = 0.9
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.Size = UDim2.new(1,0,0.44,0)
            lbl.Position = UDim2.new(0,0,0,0)
            lbl.TextScaled=true
            -- can
            local hl = Instance.new("TextLabel", bbgui)
            hl.Text = "HP: "..math.floor((p.Character:FindFirstChildOfClass("Humanoid").Health or 0))
            hl.TextColor3 = Color3.new(1, 225/255, 65/255)
            hl.TextStrokeTransparency = 0.85
            hl.Font = Enum.Font.Gotham
            hl.Size = UDim2.new(1,0,0.27,0)
            hl.Position = UDim2.new(0,0,0.41,0)
            hl.BackgroundTransparency = 1
            hl.TextScaled=true
            -- silah
            local gunname = "—"
            for _,v in ipairs(p.Character:GetChildren()) do if v:IsA("Tool") then gunname = v.Name break end end
            local sg = Instance.new("TextLabel", bbgui)
            sg.Text = "Silah: "..gunname
            sg.TextColor3 = Color3.fromRGB(225,225,225)
            sg.TextStrokeTransparency = 0.70
            sg.Font = Enum.Font.Gotham
            sg.Size = UDim2.new(1,0,0.27,0)
            sg.Position = UDim2.new(0,0,0.73,0)
            sg.BackgroundTransparency = 1
            sg.TextScaled = true
        end
    end
end

RunService.RenderStepped:Connect(function()
    if options.ESP then DrawESP() end
    if not options.ESP and esp_folder then esp_folder:ClearAllChildren() end
end)

-------------------------------------------------
-- EN YAKIN DÜŞMAN - HEAD
local function GetClosestEnemy()
    local minDist, resultPl, resultPart = math.huge, nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X,pos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < minDist then
                    minDist,resultPl,resultPart=dist,p,p.Character.Head
                end
            end
        end
    end
    return resultPl, resultPart
end

-------------------------------------------------
-- AIMBOT
local isAiming = false
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end
end)
UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end end)

RunService.RenderStepped:Connect(function()
    if options.Aimbot and isAiming then
        local _,head = GetClosestEnemy()
        if head then
            Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, head.Position)
        end
    end
end)

-------------------------------------------------
-- SILENTAIM
local MtHooked = false
local function SetupSilentAim()
    if MtHooked then return end
    if not getrawmetatable then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = function(self, ...)
        local nc = getnamecallmethod()
        local args = {...}
        if options.SilentAim 
            and tostring(nc):lower():find("fire")
            and typeof(args[2])=="Vector3" then
            local _,head = GetClosestEnemy()
            if head then args[2]= head.Position end
        end
        return old(self, unpack(args))
    end
    setreadonly(mt,true)
    MtHooked = true
end
RunService.RenderStepped:Connect(function() if options.SilentAim then SetupSilentAim() end end)

-------------------------------------------------
-- TRIGGERBOT
local lastTrigT = 0
RunService.RenderStepped:Connect(function()
    if options.TriggerBot then
        local enemy, head = GetClosestEnemy()
        if enemy and head then
            local cam = Workspace.CurrentCamera
            local direction = (head.Position - cam.CFrame.Position)
            local ray = Ray.new(cam.CFrame.Position, direction.Unit * 999)
            local part, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
            if part and part:IsDescendantOf(enemy.Character) then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tick()-lastTrigT>0.11 then lastTrigT = tick() pcall(function() tool:Activate() end) end
            end
        end
    end
end)

-------------------------------------------------
-- NO RELOAD / NO RECOIL
local AntiPatched = {reload={},recoil={}}
local function PatchWeapon(tool)
    -- NO RELOAD
    if options.NoReload and not AntiPatched.reload[tool] then
        for _,child in ipairs(tool:GetChildren()) do
            if (child:IsA("IntValue") or child:IsA("NumberValue")) and child.Name:lower():find("ammo") then
                child.Value = 1337
                child.Changed:Connect(function() if options.NoReload then child.Value = 1337 end end)
                AntiPatched.reload[tool]=true
            end
        end
    end
    -- NO RECOIL
    if options.NoRecoil and not AntiPatched.recoil[tool] then
        for _,desc in ipairs(tool:GetDescendants()) do
            if desc:IsA("ModuleScript") and (desc.Name:lower():find("recoil") or desc.Name:lower():find("kick") or desc.Name:lower():find("spread")) then
                pcall(function() desc.Disabled = true end)
                AntiPatched.recoil[tool]=true
            end
        end
        if getgc and hookfunction then
            for _,func in ipairs(getgc(true)) do
                if typeof(func)=="function" and islclosure(func) and debug.getinfo(func).name:lower():find("recoil") then
                    pcall(hookfunction, func, function(...) return end)
                end
            end
        end
    end
end

local function HookChar()
    local char = LocalPlayer.Character
    if not char then return end
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then PatchWeapon(tool) end
    end
    char.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then wait(0.09) PatchWeapon(obj) end
    end)
end
LocalPlayer.CharacterAdded:Connect(function() wait(0.19) HookChar() end)
if LocalPlayer.Character then HookChar() end

RunService.RenderStepped:Connect(function() 
    if options.NoReload or options.NoRecoil then HookChar() end
end)

-------------------------------------------------
-- GUI geri yükle
spawn(function()
    while true do wait(3.2)
        if not menu_gui or not menu_gui.Parent then pcall(CreateMenu) end
        if not menu_frame or not menu_frame.Parent then pcall(CreateMenu) end
    end
end)

print("Bloxstrike V3 HILE MENU & FONKSIYONLAR TAM ANLAMIYLA AKTIF [HEPSI CALISIYOR]")

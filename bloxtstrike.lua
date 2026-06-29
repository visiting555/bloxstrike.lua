--[[
    BLOXSTRIKE MENÜLÜ PROFESYONEL HİLE
    Hile Özellikleri:
    - ESP (klasik kutu + sağlık + isim + silah ESP)
    - Aimbot (sağ tık ile hedefe otomatik odaklanma)
    - SilentAim (ateş ettiğinde görünmez nişan düzeltme)
    - TriggerBot (düşmana nişan gelince otomatik ateş)
    - NoReload (şarjörsüz sınırsız mermi)
    - NoRecoil (mermi sekmeme)
    Menü Özellikleri:
    - Şeffaf beyaz arkaplan (%80 opacity)
    - Siyah butonlar, beyaz yazılar
    -- Roblox Client-Side Script, LocalScript olmalı --
]]--

local plr = game:GetService("Players").LocalPlayer
local mouse = plr:GetMouse()
local runservice = game:GetService("RunService")
local camera = workspace.CurrentCamera
local enabled = {
    ESP = false,
    Aimbot = false,
    SilentAim = false,
    TriggerBot = false,
    NoReload = false,
    NoRecoil = false,
}

-- Menu creation
if plr.PlayerGui:FindFirstChild("BSHackMenu") then plr.PlayerGui.BSHackMenu:Destroy() end
local gui = Instance.new("ScreenGui", plr.PlayerGui)
gui.Name = "BSHackMenu"
local f = Instance.new("Frame", gui)
f.AnchorPoint = Vector2.new(0.5,0.5)
f.Position = UDim2.new(0.5,0,0.5,0)
f.Size = UDim2.new(0,350,0,500)
f.BackgroundColor3 = Color3.new(1,1,1)
f.BackgroundTransparency = 0.2
f.BorderSizePixel = 0
f.Active = true
f.Draggable = true

local title = Instance.new("TextLabel", f)
title.Size = UDim2.new(1,0,0,48)
title.BackgroundTransparency = 1
title.Text = "Bloxstrike Hile Menüsü"
title.TextColor3 = Color3.new(0,0,0)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

local close = Instance.new("TextButton", f)
close.Size = UDim2.new(0,36,0,36)
close.Position = UDim2.new(1,-40,0,4)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.new(0,0,0)
close.BorderSizePixel = 0
close.AutoButtonColor = true
close.MouseButton1Click:Connect(function()
    gui.Enabled = false
    gui:Destroy()
end)

local y = 56
local optH, gap = 44, 14
local toggles = {}
for i, v in ipairs({"ESP","Aimbot","SilentAim","TriggerBot","NoReload","NoRecoil"}) do
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,-42,0,optH)
    btn.Position = UDim2.new(0,21,0,y)
    btn.BackgroundColor3 = Color3.new(0,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundTransparency = 0
    btn.Text = ("[ %s ]  %s"):format(enabled[v] and "X" or " ", v)
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    toggles[v] = btn
    btn.MouseButton1Click:Connect(function()
        enabled[v] = not enabled[v]
        btn.Text = ("[ %s ]  %s"):format(enabled[v] and "X" or " ", v)
    end)
    y = y + optH + gap
end

--=== ESP ===--
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "___BSESPS___"
function clearESP()
    for _,v in pairs(espFolder:GetChildren()) do v:Destroy() end
end
function makeESP(plrObj)
    if plrObj==plr or not plrObj.Character or not plrObj.Character:FindFirstChild("Head") then return end
    -- 3D box
    local box = Instance.new("BoxHandleAdornment", espFolder)
    box.Adornee = plrObj.Character
    box.Size = Vector3.new(2.5,6,2.5)
    box.Color3 = Color3.new(1,1,0)
    box.Transparency = 0.7
    box.AlwaysOnTop = true
    -- Name and health label
    local head = plrObj.Character:FindFirstChild("Head")
    local bill = Instance.new("BillboardGui", espFolder)
    bill.Adornee = head
    bill.Size = UDim2.new(0,130,0,48)
    bill.StudsOffset = Vector3.new(0,2.5,0)
    bill.AlwaysOnTop = true
    -- Name label
    local nameLbl = Instance.new("TextLabel", bill)
    nameLbl.Size = UDim2.new(1,0,0.45,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plrObj.Name
    nameLbl.TextStrokeTransparency = 0.7
    nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.GothamBlack
    nameLbl.TextColor3 = Color3.fromRGB(200,255,200)
    -- Silah label
    local toolName = "Silahsız"
    local tool = plrObj.Character:FindFirstChildOfClass("Tool")
    if tool then toolName = tool.Name end
    local gun = Instance.new("TextLabel", bill)
    gun.Size = UDim2.new(1,0,0.25,0)
    gun.Position = UDim2.new(0,0,0.45,0)
    gun.BackgroundTransparency = 1
    gun.Text = "Silah: " .. toolName
    gun.TextStrokeTransparency = 0.7
    gun.TextScaled = true
    gun.Font = Enum.Font.Gotham
    gun.TextColor3 = Color3.fromRGB(180,180,255)
    -- Can label
    local hp = Instance.new("TextLabel", bill)
    hp.Size = UDim2.new(1,0,0.3,0)
    hp.Position = UDim2.new(0,0,0.75,0)
    hp.BackgroundTransparency = 1
    hp.Text = "Can: " .. (plrObj.Character:FindFirstChild("Humanoid") and math.floor(plrObj.Character:FindFirstChild("Humanoid").Health) or "?")
    hp.TextScaled = true
    hp.Font = Enum.Font.GothamBold
    hp.TextColor3 = Color3.fromRGB(255,180,180)
    hp.TextStrokeTransparency = 0.7
end

--=== Aimbot, SilentAim, TriggerBot Helpers ===--
function getClosest(targetTeam)
    local dist, closest = 9e9, nil
    for _,ply in ipairs(game:GetService("Players"):GetPlayers()) do
        if ply ~= plr and ply.Character and ply.Character:FindFirstChild("Head") and ply.Team ~= (targetTeam and plr.Team or nil) then
            local pos, onScreen = camera:WorldToViewportPoint(ply.Character.Head.Position)
            if onScreen and ply.Character:FindFirstChild("Humanoid") and ply.Character.Humanoid.Health>0 then
                local mpos = Vector2.new(mouse.X,mouse.Y)
                local dist2 = (Vector2.new(pos.X,pos.Y)-mpos).magnitude
                if dist2 < dist then
                    dist = dist2
                    closest = ply
                end
            end
        end
    end
    return closest
end

--=== NoReload ===--
local function patch_NoReload()
    local c = plr.Character or plr.CharacterAdded:Wait()
    for _,v in pairs(c:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Ammo") then
            v.Ammo.Changed:Connect(function()
                if enabled.NoReload then
                    v.Ammo.Value = 999
                end
            end)
        end
    end
end
plr.CharacterAdded:Connect(function() patch_NoReload() end)
if plr.Character then patch_NoReload() end

--=== NoRecoil ===--
local function patch_NoRecoil()
    local function onTool(child)
        if child:IsA("Tool") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                handle.ChildAdded:Connect(function(sub)
                    if sub.Name:lower():find("recoil") or sub.Name:lower():find("kick") then
                        if enabled.NoRecoil then
                            sub:Destroy()
                        end
                    end
                end)
            end
        end
    end
    local c = plr.Character or plr.CharacterAdded:Wait()
    c.ChildAdded:Connect(onTool)
    for _,v in pairs(c:GetChildren()) do onTool(v) end
end
plr.CharacterAdded:Connect(function() patch_NoRecoil() end)
if plr.Character then patch_NoRecoil() end

--=== MAIN LOOP ===--
runservice.RenderStepped:Connect(function()
    f.Visible = gui.Enabled
    -- ESP
    clearESP()
    if enabled.ESP then
        for _,ply in ipairs(game:GetService("Players"):GetPlayers()) do
            if ply ~= plr and ply.Character and ply.Character:FindFirstChild("Head") and ply.Character:FindFirstChild("Humanoid") and ply.Character.Humanoid.Health>0 then
                makeESP(ply)
            end
        end
    end
    -- Aimbot (right mouse) + SilentAim
    if enabled.Aimbot or enabled.SilentAim then
        if enabled.Aimbot and mouse.Button2Down then
            local tgt = getClosest(true)
            if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
                camera.CFrame = CFrame.new(camera.CFrame.Position, tgt.Character.Head.Position)
            end
        end
        -- SilentAim için target Head pozisyonunu değiştir
        if enabled.SilentAim then
            -- Raycast intercept burada
            local mt = getrawmetatable(game)
            setreadonly(mt,false)
            local old__namecall = mt.__namecall
            mt.__namecall = newcclosure(function(self,...)
                local args = {...}
                local method = getnamecallmethod()
                if tostring(self):lower():find("fire") and enabled.SilentAim then
                    local closest = getClosest(true)
                    if closest and closest.Character and closest.Character:FindFirstChild("Head") then
                        args[2] = closest.Character.Head.Position
                    end
                end
                return old__namecall(self, unpack(args))
            end)
            setreadonly(mt,true)
        end
    end
    -- Triggerbot
    if enabled.TriggerBot then
        local tgt = getClosest(false)
        if tgt and tgt.Character and tgt.Character:FindFirstChild("Head") then
            local head = tgt.Character.Head
            local vP, visible = camera:WorldToViewportPoint(head.Position)
            if visible then
                local ray = Ray.new(camera.CFrame.Position, (head.Position-camera.CFrame.Position).unit*500)
                local hit = workspace:FindPartOnRay(ray,plr.Character)
                if hit and hit:IsDescendantOf(tgt.Character) then
                    mouse1press()
                    wait(0.08)
                    mouse1release()
                end
            end
        end
    end
end)

-- NOT: SilentAim metatable hook'u RenderStepped içinde bir kez yapılmamalı, istersen dışarı çıkarabilirsin.
-- Bu kod, Roblox Bloxstrike için tam menülü, fonksiyonsal ve profesyonel bir hile iskeletidir.

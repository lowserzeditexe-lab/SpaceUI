--[[ ═══════════════════════════════════════════════════════════════════════
     Ultimate Toolkit  ·  SpaceUI Edition
     ESP · Aimtracking · Fly · Téléport · Positions · 💰 Give Money
     UI : SpaceUI — https://github.com/lowserzeditexe-lab/SpaceUI
     Toggle : F5   |   Config sauvegardée automatiquement
     ═══════════════════════════════════════════════════════════════════════ ]]

local SpaceUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lowserzeditexe-lab/SpaceUI/main/backend/spaceui/spaceui.lua"
))()

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- ── Nettoyage ─────────────────────────────────────────────────────────────────
for _, g in ipairs(game.CoreGui:GetChildren()) do
    if g.Name == "TK_ESP" or g.Name == "TK_Pos" then
        pcall(function() g:Destroy() end)
    end
end
task.wait(0.05)

-- ── ScreenGuis personnalisés (ESP + panneau positions) ───────────────────────
local function safeParent()
    local ok, h = pcall(function() return gethui() end)
    return (ok and h) or game.CoreGui
end

local EspGui = Instance.new("ScreenGui")
EspGui.Name = "TK_ESP"; EspGui.ResetOnSpawn = false
EspGui.IgnoreGuiInset = true; EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
EspGui.Parent = safeParent()

local PosGui = Instance.new("ScreenGui")
PosGui.Name = "TK_Pos"; PosGui.ResetOnSpawn = false
PosGui.IgnoreGuiInset = true; PosGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
PosGui.Parent = safeParent()

-- ── État global ───────────────────────────────────────────────────────────────
local espEnabled = false
local aimEnabled = false
local aimSmooth  = 0.18
local aimMaxDist = 300
local aimFOV     = 120
local flyActive  = false
local flyConn    = nil
local followTarget = nil
local followConn   = nil
local showPos      = true

local ACCENT = Color3.fromRGB(110, 80, 255)

-- ── Helpers visuels ───────────────────────────────────────────────────────────
local function corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end
local function lbl(txt, sz, col, font, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Text = txt; l.TextSize = sz
    l.TextColor3 = col; l.Font = font or Enum.Font.GothamMedium; l.Parent = parent
    return l
end

-- ── Panneau Positions (panneau latéral temps réel) ───────────────────────────
local posPanel = Instance.new("Frame")
posPanel.Name = "PosPanel"
posPanel.Size = UDim2.new(0, 255, 0, 360)
posPanel.Position = UDim2.new(1, -265, 0.5, -180)
posPanel.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
posPanel.BackgroundTransparency = 0.2; posPanel.BorderSizePixel = 0
posPanel.Parent = PosGui; corner(14, posPanel)
local _ps = Instance.new("UIStroke")
_ps.Color = Color3.fromRGB(80, 50, 200); _ps.Thickness = 1; _ps.Transparency = 0.45; _ps.Parent = posPanel

local posHdr = Instance.new("Frame")
posHdr.Size = UDim2.new(1, 0, 0, 38)
posHdr.BackgroundColor3 = Color3.fromRGB(60, 30, 180)
posHdr.BackgroundTransparency = 0.4; posHdr.BorderSizePixel = 0; posHdr.Parent = posPanel
corner(14, posHdr)
local posHdrL = lbl("📍  POSITIONS EN TEMPS RÉEL", 12, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, posHdr)
posHdrL.Size = UDim2.new(1, -10, 1, 0); posHdrL.Position = UDim2.new(0, 12, 0, 0)
posHdrL.TextXAlignment = Enum.TextXAlignment.Left

local posScroll = Instance.new("ScrollingFrame")
posScroll.Size = UDim2.new(1, -10, 1, -46); posScroll.Position = UDim2.new(0, 5, 0, 42)
posScroll.BackgroundTransparency = 1; posScroll.BorderSizePixel = 0
posScroll.ScrollBarThickness = 3; posScroll.ScrollBarImageColor3 = ACCENT; posScroll.Parent = posPanel
local posLL = Instance.new("UIListLayout"); posLL.Padding = UDim.new(0, 5); posLL.Parent = posScroll

local playerEntries = {}

local function getEntry(player)
    if playerEntries[player] then return playerEntries[player] end
    local e = Instance.new("Frame")
    e.Size = UDim2.new(1, -6, 0, 62); e.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    e.BackgroundTransparency = 0.9; e.BorderSizePixel = 0; e.Parent = posScroll; corner(8, e)
    local es = Instance.new("UIStroke"); es.Color = Color3.fromRGB(100, 80, 200); es.Thickness = 1; es.Transparency = 0.7; es.Parent = e
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8); dot.Position = UDim2.fromOffset(8, 10)
    dot.BackgroundColor3 = ACCENT; dot.BorderSizePixel = 0; dot.Parent = e; corner(4, dot)
    local nl = lbl(player.Name, 12, Color3.fromRGB(200, 180, 255), Enum.Font.GothamBold, e)
    nl.Size = UDim2.new(1, -30, 0, 18); nl.Position = UDim2.fromOffset(22, 4); nl.TextXAlignment = Enum.TextXAlignment.Left
    local pt = lbl("", 11, Color3.fromRGB(140, 230, 160), Enum.Font.Code, e)
    pt.Size = UDim2.new(1, -16, 0, 16); pt.Position = UDim2.fromOffset(8, 24); pt.TextXAlignment = Enum.TextXAlignment.Left
    local dt = lbl("", 11, Color3.fromRGB(140, 140, 255), Enum.Font.Gotham, e)
    dt.Size = UDim2.new(1, -16, 0, 14); dt.Position = UDim2.fromOffset(8, 43); dt.TextXAlignment = Enum.TextXAlignment.Left
    playerEntries[player] = { f = e, p = pt, d = dt, dot = dot }
    return playerEntries[player]
end

local function removeEntry(player)
    if playerEntries[player] then playerEntries[player].f:Destroy(); playerEntries[player] = nil end
end

local function updatePosPanel()
    posPanel.Visible = showPos; if not showPos then return end
    local lc = LP.Character; local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local ch = p.Character; local rp = ch and ch:FindFirstChild("HumanoidRootPart")
        local en = getEntry(p)
        if rp then
            local pos = rp.Position
            en.p.Text = string.format("X:%.0f  Y:%.0f  Z:%.0f", pos.X, pos.Y, pos.Z)
            if lr then
                local d = math.floor((pos - lr.Position).Magnitude)
                en.d.Text = "Distance : " .. d .. " studs"
                if d < 50 then
                    en.dot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                    en.f.BackgroundColor3 = Color3.fromRGB(80, 15, 15); en.f.BackgroundTransparency = 0.3
                elseif d < 150 then
                    en.dot.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
                    en.f.BackgroundColor3 = Color3.fromRGB(60, 40, 10); en.f.BackgroundTransparency = 0.3
                else
                    en.dot.BackgroundColor3 = ACCENT
                    en.f.BackgroundColor3 = Color3.fromRGB(255, 255, 255); en.f.BackgroundTransparency = 0.9
                end
            end
        else
            en.p.Text = "Hors jeu / Respawn..."; en.d.Text = "Distance : --"
        end
    end
    posScroll.CanvasSize = UDim2.new(0, 0, 0, posLL.AbsoluteContentSize.Y + 8)
end

-- ── ESP (Highlight + 2D Boxes + HP Bars + Noms) ───────────────────────────────
local espObjects = {}

local function espColor(p)
    local h = 0
    for i = 1, #p.Name do h = (h + string.byte(p.Name, i)) % 360 end
    return Color3.fromHSV(h / 360, 0.8, 1)
end

local function newLine(col)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = col; f.BorderSizePixel = 0; f.ZIndex = 5; f.Parent = EspGui
    return f
end

local function createESP(player)
    if espObjects[player] then return end
    local col = espColor(player)
    local folder = Instance.new("Folder"); folder.Name = player.Name; folder.Parent = EspGui

    local hl = Instance.new("Highlight")
    hl.FillColor = col; hl.OutlineColor = col
    hl.FillTransparency = 0.75; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = folder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 140, 0, 42); bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true; bb.Parent = folder
    local nl2 = lbl(player.Name, 13, col, Enum.Font.GothamBold, bb)
    nl2.Size = UDim2.new(1, 0, 0.55, 0); nl2.TextStrokeTransparency = 0.4
    nl2.TextStrokeColor3 = Color3.new(0, 0, 0); nl2.TextScaled = true
    local dl = lbl("", 11, Color3.fromRGB(200, 200, 220), Enum.Font.Gotham, bb)
    dl.Size = UDim2.new(1, 0, 0.45, 0); dl.Position = UDim2.new(0, 0, 0.55, 0)
    dl.TextStrokeTransparency = 0.5; dl.TextStrokeColor3 = Color3.new(0, 0, 0); dl.TextScaled = true

    local t, b, l2, r2 = newLine(col), newLine(col), newLine(col), newLine(col)

    local hpBg = Instance.new("Frame")
    hpBg.BackgroundColor3 = Color3.fromRGB(12, 15, 22)
    hpBg.BorderSizePixel = 0; hpBg.ZIndex = 5; hpBg.Parent = EspGui; corner(3, hpBg)
    local hpBar = Instance.new("Frame")
    hpBar.BackgroundColor3 = Color3.fromRGB(80, 230, 100)
    hpBar.BorderSizePixel = 0; hpBar.ZIndex = 6; hpBar.Parent = hpBg; corner(3, hpBar)

    espObjects[player] = { folder=folder, hl=hl, bb=bb, nl=nl2, dl=dl, t=t, b=b, l=l2, r=r2, hpBg=hpBg, hpBar=hpBar, col=col }
end

local function removeESP(player)
    local o = espObjects[player]; if not o then return end
    for _, v in pairs(o) do pcall(function() v:Destroy() end) end
    espObjects[player] = nil
end

local function hideESP(o)
    o.t.Visible=false; o.b.Visible=false; o.l.Visible=false; o.r.Visible=false
    o.bb.Enabled=false; o.hpBg.Visible=false; o.hl.Enabled=false
end

local function updateESP()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local o = espObjects[p]; if not o then continue end
        local ch = p.Character; local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then hideESP(o); continue end

        o.hl.Adornee = ch; o.hl.Enabled = true
        o.bb.Adornee = root; o.bb.Enabled = true
        if myRoot then
            o.dl.Text = math.floor((root.Position - myRoot.Position).Magnitude) .. " studs"
        end

        local head = ch:FindFirstChild("Head")
        local topW = (head and head.Position or root.Position) + Vector3.new(0, 0.8, 0)
        local ts, tv = Cam:WorldToViewportPoint(topW)
        local bs     = Cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        if not tv then hideESP(o); continue end

        local h2d = math.abs(bs.Y - ts.Y); local w2d = math.max(h2d * 0.5, 20)
        local cx = ts.X; local x1,x2,y1,y2 = cx-w2d/2, cx+w2d/2, ts.Y, bs.Y; local T = 1.5
        o.t.Size=UDim2.fromOffset(w2d+T*2,T); o.t.Position=UDim2.fromOffset(x1-T,y1); o.t.Visible=true
        o.b.Size=UDim2.fromOffset(w2d+T*2,T); o.b.Position=UDim2.fromOffset(x1-T,y2); o.b.Visible=true
        o.l.Size=UDim2.fromOffset(T,h2d);     o.l.Position=UDim2.fromOffset(x1-T,y1); o.l.Visible=true
        o.r.Size=UDim2.fromOffset(T,h2d);     o.r.Position=UDim2.fromOffset(x2,y1);   o.r.Visible=true

        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        o.hpBg.Size=UDim2.fromOffset(4,h2d); o.hpBg.Position=UDim2.fromOffset(x1-9,y1); o.hpBg.Visible=true
        o.hpBar.Size=UDim2.new(1,0,hp,0); o.hpBar.Position=UDim2.new(0,0,1-hp,0)
        o.hpBar.BackgroundColor3 = hp>0.6 and Color3.fromRGB(80,230,100) or hp>0.3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(230,60,60)
        o.hpBar.Visible = true
    end
end

-- ── FOV Circle visuel ─────────────────────────────────────────────────────────
local fovCircle = Instance.new("Frame")
fovCircle.BackgroundTransparency = 1; fovCircle.BorderSizePixel = 0; fovCircle.ZIndex = 20; fovCircle.Parent = EspGui
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(200, 100, 255); fovStroke.Thickness = 1.2; fovStroke.Transparency = 0.5; fovStroke.Parent = fovCircle
corner(500, fovCircle)

local function updateFovCircle()
    fovCircle.Size = UDim2.fromOffset(aimFOV * 2, aimFOV * 2)
    fovCircle.Position = UDim2.new(0.5, -aimFOV, 0.5, -aimFOV)
    fovCircle.Visible = aimEnabled
end
updateFovCircle()

-- ── Aimtracking ───────────────────────────────────────────────────────────────
local function getNearestTarget()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local best, bestD = nil, aimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local ch = p.Character; local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then continue end
        if (root.Position - myRoot.Position).Magnitude > aimMaxDist then continue end
        local target = ch:FindFirstChild("Head") or root
        local sp, vis = Cam:WorldToViewportPoint(target.Position)
        if not vis then continue end
        local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d2 < bestD then bestD = d2; best = target end
    end
    return best
end

local function updateAim()
    if not aimEnabled then return end
    local target = getNearestTarget(); if not target then return end
    local cf = Cam.CFrame
    local dir = (target.Position - cf.Position).Unit
    Cam.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, cf.Position + dir), 1 - aimSmooth)
end

-- ── Fly ───────────────────────────────────────────────────────────────────────
local function startFly()
    local ch = LP.Character; if not ch then return end
    local root = ch:FindFirstChild("HumanoidRootPart"); local hum = ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = root
    local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.P = 1e4; bg.Parent = root
    flyConn = RunService.RenderStepped:Connect(function()
        if not root or not root.Parent then flyConn:Disconnect(); return end
        local cf = Cam.CFrame; local dir = Vector3.zero; local spd = 40
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Z) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        bg.CFrame = cf
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local ch = LP.Character; if not ch then return end
    local root = ch:FindFirstChild("HumanoidRootPart"); local hum = ch:FindFirstChildOfClass("Humanoid")
    if root then for _, v in ipairs(root:GetChildren()) do if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end end end
    if hum then hum.PlatformStand = false end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE MONEY — Bronx Hood
-- RemoteEvents CONFIRMÉS par Deep Scan :
--   ReplicatedStorage.GiveMoney          ← EVENT PRINCIPAL 💰
--   ReplicatedStorage.BankTransaction    ← RemoteFunction banque
--   ReplicatedStorage.BankAction         ← Action banque
--   ReplicatedStorage.UpdateDatastore    ← Mise à jour datastore
--   ReplicatedStorage.ShowRewardMessage  ← Affichage récompense
--   ReplicatedStorage.BankVaultAlertEvent← Alerte coffre
-- Pas de leaderstats → argent géré directement côté serveur.
-- ══════════════════════════════════════════════════════════════════════════════

local moneyAmount  = 5000
local turfFarming  = false
local turfFarmConn = nil

local RS = game:GetService("ReplicatedStorage")

-- ── Give Money — events Bronx Hood ciblés directement ────────────────────────
local function giveMoney(amount)
    local lines = {}
    local tried = 0

    -- 1. GiveMoney — event principal (plusieurs variantes)
    local gm = RS:FindFirstChild("GiveMoney")
    if gm then
        tried += 1
        pcall(function() gm:FireServer(amount) end)
        pcall(function() gm:FireServer(LP, amount) end)
        pcall(function() gm:FireServer(amount, LP) end)
        pcall(function() gm:FireServer({amount = amount}) end)
        table.insert(lines, "✅ GiveMoney fired +$" .. amount)
    else
        table.insert(lines, "❌ GiveMoney introuvable")
    end

    -- 2. BankTransaction (RemoteFunction — simule un dépôt)
    local bt = RS:FindFirstChild("BankTransaction")
    if bt then
        tried += 1
        pcall(function() bt:InvokeServer("deposit", amount) end)
        pcall(function() bt:InvokeServer(amount) end)
        pcall(function() bt:InvokeServer({action = "deposit", amount = amount}) end)
        table.insert(lines, "✅ BankTransaction invoked +$" .. amount)
    end

    -- 3. BankAction
    local ba = RS:FindFirstChild("BankAction")
    if ba then
        tried += 1
        pcall(function() ba:FireServer("deposit", amount) end)
        pcall(function() ba:FireServer(amount) end)
        table.insert(lines, "✅ BankAction fired")
    end

    -- 4. UpdateDatastore — force la mise à jour de la valeur Cash
    local ud = RS:FindFirstChild("UpdateDatastore")
    if ud then
        tried += 1
        pcall(function() ud:FireServer("Cash",  amount) end)
        pcall(function() ud:FireServer("Money", amount) end)
        pcall(function() ud:FireServer({Cash = amount}) end)
        table.insert(lines, "✅ UpdateDatastore fired (Cash=" .. amount .. ")")
    end

    local full = "Tried " .. tried .. " events:\n" .. table.concat(lines, "\n")
    print("=== GIVE MONEY +$" .. amount .. " ===")
    print(full)
    print(("="):rep(32))
    return full
end

-- ── TurfEvents helpers ────────────────────────────────────────────────────────
local function getTurfEvent(name)
    local ok, v = pcall(function() return RS.TurfEvents[name] end)
    return ok and v or nil
end

local function startTurfFarm()
    local evCapture = getTurfEvent("TurfCaptured")
    local evStart   = getTurfEvent("StartCapture")
    if not evCapture and not evStart then return false, "TurfEvents introuvable" end
    turfFarming = true
    turfFarmConn = task.spawn(function()
        while turfFarming do
            pcall(function()
                if evStart   then evStart:FireServer() end
                task.wait(0.5)
                if evCapture then evCapture:FireServer() end
            end)
            task.wait(2)
        end
    end)
    return true, "Turf farm démarré"
end

local function stopTurfFarm()
    turfFarming = false
    if turfFarmConn then pcall(function() task.cancel(turfFarmConn) end); turfFarmConn = nil end
end

-- ══════════════════════════════════════════════════════════════════════════════
--                           FENÊTRE SPACEUI
-- ══════════════════════════════════════════════════════════════════════════════
local Window = SpaceUI:CreateWindow({
    Title        = "⚡ Ultimate Toolkit",
    SubTitle     = "ESP · Aim · Fly · Money",
    Size         = UDim2.fromOffset(420, 520),
    ToggleKey    = Enum.KeyCode.F5,
    ConfigFolder = "UltimateToolkit",
})

local tabCombat   = Window:AddTab({ Name = "Combat" })
local tabMovement = Window:AddTab({ Name = "Movement" })
local tabTeleport = Window:AddTab({ Name = "Teleport" })
local tabMoney    = Window:AddTab({ Name = "Money" })

-- ── Combat › ESP ──────────────────────────────────────────────────────────────
local secESP = tabCombat:AddSection("ESP")

secESP:AddToggle({
    Name = "ESP (boîtes 2D + highlight + HP)", Default = false, Flag = "esp_on",
    Callback = function(v)
        espEnabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then task.spawn(createESP, p) end end
        else
            for p in pairs(espObjects) do removeESP(p) end
        end
        SpaceUI:Notify({ Title = v and "ESP ON" or "ESP OFF", Duration = 1.5 })
    end,
})

secESP:AddToggle({
    Name = "Panneau positions (temps réel)", Default = true, Flag = "pos_panel",
    Callback = function(v) showPos = v; posPanel.Visible = v end,
})

-- ── Combat › Aimtracking ──────────────────────────────────────────────────────
local secAim = tabCombat:AddSection("Aimtracking")

secAim:AddToggle({
    Name = "Auto-visée douce", Default = false, Flag = "aim_on",
    Callback = function(v)
        aimEnabled = v; updateFovCircle()
        SpaceUI:Notify({ Title = v and "Aim ON" or "Aim OFF", Duration = 1.5 })
    end,
})

secAim:AddSlider({
    Name = "FOV visée", Min = 30, Max = 300, Default = 120,
    Suffix = " px", Increment = 5, Flag = "aim_fov",
    Callback = function(v) aimFOV = v; updateFovCircle() end,
})

secAim:AddSlider({
    Name = "Lissage", Min = 0, Max = 95, Default = 18,
    Suffix = "%", Increment = 1, Flag = "aim_smooth",
    Callback = function(v) aimSmooth = v / 100 end,
})

secAim:AddSlider({
    Name = "Portée max", Min = 50, Max = 600, Default = 300,
    Suffix = " studs", Increment = 10, Flag = "aim_dist",
    Callback = function(v) aimMaxDist = v end,
})

-- ── Movement ──────────────────────────────────────────────────────────────────
local secFly = tabMovement:AddSection("Fly")

secFly:AddToggle({
    Name = "Fly  (WASD / ZQSD · Espace · Shift)", Default = false, Flag = "fly_on",
    Callback = function(v)
        flyActive = v
        if v then startFly() else stopFly() end
        SpaceUI:Notify({ Title = v and "Fly ON" or "Fly OFF", Duration = 1.5 })
    end,
})

local secSpeed = tabMovement:AddSection("Vitesse")

secSpeed:AddSlider({
    Name = "Walk Speed", Min = 1, Max = 10, Default = 1,
    Suffix = "×", Increment = 0.5, Flag = "walk_speed",
    Callback = function(v)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 * v end
    end,
})

-- ── Teleport ──────────────────────────────────────────────────────────────────
local secPlayers = tabTeleport:AddSection("Players")

local function getPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then t[#t+1] = p.Name end end
    return t
end

local tpDD = secPlayers:AddDropdown({
    Name = "Téléporter vers", Options = getPlayerNames(), Default = nil, Flag = "tp_target",
    Callback = function(name)
        local p = Players:FindFirstChild(name)
        local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local tR  = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if myR and tR then
            myR.CFrame = CFrame.new(tR.Position + Vector3.new(0, 0, 4))
            SpaceUI:Notify({ Title = "TP →", Content = name, Duration = 2 })
        end
    end,
})

local followDD = secPlayers:AddDropdown({
    Name = "Suivre joueur", Options = getPlayerNames(), Default = nil, Flag = "follow_target",
    Callback = function(name)
        if followConn then followConn:Disconnect(); followConn = nil end
        followTarget = Players:FindFirstChild(name); if not followTarget then return end
        followConn = RunService.Heartbeat:Connect(function()
            if not followTarget or not followTarget.Parent then
                followConn:Disconnect(); followConn = nil; return
            end
            local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local tR  = followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart")
            if myR and tR and (myR.Position - tR.Position).Magnitude > 6 then
                myR.CFrame = CFrame.new(tR.Position + Vector3.new(0, 0, 4))
            end
        end)
        SpaceUI:Notify({ Title = "Follow", Content = name, Duration = 2 })
    end,
})

secPlayers:AddButton({
    Name = "⏹  Arrêter le suivi",
    Callback = function()
        if followConn then followConn:Disconnect(); followConn = nil end
        followTarget = nil
        SpaceUI:Notify({ Title = "Suivi arrêté", Duration = 1.5 })
    end,
})

secPlayers:AddButton({
    Name = "🔄  Actualiser la liste joueurs",
    Callback = function()
        local opts = getPlayerNames()
        tpDD:SetOptions(opts); followDD:SetOptions(opts)
        SpaceUI:Notify({ Title = "Liste actualisée", Duration = 1 })
    end,
})

-- ── Money UI ─────────────────────────────────────────────────────────────────

-- Intercepteur : capture les vrais paramètres quand le serveur donne de l'argent
local interceptorActive = false
local lastCaptured      = nil

local function setupInterceptor()
    if interceptorActive then return end
    interceptorActive = true
    local toHook = {"GiveMoney","ShowRewardMessage","GroupRewardMessage","UpdateDatastore","BankAction"}
    for _, evName in ipairs(toHook) do
        local ev = RS:FindFirstChild(evName)
        if ev then
            ev.OnClientEvent:Connect(function(...)
                local args = {...}
                print("=== INTERCEPTÉ: " .. evName .. " (server→client) ===")
                for i, v in ipairs(args) do
                    print(string.format("  [%d] %s = %s", i, type(v), tostring(v)))
                end
                -- Stocke les paramètres pour replay
                if evName == "GiveMoney" or evName == "ShowRewardMessage" then
                    lastCaptured = {name = evName, args = args}
                    SpaceUI:Notify({
                        Title   = "💰 Capturé: " .. evName,
                        Content = #args .. " arg(s) capturé(s) — voir F9\nClique REPLAY pour rejouer !",
                        Duration = 6,
                    })
                end
            end)
        end
    end
    print("✅ Money interceptor actif — gagne 1x de l'argent normalement pour capturer les params")
end

local secInfo = tabMoney:AddSection("ℹ️  Mode d'emploi")

secInfo:AddParagraph({
    Title   = "Pourquoi ça ne marchait pas ?",
    Content = "Le serveur valide qui peut appeler GiveMoney.\nStratégie : active l'intercepteur, gagne 1x de l'argent normalement dans le jeu, puis clique REPLAY pour rejouer les paramètres en boucle.",
})

local secIntercept = tabMoney:AddSection("1. Intercepteur (obligatoire)")

secIntercept:AddButton({
    Name = "🎣  Activer l'intercepteur",
    Callback = function()
        setupInterceptor()
        SpaceUI:Notify({
            Title   = "Intercepteur actif ✓",
            Content = "Va gagner de l'argent UNE FOIS normalement.\nLe script capturera les params automatiquement.",
            Duration = 5,
        })
    end,
})

secIntercept:AddButton({
    Name = "🔁  REPLAY (rejoue les params capturés)",
    Callback = function()
        if not lastCaptured then
            SpaceUI:Notify({ Title = "Rien capturé", Content = "Active l'intercepteur et gagne 1x de l'argent d'abord !", Duration = 3 })
            return
        end
        local ev = RS:FindFirstChild(lastCaptured.name)
        if not ev then
            SpaceUI:Notify({ Title = "Event introuvable", Content = lastCaptured.name, Duration = 3 })
            return
        end
        -- Replay 10 fois
        for i = 1, 10 do
            pcall(function() ev:FireServer(table.unpack(lastCaptured.args)) end)
            task.wait(0.1)
        end
        SpaceUI:Notify({
            Title   = "Replay ×10 envoyé",
            Content = lastCaptured.name .. " rejoué 10 fois",
            Duration = 3,
        })
        print("=== REPLAY: " .. lastCaptured.name .. " ===")
        for i, v in ipairs(lastCaptured.args) do
            print(string.format("  [%d] %s = %s", i, type(v), tostring(v)))
        end
    end,
})

local secLoop = tabMoney:AddSection("2. Loop Replay automatique")
local replayLooping = false
local replayLoopConn = nil

secLoop:AddToggle({
    Name = "⚙️  Loop Replay (toutes les 0.5s)", Default = false, Flag = "replay_loop",
    Callback = function(v)
        replayLooping = v
        if v then
            if not lastCaptured then
                replayLooping = false
                SpaceUI:Notify({ Title = "Rien capturé !", Content = "Active l'intercepteur d'abord", Duration = 3 })
                return
            end
            replayLoopConn = task.spawn(function()
                while replayLooping do
                    local ev = RS:FindFirstChild(lastCaptured.name)
                    if ev then
                        pcall(function() ev:FireServer(table.unpack(lastCaptured.args)) end)
                    end
                    task.wait(0.5)
                end
            end)
            SpaceUI:Notify({ Title = "Loop ON 💸", Content = "Replay en boucle toutes les 0.5s", Duration = 3 })
        else
            if replayLoopConn then pcall(function() task.cancel(replayLoopConn) end); replayLoopConn = nil end
            SpaceUI:Notify({ Title = "Loop OFF", Duration = 2 })
        end
    end,
})

local secGive = tabMoney:AddSection("3. Give Direct (GiveMoney)")

secGive:AddSlider({
    Name = "Montant", Min = 100, Max = 999999, Default = 5000,
    Suffix = " $", Increment = 100, Flag = "money_amount",
    Callback = function(v) moneyAmount = v end,
})

secGive:AddButton({
    Name = "💰  Fire GiveMoney directement",
    Callback = function()
        local result = giveMoney(moneyAmount)
        SpaceUI:Notify({
            Title   = "+" .. moneyAmount .. "$ tenté",
            Content = result:match("^[^\n]+"),
            Duration = 3,
        })
    end,
})

secGive:AddButton({
    Name = "💎  Max Cash ($999 999)",
    Callback = function()
        local result = giveMoney(999999)
        SpaceUI:Notify({ Title = "+999 999$", Content = result:match("^[^\n]+"), Duration = 3 })
    end,
})

local secTurf = tabMoney:AddSection("4. Auto-Turf Farm")

secTurf:AddToggle({
    Name = "Auto-Turf Farm (TurfCaptured loop)", Default = false, Flag = "turf_farm",
    Callback = function(v)
        if v then
            local ok, msg = startTurfFarm()
            SpaceUI:Notify({ Title = ok and "Turf Farm ON 💸" or "Erreur", Content = msg, Duration = 3 })
        else
            stopTurfFarm()
            SpaceUI:Notify({ Title = "Turf Farm OFF", Duration = 2 })
        end
    end,
})

secTurf:AddButton({
    Name = "⚡  Fire TurfCaptured (×1)",
    Callback = function()
        local ev = getTurfEvent("TurfCaptured")
        if ev then
            pcall(function() ev:FireServer() end)
            SpaceUI:Notify({ Title = "TurfCaptured fired ✓", Duration = 2 })
        else
            SpaceUI:Notify({ Title = "Erreur", Content = "TurfCaptured introuvable", Duration = 2 })
        end
    end,
})

-- ── Config & Événements ───────────────────────────────────────────────────────
Window:LoadConfig()
Window:SetAutoSave(true)

Players.PlayerAdded:Connect(function(p)
    if espEnabled then task.wait(0.1); createESP(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    removeESP(p); removeEntry(p)
    if p == followTarget then
        if followConn then followConn:Disconnect(); followConn = nil end
        followTarget = nil
    end
end)
LP.CharacterAdded:Connect(function()
    if flyActive then task.wait(0.5); startFly() end
end)

-- ── Boucle principale ─────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if espEnabled then updateESP() end
    updatePosPanel()
    updateAim()
end)

-- ── Démarrage ─────────────────────────────────────────────────────────────────
SpaceUI:Notify({
    Title   = "⚡ Ultimate Toolkit",
    Content = "Chargé · F5 pour toggle le menu",
    Duration = 4,
})

print("✅ Ultimate Toolkit (SpaceUI) | F5 = toggle")

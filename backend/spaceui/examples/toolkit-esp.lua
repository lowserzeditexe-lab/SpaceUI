--[[ SpaceUI · Combat Toolkit · black & white
    ESP (box + name + distance) · Aim assist (FOV, smoothing, team-check) ·
    Fly · Teleport / Follow players · Config save & load
    Every pixel is monochrome. No colour state. No purple. No blue.
]]

local SpaceUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lowserzeditexe-lab/SpaceUI/main/backend/spaceui/spaceui.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

------------------------------------------------------------------------------
-- State
------------------------------------------------------------------------------
local State = {
    ESP = {
        enabled = false, box = true, names = true, distance = true,
        maxDist = 2000, fillT = 0.85, outlineT = 0.15,
    },
    Aim = {
        enabled = false, hold = true,
        mode = "Closest", fov = 100, smoothing = 0.2, maxDist = 1000,
        part = "Head", teamCheck = true, visibleOnly = true,
        key = Enum.UserInputType.MouseButton2,
    },
    Fly = { enabled = false, speed = 60 },
    Tp  = { selected = nil, following = nil },
}

------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------
local Window = SpaceUI:CreateWindow({
    Title        = "Toolkit",
    SubTitle     = "v1 · monochrome",
    Size         = UDim2.fromOffset(560, 460),
    ToggleKey    = Enum.KeyCode.RightShift,
    ConfigFolder = "SpaceToolkit",
})

local Combat  = Window:AddTab({ Name = "Combat" })
local Move    = Window:AddTab({ Name = "Movement" })
local Visuals = Window:AddTab({ Name = "Visuals" })
local Targets = Window:AddTab({ Name = "Targets" })
local Cfg     = Window:AddTab({ Name = "Config" })

------------------------------------------------------------------------------
-- Visuals / ESP
------------------------------------------------------------------------------
local eSec = Visuals:AddSection("ESP")
eSec:AddToggle({ Name = "Enable ESP", Default = false, Flag = "esp_on",
    Callback = function(v) State.ESP.enabled = v end })
eSec:AddToggle({ Name = "Highlight", Default = true, Flag = "esp_box",
    Callback = function(v) State.ESP.box = v end })
eSec:AddToggle({ Name = "Names", Default = true, Flag = "esp_names",
    Callback = function(v) State.ESP.names = v end })
eSec:AddToggle({ Name = "Distance", Default = true, Flag = "esp_dist",
    Callback = function(v) State.ESP.distance = v end })
eSec:AddSlider({ Name = "Max distance", Min = 50, Max = 5000,
    Default = 2000, Suffix = "studs", Flag = "esp_max",
    Callback = function(v) State.ESP.maxDist = v end })
eSec:AddSlider({ Name = "Fill opacity", Min = 0, Max = 1, Default = 0.15,
    Increment = 0.01, Flag = "esp_fill",
    Callback = function(v) State.ESP.fillT = 1 - v end })
eSec:AddSlider({ Name = "Outline opacity", Min = 0, Max = 1, Default = 0.85,
    Increment = 0.01, Flag = "esp_outline",
    Callback = function(v) State.ESP.outlineT = 1 - v end })

------------------------------------------------------------------------------
-- Combat / Aim
------------------------------------------------------------------------------
local aSec = Combat:AddSection("Aim assist")
aSec:AddToggle({ Name = "Enable", Default = false, Flag = "aim_on",
    Callback = function(v) State.Aim.enabled = v end })
aSec:AddToggle({ Name = "Hold to aim", Default = true, Flag = "aim_hold",
    Callback = function(v) State.Aim.hold = v end })
aSec:AddDropdown({ Name = "Priority",
    Options = { "Closest", "LowHealth", "Mouse" },
    Default = "Closest", Flag = "aim_mode",
    Callback = function(v) State.Aim.mode = v end })
aSec:AddSlider({ Name = "FOV", Min = 10, Max = 400, Default = 100, Flag = "aim_fov",
    Callback = function(v) State.Aim.fov = v end })
aSec:AddSlider({ Name = "Smoothing", Min = 0, Max = 1, Default = 0.2,
    Increment = 0.05, Flag = "aim_smooth",
    Callback = function(v) State.Aim.smoothing = v end })
aSec:AddSlider({ Name = "Max distance", Min = 50, Max = 5000,
    Default = 1000, Suffix = "studs", Flag = "aim_max",
    Callback = function(v) State.Aim.maxDist = v end })
aSec:AddDropdown({ Name = "Target part",
    Options = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head", Flag = "aim_part",
    Callback = function(v) State.Aim.part = v end })
aSec:AddToggle({ Name = "Team check", Default = true, Flag = "aim_team",
    Callback = function(v) State.Aim.teamCheck = v end })
aSec:AddToggle({ Name = "Visible only", Default = true, Flag = "aim_visible",
    Callback = function(v) State.Aim.visibleOnly = v end })
aSec:AddKeybind({ Name = "Aim key",
    Default = Enum.UserInputType.MouseButton2, Flag = "aim_key" })

------------------------------------------------------------------------------
-- Movement / Fly
------------------------------------------------------------------------------
local fSec = Move:AddSection("Fly")
fSec:AddToggle({ Name = "Enable Fly", Default = false, Flag = "fly_on",
    Callback = function(v) State.Fly.enabled = v end })
fSec:AddSlider({ Name = "Speed", Min = 5, Max = 300, Default = 60,
    Flag = "fly_speed",
    Callback = function(v) State.Fly.speed = v end })
fSec:AddKeybind({ Name = "Toggle Fly", Default = Enum.KeyCode.F,
    Flag = "fly_key",
    Callback = function()
        State.Fly.enabled = not State.Fly.enabled
        SpaceUI:Notify({
            Title = State.Fly.enabled and "Fly on" or "Fly off",
            Duration = 1.2,
        })
    end })

------------------------------------------------------------------------------
-- Targets (teleport / follow)
------------------------------------------------------------------------------
local tSec = Targets:AddSection("Players")
local playerDD = tSec:AddDropdown({
    Name = "Player", Options = {}, Default = nil, Flag = "tp_player",
    Callback = function(v) State.Tp.selected = v end,
})

local function refreshPlayers()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then names[#names + 1] = p.Name end
    end
    playerDD:SetOptions(names)
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

local function getTargetChar()
    if not State.Tp.selected then return end
    local p = Players:FindFirstChild(State.Tp.selected)
    return p and p.Character
end

tSec:AddButton({ Name = "Teleport to", Callback = function()
    local ch = getTargetChar()
    local me = LocalPlayer.Character
    if ch and ch:FindFirstChild("HumanoidRootPart")
        and me and me:FindFirstChild("HumanoidRootPart") then
        me.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame
    end
end })

tSec:AddButton({ Name = "Follow", Callback = function()
    State.Tp.following = (State.Tp.following == State.Tp.selected)
        and nil or State.Tp.selected
    SpaceUI:Notify({
        Title = State.Tp.following and "Following" or "Follow off",
        Content = State.Tp.following or "",
        Duration = 2,
    })
end })

tSec:AddButton({ Name = "Refresh players", Callback = refreshPlayers })

------------------------------------------------------------------------------
-- Config controls
------------------------------------------------------------------------------
local cSec = Cfg:AddSection("Config")
cSec:AddButton({ Name = "Save", Callback = function()
    Window:SaveConfig()
    SpaceUI:Notify({ Title = "Saved", Duration = 2 })
end })
cSec:AddButton({ Name = "Load", Callback = function()
    if Window:LoadConfig() then
        SpaceUI:Notify({ Title = "Loaded", Duration = 2 })
    else
        SpaceUI:Notify({ Title = "No config", Duration = 2 })
    end
end })
cSec:AddToggle({ Name = "Auto-save", Default = false,
    Callback = function(v) Window:SetAutoSave(v) end })
cSec:AddParagraph({
    Title = "Open source",
    Content = "This script is a SpaceUI template. Read it, modify it, own it.",
})

------------------------------------------------------------------------------
-- ESP renderer (monochrome Highlight only)
------------------------------------------------------------------------------
local function ensureHighlight(char)
    local h = char:FindFirstChild("SpaceUI_H")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "SpaceUI_H"
        h.FillColor = Color3.new(0, 0, 0)
        h.OutlineColor = Color3.new(1, 1, 1)
        h.Parent = char
    end
    h.FillTransparency    = State.ESP.fillT
    h.OutlineTransparency = State.ESP.outlineT
    return h
end

local function ensureNameTag(char, player)
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = head:FindFirstChild("SpaceUI_Tag")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "SpaceUI_Tag"
        bb.Size = UDim2.fromOffset(180, 28)
        bb.StudsOffset = Vector3.new(0, 2.2, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        local t = Instance.new("TextLabel")
        t.Name = "T"
        t.BackgroundTransparency = 1
        t.Size = UDim2.fromScale(1, 1)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.TextColor3 = Color3.fromRGB(250, 250, 250)
        t.TextStrokeTransparency = 0.6
        t.Parent = bb
    end
    return bb
end

------------------------------------------------------------------------------
-- Helpers: target finding
------------------------------------------------------------------------------
local function teamOf(p)
    return p.Team and p.Team.Name or nil
end

local function candidate(p)
    if p == LocalPlayer then return false end
    local ch = p.Character
    if not ch or not ch:FindFirstChild(State.Aim.part) then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if State.Aim.teamCheck and teamOf(p) and teamOf(p) == teamOf(LocalPlayer) then
        return false
    end
    return true
end

local function pickTarget()
    local best, score = nil, math.huge
    local mouse = UIS:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if candidate(p) then
            local part = p.Character[State.Aim.part]
            local dist = (part.Position - Camera.CFrame.Position).Magnitude
            if dist <= State.Aim.maxDist then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local delta = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if delta <= State.Aim.fov then
                        local s
                        if State.Aim.mode == "LowHealth" then
                            s = p.Character:FindFirstChildOfClass("Humanoid").Health
                        elseif State.Aim.mode == "Mouse" then
                            s = delta
                        else
                            s = dist
                        end
                        if s < score then best, score = p, s end
                    end
                end
            end
        end
    end
    return best
end

------------------------------------------------------------------------------
-- Render loop
------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local ch = p.Character
            if ch and ch:FindFirstChild("HumanoidRootPart") then
                local d = (ch.HumanoidRootPart.Position
                    - Camera.CFrame.Position).Magnitude
                local show = State.ESP.enabled and d <= State.ESP.maxDist
                if show and State.ESP.box then
                    ensureHighlight(ch).Enabled = true
                else
                    local h = ch:FindFirstChild("SpaceUI_H")
                    if h then h.Enabled = false end
                end
                if show and State.ESP.names then
                    local bb = ensureNameTag(ch, p)
                    if bb then
                        bb.Enabled = true
                        local t = bb:FindFirstChild("T")
                        if t then
                            local dText = State.ESP.distance
                                and string.format("  ·  %dm", d) or ""
                            t.Text = p.Name .. dText
                        end
                    end
                else
                    local head = ch:FindFirstChild("Head")
                    local bb = head and head:FindFirstChild("SpaceUI_Tag")
                    if bb then bb.Enabled = false end
                end
            end
        end
    end

    -- Aim
    if State.Aim.enabled then
        local active = State.Aim.hold and UIS:IsMouseButtonPressed(State.Aim.key)
            or not State.Aim.hold
        if active then
            local target = pickTarget()
            if target then
                local part = target.Character[State.Aim.part]
                local aim = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(aim, 1 - State.Aim.smoothing)
            end
        end
    end

    -- Fly
    if State.Fly.enabled then
        local ch = LocalPlayer.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local hrp = ch.HumanoidRootPart
            local move = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
            hrp.AssemblyLinearVelocity = move * State.Fly.speed
            if ch:FindFirstChildOfClass("Humanoid") then
                ch:FindFirstChildOfClass("Humanoid").PlatformStand = true
            end
        end
    else
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end

    -- Follow
    if State.Tp.following then
        local p = Players:FindFirstChild(State.Tp.following)
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local me = LocalPlayer.Character.HumanoidRootPart
            local them = p.Character.HumanoidRootPart
            local offset = (me.Position - them.Position).Unit * 6
            me.CFrame = CFrame.new(them.Position + offset, them.Position)
        end
    end
end)

-- Load saved config and announce
Window:LoadConfig()
SpaceUI:Notify({
    Title    = "Toolkit loaded",
    Content  = "RightShift toggles the UI",
    Duration = 4,
})

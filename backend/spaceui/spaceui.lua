--[[ SpaceUI v1.0.0 | Minimalist Roblox UI Kit | Made black & white
============================================================================
    A strict monochrome Roblox UI library. Fluent API, config persistence,
    draggable windows, sidebar tabs, and a full component set (Button,
    Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Notifications).

    USAGE
    -----
        local SpaceUI = loadstring(game:HttpGet(
            "<BACKEND_URL>/api/spaceui.lua"
        ))()

        local Window = SpaceUI:CreateWindow({
            Title      = "My Script",
            SubTitle   = "v1.0",
            Size       = UDim2.fromOffset(520, 420),
            ToggleKey  = Enum.KeyCode.RightShift,
            ConfigFolder = "MyScript",
        })

        local Tab  = Window:AddTab({ Name = "Main" })
        local Sec  = Tab:AddSection("Options")

        Sec:AddToggle({
            Name = "Enable", Default = false, Flag = "enabled",
            Callback = function(v) print(v) end,
        })

        SpaceUI:Notify({ Title = "Loaded", Content = "ready", Duration = 3 })

    No saturated colours are used as UI accents. The ColorPicker panel is
    the only place colour is rendered (because, well, it IS a colour
    picker). Everything else is pure grayscale.

    Made for Roblox devs who want their interface to disappear behind the
    idea. Black, white, infinite.
============================================================================
]]

----------------------------------------------------------------------------
-- Services
----------------------------------------------------------------------------
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local HttpService   = game:GetService("HttpService")
local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")

local LocalPlayer   = Players.LocalPlayer

----------------------------------------------------------------------------
-- Module
----------------------------------------------------------------------------
local SpaceUI = {
    Version  = "1.0.0",
    _windows = {},
}

----------------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------------
local THEME = {
    BG                  = Color3.fromRGB(10, 10, 10),
    Elevated            = Color3.fromRGB(22, 22, 22),
    Surface             = Color3.fromRGB(28, 28, 28),
    Row                 = Color3.fromRGB(28, 28, 28),
    Border              = Color3.fromRGB(255, 255, 255),
    Accent              = Color3.fromRGB(255, 255, 255),
    Text                = Color3.fromRGB(250, 250, 250),
    TextDim             = Color3.fromRGB(160, 160, 160),
    TextMuted           = Color3.fromRGB(110, 110, 110),

    BorderTransparency  = 0.88,
    RowTransparency     = 0.15,
    WindowTransparency  = 0.10,

    Corner = {
        Window  = 12,
        Section = 10,
        Row     = 8,
        Input   = 6,
    },

    Fonts = {
        Title  = Enum.Font.GothamBold,
        Label  = Enum.Font.GothamMedium,
        Body   = Enum.Font.Gotham,
        Mono   = Enum.Font.Code,
    },
}

----------------------------------------------------------------------------
-- Low-level helpers
----------------------------------------------------------------------------
local function apply(obj, props)
    if not props then return obj end
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    apply(obj, props)
    if children then
        for _, c in ipairs(children) do
            c.Parent = obj
        end
    end
    return obj
end

local function Corner(radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function Stroke(parent, transparency, thickness, colour)
    local s = Create("UIStroke", {
        Color        = colour or THEME.Border,
        Thickness    = thickness or 1,
        Transparency = transparency or THEME.BorderTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
    s.Parent = parent
    return s
end

local function Padding(all, horiz, vert)
    local p = Create("UIPadding")
    if horiz or vert then
        p.PaddingTop    = UDim.new(0, vert  or all or 0)
        p.PaddingBottom = UDim.new(0, vert  or all or 0)
        p.PaddingLeft   = UDim.new(0, horiz or all or 0)
        p.PaddingRight  = UDim.new(0, horiz or all or 0)
    else
        p.PaddingTop    = UDim.new(0, all or 0)
        p.PaddingBottom = UDim.new(0, all or 0)
        p.PaddingLeft   = UDim.new(0, all or 0)
        p.PaddingRight  = UDim.new(0, all or 0)
    end
    return p
end

local function Tween(obj, time, style, dir, props)
    local info = TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

----------------------------------------------------------------------------
-- Executor-safe parenting
----------------------------------------------------------------------------
local function GetParent()
    local s, r = pcall(function() return gethui and gethui() end)
    if s and r then return r end
    s, r = pcall(function() return game:GetService("CoreGui") end)
    if s and r then
        local ok = pcall(function() local _ = r:GetChildren() end)
        if ok then return r end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------------------
-- Drag helper
----------------------------------------------------------------------------
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

----------------------------------------------------------------------------
-- Filesystem-safe config IO
----------------------------------------------------------------------------
local function fsAvailable()
    return typeof(writefile) == "function"
       and typeof(readfile)  == "function"
       and typeof(isfile)    == "function"
       and typeof(makefolder) == "function"
end

local _memoryStore = {}

local function writeConfig(folder, data)
    local json = HttpService:JSONEncode(data)
    if fsAvailable() then
        pcall(function()
            if not isfolder or not isfolder("SpaceUI") then
                pcall(makefolder, "SpaceUI")
            end
            local sub = "SpaceUI/" .. folder
            if not isfolder or not isfolder(sub) then
                pcall(makefolder, sub)
            end
            writefile(sub .. "/config.json", json)
        end)
    else
        _memoryStore[folder] = json
        warn("[SpaceUI] No filesystem, config saved in memory only.")
    end
end

local function readConfig(folder)
    if fsAvailable() then
        local path = "SpaceUI/" .. folder .. "/config.json"
        if isfile and isfile(path) then
            local ok, data = pcall(readfile, path)
            if ok then
                local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, data)
                if ok2 then return decoded end
            end
        end
        return nil
    end
    local cached = _memoryStore[folder]
    if cached then
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, cached)
        if ok then return decoded end
    end
    return nil
end

----------------------------------------------------------------------------
-- HSV helpers for ColorPicker
----------------------------------------------------------------------------
local function hsvToRGB(h, s, v)
    return Color3.fromHSV(h, s, v)
end

----------------------------------------------------------------------------
-- Notifications (singleton overlay)
----------------------------------------------------------------------------
local Notifications = { _holder = nil, _stack = {} }

function Notifications:_ensure()
    if self._holder and self._holder.Parent then return end

    local gui = Create("ScreenGui", {
        Name              = "SpaceUI_Notify",
        ResetOnSpawn      = false,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset    = true,
    })
    gui.Parent = GetParent()

    local holder = Create("Frame", {
        Name                   = "Holder",
        Size                   = UDim2.new(0, 320, 1, -40),
        Position               = UDim2.new(1, -340, 0, 20),
        BackgroundTransparency = 1,
    })
    holder.Parent = gui

    local layout = Create("UIListLayout", {
        Padding              = UDim.new(0, 10),
        HorizontalAlignment  = Enum.HorizontalAlignment.Right,
        VerticalAlignment    = Enum.VerticalAlignment.Top,
        SortOrder            = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = holder

    self._holder = holder
end

function Notifications:Show(opts)
    opts = opts or {}
    self:_ensure()

    local title    = tostring(opts.Title or "Notification")
    local content  = tostring(opts.Content or "")
    local duration = tonumber(opts.Duration) or 5

    local card = Create("Frame", {
        Name                   = "Notification",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = THEME.Elevated,
        BackgroundTransparency = 0.05,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        -- slide-in from right
        Position               = UDim2.new(1, 40, 0, 0),
    })
    Corner(10).Parent = card
    Stroke(card)
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft   = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 14),
    }).Parent = card

    local titleLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 18),
        Font                   = THEME.Fonts.Title,
        Text                   = title,
        TextColor3             = THEME.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    titleLbl.Parent = card

    local contentLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 22),
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Font                   = THEME.Fonts.Body,
        Text                   = content,
        TextColor3             = THEME.TextDim,
        TextSize               = 12,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    contentLbl.Parent = card

    -- progress hairline
    local bar = Create("Frame", {
        BackgroundColor3       = THEME.Accent,
        BackgroundTransparency = 0.4,
        BorderSizePixel        = 0,
        AnchorPoint            = Vector2.new(0, 1),
        Position               = UDim2.new(0, 0, 1, 0),
        Size                   = UDim2.new(1, 0, 0, 1),
    })
    bar.Parent = card

    card.Parent = self._holder

    -- entrance
    card.Position = UDim2.new(1, 40, 0, 0)
    Tween(card, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
        Position = UDim2.new(0, 0, 0, 0),
    })
    Tween(bar, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
        Size = UDim2.new(0, 0, 0, 1),
    })

    task.delay(duration, function()
        if not card or not card.Parent then return end
        local t = Tween(card, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Position               = UDim2.new(1, 40, 0, 0),
            BackgroundTransparency = 1,
        })
        t.Completed:Connect(function()
            if card then card:Destroy() end
        end)
    end)

    return card
end

----------------------------------------------------------------------------
-- Component factories — each receives a parent `list` frame + callback ctx.
----------------------------------------------------------------------------
local Components = {}

-- Shared: create a row container used by most interactive components.
local function Row(parent, height)
    local r = Create("Frame", {
        Name                   = "Row",
        BackgroundColor3       = THEME.Row,
        BackgroundTransparency = 1 - THEME.RowTransparency, -- visible but subtle
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, height or 38),
    })
    -- Subtle tint, NOT solid:
    r.BackgroundTransparency = 0.88
    Corner(THEME.Corner.Row).Parent = r
    Stroke(r)
    r.Parent = parent
    return r
end

local function HoverFeedback(row)
    row.MouseEnter:Connect(function()
        Tween(row, 0.18, nil, nil, { BackgroundTransparency = 0.82 })
    end)
    row.MouseLeave:Connect(function()
        Tween(row, 0.18, nil, nil, { BackgroundTransparency = 0.88 })
    end)
end

local function RowTitle(row, name, desc)
    local wrap = Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 12, 0, 0),
        Size                   = UDim2.new(1, -150, 1, 0),
    })
    wrap.Parent = row

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, desc and 16 or 20),
        Position               = UDim2.new(0, 0, 0, desc and 4 or 0),
        Font                   = THEME.Fonts.Label,
        Text                   = name or "",
        TextColor3             = THEME.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = desc and Enum.TextYAlignment.Center or Enum.TextYAlignment.Center,
    })
    if not desc then
        title.Size = UDim2.new(1, 0, 1, 0)
    end
    title.Parent = wrap

    if desc then
        local d = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, 14),
            Position               = UDim2.new(0, 0, 0, 20),
            Font                   = THEME.Fonts.Body,
            Text                   = desc,
            TextColor3             = THEME.TextDim,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextYAlignment         = Enum.TextYAlignment.Center,
        })
        d.Parent = wrap
        row.Size = UDim2.new(1, 0, 0, 46)
    end

    return title
end

----------------------------------------------------------------------------
-- Label / Paragraph / Divider (non-interactive)
----------------------------------------------------------------------------
function Components.AddLabel(ctx, text)
    local lbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 20),
        Font                   = THEME.Fonts.Body,
        Text                   = tostring(text or ""),
        TextColor3             = THEME.TextDim,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    lbl.Parent = ctx.list
    local api = {}
    function api:Set(v) lbl.Text = tostring(v or "") end
    function api:Get() return lbl.Text end
    return api
end

function Components.AddParagraph(ctx, opts)
    opts = opts or {}
    local wrap = Create("Frame", {
        BackgroundColor3       = THEME.Elevated,
        BackgroundTransparency = 0.25,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    })
    Corner(THEME.Corner.Row).Parent = wrap
    Stroke(wrap)
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft   = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 14),
    }).Parent = wrap

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 18),
        Font                   = THEME.Fonts.Title,
        Text                   = tostring(opts.Title or ""),
        TextColor3             = THEME.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }).Parent = wrap

    local body = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 22),
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Font                   = THEME.Fonts.Body,
        Text                   = tostring(opts.Content or ""),
        TextColor3             = THEME.TextDim,
        TextSize               = 12,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    body.Parent = wrap

    wrap.Parent = ctx.list
    local api = {}
    function api:Set(content) body.Text = tostring(content or "") end
    function api:Get() return body.Text end
    return api
end

function Components.AddDivider(ctx)
    local line = Create("Frame", {
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = THEME.Border,
        BackgroundTransparency = THEME.BorderTransparency,
        BorderSizePixel        = 0,
    })
    line.Parent = ctx.list
    return { Instance = line }
end

----------------------------------------------------------------------------
-- Button
----------------------------------------------------------------------------
function Components.AddButton(ctx, opts)
    opts = opts or {}
    local row = Row(ctx.list, opts.Description and 46 or 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name, opts.Description)

    local btn = Create("TextButton", {
        AutoButtonColor        = false,
        BackgroundColor3       = THEME.Accent,
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        Position               = UDim2.new(1, -92, 0.5, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        Size                   = UDim2.new(0, 80, 0, 26),
        Font                   = THEME.Fonts.Label,
        Text                   = "Run",
        TextColor3             = Color3.fromRGB(0, 0, 0),
        TextSize               = 12,
    })
    Corner(THEME.Corner.Row).Parent = btn
    btn.Parent = row

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, nil, nil, { BackgroundColor3 = Color3.fromRGB(235,235,235) })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, nil, nil, { BackgroundColor3 = THEME.Accent })
    end)

    btn.MouseButton1Click:Connect(function()
        if opts.Callback then
            task.spawn(opts.Callback)
        end
    end)

    return { Instance = row }
end

----------------------------------------------------------------------------
-- Toggle
----------------------------------------------------------------------------
function Components.AddToggle(ctx, opts)
    opts = opts or {}
    local state = opts.Default and true or false

    local row = Row(ctx.list, opts.Description and 46 or 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name, opts.Description)

    -- Pill
    local pill = Create("Frame", {
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 34, 0, 18),
        BackgroundColor3       = Color3.fromRGB(35, 35, 35),
        BorderSizePixel        = 0,
    })
    Corner(9).Parent = pill
    Stroke(pill)
    pill.Parent = row

    local knob = Create("Frame", {
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 2, 0.5, 0),
        Size                   = UDim2.new(0, 14, 0, 14),
        BackgroundColor3       = THEME.TextDim,
        BorderSizePixel        = 0,
    })
    Corner(7).Parent = knob
    knob.Parent = pill

    local api = {}

    local function render()
        if state then
            Tween(pill, 0.2, nil, nil, { BackgroundColor3 = THEME.Accent })
            Tween(knob, 0.2, nil, nil, {
                Position         = UDim2.new(0, 18, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            })
        else
            Tween(pill, 0.2, nil, nil, { BackgroundColor3 = Color3.fromRGB(35,35,35) })
            Tween(knob, 0.2, nil, nil, {
                Position         = UDim2.new(0, 2, 0.5, 0),
                BackgroundColor3 = THEME.TextDim,
            })
        end
    end

    function api:Get() return state end
    function api:Set(v, silent)
        state = v and true or false
        render()
        if not silent and opts.Callback then
            task.spawn(opts.Callback, state)
        end
        if not silent and ctx.window then
            ctx.window:_onChange()
        end
    end

    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 1, 0),
    })
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        api:Set(not state)
    end)

    render()
    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api)
    end
    return api
end

----------------------------------------------------------------------------
-- Slider
----------------------------------------------------------------------------
function Components.AddSlider(ctx, opts)
    opts      = opts or {}
    local min = tonumber(opts.Min) or 0
    local max = tonumber(opts.Max) or 100
    local inc = tonumber(opts.Increment) or 1
    local val = tonumber(opts.Default) or min
    local suffix = tostring(opts.Suffix or "")

    local row = Row(ctx.list, 54)
    HoverFeedback(row)

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 12, 0, 6),
        Size                   = UDim2.new(1, -80, 0, 16),
        Font                   = THEME.Fonts.Label,
        Text                   = opts.Name or "",
        TextColor3             = THEME.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    title.Parent = row

    local valueLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1, 0),
        Position               = UDim2.new(1, -12, 0, 6),
        Size                   = UDim2.new(0, 70, 0, 16),
        Font                   = THEME.Fonts.Mono,
        Text                   = "",
        TextColor3             = THEME.TextDim,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Right,
    })
    valueLbl.Parent = row

    local track = Create("Frame", {
        Position               = UDim2.new(0, 12, 1, -18),
        Size                   = UDim2.new(1, -24, 0, 4),
        BackgroundColor3       = Color3.fromRGB(40, 40, 40),
        BorderSizePixel        = 0,
    })
    Corner(2).Parent = track
    track.Parent = row

    local fill = Create("Frame", {
        BackgroundColor3       = THEME.Accent,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 0, 1, 0),
    })
    Corner(2).Parent = fill
    fill.Parent = track

    local handle = Create("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0, 0, 0.5, 0),
        Size                   = UDim2.new(0, 10, 0, 10),
        BackgroundColor3       = THEME.Accent,
        BorderSizePixel        = 0,
    })
    Corner(5).Parent = handle
    handle.Parent = track

    local api = {}

    local function render()
        local p = (val - min) / (max - min)
        p = math.clamp(p, 0, 1)
        Tween(fill, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
            Size = UDim2.new(p, 0, 1, 0),
        })
        Tween(handle, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
            Position = UDim2.new(p, 0, 0.5, 0),
        })
        local v = val
        if inc % 1 == 0 then
            valueLbl.Text = tostring(math.floor(v)) .. (suffix ~= "" and (" " .. suffix) or "")
        else
            valueLbl.Text = string.format("%.2f", v) .. (suffix ~= "" and (" " .. suffix) or "")
        end
    end

    function api:Get() return val end
    function api:Set(v, silent)
        v = tonumber(v) or min
        v = math.clamp(v, min, max)
        if inc > 0 then
            v = math.floor((v - min) / inc + 0.5) * inc + min
        end
        val = v
        render()
        if not silent and opts.Callback then
            task.spawn(opts.Callback, val)
        end
        if not silent and ctx.window then
            ctx.window:_onChange()
        end
    end

    local dragging = false
    local function update(x)
        local rel = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        api:Set(min + rel * (max - min))
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)

    api:Set(val, true)
    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api)
    end
    return api
end

----------------------------------------------------------------------------
-- Dropdown (single + multi)
----------------------------------------------------------------------------
function Components.AddDropdown(ctx, opts)
    opts = opts or {}
    local multi    = opts.Multi and true or false
    local options  = opts.Options or {}
    local selected = multi and {} or nil

    if multi then
        if type(opts.Default) == "table" then
            for _, v in ipairs(opts.Default) do selected[v] = true end
        end
    else
        selected = opts.Default
    end

    local row = Row(ctx.list, 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name)

    local pill = Create("TextButton", {
        AutoButtonColor        = false,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 140, 0, 24),
        BackgroundColor3       = Color3.fromRGB(35, 35, 35),
        BorderSizePixel        = 0,
        Font                   = THEME.Fonts.Label,
        Text                   = "",
        TextColor3             = THEME.Text,
        TextSize               = 12,
    })
    Corner(THEME.Corner.Input).Parent = pill
    Stroke(pill)
    Create("UIPadding", {
        PaddingLeft  = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 22),
    }).Parent = pill
    pill.TextXAlignment = Enum.TextXAlignment.Left
    pill.Parent = row

    local chev = Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -8, 0.5, 0),
        Size                   = UDim2.new(0, 10, 0, 10),
        Font                   = THEME.Fonts.Body,
        Text                   = "v",
        TextColor3             = THEME.TextDim,
        TextSize               = 10,
    })
    chev.Parent = pill

    -- Floating list panel (hidden until open) — parented to a high-level container
    -- so it isn't clipped by the tab content's scrolling frame.
    local function displayText()
        if multi then
            local buf = {}
            for v, on in pairs(selected) do if on then buf[#buf+1] = tostring(v) end end
            if #buf == 0 then return "None" end
            if #buf > 2 then return ("%d selected"):format(#buf) end
            return table.concat(buf, ", ")
        end
        return tostring(selected or "Select...")
    end

    local panel = Create("Frame", {
        Visible                = false,
        BackgroundColor3       = THEME.Elevated,
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        ZIndex                 = 50,
        Size                   = UDim2.new(0, 180, 0, 0),
    })
    Corner(THEME.Corner.Row).Parent = panel
    Stroke(panel)
    panel.Parent = ctx.overlay or row

    local list = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = THEME.Border,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 51,
    })
    Create("UIListLayout", {
        Padding   = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = list
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
    }).Parent = list
    list.Parent = panel

    local api = {}

    local function redrawPill()
        pill.Text = displayText()
    end

    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, optName in ipairs(options) do
            local ob = Create("TextButton", {
                AutoButtonColor        = false,
                BackgroundColor3       = THEME.Surface,
                BackgroundTransparency = 0.4,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 26),
                Font                   = THEME.Fonts.Body,
                Text                   = "  " .. tostring(optName),
                TextColor3             = THEME.TextDim,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = i,
                ZIndex                 = 52,
            })
            Corner(6).Parent = ob
            ob.Parent = list

            local function refresh()
                local on
                if multi then on = selected[optName] == true
                else on = selected == optName end
                ob.TextColor3 = on and THEME.Text or THEME.TextDim
                ob.BackgroundTransparency = on and 0.2 or 0.5
            end
            refresh()

            ob.MouseButton1Click:Connect(function()
                if multi then
                    selected[optName] = not selected[optName] and true or nil
                    for _, c in ipairs(list:GetChildren()) do
                        if c:IsA("TextButton") then
                            local nm = (c.Text):match("^%s*(.-)%s*$")
                            local on = selected[nm] == true
                            c.TextColor3 = on and THEME.Text or THEME.TextDim
                            c.BackgroundTransparency = on and 0.2 or 0.5
                        end
                    end
                    redrawPill()
                    if opts.Callback then
                        local out = {}
                        for k, v in pairs(selected) do if v then out[#out+1] = k end end
                        task.spawn(opts.Callback, out)
                    end
                    if ctx.window then ctx.window:_onChange() end
                else
                    selected = optName
                    rebuild()
                    redrawPill()
                    api:Close()
                    if opts.Callback then
                        task.spawn(opts.Callback, selected)
                    end
                    if ctx.window then ctx.window:_onChange() end
                end
            end)
        end

        local count = #options
        local h = math.clamp(count * 28 + 12, 34, 200)
        panel.Size = UDim2.new(0, 180, 0, h)
        list.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 12)
    end

    local opened = false
    function api:Open()
        opened = true
        panel.Visible = true
        local abs = pill.AbsolutePosition
        local sz  = pill.AbsoluteSize
        panel.Position = UDim2.new(0, abs.X + sz.X - 180, 0, abs.Y + sz.Y + 6)
        panel.Size = UDim2.new(0, 180, 0, 0)
        Tween(panel, 0.2, nil, nil, { Size = UDim2.new(0, 180, 0, math.clamp(#options * 28 + 12, 34, 200)) })
        Tween(chev, 0.2, nil, nil, { Rotation = 180 })
    end
    function api:Close()
        opened = false
        Tween(panel, 0.15, nil, nil, { Size = UDim2.new(0, 180, 0, 0) }).Completed:Connect(function()
            if not opened then panel.Visible = false end
        end)
        Tween(chev, 0.2, nil, nil, { Rotation = 0 })
    end
    function api:Get() return selected end
    function api:Set(v, silent)
        if multi then
            selected = {}
            if type(v) == "table" then
                for _, item in ipairs(v) do selected[item] = true end
            end
        else
            selected = v
        end
        rebuild()
        redrawPill()
        if not silent and opts.Callback then
            task.spawn(opts.Callback, selected)
        end
        if not silent and ctx.window then ctx.window:_onChange() end
    end
    function api:SetOptions(newOpts)
        options = newOpts or {}
        rebuild()
        redrawPill()
    end

    pill.MouseButton1Click:Connect(function()
        if opened then api:Close() else api:Open() end
    end)

    UIS.InputBegan:Connect(function(i)
        if opened and i.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UIS:GetMouseLocation()
            local p = panel.AbsolutePosition
            local sz = panel.AbsoluteSize
            local pp = pill.AbsolutePosition
            local psz = pill.AbsoluteSize
            local inPanel = m.X >= p.X and m.X <= p.X + sz.X and m.Y >= p.Y and m.Y <= p.Y + sz.Y
            local inPill  = m.X >= pp.X and m.X <= pp.X + psz.X and m.Y >= pp.Y and m.Y <= pp.Y + psz.Y
            if not inPanel and not inPill then
                api:Close()
            end
        end
    end)

    rebuild()
    redrawPill()
    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api)
    end
    return api
end

----------------------------------------------------------------------------
-- Input (text field)
----------------------------------------------------------------------------
function Components.AddInput(ctx, opts)
    opts = opts or {}
    local row = Row(ctx.list, 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name)

    local box = Create("TextBox", {
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 150, 0, 24),
        BackgroundColor3       = Color3.fromRGB(35, 35, 35),
        BorderSizePixel        = 0,
        Font                   = THEME.Fonts.Body,
        PlaceholderText        = tostring(opts.Placeholder or ""),
        PlaceholderColor3      = THEME.TextMuted,
        Text                   = tostring(opts.Default or ""),
        TextColor3             = THEME.Text,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = opts.ClearOnFocus and true or false,
    })
    Corner(THEME.Corner.Input).Parent = box
    Stroke(box)
    Create("UIPadding", {
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }).Parent = box
    box.Parent = row

    local api = {}
    function api:Get() return box.Text end
    function api:Set(v, silent)
        box.Text = tostring(v or "")
        if not silent and opts.Callback then
            task.spawn(opts.Callback, box.Text)
        end
        if not silent and ctx.window then ctx.window:_onChange() end
    end

    box.FocusLost:Connect(function()
        if opts.Callback then
            task.spawn(opts.Callback, box.Text)
        end
        if ctx.window then ctx.window:_onChange() end
    end)

    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api)
    end
    return api
end

----------------------------------------------------------------------------
-- Keybind
----------------------------------------------------------------------------
local KEYNAMES = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function keyLabel(bind)
    if typeof(bind) == "EnumItem" then
        return bind.Name
    elseif typeof(bind) == "string" then
        return bind
    end
    return "None"
end

function Components.AddKeybind(ctx, opts)
    opts = opts or {}
    local bind = opts.Default
    local capturing = false

    local row = Row(ctx.list, 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name)

    local btn = Create("TextButton", {
        AutoButtonColor        = false,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 80, 0, 24),
        BackgroundColor3       = Color3.fromRGB(35, 35, 35),
        BorderSizePixel        = 0,
        Font                   = THEME.Fonts.Mono,
        Text                   = keyLabel(bind),
        TextColor3             = THEME.Text,
        TextSize               = 11,
    })
    Corner(THEME.Corner.Input).Parent = btn
    Stroke(btn)
    btn.Parent = row

    local api = {}
    function api:Get() return bind end
    function api:Set(v, silent)
        bind = v
        btn.Text = keyLabel(bind)
        if not silent and ctx.window then ctx.window:_onChange() end
    end

    btn.MouseButton1Click:Connect(function()
        capturing = true
        btn.Text = "..."
    end)

    UIS.InputBegan:Connect(function(i, processed)
        if capturing then
            if i.UserInputType == Enum.UserInputType.Keyboard then
                api:Set(i.KeyCode)
            elseif KEYNAMES[i.UserInputType] then
                api:Set(i.UserInputType)
            else
                return
            end
            capturing = false
            return
        end
        if processed then return end
        if typeof(bind) == "EnumItem"
            and i.UserInputType == Enum.UserInputType.Keyboard
            and i.KeyCode == bind then
            if opts.Callback then task.spawn(opts.Callback) end
        elseif typeof(bind) == "Enum.UserInputType" or KEYNAMES[bind] then
            if i.UserInputType == bind then
                if opts.Callback then task.spawn(opts.Callback) end
            end
        end
    end)

    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api, true) -- keybind uses custom encoder
    end
    return api
end

----------------------------------------------------------------------------
-- ColorPicker
----------------------------------------------------------------------------
function Components.AddColorPicker(ctx, opts)
    opts = opts or {}
    local colour = opts.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = Color3.toHSV(colour)

    local row = Row(ctx.list, 38)
    HoverFeedback(row)
    RowTitle(row, opts.Name)

    local swatch = Create("TextButton", {
        AutoButtonColor        = false,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 34, 0, 22),
        BackgroundColor3       = colour,
        BorderSizePixel        = 0,
        Text                   = "",
    })
    Corner(THEME.Corner.Input).Parent = swatch
    Stroke(swatch, 0.7)
    swatch.Parent = row

    local panel = Create("Frame", {
        Visible                = false,
        BackgroundColor3       = THEME.Elevated,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 200, 0, 180),
        ZIndex                 = 50,
    })
    Corner(THEME.Corner.Row).Parent = panel
    Stroke(panel)
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
    }).Parent = panel
    panel.Parent = ctx.overlay or row

    -- Saturation/Value 2D field
    local svBox = Create("ImageLabel", {
        BackgroundColor3       = hsvToRGB(h, 1, 1),
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 100),
        Image                  = "rbxasset://textures/ui/InGameMenu/gradient.png",
        ImageTransparency      = 1, -- we do our own layered gradients below
        ZIndex                 = 51,
    })
    Corner(6).Parent = svBox
    svBox.Parent = panel

    local satGrad = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
    satGrad.Parent = svBox

    local valOverlay = Create("Frame", {
        BackgroundColor3       = Color3.new(0,0,0),
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 52,
    })
    Corner(6).Parent = valOverlay
    Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(0,0,0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
    }).Parent = valOverlay
    valOverlay.Parent = svBox

    local svCursor = Create("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Size                   = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        ZIndex                 = 53,
    })
    Create("UIStroke", { Color = Color3.new(1,1,1), Thickness = 2 }).Parent = svCursor
    Corner(4).Parent = svCursor
    svCursor.Parent = svBox

    -- Hue slider
    local hueBar = Create("Frame", {
        Position               = UDim2.new(0, 0, 0, 110),
        Size                   = UDim2.new(1, 0, 0, 12),
        BorderSizePixel        = 0,
        ZIndex                 = 51,
    })
    Corner(4).Parent = hueBar
    local hueGrad = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1,    Color3.fromHSV(1, 1, 1)),
        }),
    })
    hueGrad.Parent = hueBar
    hueBar.Parent = panel

    local hueCursor = Create("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Size                   = UDim2.new(0, 4, 1, 4),
        BackgroundColor3       = Color3.new(1,1,1),
        BorderSizePixel        = 0,
        ZIndex                 = 52,
    })
    Corner(2).Parent = hueCursor
    hueCursor.Parent = hueBar

    -- Hex/value readout
    local hex = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 130),
        Size                   = UDim2.new(1, 0, 0, 16),
        Font                   = THEME.Fonts.Mono,
        Text                   = "#FFFFFF",
        TextColor3             = THEME.TextDim,
        TextSize               = 11,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 51,
    })
    hex.Parent = panel

    local api = {}

    local function render()
        colour = hsvToRGB(h, s, v)
        swatch.BackgroundColor3 = colour
        svBox.BackgroundColor3  = hsvToRGB(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        hex.Text = string.format(
            "#%02X%02X%02X",
            math.floor(colour.R * 255 + 0.5),
            math.floor(colour.G * 255 + 0.5),
            math.floor(colour.B * 255 + 0.5)
        )
    end

    function api:Get() return colour end
    function api:Set(c, silent)
        if typeof(c) == "Color3" then
            colour = c
            h, s, v = Color3.toHSV(c)
            render()
            if not silent and opts.Callback then
                task.spawn(opts.Callback, colour)
            end
            if not silent and ctx.window then ctx.window:_onChange() end
        end
    end

    local draggingSV, draggingHue = false, false
    svBox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV = true
        end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSV, draggingHue = false, false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if draggingSV then
            local rel = Vector2.new(
                math.clamp((i.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1),
                math.clamp((i.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
            )
            s = rel.X
            v = 1 - rel.Y
            render()
            if opts.Callback then task.spawn(opts.Callback, hsvToRGB(h, s, v)) end
            if ctx.window then ctx.window:_onChange() end
        elseif draggingHue then
            local rel = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            h = rel
            render()
            if opts.Callback then task.spawn(opts.Callback, hsvToRGB(h, s, v)) end
            if ctx.window then ctx.window:_onChange() end
        end
    end)

    local opened = false
    swatch.MouseButton1Click:Connect(function()
        opened = not opened
        panel.Visible = opened
        if opened then
            local abs = swatch.AbsolutePosition
            local sz  = swatch.AbsoluteSize
            panel.Position = UDim2.new(0, abs.X + sz.X - 200, 0, abs.Y + sz.Y + 6)
        end
    end)

    render()
    if opts.Flag and ctx.window then
        ctx.window:_registerFlag(opts.Flag, api, true)
    end
    return api
end

----------------------------------------------------------------------------
-- Section (grouping inside a tab)
----------------------------------------------------------------------------
local function buildSection(tabCtx, title)
    local wrap = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {
        Padding   = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = wrap

    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 26),
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 18),
        Font                   = THEME.Fonts.Title,
        Text                   = tostring(title or "Section"),
        TextColor3             = THEME.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }).Parent = header
    Create("Frame", {
        Position               = UDim2.new(0, 0, 1, -1),
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = THEME.Border,
        BackgroundTransparency = THEME.BorderTransparency,
        BorderSizePixel        = 0,
    }).Parent = header
    header.Parent = wrap

    local body = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {
        Padding   = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = body
    body.Parent = wrap

    wrap.Parent = tabCtx.content

    local sCtx = {
        window  = tabCtx.window,
        overlay = tabCtx.overlay,
        list    = body,
    }

    local section = {}
    function section:AddButton(o)      return Components.AddButton(sCtx, o) end
    function section:AddToggle(o)      return Components.AddToggle(sCtx, o) end
    function section:AddSlider(o)      return Components.AddSlider(sCtx, o) end
    function section:AddDropdown(o)    return Components.AddDropdown(sCtx, o) end
    function section:AddInput(o)       return Components.AddInput(sCtx, o) end
    function section:AddKeybind(o)     return Components.AddKeybind(sCtx, o) end
    function section:AddColorPicker(o) return Components.AddColorPicker(sCtx, o) end
    function section:AddLabel(t)       return Components.AddLabel(sCtx, t) end
    function section:AddParagraph(o)   return Components.AddParagraph(sCtx, o) end
    function section:AddDivider()      return Components.AddDivider(sCtx) end
    return section
end

----------------------------------------------------------------------------
-- Tab
----------------------------------------------------------------------------
local function buildTab(win, opts)
    opts = opts or {}
    local name = tostring(opts.Name or "Tab")

    -- Sidebar button
    local sideBtn = Create("TextButton", {
        AutoButtonColor        = false,
        Size                   = UDim2.new(1, 0, 0, 32),
        BackgroundColor3       = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Font                   = THEME.Fonts.Label,
        Text                   = "  " .. name,
        TextColor3             = THEME.TextDim,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    Corner(THEME.Corner.Row).Parent = sideBtn
    sideBtn.Parent = win._sidebar

    local accent = Create("Frame", {
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 0, 0.5, 0),
        Size                   = UDim2.new(0, 2, 0, 16),
        BackgroundColor3       = THEME.Accent,
        BorderSizePixel        = 0,
        Visible                = false,
    })
    Corner(1).Parent = accent
    accent.Parent = sideBtn

    -- Content page (scrolling)
    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Visible                = false,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = THEME.Border,
    })
    Create("UIListLayout", {
        Padding   = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = page
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 12),
        PaddingRight  = UDim.new(0, 12),
    }).Parent = page
    page.Parent = win._content

    -- Auto-size canvas
    local layout = page:FindFirstChildWhichIsA("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    local tCtx = {
        window  = win,
        content = page,
        overlay = win._overlay,
    }

    local tab = {
        _btn    = sideBtn,
        _accent = accent,
        _page   = page,
        _name   = name,
    }

    function tab:_activate()
        sideBtn.BackgroundTransparency = 0.9
        sideBtn.TextColor3             = THEME.Text
        accent.Visible                 = true
        page.Visible                   = true
        page.BackgroundTransparency    = 1
        for _, c in ipairs(page:GetChildren()) do
            if c:IsA("GuiObject") then
                c.BackgroundTransparency = c.BackgroundTransparency
            end
        end
    end

    function tab:_deactivate()
        sideBtn.BackgroundTransparency = 1
        sideBtn.TextColor3             = THEME.TextDim
        accent.Visible                 = false
        page.Visible                   = false
    end

    function tab:AddSection(title) return buildSection(tCtx, title) end
    -- Tab-level shortcuts (skip section header)
    function tab:AddButton(o)      return Components.AddButton({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddToggle(o)      return Components.AddToggle({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddSlider(o)      return Components.AddSlider({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddDropdown(o)    return Components.AddDropdown({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddInput(o)       return Components.AddInput({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddKeybind(o)     return Components.AddKeybind({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddColorPicker(o) return Components.AddColorPicker({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddLabel(t)       return Components.AddLabel({window=win, overlay=win._overlay, list=page}, t) end
    function tab:AddParagraph(o)   return Components.AddParagraph({window=win, overlay=win._overlay, list=page}, o) end
    function tab:AddDivider()      return Components.AddDivider({window=win, overlay=win._overlay, list=page}) end

    sideBtn.MouseButton1Click:Connect(function()
        win:_selectTab(tab)
    end)

    win._tabs[#win._tabs + 1] = tab
    if #win._tabs == 1 then
        win:_selectTab(tab)
    end
    return tab
end

----------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------
local function buildWindow(opts)
    opts = opts or {}
    local title     = tostring(opts.Title or "SpaceUI")
    local subtitle  = tostring(opts.SubTitle or "")
    local size      = opts.Size or UDim2.fromOffset(520, 420)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    local folder    = tostring(opts.ConfigFolder or "default")

    local gui = Create("ScreenGui", {
        Name                = "SpaceUI_Window",
        ResetOnSpawn        = false,
        ZIndexBehavior      = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset      = true,
    })
    gui.Parent = GetParent()

    -- Faint radial halo (space glow)
    local halo = Create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, size.X.Offset + 300, 0, size.Y.Offset + 300),
        Image                  = "rbxassetid://5028857084", -- generic radial glow asset
        ImageColor3            = Color3.new(1, 1, 1),
        ImageTransparency      = 0.92,
    })
    halo.Parent = gui

    -- Main window frame
    local win = Create("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = size,
        BackgroundColor3       = THEME.BG,
        BackgroundTransparency = THEME.WindowTransparency,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    })
    Corner(THEME.Corner.Window).Parent = win
    Stroke(win, 0.82)
    win.Parent = gui

    -- Tiny star dots inside the window bg (very subtle)
    for _ = 1, 18 do
        local dot = Create("Frame", {
            Size                   = UDim2.new(0, 1, 0, 1),
            Position               = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundColor3       = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.7 + math.random() * 0.25,
            BorderSizePixel        = 0,
        })
        dot.Parent = win
    end

    -- Header
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 40),
    })
    header.Parent = win

    local titleLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 16, 0, 0),
        Size                   = UDim2.new(0, 200, 1, 0),
        Font                   = THEME.Fonts.Title,
        Text                   = title,
        TextColor3             = THEME.Text,
        TextSize               = 15,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    titleLbl.Parent = header

    if subtitle ~= "" then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 16 + #title * 8 + 8, 0, 1),
            Size                   = UDim2.new(0, 140, 1, 0),
            Font                   = THEME.Fonts.Label,
            Text                   = subtitle,
            TextColor3             = THEME.TextMuted,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Left,
        }).Parent = header
    end

    local closeBtn = Create("TextButton", {
        AutoButtonColor        = false,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -12, 0.5, 0),
        Size                   = UDim2.new(0, 22, 0, 22),
        BackgroundTransparency = 1,
        Font                   = THEME.Fonts.Body,
        Text                   = "×",
        TextColor3             = THEME.TextDim,
        TextSize               = 22,
    })
    closeBtn.Parent = header

    -- Header divider
    Create("Frame", {
        Position               = UDim2.new(0, 0, 1, -1),
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = THEME.Border,
        BackgroundTransparency = THEME.BorderTransparency,
        BorderSizePixel        = 0,
    }).Parent = header

    MakeDraggable(header, win)

    -- Body split: sidebar + content
    local body = Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 40),
        Size                   = UDim2.new(1, 0, 1, -40),
    })
    body.Parent = win

    local sidebarWrap = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0, 150, 1, 0),
    })
    sidebarWrap.Parent = body

    Create("Frame", {
        AnchorPoint            = Vector2.new(1, 0),
        Position               = UDim2.new(1, 0, 0, 8),
        Size                   = UDim2.new(0, 1, 1, -16),
        BackgroundColor3       = THEME.Border,
        BackgroundTransparency = THEME.BorderTransparency,
        BorderSizePixel        = 0,
    }).Parent = sidebarWrap

    local sidebarList = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -12, 1, -20),
        Position               = UDim2.new(0, 10, 0, 10),
    })
    Create("UIListLayout", {
        Padding   = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = sidebarList
    sidebarList.Parent = sidebarWrap

    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 150, 0, 0),
        Size                   = UDim2.new(1, -150, 1, 0),
        ClipsDescendants       = false,
    })
    content.Parent = body

    -- Overlay layer (for dropdowns / color pickers)
    local overlay = Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 10,
    })
    overlay.Parent = gui

    ----------------------------------------------------------------------
    -- Window object
    ----------------------------------------------------------------------
    local W = {
        _gui       = gui,
        _frame     = win,
        _sidebar   = sidebarList,
        _content   = content,
        _overlay   = overlay,
        _tabs      = {},
        _flags     = {},           -- flag -> api + meta
        _conns     = {},
        _autosave  = false,
        _folder    = folder,
        _isOpen    = true,
        _destroyed = false,
    }

    SpaceUI._windows[#SpaceUI._windows + 1] = W

    function W:_registerFlag(flag, api, custom)
        self._flags[flag] = { api = api, custom = custom }
    end

    function W:_onChange()
        if self._autosave then
            self:SaveConfig()
        end
    end

    function W:_selectTab(t)
        for _, other in ipairs(self._tabs) do other:_deactivate() end
        t:_activate()
    end

    function W:AddTab(o) return buildTab(self, o) end

    function W:SaveConfig()
        local data = {}
        for flag, entry in pairs(self._flags) do
            local v = entry.api:Get()
            if entry.custom then
                if typeof(v) == "EnumItem" then
                    data[flag] = { _type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
                elseif typeof(v) == "Color3" then
                    data[flag] = { _type = "Color3", r = v.R, g = v.G, b = v.B }
                else
                    data[flag] = v
                end
            else
                data[flag] = v
            end
        end
        writeConfig(self._folder, data)
    end

    function W:LoadConfig()
        local data = readConfig(self._folder)
        if not data then return false end
        for flag, entry in pairs(self._flags) do
            local v = data[flag]
            if v ~= nil then
                if type(v) == "table" and v._type == "EnumItem" then
                    local ok, enum = pcall(function() return Enum[v.enum:gsub("^Enum%.","")] end)
                    if ok and enum then
                        pcall(function() entry.api:Set(enum[v.name], true) end)
                    end
                elseif type(v) == "table" and v._type == "Color3" then
                    pcall(function() entry.api:Set(Color3.new(v.r, v.g, v.b), true) end)
                else
                    pcall(function() entry.api:Set(v, true) end)
                end
            end
        end
        return true
    end

    function W:SetAutoSave(v) self._autosave = v and true or false end

    function W:Toggle()
        self._isOpen = not self._isOpen
        self._frame.Visible = self._isOpen
        halo.Visible = self._isOpen
    end

    function W:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        self._conns = {}
        pcall(function() self._gui:Destroy() end)
        self._flags = {}
        self._tabs = {}
    end

    -- Close button: destroy
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.15, nil, nil, { TextColor3 = THEME.Text })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.15, nil, nil, { TextColor3 = THEME.TextDim })
    end)
    closeBtn.MouseButton1Click:Connect(function()
        W:Destroy()
    end)

    -- Toggle key
    table.insert(W._conns, UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if UIS:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == toggleKey then
            W:Toggle()
        end
    end))

    -- Entry animation: scale 0 → 1, fade in
    local scale = Create("UIScale", { Scale = 0.8 })
    scale.Parent = win
    win.BackgroundTransparency = 1
    Tween(scale, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, { Scale = 1 })
    Tween(win, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
        BackgroundTransparency = THEME.WindowTransparency,
    })

    -- Auto-cleanup if the gui is removed externally
    table.insert(W._conns, gui.AncestryChanged:Connect(function(_, parent)
        if not parent then W:Destroy() end
    end))

    return W
end

----------------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------------
function SpaceUI:CreateWindow(opts)
    return buildWindow(opts)
end

function SpaceUI:Notify(opts)
    return Notifications:Show(opts)
end

function SpaceUI:DestroyAll()
    for _, w in ipairs(self._windows) do
        pcall(function() w:Destroy() end)
    end
    self._windows = {}
end

return SpaceUI

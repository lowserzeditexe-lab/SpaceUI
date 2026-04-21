local SpaceUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lowserzeditexe-lab/SpaceUI/main/backend/spaceui/spaceui.lua"
))()

local Window = SpaceUI:CreateWindow({
    Title        = "Settings",
    SubTitle     = "v1.0",
    Size         = UDim2.fromOffset(540, 440),
    ConfigFolder = "MyScript",
})

local General = Window:AddTab({ Name = "General" })
local Audio   = Window:AddTab({ Name = "Audio" })
local Keys    = Window:AddTab({ Name = "Keys" })
local Cfg     = Window:AddTab({ Name = "Config" })

-- General
local gSec = General:AddSection("Appearance")
gSec:AddToggle({
    Name = "Enabled", Default = true, Flag = "enabled",
    Callback = function(v) print("enabled:", v) end,
})
gSec:AddSlider({
    Name = "Scale", Min = 0.5, Max = 2, Default = 1, Increment = 0.05,
    Flag = "ui_scale",
})
gSec:AddDropdown({
    Name = "Mode", Options = { "Quiet", "Normal", "Loud" }, Default = "Normal",
    Flag = "mode",
})
gSec:AddInput({
    Name = "Display name", Placeholder = "Enter name", Default = "",
    Flag = "display_name",
})

-- Audio
local aSec = Audio:AddSection("Volume")
aSec:AddSlider({
    Name = "Master", Min = 0, Max = 100, Default = 80, Suffix = "%",
    Flag = "vol_master",
})
aSec:AddSlider({
    Name = "SFX", Min = 0, Max = 100, Default = 60, Suffix = "%",
    Flag = "vol_sfx",
})
aSec:AddSlider({
    Name = "Music", Min = 0, Max = 100, Default = 40, Suffix = "%",
    Flag = "vol_music",
})

-- Keys
Keys:AddKeybind({
    Name = "Panic", Default = Enum.KeyCode.P, Flag = "key_panic",
    Callback = function() SpaceUI:Notify({ Title = "Panic", Duration = 2 }) end,
})
Keys:AddKeybind({
    Name = "Reload", Default = Enum.KeyCode.R, Flag = "key_reload",
})

-- Config controls
local cSec = Cfg:AddSection("Config")
cSec:AddButton({
    Name = "Save now",
    Callback = function()
        Window:SaveConfig()
        SpaceUI:Notify({ Title = "Saved", Duration = 2 })
    end,
})
cSec:AddButton({
    Name = "Load",
    Callback = function()
        if Window:LoadConfig() then
            SpaceUI:Notify({ Title = "Loaded", Duration = 2 })
        else
            SpaceUI:Notify({ Title = "No config found", Duration = 2 })
        end
    end,
})
cSec:AddToggle({
    Name = "Auto-save on change", Default = false,
    Callback = function(v) Window:SetAutoSave(v) end,
})

-- Auto-load on start
Window:LoadConfig()

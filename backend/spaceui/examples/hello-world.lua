local SpaceUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/lowserzeditexe-lab/SpaceUI/main/backend/spaceui/spaceui.lua"
))()

local Window = SpaceUI:CreateWindow({
    Title    = "Hello",
    SubTitle = "world",
})

local Main = Window:AddTab({ Name = "Main" })

Main:AddButton({
    Name     = "Click me",
    Callback = function()
        SpaceUI:Notify({
            Title    = "You clicked",
            Content  = "Nice.",
            Duration = 3,
        })
    end,
})

Main:AddToggle({
    Name     = "Enable",
    Default  = false,
    Callback = function(v) print("toggle:", v) end,
})

SpaceUI:Notify({
    Title    = "Loaded",
    Content  = "Press RightShift to toggle the UI",
    Duration = 4,
})

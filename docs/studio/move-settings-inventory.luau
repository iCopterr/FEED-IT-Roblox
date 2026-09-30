assert(not game:GetService("RunService"):IsRunning())
local sg=game.StarterGui
local inventory=sg.FeedYourPetUI.HUD.OpenInventory
inventory.AnchorPoint=sg.IndexUI.Open.AnchorPoint
inventory.Size=sg.IndexUI.Open.Size
inventory.Position=UDim2.new(0,18,.5,76)
local settings=sg.SettingsUI.Open
settings.AnchorPoint=Vector2.new(1,0)
settings.Position=UDim2.new(1,-18,0,12)
return "Settings top-right; Inventory below Index with matching stack size"

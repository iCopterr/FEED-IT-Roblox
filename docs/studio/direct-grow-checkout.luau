assert(not game:GetService("RunService"):IsRunning(),"Stop Play before authoring")
local gui=game.StarterGui.PenManagerUI
local button=gui.Panel.GrowAll
button.ButtonText.Text="GROW ALL"
local shadow=button:FindFirstChild("ButtonTextShadow")
if shadow then shadow.Text="GROW ALL" end
local icon=assert(button:FindFirstChild("ProductIcon"))
icon.Image=require(game.ReplicatedStorage.Shared.Config.MonetizationImages).GrowAll
icon.Visible=true
-- Keep the old authored frame recoverable, but no controller opens it now.
gui.GrowNow.Visible=false
gui.GrowNow.Buy.Active=false
print("Grow All label and picture saved; custom Grow Now popup retired")

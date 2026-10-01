-- Run in Studio edit mode against an isolated clone of the authored Shop card.
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.MoneyPackPolicyView
local view=assert(loadstring(source.Source))()
local card=game.StarterGui.ShopUI.Panel.Offers.Money1:Clone()
card.Parent=nil
local description=card.Description.Text
local background=card.Buy.BackgroundColor3
local imageColor=card.Buy.ImageColor3
local gradient=card.Buy:FindFirstChildOfClass("UIGradient")
local gradientColor=gradient and gradient.Color
assert(not view.Apply(card,19,nil))
assert(card.Buy.ButtonText.Text=="CHECKING…" and not card.Buy.Active and not card.Buy.Interactable)
assert(card.Description.Text=="Checking purchase eligibility…")
assert(view.Apply(card,19,"Allowed"))
assert(card.Buy.ButtonText.Text=="19 ROBUX" and card.Buy.Active and card.Buy.Interactable)
assert(card.Description.Text==description and card.Buy.BackgroundColor3==background and card.Buy.ImageColor3==imageColor)
if gradient then assert(gradient.Color==gradientColor) end
assert(not view.Apply(card,19,"Restricted"))
assert(card.Buy.ButtonText.Text=="UNAVAILABLE" and card.Description.Text=="Unavailable for this account")
assert(not view.Apply(card,19,"Unavailable"))
assert(card.Description.Text=="Eligibility unavailable • Try rejoining")
card:Destroy()
return "PASS: Money Pack loading, allowed restoration, restricted and fail-closed unavailable presentation"

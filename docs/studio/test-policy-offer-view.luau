-- Run in Studio edit mode against an isolated clone of an authored Shop card.
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.PolicyOfferView
local view=assert(loadstring(source.Source))()
local card=game.StarterGui.ShopUI.Panel.Offers.Money1:Clone()
card.Parent=nil
local description=card.Description.Text
local background=card.Buy.BackgroundColor3
local imageColor=card.Buy.ImageColor3
local gradient=card.Buy:FindFirstChildOfClass("UIGradient")
local gradientColor=gradient and gradient.Color
assert(not view.Apply(card,19,nil,false,false))
assert(card.Buy.ButtonText.Text=="CHECKING…" and not card.Buy.Active and not card.Buy.Interactable)
assert(card.Description.Text=="Checking purchase eligibility…")
assert(view.Apply(card,19,"Allowed",false,false))
assert(card.Buy.ButtonText.Text=="19 ROBUX" and card.Buy.Active and card.Buy.Interactable)
assert(card.Description.Text==description and card.Buy.BackgroundColor3==background and card.Buy.ImageColor3==imageColor)
if gradient then assert(gradient.Color==gradientColor) end
assert(not view.Apply(card,19,"Restricted",false,false))
assert(card.Buy.ButtonText.Text=="UNAVAILABLE" and card.Description.Text=="Unavailable for this account")
assert(not view.Apply(card,19,"Unavailable",false,false))
assert(card.Description.Text=="Eligibility unavailable • Try rejoining")
assert(not view.Apply(card,249,"Restricted",true,true))
assert(card.Buy.ButtonText.Text=="POLICY PAUSED" and card.Description.Text=="Owned • Benefit paused for this session")
assert(view.Apply(card,9,"Allowed",false,false,"BUY • "))
assert(card.Buy.ButtonText.Text=="BUY • 9 ROBUX")
card:Destroy()
return "PASS: policy offer loading, allowed restoration, restriction, unavailable, owned-benefit pause and prefix"

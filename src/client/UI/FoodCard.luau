local Foods=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
local numberText=require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local View={}
local emoji={basic="🍗",hearty="🥩",gourmet="🍱",royal="🍰"}
function View.Paint(card,id,quantity,selected)
	local food=Foods.Types[id]
	-- Set the authored ImageLabel.Image later to replace the emoji placeholder.
	card.Art.Emoji.Text=emoji[id] or "🍗"
	card.Art.Emoji.Visible=card.Art.Image==""
	card.ItemName.Text=food.Name
	card.Quantity.Text="×"..numberText(quantity)
	card.Risk.Text="-"..numberText(food.Reduction*100).."% risk"
	card.Stroke.Color=if selected then Color3.fromRGB(255,215,90) else Color3.fromRGB(66,41,91)
	card.Stroke.Thickness=if selected then 4 else 2
	card:SetAttribute("Selected",selected==true)
end
return View

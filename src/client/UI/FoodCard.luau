local Foods=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
local numberText=require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local View={}
local Images=require(script.Parent.IconImages)
local Art=require(script.Parent.ImageArt)
function View.Paint(card,id,quantity,selected)
	local food=Foods.Types[id]
	card.Art.Emoji.Text=food.Icon
	Art.Set(card.Art,card.Art.Emoji,Images[id] or Images.empty)
	card.ItemName.Text=food.Name
	card.Quantity.Text="×"..numberText(quantity)
	card.Risk.Text=if food.GuaranteedSuccess then "100% success" else "-"..numberText(food.Reduction*100).."% risk"
	card.Stroke.Color=if selected then Color3.new(1,1,1) else card.BackgroundColor3:Lerp(Color3.new(),.65)
	card.Stroke.Thickness=5
	card:SetAttribute("Selected",selected==true)
end
return View

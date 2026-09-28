local Art={}
local bound=setmetatable({},{__mode="k"})

-- Keep authored emoji fallbacks readable while Roblox downloads/moderates art.
function Art.Set(image,emoji,url)
	image.Image=url
	if not bound[image] then
		bound[image]=true
		local function refresh() emoji.Visible=not image.IsLoaded end
		local loaded=image:GetPropertyChangedSignal("IsLoaded"):Connect(refresh)
		local changed=image:GetPropertyChangedSignal("Image"):Connect(refresh)
		image.Destroying:Once(function() loaded:Disconnect();changed:Disconnect();bound[image]=nil end)
	end
	emoji.Visible=not image.IsLoaded
end

return Art

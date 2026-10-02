-- Edit-mode geometry regression for the touch-landscape HUD shown on phones.
assert(not game:GetService("RunService"):IsRunning(), "Edit-only verification")
local source = game.StarterPlayer.StarterPlayerScripts.Client.UI.DeviceLayout:Clone()
local Layout = require(source)
local viewport = Vector2.new(1368, 630)
local scale = Layout.LauncherScale(viewport, true)
local leftScale = Layout.LeftLauncherScale(viewport, true)
local settingsScale = Layout.SettingsLauncherScale(viewport, true)
local travelScale = Layout.TravelScale(viewport, true)
local moneyScale = Layout.MoneyScale(viewport, true)
assert(Layout.CompactLandscape(viewport, true) and not Layout.CompactLandscape(viewport, false))
assert(Layout.CompactLandscape(Vector2.new(2736, 1260), true), "High-density phone not detected")
assert(not Layout.CompactLandscape(Vector2.new(2048, 1536), true), "Tablet incorrectly compacted")
assert(scale == .62 and leftScale == .93 and settingsScale == .48 and travelScale == .62 and moneyScale == .62)
assert(Layout.LeftLauncherGap(viewport,true)==20 and Layout.RightLauncherOffset(viewport,true)==20)
local shopX,shopY=Layout.ShopLauncherOffset(viewport,true)
assert(shopX==22 and shopY==-90)

local starter = game.StarterGui
local hud = starter.FeedYourPetUI.HUD
local index = starter.IndexUI.Open
local shop = starter.ShopUI.Open
local settings = starter.SettingsUI.Open
local dock = starter.PenManagerUI.Dock
local function scaled(size, factor)
	return Vector2.new(size.X.Offset * factor, size.Y.Offset * factor)
end
local travel = scaled(hud.Travel.Size, travelScale)
local money = scaled(hud.Money.Size, moneyScale)
local square = scaled(index.Size, leftScale)
local shopSize = scaled(shop.Size, leftScale)
local settingSize = scaled(settings.Size, settingsScale)
local dockSize = scaled(dock.Size, scale)
assert(travel.X <= 323 and travel.Y <= 54, "Travel controls remain oversized")
assert(money.X <= 186 and money.Y <= 38, "Money display remains oversized")
assert(square.X >= 66 and square.X <= 67 and square.Y >= 66 and square.Y <= 67, "Primary square launcher is not 50% larger")
assert(shopSize.X >= 145 and shopSize.X <= 146 and shopSize.Y >= 59 and shopSize.Y <= 60, "Shop launcher is not 50% larger")
assert(settingSize.X >= 34 and settingSize.X <= 35, "Settings launcher is not smaller")
assert(dockSize.X <= 48 and dockSize.Y <= 107, "Egg/Pet dock remains oversized")

-- The two primary square buttons use a 20px scaled gap; Shop is lifted enough
-- to leave a clearly visible vertical gap above their row.
local primaryGap=Layout.LeftLauncherGap(viewport,true)*leftScale
local verticalGap=(-square.Y/2)-((shopY*leftScale)+(shopSize.Y/2))
assert(primaryGap>=18 and verticalGap>=20,"Primary launcher gaps remain cramped")

local width, height, bottom, textSize = Layout.TutorialHint(viewport, true)
assert(width == 460 and height == 58 and bottom == 74 and textSize == 17)
assert(width < viewport.X*.5, "Tutorial covers too much of the phone")
assert(viewport.Y-bottom-height > travel.Y+24, "Tutorial overlaps the travel controls")
source:Destroy()
return "PASS: compact touch-landscape travel, launchers, money and tutorial geometry"

-- Edit-mode geometry regression for the touch-landscape HUD shown on phones.
assert(not game:GetService("RunService"):IsRunning(), "Edit-only verification")
local source = game.StarterPlayer.StarterPlayerScripts.Client.UI.DeviceLayout:Clone()
local Layout = require(source)
local viewport = Vector2.new(1368, 630)
local scale = Layout.LauncherScale(viewport, true)
local travelScale = Layout.TravelScale(viewport, true)
local moneyScale = Layout.MoneyScale(viewport, true)
assert(Layout.CompactLandscape(viewport, true) and not Layout.CompactLandscape(viewport, false))
assert(Layout.CompactLandscape(Vector2.new(2736, 1260), true), "High-density phone not detected")
assert(not Layout.CompactLandscape(Vector2.new(2048, 1536), true), "Tablet incorrectly compacted")
assert(scale == .62 and travelScale == .62 and moneyScale == .62)

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
local square = scaled(index.Size, scale)
local shopSize = scaled(shop.Size, scale)
local settingSize = scaled(settings.Size, scale)
local dockSize = scaled(dock.Size, scale)
assert(travel.X <= 323 and travel.Y <= 54, "Travel controls remain oversized")
assert(money.X <= 186 and money.Y <= 38, "Money display remains oversized")
assert(square.X >= 44 and square.X <= 45 and square.Y >= 44 and square.Y <= 45, "Square launcher is not a readable touch target")
assert(shopSize.X <= 97 and shopSize.Y <= 40, "Shop launcher remains oversized")
assert(settingSize.X <= 45 and dockSize.X <= 48 and dockSize.Y <= 107, "Right launchers remain oversized")

local width, height, bottom, textSize = Layout.TutorialHint(viewport, true)
assert(width == 460 and height == 58 and bottom == 74 and textSize == 17)
assert(width < viewport.X*.5, "Tutorial covers too much of the phone")
assert(viewport.Y-bottom-height > travel.Y+24, "Tutorial overlaps the travel controls")
source:Destroy()
return "PASS: compact touch-landscape travel, launchers, money and tutorial geometry"

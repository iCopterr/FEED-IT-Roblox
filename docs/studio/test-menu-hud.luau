-- Detached real GUI instances: no player data or authored assets modified.
assert(not game:GetService("RunService"):IsRunning())
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.MenuHUD:Clone()
local bind=require(source).Bind
local root=Instance.new("Folder")
local function screen(name)
	local s=Instance.new("ScreenGui");s.Name=name;s.Parent=root;return s
end
local function item(parent,name,visible)
	local f=Instance.new("Frame");f.Name=name;f.Visible=visible;f.Parent=parent;return f
end
local main=screen("FeedYourPetUI")
local hud=item(main,"HUD",true)
local inventory=item(main,"Inventory",false)
local feed=item(main,"FeedPanel",false)
local shop=screen("ShopUI");local launcher=item(shop,"Open",true);local panel=item(shop,"Panel",false)
local remote=screen("PenManagerUI");local dock=item(remote,"Dock",true);local pen=item(remote,"Panel",false)
local tutorial=screen("TutorialUI")
local boost=screen("BoostUI");local badge=item(boost,"MoneyBoost",false)
local debugGui=screen("DebugUI");local debugOpen=item(debugGui,"Open",false)
local cleanup=bind(root)
local ok,err=xpcall(function()
	assert(hud.Visible and launcher.Visible and not root:GetAttribute("GameMenuOpen"))
	inventory.Visible=true;task.wait()
	assert(not hud.Visible and not launcher.Visible and not dock.Visible and not boost.Enabled and not tutorial.Enabled)
	assert(main.Enabled and inventory.Visible,"Active screen must not disable itself")
	panel.Visible=true;inventory.Visible=false;task.wait()
	assert(not hud.Visible,"Overlapping menu close restored HUD too early")
	badge.Visible=true -- entitlement updates continue while HUD screen is disabled
	panel.Visible=false;task.wait()
	assert(hud.Visible and launcher.Visible and dock.Visible and boost.Enabled and badge.Visible)
	assert(not debugOpen.Visible,"Originally hidden debug launcher was revealed")
	for _=1,10 do
		pen.Visible=true;task.wait()
		assert(not dock.Visible and hud.Visible and launcher.Visible and tutorial.Enabled and boost.Enabled and not root:GetAttribute("GameMenuOpen"))
		panel.Visible=true;task.wait();assert(not hud.Visible,"Full menu must still suppress HUD alongside remote")
		panel.Visible=false;task.wait();assert(hud.Visible and not dock.Visible)
		pen.Visible=false;task.wait();assert(dock.Visible and hud.Visible)
	end
	feed.Visible=true;main.Enabled=false;task.wait()
	assert(hud.Visible and not root:GetAttribute("GameMenuOpen"),"Disabled menu screen remains modal")
	main.Enabled=true;task.wait();assert(not hud.Visible);feed.Visible=false;task.wait()
	local thanks=screen("PurchaseThanksUI");thanks.Enabled=false
	item(thanks,"Popup",true);thanks.Enabled=true;task.wait()
	assert(not hud.Visible and thanks.Enabled,"Late purchase popup must hide only background chrome")
	local late=screen("SettingsUI");local lateOpen=item(late,"Open",true);item(late,"Panel",false);task.wait()
	assert(not lateOpen.Visible,"Late launcher leaked through menu")
	thanks.Enabled=false;task.wait();assert(lateOpen.Visible and hud.Visible)
	pen.Visible=true;task.wait();pen:Destroy();task.wait()
	assert(hud.Visible and dock.Visible,"Destroyed open menu trapped HUD")
	panel.Visible=true;task.wait();cleanup()
	assert(hud.Visible and launcher.Visible and boost.Enabled and not root:GetAttribute("GameMenuOpen"),"Cleanup did not restore HUD")
end,debug.traceback)
cleanup();root:Destroy();source:Destroy();assert(ok,err)
return "PASS: menu HUD suppression, overlap, rapid toggles, remote panel, dynamic eligibility, late GUI, disabled/destroyed menu and cleanup"

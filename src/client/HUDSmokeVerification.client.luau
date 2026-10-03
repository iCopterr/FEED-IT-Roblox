if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("HUDSmokeVerificationReport",15)
if not report then return end
local player=game.Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui")
local checks={}
local originalOwned,originalPolicy
local attributesChanged=false
local ok,failure=xpcall(function()
	local function check(value,label)assert(value,label);table.insert(checks,label)end
	local function waitFor(predicate)
		local deadline=os.clock()+20
		repeat if predicate() then return end;task.wait(.1) until os.clock()>deadline
		error("HUD smoke wait timed out")
	end
	for _,name in {"FeedYourPetUI","SettingsUI","ShopUI","IndexUI","StarterPackUI","BoostUI","MerchantUI","ReviveUI","PenManagerUI"} do
		check(gui:WaitForChild(name,10)~=nil,name.." replicated")
	end
	waitFor(function()return player:GetAttribute("PaidRandomPolicyStatus")~="Loading" and player:GetAttribute("PaidRandomPolicyStatus")~=nil end)
	task.wait(2)
	local main=gui.FeedYourPetUI
	waitFor(function()return main.HUD.Money.Value.Text:find("2.00K",1,true)end)
	check(true,"Fresh-player Money HUD shows $2.00K")
	local view=gui.BoostUI.MoneyBoost
	local expected=player:GetAttribute("DoubleMoneyOwned")==true and player:GetAttribute("PaidRandomPolicyStatus")=="Allowed"
	check(view.Visible==expected,"Boost matches real replicated eligibility")
	-- Local-only rendering probe, NOT server ownership or a payout override.
	originalOwned=player:GetAttribute("DoubleMoneyOwned")
	originalPolicy=player:GetAttribute("PaidRandomPolicyStatus")
	attributesChanged=true
	player:SetAttribute("DoubleMoneyOwned",true);player:SetAttribute("PaidRandomPolicyStatus","Allowed")
	waitFor(function()return view.Visible end)
	local relative=view.AbsolutePosition-gui.BoostUI.AbsolutePosition
	check(gui.BoostUI.Enabled and relative.X>=0 and relative.Y>=0
		and relative.X+view.AbsoluteSize.X<=gui.BoostUI.AbsoluteSize.X+.1
		and relative.Y+view.AbsoluteSize.Y<=gui.BoostUI.AbsoluteSize.Y+.1,"Eligible boost is visible inside HUD bounds")
	player:SetAttribute("PaidRandomPolicyStatus","Restricted")
	waitFor(function()return not view.Visible end)
	check(true,"Restricted boost hides without restart")
	player:SetAttribute("DoubleMoneyOwned",originalOwned);player:SetAttribute("PaidRandomPolicyStatus",originalPolicy)
	attributesChanged=false
	for _,button in {main.HUD.OpenInventory,gui.IndexUI.Open,gui.ShopUI.Open,gui.SettingsUI.Open} do
		local scales=0
		for _,c in button:GetChildren()do if c:IsA("UIScale")then scales+=1 end end
		check(scales==1 and button.Active and button.Visible,button:GetFullName().." has one scale and is available")
	end
	for _,panel in {gui.ShopUI.Panel,gui.SettingsUI.Panel,gui.IndexUI.Panel,main.Inventory} do
		for _=1,2 do panel.Visible=true;task.wait(.3);check(panel.Visible,panel.Parent.Name.." can reopen");panel.Visible=false;task.wait(.3)end
	end
	local sounds=game:GetService("SoundService")
	check(sounds:FindFirstChild("MusicVolumeGroup") and sounds:FindFirstChild("SFXVolumeGroup"),"Volume groups present")
	for _,name in {"BackgroundMusic","Click","Buy","BuyFail","Hatching","HatchFinish","Eating","Feeding","Failed","Complete"}do
		check(sounds[name].SoundId~="",name.." sound configured")
	end
	for _,entry in game:GetService("LogService"):GetLogHistory()do
		if not entry.message:lower():find("plugin",1,true) then
			check(entry.messageType~=Enum.MessageType.MessageError and not entry.message:find("startup failed:",1,true)
				and not entry.message:find("Infinite yield",1,true),"Clean client log: "..entry.message:sub(1,100))
		end
	end
end,debug.traceback)
if attributesChanged then player:SetAttribute("DoubleMoneyOwned",originalOwned);player:SetAttribute("PaidRandomPolicyStatus",originalPolicy)end
report:FireServer({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})

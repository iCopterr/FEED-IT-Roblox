-- Edit-only test using real authored instances and TweenService, not scale math alone.
assert(not game:GetService("RunService"):IsRunning())
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.Motion:Clone()
local Motion=require(source)
local screen=Instance.new("ScreenGui")
screen.Name="LauncherScaleRegression"
local function signal()
	local listeners={}
	return {Connect=function(_,fn) listeners[fn]=true;return {Disconnect=function()listeners[fn]=nil end} end,
		Fire=function(...) for fn in listeners do fn(...) end end}
end
local ok,err=pcall(function()
	screen.Parent=game.StarterGui
	for _,template in {game.StarterGui.SettingsUI.Open,game.StarterGui.IndexUI.Open,game.StarterGui.ShopUI.Open,game.StarterGui.FeedYourPetUI.HUD.OpenInventory} do
		local clone=template:Clone();clone.Parent=screen
		local pulse=clone.MotionScale
		local button={Active=true,MouseEnter=signal(),MouseLeave=signal(),InputBegan=signal(),InputEnded=signal(),Activated=signal(),Destroying=signal()}
		function button:FindFirstChild(name)return clone:FindFirstChild(name)end
		function button:GetAttributeChangedSignal()return signal()end
		function button:GetPropertyChangedSignal()return signal()end
		function button:GetAttribute()return false end
		local visibility=signal()
		local panel={Visible=true,GetPropertyChangedSignal=function()return visibility end}
		Motion.BindButton(button,panel);Motion.BindButton(button,panel)
		assert(pulse.Parent==nil,"Motion scale still competes with responsive scale")
		local count=0
		for _,c in clone:GetChildren() do if c:IsA("UIScale") then count+=1 end end
		assert(count==1,"Multiple active button scales")
		local function check(base,factor)
			-- Edit-mode rendering can be throttled; wait for the tween's actual
			-- target rather than assuming two render frames fit in 160ms.
			local deadline=os.clock()+3
			repeat task.wait(.05) until math.abs(clone.UIScale.Scale-base*factor)<.001 or os.clock()>=deadline
			assert(math.abs(clone.UIScale.Scale-base*factor)<.001,string.format("%s: expected %.4f, got %.4f (pulse %.4f)",template:GetFullName(),base*factor,clone.UIScale.Scale,pulse.Scale))
			assert(math.abs(clone.AbsoluteSize.X-clone.Size.X.Offset*base*factor)<1,"Rendered size ignores responsive scale")
		end
		clone.UIScale.Scale=.48;check(.48,1)
		button.MouseEnter.Fire();check(.48,1.025)
		clone.UIScale.Scale=.93;check(.93,1.025)
		button.InputBegan.Fire({UserInputType=Enum.UserInputType.Touch});check(.93,.96)
		button.InputEnded.Fire({UserInputType=Enum.UserInputType.Touch});check(.93,1.025)
		button.MouseLeave.Fire();check(.93,1)
		clone.UIScale.Scale=1;check(1,1)
		button.MouseEnter.Fire();check(1,1.025)
		panel.Visible=false;visibility.Fire();check(1,1)
		button.Destroying.Fire();clone:Destroy()
	end
end)
screen:Destroy();source:Destroy()
assert(ok,err)
return "PASS: real launcher pixel bounds, one effective scale, resize during hover, touch press, desktop reset, cleanup"

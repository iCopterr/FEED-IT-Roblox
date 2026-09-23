local TweenService=game:GetService("TweenService")
local Motion={}
local popups=setmetatable({},{__mode="k"})
local buttons=setmetatable({},{__mode="k"})

function Motion.BindPopup(panel,options)
	if popups[panel] then return end
	local horizontal=options and options.FromRight
	local function offscreen()
		return panel.AbsoluteSize.X+80
	end
	local progress=Instance.new("NumberValue")
	local home=panel.Position
	local lastApplied=home
	local writing=false
	local tween
	local generation=0
	local state={}
	popups[panel]=state
	local function apply()
		writing=true
		lastApplied=home+(if horizontal then UDim2.fromOffset(progress.Value,0) else UDim2.fromOffset(0,progress.Value))
		panel.Position=lastApplied
		writing=false
	end
	local function animate(offset,duration,style)
		if tween then tween:Cancel() end
		tween=TweenService:Create(progress,TweenInfo.new(duration,style,Enum.EasingDirection.Out),{Value=offset})
		tween:Play()
	end
	local function visibility()
		generation+=1
		if tween then tween:Cancel() end
		progress.Value=0
		if panel.Visible then
			progress.Value=if horizontal then offscreen() else 18
			animate(0,if horizontal then .24 else .18,Enum.EasingStyle.Quart)
		end
	end
	local changed=progress.Changed:Connect(apply)
	local position=panel:GetPropertyChangedSignal("Position"):Connect(function()
		-- Responsive layout owns the resting position, even during a tween.
		if not writing and panel.Position~=lastApplied then home=panel.Position;apply() end
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(visibility)
	state.Close=function()
		if not panel.Visible then return end
		generation+=1
		local ticket=generation
		local duration=if horizontal then .18 else .1
		animate(if horizontal then offscreen() else 12,duration,Enum.EasingStyle.Quad)
		task.delay(duration,function()
			if panel.Parent and ticket==generation then panel.Visible=false end
		end)
	end
	panel.Destroying:Connect(function()
		generation+=1
		if tween then tween:Cancel() end
		changed:Disconnect();position:Disconnect();progress:Destroy();popups[panel]=nil
	end)
	visibility()
end

function Motion.Close(panel)
	Motion.BindPopup(panel)
	popups[panel].Close()
end

function Motion.BindButton(button,panel)
	if buttons[button] then return end
	local scale=button:FindFirstChild("MotionScale")
	if not scale then return end -- UI geometry is authored, never built here.
	buttons[button]=true
	local hovered,pressed=false,false
	local tween
	local function update()
		if tween then tween:Cancel() end
		local target=if not button.Active or not panel.Visible then 1 elseif pressed then .96 elseif hovered then 1.025 else 1
		tween=TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=target})
		tween:Play()
	end
	button.MouseEnter:Connect(function() hovered=true;update() end)
	button.MouseLeave:Connect(function() hovered=false;pressed=false;update() end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=true;update() end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed=false;update() end
	end)
	button.Activated:Connect(function() pressed=false;update() end)
	button:GetAttributeChangedSignal("Selected"):Connect(function()
		if button:GetAttribute("Selected") and panel.Visible and button.Active then
			if tween then tween:Cancel() end
			scale.Scale=1.025
			update()
		end
	end)
	button:GetPropertyChangedSignal("Active"):Connect(update)
	local visible=panel:GetPropertyChangedSignal("Visible"):Connect(function()
		hovered=false;pressed=false
		if tween then tween:Cancel() end
		scale.Scale=1
	end)
	button.Destroying:Connect(function() if tween then tween:Cancel() end;visible:Disconnect();buttons[button]=nil end)
end
return Motion

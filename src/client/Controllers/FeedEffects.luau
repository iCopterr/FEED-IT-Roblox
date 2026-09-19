local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local P = Config.Presentation
local FeedEffects = {}
local numberText = require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local seen = {}
local bannerToken = 0

local function animate(seconds, update)
	local start = os.clock()
	repeat
		local alpha = math.clamp((os.clock()-start)/seconds,0,1)
		update(alpha)
		if alpha == 1 then break end
		RunService.RenderStepped:Wait()
	until false
end

local function banner(gui, result)
	if not gui then return end
	local label = gui:FindFirstChild("FeedBanner")
	if not label then return end
	bannerToken += 1
	local token = bannerToken
	local presentation = P[result.Code]
	local color, text
	if result.Code == "Explosion" then
		color = Color3.fromRGB(255,108,73)
		text = presentation.BannerText .. string.format("\nRevive or keep at LEVEL %d • Pet not deleted • Food spent",result.FeedLevel)
	elseif result.Code == "MiracleSave" then
		color = Color3.fromRGB(101,239,255)
		text = presentation.BannerText .. "\nPet survived at the same level • Food spent"
	else
		color = Color3.fromRGB(161,255,101)
		text = if result.Critical == "Normal" then presentation.BannerText else string.upper(result.Critical) .. " FEED!"
		text ..= string.format("\n+%d LEVEL • LEVEL %d • %s MONEY/SEC",result.Gain,result.FeedLevel,numberText(result.Income))
	end
	label.Text, label.TextColor3, label.Visible = text, color, true
	label.UIScale.Scale = .8
	TweenService:Create(label.UIScale,TweenInfo.new(.3,Enum.EasingStyle.Back),{Scale=1}):Play()
	task.delay(presentation.BannerSeconds,function() if token==bannerToken then label.Visible=false end end)
end

function FeedEffects.Play(result, gui)
	if not result.Accepted or seen[result.AttemptId] then return end
	seen[result.AttemptId] = true
	task.delay(60,function() seen[result.AttemptId]=nil end)
	-- Late snapshots recover missed results, but never replay old animations.
	if result.StartedAt and workspace:GetServerTimeNow()-result.StartedAt > 8 then return end
	task.spawn(function()
		local model
		local ok, failure = xpcall(function()
			local templates = workspace:FindFirstChild("PetTemplates")
			local template = templates and templates:FindFirstChild(result.SpeciesId)
			if not template then banner(gui,result); return end
			-- Clone the authored pet, never generate replacement world geometry.
			model = template:Clone()
			model.Name = "FeedEffect_"..result.AttemptId
			local oldScale, newScale = Config.GetScale(result.OldLevel), Config.GetScale(result.FeedLevel)
			model:ScaleTo(oldScale)
			model:PivotTo(result.Origin)
			local _, oldSize = model:GetBoundingBox()
			local parts = {}
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
					table.insert(parts,{Part=part,Color=part.Color,Material=part.Material})
				end
			end
			model.Parent = workspace
			local origin = result.Origin
			local raised = origin + Vector3.new(0,P.FloatHeight,0)
			animate(P.FloatSeconds,function(a) model:PivotTo(origin:Lerp(raised,1-(1-a)^3)) end)
			animate(P.SpinSeconds,function(a)
				local degrees = P.SpinSeconds*(P.SpinStartDegreesPerSecond*a
					+(P.SpinEndDegreesPerSecond-P.SpinStartDegreesPerSecond)*a^(P.SpinAccelerationExponent+1)/(P.SpinAccelerationExponent+1))
				model:PivotTo(raised*CFrame.Angles(0,math.rad(degrees),0))
			end)
			banner(gui,result)
			if result.Code == "Explosion" then
				for i, entry in parts do
					local part = entry.Part
					local angle = i*math.pi*2/#parts
					part.Color=Color3.fromRGB(255,132,46); part.Material=Enum.Material.Neon
					TweenService:Create(part,TweenInfo.new(P.Explosion.BurstSeconds+P.Explosion.FadeSeconds),{
						CFrame=part.CFrame+Vector3.new(math.cos(angle)*8,3+i,math.sin(angle)*8),Transparency=1}):Play()
				end
				task.wait(P.Explosion.BurstSeconds+P.Explosion.FadeSeconds)
			else
				local miracle = result.Code == "MiracleSave"
				local seconds = if miracle then P.MiracleSave.ReturnSeconds else P.Success.ReturnSeconds
				local start = model:GetPivot()
				animate(seconds,function(a)
					local smooth = a*a*(3-2*a)
					model:ScaleTo(oldScale+(newScale-oldScale)*smooth)
					local lift = oldSize.Y*(newScale/oldScale-1)/2
					model:PivotTo(start:Lerp(origin+Vector3.new(0,lift,0),smooth))
					for _, entry in parts do
						local flash = if miracle and a<.2 then Color3.fromRGB(255,80,60)
							else if miracle then Color3.fromRGB(110,245,255) else Color3.fromRGB(191,255,99)
						entry.Part.Color = flash:Lerp(entry.Color,a)
					end
				end)
			end
		end,debug.traceback)
		if model then model:Destroy() end
		if not ok then warn("[FeedEffects]",failure); banner(gui,result) end
	end)
end
return FeedEffects

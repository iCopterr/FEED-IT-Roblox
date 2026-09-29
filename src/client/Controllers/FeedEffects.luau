local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local P = Config.Presentation
local FeedEffects = {}
local numberText = require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local PetModels = require(game.ReplicatedStorage.Shared.PetModels)
local VFX = require(script.Parent.VFXController)
local FeedCharge = require(script.Parent.Parent.UI.FeedCharge)
local Sounds = require(script.Parent.Parent.Audio.GameSounds)
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
		text = presentation.BannerText .. "\nVisit the Revive Machine within 24h • Food spent"
	elseif result.Code == "MiracleSave" then
		color = Color3.fromRGB(101,239,255)
		text = presentation.BannerText .. "\nPet survived at the same level • Food spent"
	else
		color = Color3.fromRGB(161,255,101)
		text = if result.Critical == "Normal" then presentation.BannerText else string.upper(result.Critical) .. " FEED!"
		text ..= string.format("\n+%d LEVEL • LEVEL %d • %s MONEY/SEC",result.Gain,result.FeedLevel,numberText(result.Income))
	end
	if result.Protected then text = "🛡 PROTECTED\n" .. text end
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
		local own = result.OwnerUserId == game.Players.LocalPlayer.UserId
		local stopEating, stopFeeding = function() end, function() end
		local ok, failure = xpcall(function()
			local template = PetModels.GetTemplate(result.SpeciesId)
			if not template then banner(gui,result); return end
			-- Clone the authored pet, never generate replacement world geometry.
			model = template:Clone()
			model.Name = "FeedEffect_"..result.AttemptId
			local oldScale, newScale = PetModels.GetScale(result.SpeciesId,result.OldLevel), PetModels.GetScale(result.SpeciesId,result.FeedLevel)
			model:ScaleTo(oldScale)
			model:PivotTo(result.Origin)
			local _, oldSize = model:GetBoundingBox()
			local parts = {}
			for _, part in model:GetDescendants() do
				if part:IsA("LuaSourceContainer") or part:IsA("ProximityPrompt") or part:IsA("LayerCollector") then
					part:Destroy()
				elseif part:IsA("BasePart") then
					part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
					table.insert(parts,{Part=part,Color=part.Color,Material=part.Material})
				end
			end
			model.Parent = workspace
			game:GetService("Debris"):AddItem(model,10)
			local charge=FeedCharge.Create(model)
			local origin = result.Origin
			local raised = origin + Vector3.new(0,P.FloatHeight,0)
			if own then stopEating = Sounds.Play("Eating", P.FloatSeconds + .1) end
			animate(P.FloatSeconds,function(a)
				local eased=1-(1-a)^3
				model:PivotTo(origin:Lerp(raised,eased)+Vector3.new(0,math.sin(a*math.pi)*.25,0))
				charge.Update(a*.15,model:GetPivot().Position)
			end)
			stopEating()
			if own then stopFeeding = Sounds.Play("Feeding", P.SpinSeconds + .5) end
			animate(P.SpinSeconds,function(a)
				local degrees = P.SpinSeconds*(P.SpinStartDegreesPerSecond*a
					+(P.SpinEndDegreesPerSecond-P.SpinStartDegreesPerSecond)*a^(P.SpinAccelerationExponent+1)/(P.SpinAccelerationExponent+1))
				local tremble=math.max(0,(a-.75)/.25)
				model:PivotTo((raised+Vector3.new(0,math.sin(a*math.pi*6)*.12,0))
					*CFrame.Angles(math.sin(a*60)*tremble*.035,math.rad(degrees),math.sin(a*75)*tremble*.04))
				charge.Update(.15+.85*a,model:GetPivot().Position)
			end)
			charge.Finish()
			stopFeeding()
			if own then Sounds.Play(if result.Code == "Explosion" then "Failed" else "Complete") end
			banner(gui,result)
			VFX.Burst(raised.Position,result.Code)
			if result.Code == "Explosion" then
				for i, entry in parts do
					local part = entry.Part
					-- Multipart pets can contain thousands of blocks: cap debris tweens.
					if i > 24 then part.Transparency=1; continue end
					local angle = i*math.pi*2/math.min(#parts,24)
					part.Color=Color3.fromRGB(255,132,46); part.Material=Enum.Material.Neon
					TweenService:Create(part,TweenInfo.new(P.Explosion.BurstSeconds+P.Explosion.FadeSeconds),{
						CFrame=(part.CFrame+Vector3.new(math.cos(angle)*8,3+(i%4),math.sin(angle)*8))
							*CFrame.Angles(i*.7,i*.4,i*.9),Transparency=1}):Play()
				end
				task.wait(P.Explosion.BurstSeconds+P.Explosion.FadeSeconds)
			else
				local miracle = result.Code == "MiracleSave"
				local seconds = if miracle then P.MiracleSave.ReturnSeconds else P.Success.ReturnSeconds
				local start = model:GetPivot()
				animate(seconds,function(a)
					local smooth = a*a*(3-2*a)
					local growth=oldScale+(newScale-oldScale)*smooth
					model:ScaleTo(growth*(1+(if miracle then .02 else .06)*math.sin(math.pi*a)))
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
		stopEating(); stopFeeding()
		if model then model:Destroy() end
		if not ok then warn("[FeedEffects]",failure); banner(gui,result) end
	end)
end
return FeedEffects

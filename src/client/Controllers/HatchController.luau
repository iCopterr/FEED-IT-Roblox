local Storage=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local Colors=require(Storage.Shared.Config.InventoryConfig).RarityColors
local Controller={}
local queue,seen={},{}
local panel,working,cancelled

local function animate(seconds,update)
	local start=os.clock()
	repeat
		if cancelled or not panel.Parent then return false end
		local a=math.clamp((os.clock()-start)/seconds,0,1);update(a)
		if a==1 then return true end
		Run.RenderStepped:Wait()
	until false
end

local function play(result)
	cancelled=false
	panel.Visible=true;panel.Title.Text="HATCHING...";panel.PetName.Text="";panel.Rarity.Text=""
	panel.Flash.BackgroundTransparency=1
	panel:SetAttribute("Stage","Egg")
	Preview.Set(panel.Preview,{Kind="Egg",EggId=result.EggId})
	local egg=panel.Preview.World:FindFirstChildOfClass("Model")
	local pivot=egg and egg:GetPivot()
	if not animate(1.25,function(a)
		if egg then egg:PivotTo(pivot*CFrame.new(0,math.abs(math.sin(a*math.pi*6))*.25,0)*CFrame.Angles(0,0,math.sin(a*a*40)*a*.35)) end
	end) then return end
	panel.Flash.BackgroundTransparency=.15
	Preview.Set(panel.Preview,nil)
	Preview.Set(panel.Preview,{Kind="Pet",SpeciesId=result.SpeciesId})
	panel:SetAttribute("Stage","Pet")
	panel.Title.Text="YOU HATCHED!";panel.PetName.Text=result.PetName
	panel.Rarity.Text=(if result.Variant~="Normal" then result.Variant.." • " else "")..result.Rarity
	panel.Rarity.TextColor3=Colors[result.Rarity] or Color3.new(1,1,1)
	local pet=panel.Preview.World:FindFirstChildOfClass("Model")
	local bounds=pet and pet:GetBoundingBox()
	local offset=pet and bounds:ToObjectSpace(pet:GetPivot())
	animate(2.1,function(a)
		panel.Flash.BackgroundTransparency=math.min(1,.15+a*7)
		if pet then pet:PivotTo(bounds*CFrame.Angles(0,math.rad(65)*math.sin(a*math.pi),0)*offset) end
	end)
end

function Controller.Enqueue(result)
	if not panel or type(result)~="table" or result.Code~="Hatched" or not result.Ok
		or type(result.EggUid)~="string" or type(result.SpeciesId)~="string" or seen[result.EggUid] then return false end
	seen[result.EggUid]=true
	task.delay(120,function() seen[result.EggUid]=nil end)
	-- Visual-only queue budget: pets are already granted even if presentation is skipped.
	if #queue>=8 then return false end
	table.insert(queue,table.clone(result))
	if working then return true end
	working=true
	task.spawn(function()
		while #queue>0 do
			local ok,failure=xpcall(function() play(table.remove(queue,1)) end,debug.traceback)
			Preview.Set(panel.Preview,nil);panel.Visible=false;panel:SetAttribute("Stage","Idle")
			if not ok then warn("[HatchController]",failure) end
			task.wait(.1)
		end
		working=false
	end)
	return true
end

function Controller.Skip() cancelled=true end
function Controller.Start()
	if panel then return end
	local gui=game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HatchUI",30)
	if not gui then warn("[HatchController] Authored HatchUI missing");return end
	panel=gui.Panel
	panel.Skip.Activated:Connect(Controller.Skip)
	local function resize()
		local size=workspace.CurrentCamera.ViewportSize
		panel.UIScale.Scale=math.min(1,(size.X-24)/520,(size.Y-40)/500)
	end
	resize();workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	Storage:WaitForChild("HatchOutcome").OnClientEvent:Connect(Controller.Enqueue)
end
return Controller

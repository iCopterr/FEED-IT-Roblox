local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config.TravelConfig)
local Data=require(script.Parent.DataService)
local Plots=require(script.Parent.PlotService)
local Farm=require(script.Parent.FarmService)
local Locks=require(script.Parent.FeedLocks)
local Service={}
local lastRequest={}

function Service.HandleRequest(player,destination)
	if destination~="Base" and destination~="Merchant" then return {Ok=false,Code="InvalidDestination"} end
	if player.Parent~=Players or not Data.IsLoaded(player) then return {Ok=false,Code="Loading"} end
	local now=os.clock()
	if now-(lastRequest[player] or -math.huge)<Config.Cooldown then return {Ok=false,Code="Cooldown"} end
	lastRequest[player]=now
	if Locks.IsLocked(player) or player:GetAttribute("FeedBusy") then return {Ok=false,Code="Busy"} end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health<=0 or not root then return {Ok=false,Code="CharacterUnavailable"} end
	local target
	if destination=="Base" then
		local plot=Plots.GetPlot(player)
		if not plot or plot:GetAttribute("OwnerUserId")~=player.UserId then return {Ok=false,Code="NoPlot"} end
		target=plot:FindFirstChild("Spawn")
	else
		local merchant=workspace:FindFirstChild("MysteryMerchant")
		target=merchant and merchant:FindFirstChild("InteractionPoint",true)
	end
	if not target or not target:IsA("BasePart") or not target:IsDescendantOf(workspace) then return {Ok=false,Code="Unavailable"} end
	-- Release the farm anchor before moving; never leave food production active remotely.
	Farm.Exit(player,false)
	if root.Anchored then return {Ok=false,Code="Busy"} end
	humanoid.Sit=false
	character:PivotTo(target.CFrame+Vector3.new(0,target.Size.Y/2+Config.Clearance,0))
	root.AssemblyLinearVelocity=Vector3.zero
	root.AssemblyAngularVelocity=Vector3.zero
	return {Ok=true}
end

function Service.Start()
	local remote=Instance.new("RemoteFunction")
	remote.Name="PrototypeTravel";remote.OnServerInvoke=Service.HandleRequest;remote.Parent=ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) lastRequest[player]=nil end)
end
return Service

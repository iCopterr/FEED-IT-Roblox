local Players=game:GetService("Players")
local Data=require(script.Parent.DataService)
local Progress=require(script.Parent.TutorialProgress)
local Config=require(game.ReplicatedStorage.Shared.Config.TutorialConfig)
local Service={}
local saving,savedStates,retryAt={},{},{}

function Service.Refresh(player)
	local data=Data.GetData(player)
	if not data then return end
	Progress.Reconcile(data)
	local settings=data.Settings
	-- These attributes are presentation only. Client changes never advance saves.
	player:SetAttribute("TutorialStep",settings.TutorialStep)
	player:SetAttribute("TutorialEggUid",settings.TutorialEggUid)
	player:SetAttribute("TutorialPetId",settings.TutorialPetId)
	if not settings.TutorialStep then return end
	if settings.TutorialStep and settings.TutorialStep~=Config.Completed then
		player:SetAttribute("TutorialMoney",data.Money)
	end
	local signature=tostring(settings.TutorialStep)..":"..tostring(settings.TutorialBoughtFood)
	if savedStates[player]~=signature and not saving[player] and os.clock()>=(retryAt[player] or 0) then
		saving[player]=true
		task.spawn(function()
			local ok,saved=pcall(Data.Save,player)
			if ok and saved and Data.GetData(player)==data then savedStates[player]=signature end
			retryAt[player]=os.clock()+ (if ok and saved then 0 else Config.SaveRetrySeconds)
			saving[player]=nil
		end)
	end
end

function Service.Start()
	Players.PlayerRemoving:Connect(function(player) saving[player],savedStates[player],retryAt[player]=nil,nil,nil end)
	task.spawn(function()
		while true do
			for _,player in Players:GetPlayers() do Service.Refresh(player) end
			task.wait(Config.RefreshSeconds)
		end
	end)
end
return Service

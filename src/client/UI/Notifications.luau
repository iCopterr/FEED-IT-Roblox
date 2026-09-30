local Players=game:GetService("Players")
local Notice={}
local ticket=0
local lastText,lastAt="",-math.huge

function Notice.Position(gui)
	local bar=gui.Hotbar
	local label=gui.Notification
	local height=math.max(66,bar.AbsoluteSize.Y)
	local bottom=gui.AbsoluteSize.Y-(bar.AbsolutePosition.Y-gui.AbsolutePosition.Y)-bar.AbsoluteSize.Y
	label.Position=UDim2.new(.5,0,1,-math.max(100,bottom+height+12))
	label.Size=UDim2.fromOffset(math.min(620,math.max(100,gui.AbsoluteSize.X-32)),76)
end

function Notice.Show(text,color,seconds)
	if type(text)~="string" or text=="" then return end
	-- Polling errors and transient work-in-progress labels must not spam players.
	if text=="Loading…" or text=="Picking up…" or text=="Feeding…" or text=="Restoring…"
		or text=="Finding your best pets…" then return end
	local now=os.clock()
	if text==lastText and now-lastAt<5 then return end
	local playerGui=Players.LocalPlayer:FindFirstChild("PlayerGui")
	local gui=playerGui and playerGui:FindFirstChild("FeedYourPetUI")
	local label=gui and gui:FindFirstChild("Notification")
	if not label then return end
	lastText,lastAt=text,now;ticket+=1
	local own=ticket
	Notice.Position(gui)
	label.Text=text;label.TextColor3=color or Color3.new(1,1,1);label.Visible=true
	task.delay(seconds or 4,function() if own==ticket and label.Parent then label.Visible=false end end)
end

return Notice

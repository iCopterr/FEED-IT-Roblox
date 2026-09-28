local old=game.StarterGui:FindFirstChild('_RosterIndexReview');if old then old:Destroy()end
local gui=game.StarterGui.IndexUI:Clone();gui.Name='_RosterIndexReview';gui.Enabled=true;gui.DisplayOrder=100;gui.Parent=game.StarterGui
gui.Panel.Visible=true;gui.Open.Visible=false
local view=require(game.StarterPlayer.StarterPlayerScripts.Client.UI.IndexView)
local cfg=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local eggs=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local all={};for id in cfg.Species do all[id]=true end
for _,egg in eggs.Order do
 view.Render(gui.Panel,all,egg,eggs.Definitions[egg].Results[6].SpeciesId)
 assert(gui.Panel.Progress.Text=='DISCOVERED  36 / 36')
 for i=1,6 do assert(gui.Panel.Pets['Pet'..i].Preview.World:FindFirstChildOfClass('Model')) end
end
for i=1,6 do
 local tab=gui.Panel.Categories['Egg'..i]
 assert(tab.LayoutOrder==i)
 assert(tab.Count.Position.Y.Offset+tab.Count.Size.Y.Offset<=tab.Size.Y.Offset)
 assert(tab.Preview.Position.Y.Offset+tab.Preview.Size.Y.Offset<=tab.Size.Y.Offset)
end
return 'Six index pools rendered, 36 models found; tab layout fits'

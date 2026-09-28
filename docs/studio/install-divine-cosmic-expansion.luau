assert(not game:GetService('RunService'):IsRunning())
local storage=game:GetService('ServerStorage')
local names={'Divine Phoenix','Heavenly Kirin','Godly Behemoth','Galaxy Dragon','Cosmic Hydra','World Eater'}
local cfg=game.ReplicatedStorage.Shared.Config.PetConfig:Clone();cfg.Parent=storage
local definitions=require(cfg).Species;cfg:Destroy()
local templates=game.ReplicatedStorage.PetsModel
local report={}
for _,name in names do
 local candidate=storage.PetOptimizationCandidates[name]
 assert(candidate:GetAttribute('SerializationVerified') and not candidate:GetAttribute('OptimizationError'),name)
 candidate:SetAttribute('VisualReviewPassed',true)
 if not templates:FindFirstChild(name) then
  local m=candidate:Clone();m:SetAttribute('OptimizationState','Installed');m.Parent=templates
 end
 table.insert(report,game:GetService('HttpService'):JSONDecode(candidate:GetAttribute('OptimizationReport')))
end
local metadataBackup=storage:FindFirstChild('RosterMetadataBackup_20260927') or Instance.new('Folder')
metadataBackup.Name='RosterMetadataBackup_20260927';metadataBackup.Parent=storage
for id,definition in definitions do
 local m=assert(templates:FindFirstChild(definition.TemplateName))
 if not metadataBackup:FindFirstChild(m.Name) then
  local record=Instance.new('StringValue');record.Name=m.Name;record.Value=game:GetService('HttpService'):JSONEncode(m:GetAttributes());record.Parent=metadataBackup
 end
 m:SetAttribute('SpeciesId',id);m:SetAttribute('EggId',definition.EggId)
 m:SetAttribute('Rarity',definition.Rarity);m:SetAttribute('BaseIncome',definition.BaseIncome)
 for _,folder in {storage.PetOptimizationCandidates,storage.DivineCosmicSources_20260927} do
  local copy=folder:FindFirstChild(m.Name)
  if copy then for _,key in {'SpeciesId','EggId','Rarity','BaseIncome'} do copy:SetAttribute(key,m:GetAttribute(key)) end end
 end
end
return game:GetService('HttpService'):JSONEncode(report)

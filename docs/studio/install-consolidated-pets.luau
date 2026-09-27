-- Run only after all 24 candidates have passed structural and visual review.
assert(not game:GetService('RunService'):IsRunning())
local names={'Ember Drake','Frost Wolf','Storm Griffin','Lava Golem','Thunder Serpent','Ice Dragon','Kitsune','Minotaur','Basilisk','Manticore','Chimera','Cerberus','Hydra','Phoenix','Kraken','Ancient Wyvern','Bone Dragon','Behemoth','Astral Kitsune','Eclipse Griffin','Void Leviathan','Celestial Dragon','Seraph Beast','World Serpent'}
local templates=game.ReplicatedStorage.PetsModel
local backups=assert(game.ServerStorage:FindFirstChild('PetModelBackups_20260927'))
local staging=assert(game.ServerStorage:FindFirstChild('PetOptimizationCandidates'))
for _,name in names do
 local current=assert(templates:FindFirstChild(name))
 if current:GetAttribute('OptimizationState')=='Installed' then continue end
 local candidate=assert(staging:FindFirstChild(name))
 assert(candidate:GetAttribute('SerializationVerified')and candidate:GetAttribute('VisualReviewPassed'),name..' still needs review')
 assert(backups:FindFirstChild(name),name..' missing backup snapshot')
end
for _,name in names do
 local current=templates[name]
 if current:GetAttribute('OptimizationState')=='Installed'then continue end
 local candidate=staging[name]
 local snapshot=backups[name]
 snapshot.Name=name..'_Snapshot'
 -- Move the actual original instance into backup, retaining its full hierarchy.
 current.Parent=backups
 candidate.Parent=templates
 candidate:SetAttribute('OptimizationState','Installed')
 -- Only the redundant pre-operation clone is removed. The actual original stays.
 snapshot:Destroy()
 print('Installed '..name..' ('..candidate:GetAttribute('OptimizedPartCount')..' parts)')
end

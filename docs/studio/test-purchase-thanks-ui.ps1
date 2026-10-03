param([int]$Port=58741,[switch]$KeepPreview)
$ErrorActionPreference='Stop'
$source=[IO.File]::ReadAllText((Resolve-Path 'src/client/UI/PurchaseThanks.luau'))
$prefix=@'
local realGame,realRequire=game,require
local CoreGui=realGame:GetService("CoreGui")
local old=CoreGui:FindFirstChild("PurchaseThanksUI")
if old then old:Destroy() end
local iconToken,soundToken={},{}
local played
local icons={
 hearty="rbxassetid://91392940915097",revive="rbxassetid://133373414506019",reviveShard="rbxassetid://82838242551952",
}
local sounds={Play=function(name)played=name end}
local fakePlayer={WaitForChild=function(_,name)assert(name=="PlayerGui");return CoreGui end}
local fakePlayers={LocalPlayer=fakePlayer}
local fakeGame={ReplicatedStorage=realGame.ReplicatedStorage,GetService=function(_,name)
 if name=="Players" then return fakePlayers end
 return realGame:GetService(name)
end}
local fakeScript={Parent={IconImages=iconToken,Parent={Audio={GameSounds=soundToken}}}}
local fakeRequire=function(module)
 if module==iconToken then return icons end
 if module==soundToken then return sounds end
 return realRequire(module)
end
local module=(function(game,require,script)
'@
$suffix=@'
end)(fakeGame,fakeRequire,fakeScript)
module.Show({Kind="Food",ItemId="hearty",Reward="Hearty Food",Rarity="Rare",Shards=5})
task.wait(.35)
local gui=module.GetGui()
local card=gui.Popup.Card
local reward=card:FindFirstChild("Reward")
local shardBonus=card:FindFirstChild("ShardBonus")
assert(reward and shardBonus,"missing popup sections")
local rewardName=reward:FindFirstChild("RewardName")
local shardText=shardBonus:FindFirstChild("ShardText")
local shardFallback=shardBonus:FindFirstChild("ShardFallback")
local shardIcon=shardBonus:FindFirstChild("ShardIcon")
assert(rewardName and shardText and shardFallback and shardIcon,"missing popup labels")
assert(gui.Enabled and card.Header.Title.Text=="THANK YOU!","header")
assert(card.Header.Subtitle.Text=="FOR YOUR PURCHASE","subtitle")
assert(rewardName.Text=="1× Hearty Food","food name: "..rewardName.Text)
assert(shardBonus.Visible and shardText.Text=="BONUS  +5 REPAIR SHARDS","shard banner: "..shardText.Text)
assert(not shardFallback.Visible and shardIcon.Visible,"shard art")
assert(played=="Buy","sound")
if __KEEP_PREVIEW__ then return "PREVIEW: PurchaseThanksUI left in CoreGui" end
module.Close();task.wait(1);assert(not gui.Enabled,"close")
module.Show({Kind="Money",ProductId=3715613401,Reward="MONEY",Amount=25000})
task.wait(.3)
local secondGui=module.GetGui()
local secondCard=secondGui.Popup.Card
local secondName=secondCard:FindFirstChild("Reward"):FindFirstChild("RewardName")
local secondShard=secondCard:FindFirstChild("ShardBonus")
assert(secondGui.Enabled and secondName.Text=="$25K MONEY","second popup: "..secondName.Text)
assert(not secondShard.Visible,"money shard hidden")
module.Close();task.wait(1)
if gui.Parent then gui:Destroy() end
if secondGui.Parent then secondGui:Destroy() end
return "PASS: responsive thank-you popup, food/shard art and copy, sequential money popup, sound and close"
'@
$suffix=$suffix.Replace('__KEEP_PREVIEW__',$(if($KeepPreview){'true'}else{'false'}))
$code=$prefix+"`n"+$source+"`n"+$suffix
$body=@{jsonrpc='2.0';id=1501;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue

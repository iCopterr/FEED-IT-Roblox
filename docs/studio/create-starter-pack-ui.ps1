# Author a separate modal using the existing shop's visual templates.
# Does not modify ShopUI. Run only for initial creation, not to overwrite Studio edits.
$ErrorActionPreference='Stop'
$destination=Join-Path (Get-Location) 'src/ui/StarterPackUI.rbxmx'
if(Test-Path -LiteralPath $destination){throw 'StarterPackUI already exists; preserve authored edits.'}
$xml=[xml](Get-Content 'src/ui/ShopUI.rbxmx' -Raw)
function Child($node,$name){$node.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")}
function Prop($node,$name,$value){$node.SelectSingleNode("Properties/*[@name='$name']").InnerText=$value}
function Rect($node,$name,$xs,$xo,$ys,$yo){
 $p=$node.SelectSingleNode("Properties/UDim2[@name='$name']")
 $p.XS=[string]$xs;$p.XO=[string]$xo;$p.YS=[string]$ys;$p.YO=[string]$yo
}
$gui=$xml.roblox.Item
Prop $gui 'Name' 'StarterPackUI'
Prop $gui 'DisplayOrder' 70
$panel=Child $gui 'Panel'
foreach($node in @($gui.SelectNodes('Item'))){if($node -ne $panel){[void]$gui.RemoveChild($node)}}
Rect $panel 'Size' 0 760 0 386
Prop $panel 'Visible' 'false'
Prop (Child $panel 'Title') 'Text' 'STARTER PACK'
$offers=Child $panel 'Offers'
$card=Child $offers 'Welcome'
foreach($node in @($offers.SelectNodes('Item'))){if($node -ne $card){[void]$offers.RemoveChild($node)}}
Rect $offers 'Position' 0 18 0 88
Rect $offers 'Size' 1 -36 0 280
Rect $offers 'CanvasSize' 0 0 0 0
Prop $offers 'ScrollingEnabled' 'false'
Prop $offers 'ScrollBarThickness' 0
Rect $card 'Position' 0 8 0 8
Rect $card 'Size' 0 708 0 264
# Owner's shop contains duplicate imported artwork/gradient nodes; the new modal
# needs only the first of each. The original asset is left completely untouched.
foreach($name in @('Artwork','OfferGradient')){
 $nodes=@($card.SelectNodes("Item[Properties/string[@name='Name']='$name']"))
 for($i=1;$i -lt $nodes.Count;$i++){[void]$card.RemoveChild($nodes[$i])}
}
$art=Child $card 'Artwork'
Rect $art 'Position' 0 16 0 22
Rect $art 'Size' 0 248 0 220
$title=Child $card 'Title'
Prop $title 'Text' 'WELCOME TREAT PACK'
Prop $title 'TextSize' 28
Rect $title 'Position' 0 282 0 20
Rect $title 'Size' 0 406 0 44
$description=Child $card 'Description'
Prop $description 'Text' "2 Hearty Food + 1 Royal Food`n1 Revive Charm`nOnce per player"
Prop $description 'TextSize' 23
Rect $description 'Position' 0 282 0 74
Rect $description 'Size' 0 406 0 108
$buy=Child $card 'Buy'
Prop $buy 'Active' 'true'
Prop $buy 'Interactable' 'true'
Rect $buy 'Position' 0 282 0 202
Rect $buy 'Size' 0 406 0 48
Prop (Child $buy 'ButtonText') 'Text' 'BUY • 9 ROBUX'
# Make all exported referents unique to this separate authored ScreenGui.
$refs=@{};$index=0
foreach($node in $xml.SelectNodes('//Item')){
 $old=$node.GetAttribute('referent');$index++;$new="StarterPack_$index"
 $refs[$old]=$new;$node.SetAttribute('referent',$new)
}
foreach($ref in $xml.SelectNodes('//Ref')){if($refs.ContainsKey($ref.InnerText)){$ref.InnerText=$refs[$ref.InnerText]}}
[IO.File]::WriteAllText($destination,$xml.OuterXml,[Text.UTF8Encoding]::new($false))
'Created standalone StarterPackUI; original ShopUI unchanged.'

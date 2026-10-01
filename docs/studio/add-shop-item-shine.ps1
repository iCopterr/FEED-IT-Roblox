# Mechanical XML asset addition; preserves every existing authored node/property.
$ErrorActionPreference='Stop'
$path=(Resolve-Path 'src/ui/ShopUI.rbxmx').Path
$raw=[IO.File]::ReadAllText($path)
$xml=[xml]$raw
$offers=$xml.SelectSingleNode('//Item[Properties/string[@name="Name"]="Offers"]')
$count=0
foreach($name in @('Welcome','DoubleMoney','Money1','Money2','Money3','Money4','Money5','Money6')) {
 $card=$offers.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")
 if(!$card){throw "Missing $name"}
 if($card.SelectSingleNode('Item[Properties/string[@name="Name"]="ItemShine"]')){continue}
 $art=$card.SelectSingleNode('Item[Properties/string[@name="Name"]="Artwork"]')
 if(!$art){throw "Missing artwork $name"}
 $size=$art.SelectSingleNode('Properties/UDim2[@name="Size"]')
 $pos=$art.SelectSingleNode('Properties/UDim2[@name="Position"]')
 $anchor=$art.SelectSingleNode('Properties/Vector2[@name="AnchorPoint"]')
 $xs=[double]$pos.XS + [double]$size.XS*(.5-[double]$anchor.X)
 $ys=[double]$pos.YS + [double]$size.YS*(.5-[double]$anchor.Y)
 $xo=[double]$pos.XO + [double]$size.XO*(.5-[double]$anchor.X)
 $yo=[double]$pos.YO + [double]$size.YO*(.5-[double]$anchor.Y)
 $side=[Math]::Max([double]$size.XO,[double]$size.YO)*1.5
 $corner=$card.SelectSingleNode('Item[@class="UICorner"]/Properties/UDim[@name="CornerRadius"]')
 $cornerXml=if($corner){$corner.OuterXml}else{'<UDim name="CornerRadius"><S>0</S><O>12</O></UDim>'}
 $fragment=$xml.CreateDocumentFragment()
 $fragment.InnerXml=@"
<Item class="CanvasGroup" referent="ShopShine_$name"><Properties><string name="Name">ItemShine</string><bool name="Active">false</bool><bool name="Interactable">false</bool><float name="BackgroundTransparency">1</float><int name="BorderSizePixel">0</int><bool name="ClipsDescendants">true</bool><UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2><int name="ZIndex">2</int><bool name="Visible">true</bool></Properties><Item class="UICorner" referent="ShopShineCorner_$name"><Properties><string name="Name">UICorner</string>$cornerXml</Properties></Item><Item class="ImageLabel" referent="ShopShineRays_$name"><Properties><string name="Name">Rays</string><bool name="Active">false</bool><bool name="Interactable">false</bool><bool name="Selectable">false</bool><float name="BackgroundTransparency">1</float><int name="BorderSizePixel">0</int><Vector2 name="AnchorPoint"><X>0.5</X><Y>0.5</Y></Vector2><Content name="ImageContent"><uri>rbxassetid://119106720608654</uri></Content><Color3 name="ImageColor3"><R>1</R><G>1</G><B>1</B></Color3><float name="ImageTransparency">0.4</float><UDim2 name="Position"><XS>$xs</XS><XO>$xo</XO><YS>$ys</YS><YO>$yo</YO></UDim2><UDim2 name="Size"><XS>0</XS><XO>$side</XO><YS>0</YS><YO>$side</YO></UDim2><token name="ScaleType">0</token><float name="Rotation">0</float><int name="ZIndex">2</int><bool name="Visible">true</bool></Properties></Item></Item>
"@
 [void]$card.AppendChild($fragment)
 $count++
}
if($count -gt 0){[IO.File]::WriteAllText($path,$xml.OuterXml,[Text.UTF8Encoding]::new($false))}
"Added $count authored shop shine layers"

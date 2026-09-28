# Edit saved ScreenGui geometry, never create UI at runtime.
$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot '../../src/ui/FeedYourPetUI.rbxmx'
$doc=[xml](Get-Content $path -Raw -Encoding UTF8)
function Prop($item,$tag,$name,$value) {
    $node=$item.SelectSingleNode("Properties/*[@name='$name']")
    if (!$node) { $node=$doc.CreateElement($tag);$node.SetAttribute('name',$name);[void]$item.Properties.AppendChild($node) }
    $node.InnerText=$value
}
function Rect($item,$name,$xs,$xo,$ys,$yo) {
    $node=$item.SelectSingleNode("Properties/UDim2[@name='$name']")
    if (!$node) { $node=$doc.CreateElement('UDim2');$node.SetAttribute('name',$name);[void]$item.Properties.AppendChild($node) }
    $node.InnerXml="<XS>$xs</XS><XO>$xo</XO><YS>$ys</YS><YO>$yo</YO>"
}
function Child($item,$name) { $item.SelectSingleNode("Item[Properties/string[@name='Name']='$name']") }
$panel=$doc.SelectSingleNode("//Item[Properties/string[@name='Name']='FeedPanel']")
$sidebar=Child $panel 'FoodCards'
Rect $sidebar 'Position' 0 584 0 0
Rect $sidebar 'Size' 0 300 0 620
foreach ($surface in @($panel,$sidebar)) {
    foreach ($layerName in @('PageTexture','PageHeader')) {
        $layer=Child $surface $layerName
        Rect $layer 'Position' 0 4 0 4
        if ($layerName -eq 'PageTexture') { Rect $layer 'Size' 1 -8 1 -8 }
        else { Rect $layer 'Size' 1 -8 0 54 }
        $corner=$layer.SelectSingleNode("Item[@class='UICorner']")
        if (!$corner) {
            $corner=$doc.CreateElement('Item');$corner.SetAttribute('class','UICorner')
            $corner.InnerXml='<Properties><string name="Name">ArtCorner</string><UDim name="CornerRadius"><S>0</S><O>11</O></UDim></Properties>'
            [void]$layer.AppendChild($corner)
        } else { $corner.SelectSingleNode('Properties/UDim[@name="CornerRadius"]').InnerXml='<S>0</S><O>11</O>' }
    }
}
$list=Child $sidebar 'List'
Rect $list 'Position' 0 20 0 80
Rect $list 'Size' 1 -40 1 -104
$layout=$list.SelectSingleNode("Item[@class='UIListLayout']")
$layout.SelectSingleNode('Properties/UDim[@name="Padding"]').InnerXml='<S>0</S><O>16</O>'
Prop $list 'float' 'ScrollBarThickness' 4
$padding=$list.SelectSingleNode("Item[@class='UIPadding']")
if (!$padding) {
    $padding=$doc.CreateElement('Item');$padding.SetAttribute('class','UIPadding')
    $padding.InnerXml='<Properties><string name="Name">BorderClearance</string></Properties>'
    [void]$list.AppendChild($padding)
}
foreach ($side in @('Top','Bottom','Left','Right')) {
    $property='Padding'+$side
    $node=$padding.SelectSingleNode("Properties/UDim[@name='$property']")
    if (!$node) { $node=$doc.CreateElement('UDim');$node.SetAttribute('name',$property);[void]$padding.Properties.AppendChild($node) }
    $gap=if ($side -eq 'Right') { 16 } else { 6 }
    $node.InnerXml="<S>0</S><O>$gap</O>"
}
foreach ($card in $list.SelectNodes("Item[@class='TextButton']")) {
    Rect $card 'Size' 1 0 0 128
    $texture=Child $card 'ButtonTexture'
    if ($texture) {
        Rect $texture 'Position' 0 2 0 2
        Rect $texture 'Size' 1 -4 1 -4
        $corner=$texture.SelectSingleNode("Item[@class='UICorner']")
        if (!$corner) {
            $corner=$doc.CreateElement('Item');$corner.SetAttribute('class','UICorner')
            $corner.InnerXml='<Properties><string name="Name">ArtCorner</string><UDim name="CornerRadius"><S>0</S><O>12</O></UDim></Properties>'
            [void]$texture.AppendChild($corner)
        }
    }
    $art=Child $card 'Art'
    Rect $art 'Position' 0 12 0.5 -38
    Rect $art 'Size' 0 76 0 76
    $name=Child $card 'ItemName'
    Rect $name 'Position' 0 100 0 14
    Rect $name 'Size' 1 -112 0 48
    Prop $name 'float' 'TextSize' 24
    Prop $name 'token' 'TextXAlignment' 0
    $quantity=Child $card 'Quantity'
    Rect $quantity 'Position' 0 100 0 64
    Rect $quantity 'Size' 1 -112 0 24
    Prop $quantity 'float' 'TextSize' 24
    Prop $quantity 'token' 'TextXAlignment' 0
    $risk=Child $card 'Risk'
    Rect $risk 'Position' 0 100 0 94
    Rect $risk 'Size' 1 -112 0 26
    Prop $risk 'float' 'TextSize' 20
    Prop $risk 'token' 'TextXAlignment' 0
    foreach ($label in @($name,$quantity,$risk)) {
        foreach ($stroke in $label.SelectNodes("Item[@class='UIStroke']")) { Prop $stroke 'float' 'Thickness' 2.5 }
    }
    foreach ($stroke in @($card.SelectNodes("Item[@class='UIStroke']"))) {
        $strokeName=$stroke.SelectSingleNode("Properties/string[@name='Name']").InnerText
        if ($strokeName -ne 'Stroke') { [void]$card.RemoveChild($stroke) }
        else { Prop $stroke 'float' 'Thickness' 2 }
    }
}
[System.IO.File]::WriteAllText($path,$doc.OuterXml,[System.Text.UTF8Encoding]::new($false))

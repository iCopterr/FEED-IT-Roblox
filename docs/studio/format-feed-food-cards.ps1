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
    $node.InnerXml="<XS>$xs</XS><XO>$xo</XO><YS>$ys</YS><YO>$yo</YO>"
}
function Child($item,$name) { $item.SelectSingleNode("Item[Properties/string[@name='Name']='$name']") }
$panel=$doc.SelectSingleNode("//Item[Properties/string[@name='Name']='FeedPanel']")
$sidebar=Child $panel 'FoodCards'
$list=Child $sidebar 'List'
Rect $list 'Position' 0 12 0 76
Rect $list 'Size' 1 -24 1 -90
Prop $list 'float' 'ScrollBarThickness' 4
foreach ($card in $list.SelectNodes("Item[@class='TextButton']")) {
    Rect $card 'Size' 1 -10 0 108
    $art=Child $card 'Art'
    Rect $art 'Position' 0 8 0 12
    Rect $art 'Size' 0 60 0 60
    $name=Child $card 'ItemName'
    Rect $name 'Position' 0 76 0 12
    Rect $name 'Size' 1 -82 0 42
    Prop $name 'float' 'TextSize' 20
    Prop $name 'token' 'TextXAlignment' 0
    $quantity=Child $card 'Quantity'
    Rect $quantity 'Position' 0 76 0 55
    Rect $quantity 'Size' 1 -82 0 24
    Prop $quantity 'float' 'TextSize' 18
    Prop $quantity 'token' 'TextXAlignment' 0
    $risk=Child $card 'Risk'
    Rect $risk 'Position' 0 12 1 -27
    Rect $risk 'Size' 1 -24 0 22
    Prop $risk 'float' 'TextSize' 16
    foreach ($label in @($name,$quantity,$risk)) {
        foreach ($stroke in $label.SelectNodes("Item[@class='UIStroke']")) { Prop $stroke 'float' 'Thickness' 1.5 }
    }
    foreach ($stroke in @($card.SelectNodes("Item[@class='UIStroke']"))) {
        $strokeName=$stroke.SelectSingleNode("Properties/string[@name='Name']").InnerText
        if ($strokeName -ne 'Stroke') { [void]$card.RemoveChild($stroke) }
        else { Prop $stroke 'float' 'Thickness' 2 }
    }
}
[System.IO.File]::WriteAllText($path,$doc.OuterXml,[System.Text.UTF8Encoding]::new($false))

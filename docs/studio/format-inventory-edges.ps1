$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot '../../src/ui/FeedYourPetUI.rbxmx'
$doc=[xml](Get-Content $path -Raw -Encoding UTF8)
$inventory=$doc.SelectSingleNode("//Item[Properties/string[@name='Name']='Inventory']")
function Rect($item,$name,$xs,$xo,$ys,$yo) {
    $node=$item.SelectSingleNode("Properties/UDim2[@name='$name']")
    if (!$node) { $node=$doc.CreateElement('UDim2');$node.SetAttribute('name',$name);[void]$item.Properties.AppendChild($node) }
    $node.InnerXml="<XS>$xs</XS><XO>$xo</XO><YS>$ys</YS><YO>$yo</YO>"
}
function Round($item,$radius) {
    $corner=$item.SelectSingleNode("Item[@class='UICorner']")
    if (!$corner) {
        $corner=$doc.CreateElement('Item');$corner.SetAttribute('class','UICorner')
        $corner.InnerXml='<Properties><string name="Name">ArtCorner</string><UDim name="CornerRadius"><S>0</S><O>0</O></UDim></Properties>'
        [void]$item.AppendChild($corner)
    }
    $corner.SelectSingleNode('Properties/UDim[@name="CornerRadius"]').InnerXml="<S>0</S><O>$radius</O>"
}
foreach ($name in @('PageHeader','PageTexture')) {
    $layer=$inventory.SelectSingleNode(".//Item[Properties/string[@name='Name']='$name']")
    Rect $layer 'Position' 0 4 0 4
    if ($name -eq 'PageHeader') { Rect $layer 'Size' 1 -8 0 50 }
    else { Rect $layer 'Size' 1 -8 1 -8 }
    Round $layer 11
}
$stripe=$inventory.SelectSingleNode(".//Item[Properties/string[@name='Name']='RarityStripe']")
Rect $stripe 'Position' 0 14 0 7
Rect $stripe 'Size' 1 -28 0 5
Round $stripe 3
[System.IO.File]::WriteAllText($path,$doc.OuterXml,[System.Text.UTF8Encoding]::new($false))
foreach ($screen in @('PenManagerUI','MerchantUI')) {
    $path=Join-Path $PSScriptRoot "../../src/ui/$screen.rbxmx"
    $doc=[xml](Get-Content $path -Raw -Encoding UTF8)
    foreach ($layer in $doc.SelectNodes("//Item[Properties/string[@name='Name']='PageHeader' or Properties/string[@name='Name']='PageTexture' or Properties/string[@name='Name']='Texture']")) {
        $name=$layer.SelectSingleNode('Properties/string[@name="Name"]').InnerText
        $height=$layer.SelectSingleNode('Properties/UDim2[@name="Size"]/YO').InnerText
        Rect $layer 'Position' 0 4 0 4
        if ($name -eq 'PageHeader') { Rect $layer 'Size' 1 -8 0 ([math]::Max(48,[int]$height-4)) }
        else { Rect $layer 'Size' 1 -8 1 -8 }
        Round $layer 11
    }
    if ($screen -eq 'MerchantUI') {
        $offers=$doc.SelectSingleNode("//Item[Properties/string[@name='Name']='Offers']")
        $padding=$offers.SelectSingleNode("Item[@class='UIPadding']")
        if (!$padding) {
            $padding=$doc.CreateElement('Item');$padding.SetAttribute('class','UIPadding')
            $padding.InnerXml='<Properties><string name="Name">BorderClearance</string></Properties>'
            [void]$offers.AppendChild($padding)
        }
        foreach ($side in @('Top','Bottom','Left','Right')) {
            $name='Padding'+$side;$node=$padding.SelectSingleNode("Properties/UDim[@name='$name']")
            if (!$node) { $node=$doc.CreateElement('UDim');$node.SetAttribute('name',$name);[void]$padding.Properties.AppendChild($node) }
            $gap=if ($side -eq 'Right') { 16 } else { 8 }
            $node.InnerXml="<S>0</S><O>$gap</O>"
        }
    }
    [System.IO.File]::WriteAllText($path,$doc.OuterXml,[System.Text.UTF8Encoding]::new($false))
}

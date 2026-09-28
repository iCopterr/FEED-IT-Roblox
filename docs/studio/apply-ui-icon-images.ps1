# Mechanical migration of authored ScreenGui art; does not generate UI at runtime.
$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '../..')
$manifest = Get-Content (Join-Path $repo 'assets/ui/emoji-icons-v1/manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$images = @{}
$emojiImages = @{}
foreach ($icon in $manifest.icons) {
    $images[$icon.name] = 'rbxassetid://' + $icon.robloxAssetId
    if ($icon.name -in @('money','egg','pets','index')) { $emojiImages[$icon.emoji] = $images[$icon.name] }
}
function Set-XmlProperty($doc, $item, $tag, $name, $value) {
    $old = $item.SelectSingleNode("Properties/*[@name='$name']")
    if ($old) { [void]$old.ParentNode.RemoveChild($old) }
    $node = $doc.CreateElement($tag)
    $node.SetAttribute('name', $name)
    if ($tag -eq 'Content') { $url = $doc.CreateElement('url'); $url.InnerText = $value; [void]$node.AppendChild($url) }
    else { $node.InnerText = $value }
    [void]$item.Properties.AppendChild($node)
}
foreach ($file in @('FeedYourPetUI','PenManagerUI','IndexUI','MerchantUI')) {
    $path = Join-Path $repo "src/ui/$file.rbxmx"
    $doc = [xml](Get-Content $path -Raw -Encoding UTF8)
    foreach ($item in @($doc.SelectNodes('//Item'))) {
        $name = $item.SelectSingleNode('Properties/string[@name="Name"]').InnerText
        $text = $item.SelectSingleNode('Properties/string[@name="Text"]')
        if ($item.class -eq 'TextLabel' -and $text -and $emojiImages.ContainsKey($text.InnerText)) {
            $image = $emojiImages[$text.InnerText]
            $item.SetAttribute('class', 'ImageLabel')
            foreach ($prop in @($item.Properties.ChildNodes)) {
                if ($prop.GetAttribute('name') -match '^(Text|Font|LineHeight|MaxVisibleGraphemes|RichText)') { [void]$item.Properties.RemoveChild($prop) }
            }
            foreach ($stroke in @($item.SelectNodes('Item[@class="UIStroke"]'))) { [void]$item.RemoveChild($stroke) }
            Set-XmlProperty $doc $item 'Content' 'Image' $image
            Set-XmlProperty $doc $item 'token' 'ScaleType' '3'
        }
        if ($item.class -eq 'ImageLabel' -and $name -in @('Art','FoodArt','Picture')) {
            $parentName = $item.ParentNode.SelectSingleNode('Properties/string[@name="Name"]').InnerText
            $key = if ($images.ContainsKey($parentName+'-food')) { $parentName+'-food' } else { 'empty-food' }
            Set-XmlProperty $doc $item 'Content' 'Image' $images[$key]
            Set-XmlProperty $doc $item 'token' 'ScaleType' '3'
        }
        if ($item.class -eq 'TextLabel' -and $name -eq 'Emoji') {
            Set-XmlProperty $doc $item 'bool' 'Visible' 'false'
        }
    }
    [System.IO.File]::WriteAllText($path, $doc.OuterXml, [System.Text.UTF8Encoding]::new($false))
    Write-Output "Updated authored art: $file"
}

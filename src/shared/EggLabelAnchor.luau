-- Keep labels over the egg body, independent of descendant ordering or trim.
local Anchor = {}

function Anchor.Bind(model: Model, label: BillboardGui): Attachment
	local shell = model:FindFirstChild("Shell", true)
	local body = if shell and shell:IsA("BasePart") then shell else model.PrimaryPart
	assert(body, "Egg label requires a Shell or PrimaryPart")
	local bounds, size = model:GetBoundingBox()
	local point = Vector3.new(body.Position.X, bounds.Position.Y + size.Y / 2 + 2.5, body.Position.Z)
	local anchor = Instance.new("Attachment")
	anchor.Name = "EggLabelAnchor"
	anchor.Position = body.CFrame:PointToObjectSpace(point)
	anchor.Parent = body
	-- A single explicit attachment avoids combining part-origin and GUI offsets.
	label.StudsOffset = Vector3.zero
	label.StudsOffsetWorldSpace = Vector3.zero
	label.ExtentsOffset = Vector3.zero
	label.ExtentsOffsetWorldSpace = Vector3.zero
	label.SizeOffset = Vector2.zero
	label.Adornee = anchor
	label.Parent = body
	return anchor
end

return table.freeze(Anchor)

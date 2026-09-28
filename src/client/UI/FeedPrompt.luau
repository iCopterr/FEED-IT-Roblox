local FeedPrompt={}

function FeedPrompt.CanOpen(prompt,userId,petId,root)
	if not prompt or not prompt:IsA("ProximityPrompt") or prompt.Name~="OpenFeedUI"
		or not petId or not root or not root:IsA("BasePart") then return false end
	local model=prompt:FindFirstAncestorOfClass("Model")
	if not model or model:GetAttribute("OwnerUserId")~=userId
		or model:GetAttribute("PetId")~=petId then return false end
	local anchor=prompt.Parent
	-- Large pets keep the interaction at plate height through an Attachment.
	local position=if anchor and anchor:IsA("Attachment") then anchor.WorldPosition
		elseif anchor and anchor:IsA("BasePart") then anchor.Position else nil
	return position~=nil and (root.Position-position).Magnitude<=prompt.MaxActivationDistance+1
end

return FeedPrompt

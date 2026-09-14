-- Geometry and typography live in StarterGui; only selection tint is dynamic.
local Stud = {}

function Stud.Tint(component, color)
	component.UIGradient.Color = ColorSequence.new(color, color:Lerp(Color3.new(), 0.2))
	component.UIStroke.Color = color:Lerp(Color3.new(), 0.65)
end

return Stud

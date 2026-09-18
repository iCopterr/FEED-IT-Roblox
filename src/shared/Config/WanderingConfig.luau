-- Presentation only; no economy or persisted-position changes.
return table.freeze({
	Speed = 3,
	MinPauseSeconds = 2,
	MaxPauseSeconds = 4,
	MinWalkDistance = 4,
	MaxWalkDistance = 10,
	FenceClearance = 0.5,
	MaxStepSeconds = 0.1,
})

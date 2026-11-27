extends Node3D

# Visual component only; the game owns strategic state and unlocks.
func set_orientation(priorities: Vector3, autonomy: float) -> void:
	var weights := Vector3(maxf(priorities.x,0),maxf(priorities.y,0),maxf(priorities.z,0))
	var total := weights.x + weights.y + weights.z
	if total <= 0.0:
		weights = Vector3.ONE / 3.0
	else:
		weights /= total
	$BoardSurface/StrategyDisplay/StrategyMarker.position = Vector3(-0.43,1.40,0.10)*weights.x + Vector3(0,2.00,0.10)*weights.y + Vector3(0.43,1.40,0.10)*weights.z
	$BoardSurface/StrategyDisplay/AutonomyMarker.position = Vector3(lerpf(-0.46,0.46,clampf(autonomy,0,1)),1.05,0.10)

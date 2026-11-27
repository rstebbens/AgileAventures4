extends RefCounted
# Rebuild a flat navigation grid from actual room physics on each click.
# This automatically includes newly enabled furniture collision.
const STEP := 0.2
const WIDTH := 46
const HEIGHT := 31
const MIN_X := -4.5
const MIN_Z := -2.9

func _point(id: Vector2i, y: float) -> Vector3:
	return Vector3(MIN_X + id.x * STEP, y, MIN_Z + id.y * STEP)

func route(player: CharacterBody3D, destination: Vector3) -> PackedVector3Array:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, WIDTH, HEIGHT)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.65
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var space := player.get_world_3d().direct_space_state
	var start := Vector2i(-1, -1)
	var best_start := INF
	var candidates: Array[Vector2i] = []
	for x in range(WIDTH):
		for z in range(HEIGHT):
			var id := Vector2i(x, z)
			var p := _point(id, player.global_position.y)
			query.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.85, 0))
			if not space.intersect_shape(query, 1).is_empty():
				grid.set_point_solid(id)
				continue
			candidates.append(id)
			var d := p.distance_squared_to(player.global_position)
			if d < best_start:
				best_start = d
				start = id
	if start.x < 0:
		return PackedVector3Array()
	candidates.sort_custom(func(a: Vector2i, b: Vector2i): return _point(a, player.global_position.y).distance_squared_to(destination) < _point(b, player.global_position.y).distance_squared_to(destination))
	for goal in candidates:
		var ids := grid.get_id_path(start, goal)
		if ids.is_empty():
			continue
		var result := PackedVector3Array()
		for id in ids:
			result.append(_point(id, player.global_position.y))
		return result
	return PackedVector3Array()

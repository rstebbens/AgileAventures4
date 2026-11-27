extends Node3D

# Procedural 3D vertical slice: fixed orthographic camera, walkable boardroom,
# decision lock and a factory reveal. Meshes are temporary until authored assets arrive.
const WALK_SPEED := 3.0
var dave: CharacterBody3D
var dave_art: Node3D
var walk_clock := 0.0
var idle_clock := 0.0
var emote := "neutral"
var martin: Node3D
var camera: Camera3D
var target := Vector3.ZERO
var auto_walk := false
@export var bake_environments := false
var phase := "explore"
var nearby := ""
var prompt: Label3D
var highlight: MeshInstance3D
var interact_meshes := {}
var interaction_settings := {}
var highlighted_mesh: MeshInstance3D
var highlight_material: StandardMaterial3D
@export var walk_speed := 1.5
@export var walk_animation_speed := 2.5
@export var idle_animation_speed := 1.5
var choice := ""
var factory_seen := false
var strategy_board: Node3D
var strategy := Vector3(0.45, 0.10, 0.45)
var autonomy := 0.25
var recovery_discussed := false
var dialogue_lines: Array[String] = []
var line_number := 0
var after_dialogue := ""
var panel: PanelContainer
var message: Label
var actions: HBoxContainer
var title_label: Label
var factory_root: Node3D
var boardroom_root: Node3D
var objects := {
	"Martin": Vector3(2.7, 0, 0.8),
	"Research": Vector3(-3.5, 0, -2.25),
	"Order": Vector3(-1.0, 0, -2.25),
	"Dashboard": Vector3(3.0, 0, -2.25),
	"Coffee": Vector3(-4.0, 0, 1.8)
}
var palette := {
	"floor": Color("#b7a99a"),
	"wall": Color("#e5d5c1"),
	"wood": Color("#946f50"),
	"wood_dark": Color("#5b4436"),
	"chair": Color("#34363b"),
	"metal": Color("#4b5963"),
	"paper": Color("#f7eddb"),
	"purple": Color("#7950a4")
}

func _ready() -> void:
	_setup_world()
	if bake_environments:
		_make_boardroom()
		_make_factory()
		_bake_rooms()
		get_tree().quit()
		return
	if ResourceLoader.exists("res://scenes/BoardroomEditable.tscn") and ResourceLoader.exists("res://scenes/FactoryEditable.tscn"):
		_load_rooms()
	else:
		_make_boardroom()
		_make_factory()
	factory_root.visible = false
	_make_strategy_board()
	_make_ui()
	_setup_interaction_hint()
	panel.visible = false

func _setup_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#d4c3ae")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff2df")
	env.ambient_light_energy = 0.43
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -34, 0)
	sun.light_energy = 0.68
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5
	add_child(camera)
	camera.position = Vector3(14, 13, 14)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	camera.make_current()

func _material(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _block(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = position
	parent.add_child(node)
	return node

func _sphere(parent: Node3D, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = position
	parent.add_child(node)
	return node

func _make_boardroom() -> void:
	boardroom_root = Node3D.new()
	boardroom_root.name = "Boardroom"
	add_child(boardroom_root)
	_block(boardroom_root, Vector3(0,-0.24,0), Vector3(10.5,0.45,7.5), Color("#54483e"))
	for i in range(10):
		for j in range(7):
			_block(boardroom_root, Vector3(-4.725+i*1.05,0.015,-3.21+j*1.07), Vector3(1.035,0.06,1.055), Color("#a99b87") if (i+j)%2 == 0 else Color("#a39785"))
	# Genuine apertures in the back wall, built from separate masonry pieces.
	_block(boardroom_root, Vector3(0,0.45,-3.72), Vector3(10.5,0.9,0.25), palette["wall"])
	_block(boardroom_root, Vector3(0,3.3,-3.72), Vector3(10.5,0.6,0.25), palette["wall"])
	for item in [Vector2(-4.795,0.91),Vector2(-2.65,0.62),Vector2(2.145,6.21)]:
		_block(boardroom_root, Vector3(item.x,1.95,-3.72), Vector3(item.y,2.1,0.25), palette["wall"])
	for x in [-3.65,-1.65]:
		_window(x)
	_block(boardroom_root, Vector3(-5.23,1.8,0), Vector3(0.24,3.6,7.5), palette["wall"])
	_block(boardroom_root, Vector3(0,3.64,-3.72), Vector3(10.7,0.2,0.35), palette["wood_dark"])
	_block(boardroom_root, Vector3(-5.23,3.64,0), Vector3(0.35,0.2,7.6), palette["wood_dark"])
	for i in range(23):
		_block(boardroom_root,Vector3(-5.08,1.8,-3.55+i*0.31),Vector3(0.08,3.5,0.23),Color("#b58c66"))
	_block(boardroom_root,Vector3(0,0.85,0.3),Vector3(4.4,0.18,1.75),palette["wood"])
	_block(boardroom_root,Vector3(0,0.73,0.3),Vector3(4.3,0.1,1.65),palette["wood_dark"])
	_obstacle(Vector3(0,0.55,0.3),Vector3(4.4,1.1,1.75))
	for x in [-1.85,1.85]:
		for z in [-0.35,0.95]:
			_block(boardroom_root,Vector3(x,0.42,z),Vector3(0.12,0.8,0.12),palette["wood_dark"])
	for x in [-1.5,0.0,1.5]:
		for z in [-1.25,1.85]:
			_chair(Vector3(x,0,z),z>0)
	for x in [0.8,4.35]:
		_bookcase(x)
	_block(boardroom_root,Vector3(2.55,0.4,-3.22),Vector3(2.25,0.8,0.85),palette["wood_dark"])
	_obstacle(Vector3(2.55,0.4,-3.22),Vector3(2.25,0.8,0.85))
	_block(boardroom_root,Vector3(2.55,2.05,-3.53),Vector3(2.2,1.35,0.14),Color("#20262c"))
	interact_meshes["Dashboard"] = _block(boardroom_root,Vector3(2.55,2.05,-3.44),Vector3(2.04,1.19,0.025),Color("#304957"))
	for i in range(5):
		_block(boardroom_root,Vector3(1.85+i*0.32,1.65+i*0.07,-3.41),Vector3(0.18,0.24+i*0.14,0.025),Color("#8bb5ae"))
	_block(boardroom_root,Vector3(-3.7,0.5,2.6),Vector3(0.9,1.0,0.8),palette["wood_dark"])
	_obstacle(Vector3(-3.7,0.5,2.6),Vector3(0.9,1.0,0.8))
	interact_meshes["Coffee"] = _block(boardroom_root,Vector3(-3.7,1.23,2.6),Vector3(0.55,0.46,0.48),Color("#333940"))
	objects["Coffee"] = Vector3(-3.7,0,2.0)
	_block(boardroom_root,Vector3(-3.7,1.19,2.88),Vector3(0.32,0.19,0.09),Color("#92999b"))
	for x in [-1.25,1.15]:
		_block(boardroom_root,Vector3(x,0.97,0.1),Vector3(0.65,0.045,0.46),Color("#aeb5ba"))
		var screen = _block(boardroom_root,Vector3(x,1.21,-0.11),Vector3(0.65,0.45,0.045),Color("#b6bec3"))
		screen.rotation_degrees.x = -12
		var key := "Research" if x < 0 else "Order"
		interact_meshes[key] = screen
		objects[key] = Vector3(x,0,1.05)
	_block(boardroom_root,Vector3(0,0.96,0.5),Vector3(0.45,0.025,0.32),palette["paper"])
	var clock = _sphere(boardroom_root,Vector3(-2.45,2.65,-3.53),0.25,Color("#51443a"))
	clock.scale.z = 0.14
	for i in range(12):
		var angle = i*TAU/12.0
		_block(boardroom_root,Vector3(-2.45+sin(angle)*0.19,2.65+cos(angle)*0.19,-3.48),Vector3(0.025,0.025,0.025),Color.WHITE)
	_block(boardroom_root,Vector3(-2.45,2.72,-3.46),Vector3(0.025,0.15,0.025),Color.WHITE)
	_block(boardroom_root,Vector3(-2.38,2.65,-3.46),Vector3(0.14,0.025,0.025),Color.WHITE)
	_spawn_dave(Vector3(-3.3,0.06,1.35))
	martin = _character(boardroom_root,Vector3(3.35,0.06,0.8),Color("#3d7564"))
	objects["Martin"] = martin.position
	objects["Dashboard"] = Vector3(2.55,0,-2.15)
	_obstacle(martin.position+Vector3(0,0.85,0),Vector3(0.65,1.7,0.65))
	martin.name = "Martin"

func _spawn_dave(at: Vector3) -> void:
	dave = CharacterBody3D.new()
	boardroom_root.add_child(dave)
	dave.position = at
	dave.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var body_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.65
	body_shape.shape = capsule
	body_shape.position.y = 0.85
	dave.add_child(body_shape)
	dave_art = _make_dave(dave)

func _obstacle(at: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	boardroom_root.add_child(body)
	body.position = at
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)

func _window(x: float) -> void:
	var frame = Color("#74583e")
	# Bright exterior set behind the aperture, leaving the wall opening intact.
	_block(boardroom_root,Vector3(x,1.95,-3.91),Vector3(1.35,2.08,0.04),Color("#bfd5df"))
	for dx in [-0.69,0.69,0.0]:
		_block(boardroom_root,Vector3(x+dx,1.95,-3.63),Vector3(0.065,2.1,0.16),frame)
	for y in [0.9,1.95,3.0]:
		_block(boardroom_root,Vector3(x,y,-3.63),Vector3(1.43,0.07,0.16),frame)
	_block(boardroom_root,Vector3(x,0.87,-3.49),Vector3(1.55,0.09,0.42),frame)
	for i in range(15):
		var slat = _block(boardroom_root,Vector3(x,2.96-i*0.065,-3.46),Vector3(1.42,0.035,0.13),Color("#d4c5aa"))
		slat.rotation_degrees.x = 22

func _bookcase(x: float) -> void:
	var z = -3.2
	_obstacle(Vector3(x,1.35,z),Vector3(1.1,2.7,0.76))
	_block(boardroom_root,Vector3(x,1.35,z-0.33),Vector3(1.1,2.7,0.09),palette["wood_dark"])
	for dx in [-0.51,0.51]:
		_block(boardroom_root,Vector3(x+dx,1.35,z),Vector3(0.08,2.7,0.75),palette["wood"])
	for y in [0.12,0.75,1.4,2.05,2.65]:
		_block(boardroom_root,Vector3(x,y,z),Vector3(1.1,0.09,0.75),palette["wood"])
	var colors = [Color("#895b46"),Color("#657e71"),Color("#d1b780"),Color("#54697b")]
	for row in range(3):
		for i in range(6):
			var h = 0.26+0.035*((i+row)%4)
			_block(boardroom_root,Vector3(x-0.36+i*0.13,0.8+row*0.65+h/2,z+0.1),Vector3(0.11,h,0.28),colors[(i+row)%4])

func _chair(at: Vector3, facing_front: bool) -> void:
	var back_z = 0.28 if facing_front else -0.28
	_obstacle(at+Vector3(0,0.6,0),Vector3(0.7,1.2,0.72))
	_block(boardroom_root,at+Vector3(0,0.46,0),Vector3(0.65,0.14,0.59),palette["chair"])
	var cushion = _sphere(boardroom_root,at+Vector3(0,0.93,back_z),0.36,Color("#4a4540"))
	cushion.scale = Vector3(0.94,1.48,0.25)
	for x in [-0.25,0.25]:
		for z in [-0.22,0.22]:
			_block(boardroom_root,at+Vector3(x,0.22,z),Vector3(0.045,0.44,0.045),palette["metal"])

func _joint(parent: Node3D, name_: String, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = name_
	joint.position = at
	parent.add_child(joint)
	return joint

func _ink(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var rod := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	rod.mesh = mesh
	rod.material_override = _material(color)
	parent.add_child(rod)
	rod.position = (a+b)*0.5
	var axis := (b-a).normalized()
	var helper := Vector3.RIGHT if absf(axis.dot(Vector3.FORWARD)) > 0.95 else Vector3.FORWARD
	var right := axis.cross(helper).normalized()
	rod.basis = Basis(right,axis,right.cross(axis).normalized())

func _oval(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var piece := _sphere(parent,at,0.5,color)
	piece.scale = dimensions
	return piece

func _soft_limb(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var piece := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = a.distance_to(b)+radius*2.0
	piece.mesh = mesh
	piece.material_override = _material(color,0.72)
	parent.add_child(piece)
	piece.position = (a+b)*0.5
	var axis := (b-a).normalized()
	var helper := Vector3.RIGHT if absf(axis.dot(Vector3.FORWARD)) > 0.95 else Vector3.FORWARD
	var right := axis.cross(helper).normalized()
	piece.basis = Basis(right,axis,right.cross(axis).normalized())

# Imported character, fitted to the existing room in world units.
var dave_animation: AnimationPlayer
var dave_wave_active := false
const DAVE_HEIGHT := 1.8
@export var dave_facing_offset_degrees := 180.0

func _make_dave(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "DaveArt"
	parent.add_child(root)
	var model := preload("res://Models/DaveRigged.glb").instantiate() as Node3D
	root.add_child(model)
	var bounds := AABB()
	var found := false
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		var local_bounds: AABB = (root.global_transform.affine_inverse() * mesh_node.global_transform) * mesh_node.get_aabb()
		bounds = bounds.merge(local_bounds) if found else local_bounds
		found = true
	if found and bounds.size.y > 0.001:
		var factor := DAVE_HEIGHT / bounds.size.y
		model.scale *= factor
		model.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	model.rotation.y += deg_to_rad(dave_facing_offset_degrees)
	dave_animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if dave_animation != null:
		for clip in dave_animation.get_animation_list():
			var animation := dave_animation.get_animation(clip)
			var short_name := String(clip).get_file().to_lower()
			if short_name == "idle" or short_name == "walk":
				animation.loop_mode = Animation.LOOP_LINEAR
			elif short_name == "wave":
				animation.loop_mode = Animation.LOOP_NONE
	else:
		push_warning("DaveRigged has no AnimationPlayer.")
	root.rotation.y = 0.78
	return root

func _dave_clip(wanted: String) -> StringName:
	if dave_animation != null:
		for clip in dave_animation.get_animation_list():
			if String(clip).get_file().to_lower() == wanted.to_lower():
				return clip
	return &""

func _pose_dave(state: String, _dt: float) -> void:
	if not is_instance_valid(dave_animation):
		return
	var wanted := "Idle"
	if state == "walk":
		wanted = "Walk"
	elif state == "welcome":
		wanted = "Wave"
		if dave_wave_active:
			if dave_animation.is_playing() and dave_animation.current_animation == _dave_clip("Wave"):
				return
			wanted = "Idle"
		dave_wave_active = true
	if state != "welcome":
		dave_wave_active = false
	var clip := _dave_clip(wanted)
	if clip == &"":
		clip = _dave_clip("Idle")
	if clip != &"" and (dave_animation.current_animation != clip or not dave_animation.is_playing()):
		dave_animation.play(clip, 0.18, walk_animation_speed if wanted == "Walk" else idle_animation_speed)

func _dialogue_emote() -> void:
	var words := message.text.to_lower()
	emote = "neutral"
	if "to camera" in words or "demographic" in words:
		emote = "confused"
		dave_art.rotation.y = 0.78
	elif "sample size" in words or "research" in words:
		emote = "thinking"
	elif "removed" in words or "no brakes" in words:
		emote = "frustrated"
	elif "nobody" in words:
		emote = "sad"
	elif "coffee" in words:
		emote = "welcome"

func _character(parent: Node3D, at: Vector3, clothing: Color) -> Node3D:
	var root = Node3D.new()
	root.position = at
	parent.add_child(root)
	var torso = _sphere(root,Vector3(0,0.94,0),0.31,clothing)
	torso.scale = Vector3(0.88,1.28,0.58)
	var skin = Color("#c98e68")
	var head = _sphere(root,Vector3(0,1.51,0),0.255,skin)
	head.scale.y = 1.13
	var hair = _sphere(root,Vector3(0,1.67,-0.045),0.245,Color("#49382f"))
	hair.scale = Vector3(1.02,0.6,0.98)
	for x in [-0.085,0.085]:
		_sphere(root,Vector3(x,1.54,0.225),0.038,Color("#f9f4e8"))
		_sphere(root,Vector3(x,1.54,0.254),0.018,Color("#28272b"))
		_block(root,Vector3(x,1.61,0.22),Vector3(0.085,0.025,0.025),Color("#49382f"))
	_sphere(root,Vector3(0,1.48,0.25),0.045,skin)
	_block(root,Vector3(0,1.39,0.214),Vector3(0.095,0.022,0.022),Color("#74463a"))
	for x in [-0.13,0.13]:
		_block(root,Vector3(x,0.34,0),Vector3(0.17,0.58,0.23),Color("#313947"))
		_block(root,Vector3(x,0.09,0.065),Vector3(0.19,0.15,0.32),Color("#322c29"))
	for x in [-0.31,0.31]:
		var arm = _sphere(root,Vector3(x,0.98,0),0.13,clothing)
		arm.scale.y = 2.1
		_sphere(root,Vector3(x,0.73,0),0.09,skin)
	_block(root,Vector3(0,1.15,0.175),Vector3(0.12,0.23,0.035),Color("#e2dbd3"))
	root.rotation.y = 0.65
	return root

func _make_factory() -> void:
	factory_root = Node3D.new()
	factory_root.name = "Factory"
	add_child(factory_root)
	_block(factory_root, Vector3(0, -0.2, 0), Vector3(10.5, 0.4, 7.5), Color("#9a9b97"))
	_block(factory_root, Vector3(0, 1.8, -3.72), Vector3(10.5, 3.6, 0.22), Color("#c6c4b7"))
	_block(factory_root, Vector3(-5.23, 1.8, 0), Vector3(0.22, 3.6, 7.5), Color("#b7b5ac"))
	for x in [-3.3, -1.1, 1.1, 3.3]:
		_block(factory_root, Vector3(x, 0.7, 0.2), Vector3(1.9, 0.2, 1.4), palette["metal"])
		for wheel_offset in [-0.5, 0.5]:
			_sphere(factory_root, Vector3(x + wheel_offset, 1.05, 0.2), 0.35, Color("#222a31"))
		_block(factory_root, Vector3(x, 1.1, 0.2), Vector3(1.15, 0.08, 0.12), Color("#d6a458"))
		_character(factory_root, Vector3(x, 0, -1.5), Color("#cb9b51"))
	_block(factory_root, Vector3(0, 0.5, 2.0), Vector3(9.3, 0.5, 1.3), Color("#52606a"))

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	title_label = Label.new()
	title_label.text = "Objective: Understand the Halvefords opportunity"
	title_label.position = Vector2(18, 15)
	title_label.add_theme_color_override("font_color", Color("#252a31"))
	layer.add_child(title_label)
	var hud := Control.new()
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	hud.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.anchor_left = 0.18
	panel.anchor_right = 0.82
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = -220
	panel.offset_bottom = -20
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#26343f")
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	var header_space := Control.new()
	header_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_space)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Close dialogue"
	close_button.custom_minimum_size = Vector2(38, 32)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(_dismiss_panel)
	header.add_child(close_button)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 40
	message.add_theme_font_size_override("font_size", 19)
	stack.add_child(message)
	actions = HBoxContainer.new()
	stack.add_child(actions)

func _buttons(options: Array[String], callback: Callable) -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for option in options:
		var b := Button.new()
		b.text = option
		b.pressed.connect(func(): callback.call(option))
		actions.add_child(b)

func _say(lines: Array[String], next_phase: String = "explore") -> void:
	dialogue_lines = lines
	line_number = 0
	after_dialogue = next_phase
	phase = "dialogue"
	panel.visible = true
	_show_line()

func _show_line() -> void:
	message.text = dialogue_lines[line_number]
	_dialogue_emote()
	_buttons(["Continue"], func(_unused): _advance())

func _advance() -> void:
	line_number += 1
	if line_number < dialogue_lines.size():
		_show_line()
	elif after_dialogue == "decision":
		phase = "decision"
		message.text = "MARTIN: What are we prioritizing?"
		_buttons(["Speed", "Comfort", "Cost"], func(value): _decide(value))
	elif after_dialogue == "factory":
		_start_factory()
	elif after_dialogue == "strategy_recovery":
		recovery_discussed = true
		strategy = Vector3(0.35, 0.35, 0.30)
		autonomy = 0.45
		_update_strategy_markers()
		phase = "explore"
		panel.visible = false
	else:
		phase = "explore"
		panel.visible = false

func _interact(name: String) -> void:
	if name == "Martin":
		if factory_seen and not recovery_discussed:
			_say(["DAVE: Three bikes, none accepted. Can we investigate the failure before producing more?", "MARTIN: Fine. Let the team investigate."] , "strategy_recovery")
		elif choice != "":
			_say(["MARTIN: We already committed to " + choice.to_lower() + ".", "DAVE (to camera): Apparently repeating it makes it a strategy."])
		else:
			_say(["MARTIN: Halvefords want 1,200 bikes by Christmas.", "DAVE: Why 27 gears and not 18?", "MARTIN: Twelve-year-olds prefer more gears.", "DAVE: Who's our target demographic?", "MARTIN: Middle-aged divorcees. Essentially the same thing.", "DAVE (to camera): You're hearing this too, right?"], "decision")
	elif name == "Research":
		_say(["RESEARCH: Twelve children surveyed. Preferred gear count: 27.", "DAVE: That is a sample size, not a strategy."])
	elif name == "Order":
		_say(["HALVEFORDS ORDER: 1,200 bicycles. Christmas deadline.", "DAVE: A deadline is not a product vision."])
	elif name == "Coffee":
		_say(["DAVE: At least the coffee machine knows what it's here for."])
	elif name == "Dashboard":
		if choice == "":
			_say(["DASHBOARD: No strategy selected."])
		elif not factory_seen:
			_say(["DAVE: Perhaps we should visit the factory first."])
		else:
			var summary := {"Speed": "Delivered quickly. Brakes omitted.", "Comfort": "Unrequested suspension. Costs and delays increase.", "Cost": "Basic brakes. Premium braking subscription."}
			_say(["DASHBOARD: " + summary[choice], "DAVE: A decision has consequences. Who knew?"])

func _decide(value: String) -> void:
	if choice != "":
		return
	choice = value
	_say(["MARTIN: Excellent. I'll tell the factory to prioritize " + value.to_lower() + ".", "DAVE (to camera): I have a feeling we should see this for ourselves."], "factory")

func _start_factory() -> void:
	boardroom_root.visible = false
	factory_root.visible = true
	phase = "factory"
	var consequences := {
		"Speed": ["FACTORY: Bicycles move through assembly at record speed.", "WORKER: We've removed the brake installation step.", "DAVE (to camera): No brakes. What could possibly slow us down?"],
		"Comfort": ["FACTORY: Premium suspension is fitted to every bicycle.", "WORKER: Nobody asked for it, and production takes twice as long.", "DAVE (to camera): We're solving a problem nobody has."],
		"Cost": ["FACTORY: Every bicycle receives basic working brakes.", "WORKER: Better stopping power is available on subscription.", "DAVE (to camera): Brakes as a service. Of course."]
	}
	dialogue_lines.assign(consequences[choice])
	line_number = 0
	_factory_beat()

func _factory_beat() -> void:
	message.text = dialogue_lines[line_number]
	if line_number < dialogue_lines.size() - 1:
		_buttons(["Next"], func(_unused):
			line_number += 1
			_factory_beat()
		)
	else:
		_buttons(["Return to boardroom"], func(_unused):
			factory_seen = true
			strategy_board.visible = true
			objects["Strategy"] = boardroom_root.to_local(strategy_board.get_node("Approach").global_position)
			title_label.text = "3 produced / 0 accepted | Strategy board unlocked"
			factory_root.visible = false
			boardroom_root.visible = true
			_say(["DAVE: Three bikes produced. Three rejected. We have been busy, but achieved absolutely nothing.", "MARTIN: So what do we do differently?", "DAVE: We need a strategy. Take a look at the new flip chart."])
		)

func _physics_process(delta: float) -> void:
	if phase != "explore":
		_update_interaction_hint()
		_pose_dave(emote,delta)
		return
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): move.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): move.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): move.z -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): move.z += 1
	if move.length() > 0:
		auto_walk = false
	elif auto_walk:
		move = target - dave.position
		move.y = 0
		if move.length() < 0.12:
			auto_walk = false
			move = Vector3.ZERO
	if move.length() > 0:
		var previous := dave.position
		dave.velocity = move.normalized() * walk_speed
		dave.move_and_slide()
		dave.position.x = clampf(dave.position.x, -4.55, 4.55)
		dave.position.z = clampf(dave.position.z, -2.9, 3.1)
		dave_art.rotation.y = lerp_angle(dave_art.rotation.y,atan2(move.x,move.z),minf(delta*12,1.0))
		if dave.position.distance_to(previous) > 0.002:
			idle_clock = 0.0
			_pose_dave("walk",delta)
		else:
			_pose_dave("neutral",delta)
		if auto_walk and dave.get_slide_collision_count() > 0:
			auto_walk = false
	else:
		dave.velocity = Vector3.ZERO
		idle_clock += delta
		_pose_dave("neutral",delta)
	_update_interaction_hint()

func _setup_interaction_hint() -> void:
	prompt = Label3D.new()
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 36
	prompt.pixel_size = 0.006
	prompt.outline_size = 10
	prompt.modulate = Color("#ffe29a")
	prompt.no_depth_test = true
	boardroom_root.add_child(prompt)
	highlight = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.36
	ring.outer_radius = 0.43
	highlight.mesh = ring
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color("#ffff21")
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight.material_override = highlight_material
	boardroom_root.add_child(highlight)
	_update_interaction_hint()

func _update_interaction_hint() -> void:
	nearby = ""
	var best := INF
	if phase == "explore":
		for key in objects:
			var dist: float = dave.position.distance_to(objects[key])
			if dist < best and dist < float(interaction_settings.get(key, {}).get("distance", 1.85)):
				best = dist
				nearby = key
	if is_instance_valid(highlighted_mesh):
		highlighted_mesh.material_overlay = null
		highlighted_mesh = null
	prompt.visible = nearby != ""
	highlight.visible = nearby != ""
	if nearby == "":
		return
	var labels := {"Dashboard":"View sales targets", "Research":"Examine research", "Order":"Review order", "Martin":"Talk to Martin", "Coffee":"Inspect coffee machine"}
	prompt.text = "[E] " + str(interaction_settings.get(nearby, {}).get("prompt", labels.get(nearby, nearby)))
	var at: Vector3 = objects[nearby]
	prompt.position = at + Vector3(0,2.25,0)
	highlight.position = at + Vector3(0,0.09,0)
	if interact_meshes.has(nearby):
		highlighted_mesh = interact_meshes[nearby]
		var glow := StandardMaterial3D.new()
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.albedo_color = interaction_settings.get(nearby, {}).get("color", Color(1.0,0.78,0.25,0.22))
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		highlighted_mesh.material_overlay = glow

func _inspect_object(name: String) -> void:
	auto_walk = false
	dave.velocity = Vector3.ZERO
	if name == "Strategy":
		_say(["DAVE: We know what we need to achieve: 1,200 bikes for Halvefords. What we have not agreed is how.", "DAVE: The triangle shows our current balance of cost, quality and speed. The scale shows how much decision-making sits with management or the team.", "DAVE: You cannot move these markers directly. Your conversations, decisions and actions influence them.", "DAVE: Watch how our strategy evolves and what happens to our results."])
		return
	if name == "Martin":
		_interact(name)
		return
	phase = "inspect"
	emote = "neutral"
	panel.visible = true
	var details := {
		"Dashboard": "SALES TARGETS   |   Halvefords\n1,200 bicycles  •  Delivery: Christmas\nProduct strategy: Not defined",
		"Research": "CUSTOMER RESEARCH\n12 children surveyed. Preferred gear count: 27.",
		"Order": "HALVEFORDS ORDER\n1,200 bicycles. Christmas deadline.",
		"Coffee": "DAVE: At least the coffee machine knows what it's here for."
	}
	message.text = str(interaction_settings.get(name, {}).get("text", details.get(name, "")))
	if name == "Dashboard" and factory_seen:
		var results := {"Speed":"Delivered quickly. Brakes omitted.", "Comfort":"Unrequested suspension. Costs and delays increase.", "Cost":"Basic brakes. Premium braking subscription."}
		message.text += "\nOutcome: " + results.get(choice, "")
	_buttons([], func(_unused): pass)

func _dismiss_panel() -> void:
	if phase == "factory":
		factory_root.visible = false
		boardroom_root.visible = true
	_close_inspection()

func _close_inspection() -> void:
	phase = "explore"
	panel.visible = false
	auto_walk = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and panel.visible:
			_dismiss_panel()
			return
		if phase == "explore" and (event.keycode == KEY_E or event.keycode == KEY_ENTER):
			if nearby != "":
				_inspect_object(nearby)
		elif phase == "dialogue" and event.keycode == KEY_SPACE:
			_advance()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and phase == "explore":
		var origin := camera.project_ray_origin(event.position)
		var direction := camera.project_ray_normal(event.position)
		if absf(direction.y) < 0.0001:
			return
		var distance := -origin.y / direction.y
		if distance <= 0:
			return
		var point := origin + direction * distance
		if nearby != "":
			var at: Vector3 = objects[nearby]
			var screen_at := camera.unproject_position(at + Vector3(0,1.0,0))
			if point.distance_to(at) < 0.85 or event.position.distance_to(screen_at) < 55:
				_inspect_object(nearby)
				return
		target = point
		auto_walk = true

# One-off scene conversion. Run BakeEnvironments.tscn from the editor.
func _own_descendants(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_own_descendants(child, scene_root)

func _save_room(room: Node3D, path: String) -> void:
	_own_descendants(room, room)
	var packed := PackedScene.new()
	var result := packed.pack(room)
	if result == OK:
		result = ResourceSaver.save(packed, path)
	if result != OK:
		push_error("Could not save " + path + ": " + str(result))
	else:
		print("Saved editable scene: " + path)

func _bake_rooms() -> void:
	var spawn := Marker3D.new()
	spawn.name = "DaveSpawn"
	spawn.position = dave.position
	boardroom_root.add_child(spawn)
	boardroom_root.remove_child(dave)
	dave.queue_free()
	var markers := Node3D.new()
	markers.name = "InteractionPoints"
	boardroom_root.add_child(markers)
	for key in objects:
		var marker := Marker3D.new()
		marker.name = key
		marker.position = objects[key]
		markers.add_child(marker)
		if interact_meshes.has(key):
			var mesh: MeshInstance3D = interact_meshes[key]
			mesh.name = key + "Highlight"
	_save_room(boardroom_root, "res://scenes/BoardroomEditable.tscn")
	_save_room(factory_root, "res://scenes/FactoryEditable.tscn")

func _load_rooms() -> void:
	boardroom_root = (load("res://scenes/BoardroomEditable.tscn") as PackedScene).instantiate() as Node3D
	factory_root = (load("res://scenes/FactoryEditable.tscn") as PackedScene).instantiate() as Node3D
	add_child(boardroom_root)
	add_child(factory_root)
	martin = boardroom_root.get_node("Martin") as Node3D
	for marker in boardroom_root.find_children("*", "Marker3D", true, false):
		var key := String(marker.name)
		var custom: bool = marker.get_script() == preload("res://scenes/interaction_point.gd")
		if custom:
			key = marker.interaction_id
			if key.is_empty():
				continue
			interaction_settings[key] = {"distance": marker.activation_distance, "color": marker.highlight_color}
			if not marker.prompt_text.is_empty():
				interaction_settings[key]["prompt"] = marker.prompt_text
			if not marker.inspection_text.is_empty():
				interaction_settings[key]["text"] = marker.inspection_text
		elif not objects.has(key):
			continue
		objects[key] = boardroom_root.to_local(marker.global_position)
		var mesh: MeshInstance3D
		if custom and not marker.highlight_mesh.is_empty():
			mesh = marker.get_node_or_null(marker.highlight_mesh) as MeshInstance3D
		else:
			mesh = boardroom_root.find_child(key + "Highlight", true, false) as MeshInstance3D
		if mesh != null:
			interact_meshes[key] = mesh
	_spawn_dave((boardroom_root.get_node("DaveSpawn") as Marker3D).position)

# The editable room owns placement; the game owns unlock and strategic state.
func _make_strategy_board() -> void:
	strategy_board = boardroom_root.get_node_or_null("StrategyBoard") as Node3D
	if strategy_board == null:
		strategy_board = preload("res://scenes/StrategyBoard.tscn").instantiate() as Node3D
		boardroom_root.add_child(strategy_board)
		strategy_board.position = Vector3(4.1,0,-0.8)
	interact_meshes["Strategy"] = strategy_board.get_node("BoardSurface/Paper")
	interaction_settings["Strategy"] = {"prompt":"View strategy board","distance":1.4,"color":Color(0.65,0.35,1.0,0.25)}
	_update_strategy_markers()
	strategy_board.visible = false

func _update_strategy_markers() -> void:
	strategy_board.call("set_orientation", strategy, autonomy)

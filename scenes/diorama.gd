extends Node3D

# Procedural 3D vertical slice: fixed orthographic camera, walkable boardroom,
# decision lock and a factory reveal. Meshes are temporary until authored assets arrive.
const WALK_SPEED := 3.0
var dave: Node3D
var martin: Node3D
var camera: Camera3D
var target := Vector3.ZERO
var auto_walk := false
var phase := "intro"
var choice := ""
var factory_seen := false
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
    _make_boardroom()
    _make_factory()
    factory_root.visible = false
    _make_ui()
    _say(["DAVE: Halvefords want 1,200 bicycles by Christmas.", "DAVE (to camera): Apparently we have a strategy. Nobody's seen it."], "explore")

func _setup_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#d4c3ae")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#fff2df")
    env.ambient_light_energy = 0.75
    environment.environment = env
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -34, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 14.5
    camera.position = Vector3(11, 13, 15)
    camera.look_at(Vector3(0, 0, 0))
    camera.current = true
    add_child(camera)

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
    _block(boardroom_root, Vector3(0, -0.24, 0), Vector3(10.5, 0.45, 7.5), palette["floor"])
    _block(boardroom_root, Vector3(0, 1.8, -3.72), Vector3(10.5, 3.6, 0.22), palette["wall"])
    _block(boardroom_root, Vector3(-5.23, 1.8, 0), Vector3(0.22, 3.6, 7.5), palette["wall"])
    _block(boardroom_root, Vector3(0, 3.64, -3.72), Vector3(10.7, 0.2, 0.35), palette["wood_dark"])
    _block(boardroom_root, Vector3(-5.23, 3.64, 0), Vector3(0.35, 0.2, 7.6), palette["wood_dark"])
    # Window frames and glass-like panes on the back wall.
    for x in [-3.8, -2.6]:
        _block(boardroom_root, Vector3(x, 2.15, -3.57), Vector3(1.02, 1.5, 0.06), Color("#b7d3d0"))
        _block(boardroom_root, Vector3(x, 2.15, -3.51), Vector3(0.07, 1.6, 0.09), palette["wood_dark"])
        _block(boardroom_root, Vector3(x, 2.15, -3.49), Vector3(1.1, 0.07, 0.09), palette["wood_dark"])
    # Table: top and four legs.
    _block(boardroom_root, Vector3(0, 0.85, 0.3), Vector3(4.4, 0.18, 1.75), palette["wood"])
    for x in [-1.85, 1.85]:
        for z in [-0.35, 0.95]:
            _block(boardroom_root, Vector3(x, 0.42, z), Vector3(0.13, 0.8, 0.13), palette["wood_dark"])
    for x in [-1.5, 0.0, 1.5]:
        for z in [-1.25, 1.85]:
            _chair(Vector3(x, 0, z), z > 0)
    # Bookcase, television, console and small props.
    _block(boardroom_root, Vector3(4.35, 1.3, -3.25), Vector3(1.3, 2.6, 0.7), palette["wood"])
    for y in [0.55, 1.25, 1.95]:
        _block(boardroom_root, Vector3(4.35, y, -2.86), Vector3(1.15, 0.08, 0.65), palette["wood_dark"])
    _block(boardroom_root, Vector3(1.4, 2.1, -3.54), Vector3(2.45, 1.45, 0.12), Color("#1e2833"))
    _block(boardroom_root, Vector3(1.4, 2.1, -3.46), Vector3(2.24, 1.25, 0.03), Color("#3c6071"))
    _block(boardroom_root, Vector3(-3.7, 0.5, 2.6), Vector3(0.9, 1.0, 0.8), palette["wood_dark"])
    _block(boardroom_root, Vector3(-3.7, 1.08, 2.6), Vector3(0.5, 0.25, 0.5), Color("#b4b3ac"))
    _block(boardroom_root, Vector3(-0.8, 0.99, 0.15), Vector3(0.62, 0.03, 0.42), palette["paper"])
    _block(boardroom_root, Vector3(0.7, 1.01, 0.1), Vector3(0.55, 0.04, 0.38), Color("#d2b88e"))
    dave = _character(boardroom_root, Vector3(-3.3, 0, 1.35), palette["purple"])
    martin = _character(boardroom_root, Vector3(2.7, 0, 0.8), Color("#3d7564"))

func _chair(at: Vector3, facing_front: bool) -> void:
    _block(boardroom_root, at + Vector3(0, 0.45, 0), Vector3(0.65, 0.13, 0.58), palette["chair"])
    var back_z := 0.28 if facing_front else -0.28
    _block(boardroom_root, at + Vector3(0, 0.95, back_z), Vector3(0.65, 1.05, 0.13), palette["chair"])
    _block(boardroom_root, at + Vector3(0, 0.2, 0), Vector3(0.1, 0.4, 0.1), palette["metal"])

func _character(parent: Node3D, at: Vector3, clothing: Color) -> Node3D:
    var root := Node3D.new()
    root.position = at
    parent.add_child(root)
    _block(root, Vector3(0, 0.95, 0), Vector3(0.46, 0.8, 0.28), clothing)
    _sphere(root, Vector3(0, 1.6, 0), 0.27, Color("#e6b38e"))
    _block(root, Vector3(-0.13, 0.3, 0), Vector3(0.15, 0.58, 0.2), Color("#313947"))
    _block(root, Vector3(0.13, 0.3, 0), Vector3(0.15, 0.58, 0.2), Color("#313947"))
    _block(root, Vector3(-0.33, 1.05, 0), Vector3(0.14, 0.62, 0.19), clothing)
    _block(root, Vector3(0.33, 1.05, 0), Vector3(0.14, 0.62, 0.19), clothing)
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
    title_label.text = "AGILE ADVENTURES 4  |  WASD / Arrows: move  |  E: interact  |  Tap: move or inspect"
    title_label.position = Vector2(18, 15)
    title_label.add_theme_color_override("font_color", Color("#252a31"))
    layer.add_child(title_label)
    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 35
    panel.offset_right = -35
    panel.offset_top = -165
    panel.offset_bottom = -20
    layer.add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    message = Label.new()
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.custom_minimum_size.y = 68
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
    else:
        phase = "explore"
        panel.visible = false

func _interact(name: String) -> void:
    if name == "Martin":
        if choice != "":
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
    dialogue_lines = consequences[choice]
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
            factory_root.visible = false
            boardroom_root.visible = true
            phase = "explore"
            panel.visible = false
        )

func _process(delta: float) -> void:
    if phase != "explore":
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
        var next := dave.position + move.normalized() * WALK_SPEED * delta
        next.x = clampf(next.x, -4.55, 4.55)
        next.z = clampf(next.z, -2.9, 3.1)
        if not (absf(next.x) < 2.65 and next.z > -1.25 and next.z < 1.55):
            dave.position = next

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if phase == "explore" and (event.keycode == KEY_E or event.keycode == KEY_ENTER):
            var nearest := ""
            var best := 1.75
            for key in objects:
                var dist: float = dave.position.distance_to(objects[key])
                if dist < best:
                    best = dist
                    nearest = key
            if nearest != "":
                _interact(nearest)
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
        var nearest := ""
        for key in objects:
            if point.distance_to(objects[key]) < 0.85:
                nearest = key
                break
        if nearest != "":
            _interact(nearest)
        else:
            target = point
            auto_walk = true

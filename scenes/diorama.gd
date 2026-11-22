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
    _block(boardroom_root,Vector3(2.55,2.05,-3.44),Vector3(2.04,1.19,0.025),Color("#304957"))
    for i in range(5):
        _block(boardroom_root,Vector3(1.85+i*0.32,1.65+i*0.07,-3.41),Vector3(0.18,0.24+i*0.14,0.025),Color("#8bb5ae"))
    _block(boardroom_root,Vector3(-3.7,0.5,2.6),Vector3(0.9,1.0,0.8),palette["wood_dark"])
    _obstacle(Vector3(-3.7,0.5,2.6),Vector3(0.9,1.0,0.8))
    _block(boardroom_root,Vector3(-3.7,1.23,2.6),Vector3(0.55,0.46,0.48),Color("#333940"))
    _block(boardroom_root,Vector3(-3.7,1.19,2.88),Vector3(0.32,0.19,0.09),Color("#92999b"))
    for x in [-1.25,1.15]:
        _block(boardroom_root,Vector3(x,0.97,0.1),Vector3(0.65,0.045,0.46),Color("#aeb5ba"))
        var screen = _block(boardroom_root,Vector3(x,1.21,-0.11),Vector3(0.65,0.45,0.045),Color("#b6bec3"))
        screen.rotation_degrees.x = -12
    _block(boardroom_root,Vector3(0,0.96,0.5),Vector3(0.45,0.025,0.32),palette["paper"])
    var clock = _sphere(boardroom_root,Vector3(-2.45,2.65,-3.53),0.25,Color("#51443a"))
    clock.scale.z = 0.14
    for i in range(12):
        var angle = i*TAU/12.0
        _block(boardroom_root,Vector3(-2.45+sin(angle)*0.19,2.65+cos(angle)*0.19,-3.48),Vector3(0.025,0.025,0.025),Color.WHITE)
    _block(boardroom_root,Vector3(-2.45,2.72,-3.46),Vector3(0.025,0.15,0.025),Color.WHITE)
    _block(boardroom_root,Vector3(-2.38,2.65,-3.46),Vector3(0.14,0.025,0.025),Color.WHITE)
    dave = CharacterBody3D.new()
    boardroom_root.add_child(dave)
    dave.position = Vector3(-3.3,0.06,1.35)
    dave.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
    var body_shape = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.28
    capsule.height = 1.65
    body_shape.shape = capsule
    body_shape.position.y = 0.85
    dave.add_child(body_shape)
    dave_art = _make_dave(dave)
    martin = _character(boardroom_root,Vector3(3.35,0.06,0.8),Color("#3d7564"))
    objects["Martin"] = martin.position
    objects["Dashboard"] = Vector3(2.55,0,-2.15)
    _obstacle(martin.position+Vector3(0,0.85,0),Vector3(0.65,1.7,0.65))

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

func _make_dave(parent: Node3D) -> Node3D:
    var ink := Color("#30282a")
    var skin := Color("#eeb17c")
    var hair_color := Color("#563124")
    var root := _joint(parent,"DaveArt",Vector3.ZERO)
    var upper := _joint(root,"Upper",Vector3.ZERO)
    # Rounded, continuous purple tunic, not a flat outlined rectangle.
    var shirt := _oval(upper,Vector3(0,0.91,0),Vector3(0.54,0.64,0.37),Color("#80368e"))
    var neck := _oval(upper,Vector3(0,1.2,0),Vector3(0.19,0.15,0.19),skin)
    var head := _joint(upper,"Head",Vector3(0,1.55,0))
    _oval(head,Vector3.ZERO,Vector3(0.77,0.75,0.70),skin)
    # Hair is a sculpted crown/back cap, with exposed skin on either side.
    _oval(head,Vector3(0,0.11,-0.13),Vector3(0.77,0.62,0.54),hair_color)
    for k in range(9):
        var angle := float(k)*TAU/9.0
        var lock := _oval(head,Vector3(sin(angle)*0.26,0.29+0.035*sin(angle*3),cos(angle)*0.22-0.04),Vector3(0.21,0.26,0.20),hair_color)
        lock.rotation.z = -sin(angle)*0.65
        lock.rotation.x = cos(angle)*0.55
    _oval(head,Vector3(-0.10,0.39,-0.015),Vector3(0.19,0.23,0.19),hair_color).rotation.z = 0.35
    _oval(head,Vector3(0.075,0.38,-0.075),Vector3(0.22,0.25,0.21),hair_color).rotation.z = -0.42
    for side in [-1,1]:
        _oval(head,Vector3(side*0.36,-0.025,-0.015),Vector3(0.105,0.15,0.105),skin)
        var eye := _oval(head,Vector3(side*0.12,0.015,0.331),Vector3(0.082,0.125,0.045),ink)
        var brow := _joint(head,"BrowL" if side == -1 else "BrowR",Vector3(side*0.13,0.15,0.31))
        _soft_limb(brow,Vector3(-0.045,-0.008,-0.005),Vector3(0.0,0.012,0.012),0.018,hair_color)
        _soft_limb(brow,Vector3(0.0,0.012,0.012),Vector3(0.045,-0.008,-0.005),0.018,hair_color)
    for mood in ["neutral","happy","sad","open"]:
        var mouth := _joint(head,"Mouth_"+mood,Vector3(0,-0.13,0.325))
        if mood == "open":
            _oval(mouth,Vector3.ZERO,Vector3(0.23,0.12,0.043),ink)
            _oval(mouth,Vector3(0,-0.035,0.019),Vector3(0.10,0.036,0.021),Color("#d77e79"))
        else:
            var depth := -0.04 if mood == "sad" else 0.05
            for k in range(8):
                var t := -1.0+k*0.25
                var u := t+0.25
                _ink(mouth,Vector3(t*0.105,depth*t*t-depth,-0.025*t*t),Vector3(u*0.105,depth*u*u-depth,-0.025*u*u),0.012,ink)
        mouth.visible = mood == "neutral"
    for side in [-1,1]:
        var leg := _joint(root,"LegL" if side == -1 else "LegR",Vector3(side*0.135,0.66,0))
        _soft_limb(leg,Vector3.ZERO,Vector3(0,-0.29,0),0.073,ink)
        var knee := _joint(leg,"Knee",Vector3(0,-0.29,0))
        _soft_limb(knee,Vector3.ZERO,Vector3(0,-0.25,0),0.063,ink)
        _oval(knee,Vector3(0,-0.29,0.065),Vector3(0.18,0.14,0.30),ink)
        var arm := _joint(upper,"ArmL" if side == -1 else "ArmR",Vector3(side*0.23,1.13,0))
        _soft_limb(arm,Vector3.ZERO,Vector3(side*0.075,-0.22,0),0.067,ink)
        var elbow := _joint(arm,"Elbow",Vector3(side*0.075,-0.22,0))
        _soft_limb(elbow,Vector3.ZERO,Vector3(0,-0.20,0),0.058,ink)
        _oval(elbow,Vector3(0,-0.245,0),Vector3(0.15,0.17,0.13),skin)
        _oval(elbow,Vector3(-side*0.065,-0.22,0.025),Vector3(0.075,0.10,0.08),skin)
    root.rotation.y = 0.78
    return root

func _pose_dave(state: String, dt: float) -> void:
    if not is_instance_valid(dave_art):
        return
    var upper := dave_art.get_node("Upper") as Node3D
    var head := upper.get_node("Head") as Node3D
    var left := upper.get_node("ArmL") as Node3D
    var right := upper.get_node("ArmR") as Node3D
    var ll := dave_art.get_node("LegL") as Node3D
    var rl := dave_art.get_node("LegR") as Node3D
    var re := right.get_node("Elbow") as Node3D
    var le := left.get_node("Elbow") as Node3D
    var swing := 0.0
    var mouth := "neutral"
    var l := Vector3(0,0,-0.12)
    var r := Vector3(0,0,0.12)
    var elbow := Vector3.ZERO
    var tilt := 0.0
    var brows := 0.0
    if state == "walk":
        walk_clock += dt*10.0
        swing = sin(walk_clock)*0.53
    elif state == "welcome":
        mouth = "open"
        r.z = 2.1+sin(idle_clock*8)*0.22
        elbow.z = 0.35
    elif state == "thinking":
        mouth = "sad"
        r.x = -0.85
        r.z = -0.16
        elbow.x = -1.45
        tilt = 0.12
        brows = 0.23
    elif state == "idea" or state == "thumbs":
        mouth = "open"
        r.z = 1.9
        elbow.z = 0.45
    elif state == "confused":
        mouth = "sad"
        r.z = 2.2
        elbow.z = -0.85
        tilt = -0.15
        brows = 0.28
    elif state == "sad":
        mouth = "sad"
        tilt = 0.08
        brows = 0.35
    elif state == "frustrated":
        mouth = "sad"
        brows = -0.45
        r.x = -0.55
        l.x = -0.55
        r.z = -0.45
        l.z = 0.45
        elbow.x = -0.8
    l.x += swing
    r.x -= swing
    var blend := minf(dt*13.0,1.0)
    left.rotation = left.rotation.lerp(l,blend)
    right.rotation = right.rotation.lerp(r,blend)
    re.rotation = re.rotation.lerp(elbow,blend)
    le.rotation = le.rotation.lerp(Vector3(-0.8,0,0) if state == "frustrated" else Vector3.ZERO,blend)
    ll.rotation.x = lerpf(ll.rotation.x,-swing,blend)
    rl.rotation.x = lerpf(rl.rotation.x,swing,blend)
    var lk := ll.get_node("Knee") as Node3D
    var rk := rl.get_node("Knee") as Node3D
    lk.rotation.x = lerpf(lk.rotation.x,maxf(0.0,swing)*0.85,blend)
    rk.rotation.x = lerpf(rk.rotation.x,maxf(0.0,-swing)*0.85,blend)
    if state == "walk":
        re.rotation.x = lerpf(re.rotation.x,-0.18-maxf(swing,0.0)*0.22,blend)
        le.rotation.x = lerpf(le.rotation.x,-0.18-maxf(-swing,0.0)*0.22,blend)
    upper.position.y = lerpf(upper.position.y,absf(swing)*0.055,blend)
    head.rotation.z = lerpf(head.rotation.z,tilt,blend)
    (head.get_node("BrowL") as Node3D).rotation.z = lerpf((head.get_node("BrowL") as Node3D).rotation.z,brows,blend)
    (head.get_node("BrowR") as Node3D).rotation.z = lerpf((head.get_node("BrowR") as Node3D).rotation.z,-brows,blend)
    for mood in ["neutral","happy","sad","open"]:
        (head.get_node("Mouth_"+mood) as Node3D).visible = mood == mouth

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
    title_label.text = "AGILE ADVENTURES 4  |  WASD / Arrows: move  |  E: interact  |  Tap: move or inspect"
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
    panel.offset_left = 35
    panel.offset_right = -35
    panel.offset_top = -165
    panel.offset_bottom = -20
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
            factory_root.visible = false
            boardroom_root.visible = true
            phase = "explore"
            panel.visible = false
        )

func _physics_process(delta: float) -> void:
    if phase != "explore":
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
        dave.velocity = move.normalized() * WALK_SPEED
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
        var cycle := fmod(idle_clock,12.0)
        var state := "neutral"
        if cycle > 3.0 and cycle < 5.5: state = "welcome"
        elif cycle > 7.0 and cycle < 10.0: state = "thinking"
        if state != "neutral":
            dave_art.rotation.y = lerp_angle(dave_art.rotation.y,0.78,minf(delta*5,1.0))
        _pose_dave(state,delta)

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

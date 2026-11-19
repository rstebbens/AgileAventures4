extends Node2D

const SPEED = 210.0
var dave = Vector2(250, 475)
var target = Vector2.ZERO
var walking = false
var mode = "intro"
var lines = ["DAVE: Halvefords need 1,200 bicycles by Christmas.", "DAVE (to camera): Apparently we have a strategy. Nobody's seen it."]
var line_index = 0
var outcome = ""
var factory_seen = false
var factory_stage = 0
var ui: CanvasLayer
var panel: PanelContainer
var dialogue: Label
var choices: HBoxContainer
var status: Label
var locations = {"Martin": Vector2(755, 370), "Research": Vector2(360, 235), "Order": Vector2(570, 235), "Dashboard": Vector2(900, 245), "Coffee": Vector2(185, 330)}

func _ready():
    _build_ui()
    _show_line()

func _process(delta):
    if mode == "explore":
        var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        if Input.is_key_pressed(KEY_A): direction.x -= 1
        if Input.is_key_pressed(KEY_D): direction.x += 1
        if Input.is_key_pressed(KEY_W): direction.y -= 1
        if Input.is_key_pressed(KEY_S): direction.y += 1
        direction = direction.normalized()
        if direction.length() > 0: walking = false
        elif walking:
            if dave.distance_to(target) > 5: direction = dave.direction_to(target)
            else: walking = false
        var next = dave + direction * SPEED * delta
        next.x = clampf(next.x, 140, 960)
        next.y = clampf(next.y, 295, 565)
        if not Rect2(405, 330, 295, 150).has_point(next): dave = next
    queue_redraw()

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if mode == "explore" and (event.keycode == KEY_E or event.keycode == KEY_ENTER):
            var nearest = ""
            var distance = 95.0
            for name in locations:
                var d = dave.distance_to(locations[name])
                if d < distance:
                    nearest = name
                    distance = d
            if nearest != "": _interact(nearest)
        elif mode == "dialogue" and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER): _advance()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mode == "explore":
        var p = get_global_mouse_position()
        for name in locations:
            if p.distance_to(locations[name]) < 55:
                _interact(name)
                return
        target = p
        walking = true

func _build_ui():
    ui = CanvasLayer.new()
    add_child(ui)
    status = Label.new()
    status.position = Vector2(25, 16)
    status.add_theme_font_size_override("font_size", 19)
    status.text = "AGILE ADVENTURES 4   |   Arrow keys / WASD: move   |   E: interact   |   Tap: move or inspect"
    ui.add_child(status)
    panel = PanelContainer.new()
    panel.position = Vector2(130, 570)
    panel.custom_minimum_size = Vector2(840, 112)
    ui.add_child(panel)
    var content = VBoxContainer.new()
    panel.add_child(content)
    dialogue = Label.new()
    dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue.custom_minimum_size = Vector2(790, 52)
    dialogue.add_theme_font_size_override("font_size", 20)
    content.add_child(dialogue)
    choices = HBoxContainer.new()
    content.add_child(choices)

func _say(new_lines):
    lines = new_lines
    line_index = 0
    mode = "dialogue"
    _show_line()

func _show_line():
    for child in choices.get_children(): child.queue_free()
    dialogue.text = lines[line_index]
    var button = Button.new()
    button.text = "Continue  [Space]"
    button.pressed.connect(_advance)
    choices.add_child(button)

func _advance():
    line_index += 1
    if line_index < lines.size():
        _show_line()
    else:
        mode = "explore"
        panel.visible = false

func _interact(name):
    panel.visible = true
    if name == "Martin" and outcome != "":
        _say(["MARTIN: We already committed to " + outcome.to_lower() + ". The factory is implementing it.", "DAVE (to camera): Apparently a decision becomes a strategy if you say it confidently enough."])
    elif name == "Martin":
        _say(["MARTIN: Halvefords want 1,200 bicycles by Christmas. We need to move quickly.", "DAVE: Why 27 gears and not 18?", "MARTIN: A survey of twelve-year-olds suggests more gears are better.", "DAVE: What's the target demographic?", "MARTIN: Middle-aged divorcees. Essentially the same thing.", "DAVE (to camera): You're hearing this too, right?"])
        # Present the decision after the dialogue sequence.
        mode = "martin"
        _martin_dialogue(0)
    elif name == "Research":
        _say(["RESEARCH: Twelve children surveyed. Preferred gear count: 27.", "DAVE (to camera): That's a sample size, not a strategy."])
    elif name == "Order":
        _say(["ORDER: Halvefords. 1,200 bicycles. Delivery by Christmas.", "DAVE: A deadline is not a product vision."])
    elif name == "Coffee":
        _say(["DAVE: At least the coffee machine has a clear purpose."])
    elif name == "Dashboard":
        if outcome != "" and not factory_seen:
            _say(["DAVE: First we need to see what is actually happening on the factory floor."])
        elif outcome == "":
            _say(["DASHBOARD: No strategy selected. No meaningful performance data available."])
        else:
            var result = {"Speed":"Delivery on time. Brakes missing. Customer complaints: catastrophic.", "Comfort":"Premium suspension added. Nobody asked for it. Costs soar.", "Cost":"Basic brakes included. Better brakes available by subscription."}
            _say(["DASHBOARD: " + result[outcome], "DAVE (to camera): And that's what happens when we mistake a constraint for a strategy."])

func _martin_dialogue(index):
    var conversation = ["MARTIN: Halvefords want 1,200 bicycles by Christmas.", "DAVE: Why 27 gears and not 18?", "MARTIN: Twelve-year-olds prefer more gears.", "DAVE: What's the target demographic?", "MARTIN: Middle-aged divorcees. Essentially the same thing.", "DAVE (to camera): You're hearing this too, right?", "MARTIN: So, what's our priority?"]
    for child in choices.get_children(): child.queue_free()
    dialogue.text = conversation[index]
    if index < conversation.size() - 1:
        var next = Button.new()
        next.text = "Continue"
        next.pressed.connect(func(): _martin_dialogue(index + 1))
        choices.add_child(next)
    else:
        for option in ["Speed", "Comfort", "Cost"]:
            var b = Button.new()
            b.text = option
            b.pressed.connect(func(): _decide(option))
            choices.add_child(b)

func _decide(option):
    if outcome != "": return
    outcome = option
    var quips = {"Speed":"No brakes. Bold strategy. Shall we tell the customers?", "Comfort":"Suspension? Lovely. Was that in the requirements? Of course not.", "Cost":"Brakes as a subscription. What could possibly go wrong?"}
    _say(["MARTIN: Great. I\'ll tell the factory to prioritize " + option.to_lower() + ".", "DAVE (to camera): " + quips[option], "DAVE: Perhaps we should visit the assembly line before declaring victory."])
    mode = "factory_intro"
    _factory_sequence(0)

func _factory_sequence(index):
    mode = "factory"
    factory_stage = index
    panel.visible = true
    for child in choices.get_children(): child.queue_free()
    var scenes = {
        "Speed": ["FACTORY: The production counter races upward. Workers skip the brake installation station.", "WORKER: We can ship by Friday. Brakes are in the next release.", "DAVE (to camera): A bicycle with no brakes. What could possibly slow us down?"],
        "Comfort": ["FACTORY: Every bicycle receives oversized premium suspension.", "WORKER: Assembly time doubled. Nobody ordered the suspension, but it is very comfortable.", "DAVE (to camera): We're solving a problem nobody has, at twice the cost."],
        "Cost": ["FACTORY: Basic brakes are installed. A premium braking subscription is advertised.", "WORKER: The brakes work. Enhanced stopping power is a monthly upgrade.", "DAVE (to camera): We've invented brakes-as-a-service. I wish I were joking."]
    }
    var beats = scenes[outcome]
    dialogue.text = beats[index]
    if index < beats.size() - 1:
        var b = Button.new()
        b.text = "Next factory scene"
        b.pressed.connect(func(): _factory_sequence(index + 1))
        choices.add_child(b)
    else:
        var b = Button.new()
        b.text = "Return to boardroom"
        b.pressed.connect(func():
            factory_seen = true
            mode = "explore"
            panel.visible = false
        )
        choices.add_child(b)

func _draw():
    if mode == "factory":
        _draw_factory()
        return
    draw_rect(Rect2(0, 0, 1100, 700), Color("#17212e"))
    draw_rect(Rect2(110, 110, 880, 460), Color("#607e8a"))
    draw_colored_polygon(PackedVector2Array([Vector2(110, 275),Vector2(990, 275),Vector2(990, 570),Vector2(110, 570)]), Color("#b5b4a4"))
    draw_rect(Rect2(405, 330, 295, 150), Color("#604638"))
    draw_rect(Rect2(422, 343, 260, 120), Color("#98735a"))
    for i in range(5):
        var x = 440 + i * 50
        draw_rect(Rect2(x, 312, 30, 24), Color("#34445a"))
        draw_rect(Rect2(x, 480, 30, 23), Color("#34445a"))
    _object(Vector2(360, 235), "RESEARCH", Color("#e3d9ae"))
    _object(Vector2(570, 235), "ORDER", Color("#e5c18e"))
    _object(Vector2(900, 245), "DASHBOARD", Color("#a8d5de") if outcome == "" else Color("#f2b56e"))
    _object(Vector2(185, 330), "COFFEE", Color("#c9a8c9"))
    _person(Vector2(755, 370), Color("#3b8665"), "MARTIN")
    _person(dave, Color("#8954b5"), "DAVE")
    if mode == "explore":
        for name in locations:
            if dave.distance_to(locations[name]) < 95:
                draw_arc(locations[name], 38, 0, TAU, 40, Color.YELLOW, 3)

func _object(p, label, color):
    draw_rect(Rect2(p.x - 47, p.y - 30, 94, 58), color)
    draw_rect(Rect2(p.x - 47, p.y - 30, 94, 58), Color("#26323d"), false, 3)
    draw_string(ThemeDB.fallback_font, p + Vector2(-43, 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#17212e"))

func _person(p, color, label):
    draw_ellipse_placeholder(p)
    draw_circle(p + Vector2(0, -31), 14, Color("#e9b78f"))
    draw_rect(Rect2(p.x - 16, p.y - 16, 32, 35), color)
    draw_string(ThemeDB.fallback_font, p + Vector2(-25, -57), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func draw_ellipse_placeholder(p):
    draw_circle(p + Vector2(0, 17), 21, Color(0, 0, 0, 0.24))

func _draw_factory():
    draw_rect(Rect2(0, 0, 1100, 700), Color("#202e3c"))
    draw_rect(Rect2(65, 120, 970, 400), Color("#526270"))
    draw_rect(Rect2(90, 360, 920, 110), Color("#303d46"))
    for i in range(5):
        var x = 155 + i * 180
        draw_circle(Vector2(x - 42, 396), 32, Color("#1b2530"))
        draw_circle(Vector2(x + 42, 396), 32, Color("#1b2530"))
        draw_line(Vector2(x - 42, 396), Vector2(x, 343), Color("#d3a65c"), 7)
        draw_line(Vector2(x, 343), Vector2(x + 42, 396), Color("#d3a65c"), 7)
        draw_line(Vector2(x - 42, 396), Vector2(x + 42, 396), Color("#d3a65c"), 7)
        if outcome == "Comfort":
            draw_line(Vector2(x, 343), Vector2(x + 25, 312), Color("#df84e8"), 8)
        elif outcome == "Cost":
            draw_string(ThemeDB.fallback_font, Vector2(x - 45, 450), "SUBSCRIBE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff0a5"))
        else:
            draw_string(ThemeDB.fallback_font, Vector2(x - 42, 450), "NO BRAKES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffaaaa"))
    draw_string(ThemeDB.fallback_font, Vector2(110, 180), "HALVEFORDS ASSEMBLY LINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(110, 225), "Priority: " + outcome + "   |   Scene " + str(factory_stage + 1) + " / 3", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#d8e5ed"))

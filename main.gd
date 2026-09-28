extends Control

const BG := Color("#060713")
const PANEL := Color("#0B0E1C")
const PANEL_2 := Color("#10142A")
const CYAN := Color("#58E7FF")
const BLUE := Color("#6E7CFF")
const PURPLE := Color("#B86CFF")
const PINK := Color("#FF5EC4")
const GREEN := Color("#72F7C2")
const TEXT_MAIN := Color("#F5F7FF")
const TEXT_MUTED := Color("#8992B4")
const GRID := Color(0.25, 0.42, 0.75, 0.08)
const FIGHTER_PREVIEW := preload("res://fighter_preview.tscn")

var pulse := 0.0
var screen_name := "home"
var selected_hunter := 0
var selected_arena := 0
var status_label: Label

func _ready() -> void:
	set_process(true)
	_show_screen("home")
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BG)

	# Atmosphere
	_draw_glow(Vector2(size.x * 0.16, size.y * 0.18), 250.0, Color(CYAN, 0.07))
	_draw_glow(Vector2(size.x * 0.83, size.y * 0.28), 310.0, Color(PURPLE, 0.08))
	_draw_glow(Vector2(size.x * 0.55, size.y * 0.84), 380.0, Color(PINK, 0.045))

	# Perspective grid
	var horizon := size.y * 0.72
	for i in range(9):
		var t := float(i) / 8.0
		var y := horizon + pow(t, 1.7) * size.y * 0.34
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
	for i in range(-12, 13):
		var top_x := size.x * 0.5 + i * 10.0
		var bottom_x := size.x * 0.5 + i * size.x * 0.062
		draw_line(Vector2(top_x, horizon), Vector2(bottom_x, size.y), Color(0.25, 0.42, 0.75, 0.055), 1.0)

	# Frame
	var f := Rect2(28, 28, size.x - 56, size.y - 56)
	draw_line(f.position, f.position + Vector2(185, 0), Color(CYAN, 0.72), 2.0)
	draw_line(Vector2(f.end.x - 185, f.position.y), f.end, Color(PURPLE, 0.72), 2.0)
	draw_line(Vector2(f.position.x, f.end.y), Vector2(f.position.x + 185, f.end.y), Color(CYAN, 0.22), 2.0)
	draw_line(Vector2(f.end.x - 185, f.end.y), f.end, Color(PURPLE, 0.22), 2.0)

func _show_screen(next: String) -> void:
	screen_name = next
	for child in get_children():
		if child != status_label:
			child.queue_free()
	await get_tree().process_frame
	_build_header()
	match screen_name:
		"home":
			_build_home()
		"characters":
			_build_character_select()
		"arenas":
			_build_arena_select()
		"setup":
			_build_setup()
		"settings":
			_build_settings()
	_update_status("")
	queue_redraw()

func _build_header() -> void:
	var brand := Label.new()
	brand.text = "✦  HUNTER'S RISE"
	brand.position = Vector2(58, 48)
	brand.add_theme_font_size_override("font_size", 21)
	brand.add_theme_color_override("font_color", TEXT_MAIN)
	add_child(brand)

	var step := Label.new()
	step.text = _step_label()
	step.position = Vector2(58, 84)
	step.add_theme_font_size_override("font_size", 11)
	step.add_theme_color_override("font_color", CYAN)
	add_child(step)

	var version := Label.new()
	version.text = "PROTOTYPE  •  0.4"
	version.position = Vector2(get_viewport_rect().size.x - 245, 58)
	version.size = Vector2(185, 26)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", TEXT_MUTED)
	add_child(version)

func _step_label() -> String:
	match screen_name:
		"home": return "MAIN MENU"
		"characters": return "01  /  CHOOSE YOUR HUNTER"
		"arenas": return "02  /  CHOOSE YOUR ARENA"
		"setup": return "03  /  BATTLE SETUP"
		"settings": return "SYSTEM / SETTINGS"
	return ""

func _build_home() -> void:
	var title := _label("HUNTER'S\nRISE", Vector2(72, 155), Vector2(560, 170), 82, TEXT_MAIN)
	add_child(title)

	var sub := _label("THE BATTLE BEGINS", Vector2(76, 330), Vector2(400, 30), 16, CYAN)
	add_child(sub)

	var desc := _label("A stylish arena fighter built from the ground up.\nThis prototype is focused on the experience first.", Vector2(76, 370), Vector2(430, 58), 16, TEXT_MUTED)
	add_child(desc)

	var play := _button("PLAY", Vector2(76, 468), Vector2(280, 64), CYAN)
	play.pressed.connect(func(): _show_screen("characters"))
	add_child(play)

	var chars := _button("CHARACTERS", Vector2(76, 545), Vector2(280, 52), PURPLE)
	chars.pressed.connect(func(): _show_screen("characters"))
	add_child(chars)

	var settings := _button("SETTINGS", Vector2(76, 610), Vector2(280, 46), Color("#3F476F"))
	settings.pressed.connect(func(): _show_screen("settings"))
	add_child(settings)

	var panel := _card(Vector2(700, 164), Vector2(438, 350), PANEL)
	add_child(panel)
	add_child(_label("PROTOTYPE ROADMAP", Vector2(734, 192), Vector2(300, 30), 14, TEXT_MUTED))
	add_child(_label("Build the fight in layers.", Vector2(734, 226), Vector2(360, 42), 28, TEXT_MAIN))
	var roadmap := _label("01   HOME\n\n02   CHARACTER SELECT\n\n03   ARENA SELECT\n\n04   BATTLE SETUP\n\n05   COMBAT", Vector2(736, 292), Vector2(360, 190), 16, TEXT_MUTED)
	add_child(roadmap)
	add_child(_label("COMBAT CONTENT WILL COME AFTER THE FLOW IS READY.", Vector2(736, 468), Vector2(350, 28), 11, CYAN))

func _build_character_select() -> void:
	add_child(_label("CHOOSE YOUR HUNTER", Vector2(72, 140), Vector2(600, 54), 38, TEXT_MAIN))
	add_child(_label("3D previews are live. Final Meshy characters come next.", Vector2(74, 194), Vector2(700, 30), 15, TEXT_MUTED))

	var left := _character_card(72, "HUNTER SLOT 01", "PHANTOM", CYAN, 0)
	var right := _character_card(664, "HUNTER SLOT 02", "VANGUARD", PINK, 1)
	add_child(left)
	add_child(right)

	var back := _button("BACK", Vector2(72, 635), Vector2(150, 46), Color("#3F476F"))
	back.pressed.connect(func(): _show_screen("home"))
	add_child(back)

	var next := _button("CONTINUE  →", Vector2(906, 625), Vector2(232, 56), CYAN)
	next.pressed.connect(func(): _show_screen("arenas"))
	add_child(next)

func _character_card(x: float, name_top: String, name: String, accent: Color, index: int) -> Control:
	var root := Control.new()
	root.position = Vector2(x, 252)
	root.size = Vector2(520, 335)

	var bg := _card(Vector2.ZERO, root.size, PANEL)
	root.add_child(bg)

	var accent_bar := ColorRect.new()
	accent_bar.position = Vector2(0, 0)
	accent_bar.size = Vector2(6, root.size.y)
	accent_bar.color = accent
	root.add_child(accent_bar)

	var top := _label(name_top, Vector2(28, 22), Vector2(300, 24), 12, TEXT_MUTED)
	root.add_child(top)
	root.add_child(_label(name, Vector2(28, 52), Vector2(250, 40), 30, TEXT_MAIN))

	# Reusable 3D preview viewport. The procedural fighter will be replaced by the final Meshy asset later.
	var portrait := Panel.new()
	portrait.position = Vector2(30, 112)
	portrait.size = Vector2(190, 178)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(accent.r, accent.g, accent.b, 0.06)
	ps.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	ps.set_border_width_all(1)
	portrait.add_theme_stylebox_override("panel", ps)
	_add_3d_preview(portrait, accent)

	var lock := _label("ASSET PENDING", Vector2(48, 182), Vector2(155, 30), 12, accent)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_child(lock)

	var preview_label := _label("3D PREVIEW", Vector2(58, 153), Vector2(135, 20), 10, TEXT_MUTED)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_child(preview_label)

	root.add_child(portrait)

	root.add_child(_label("ROLE", Vector2(255, 116), Vector2(100, 22), 11, TEXT_MUTED))
	root.add_child(_label("PROTOTYPE", Vector2(255, 140), Vector2(180, 30), 16, TEXT_MAIN))
	root.add_child(_label("This slot will receive the\nfinal Meshy model later.", Vector2(255, 184), Vector2(220, 58), 14, TEXT_MUTED))

	var stats := _label("POWER     —\nSPEED     —\nSKILL     —", Vector2(255, 260), Vector2(180, 75), 13, TEXT_MUTED)
	root.add_child(stats)

	var choose := _button("SELECT", Vector2(382, 266), Vector2(108, 42), accent)
	choose.pressed.connect(func(): _select_hunter(index, root, accent))
	root.add_child(choose)

	if selected_hunter == index:
		var selected := _label("SELECTED", Vector2(28, 300), Vector2(120, 20), 11, accent)
		root.add_child(selected)

	return root

func _select_hunter(index: int, root: Control, accent: Color) -> void:
	selected_hunter = index
	_update_status("Hunter slot %02d selected." % (index + 1))
	_show_screen("characters")

func _build_arena_select() -> void:
	add_child(_label("CHOOSE YOUR ARENA", Vector2(72, 140), Vector2(620, 54), 38, TEXT_MAIN))
	add_child(_label("One arena slot is enough for the first prototype.", Vector2(74, 194), Vector2(700, 30), 15, TEXT_MUTED))

	var card := _card(Vector2(72, 250), Vector2(1066, 330), PANEL)
	add_child(card)

	# Arena preview frame
	var preview := Panel.new()
	preview.position = Vector2(100, 280)
	preview.size = Vector2(520, 270)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#090B18")
	ps.border_color = Color(CYAN, 0.5)
	ps.set_border_width_all(1)
	preview.add_theme_stylebox_override("panel", ps)
	add_child(preview)

	# Stylized neon skyline
	for i in range(8):
		var h := 65.0 + float((i * 37) % 120)
		var building := ColorRect.new()
		building.position = Vector2(118 + i * 60, 510 - h)
		building.size = Vector2(42, h)
		building.color = Color(0.06, 0.08, 0.16, 1.0)
		add_child(building)
		var neon := ColorRect.new()
		neon.position = Vector2(124 + i * 60, 520 - h)
		neon.size = Vector2(3, max(h - 25, 10))
		neon.color = Color(CYAN if i % 2 == 0 else PURPLE, 0.6)
		add_child(neon)

	add_child(_label("NEON DISTRICT", Vector2(665, 292), Vector2(360, 45), 31, TEXT_MAIN))
	add_child(_label("ARENA SLOT 01", Vector2(666, 344), Vector2(200, 24), 12, CYAN))
	add_child(_label("A compact cyber-futuristic\nfighting space.\n\nFINAL 3D ENVIRONMENT: NEXT BUILD", Vector2(666, 382), Vector2(350, 120), 16, TEXT_MUTED))

	var select := _button("SELECT ARENA", Vector2(666, 520), Vector2(220, 46), CYAN)
	select.pressed.connect(func(): selected_arena = 0; _show_screen("setup"))
	add_child(select)

	var back := _button("← BACK", Vector2(72, 635), Vector2(150, 46), Color("#3F476F"))
	back.pressed.connect(func(): _show_screen("characters"))
	add_child(back)

func _build_setup() -> void:
	add_child(_label("BATTLE SETUP", Vector2(72, 140), Vector2(600, 54), 38, TEXT_MAIN))
	add_child(_label("Everything is wired before the final assets arrive.", Vector2(74, 194), Vector2(700, 30), 15, TEXT_MUTED))

	var p1_index := selected_hunter
	var p2_index := 1 if selected_hunter == 0 else 0
	var p1_name := "PHANTOM" if p1_index == 0 else "VANGUARD"
	var p2_name := "PHANTOM" if p2_index == 0 else "VANGUARD"
	var p1_accent := CYAN if p1_index == 0 else PINK
	var p2_accent := CYAN if p2_index == 0 else PINK

	var p1 := _setup_card(Vector2(72, 265), "PLAYER 01", p1_name, p1_accent)
	var vs := _label("VS", Vector2(564, 335), Vector2(72, 52), 34, TEXT_MAIN)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(p1)
	add_child(vs)
	add_child(_setup_card(Vector2(664, 265), "PLAYER 02", p2_name, p2_accent))

	var arena := _card(Vector2(72, 505), Vector2(1066, 104), PANEL)
	add_child(arena)
	add_child(_label("ARENA", Vector2(98, 528), Vector2(100, 22), 11, TEXT_MUTED))
	add_child(_label("NEON DISTRICT", Vector2(98, 554), Vector2(260, 32), 20, TEXT_MAIN))
	add_child(_label("READY FOR 3D ASSET", Vector2(790, 552), Vector2(300, 24), 12, CYAN))

	var back := _button("← BACK", Vector2(72, 640), Vector2(150, 46), Color("#3F476F"))
	back.pressed.connect(func(): _show_screen("arenas"))
	add_child(back)

	var fight := _button("ENTER FIGHT  →", Vector2(878, 632), Vector2(260, 56), PURPLE)
	fight.pressed.connect(_enter_fight)
	add_child(fight)

func _add_3d_preview(parent: Control, accent: Color) -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(1, 1)
	container.size = parent.size - Vector2(2, 2)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(container.size.x), int(container.size.y))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var environment := WorldEnvironment.new()
	var world_environment := Environment.new()
	world_environment.background_mode = Environment.BG_COLOR
	world_environment.background_color = Color("#070914")
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color(accent.r, accent.g, accent.b, 1.0)
	world_environment.ambient_light_energy = 0.65
	environment.environment = world_environment
	viewport.add_child(environment)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.1, 3.4)
	camera.current = true
	camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	viewport.add_child(camera)

	var fighter_preview := FIGHTER_PREVIEW.instantiate()
	fighter_preview.accent = accent
	viewport.add_child(fighter_preview)

	container.add_child(viewport)
	parent.add_child(container)

func _setup_card(pos: Vector2, slot: String, fighter: String, accent: Color) -> Control:
	var c := _card(pos, Vector2(428, 190), PANEL)
	c.add_child(_label(slot, Vector2(24, 20), Vector2(160, 22), 11, TEXT_MUTED))
	c.add_child(_label(fighter, Vector2(24, 50), Vector2(280, 38), 25, TEXT_MAIN))
	c.add_child(_label("3D MODEL PENDING", Vector2(24, 94), Vector2(250, 24), 12, accent))
	c.add_child(_label("Animation rig • moves • combat data", Vector2(24, 130), Vector2(350, 26), 13, TEXT_MUTED))
	return c

func _enter_fight() -> void:
	get_tree().set_meta("p1_hunter", selected_hunter)
	get_tree().set_meta("selected_arena", selected_arena)
	get_tree().change_scene_to_file("res://combat.tscn")

func _build_settings() -> void:
	add_child(_label("SETTINGS", Vector2(72, 140), Vector2(400, 54), 38, TEXT_MAIN))
	add_child(_label("Prototype controls. Audio and graphics options will come later.", Vector2(74, 194), Vector2(700, 30), 15, TEXT_MUTED))

	var card := _card(Vector2(72, 252), Vector2(1066, 280), PANEL)
	add_child(card)
	add_child(_setting_row(card, 30, "DISPLAY", "1280 × 720 prototype viewport"))
	add_child(_setting_row(card, 92, "INPUT", "Keyboard / controller support planned"))
	add_child(_setting_row(card, 154, "AUDIO", "Not connected yet"))
	add_child(_setting_row(card, 216, "GRAPHICS", "Godot compatibility renderer"))

	var back := _button("← BACK TO HOME", Vector2(72, 590), Vector2(220, 52), CYAN)
	back.pressed.connect(func(): _show_screen("home"))
	add_child(back)

func _setting_row(parent: Control, y: float, key: String, value: String) -> Control:
	var row := Control.new()
	row.position = Vector2(28, y)
	row.size = Vector2(1000, 42)
	row.add_child(_label(key, Vector2.ZERO, Vector2(160, 24), 11, TEXT_MUTED))
	row.add_child(_label(value, Vector2(180, -2), Vector2(700, 30), 15, TEXT_MAIN))
	return row

func _card(pos: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.3, 0.4, 0.7, 0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text_value: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text_value: String, pos: Vector2, size: Vector2, accent: Color) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", TEXT_MAIN)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r, accent.g, accent.b, 0.1)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.48)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	var hover := normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	var pressed := hover.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.34)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	for i in range(10, 0, -1):
		var r := radius * (float(i) / 10.0)
		var c := Color(color.r, color.g, color.b, color.a * (1.0 - float(i - 1) / 10.0))
		draw_circle(center, r, c)

func _update_status(message: String) -> void:
	if status_label == null or not is_instance_valid(status_label):
		status_label = Label.new()
		status_label.position = Vector2(get_viewport_rect().size.x - 450, get_viewport_rect().size.y - 48)
		status_label.size = Vector2(380, 28)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", CYAN)
		add_child(status_label)
	status_label.text = message

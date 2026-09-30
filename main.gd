extends Node

const FighterScript = preload("res://fighter.gd")
const BattleScene = preload("res://battle.tscn")

var selected_fighter := 0
var selected_style := 0
var root_ui: Control

const BG := Color("#050712")
const PANEL := Color("#0A0F1D")
const CYAN := Color("#58E7FF")
const PINK := Color("#FF5EC4")
const PURPLE := Color("#B86CFF")
const WHITE := Color("#F5F7FF")
const MUTED := Color("#8992B4")

func _ready() -> void:
	_show_home()

func _clear() -> void:
	for child in get_children():
		child.free()
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ui)

func _show_settings() -> void:
	_clear()
	_add_background_texture("res://art/home.svg", 0.92)
	_header("SYSTEM / SETTINGS")
	root_ui.add_child(_label("SETTINGS", Vector2(72, 132), Vector2(400, 50), 38, WHITE))
	var card := _card(Vector2(72, 220), Vector2(1066, 330))
	root_ui.add_child(card)
	root_ui.add_child(_label("DISPLAY", Vector2(105, 260), Vector2(160, 24), 11, CYAN))
	root_ui.add_child(_label("1280 × 720 • GL Compatibility • Mobile ready", Vector2(270, 256), Vector2(650, 30), 16, WHITE))
	root_ui.add_child(_label("GAMEPLAY", Vector2(105, 325), Vector2(160, 24), 11, PINK))
	root_ui.add_child(_label("60 second rounds • CPU opponent • 3 attack classes", Vector2(270, 321), Vector2(650, 30), 16, WHITE))
	root_ui.add_child(_label("CONTROLS", Vector2(105, 390), Vector2(160, 24), 11, PURPLE))
	root_ui.add_child(_label("Touch: analog + LIGHT / HEAVY / SPECIAL / BLOCK", Vector2(270, 386), Vector2(650, 30), 16, WHITE))
	var back := _button("← HOME", Vector2(72, 590), Vector2(180, 50), CYAN)
	back.pressed.connect(_show_home)
	root_ui.add_child(back)

func _show_how_to_play() -> void:
	_clear()
	_add_background_texture("res://art/arena.svg", 0.86)
	_header("SYSTEM / HOW TO PLAY")
	root_ui.add_child(_label("HOW TO PLAY", Vector2(72, 132), Vector2(500, 50), 38, WHITE))
	var card := _card(Vector2(72, 220), Vector2(1066, 360))
	root_ui.add_child(card)
	root_ui.add_child(_label("MOVE", Vector2(105, 260), Vector2(160, 24), 11, CYAN))
	root_ui.add_child(_label("Use the analog stick to close distance, retreat and reposition.", Vector2(270, 256), Vector2(730, 30), 16, WHITE))
	root_ui.add_child(_label("ATTACK", Vector2(105, 325), Vector2(160, 24), 11, PINK))
	root_ui.add_child(_label("LIGHT is quick. HEAVY hits harder. SPECIAL is the cinematic hit.", Vector2(270, 321), Vector2(730, 30), 16, WHITE))
	root_ui.add_child(_label("DEFEND", Vector2(105, 390), Vector2(160, 24), 11, PURPLE))
	root_ui.add_child(_label("Hold BLOCK to reduce incoming damage.", Vector2(270, 386), Vector2(730, 30), 16, WHITE))
	root_ui.add_child(_label("WIN", Vector2(105, 455), Vector2(160, 24), 11, Color("#FFB84D")))
	root_ui.add_child(_label("Empty the opponent health bar before the timer reaches zero.", Vector2(270, 451), Vector2(730, 30), 16, WHITE))
	var back := _button("← HOME", Vector2(72, 610), Vector2(180, 50), CYAN)
	back.pressed.connect(_show_home)
	root_ui.add_child(back)
func _show_home() -> void:
	_clear()
	_add_background_texture("res://art/home.svg", 1.0)
	_header("HOME")
	root_ui.add_child(_label("NEXAUREN\nBATTLE ARENA", Vector2(72, 150), Vector2(580, 150), 72, WHITE))
	root_ui.add_child(_label("NEON DISTRICT", Vector2(76, 322), Vector2(300, 28), 16, CYAN))
	root_ui.add_child(_label("TWO FIGHTERS. ONE ARENA. INFINITE POSSIBILITIES.", Vector2(76, 360), Vector2(510, 65), 15, MUTED))

	var play := _button("▶  PLAY", Vector2(76, 420), Vector2(280, 56), CYAN)
	play.pressed.connect(_show_character_select)
	root_ui.add_child(play)
	var chars := _button("♙  CHARACTERS", Vector2(76, 484), Vector2(280, 46), PURPLE)
	chars.pressed.connect(_show_character_select)
	root_ui.add_child(chars)
	var settings := _button("⚙  SETTINGS", Vector2(76, 538), Vector2(280, 46), Color("#4D5B85"))
	settings.pressed.connect(_show_settings)
	root_ui.add_child(settings)
	var help := _button("▣  HOW TO PLAY", Vector2(76, 592), Vector2(280, 46), PINK)
	help.pressed.connect(_show_how_to_play)
	root_ui.add_child(help)
	var quit := _button("◉  QUIT", Vector2(76, 646), Vector2(280, 40), Color("#38405D"))
	quit.pressed.connect(func(): get_tree().quit())
	root_ui.add_child(quit)

	var card := _card(Vector2(650, 150), Vector2(500, 410))
	root_ui.add_child(card)
	root_ui.add_child(_label("BUILD CONTENT", Vector2(682, 184), Vector2(250, 22), 11, CYAN))
	root_ui.add_child(_label("REX  +  ZARA", Vector2(682, 222), Vector2(360, 44), 32, WHITE))
	root_ui.add_child(_label("NEON DISTRICT", Vector2(682, 288), Vector2(330, 36), 25, WHITE))
	root_ui.add_child(_label("Live 3D Rex + Zara\nNeon District combat platform\nIdle / walk / light combo / heavy / special\nBlock / perfect block / impact FX / KO\nTouch + keyboard controls", Vector2(682, 340), Vector2(420, 190), 16, MUTED))

func _show_character_select() -> void:
	_clear()
	_add_background_texture("res://art/select.svg", 1.0)
	_header("01 / CHARACTER SELECT")
	root_ui.add_child(_label("CHOOSE YOUR FIGHTER", Vector2(72, 132), Vector2(650, 50), 38, WHITE))
	root_ui.add_child(_label("The other fighter becomes the CPU opponent. The preview is the same live 3D fighter used in battle.", Vector2(74, 182), Vector2(880, 26), 15, MUTED))
	_character_card(72, "REX", "TECHNICAL STRIKER", CYAN, 0)
	_character_card(664, "ZARA", "PHASE ASSAULT", PINK, 1)

	var back := _button("BACK", Vector2(72, 636), Vector2(150, 44), Color("#3D4568"))
	back.pressed.connect(_show_home)
	root_ui.add_child(back)

	var next := _button("NEXT", Vector2(948, 628), Vector2(190, 54), CYAN)
	next.pressed.connect(_show_stage_select)
	root_ui.add_child(next)

func _character_card(x: float, title: String, role: String, accent: Color, index: int) -> void:
	var card := _card(Vector2(x, 235), Vector2(520, 350))
	root_ui.add_child(card)
	root_ui.add_child(_label("FIGHTER %02d" % (index + 1), Vector2(x + 28, 255), Vector2(160, 20), 11, MUTED))
	root_ui.add_child(_label(title, Vector2(x + 28, 284), Vector2(320, 42), 32, WHITE))
	root_ui.add_child(_label(role, Vector2(x + 30, 330), Vector2(300, 24), 12, accent))

	var preview := _make_preview(index, accent)
	preview.position = Vector2(x + 28, 372)
	root_ui.add_child(preview)

	var stats := _label("POWER   %s\nSPEED   %s\nSTYLE   %s" % ["A" if index == 1 else "B", "A+" if index == 0 else "B+", "TECH" if index == 0 else "PHASE"], Vector2(x + 270, 385), Vector2(200, 88), 14, MUTED)
	root_ui.add_child(stats)
	root_ui.add_child(_label("STYLE", Vector2(x + 270, 468), Vector2(90, 18), 10, accent))
	var style_names := ["VANGUARD", "RUSH", "BREAKER"] if index == 0 else ["PHANTOM", "BLADE", "PULSE"]
	for style_index in range(3):
		var style_button := _button(style_names[style_index], Vector2(x + 270 + style_index * 78, 490), Vector2(72, 30), accent if selected_style == style_index and selected_fighter == index else Color("#38405D"))
		style_button.add_theme_font_size_override("font_size", 10)
		style_button.pressed.connect(func(si := style_index, fi := index):
			selected_fighter = fi
			selected_style = si
			_show_character_select()
		)
		root_ui.add_child(style_button)

	var select := _button("SELECT", Vector2(x + 364, 532), Vector2(126, 38), accent)
	select.add_theme_font_size_override("font_size", 14)
	select.pressed.connect(func(): selected_fighter = index; _show_character_select())
	root_ui.add_child(select)

	if selected_fighter == index:
		root_ui.add_child(_label("SELECTED", Vector2(x + 28, 560), Vector2(100, 20), 11, accent))

func _make_preview(index: int, accent: Color) -> Control:
	var holder := SubViewportContainer.new()
	holder.size = Vector2(210, 170)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(210, 170)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#070914")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#A4B8D7")
	environment.ambient_light_energy = 0.85
	world.environment = environment
	viewport.add_child(world)

	var light := OmniLight3D.new()
	light.position = Vector3(-1.5, 3.0, 2.5)
	light.light_color = accent
	light.light_energy = 7.0
	light.omni_range = 7.0
	viewport.add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.25, 3.6)
	camera.current = true
	camera.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	viewport.add_child(camera)

	var fighter = FighterScript.new()
	fighter.setup("Rex" if index == 0 else "Zara", accent, Color("#6E7CFF") if index == 0 else Color("#FFB84D"))
	fighter.position.y = 0.02
	fighter.set_physics_process(false)
	viewport.add_child(fighter)

	holder.add_child(viewport)
	return holder

func _show_stage_select() -> void:
	_clear()
	_add_background_texture("res://art/arena.svg", 1.0)
	_header("02 / PLACE")
	root_ui.add_child(_label("SELECT YOUR PLACE", Vector2(72, 132), Vector2(620, 50), 38, WHITE))
	root_ui.add_child(_label("One focused stage: a city around a dedicated fighting platform.", Vector2(74, 182), Vector2(720, 26), 15, MUTED))

	var card := _card(Vector2(72, 235), Vector2(1066, 360))
	root_ui.add_child(card)
	root_ui.add_child(_label("NEON DISTRICT", Vector2(105, 270), Vector2(360, 42), 30, WHITE))
	root_ui.add_child(_label("CITY / NIGHT / CENTRAL COMBAT AREA", Vector2(107, 316), Vector2(390, 24), 11, CYAN))
	root_ui.add_child(_label("Buildings, streets, lights, billboards, plants and\na raised combat deck keep the whole city visible\nwithout making the fight area confusing.", Vector2(107, 365), Vector2(420, 90), 15, MUTED))

	var art := ColorRect.new()
	art.position = Vector2(585, 265)
	art.size = Vector2(500, 275)
	art.color = Color("#070A13")
	root_ui.add_child(art)
	for i in range(7):
		var b := ColorRect.new()
		b.position = Vector2(602 + i * 65, 420 - float((i * 41) % 125))
		b.size = Vector2(42, 150 + float((i * 41) % 125))
		b.color = Color("#121927")
		art.add_child(b)
		var w := ColorRect.new()
		w.position = Vector2(b.position.x + 8, b.position.y + 18)
		w.size = Vector2(4, b.size.y - 30)
		w.color = CYAN if i % 2 == 0 else PINK
		w.modulate.a = 0.65
		art.add_child(w)
	var floor := ColorRect.new()
	floor.position = Vector2(600, 500)
	floor.size = Vector2(470, 18)
	floor.color = Color("#222936")
	art.add_child(floor)
	var glow := ColorRect.new()
	glow.position = Vector2(625, 494)
	glow.size = Vector2(420, 4)
	glow.color = PURPLE
	art.add_child(glow)

	var back := _button("BACK", Vector2(72, 636), Vector2(150, 44), Color("#3D4568"))
	back.pressed.connect(_show_character_select)
	root_ui.add_child(back)

	var fight := _button("ENTER ARENA  →", Vector2(890, 628), Vector2(250, 54), PINK)
	fight.pressed.connect(_start_battle)
	root_ui.add_child(fight)

func _start_battle() -> void:
	_clear()
	var battle = BattleScene.instantiate()
	battle.selected_player = selected_fighter
	battle.selected_style = selected_style
	add_child(battle)


func _add_background_texture(path: String, opacity: float = 1.0) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var background := TextureRect.new()
	background.texture = texture
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(1, 1, 1, opacity)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(background)
	root_ui.move_child(background, 0)

func _header(step: String) -> void:
	root_ui.add_child(_label("✦  NEXAR BATTLE ARENA", Vector2(52, 40), Vector2(360, 30), 20, WHITE))
	root_ui.add_child(_label(step, Vector2(54, 72), Vector2(420, 22), 11, CYAN))
	root_ui.add_child(_label("GODOT 4.x / MOBILE READY", Vector2(960, 46), Vector2(230, 22), 11, MUTED))

func _card(pos: Vector2, size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(0.35, 0.45, 0.75, 0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, pos: Vector2, size: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.50)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	var hover = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.90)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

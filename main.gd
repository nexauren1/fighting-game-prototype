extends Node

const FighterScript = preload("res://fighter.gd")
const BattleScene = preload("res://battle.tscn")

var selected_fighter := 0
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

func _show_home() -> void:
	_clear()
	_header("HOME")
	root_ui.add_child(_label("HUNTER'S\nRISE", Vector2(72, 150), Vector2(580, 150), 82, WHITE))
	root_ui.add_child(_label("NEON DISTRICT", Vector2(76, 310), Vector2(300, 28), 16, CYAN))
	root_ui.add_child(_label("A small, complete fighting-game slice built for Godot 4.x.\nPick a fighter, enter the city, and fight.", Vector2(76, 350), Vector2(510, 65), 15, MUTED))

	var play := _button("PLAY", Vector2(76, 450), Vector2(280, 62), CYAN)
	play.pressed.connect(_show_character_select)
	root_ui.add_child(play)

	var card := _card(Vector2(650, 150), Vector2(500, 410))
	root_ui.add_child(card)
	root_ui.add_child(_label("BUILD CONTENT", Vector2(682, 184), Vector2(250, 22), 11, CYAN))
	root_ui.add_child(_label("REX  +  ZARA", Vector2(682, 222), Vector2(360, 44), 32, WHITE))
	root_ui.add_child(_label("NEON DISTRICT", Vector2(682, 288), Vector2(330, 36), 25, WHITE))
	root_ui.add_child(_label("City backdrop\nCentral combat platform\nTwo 3D characters\nIdle / walk / attack / hit / KO\nAnalog + four touch buttons", Vector2(682, 340), Vector2(380, 180), 16, MUTED))

func _show_character_select() -> void:
	_clear()
	_header("01 / CHARACTER SELECT")
	root_ui.add_child(_label("CHOOSE YOUR FIGHTER", Vector2(72, 132), Vector2(650, 50), 38, WHITE))
	root_ui.add_child(_label("The other fighter becomes the CPU opponent.", Vector2(74, 182), Vector2(600, 26), 15, MUTED))
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

	var stats := _label("POWER   %s\nSPEED   %s\nSTYLE   %s" % ["A" if index == 1 else "B", "A+" if index == 0 else "B+", "TECH" if index == 0 else "PHASE"], Vector2(x + 270, 385), Vector2(200, 100), 15, MUTED)
	root_ui.add_child(stats)

	var select := _button("SELECT", Vector2(x + 364, 532), Vector2(126, 38), accent)
	select.add_theme_font_size_override("font_size", 14)
	select.pressed.connect(func(): selected_fighter = index)
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
	viewport.add_child(fighter)

	holder.add_child(viewport)
	return holder

func _show_stage_select() -> void:
	_clear()
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
	add_child(battle)

func _header(step: String) -> void:
	root_ui.add_child(_label("✦  HUNTER'S RISE", Vector2(52, 40), Vector2(360, 30), 20, WHITE))
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

extends Node3D

const FIGHTER_SCENE := preload("res://combat_fighter.tscn")

const BG := Color("#050612")
const CYAN := Color("#58E7FF")
const PINK := Color("#FF5EC4")
const PURPLE := Color("#B86CFF")
const TEXT := Color("#F5F7FF")
const MUTED := Color("#8B94B7")

var player_one: CombatFighter
var player_two: CombatFighter
var camera: Camera3D
var arena_root: Node3D
var round_time := 60.0
var round_over := false
var announce_timer := 0.0
var announce_text := ""
var p1_health_bar: ColorRect
var p2_health_bar: ColorRect
var timer_label: Label
var p1_info: Label
var p2_info: Label
var announce_label: Label

var p1_style := 0
var p2_style := 1

func _ready() -> void:
	_build_environment()
	_build_fighters()
	_build_ui()
	_show_announce("READY", 1.0)

func _process(delta: float) -> void:
	if not round_over:
		_process_input()
		_process_fighters(delta)
		_resolve_attacks()
		round_time = max(0.0, round_time - delta)
		if round_time <= 0.0:
			_end_round_by_time()
	_update_camera(delta)
	_update_ui()
	announce_timer = max(0.0, announce_timer - delta)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.echo or not key_event.pressed:
		return

	match key_event.keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://main.tscn")
		KEY_ENTER, KEY_KP_ENTER, KEY_R:
			if round_over:
				_restart_round()

	# Player 1
	match key_event.keycode:
		KEY_F:
			player_one.start_attack(0)
		KEY_G:
			player_one.start_attack(1)
		KEY_H:
			player_one.start_attack(2)
		KEY_T:
			player_one.dash(player_one.facing)
		KEY_1:
			_set_player_style(player_one, 0, true)
		KEY_2:
			_set_player_style(player_one, 1, true)
		KEY_3:
			_set_player_style(player_one, 2, true)

	# Player 2
	match key_event.keycode:
		KEY_J:
			player_two.start_attack(0)
		KEY_K:
			player_two.start_attack(1)
		KEY_L:
			player_two.start_attack(2)
		KEY_O:
			player_two.dash(player_two.facing)
		KEY_7:
			_set_player_style(player_two, 0, false)
		KEY_8:
			_set_player_style(player_two, 1, false)
		KEY_9:
			_set_player_style(player_two, 2, false)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.62)
	env.ambient_light_energy = 1.2
	world.environment = env
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52, -25, 0)
	key_light.light_energy = 1.4
	key_light.shadow_enabled = false
	add_child(key_light)

	arena_root = Node3D.new()
	arena_root.name = "NeonDistrict"
	add_child(arena_root)

	_add_box(Vector3(0, -0.18, 0), Vector3(20, 0.36, 10), Color("#101429"), Vector3.ZERO)
	_add_box(Vector3(0, 0.02, 4.2), Vector3(20, 0.12, 0.10), CYAN, Vector3.ZERO)
	_add_box(Vector3(0, 0.02, -4.2), Vector3(20, 0.12, 0.10), PURPLE, Vector3.ZERO)

	for i in range(12):
		var x := -10.5 + float(i) * 1.9
		var h := 1.8 + float((i * 7) % 8) * 0.7
		var z := -2.8 if i % 2 == 0 else 2.8
		_add_box(Vector3(x, h * 0.5 - 0.15, z), Vector3(1.25, h, 0.9), Color("#090C19"), Vector3.ZERO)
		_add_box(Vector3(x, 0.15, z + (0.48 if z > 0 else -0.48)), Vector3(0.9, 0.06, 0.05), CYAN if i % 2 == 0 else PINK, Vector3.ZERO)

	for i in range(9):
		var x2 := -9.0 + float(i) * 2.25
		var h2 := 3.0 + float((i * 5) % 6) * 0.5
		_add_box(Vector3(x2, h2 * 0.5, -1.8), Vector3(1.3, h2, 0.5), Color("#0B0E1D"), Vector3.ZERO)

	camera = Camera3D.new()
	camera.fov = 48.0
	camera.position = Vector3(0, 4.8, 14.5)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)

func _add_box(pos: Vector3, size: Vector3, color: Color, rotation: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.rotation = rotation
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.4
	if color != Color("#101429") and color != Color("#090C19") and color != Color("#0B0E1D"):
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	part.material_override = mat
	arena_root.add_child(part)

func _build_fighters() -> void:
	var p1_name := "PHANTOM"
	var p2_name := "VANGUARD"
	if get_tree().has_meta("p1_hunter") and int(get_tree().get_meta("p1_hunter")) == 1:
		p1_name = "VANGUARD"
		p2_name = "PHANTOM"

	player_one = FIGHTER_SCENE.instantiate()
	player_one.setup(p1_name, CYAN, p1_style)
	player_one.position = Vector3(-3.2, 0, 0)
	player_one.facing = 1.0
	add_child(player_one)

	player_two = FIGHTER_SCENE.instantiate()
	player_two.setup(p2_name, PINK, p2_style)
	player_two.position = Vector3(3.2, 0, 0)
	player_two.facing = -1.0
	add_child(player_two)

func _process_input() -> void:
	if round_over:
		return

	player_one.is_blocking = Input.is_physical_key_pressed(KEY_R) and not player_one.is_attacking()
	player_two.is_blocking = Input.is_physical_key_pressed(KEY_I) and not player_two.is_attacking()

	var p1_dir := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		p1_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		p1_dir += 1.0
	_move_player(player_one, p1_dir)

	var p2_dir := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		p2_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		p2_dir += 1.0
	_move_player(player_two, p2_dir)

	if Input.is_physical_key_pressed(KEY_W):
		player_one.jump()
	if Input.is_physical_key_pressed(KEY_UP):
		player_two.jump()

func _move_player(fighter: CombatFighter, direction: float) -> void:
	if direction == 0.0 or fighter.ko or fighter.stun_timer > 0.0 or fighter.is_attacking():
		return
	fighter.position.x += direction * fighter.style_speed() * get_process_delta_time()
	fighter.position.x = clampf(fighter.position.x, -8.3, 8.3)
	fighter.facing = sign(direction)

func _process_fighters(delta: float) -> void:
	player_one.apply_gravity(delta)
	player_two.apply_gravity(delta)

	if not player_one.ko:
		player_one.facing = 1.0 if player_two.position.x >= player_one.position.x else -1.0
	if not player_two.ko:
		player_two.facing = 1.0 if player_one.position.x >= player_two.position.x else -1.0

func _resolve_attacks() -> void:
	_resolve_single_attack(player_one, player_two)
	_resolve_single_attack(player_two, player_one)

func _resolve_single_attack(attacker: CombatFighter, target: CombatFighter) -> void:
	if not attacker.attack_ready_for_hit():
		return

	attacker.mark_hit()
	var distance := absf(attacker.position.x - target.position.x)
	var direction_to_target := sign(target.position.x - attacker.position.x)
	var is_facing_target := direction_to_target == attacker.facing or distance < 0.3

	if distance <= attacker.attack_range() and is_facing_target:
		var knock := [0.16, 0.34, 0.58][attacker.attack_kind]
		target.receive_hit(attacker.attack_damage(), knock, attacker.position.x)
		_show_announce("%s  %.0f" % [attacker.special_name() if attacker.attack_kind == 2 else "HIT", attacker.attack_damage()], 0.25)

	if target.ko:
		_end_round(attacker.fighter_name + " WINS")

func _set_player_style(fighter: CombatFighter, index: int, announce: bool) -> void:
	fighter.set_style(index)
	if fighter == player_one:
		p1_style = index
	else:
		p2_style = index
	if announce:
		_show_announce("%s: %s" % [fighter.fighter_name, fighter.style_name()], 0.55)

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var midpoint := (player_one.position.x + player_two.position.x) * 0.5
	var separation := absf(player_one.position.x - player_two.position.x)
	var desired_z := clampf(13.0 + separation * 0.50, 12.5, 17.0)
	var desired := Vector3(midpoint * 0.22, 4.7, desired_z)
	camera.position = camera.position.lerp(desired, clampf(delta * 3.0, 0.0, 1.0))
	camera.look_at(Vector3(midpoint, 1.0, 0), Vector3.UP)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	layer.add_child(_ui_label("NEON DISTRICT // COMBAT TEST", Vector2(34, 26), Vector2(620, 30), 18, TEXT))
	layer.add_child(_ui_label("ESC  BACK TO SETUP", Vector2(34, 58), Vector2(300, 22), 11, MUTED))

	layer.add_child(_ui_label("PLAYER 01", Vector2(50, 102), Vector2(260, 22), 12, CYAN))
	p1_info = _ui_label("", Vector2(50, 126), Vector2(520, 25), 14, TEXT)
	layer.add_child(p1_info)

	layer.add_child(_ui_label("PLAYER 02", Vector2(970, 102), Vector2(260, 22), 12, PINK))
	p2_info = _ui_label("", Vector2(750, 126), Vector2(480, 25), 14, TEXT)
	p2_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(p2_info)

	p1_health_bar = _health_bar(layer, Vector2(50, 158), CYAN)
	p2_health_bar = _health_bar(layer, Vector2(850, 158), PINK)

	timer_label = _ui_label("60", Vector2(600, 118), Vector2(80, 60), 34, TEXT)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(timer_label)

	announce_label = _ui_label("", Vector2(300, 285), Vector2(680, 80), 34, TEXT)
	announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(announce_label)

	var controls_text := "P1  A/D move  W jump  F light  G heavy  H special  R block  T dash  1/2/3 style\n" + 		"P2  ←/→ move  ↑ jump  J light  K heavy  L special  I block  O dash  7/8/9 style"
	var controls := _ui_label(controls_text, Vector2(34, 638), Vector2(1210, 50), 11, MUTED)
	layer.add_child(controls)

	var rematch := _ui_label("ENTER / R = rematch after KO", Vector2(820, 598), Vector2(390, 24), 11, MUTED)
	rematch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(rematch)

func _health_bar(layer: CanvasLayer, pos: Vector2, accent: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = Vector2(360, 22)
	bg.color = Color(0.05, 0.06, 0.12, 0.95)
	layer.add_child(bg)

	var fill := ColorRect.new()
	fill.position = Vector2.ZERO
	fill.size = bg.size
	fill.color = accent
	bg.add_child(fill)
	bg.set_meta("fill", fill)
	return bg

func _update_ui() -> void:
	if p1_health_bar == null:
		return
	var p1_fill := p1_health_bar.get_meta("fill") as ColorRect
	var p2_fill := p2_health_bar.get_meta("fill") as ColorRect
	p1_fill.size.x = 360.0 * player_one.health / player_one.max_health
	p2_fill.position.x = 360.0 - 360.0 * player_two.health / player_two.max_health
	p2_fill.size.x = 360.0 * player_two.health / player_two.max_health

	timer_label.text = str(int(ceil(round_time)))
	p1_info.text = "%s  •  %s  •  %03d HP" % [player_one.fighter_name, player_one.style_name(), int(player_one.health)]
	p2_info.text = "%s  •  %s  •  %03d HP" % [player_two.fighter_name, player_two.style_name(), int(player_two.health)]
	announce_label.text = announce_text if announce_timer > 0.0 else ""

func _show_announce(message: String, duration: float) -> void:
	announce_text = message
	announce_timer = duration

func _end_round(winner: String) -> void:
	if round_over:
		return
	round_over = true
	_show_announce(winner + "\nENTER = REMATCH  •  ESC = SETUP", 999.0)

func _end_round_by_time() -> void:
	if round_over:
		return
	if is_equal_approx(player_one.health, player_two.health):
		_end_round("DRAW")
	elif player_one.health > player_two.health:
		_end_round(player_one.fighter_name + " WINS")
	else:
		_end_round(player_two.fighter_name + " WINS")

func _restart_round() -> void:
	get_tree().reload_current_scene()

func _ui_label(text_value: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

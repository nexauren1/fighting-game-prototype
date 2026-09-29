extends Node3D

const FighterScene = preload("res://fighter.tscn")
const ArenaScript = preload("res://arena.gd")
const JoystickScript = preload("res://virtual_joystick.gd")

var selected_player := 0
var player: CharacterBody3D
var cpu: CharacterBody3D
var arena
var camera: Camera3D

var player_attack_cooldown := 0.0
var cpu_attack_cooldown := 0.0
var cpu_decision_time := 0.0
var round_time := 60.0
var round_over := false

var joystick
var block_held := false
var mobile_root: Control

var player_bar: ColorRect
var cpu_bar: ColorRect
var timer_label: Label
var announce: Label
var player_name_label: Label
var cpu_name_label: Label
var combo_label: Label
var player_portrait: TextureRect
var cpu_portrait: TextureRect
var camera_shake := 0.0
var combo_hits := 0
var combo_time := 0.0
var combo_owner := ""
var player_meter: ColorRect
var cpu_meter: ColorRect
var combo_stat_label: Label

const CYAN := Color("#58E7FF")
const PINK := Color("#FF5EC4")
const PURPLE := Color("#B86CFF")
const WHITE := Color("#F5F7FF")
const MUTED := Color("#9AA5C4")

func _ready() -> void:
	_setup_world()
	_spawn_fighters()
	_setup_hud()
	_setup_touch_controls()
	announce.text = "READY"
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(announce):
		announce.text = "FIGHT!"

func _physics_process(delta: float) -> void:
	if round_over:
		return

	round_time = maxf(0.0, round_time - delta)
	player_attack_cooldown = maxf(0.0, player_attack_cooldown - delta)
	cpu_attack_cooldown = maxf(0.0, cpu_attack_cooldown - delta)
	cpu_decision_time = maxf(0.0, cpu_decision_time - delta)

	_update_player(delta)
	_update_cpu(delta)
	_update_fighters(delta)
	_update_camera(delta)
	combo_time = maxf(0.0, combo_time - delta)
	if combo_time <= 0.0:
		combo_hits = 0
	_update_hud()

	if round_time <= 0.0:
		_finish_round()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	if key.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://main.tscn")
		return

	if round_over and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		get_tree().reload_current_scene()
		return

	if key.keycode == KEY_F or key.keycode == KEY_X:
		_player_attack(0)
	elif key.keycode == KEY_G:
		_player_attack(1)
	elif key.keycode == KEY_H:
		_player_attack(2)
	elif key.keycode == KEY_R:
		block_held = true
	elif key.keycode == KEY_T:
		_player_dash()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed and key.keycode == KEY_R:
			block_held = false

func _setup_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#02040A")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#A9BED9")
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color("#112540")
	environment.fog_density = 0.008
	environment.glow_enabled = true
	environment.glow_intensity = 0.80
	environment.glow_bloom = 0.16
	environment_node.environment = environment
	add_child(environment_node)

	arena = ArenaScript.new()
	add_child(arena)
	arena.build()

	camera = Camera3D.new()
	camera.fov = 48.0
	camera.position = Vector3(0, 5.0, 13.5)
	camera.current = true
	add_child(camera)


func _add_city_backdrop() -> void:
	var texture := load("res://art/arena.svg") as Texture2D
	if texture == null:
		return
	var backdrop := MeshInstance3D.new()
	backdrop.name = "CityBackdrop"
	var quad := QuadMesh.new()
	quad.size = Vector2(28.0, 15.5)
	backdrop.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.metallic = 0.0
	backdrop.material_override = material
	backdrop.position = Vector3(0, 6.0, -12.0)
	add_child(backdrop)

func _spawn_fighters() -> void:
	var player_is_rex := selected_player == 0
	var player_name := "Rex" if player_is_rex else "Zara"
	var cpu_name := "Zara" if player_is_rex else "Rex"
	var player_accent := CYAN if player_is_rex else PINK
	var cpu_accent := PINK if player_is_rex else CYAN
	var player_secondary := Color("#6E7CFF") if player_is_rex else Color("#FFB84D")
	var cpu_secondary := Color("#FFB84D") if player_is_rex else Color("#6E7CFF")

	player = FighterScene.instantiate() as CharacterBody3D
	player.setup(player_name, player_accent, player_secondary)
	player.position = Vector3(-3.2, 0.30, 0.0)
	add_child(player)

	cpu = FighterScene.instantiate() as CharacterBody3D
	cpu.setup(cpu_name, cpu_accent, cpu_secondary)
	cpu.position = Vector3(3.2, 0.30, 0.0)
	add_child(cpu)

	player.rotation.y = PI * 0.5
	cpu.rotation.y = -PI * 0.5

func _update_player(delta: float) -> void:
	if not is_instance_valid(player) or player.knocked_out:
		return

	var input_vector := Vector2.ZERO
	if joystick != null:
		input_vector = joystick.get_vector()

	if absf(input_vector.x) < 0.05 and absf(input_vector.y) < 0.05:
		if Input.is_key_pressed(KEY_A):
			input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W):
			input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			input_vector.y += 1.0

	player.set_block(block_held or Input.is_key_pressed(KEY_R))
	player.set_move(input_vector, 5.2)

	if player.position.y < 0.30:
		player.position.y = 0.30

	player.position.x = clampf(player.position.x, -8.3, 8.3)
	player.position.z = clampf(player.position.z, -3.1, 3.1)

func _update_cpu(_delta: float) -> void:
	if not is_instance_valid(cpu) or cpu.knocked_out:
		return

	var to_player := player.position - cpu.position
	to_player.y = 0.0
	var distance := to_player.length()
	var direction := Vector2(to_player.x, to_player.z).normalized()

	if distance > 2.2:
		cpu.set_block(false)
		cpu.set_move(direction, 3.7)
	elif cpu_decision_time <= 0.0 and cpu_attack_cooldown <= 0.0:
		cpu_decision_time = 0.35
		cpu_attack_cooldown = 0.75
		var attack_kind := 0
		if distance < 1.6:
			attack_kind = 1
		if distance < 1.3 and fmod(Time.get_ticks_msec() * 0.001, 3.0) > 1.9:
			attack_kind = 2
		cpu.start_attack(attack_kind)
	else:
		cpu.set_block(false)

	cpu.position.x = clampf(cpu.position.x, -8.3, 8.3)
	cpu.position.z = clampf(cpu.position.z, -3.1, 3.1)

	_face_each_other()

func _update_fighters(delta: float) -> void:
	_check_attack(player, cpu)
	_check_attack(cpu, player)
	player_attack_cooldown = maxf(0.0, player_attack_cooldown - delta)

	if player.knocked_out or cpu.knocked_out:
		if player.knocked_out and cpu.knocked_out:
			_end_message("DRAW")
		elif player.knocked_out:
			_end_message("%s WINS" % cpu.fighter_name)
		else:
			_end_message("%s WINS" % player.fighter_name)
		return

	if player.health <= 0.0 or cpu.health <= 0.0:
		return

	_face_each_other()

func _check_attack(attacker: CharacterBody3D, target: CharacterBody3D) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if not attacker.is_attacking() or not attacker.attack_hit_ready():
		return

	attacker.consume_attack_hit()
	var distance := attacker.global_position.distance_to(target.global_position)
	if distance > attacker.get_attack_range():
		return

	var push := (target.global_position - attacker.global_position).normalized()
	push.y = 0.0
	target.take_hit(attacker.get_attack_damage(), push)
	combo_hits += 1
	combo_time = 0.9
	camera_shake = 0.20 if attacker.attack_kind >= 1 else 0.12
	_spawn_hit_effect(target.global_position + Vector3.UP * 1.05, attacker.accent, attacker.attack_kind >= 2)
	announce.text = "SPECIAL HIT!" if attacker.attack_kind >= 2 else ("HEAVY!" if attacker.attack_kind == 1 else "HIT!")
	announce.modulate = Color(attacker.accent.r, attacker.accent.g, attacker.accent.b, 1.0)

func _face_each_other() -> void:
	if is_instance_valid(player) and is_instance_valid(cpu):
		var player_target := Vector3(cpu.position.x, player.position.y, cpu.position.z)
		var cpu_target := Vector3(player.position.x, cpu.position.y, player.position.z)
		player.look_at(player_target, Vector3.UP)
		cpu.look_at(cpu_target, Vector3.UP)

func _player_attack(kind: int) -> void:
	if round_over or not is_instance_valid(player):
		return
	if player_attack_cooldown > 0.0:
		return
	if player.start_attack(kind):
		player_attack_cooldown = 0.12

func _player_dash() -> void:
	if round_over or not is_instance_valid(player) or player.knocked_out:
		return
	var direction := Vector3.ZERO
	if joystick != null:
		direction.x = joystick.get_vector().x
		direction.z = joystick.get_vector().y
	if direction.length() < 0.1:
		direction.x = 1.0 if player.position.x < cpu.position.x else -1.0
	direction = direction.normalized()
	player.position += direction * 1.4
	player.position.x = clampf(player.position.x, -8.3, 8.3)
	player.position.z = clampf(player.position.z, -3.1, 3.1)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if not is_instance_valid(player) or not is_instance_valid(cpu):
		return
	var midpoint := (player.position + cpu.position) * 0.5
	var separation := player.position.distance_to(cpu.position)
	var target := Vector3(midpoint.x * 0.12, 4.8, clampf(12.0 + separation * 0.45, 12.0, 16.8))
	if camera_shake > 0.0:
		target += Vector3(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake * 0.45, camera_shake * 0.45), 0.0)
		camera_shake = maxf(0.0, camera_shake - delta * 1.5)
	camera.position = camera.position.lerp(target, clampf(delta * 4.0, 0.0, 1.0))
	camera.look_at(Vector3(midpoint.x, 1.3, 0.0), Vector3.UP)

func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var top_left := _panel(root, Vector2(26, 24), Vector2(530, 116), Color(0.02, 0.04, 0.09, 0.80), CYAN)
	var top_right := _panel(root, Vector2(724, 24), Vector2(530, 116), Color(0.02, 0.04, 0.09, 0.80), PINK)
	root.add_child(top_left)
	root.add_child(top_right)

	player_portrait = _portrait(root, "res://art/rex.svg", Vector2(38, 34))
	cpu_portrait = _portrait(root, "res://art/zara.svg", Vector2(1154, 34))
	root.add_child(player_portrait)
	root.add_child(cpu_portrait)

	player_name_label = _label("", Vector2(160, 40), Vector2(340, 28), 21, WHITE)
	root.add_child(player_name_label)
	cpu_name_label = _label("", Vector2(780, 40), Vector2(340, 28), 21, WHITE)
	cpu_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(cpu_name_label)

	player_bar = _health_bar(root, Vector2(160, 78), 330, CYAN, false)
	cpu_bar = _health_bar(root, Vector2(780, 78), 330, PINK, true)

	var timer_panel := _panel(root, Vector2(596, 22), Vector2(88, 98), Color(0.03, 0.03, 0.08, 0.95), PURPLE)
	root.add_child(timer_panel)
	timer_label = _label("60", Vector2(600, 37), Vector2(80, 50), 38, WHITE)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(timer_label)
	root.add_child(_label("ROUND 01", Vector2(600, 82), Vector2(80, 18), 9, MUTED))

	combo_label = _label("", Vector2(520, 204), Vector2(240, 64), 24, WHITE)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(combo_label)

	announce = _label("READY", Vector2(280, 278), Vector2(720, 84), 36, WHITE)
	announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(announce)

	root.add_child(_label("NEON DISTRICT  •  NEXAR BATTLE ARENA", Vector2(28, 680), Vector2(500, 22), 11, MUTED))
	root.add_child(_label("WASD / F G H / R / T", Vector2(1070, 680), Vector2(190, 22), 11, MUTED))

func _portrait(parent: Control, path: String, pos: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.texture = load(path)
	portrait.position = pos
	portrait.size = Vector2(104, 104)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait

func _panel(parent: Control, pos: Vector2, size: Vector2, bg: Color, accent: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _health_bar(parent: Control, pos: Vector2, width: float, color: Color, reverse: bool) -> ColorRect:
	var background := ColorRect.new()
	background.position = pos
	background.size = Vector2(width, 20)
	background.color = Color("#111827")
	parent.add_child(background)
	var fill := ColorRect.new()
	fill.size = background.size
	fill.color = color
	background.add_child(fill)
	fill.set_meta("background_width", width)
	fill.set_meta("reverse", reverse)
	return fill

func _setup_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	add_child(layer)
	mobile_root = Control.new()
	mobile_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(mobile_root)

	joystick = JoystickScript.new()
	joystick.size = Vector2(190, 190)
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_root.add_child(joystick)

	_create_action_button("✦\nLIGHT", 0, CYAN, func(): _player_attack(0))
	_create_action_button("✺\nHEAVY", 1, PURPLE, func(): _player_attack(1))
	_create_action_button("⚡\nSPECIAL", 2, PINK, func(): _player_attack(2))
	_create_block_button()
	_layout_touch_controls()
func _create_action_button(text_value: String, index: int, color: Color, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.name = "Action" + str(index)
	button.size = Vector2(88, 76)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", WHITE)
	_style_touch_button(button, color)
	button.button_down.connect(action)
	mobile_root.add_child(button)
	button.set_meta("touch_index", index)

func _create_block_button() -> void:
	var button := Button.new()
	button.text = "⬡\nBLOCK"
	button.name = "Block"
	button.size = Vector2(88, 76)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", WHITE)
	_style_touch_button(button, Color("#4E607E"))
	button.button_down.connect(func(): block_held = true)
	button.button_up.connect(func(): block_held = false)
	mobile_root.add_child(button)

func _style_touch_button(button: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r, color.g, color.b, 0.18)
	normal.border_color = Color(color.r, color.g, color.b, 0.75)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 44
	normal.corner_radius_top_right = 44
	normal.corner_radius_bottom_left = 44
	normal.corner_radius_bottom_right = 44
	var pressed := normal.duplicate()
	pressed.bg_color = Color(color.r, color.g, color.b, 0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)

func _process(_delta: float) -> void:
	_layout_touch_controls()

func _layout_touch_controls() -> void:
	if mobile_root == null or joystick == null:
		return
	var size := get_viewport().get_visible_rect().size
	joystick.position = Vector2(34, size.y - 208)

	var start_x := size.x - 390.0
	var y := size.y - 175.0
	var gap := 96.0

	var action0 := mobile_root.get_node_or_null("Action0")
	var action1 := mobile_root.get_node_or_null("Action1")
	var action2 := mobile_root.get_node_or_null("Action2")
	var block := mobile_root.get_node_or_null("Block")

	if action0:
		action0.position = Vector2(start_x, y)
	if action1:
		action1.position = Vector2(start_x + gap, y - 46)
	if action2:
		action2.position = Vector2(start_x + gap * 2.0, y)
	if block:
		block.position = Vector2(start_x + gap * 3.0, y - 46)

func _spawn_hit_effect(pos: Vector3, color: Color, heavy: bool) -> void:
	var root := Node3D.new()
	root.name = "ImpactFX"
	root.global_position = pos
	add_child(root)

	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.20 if not heavy else 0.28
	sphere.height = 0.40 if not heavy else 0.56
	flash.mesh = sphere
	flash.material_override = _fx_material(color, color, 3.5)
	root.add_child(flash)

	var ring_node := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.30
	ring.outer_radius = 0.37
	ring.rings = 28
	ring.ring_segments = 12
	ring_node.mesh = ring
	ring_node.material_override = _fx_material(color, color, 2.8)
	root.add_child(ring_node)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 7.0 if heavy else 4.0
	light.omni_range = 4.0
	root.add_child(light)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * (3.0 if heavy else 2.2), 0.16)
	tween.tween_property(ring_node, "scale", Vector3.ONE * (2.8 if heavy else 2.0), 0.18)
	tween.tween_property(light, "light_energy", 0.0, 0.20)

	var spark_count := 8 if heavy else 5
	for i in range(spark_count):
		var spark := MeshInstance3D.new()
		var spark_mesh := BoxMesh.new()
		spark_mesh.size = Vector3(0.035, 0.035, 0.24 if heavy else 0.18)
		spark.mesh = spark_mesh
		spark.material_override = _fx_material(color, color, 4.0)
		root.add_child(spark)
		var angle := float(i) * TAU / float(spark_count)
		spark.position = Vector3(0, 0, 0)
		spark.rotation.y = angle
		var direction := Vector3(cos(angle), randf_range(-0.25, 0.25), sin(angle))
		tween.tween_property(spark, "position", direction * (1.3 if heavy else 0.9), 0.24)

	tween.tween_callback(root.queue_free).set_delay(0.28)

func _fx_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(albedo.r, albedo.g, albedo.b, 0.95)
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material

func _update_hud() -> void:
	if not is_instance_valid(player_bar) or not is_instance_valid(cpu_bar):
		return
	player_bar.size.x = 360.0 * player.health / player.max_health
	cpu_bar.size.x = 360.0 * cpu.health / cpu.max_health
	cpu_bar.position.x = 360.0 - cpu_bar.size.x
	if combo_label:
		combo_label.text = "COMBO  x%d" % combo_hits if combo_hits > 1 and combo_time > 0.0 else ""
	timer_label.text = str(int(ceil(round_time)))
	player_name_label.text = "%s • %03d HP" % [player.fighter_name, int(player.health)]
	cpu_name_label.text = "%s • %03d HP" % [cpu.fighter_name, int(cpu.health)]

func _health_bar(parent: Control, pos: Vector2, width: float, color: Color, reverse: bool) -> ColorRect:
	var background := ColorRect.new()
	background.position = pos
	background.size = Vector2(width, 20)
	background.color = Color("#111624")
	parent.add_child(background)
	var fill := ColorRect.new()
	fill.size = background.size
	fill.color = color
	background.add_child(fill)
	fill.set_meta("reverse", reverse)
	return fill

func _end_message(text_value: String) -> void:
	if round_over:
		return
	round_over = true
	announce.text = text_value + "\nENTER = REMATCH • ESC = HOME"

func _finish_round() -> void:
	if player.health > cpu.health:
		_end_message("%s WINS" % player.fighter_name)
	elif cpu.health > player.health:
		_end_message("%s WINS" % cpu.fighter_name)
	else:
		_end_message("DRAW")

func _label(value: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.12)
	style.border_color = Color(color.r, color.g, color.b, 0.65)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style.duplicate())
	return button

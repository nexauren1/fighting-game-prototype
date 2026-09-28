extends Node3D

# Self-contained combat test scene.
# This intentionally avoids external fighter dependencies so the scene
# can boot even before final character assets are imported.

const CYAN := Color("#58E7FF")
const PINK := Color("#FF5EC4")
const PURPLE := Color("#B86CFF")
const GREEN := Color("#72F7C2")
const BG := Color("#050612")
const TEXT := Color("#F5F7FF")
const MUTED := Color("#8B94B7")

var p1: Node3D
var p2: Node3D
var p1_parts: Array[MeshInstance3D] = []
var p2_parts: Array[MeshInstance3D] = []

var p1_state := {
	"hp": 100.0,
	"style": 0,
	"attack": -1,
	"attack_time": 0.0,
	"attack_hit": false,
	"stun": 0.0,
	"dash": 0.0,
	"jump": 0.0,
	"blocking": false,
	"ko": false,
	"facing": 1.0
}
var p2_state := {
	"hp": 100.0,
	"style": 1,
	"attack": -1,
	"attack_time": 0.0,
	"attack_hit": false,
	"stun": 0.0,
	"dash": 0.0,
	"jump": 0.0,
	"blocking": false,
	"ko": false,
	"facing": -1.0
}

var camera: Camera3D
var round_time := 60.0
var round_over := false
var announce_time := 0.0
var announce_text := "READY"

var p1_fill: ColorRect
var p2_fill: ColorRect
var timer_label: Label
var p1_info: Label
var p2_info: Label
var announce_label: Label

const STYLE_NAMES := ["SWIFT", "POWER", "PHASE"]
const STYLE_SPEED := [5.0, 3.8, 4.6]
const STYLE_DAMAGE := [0.90, 1.25, 1.00]
const ATTACK_NAMES := ["LIGHT", "HEAVY", "SPECIAL"]
const ATTACK_DAMAGE := [9.0, 18.0, 27.0]
const ATTACK_DURATION := [0.38, 0.56, 0.72]
const ATTACK_RANGE := [1.55, 1.80, 2.05]

func _ready() -> void:
	_setup_world()
	_setup_fighters()
	_setup_hud()
	_show_announce("READY", 1.0)

func _process(delta: float) -> void:
	if not round_over:
		_update_timers(delta)
		_read_controls(delta)
		_update_fighters(delta)
		_resolve_attacks()
		round_time = maxf(0.0, round_time - delta)
		if round_time <= 0.0:
			_finish_by_time()

	_update_camera(delta)
	_update_visuals()
	_update_hud()
	announce_time = maxf(0.0, announce_time - delta)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key := event as InputEventKey
	if key.echo or not key.pressed:
		return

	match key.keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://main.tscn")
			return
		KEY_ENTER, KEY_KP_ENTER:
			if round_over:
				get_tree().reload_current_scene()
				return

	# P1 attacks / styles.
	match key.keycode:
		KEY_F:
			_start_attack(p1_state, 0)
		KEY_G:
			_start_attack(p1_state, 1)
		KEY_H:
			_start_attack(p1_state, 2)
		KEY_T:
			_dash(p1, p1_state)
		KEY_1:
			_set_style(p1_state, 0, "P1")
		KEY_2:
			_set_style(p1_state, 1, "P1")
		KEY_3:
			_set_style(p1_state, 2, "P1")

	# P2 attacks / styles.
	match key.keycode:
		KEY_J:
			_start_attack(p2_state, 0)
		KEY_K:
			_start_attack(p2_state, 1)
		KEY_L:
			_start_attack(p2_state, 2)
		KEY_O:
			_dash(p2, p2_state)
		KEY_7:
			_set_style(p2_state, 0, "P2")
		KEY_8:
			_set_style(p2_state, 1, "P2")
		KEY_9:
			_set_style(p2_state, 2, "P2")

func _setup_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BG
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 1.0
	env.environment = environment
	add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -25.0, 0.0)
	light.light_energy = 1.5
	add_child(light)

	# Floor.
	_add_box(self, Vector3(0, -0.15, 0), Vector3(20, 0.30, 8), Color("#15192D"))

	# Neon arena rails.
	_add_box(self, Vector3(0, 0.04, -3.5), Vector3(20, 0.08, 0.08), PURPLE)
	_add_box(self, Vector3(0, 0.04, 3.5), Vector3(20, 0.08, 0.08), CYAN)

	# Simple skyline.
	for i in range(11):
		var x := -10.0 + float(i) * 2.0
		var h := 2.5 + float((i * 3) % 5) * 0.65
		_add_box(self, Vector3(x, h * 0.5, -2.4), Vector3(1.35, h, 0.45), Color("#0B0F20"))
		_add_box(self, Vector3(x, 0.25, -2.12), Vector3(0.80, 0.05, 0.03), CYAN if i % 2 == 0 else PINK)

	camera = Camera3D.new()
	camera.fov = 48.0
	camera.position = Vector3(0, 4.6, 14.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)

func _setup_fighters() -> void:
	var p1_name := "PHANTOM"
	var p2_name := "VANGUARD"
	if get_tree().has_meta("p1_hunter"):
		if int(get_tree().get_meta("p1_hunter")) == 1:
			p1_name = "VANGUARD"
			p2_name = "PHANTOM"

	p1 = _create_fighter(p1_name, CYAN)
	p1.position = Vector3(-3.1, 0, 0)
	add_child(p1)

	p2 = _create_fighter(p2_name, PINK)
	p2.position = Vector3(3.1, 0, 0)
	add_child(p2)

func _create_fighter(display_name: String, accent: Color) -> Node3D:
	var root := Node3D.new()
	root.name = display_name

	var dark := _material(Color("#111426"))
	var accent_mat := _material(accent)
	var visor_mat := _material(Color("#F2FBFF"))

	var torso := _box(root, Vector3(0, 1.05, 0), Vector3(0.78, 1.18, 0.48), dark)
	var head := _sphere(root, Vector3(0, 1.87, 0), 0.27, dark)
	_box(root, Vector3(0, 1.90, 0.25), Vector3(0.38, 0.09, 0.03), visor_mat)
	_box(root, Vector3(-0.50, 1.10, 0), Vector3(0.20, 0.76, 0.20), accent_mat)
	_box(root, Vector3(0.50, 1.10, 0), Vector3(0.20, 0.76, 0.20), accent_mat)
	_box(root, Vector3(-0.19, 0.31, 0), Vector3(0.25, 0.78, 0.25), dark)
	_box(root, Vector3(0.19, 0.31, 0), Vector3(0.25, 0.78, 0.25), dark)
	_box(root, Vector3(-0.49, 1.47, 0), Vector3(0.28, 0.22, 0.32), accent_mat)
	_box(root, Vector3(0.49, 1.47, 0), Vector3(0.28, 0.22, 0.32), accent_mat)

	root.set_meta("display_name", display_name)
	root.set_meta("accent", accent)
	return root

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color != Color("#111426") and color != Color("#F2FBFF") and color != Color("#0B0F20") and color != Color("#15192D"):
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
	return mat

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

func _sphere(parent: Node3D, pos: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	layer.add_child(_label("NEON DISTRICT // COMBAT TEST", Vector2(34, 24), Vector2(700, 34), 18, TEXT))
	layer.add_child(_label("ESC  BACK TO SETUP", Vector2(34, 54), Vector2(300, 24), 11, MUTED))

	layer.add_child(_label("PLAYER 01", Vector2(50, 100), Vector2(260, 24), 12, CYAN))
	p1_info = _label("", Vector2(50, 125), Vector2(500, 28), 14, TEXT)
	layer.add_child(p1_info)

	layer.add_child(_label("PLAYER 02", Vector2(970, 100), Vector2(260, 24), 12, PINK))
	p2_info = _label("", Vector2(760, 125), Vector2(470, 28), 14, TEXT)
	p2_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(p2_info)

	var p1_bg := _bar(layer, Vector2(50, 158), CYAN)
	var p2_bg := _bar(layer, Vector2(870, 158), PINK)
	p1_fill = p1_bg.get_meta("fill")
	p2_fill = p2_bg.get_meta("fill")

	timer_label = _label("60", Vector2(600, 112), Vector2(80, 55), 32, TEXT)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(timer_label)

	announce_label = _label("", Vector2(280, 280), Vector2(720, 90), 34, TEXT)
	announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(announce_label)

	var controls := _label(
		"P1  A/D move  W jump  F light  G heavy  H special  R block  T dash  1/2/3 style\n" +
		"P2  LEFT/RIGHT move  UP jump  J light  K heavy  L special  I block  O dash  7/8/9 style",
		Vector2(34, 638), Vector2(1210, 52), 11, MUTED
	)
	layer.add_child(controls)

func _bar(layer: CanvasLayer, pos: Vector2, color: Color) -> ColorRect:
	var background := ColorRect.new()
	background.position = pos
	background.size = Vector2(330, 20)
	background.color = Color("#111426")
	layer.add_child(background)

	var fill := ColorRect.new()
	fill.position = Vector2.ZERO
	fill.size = background.size
	fill.color = color
	background.add_child(fill)
	background.set_meta("fill", fill)
	return background

func _label(value: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _read_controls(delta: float) -> void:
	p1_state["blocking"] = Input.is_physical_key_pressed(KEY_R) and not _is_attacking(p1_state)
	p2_state["blocking"] = Input.is_physical_key_pressed(KEY_I) and not _is_attacking(p2_state)

	var p1_dir := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		p1_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		p1_dir += 1.0
	_move(p1, p1_state, p1_dir, delta)

	var p2_dir := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		p2_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		p2_dir += 1.0
	_move(p2, p2_state, p2_dir, delta)

	if Input.is_physical_key_pressed(KEY_W):
		_jump(p1, p1_state)
	if Input.is_physical_key_pressed(KEY_UP):
		_jump(p2, p2_state)

func _move(node: Node3D, state: Dictionary, direction: float, delta: float) -> void:
	if direction == 0.0 or bool(state["ko"]) or float(state["stun"]) > 0.0 or _is_attacking(state):
		return
	node.position.x += direction * STYLE_SPEED[int(state["style"])] * delta
	node.position.x = clampf(node.position.x, -8.0, 8.0)
	state["facing"] = signf(direction)

func _jump(node: Node3D, state: Dictionary) -> void:
	if bool(state["ko"]) or float(state["stun"]) > 0.0:
		return
	if node.position.y <= 0.03:
		state["jump"] = 7.0

func _update_fighters(delta: float) -> void:
	_apply_vertical(p1, p1_state, delta)
	_apply_vertical(p2, p2_state, delta)

	if not bool(p1_state["ko"]):
		p1_state["facing"] = 1.0 if p2.position.x >= p1.position.x else -1.0
	if not bool(p2_state["ko"]):
		p2_state["facing"] = 1.0 if p1.position.x >= p2.position.x else -1.0

func _apply_vertical(node: Node3D, state: Dictionary, delta: float) -> void:
	var jump_velocity := float(state["jump"])
	if node.position.y > 0.0 or jump_velocity > 0.0:
		jump_velocity -= 18.0 * delta
		node.position.y += jump_velocity * delta
		if node.position.y <= 0.0:
			node.position.y = 0.0
			jump_velocity = 0.0
	state["jump"] = jump_velocity

func _update_timers(delta: float) -> void:
	for state in [p1_state, p2_state]:
		state["attack_time"] = maxf(0.0, float(state["attack_time"]) - delta)
		state["stun"] = maxf(0.0, float(state["stun"]) - delta)
		state["dash"] = maxf(0.0, float(state["dash"]) - delta)

func _start_attack(state: Dictionary, kind: int) -> void:
	if bool(state["ko"]) or float(state["stun"]) > 0.0 or _is_attacking(state):
		return
	state["attack"] = kind
	state["attack_hit"] = false
	state["attack_time"] = ATTACK_DURATION[kind] * [1.0, 0.82, 0.92][int(state["style"])]

func _is_attacking(state: Dictionary) -> bool:
	return float(state["attack_time"]) > 0.0

func _dash(node: Node3D, state: Dictionary) -> void:
	if bool(state["ko"]) or float(state["stun"]) > 0.0 or _is_attacking(state):
		return
	node.position.x += float(state["facing"]) * 1.7
	node.position.x = clampf(node.position.x, -8.0, 8.0)
	state["dash"] = 0.15

func _resolve_attacks() -> void:
	_resolve_one(p1, p1_state, p2, p2_state)
	_resolve_one(p2, p2_state, p1, p1_state)

func _resolve_one(attacker: Node3D, a: Dictionary, target: Node3D, t: Dictionary) -> void:
	if not _is_attacking(a) or bool(a["attack_hit"]):
		return

	var kind := int(a["attack"])
	var duration := ATTACK_DURATION[kind] * [1.0, 0.82, 0.92][int(a["style"])]
	var progress := 1.0 - float(a["attack_time"]) / duration
	if progress < 0.45:
		return

	a["attack_hit"] = true
	var distance := absf(attacker.position.x - target.position.x)
	var direction := signf(target.position.x - attacker.position.x)
	var facing_ok := direction == float(a["facing"]) or distance < 0.25

	if distance <= ATTACK_RANGE[kind] and facing_ok:
		var damage := ATTACK_DAMAGE[kind] * STYLE_DAMAGE[int(a["style"])]
		if bool(t["blocking"]):
			damage *= 0.25
		t["hp"] = maxf(0.0, float(t["hp"]) - damage)
		t["stun"] = 0.20 if not bool(t["blocking"]) else 0.10
		target.position.x += direction * [0.12, 0.28, 0.48][kind]
		_show_announce("%s  -  %.0f" % [ATTACK_NAMES[kind], damage], 0.25)

		if float(t["hp"]) <= 0.0:
			t["ko"] = true
			t["blocking"] = false
			t["attack_time"] = 0.0
			_finish("%s WINS" % str(attacker.get_meta("display_name")))

func _set_style(state: Dictionary, index: int, player_label: String) -> void:
	state["style"] = index
	_show_announce("%s: %s" % [player_label, STYLE_NAMES[index]], 0.55)

func _update_visuals() -> void:
	_animate_fighter(p1, p1_state)
	_animate_fighter(p2, p2_state)

func _animate_fighter(node: Node3D, state: Dictionary) -> void:
	var children := node.get_children()
	if children.is_empty():
		return

	var base_y := sin(Time.get_ticks_msec() * 0.004) * 0.025
	node.scale = Vector3.ONE
	node.rotation = Vector3.ZERO
	node.position.y = maxf(0.0, node.position.y)

	if bool(state["ko"]):
		node.rotation.z = -1.2
		node.position.y = -0.05
		return

	if bool(state["blocking"]):
		node.scale = Vector3(0.94, 1.02, 0.94)

	if _is_attacking(state):
		var kind := int(state["attack"])
		var duration := ATTACK_DURATION[kind] * [1.0, 0.82, 0.92][int(state["style"])]
		var progress := clampf(1.0 - float(state["attack_time"]) / duration, 0.0, 1.0)
		var swing := sin(progress * PI)
		node.rotation.z = -0.10 * swing
		node.scale = Vector3.ONE * (1.0 + 0.05 * swing)
	else:
		node.position.y += base_y

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var midpoint := (p1.position.x + p2.position.x) * 0.5
	var separation := absf(p1.position.x - p2.position.x)
	var desired := Vector3(midpoint * 0.20, 4.5, clampf(12.5 + separation * 0.50, 12.5, 17.0))
	camera.position = camera.position.lerp(desired, clampf(delta * 3.0, 0.0, 1.0))
	camera.look_at(Vector3(midpoint, 1.0, 0), Vector3.UP)

func _update_hud() -> void:
	if p1_fill == null:
		return

	p1_fill.size.x = 330.0 * float(p1_state["hp"]) / 100.0
	var p2_width := 330.0 * float(p2_state["hp"]) / 100.0
	p2_fill.position.x = 330.0 - p2_width
	p2_fill.size.x = p2_width

	timer_label.text = str(int(ceil(round_time)))
	p1_info.text = "%s  •  %s  •  %03d HP" % [str(p1.get_meta("display_name")), STYLE_NAMES[int(p1_state["style"])], int(p1_state["hp"])]
	p2_info.text = "%s  •  %s  •  %03d HP" % [str(p2.get_meta("display_name")), STYLE_NAMES[int(p2_state["style"])], int(p2_state["hp"])]
	announce_label.text = announce_text if announce_time > 0.0 else ""

func _show_announce(message: String, duration: float) -> void:
	announce_text = message
	announce_time = duration

func _finish(message: String) -> void:
	if round_over:
		return
	round_over = true
	_show_announce(message + "\nENTER = REMATCH   •   ESC = SETUP", 999.0)

func _finish_by_time() -> void:
	if round_over:
		return
	var h1 := float(p1_state["hp"])
	var h2 := float(p2_state["hp"])
	if is_equal_approx(h1, h2):
		_finish("DRAW")
	elif h1 > h2:
		_finish("%s WINS" % str(p1.get_meta("display_name")))
	else:
		_finish("%s WINS" % str(p2.get_meta("display_name")))

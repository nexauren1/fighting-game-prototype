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
	environment.background_color = Color("#02040A")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#B7C9E8")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#10203A")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.012
	environment.fog_height = 1.5
	environment.fog_height_density = 0.18
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.18
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_color = Color("#D8E8FF")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	_add_box(self, Vector3(0, -0.35, 0), Vector3(30, 0.70, 22), Color("#090C13"), 0.20, 0.82)
	_add_box(self, Vector3(0, -0.01, 0), Vector3(20.5, 0.18, 8.5), Color("#151A23"), 0.25, 0.72)
	_add_box(self, Vector3(0, 0.10, 0), Vector3(18.8, 0.12, 7.4), Color("#252A33"), 0.45, 0.55)

	_add_box(self, Vector3(0, 0.02, -4.05), Vector3(21.0, 0.28, 0.42), Color("#3A3E46"), 0.15, 0.62)
	_add_box(self, Vector3(0, 0.02, 4.05), Vector3(21.0, 0.28, 0.42), Color("#3A3E46"), 0.15, 0.62)
	_add_box(self, Vector3(-10.45, 0.02, 0), Vector3(0.42, 0.28, 8.5), Color("#3A3E46"), 0.15, 0.62)
	_add_box(self, Vector3(10.45, 0.02, 0), Vector3(0.42, 0.28, 8.5), Color("#3A3E46"), 0.15, 0.62)

	for x in range(-8, 9, 2):
		_add_box(self, Vector3(float(x), 0.17, 0), Vector3(0.035, 0.012, 6.9), Color("#5C6573"), 0.0, 0.5, 0.12)
	_add_box(self, Vector3(0, 0.18, -3.48), Vector3(19.0, 0.018, 0.045), PURPLE, 0.0, 0.32, 2.0)
	_add_box(self, Vector3(0, 0.18, 3.48), Vector3(19.0, 0.018, 0.045), CYAN, 0.0, 0.32, 2.0)

	for x in [-7.5, -3.75, 0.0, 3.75, 7.5]:
		_add_box(self, Vector3(x, 0.185, -3.15), Vector3(0.16, 0.02, 0.45), Color("#B9F4FF"), 0.1, 0.28, 4.0)
		_add_box(self, Vector3(x, 0.185, 3.15), Vector3(0.16, 0.02, 0.45), Color("#B9F4FF"), 0.1, 0.28, 4.0)

	_add_box(self, Vector3(-6.2, 0.195, 1.75), Vector3(2.8, 0.012, 0.72), Color("#17202B"), 0.65, 0.16)
	_add_box(self, Vector3(4.8, 0.197, -1.9), Vector3(3.4, 0.012, 0.55), Color("#141C26"), 0.72, 0.12)
	_add_box(self, Vector3(0.5, 0.198, 2.45), Vector3(1.7, 0.012, 0.40), Color("#1B2430"), 0.62, 0.15)

	for i in range(13):
		var x := -16.0 + float(i) * 2.65
		var width := 1.55 + float((i * 7) % 4) * 0.22
		var depth := 1.7 + float((i * 5) % 3) * 0.35
		var height := 5.5 + float((i * 11) % 7) * 1.35
		var z := -6.0 - float(i % 3) * 0.7
		_add_city_building(x, z, width, depth, height, i)
	_add_city_building(-7.0, -5.0, 3.2, 2.4, 11.5, 21)
	_add_city_building(7.2, -5.5, 3.5, 2.6, 13.0, 22)

	for x in [-8.8, 8.8]:
		_add_box(self, Vector3(x, 0.52, -2.7), Vector3(1.1, 0.72, 0.95), Color("#30343C"), 0.55, 0.72)
		_add_box(self, Vector3(x, 0.93, -2.7), Vector3(0.72, 0.08, 0.56), Color("#606875"), 0.65, 0.35)
		_add_box(self, Vector3(x, 0.20, -2.22), Vector3(1.55, 0.12, 0.08), CYAN if x < 0 else PINK, 0.0, 0.35, 2.2)

	for x in [-9.2, -6.1, 6.1, 9.2]:
		_add_cylinder(self, Vector3(x, 0.62, -3.55), 0.08, 1.15, Color("#545A64"), 0.35, 0.55)
		_add_box(self, Vector3(x, 1.18, -3.55), Vector3(0.75, 0.06, 0.06), Color("#5A626D"), 0.35, 0.48)

	_add_omni_light(Vector3(-7.6, 3.6, -3.8), CYAN, 7.0, 8.0)
	_add_omni_light(Vector3(7.6, 4.0, -3.8), PINK, 7.0, 8.0)
	_add_omni_light(Vector3(0, 5.5, -4.5), Color("#9FA8FF"), 5.0, 10.0)

	camera = Camera3D.new()
	camera.fov = 46.0
	camera.position = Vector3(0, 4.9, 14.8)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)

func _add_city_building(x: float, z: float, width: float, depth: float, height: float, index: int) -> void:
	var wall_colors := [Color("#151923"), Color("#1B202A"), Color("#111720"), Color("#20242D")]
	var wall := wall_colors[index % wall_colors.size()]
	_add_box(self, Vector3(x, height * 0.5, z), Vector3(width, height, depth), wall, 0.28, 0.68)
	_add_box(self, Vector3(x, height * 0.52, z + depth * 0.5 + 0.015), Vector3(width * 0.82, height * 0.84, 0.025), Color("#0B1622"), 0.72, 0.22)
	var floors := maxi(2, int(height / 2.2))
	for floor in range(floors):
		var y := 1.05 + float(floor) * 2.0
		if y > height - 0.55:
			break
		for col in range(3):
			var window_x := x - width * 0.30 + float(col) * width * 0.30
			var window_color := Color("#B7D9E8") if (index + floor + col) % 4 == 0 else Color("#314859")
			_add_box(self, Vector3(window_x, y, z + depth * 0.515), Vector3(width * 0.18, 0.78, 0.035), window_color, 0.15, 0.34, 0.35 if window_color.r > 0.5 else 0.0)
	_add_box(self, Vector3(x, height + 0.10, z), Vector3(width * 0.58, 0.18, depth * 0.62), Color("#343942"), 0.45, 0.58)
	if index % 3 == 0:
		_add_box(self, Vector3(x, height + 0.52, z), Vector3(width * 0.24, 0.75, depth * 0.24), Color("#4A505A"), 0.55, 0.65)
	if index % 2 == 0:
		_add_box(self, Vector3(x, height * 0.58, z + depth * 0.53), Vector3(width * 0.60, 0.06, 0.035), CYAN if index % 4 == 0 else PURPLE, 0.0, 0.30, 1.8)

func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color, metallic, roughness)
	parent.add_child(node)
	return node

func _add_omni_light(pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = true
	add_child(light)

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

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.65, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metallic: float = 0.0, roughness: float = 0.65, emission_energy: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color, metallic, roughness, emission_energy)
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

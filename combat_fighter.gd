extends Node3D
class_name CombatFighter

var fighter_name := "FIGHTER"
var accent := Color("#58E7FF")
var max_health := 100.0
var health := 100.0

var style_index := 0
var weapon_index := 0
var facing := 1.0
var attack_timer := 0.0
var attack_kind := 0
var hit_applied := false
var stun_timer := 0.0
var dash_timer := 0.0
var invuln_timer := 0.0
var jump_velocity := 0.0
var is_blocking := false
var ko := false

var model_root: Node3D
var torso: MeshInstance3D
var head: MeshInstance3D
var arm_l: MeshInstance3D
var arm_r: MeshInstance3D
var leg_l: MeshInstance3D
var leg_r: MeshInstance3D
var weapon_root: Node3D
var aura_root: Node3D
var damage_flash := 0.0

const STYLE_NAMES := ["DUELIST", "BERSERKER", "PHANTOM"]
const WEAPON_NAMES := ["ENERGY BLADE", "WAR HAMMER", "ARC GAUNTLET"]

func setup(display_name: String, color: Color, starting_style := 0, starting_weapon := 0) -> void:
	fighter_name = display_name
	accent = color
	style_index = starting_style
	weapon_index = starting_weapon
	_build_model()

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer = max(0.0, attack_timer - delta)
	if stun_timer > 0.0:
		stun_timer = max(0.0, stun_timer - delta)
	if dash_timer > 0.0:
		dash_timer = max(0.0, dash_timer - delta)
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
	if damage_flash > 0.0:
		damage_flash = max(0.0, damage_flash - delta)
	_animate(delta)

func _build_model() -> void:
	for child in get_children():
		child.queue_free()

	model_root = Node3D.new()
	model_root.name = "Model"
	add_child(model_root)

	var accent_mat := _material(accent, true, 1.8)
	var dark_mat := _material(Color("#111426"), false, 0.0)
	var visor_mat := _material(Color("#EAF7FF"), true, 3.5)

	torso = _box("Torso", Vector3(0, 1.05, 0), Vector3(0.78, 1.18, 0.48), dark_mat)
	head = _sphere("Head", Vector3(0, 1.88, 0), 0.28, dark_mat)
	var visor := _box("Visor", Vector3(0, 1.91, 0.255), Vector3(0.37, 0.09, 0.025), visor_mat)
	arm_l = _box("ArmL", Vector3(-0.50, 1.10, 0), Vector3(0.20, 0.76, 0.20), accent_mat)
	arm_r = _box("ArmR", Vector3(0.50, 1.10, 0), Vector3(0.20, 0.76, 0.20), accent_mat)
	leg_l = _box("LegL", Vector3(-0.19, 0.31, 0), Vector3(0.25, 0.78, 0.25), dark_mat)
	leg_r = _box("LegR", Vector3(0.19, 0.31, 0), Vector3(0.25, 0.78, 0.25), dark_mat)

	var shoulder_l := _box("ShoulderL", Vector3(-0.48, 1.46, 0), Vector3(0.26, 0.22, 0.32), accent_mat)
	var shoulder_r := _box("ShoulderR", Vector3(0.48, 1.46, 0), Vector3(0.26, 0.22, 0.32), accent_mat)
	shoulder_l.rotation_degrees.z = -8
	shoulder_r.rotation_degrees.z = 8

	weapon_root = Node3D.new()
	weapon_root.name = "Weapon"
	model_root.add_child(weapon_root)
	_rebuild_weapon()

	aura_root = Node3D.new()
	aura_root.name = "Aura"
	model_root.add_child(aura_root)
	var aura_mesh := SphereMesh.new()
	aura_mesh.radius = 0.76
	aura_mesh.height = 1.70
	var aura := MeshInstance3D.new()
	aura.name = "Aura"
	aura.mesh = aura_mesh
	var aura_mat := _material(accent, true, 1.0)
	aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_mat.albedo_color = Color(accent.r, accent.g, accent.b, 0.035)
	aura.material_override = aura_mat
	aura.position.y = 1.0
	aura_root.add_child(aura)

func _rebuild_weapon() -> void:
	for child in weapon_root.get_children():
		child.queue_free()

	var accent_mat := _material(accent, true, 3.0)
	var dark_mat := _material(Color("#232843"), true, 0.6)

	match weapon_index:
		0:
			var grip := _box("Grip", Vector3(0.62, 0.82, 0), Vector3(0.10, 0.36, 0.10), dark_mat)
			var blade := _box("Blade", Vector3(0.62, 1.17, 0), Vector3(0.12, 0.98, 0.08), accent_mat)
			blade.rotation_degrees.z = -4
			var guard := _box("Guard", Vector3(0.62, 1.00, 0), Vector3(0.42, 0.08, 0.12), accent_mat)
			weapon_root.add_child(grip)
			weapon_root.add_child(blade)
			weapon_root.add_child(guard)
		1:
			var handle := _box("Handle", Vector3(0.64, 0.95, 0), Vector3(0.12, 0.62, 0.12), dark_mat)
			var head_mesh := _box("HammerHead", Vector3(0.64, 1.34, 0), Vector3(0.42, 0.28, 0.36), accent_mat)
			weapon_root.add_child(handle)
			weapon_root.add_child(head_mesh)
		2:
			var gauntlet := _box("Gauntlet", Vector3(0.62, 1.14, 0), Vector3(0.40, 0.34, 0.34), accent_mat)
			var emitter := _sphere("Emitter", Vector3(0.62, 1.14, 0.19), 0.10, accent_mat)
			weapon_root.add_child(gauntlet)
			weapon_root.add_child(emitter)

func _material(color: Color, emission: bool, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.38
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
	return mat

func _box(node_name: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	model_root.add_child(part)
	return part

func _sphere(node_name: String, pos: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = mat
	part.position = pos
	model_root.add_child(part)
	return part

func set_style(index: int) -> void:
	style_index = clampi(index, 0, STYLE_NAMES.size() - 1)
	_update_style_visuals()

func set_weapon(index: int) -> void:
	weapon_index = clampi(index, 0, WEAPON_NAMES.size() - 1)
	_rebuild_weapon()

func style_name() -> String:
	return STYLE_NAMES[style_index]

func weapon_name() -> String:
	return WEAPON_NAMES[weapon_index]

func is_attacking() -> bool:
	return attack_timer > 0.0

func can_act() -> bool:
	return not ko and stun_timer <= 0.0 and dash_timer <= 0.0

func start_attack(kind: int) -> bool:
	if not can_act() or is_attacking():
		return false
	attack_kind = clampi(kind, 0, 2)
	hit_applied = false
	var speed_mult := [1.0, 0.78, 0.90][style_index]
	var base_duration := [0.42, 0.62, 0.78][attack_kind]
	attack_timer = base_duration * speed_mult
	return true

func attack_ready_for_hit() -> bool:
	if hit_applied or attack_timer <= 0.0:
		return false
	var speed_mult := [1.0, 0.78, 0.90][style_index]
	var duration := [0.42, 0.62, 0.78][attack_kind] * speed_mult
	var progress := 1.0 - (attack_timer / duration)
	return progress >= 0.43

func mark_hit() -> void:
	hit_applied = true

func attack_damage() -> float:
	var style_mult := [1.0, 1.22, 0.82][style_index]
	var weapon_mult := [1.0, 1.28, 0.88][weapon_index]
	var base := [9.0, 18.0, 28.0][attack_kind]
	return base * style_mult * weapon_mult

func attack_range() -> float:
	var weapon_range := [1.75, 1.95, 2.10][weapon_index]
	var style_range := [1.0, 0.95, 1.12][style_index]
	return weapon_range * style_range

func receive_hit(damage: float, knockback: float, source_x: float) -> void:
	if ko or invuln_timer > 0.0:
		return
	var final_damage := damage
	if is_blocking:
		final_damage *= 0.25
		stun_timer = max(stun_timer, 0.12)
	else:
		stun_timer = max(stun_timer, 0.22)

	health = max(0.0, health - final_damage)
	damage_flash = 0.16
	invuln_timer = 0.08
	position.x += sign(position.x - source_x) * knockback
	if health <= 0.0:
		ko = true
		attack_timer = 0.0
		is_blocking = false

func dash(direction: float) -> bool:
	if not can_act() or is_attacking():
		return false
	position.x += direction * 2.0
	dash_timer = 0.18
	invuln_timer = 0.20
	return true

func jump() -> bool:
	if ko or stun_timer > 0.0 or position.y > 0.08:
		return false
	jump_velocity = 7.0
	return true

func apply_gravity(delta: float) -> void:
	if position.y > 0.0 or jump_velocity > 0.0:
		jump_velocity -= 18.0 * delta
		position.y += jump_velocity * delta
		if position.y <= 0.0:
			position.y = 0.0
			jump_velocity = 0.0

func _update_style_visuals() -> void:
	if aura_root == null:
		return
	var aura := aura_root.get_node_or_null("Aura") as MeshInstance3D
	if aura == null:
		return
	var style_alpha := [0.028, 0.045, 0.075][style_index]
	var mat := aura.material_override as StandardMaterial3D
	mat.albedo_color = Color(accent.r, accent.g, accent.b, style_alpha)

func _animate(delta: float) -> void:
	if model_root == null:
		return

	var idle := sin(Time.get_ticks_msec() * 0.004) * 0.035
	model_root.position.y = idle

	arm_l.rotation = Vector3.ZERO
	arm_r.rotation = Vector3.ZERO
	leg_l.rotation = Vector3.ZERO
	leg_r.rotation = Vector3.ZERO
	if weapon_root != null:
		weapon_root.rotation = Vector3.ZERO

	if is_blocking:
		arm_l.rotation.z = -0.65
		arm_r.rotation.z = 0.65
		arm_l.rotation.x = -0.25
		arm_r.rotation.x = -0.25

	if is_attacking():
		var speed_mult := [1.0, 0.78, 0.90][style_index]
		var duration := [0.42, 0.62, 0.78][attack_kind] * speed_mult
		var progress := clampf(1.0 - attack_timer / duration, 0.0, 1.0)
		var swing := sin(progress * PI)
		if attack_kind == 0:
			arm_r.rotation.z = -1.15 * swing
			arm_r.rotation.x = -0.70 * swing
		elif attack_kind == 1:
			arm_r.rotation.z = -1.50 * swing
			arm_r.rotation.x = -0.90 * swing
			model_root.rotation.z = -0.10 * swing
		else:
			arm_l.rotation.z = 1.35 * swing
			arm_r.rotation.z = -1.35 * swing
			model_root.scale = Vector3.ONE * (1.0 + 0.06 * swing)

	if damage_flash > 0.0:
		model_root.modulate = Color(2.5, 2.5, 2.5, 1.0)
	else:
		model_root.modulate = Color.WHITE

	if ko:
		model_root.rotation.z = -1.22
		model_root.position.y = -0.05

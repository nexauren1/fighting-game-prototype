extends CharacterBody3D

var fighter_name := "Fighter"
var accent := Color("#58E7FF")
var secondary := Color("#6E7CFF")
var max_health := 100.0
var health := 100.0

var attack_kind := -1
var attack_time := 0.0
var attack_duration := 0.0
var attack_hit_done := false
var stun_time := 0.0
var blocking := false
var knocked_out := false

var visual: Node3D
var body_core: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var head: Node3D
var base_height := 0.0
var move_amount := 0.0
var hit_flash := 0.0
var stance_phase := 0.0
var combo_stage := 0
var combo_window := 0.0
var queued_light := false
var last_was_light := false
var overdrive := 0.0
var enhanced_special := false
var block_timer := 9.0
var style_id := 0
var attack_lunge_done := false
var attack_variant := 0

const ATTACK_DURATION := [0.30, 0.46, 0.62]
const ATTACK_DAMAGE := [8.0, 16.0, 24.0]
const ATTACK_RANGE := [1.55, 1.80, 2.10]
const LUNGE_DISTANCE := [0.28, 0.42, 0.58]

func setup(name_value: String, accent_value: Color, secondary_value: Color, style_value: int = 0) -> void:
	fighter_name = name_value
	accent = accent_value
	secondary = secondary_value
	style_id = clampi(style_value, 0, 2)
	_build_collision()
	_build_model()

func _physics_process(delta: float) -> void:
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - delta)
		if attack_time == 0.0:
			var continue_light := queued_light
			queued_light = false
			attack_kind = -1
			if continue_light:
				_start_attack_internal(0)
	_apply_attack_motion()

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5

	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)
	combo_window = maxf(0.0, combo_window - delta)
	if combo_window <= 0.0 and not is_attacking() and not queued_light:
		combo_stage = 0
	hit_flash = maxf(0.0, hit_flash - delta)
	stance_phase += delta * 2.4
	if blocking:
		block_timer += delta

	velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
	move_and_slide()
	_animate(delta)

func set_style(value: int) -> void:
	style_id = clampi(value, 0, 2)

func get_style_label() -> String:
	if fighter_name == "Rex":
		return ["VANGUARD", "RUSH", "BREAKER"][style_id]
	return ["PHANTOM", "BLADE", "PULSE"][style_id]

func get_style_speed(base_speed: float) -> float:
	return base_speed * [1.0, 1.18, 0.86][style_id]

func get_style_damage(base_damage: float) -> float:
	return base_damage * [1.0, 0.88, 1.22][style_id]

func get_style_reach(base_reach: float) -> float:
	return base_reach * [1.0, 0.96, 1.10][style_id]

func set_move(direction: Vector2, speed: float) -> void:
	if knocked_out or stun_time > 0.0 or is_attacking():
		return
	var dir := Vector3(direction.x, 0.0, direction.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_amount = clampf(dir.length(), 0.0, 1.0)
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.30)

func start_attack(kind: int) -> bool:
	if knocked_out or stun_time > 0.0:
		return false
	if is_attacking():
		if kind == 0 and attack_kind == 0 and attack_time <= 0.20 and combo_window > 0.0:
			queued_light = true
			return true
		return false
	return _start_attack_internal(kind)

func _start_attack_internal(kind: int) -> bool:
	attack_kind = clampi(kind, 0, 2)
	enhanced_special = false
	if attack_kind == 2 and overdrive >= 70.0:
		overdrive -= 70.0
		enhanced_special = true
	if attack_kind == 0:
		if not last_was_light or combo_window <= 0.0:
			combo_stage = 1
		else:
			combo_stage += 1
			if combo_stage > 3:
				combo_stage = 1
		last_was_light = true
		attack_duration = [0.28, 0.32, 0.46][combo_stage - 1]
		combo_window = 0.62
	else:
		combo_stage = 0
		combo_window = 0.0
		last_was_light = false
		attack_duration = ATTACK_DURATION[attack_kind]
	attack_time = attack_duration
	attack_hit_done = false
	attack_lunge_done = false
	attack_variant = (combo_stage + style_id + (1 if fighter_name == "Zara" else 0)) % 3
	return true

func reset_combo() -> void:
	combo_stage = 0
	combo_window = 0.0
	queued_light = false
	last_was_light = false

func get_combo_stage() -> int:
	return combo_stage

func add_overdrive(amount: float) -> void:
	overdrive = clampf(overdrive + amount, 0.0, 100.0)

func consume_overdrive(amount: float) -> bool:
	if overdrive < amount:
		return false
	overdrive -= amount
	return true

func is_special_enhanced() -> bool:
	return enhanced_special

func is_attacking() -> bool:
	return attack_time > 0.0

func attack_hit_ready() -> bool:
	if not is_attacking() or attack_hit_done:
		return false
	var progress := 1.0 - attack_time / attack_duration
	return progress >= 0.45

func consume_attack_hit() -> void:
	attack_hit_done = true

func get_attack_damage() -> float:
	if attack_kind < 0:
		return 0.0
	if attack_kind == 0:
		return [8.0, 10.0, 15.0][maxi(combo_stage - 1, 0)] * (1.0 + overdrive * 0.0015) * [1.0, 0.92, 1.18][style_id]
	return ATTACK_DAMAGE[attack_kind] * (1.12 if overdrive >= 70.0 else 1.0) * [1.0, 0.92, 1.22][style_id]

func get_attack_range() -> float:
	if attack_kind < 0:
		return 0.0
	if attack_kind == 0:
		return [1.50, 1.62, 1.86][maxi(combo_stage - 1, 0)] * [1.0, 0.96, 1.10][style_id]
	return ATTACK_RANGE[attack_kind] * [1.0, 0.96, 1.10][style_id]

func take_hit(damage: float, push_direction: Vector3) -> void:
	if knocked_out:
		return
	if blocking:
		damage *= 0.25
		stun_time = maxf(stun_time, 0.12)
	else:
		stun_time = maxf(stun_time, 0.26)
	health = maxf(0.0, health - damage)
	hit_flash = 0.14
	velocity += push_direction * 1.8
	if health <= 0.0:
		knocked_out = true
		attack_time = 0.0
		blocking = false

func set_block(value: bool) -> void:
	var next_block := value and not knocked_out and not is_attacking() and stun_time <= 0.0
	if next_block and not blocking:
		block_timer = 0.0
	blocking = next_block

func is_perfect_block() -> bool:
	return blocking and block_timer <= 0.16

func trigger_stun(duration: float) -> void:
	stun_time = maxf(stun_time, duration)
	reset_combo()

func _build_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	shape_node.shape = capsule
	shape_node.position.y = 0.90
	add_child(shape_node)

func _build_model() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var dark := _material(Color("#101622"), 0.65, 0.30)
	var dark2 := _material(Color("#253148"), 0.55, 0.25)
	var accent_mat := _material(accent, 0.20, 0.25, accent, 2.5)
	var secondary_mat := _material(secondary, 0.18, 0.28, secondary, 1.8)
	var skin := _material(Color("#B7775B") if fighter_name == "Rex" else Color("#D28A69"), 0.05, 0.50)
	var visor := _material(Color("#E8FAFF"), 0.10, 0.10, accent, 3.0)
	var hair := _material(Color("#0C1220") if fighter_name == "Rex" else Color("#2A1734"), 0.10, 0.42)

	body_core = Node3D.new()
	body_core.name = "BodyCore"
	visual.add_child(body_core)

	_add_box(body_core, "FootL", Vector3(-0.18, 0.10, 0.14), Vector3(0.30, 0.16, 0.52), secondary_mat)
	_add_box(body_core, "FootR", Vector3(0.18, 0.10, 0.14), Vector3(0.30, 0.16, 0.52), secondary_mat)
	leg_l = _add_limb(body_core, "LegL", Vector3(-0.18, 0.43, 0), 0.13, 0.63, dark)
	leg_r = _add_limb(body_core, "LegR", Vector3(0.18, 0.43, 0), 0.13, 0.63, dark)
	_add_box(body_core, "KneeL", Vector3(-0.18, 0.73, 0.04), Vector3(0.32, 0.18, 0.32), secondary_mat)
	_add_box(body_core, "KneeR", Vector3(0.18, 0.73, 0.04), Vector3(0.32, 0.18, 0.32), secondary_mat)
	_add_box(body_core, "Torso", Vector3(0, 1.25, 0), Vector3(0.82, 0.82, 0.50), dark)
	_add_box(body_core, "Chest", Vector3(0, 1.42, 0.27), Vector3(0.58, 0.34, 0.10), accent_mat)
	_add_box(body_core, "Core", Vector3(0, 1.30, 0.33), Vector3(0.25, 0.15, 0.07), visor)
	_add_box(body_core, "Waist", Vector3(0, 0.95, 0.25), Vector3(0.72, 0.12, 0.10), secondary_mat)
	_add_box(body_core, "BeltFront", Vector3(0, 1.00, 0.34), Vector3(0.64, 0.11, 0.06), accent_mat)
	_add_box(body_core, "ChestLeft", Vector3(-0.24, 1.50, 0.30), Vector3(0.24, 0.28, 0.09), secondary_mat, Vector3(0, -10, -4))
	_add_box(body_core, "ChestRight", Vector3(0.24, 1.50, 0.30), Vector3(0.24, 0.28, 0.09), secondary_mat, Vector3(0, 10, 4))

	_add_sphere(body_core, "ShoulderL", Vector3(-0.52, 1.52, 0), 0.16, accent_mat)
	_add_sphere(body_core, "ShoulderR", Vector3(0.52, 1.52, 0), 0.16, accent_mat)
	arm_l = _add_limb(body_core, "ArmL", Vector3(-0.53, 1.21, 0), 0.12, 0.58, dark2)
	arm_r = _add_limb(body_core, "ArmR", Vector3(0.53, 1.21, 0), 0.12, 0.58, dark2)
	_add_box(body_core, "GloveL", Vector3(-0.54, 0.91, 0.05), Vector3(0.24, 0.28, 0.26), accent_mat)
	_add_box(body_core, "GloveR", Vector3(0.54, 0.91, 0.05), Vector3(0.24, 0.28, 0.26), accent_mat)
	_add_box(body_core, "ForearmL", Vector3(-0.54, 1.05, 0.11), Vector3(0.18, 0.24, 0.30), secondary_mat, Vector3(0, 0, -10))
	_add_box(body_core, "ForearmR", Vector3(0.54, 1.05, 0.11), Vector3(0.18, 0.24, 0.30), secondary_mat, Vector3(0, 0, 10))
	_add_box(body_core, "ShinL", Vector3(-0.18, 0.43, 0.10), Vector3(0.18, 0.42, 0.08), secondary_mat)
	_add_box(body_core, "ShinR", Vector3(0.18, 0.43, 0.10), Vector3(0.18, 0.42, 0.08), secondary_mat)

	_add_cylinder(body_core, "Neck", Vector3(0, 1.73, 0), 0.12, 0.16, skin)
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.99, 0)
	body_core.add_child(head)
	_add_sphere(head, "HeadMesh", Vector3.ZERO, 0.28, skin)
	_add_box(head, "Helmet", Vector3(0, 0.13, -0.02), Vector3(0.46, 0.18, 0.40), hair)
	_add_box(head, "Visor", Vector3(0, 0.01, 0.25), Vector3(0.40, 0.10, 0.04), visor)

	if fighter_name == "Rex":
		_add_box(body_core, "BackUnit", Vector3(0, 1.50, -0.33), Vector3(0.16, 0.55, 0.10), secondary_mat, Vector3(-12, 0, 0))
		_add_box(body_core, "ShoulderMark", Vector3(0.63, 1.52, 0), Vector3(0.11, 0.32, 0.18), secondary_mat)
	else:
		_add_box(body_core, "HairBand", Vector3(0, 1.98, -0.24), Vector3(0.62, 0.12, 0.08), hair)
		_add_box(body_core, "Sash", Vector3(0, 1.08, 0.31), Vector3(0.58, 0.06, 0.08), accent_mat)
		_add_box(body_core, "HipGuardL", Vector3(-0.30, 0.92, 0.17), Vector3(0.14, 0.30, 0.20), secondary_mat, Vector3(0, 0, -12))
		_add_box(body_core, "HipGuardR", Vector3(0.30, 0.92, 0.17), Vector3(0.14, 0.30, 0.20), secondary_mat, Vector3(0, 0, 12))

func _apply_attack_motion() -> void:
	if not is_attacking() or attack_lunge_done:
		return
	var progress := 1.0 - attack_time / attack_duration
	if progress < 0.28:
		var lunge := LUNGE_DISTANCE[attack_kind]
		var direction := -global_transform.basis.z.normalized()
		global_position += direction * (lunge * 0.34)
		attack_lunge_done = true

func _animate(_delta: float) -> void:
	if visual == null:
		return

	var t := Time.get_ticks_msec() * 0.004
	visual.position.y = sin(t) * 0.025
	visual.rotation.z = 0.0
	body_core.rotation = Vector3.ZERO
	body_core.scale = Vector3.ONE

	if knocked_out:
		body_core.rotation.z = -1.15
		body_core.rotation.x = 0.22
		visual.position.y = -0.18
		return

	if blocking:
		arm_l.rotation.z = 0.72
		arm_r.rotation.z = -0.72
		arm_l.rotation.x = -0.40
		arm_r.rotation.x = -0.40
		body_core.scale = Vector3(0.96, 1.02, 0.96)
	elif is_attacking():
		var progress := clampf(1.0 - attack_time / attack_duration, 0.0, 1.0)
		var swing := sin(progress * PI)
		var windup := minf(progress / 0.22, 1.0)
		if attack_kind == 0:
			if fighter_name == "Rex":
				arm_r.rotation.z = lerp(0.15, -1.45, windup) * swing
				arm_r.rotation.x = lerp(-0.15, -0.55, windup) * swing
				arm_l.rotation.z = -0.18 * swing
			else:
				arm_l.rotation.z = lerp(-0.10, 1.35, windup) * swing
				arm_l.rotation.x = lerp(-0.20, -0.50, windup) * swing
				arm_r.rotation.z = -0.24 * swing
			body_core.rotation.y = (0.10 if attack_variant == 1 else -0.08) * swing
		elif attack_kind == 1:
			body_core.rotation.y = (-0.24 if fighter_name == "Rex" else 0.24) * swing
			if fighter_name == "Zara":
				leg_r.rotation.x = -1.05 * swing
				leg_l.rotation.x = 0.38 * swing
				arm_l.rotation.z = 0.72 * swing
				arm_r.rotation.z = -1.12 * swing
			else:
				arm_r.rotation.z = -1.72 * swing
				arm_r.rotation.x = -0.72 * swing
				arm_l.rotation.z = 0.52 * swing
			body_core.scale = Vector3.ONE * (1.0 + 0.06 * swing)
		else:
			body_core.rotation.y = 0.30 * sin(progress * PI)
			arm_l.rotation.z = 1.25 * swing
			arm_r.rotation.z = -1.25 * swing
			arm_l.rotation.x = -0.45 * swing
			arm_r.rotation.x = -0.55 * swing
			if fighter_name == "Rex":
				body_core.scale = Vector3.ONE * (1.0 + 0.11 * swing)
			else:
				body_core.scale = Vector3(1.0 + 0.05 * swing, 1.0 + 0.13 * swing, 1.0 + 0.05 * swing)
	elif stun_time > 0.0:
		var recoil := sin(stun_time * 24.0) * 0.10
		body_core.rotation.x = recoil
		body_core.rotation.y = recoil * 0.7
		arm_l.rotation.z = 0.95
		arm_r.rotation.z = -0.95
		leg_l.rotation.x = -0.10
		leg_r.rotation.x = 0.12
	elif move_amount > 0.1:
		var step := sin(t * (4.2 if style_id == 1 else 3.2)) * 0.15
		leg_l.rotation.x = step
		leg_r.rotation.x = -step
		arm_l.rotation.x = -step * 0.8
		arm_r.rotation.x = step * 0.8
		if fighter_name == "Zara":
			body_core.rotation.y = sin(t * 2.0) * 0.035
	else:
		var bounce := sin(stance_phase * (1.45 if style_id == 1 else 1.0)) * 0.035
		body_core.position.y = bounce
		body_core.rotation.x = -0.035
		arm_l.rotation.z = 0.28 + sin(stance_phase) * 0.05
		arm_r.rotation.z = -0.42 - sin(stance_phase) * 0.05
		arm_l.rotation.x = -0.18
		arm_r.rotation.x = -0.28
		leg_l.rotation.x = -0.04
		leg_r.rotation.x = 0.05

func _material(color: Color, metallic: float, roughness: float, emission_color: Color = Color.WHITE, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material

func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot
	parent.add_child(node)
	return node

func _add_limb(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = pos
	parent.add_child(node)
	_add_box(node, "Segment", Vector3.ZERO, Vector3(radius * 2.0, height, radius * 2.0), material)
	return node

func _add_sphere(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 18
	mesh.rings = 10
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node

func _add_cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node

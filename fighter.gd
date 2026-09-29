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

const ATTACK_DURATION := [0.30, 0.46, 0.62]
const ATTACK_DAMAGE := [8.0, 16.0, 24.0]
const ATTACK_RANGE := [1.55, 1.80, 2.10]

func setup(name_value: String, accent_value: Color, secondary_value: Color) -> void:
	fighter_name = name_value
	accent = accent_value
	secondary = secondary_value
	_build_collision()
	_build_model()

func _physics_process(delta: float) -> void:
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - delta)
		if attack_time == 0.0:
			attack_kind = -1
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5

	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)

	velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
	move_and_slide()
	_animate(delta)

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
	if knocked_out or stun_time > 0.0 or is_attacking():
		return false
	attack_kind = clampi(kind, 0, 2)
	attack_duration = ATTACK_DURATION[attack_kind]
	attack_time = attack_duration
	attack_hit_done = false
	return true

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
	return ATTACK_DAMAGE[attack_kind]

func get_attack_range() -> float:
	if attack_kind < 0:
		return 0.0
	return ATTACK_RANGE[attack_kind]

func take_hit(damage: float, push_direction: Vector3) -> void:
	if knocked_out:
		return
	if blocking:
		damage *= 0.25
		stun_time = maxf(stun_time, 0.12)
	else:
		stun_time = maxf(stun_time, 0.26)
	health = maxf(0.0, health - damage)
	velocity += push_direction * 1.8
	if health <= 0.0:
		knocked_out = true
		attack_time = 0.0
		blocking = false

func set_block(value: bool) -> void:
	blocking = value and not knocked_out and not is_attacking() and stun_time <= 0.0

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

	_add_sphere(body_core, "ShoulderL", Vector3(-0.52, 1.52, 0), 0.16, accent_mat)
	_add_sphere(body_core, "ShoulderR", Vector3(0.52, 1.52, 0), 0.16, accent_mat)
	arm_l = _add_limb(body_core, "ArmL", Vector3(-0.53, 1.21, 0), 0.12, 0.58, dark2)
	arm_r = _add_limb(body_core, "ArmR", Vector3(0.53, 1.21, 0), 0.12, 0.58, dark2)
	_add_box(body_core, "GloveL", Vector3(-0.54, 0.91, 0.05), Vector3(0.24, 0.28, 0.26), accent_mat)
	_add_box(body_core, "GloveR", Vector3(0.54, 0.91, 0.05), Vector3(0.24, 0.28, 0.26), accent_mat)

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
		visual.position.y = -0.18
		return

	if blocking:
		arm_l.rotation.z = 0.65
		arm_r.rotation.z = -0.65
		body_core.scale = Vector3(0.96, 1.02, 0.96)
	elif is_attacking():
		var progress := clampf(1.0 - attack_time / attack_duration, 0.0, 1.0)
		var swing := sin(progress * PI)
		if attack_kind == 0:
			arm_r.rotation.z = -1.20 * swing
			arm_r.rotation.x = -0.45 * swing
		elif attack_kind == 1:
			arm_r.rotation.z = -1.55 * swing
			arm_r.rotation.x = -0.80 * swing
			body_core.rotation.z = -0.06 * swing
		else:
			arm_l.rotation.z = 1.20 * swing
			arm_r.rotation.z = -1.20 * swing
			body_core.rotation.z = -0.10 * swing
			body_core.scale = Vector3.ONE * (1.0 + 0.06 * swing)
	elif move_amount > 0.1:
		var step := sin(t * 3.0) * 0.12
		leg_l.rotation.x = step
		leg_r.rotation.x = -step
		arm_l.rotation.x = -step * 0.7
		arm_r.rotation.x = step * 0.7
	else:
		leg_l.rotation.x = 0.0
		leg_r.rotation.x = 0.0
		arm_l.rotation.z = 0.0
		arm_r.rotation.z = 0.0

func _material(color: Color, metallic: float, roughness: float, emission_color: Color = Color.WHITE, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
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

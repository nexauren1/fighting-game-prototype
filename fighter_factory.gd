class_name FighterFactory
extends RefCounted

static func create_fighter(fighter_name: String, accent: Color, secondary: Color) -> Node3D:
	var root := Node3D.new()
	root.name = fighter_name
	root.set_meta("display_name", fighter_name)
	root.set_meta("accent", accent)
	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)

	var dark := _material(Color("#0D121D"), 0.65, 0.28)
	var dark2 := _material(Color("#202A3E"), 0.60, 0.24)
	var metal := _material(Color("#566579"), 0.86, 0.20)
	var accent_m := _material(accent, 0.28, 0.24, accent, 2.4)
	var secondary_m := _material(secondary, 0.25, 0.28, secondary, 1.9)
	var visor := _material(Color("#DFF7FF"), 0.10, 0.10, accent, 3.0)
	var skin := _material(Color("#B97958") if fighter_name == "Rex" else Color("#D08F6B"), 0.02, 0.48)
	var hair := _material(Color("#101426") if fighter_name == "Rex" else Color("#24162F"), 0.12, 0.40)

	_add_box(visual, "Foot_L", Vector3(-0.18, 0.10, 0.18), Vector3(0.31, 0.16, 0.54), secondary_m)
	_add_box(visual, "Foot_R", Vector3(0.18, 0.10, 0.18), Vector3(0.31, 0.16, 0.54), secondary_m)
	_add_capsule(visual, "Leg_L", Vector3(-0.18, 0.43, 0.0), 0.13, 0.62, dark)
	_add_capsule(visual, "Leg_R", Vector3(0.18, 0.43, 0.0), 0.13, 0.62, dark)
	_add_box(visual, "Knee_L", Vector3(-0.18, 0.73, 0.03), Vector3(0.34, 0.18, 0.34), metal)
	_add_box(visual, "Knee_R", Vector3(0.18, 0.73, 0.03), Vector3(0.34, 0.18, 0.34), metal)

	_add_capsule(visual, "Pelvis", Vector3(0, 0.90, 0), 0.34, 0.48, dark2)
	_add_box(visual, "Torso", Vector3(0, 1.28, 0), Vector3(0.82, 0.86, 0.48), dark)
	_add_box(visual, "ChestPlate", Vector3(0, 1.43, 0.26), Vector3(0.64, 0.38, 0.12), accent_m)
	_add_box(visual, "Core", Vector3(0, 1.34, 0.33), Vector3(0.45, 0.18, 0.09), visor)
	_add_box(visual, "WaistLight", Vector3(0, 1.01, 0.25), Vector3(0.90, 0.08, 0.10), secondary_m)

	_add_sphere(visual, "Shoulder_L", Vector3(-0.54, 1.55, 0), 0.17, accent_m)
	_add_sphere(visual, "Shoulder_R", Vector3(0.54, 1.55, 0), 0.17, accent_m)
	_add_capsule(visual, "Arm_L", Vector3(-0.54, 1.24, 0), 0.12, 0.58, dark2)
	_add_capsule(visual, "Arm_R", Vector3(0.54, 1.24, 0), 0.12, 0.58, dark2)
	_add_box(visual, "Gauntlet_L", Vector3(-0.56, 0.95, 0.03), Vector3(0.25, 0.34, 0.30), accent_m)
	_add_box(visual, "Gauntlet_R", Vector3(0.56, 0.95, 0.03), Vector3(0.25, 0.34, 0.30), accent_m)
	_add_box(visual, "Knuckle_L", Vector3(-0.56, 0.76, 0.19), Vector3(0.17, 0.18, 0.20), metal)
	_add_box(visual, "Knuckle_R", Vector3(0.56, 0.76, 0.19), Vector3(0.17, 0.18, 0.20), metal)

	_add_cylinder(visual, "Neck", Vector3(0, 1.76, 0), 0.13, 0.16, skin)
	_add_sphere(visual, "Head", Vector3(0, 2.02, 0), 0.29, skin)
	_add_box(visual, "Helmet", Vector3(0, 2.16, 0), Vector3(0.44, 0.18, 0.40), dark2)
	_add_box(visual, "Visor", Vector3(0, 2.05, 0.26), Vector3(0.43, 0.11, 0.04), visor)
	_add_box(visual, "VisorCore", Vector3(0, 2.05, 0.285), Vector3(0.18, 0.05, 0.03), accent_m)

	if fighter_name == "Rex":
		_add_box(visual, "BackBlade", Vector3(0, 1.57, -0.35), Vector3(0.13, 0.55, 0.09), metal, Vector3(-0.2,0,0))
		_add_box(visual, "ShoulderSigil", Vector3(0.61, 1.54, -0.02), Vector3(0.18, 0.44, 0.09), secondary_m, Vector3(0,0,0.20))
	else:
		_add_box(visual, "HairBand", Vector3(0, 2.00, -0.21), Vector3(0.74, 0.12, 0.09), hair)
		_add_box(visual, "HairTail", Vector3(0, 1.74, -0.38), Vector3(0.12, 0.60, 0.12), hair, Vector3(-0.18,0,0))
		_add_box(visual, "HipArmor", Vector3(0, 0.96, 0), Vector3(0.72, 0.16, 0.38), secondary_m)
		_add_box(visual, "Sash", Vector3(0, 1.07, 0.31), Vector3(0.58, 0.07, 0.09), accent_m)

	_add_box(visual, "EnergyPlate_L", Vector3(-0.72, 1.33, 0), Vector3(0.05, 0.45, 0.38), accent_m)
	_add_box(visual, "EnergyPlate_R", Vector3(0.72, 1.33, 0), Vector3(0.05, 0.45, 0.38), accent_m)
	_add_box(visual, "CoreLight", Vector3(0, 1.34, 0.39), Vector3(0.16, 0.07, 0.03), accent_m)
	return root

static func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.WHITE, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

static func _add_box(root: Node3D, name: String, pos: Vector3, size: Vector3, material: StandardMaterial3D, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_deg
	root.add_child(node)
	return node

static func _add_sphere(root: Node3D, name: String, pos: Vector3, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	root.add_child(node)
	return node

static func _add_capsule(root: Node3D, name: String, pos: Vector3, radius: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	root.add_child(node)
	return node

static func _add_cylinder(root: Node3D, name: String, pos: Vector3, radius: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	root.add_child(node)
	return node

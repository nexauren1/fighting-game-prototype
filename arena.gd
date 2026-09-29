extends Node3D

const CYAN := Color("#58E7FF")
const PINK := Color("#FF5EC4")
const PURPLE := Color("#B86CFF")

func build() -> void:
	_build_materials()
	_build_floor()
	_build_city()
	_build_props()
	_build_lighting()

var mat_floor: StandardMaterial3D
var mat_city: StandardMaterial3D
var mat_city2: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_cyan: StandardMaterial3D
var mat_pink: StandardMaterial3D
var mat_purple: StandardMaterial3D
var mat_window: StandardMaterial3D

func _build_materials() -> void:
	mat_floor = _mat(Color("#242A35"), 0.55, 0.45)
	mat_city = _mat(Color("#111722"), 0.60, 0.48)
	mat_city2 = _mat(Color("#1B2230"), 0.55, 0.42)
	mat_metal = _mat(Color("#566478"), 0.85, 0.22)
	mat_cyan = _mat(CYAN, 0.18, 0.25, CYAN, 2.8)
	mat_pink = _mat(PINK, 0.18, 0.25, PINK, 2.6)
	mat_purple = _mat(PURPLE, 0.18, 0.28, PURPLE, 2.3)
	mat_window = _mat(Color("#183246"), 0.25, 0.20, Color("#58A6D5"), 0.8)

func _build_floor() -> void:
	_add_box("Ground", Vector3(0, -0.35, 0), Vector3(34, 0.6, 26), mat_floor)
	_add_box("CombatDeck", Vector3(0, 0.08, 0), Vector3(20.5, 0.28, 8.7), mat_metal)
	_add_box("CombatSurface", Vector3(0, 0.25, 0), Vector3(19.5, 0.08, 7.9), mat_floor)

	_add_box("EdgeNorth", Vector3(0, 0.45, -4.05), Vector3(20.0, 0.16, 0.12), mat_pink)
	_add_box("EdgeSouth", Vector3(0, 0.45, 4.05), Vector3(20.0, 0.16, 0.12), mat_cyan)
	_add_box("EdgeWest", Vector3(-9.85, 0.45, 0), Vector3(0.12, 0.16, 7.9), mat_purple)
	_add_box("EdgeEast", Vector3(9.85, 0.45, 0), Vector3(0.12, 0.16, 7.9), mat_purple)

	for x in range(-8, 9, 2):
		_add_box("LineX" + str(x), Vector3(float(x), 0.31, 0), Vector3(0.025, 0.018, 7.2), _mat(Color("#677487"), 0.1, 0.6))
	for z in range(-3, 4, 2):
		_add_box("LineZ" + str(z), Vector3(0, 0.32, float(z)), Vector3(18.0, 0.018, 0.025), _mat(Color("#677487"), 0.1, 0.6))

	_add_box("CenterGlow", Vector3(0, 0.34, 0), Vector3(0.08, 0.02, 5.6), mat_purple)

	_add_static_collision(Vector3(0, -0.10, 0), Vector3(34, 0.50, 26))
	_add_static_collision(Vector3(0, 0.42, -4.12), Vector3(20.0, 0.40, 0.25))
	_add_static_collision(Vector3(0, 0.42, 4.12), Vector3(20.0, 0.40, 0.25))
	_add_static_collision(Vector3(-10.0, 0.42, 0), Vector3(0.25, 0.40, 8.6))
	_add_static_collision(Vector3(10.0, 0.42, 0), Vector3(0.25, 0.40, 8.6))

func _build_city() -> void:
	var heights := [5.5, 8.0, 11.0, 7.0, 13.0, 9.0, 6.5, 12.0, 10.0, 7.5]
	for side in [-1, 1]:
		var z := 10.0 * float(side)
		for i in range(11):
			var x := -15.5 + float(i) * 3.1
			var h := heights[i % heights.size()]
			var w := 2.2 + float(i % 3) * 0.25
			var d := 2.6 + float(i % 2) * 0.3
			var wall := mat_city if (i + side) % 2 == 0 else mat_city2
			_add_box("Building_%s_%s" % [side, i], Vector3(x, h * 0.5, z), Vector3(w, h, d), wall)
			var front_z := z - 0.5 * d if side > 0 else z + 0.5 * d
			for floor_index in range(maxi(2, int(h / 2.0))):
				var y := 1.1 + float(floor_index) * 1.75
				if y > h - 0.4:
					break
				for col in range(3):
					var window_x := x - w * 0.27 + float(col) * w * 0.27
					_add_box("Window", Vector3(window_x, y, front_z - 0.025 if side > 0 else front_z + 0.025), Vector3(w * 0.12, 0.58, 0.035), mat_window)
			if i % 3 == 0:
				_add_box("Roof", Vector3(x, h + 0.13, z), Vector3(w * 0.62, 0.18, d * 0.60), mat_metal)
			if i % 4 == 0:
				_add_box("RoofGlow", Vector3(x, h + 0.25, z), Vector3(w * 0.38, 0.05, d * 0.38), mat_cyan if side < 0 else mat_pink)

func _build_props() -> void:
	for x in [-8.5, -4.2, 4.2, 8.5]:
		_add_box("Pillar", Vector3(x, 1.4, -3.6), Vector3(0.18, 2.4, 0.18), mat_metal)
		_add_box("PillarLight", Vector3(x, 2.65, -3.6), Vector3(0.26, 0.08, 0.26), mat_cyan if x < 0 else mat_pink)

	_add_box("ObstacleA", Vector3(-6.0, 0.58, 1.75), Vector3(2.6, 0.64, 0.70), mat_metal)
	_add_box("ObstacleALight", Vector3(-6.0, 0.93, 1.39), Vector3(2.1, 0.04, 0.05), mat_cyan)
	_add_box("ObstacleB", Vector3(5.0, 0.56, -1.70), Vector3(3.1, 0.58, 0.66), mat_metal)
	_add_box("ObstacleBLight", Vector3(5.0, 0.88, -2.05), Vector3(2.5, 0.04, 0.05), mat_pink)

	for x in [-8.0, -2.7, 2.7, 8.0]:
		_add_box("Planter", Vector3(x, 0.27, 5.0), Vector3(0.9, 0.40, 0.75), mat_metal)
		_add_sphere("Plant", Vector3(x, 0.75, 5.0), 0.45, _mat(Color("#215B4F"), 0.0, 0.8))

	for x in [-9.5, 9.5]:
		_add_box("BillboardPostA", Vector3(x, 2.5, -6.2), Vector3(0.22, 5.0, 0.22), mat_metal)
		_add_box("BillboardPostB", Vector3(x + (1.1 if x < 0 else -1.1), 2.5, -6.2), Vector3(0.22, 5.0, 0.22), mat_metal)
		_add_box("BillboardTop", Vector3(x + (0.55 if x < 0 else -0.55), 4.95, -6.2), Vector3(1.45, 0.18, 0.20), mat_cyan if x < 0 else mat_pink)
		_add_box("Billboard", Vector3(x + (0.55 if x < 0 else -0.55), 4.05, -6.22), Vector3(2.5, 1.45, 0.10), mat_city2)
		_add_box("BillboardGlow", Vector3(x + (0.55 if x < 0 else -0.55), 4.05, -6.30), Vector3(2.05, 1.0, 0.03), mat_cyan if x < 0 else mat_pink)

	for z in [-7.0, 7.0]:
		_add_box("Street", Vector3(0, -0.02, z), Vector3(34, 0.16, 2.8), mat_city)
		for x in range(-15, 16, 3):
			_add_box("StreetMark", Vector3(float(x), 0.08, z), Vector3(1.15, 0.03, 0.07), mat_window)

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = Color("#DDEBFF")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)

	_add_light(Vector3(-7.5, 4.0, -3.0), CYAN, 7.0, 9.0)
	_add_light(Vector3(7.5, 4.0, -3.0), PINK, 7.0, 9.0)
	_add_light(Vector3(0, 5.5, -5.0), PURPLE, 5.0, 11.0)

func _add_light(pos: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	add_child(light)

func _add_static_collision(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)

func _mat(color: Color, metallic: float, roughness: float, emission_color: Color = Color.WHITE, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material

func _add_box(node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	add_child(node)
	return node

func _add_sphere(node_name: String, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 10
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	add_child(node)
	return node

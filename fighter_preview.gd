extends Node3D

@export var accent: Color = Color("#58E7FF")

func _ready() -> void:
	_build_preview()

func _build_preview() -> void:
	var accent_material := StandardMaterial3D.new()
	accent_material.albedo_color = accent
	accent_material.emission_enabled = true
	accent_material.emission = accent

	var dark_material := StandardMaterial3D.new()
	dark_material.albedo_color = Color("#111426")

	_add_box(Vector3(0, 1.15, 0), Vector3(0.72, 1.10, 0.42), accent_material)
	_add_sphere(Vector3(0, 1.91, 0), 0.27, dark_material)
	_add_box(Vector3(0, 1.91, 0.245), Vector3(0.34, 0.10, 0.025), accent_material)

	_add_box(Vector3(-0.52, 1.23, 0), Vector3(0.20, 0.78, 0.20), accent_material)
	_add_box(Vector3(0.52, 1.23, 0), Vector3(0.20, 0.78, 0.20), accent_material)
	_add_sphere(Vector3(-0.52, 0.81, 0), 0.13, accent_material)
	_add_sphere(Vector3(0.52, 0.81, 0), 0.13, accent_material)

	_add_box(Vector3(-0.19, 0.30, 0), Vector3(0.25, 0.80, 0.25), dark_material)
	_add_box(Vector3(0.19, 0.30, 0), Vector3(0.25, 0.80, 0.25), dark_material)
	_add_box(Vector3(-0.19, -0.13, 0.10), Vector3(0.30, 0.16, 0.48), accent_material)
	_add_box(Vector3(0.19, -0.13, 0.10), Vector3(0.30, 0.16, 0.48), accent_material)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 2.2
	light.shadow_enabled = false
	add_child(light)

func _add_box(position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = position
	add_child(part)

func _add_sphere(position: Vector3, radius: float, material: StandardMaterial3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = position
	add_child(part)

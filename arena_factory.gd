class_name ArenaFactory
extends RefCounted

static func build(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "NeonDistrict"
	parent.add_child(root)

	var road := _material(Color("#121821"), 0.72, 0.62)
	var platform := _material(Color("#2A303C"), 0.58, 0.40)
	var metal := _material(Color("#657487"), 0.86, 0.22)
	var cyan := _material(Color("#58E7FF"), 0.20, 0.24, Color("#58E7FF"), 2.7)
	var pink := _material(Color("#FF5EC4"), 0.20, 0.25, Color("#FF5EC4"), 2.5)
	var purple := _material(Color("#B86CFF"), 0.18, 0.28, Color("#B86CFF"), 2.2)
	var white := _material(Color("#D4EEFF"), 0.15, 0.22, Color("#D4EEFF"), 1.2)
	var plant := _material(Color("#245C4F"), 0.0, 0.75)

	_add_box(root,"CityBase",Vector3(0,-0.30,0),Vector3(36,0.55,26),road)
	_add_box(root,"FightDeck",Vector3(0,0.10,0),Vector3(20.5,0.25,9.2),platform)
	_add_box(root,"FightSurface",Vector3(0,0.27,0),Vector3(19.3,0.08,7.8),glass_material())
	for x in [-9.8,9.8]: _add_box(root,"BorderX"+str(x),Vector3(x,0.28,0),Vector3(0.30,0.35,8.7),metal)
	for z in [-4.2,4.2]: _add_box(root,"BorderZ"+str(z),Vector3(0,0.28,z),Vector3(20,0.35,0.30),metal)
	_add_box(root,"NeonFront",Vector3(0,0.46,-3.82),Vector3(19.3,0.05,0.08),cyan)
	_add_box(root,"NeonBack",Vector3(0,0.46,3.82),Vector3(19.3,0.05,0.08),pink)
	_add_cylinder(root,"ArenaCore",Vector3(0,0.43,0),1.35,0.06,purple)
	_add_box(root,"CenterLine",Vector3(0,0.48,0),Vector3(0.10,0.04,5.4),white)

	for x in [-8.6,-4.3,4.3,8.6]:
		_add_box(root,"Pylon"+str(x),Vector3(x,1.55,-3.65),Vector3(0.20,2.5,0.20),metal)
		_add_box(root,"PylonLight"+str(x),Vector3(x,2.75,-3.65),Vector3(0.28,0.06,0.28),cyan if x<0 else pink)

	_obstacle(root,"ObstacleA",Vector3(-6.1,0.58,1.75),Vector3(2.7,0.62,0.74),cyan,metal)
	_obstacle(root,"ObstacleB",Vector3(5.3,0.56,-1.75),Vector3(3.2,0.58,0.70),pink,metal)
	_obstacle(root,"ObstacleC",Vector3(-0.8,0.48,2.30),Vector3(1.6,0.48,0.50),purple,metal)

	for z in [-7.0,7.0]:
		_add_box(root,"Street"+str(z),Vector3(0,0.0,z),Vector3(35,0.15,2.8),road)
		for x in range(-16,17,3):
			_add_box(root,"RoadMark"+str(x)+str(z),Vector3(x,0.09,z),Vector3(1.15,0.03,0.06),white)

	var heights := [6.0,8.5,11.0,7.0,13.0,9.5,6.8,12.0,10.0,7.4]
	for side in [-1,1]:
		var z := float(side)*10.0
		for i in range(11):
			var x := -15.5+float(i)*3.15
			var h := heights[i%heights.size()]
			var w := 2.25+float(i%3)*0.30
			var d := 2.5+float(i%2)*0.45
			_add_building(root,"Building_%s_%s"%[side,i],Vector3(x,h*0.5,z),Vector3(w,h,d),cyan if (i+side)%4==0 else purple if i%3==0 else pink)

	for x in [-9.2,-5.7,5.7,9.2]:
		_add_cylinder(root,"LampPole"+str(x),Vector3(x,1.75,5.0),0.055,3.5,metal)
		_add_box(root,"LampHead"+str(x),Vector3(x,3.40,5.0),Vector3(0.75,0.07,0.10),white)

	for x in [-8.0,-3.0,3.0,8.0]:
		_add_box(root,"Planter"+str(x),Vector3(x,0.25,4.8),Vector3(0.85,0.32,0.72),metal)
		_add_sphere(root,"Plant"+str(x),Vector3(x,0.70,4.8),0.45,plant)

	for x in [-7.0,7.0]:
		_add_box(root,"FrameA"+str(x),Vector3(x,2.8,-6.2),Vector3(0.25,5.6,0.25),metal)
		_add_box(root,"FrameB"+str(x),Vector3(x+1.1,2.8,-6.2),Vector3(0.25,5.6,0.25),metal)
		_add_box(root,"FrameTop"+str(x),Vector3(x+0.55,5.58,-6.2),Vector3(1.35,0.18,0.22),cyan if x<0 else pink)
		_add_box(root,"Billboard"+str(x),Vector3(x+0.55,4.55,-6.35),Vector3(2.60,1.40,0.12),dark_glass())
		_add_box(root,"BillboardGlow"+str(x),Vector3(x+0.55,4.55,-6.43),Vector3(2.15,1.05,0.03),cyan if x<0 else pink)

	return root

static func _add_building(root:Node3D,name:String,pos:Vector3,size:Vector3,light_color:Material)->void:
	var wall:=_material(Color("#121824") if int(abs(pos.x))%2==0 else Color("#1B202B"),0.60,0.42)
	_add_box(root,name,pos,size,wall)
	var front_z:=pos.z+(size.z*-0.5 if pos.z>0.0 else size.z*0.5)
	_add_box(root,name+"_Glass",Vector3(pos.x,pos.y,front_z),Vector3(size.x*0.82,size.y*0.82,0.04),glass_material())
	var floors:=maxi(2,int(size.y/1.9))
	for floor in range(floors):
		var y:=1.1+float(floor)*1.75
		if y>size.y-0.35: break
		for col in [-0.28,0.0,0.28]:
			var window_color:=light_color if (floor+int(abs(pos.x))*2)%3==0 else glass_material()
			_add_box(root,name+"_Window_%s_%s"%[floor,col],Vector3(pos.x+size.x*col,y,front_z-0.03 if pos.z<0 else front_z+0.03),Vector3(size.x*0.13,0.55,0.035),window_color)
	_add_box(root,name+"_Top",Vector3(pos.x,size.y+0.12,pos.z),Vector3(size.x*0.62,0.20,size.z*0.62),metal_material())

static func _obstacle(root:Node3D,name:String,pos:Vector3,size:Vector3,glow:Material,metal:Material)->void:
	_add_box(root,name,pos,size,metal)
	_add_box(root,name+"_Glow",Vector3(pos.x,pos.y+size.y*0.5+0.03,pos.z-size.z*0.5-0.02),Vector3(size.x*0.82,0.04,0.05),glow)

static func _material(color:Color,metallic:float,roughness:float,emission:Color=Color.WHITE,energy:float=0.0)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.metallic=metallic; m.roughness=roughness
	if energy>0.0: m.emission_enabled=true; m.emission=emission; m.emission_energy_multiplier=energy
	return m
static func glass_material()->StandardMaterial3D: return _material(Color("#091928"),0.35,0.14)
static func dark_glass()->StandardMaterial3D: return _material(Color("#07111E"),0.35,0.13)
static func metal_material()->StandardMaterial3D: return _material(Color("#596777"),0.84,0.22)
static func _add_box(root:Node3D,name:String,pos:Vector3,size:Vector3,material:Material)->MeshInstance3D:
	var mesh:=BoxMesh.new(); mesh.size=size
	var node:=MeshInstance3D.new(); node.name=name; node.mesh=mesh; node.material_override=material; node.position=pos; root.add_child(node); return node
static func _add_sphere(root:Node3D,name:String,pos:Vector3,radius:float,material:Material)->MeshInstance3D:
	var mesh:=SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2.0; mesh.radial_segments=18; mesh.rings=10
	var node:=MeshInstance3D.new(); node.name=name; node.mesh=mesh; node.material_override=material; node.position=pos; root.add_child(node); return node
static func _add_cylinder(root:Node3D,name:String,pos:Vector3,radius:float,height:float,material:Material)->MeshInstance3D:
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=20
	var node:=MeshInstance3D.new(); node.name=name; node.mesh=mesh; node.material_override=material; node.position=pos; root.add_child(node); return node

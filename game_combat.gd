extends Node3D

const CYAN:=Color("#58E7FF")
const PINK:=Color("#FF5EC4")
const PURPLE:=Color("#B86CFF")
const WHITE:=Color("#F5F7FF")
const MUTED:=Color("#8B94B7")

var p1:Node3D
var p2:Node3D
var camera:Camera3D
var round_time:=60.0
var over:=false
var message:="READY"
var message_time:=1.0
var p1_hp:=100.0
var p2_hp:=100.0
var p1_style:=0
var p2_style:=0
var p1_attack:=Vector2(-1,0)
var p2_attack:=Vector2(-1,0)
var p1_stun:=0.0
var p2_stun:=0.0
var p1_jump:=0.0
var p2_jump:=0.0
var p1_block:=false
var p2_block:=false
var p1_facing:=1.0
var p2_facing:=-1.0
var p1_bar:ColorRect
var p2_bar:ColorRect
var timer_label:Label
var info1:Label
var info2:Label
var announce:Label

const SPEED:=[5.2,4.0,4.7]
const STYLE_DAMAGE:=[0.9,1.25,1.0]
const DAMAGE:=[9.0,18.0,27.0]
const RANGE:=[1.55,1.80,2.05]
const DUR:=[0.38,0.56,0.72]
const STYLES:=["SWIFT","POWER","PHASE"]

func _ready()->void:
	_setup_world()
	_setup_fighters()
	_setup_hud()

func _process(delta:float)->void:
	if not over:
		message_time=maxf(0.0,message_time-delta)
		round_time=maxf(0.0,round_time-delta)
		p1_stun=maxf(0.0,p1_stun-delta)
		p2_stun=maxf(0.0,p2_stun-delta)
		_update_input(delta)
		_update_jump(p1,p1_jump,delta,1)
		_update_jump(p2,p2_jump,delta,2)
		_check_attacks(delta)
		if round_time<=0.0:
			_finish_time()
	_update_visuals()
	_update_camera(delta)
	_update_hud()

func _input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var k:=event as InputEventKey
	if k.keycode==KEY_ESCAPE:
		get_tree().change_scene_to_file("res://main.tscn")
	elif over and (k.keycode==KEY_ENTER or k.keycode==KEY_KP_ENTER):
		get_tree().reload_current_scene()
	elif k.keycode==KEY_F:
		_attack(1,0)
	elif k.keycode==KEY_G:
		_attack(1,1)
	elif k.keycode==KEY_H:
		_attack(1,2)
	elif k.keycode==KEY_T:
		_dash(1)
	elif k.keycode==KEY_1:
		p1_style=0
	elif k.keycode==KEY_2:
		p1_style=1
	elif k.keycode==KEY_3:
		p1_style=2
	elif k.keycode==KEY_J:
		_attack(2,0)
	elif k.keycode==KEY_K:
		_attack(2,1)
	elif k.keycode==KEY_L:
		_attack(2,2)
	elif k.keycode==KEY_O:
		_dash(2)
	elif k.keycode==KEY_7:
		p2_style=0
	elif k.keycode==KEY_8:
		p2_style=1
	elif k.keycode==KEY_9:
		p2_style=2

func _setup_world()->void:
	var env:=WorldEnvironment.new()
	var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("#02040A")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("#A5BCD9")
	e.ambient_light_energy=0.72
	e.fog_enabled=true
	e.fog_light_color=Color("#12233E")
	e.fog_density=0.012
	e.glow_enabled=true
	e.glow_intensity=0.85
	env.environment=e
	add_child(env)
	ArenaFactory.build(self)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-28,0)
	sun.light_energy=1.15
	sun.light_color=Color("#DCEBFF")
	sun.shadow_enabled=true
	add_child(sun)
	_add_light(Vector3(-7.5,4.0,-3.5),CYAN,8.0,9.0)
	_add_light(Vector3(7.5,4.0,-3.5),PINK,8.0,9.0)
	_add_light(Vector3(0,6.0,-5.0),PURPLE,5.5,12.0)
	camera:=Camera3D.new()
	camera.fov=48
	camera.position=Vector3(0,5.2,14.8)
	camera.current=true
	add_child(camera)
	camera.look_at(Vector3(0,1.25,0),Vector3.UP)

func _add_light(pos:Vector3,color:Color,energy:float,range_value:float)->void:
	var l:=OmniLight3D.new()
	l.position=pos
	l.light_color=color
	l.light_energy=energy
	l.omni_range=range_value
	l.shadow_enabled=true
	add_child(l)

func _setup_fighters()->void:
	var chosen:=int(get_tree().get_meta("selected_fighter",0))
	var rex_first:=chosen==0
	p1=FighterFactory.create_fighter("Rex" if rex_first else "Zara",CYAN if rex_first else PINK,Color("#6E7CFF") if rex_first else Color("#FFB84D"))
	p2=FighterFactory.create_fighter("Zara" if rex_first else "Rex",PINK if rex_first else CYAN,Color("#FFB84D") if rex_first else Color("#6E7CFF"))
	p1.position=Vector3(-3.2,0.35,0)
	p2.position=Vector3(3.2,0.35,0)
	add_child(p1)
	add_child(p2)
	p1_style=0
	p2_style=2

func _update_input(delta:float)->void:
	if not _busy(1):
		var d:=0.0
		if Input.is_physical_key_pressed(KEY_A):
			d-=1.0
		if Input.is_physical_key_pressed(KEY_D):
			d+=1.0
		if d!=0.0:
			p1.position.x=clampf(p1.position.x+d*SPEED[p1_style]*delta,-8.3,8.3)
			p1_facing=signf(d)
		p1_block=Input.is_physical_key_pressed(KEY_R) and p1_attack.x<0
	else:
		p1_block=false
	if not _busy(2):
		var d2:=0.0
		if Input.is_physical_key_pressed(KEY_LEFT):
			d2-=1.0
		if Input.is_physical_key_pressed(KEY_RIGHT):
			d2+=1.0
		if d2!=0.0:
			p2.position.x=clampf(p2.position.x+d2*SPEED[p2_style]*delta,-8.3,8.3)
			p2_facing=signf(d2)
		p2_block=Input.is_physical_key_pressed(KEY_I) and p2_attack.x<0
	else:
		p2_block=false
	if Input.is_physical_key_pressed(KEY_W) and p1.position.y<=0.36:
		p1_jump=7.0
	if Input.is_physical_key_pressed(KEY_UP) and p2.position.y<=0.36:
		p2_jump=7.0

func _busy(player:int)->bool:
	return (p1_attack.x>=0 if player==1 else p2_attack.x>=0) or (p1_stun>0 if player==1 else p2_stun>0) or over

func _update_jump(node:Node3D,jump_value:float,delta:float,player:int)->void:
	var j:=jump_value
	if j>0.0 or node.position.y>0.36:
		j-=18.0*delta
		node.position.y+=j*delta
		if node.position.y<=0.36:
			node.position.y=0.36
			j=0.0
	if player==1:
		p1_jump=j
	else:
		p2_jump=j

func _attack(player:int,kind:int)->void:
	if _busy(player):
		return
	if player==1:
		p1_attack=Vector2(kind,DUR[kind]*[1.0,0.82,0.92][p1_style])
	else:
		p2_attack=Vector2(kind,DUR[kind]*[1.0,0.82,0.92][p2_style])

func _dash(player:int)->void:
	if _busy(player):
		return
	if player==1:
		p1.position.x=clampf(p1.position.x+p1_facing*1.7,-8.3,8.3)
	else:
		p2.position.x=clampf(p2.position.x+p2_facing*1.7,-8.3,8.3)

func _check_attacks(delta:float)->void:
	if p1_attack.x>=0:
		p1_attack.y=maxf(0.0,p1_attack.y-delta)
		if p1_attack.y>0.0:
			_try_hit(1)
	if p2_attack.x>=0:
		p2_attack.y=maxf(0.0,p2_attack.y-delta)
		if p2_attack.y>0.0:
			_try_hit(2)

func _try_hit(player:int)->void:
	var attack:=int(p1_attack.x if player==1 else p2_attack.x)
	var remaining:=float(p1_attack.y if player==1 else p2_attack.y)
	var style:=p1_style if player==1 else p2_style
	var duration:=DUR[attack]*[1.0,0.82,0.92][style]
	var progress:=1.0-remaining/duration
	if progress<0.45:
		return
	if player==1:
		p1_attack.x=-2
	else:
		p2_attack.x=-2
	var attacker:=p1 if player==1 else p2
	var target:=p2 if player==1 else p1
	var distance:=absf(attacker.position.x-target.position.x)
	var facing:=p1_facing if player==1 else p2_facing
	var direction:=signf(target.position.x-attacker.position.x)
	if distance>RANGE[attack] or (direction!=facing and distance>0.25):
		return
	var amount:=DAMAGE[attack]*STYLE_DAMAGE[style]
	if player==1 and p2_block:
		amount*=0.25
	if player==2 and p1_block:
		amount*=0.25
	if player==1:
		p2_hp=maxf(0.0,p2_hp-amount)
		p2_stun=0.12 if p2_block else 0.20
	else:
		p1_hp=maxf(0.0,p1_hp-amount)
		p1_stun=0.12 if p1_block else 0.20
	target.position.x+=direction*[0.12,0.28,0.48][attack]
	message="HIT  %.0f" % amount
	message_time=0.25
	if p1_hp<=0.0:
		_finish("%s WINS" % p2.get_meta("display_name"))
	elif p2_hp<=0.0:
		_finish("%s WINS" % p1.get_meta("display_name"))

func _update_visuals()->void:
	var v1:=p1.get_node_or_null("Visual") as Node3D
	var v2:=p2.get_node_or_null("Visual") as Node3D
	if v1:
		v1.position.y=sin(Time.get_ticks_msec()*0.004)*0.025
		v1.rotation=Vector3.ZERO
	if v2:
		v2.position.y=sin(Time.get_ticks_msec()*0.004+0.5)*0.025
		v2.rotation=Vector3.ZERO
	var a:=int(p1_attack.x)
	if a>=0 and v1:
		v1.rotation.z=-0.10*sin(clampf(1.0-float(p1_attack.y)/DUR[a],0.0,1.0)*PI)
	var b:=int(p2_attack.x)
	if b>=0 and v2:
		v2.rotation.z=0.10*sin(clampf(1.0-float(p2_attack.y)/DUR[b],0.0,1.0)*PI)
	if v1:
		v1.scale=Vector3(0.95,1.03,0.95) if p1_block else Vector3.ONE
	if v2:
		v2.scale=Vector3(0.95,1.03,0.95) if p2_block else Vector3.ONE
	if p1_hp<=0.0 and v1:
		v1.rotation.z=-1.2
	if p2_hp<=0.0 and v2:
		v2.rotation.z=1.2

func _update_camera(delta:float)->void:
	var mid:=(p1.position.x+p2.position.x)*0.5
	var sep:=absf(p1.position.x-p2.position.x)
	camera.position=camera.position.lerp(Vector3(mid*0.18,4.8,clampf(14.2+sep*0.45,14.2,17.2)),clampf(delta*3.0,0.0,1.0))
	camera.look_at(Vector3(mid,1.25,0),Vector3.UP)

func _setup_hud()->void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	layer.add_child(_label("NEON DISTRICT // LOCAL VERSUS",Vector2(34,22),Vector2(700,30),18,WHITE))
	layer.add_child(_label("ESC  HOME",Vector2(34,50),Vector2(200,24),11,MUTED))
	layer.add_child(_label("PLAYER 01",Vector2(50,96),Vector2(200,22),12,CYAN))
	info1=_label("",Vector2(50,121),Vector2(520,26),14,WHITE)
	layer.add_child(info1)
	layer.add_child(_label("PLAYER 02",Vector2(970,96),Vector2(200,22),12,PINK))
	info2=_label("",Vector2(760,121),Vector2(470,26),14,WHITE)
	info2.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(info2)
	p1_bar=_bar(layer,Vector2(50,154),CYAN)
	p2_bar=_bar(layer,Vector2(900,154),PINK)
	timer_label=_label("60",Vector2(600,103),Vector2(80,54),32,WHITE)
	timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(timer_label)
	announce=_label("READY",Vector2(280,282),Vector2(720,90),34,WHITE)
	announce.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(announce)
	layer.add_child(_label("P1 A/D W F/G/H R T      |      P2 ←/→ ↑ J/K/L I O      |      1-3 / 7-9 style",Vector2(34,658),Vector2(1210,24),11,MUTED))

func _bar(layer:CanvasLayer,pos:Vector2,color:Color)->ColorRect:
	var bg:=ColorRect.new()
	bg.position=pos
	bg.size=Vector2(330,20)
	bg.color=Color("#111426")
	layer.add_child(bg)
	var fill:=ColorRect.new()
	fill.size=bg.size
	fill.color=color
	bg.add_child(fill)
	return fill

func _update_hud()->void:
	p1_bar.size.x=330.0*p1_hp/100.0
	var w:=330.0*p2_hp/100.0
	p2_bar.position.x=330.0-w
	p2_bar.size.x=w
	timer_label.text=str(int(ceil(round_time)))
	info1.text="%s • %s • %03d HP" % [p1.get_meta("display_name"),STYLES[p1_style],int(p1_hp)]
	info2.text="%s • %s • %03d HP" % [p2.get_meta("display_name"),STYLES[p2_style],int(p2_hp)]
	announce.text=message if message_time>0.0 else ""

func _finish(winner:String)->void:
	if over:
		return
	over=true
	message=winner+"\nENTER = REMATCH   •   ESC = HOME"
	message_time=999.0

func _finish_time()->void:
	if p1_hp==p2_hp:
		_finish("DRAW")
	elif p1_hp>p2_hp:
		_finish("%s WINS" % p1.get_meta("display_name"))
	else:
		_finish("%s WINS" % p2.get_meta("display_name"))

func _label(t:String,pos:Vector2,size:Vector2,fs:int,c:Color)->Label:
	var l:=Label.new()
	l.text=t
	l.position=pos
	l.size=size
	l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",c)
	return l

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
var animation_player: AnimationPlayer
var current_animation := ""

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

const ATTACK_DURATION := [0.30, 0.46, 0.62]
const ATTACK_DAMAGE := [8.0, 16.0, 24.0]
const ATTACK_RANGE := [1.55, 1.80, 2.10]
const LUNGE_DISTANCE := [0.28, 0.42, 0.58]

const RIGGED_ASSETS := {
	"Rex": "res://assets/characters/rex.glb",
	"Zara": "res://assets/characters/zara.glb"
}

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
	return ["PHANTOM", "BLAZE", "PULSE"][style_id]

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
	return ATTACK_DAMAGE[attack_kind] * (1.12 if enhanced_special else 1.0) * [1.0, 0.92, 1.22][style_id]

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
	var old_shape := get_node_or_null("CollisionShape3D")
	if old_shape:
		old_shape.queue_free()
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	shape_node.shape = capsule
	shape_node.position.y = 0.95
	shape_node.name = "CollisionShape3D"
	add_child(shape_node)

func _build_model() -> void:
	var asset_path: String = RIGGED_ASSETS.get(fighter_name, RIGGED_ASSETS["Rex"])
	var packed := load(asset_path) as PackedScene
	if packed == null:
		push_error("Could not load rigged fighter asset: " + asset_path)
		return

	visual = packed.instantiate() as Node3D
	if visual == null:
		push_error("Rigged fighter asset did not instantiate as Node3D: " + asset_path)
		return

	visual.name = "RiggedHumanoid"
	add_child(visual)

	animation_player = _find_animation_player(visual)
	if animation_player == null:
		push_error("No AnimationPlayer found in rigged fighter asset: " + asset_path)
		return

	_configure_animations()
	_play_animation("Idle")

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _configure_animations() -> void:
	if animation_player == null:
		return
	var library_names := animation_player.get_animation_library_list()
	for library_name in library_names:
		var library := animation_player.get_animation_library(library_name)
		for animation_name in library.get_animation_list():
			var animation := library.get_animation(animation_name)
			animation.loop_mode = Animation.LOOP_NONE
	for loop_name in ["Idle", "Walk", "Block"]:
		var animation := _get_animation(loop_name)
		if animation != null:
			animation.loop_mode = Animation.LOOP_LINEAR

func _get_animation(name_value: String) -> Animation:
	if animation_player == null:
		return null
	for library_name in animation_player.get_animation_library_list():
		var library := animation_player.get_animation_library(library_name)
		if library.has_animation(name_value):
			return library.get_animation(name_value)
	return null

func _play_animation(name_value: String) -> void:
	if animation_player == null:
		return
	if _get_animation(name_value) == null:
		name_value = "Idle" if _get_animation("Idle") != null else animation_player.current_animation
	if name_value == "" or name_value == current_animation:
		return
	current_animation = name_value
	animation_player.play(name_value, 0.08)

func _desired_animation() -> String:
	if knocked_out:
		return "KO"
	if blocking:
		return "Block"
	if stun_time > 0.0:
		return "Hit"
	if is_attacking():
		if attack_kind == 0:
			return ["Light1", "Light2", "Light3"][clampi(combo_stage - 1, 0, 2)]
		if attack_kind == 1:
			return "Heavy"
		return "Special"
	if move_amount > 0.10:
		return "Walk"
	return "Idle"

func _apply_attack_motion() -> void:
	if not is_attacking() or attack_lunge_done:
		return
	var progress := 1.0 - attack_time / attack_duration
	if progress < 0.28:
		var lunge: float = LUNGE_DISTANCE[attack_kind]
		var direction := -global_transform.basis.z.normalized()
		global_position += direction * (lunge * 0.34)
		attack_lunge_done = true

func _animate(_delta: float) -> void:
	if visual == null:
		return

	var desired := _desired_animation()
	_play_animation(desired)

	var pulse := 1.0
	if hit_flash > 0.0 and not knocked_out:
		pulse += sin((hit_flash / 0.14) * PI) * 0.06
	visual.scale = Vector3.ONE * pulse

	# Keep generated GLBs visually locked to the arena ground while allowing
	# the skeletal animation to provide all pose changes.
	if not knocked_out:
		visual.position.y = 0.0

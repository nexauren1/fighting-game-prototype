extends Control
signal flicked(direction: Vector2)

var value := Vector2.ZERO
var radius := 88.0
var knob_radius := 38.0
var dead_zone := 0.12
var active := false
var pointer_id := -1
var last_input := Vector2.ZERO
var return_speed := 11.0
var pulse := 0.0
var touch_start_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if not active:
		value = value.lerp(Vector2.ZERO, 1.0 - exp(-return_speed * delta))
	if value.length() < 0.015:
		value = Vector2.ZERO
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not active:
			active = true
			pointer_id = touch.index
			touch_start_time = Time.get_ticks_msec() * 0.001
			_set_value(touch.position)
			accept_event()
		elif not touch.pressed and active and touch.index == pointer_id:
			_release()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if active and drag.index == pointer_id:
			var before := value
			_set_value(drag.position)
			var elapsed := Time.get_ticks_msec() * 0.001 - touch_start_time
			if elapsed < 0.22 and value.length() > 0.82 and before.length() < 0.55:
				flicked.emit(value.normalized())
				touch_start_time = -99.0
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				active = true
				_set_value(mouse.position)
			else:
				_release()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if active:
			_set_value(motion.position)
			accept_event()

func get_vector() -> Vector2:
	return value

func _release() -> void:
	active = false
	pointer_id = -1
	last_input = Vector2.ZERO

func _set_value(point: Vector2) -> void:
	var center := size * 0.5
	var offset := point - center
	var length := offset.length()
	if length > radius:
		offset = offset.normalized() * radius
	var raw := offset / radius
	var magnitude := raw.length()
	if magnitude < dead_zone:
		value = Vector2.ZERO
	else:
		var scaled := (magnitude - dead_zone) / (1.0 - dead_zone)
		scaled = scaled * scaled * (3.0 - 2.0 * scaled)
		value = raw.normalized() * scaled
	last_input = value
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var ring_color := Color("#58E7FF", 0.62 if active else 0.40)
	var knob_color := Color("#58E7FF", 0.32 if active else 0.20)
	var outer_color := Color(0.02, 0.05, 0.10, 0.82)

	draw_circle(center, radius + 12.0, Color("#07101E", 0.45))
	draw_arc(center, radius + 8.0, 0.0, TAU, 64, Color("#7FEFFF", 0.16), 3.0)
	draw_circle(center, radius, outer_color)
	draw_arc(center, radius, 0.0, TAU, 64, ring_color, 3.0)

	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tick_center := center + direction * (radius * 0.72)
		var tick_end := center + direction * (radius * 0.84)
		draw_line(tick_center, tick_end, Color("#B8F7FF", 0.45), 3.0)

	var knob_pos := center + value * radius
	draw_circle(knob_pos, knob_radius + 7.0, Color("#58E7FF", 0.06))
	draw_circle(knob_pos, knob_radius, knob_color)
	draw_arc(knob_pos, knob_radius, 0.0, TAU, 48, Color("#E9FCFF", 0.90), 2.0)

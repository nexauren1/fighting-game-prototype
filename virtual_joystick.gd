extends Control

var value := Vector2.ZERO
var radius := 78.0
var knob_radius := 34.0
var active := false
var pointer_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			active = true
			pointer_id = touch.index
			_set_value(touch.position)
			accept_event()
		elif active and touch.index == pointer_id:
			active = false
			pointer_id = -1
			value = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if active and drag.index == pointer_id:
			_set_value(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			active = mouse.pressed
			if active:
				_set_value(mouse.position)
			else:
				value = Vector2.ZERO
				queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if active:
			_set_value(motion.position)
			accept_event()

func get_vector() -> Vector2:
	return value

func _set_value(point: Vector2) -> void:
	var center := size * 0.5
	var offset := point - center
	var length := offset.length()
	if length > radius:
		offset = offset.normalized() * radius
	value = offset / radius
	if value.length() < 0.14:
		value = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.04, 0.08, 0.14, 0.78))
	draw_arc(center, radius, 0.0, TAU, 48, Color("#58E7FF", 0.45), 3.0)
	draw_circle(center + value * radius, knob_radius, Color("#58E7FF", 0.20))
	draw_arc(center + value * radius, knob_radius, 0.0, TAU, 32, Color("#D6F9FF", 0.90), 2.0)

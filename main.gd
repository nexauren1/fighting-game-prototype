extends Control

const BG_TOP := Color("#070817")
const BG_BOTTOM := Color("#11102A")
const CYAN := Color("#58E7FF")
const BLUE := Color("#6E7CFF")
const PURPLE := Color("#B86CFF")
const PINK := Color("#FF5EC4")
const TEXT_MAIN := Color("#F5F7FF")
const TEXT_MUTED := Color("#8D95B7")

var play_button: Button
var notice: Label
var pulse := 0.0

func _ready() -> void:
	set_process(true)
	_build_ui()
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	# Deep background
	draw_rect(Rect2(Vector2.ZERO, size), BG_TOP)

	# Layered glows
	_draw_glow(Vector2(size.x * 0.18, size.y * 0.20), 260.0, Color(CYAN, 0.075))
	_draw_glow(Vector2(size.x * 0.84, size.y * 0.30), 300.0, Color(PURPLE, 0.08))
	_draw_glow(Vector2(size.x * 0.53, size.y * 0.82), 360.0, Color(PINK, 0.055))

	# Subtle perspective floor
	var floor_y := size.y * 0.79
	for i in range(9):
		var y := floor_y + pow(float(i) / 8.0, 1.65) * size.y * 0.22
		draw_line(Vector2(size.x * 0.08, y), Vector2(size.x * 0.92, y), Color(0.35, 0.55, 1.0, 0.08), 1.0)

	for i in range(-8, 9):
		var x := size.x * 0.5 + i * size.x * 0.055
		draw_line(
			Vector2(size.x * 0.5 + i * size.x * 0.012, floor_y),
			Vector2(x, size.y),
			Color(0.3, 0.55, 1.0, 0.06),
			1.0
		)

	# Neon frame accents
	var frame := Rect2(34, 34, size.x - 68, size.y - 68)
	draw_line(frame.position, frame.position + Vector2(180, 0), Color(CYAN, 0.65), 2.0)
	draw_line(frame.position, frame.position + Vector2(0, 110), Color(CYAN, 0.25), 2.0)
	draw_line(Vector2(frame.end.x - 180, frame.position.y), Vector2(frame.end.x, frame.position.y), Color(PURPLE, 0.65), 2.0)
	draw_line(Vector2(frame.end.x, frame.end.y - 110), frame.end, Color(PURPLE, 0.25), 2.0)

	# Character silhouettes for the concept prototype
	_draw_character(Vector2(size.x * 0.18, size.y * 0.53), 1.0, CYAN, false)
	_draw_character(Vector2(size.x * 0.82, size.y * 0.53), 1.0, PINK, true)

func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	for i in range(10, 0, -1):
		var r := radius * (float(i) / 10.0)
		var c := Color(color.r, color.g, color.b, color.a * (1.0 - float(i - 1) / 10.0))
		draw_circle(center, r, c)

func _draw_character(base: Vector2, scale_value: float, accent: Color, mirror: bool) -> void:
	var dir := -1.0 if mirror else 1.0
	var bob := sin(pulse * 2.0) * 3.0

	var glow_color := Color(accent.r, accent.g, accent.b, 0.09)
	for r in [130.0, 95.0, 65.0]:
		draw_circle(base + Vector2(0, bob), r * scale_value, glow_color)

	# Body
	var head := base + Vector2(0, -118 + bob)
	var chest := base + Vector2(0, -46 + bob)
	var hip := base + Vector2(8 * dir, 30 + bob)
	var shoulder_l := chest + Vector2(-52 * dir, 4)
	var shoulder_r := chest + Vector2(52 * dir, -4)
	var hand_l := base + Vector2(-96 * dir, 42 + bob)
	var hand_r := base + Vector2(102 * dir, 18 + bob)
	var foot_l := base + Vector2(-46 * dir, 155)
	var foot_r := base + Vector2(58 * dir, 146)

	# Silhouette strokes
	_draw_segment(head, chest + Vector2(0, -14), 44.0, accent)
	_draw_segment(shoulder_l, hand_l, 17.0, accent)
	_draw_segment(shoulder_r, hand_r, 17.0, accent)
	_draw_segment(hip, foot_l, 21.0, accent)
	_draw_segment(hip, foot_r, 21.0, accent)

	# Head
	draw_circle(head, 24.0, Color("#0E1021"))
	draw_circle(head, 22.0, Color(accent.r, accent.g, accent.b, 0.18))
	draw_arc(head, 22.0, 0.15, 5.95, 32, Color(accent.r, accent.g, accent.b, 0.8), 2.0)

	# Core highlight
	draw_line(chest + Vector2(-15, -8), chest + Vector2(16, 10), Color(accent.r, accent.g, accent.b, 0.75), 3.0)

func _draw_segment(a: Vector2, b: Vector2, width: float, accent: Color) -> void:
	draw_line(a, b, Color("#090B18"), width + 10.0, true)
	draw_line(a, b, Color(accent.r, accent.g, accent.b, 0.18), width + 5.0, true)
	draw_line(a, b, accent, width, true)

func _build_ui() -> void:
	var margin := 72.0

	# Top-left brand mark
	var brand := Label.new()
	brand.text = "✦  HUNTER'S RISE"
	brand.position = Vector2(margin, 58)
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", TEXT_MAIN)
	add_child(brand)

	var version := Label.new()
	version.text = "PROTOTYPE  •  0.1"
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.position = Vector2(-210, 62)
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", TEXT_MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	# Main title
	var title := Label.new()
	title.text = "HUNTER'S\nRISE"
	title.position = Vector2(margin, 155)
	title.size = Vector2(610, 170)
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_constant_override("line_spacing", -8)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THE BATTLE BEGINS"
	subtitle.position = Vector2(margin + 4, 326)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", CYAN)
	add_child(subtitle)

	var description := Label.new()
	description.text = "A fast, stylish fighting prototype.\nChoose your hunter and enter the arena."
	description.position = Vector2(margin + 4, 362)
	description.size = Vector2(360, 60)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", TEXT_MUTED)
	add_child(description)

	# Main CTA
	play_button = _make_button("PLAY", Vector2(margin, 470), Vector2(260, 68), CYAN)
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

	var select_button := _make_button("CHARACTERS", Vector2(margin, 548), Vector2(260, 54), PURPLE)
	select_button.pressed.connect(_on_characters_pressed)
	add_child(select_button)

	var settings_button := _make_button("SETTINGS", Vector2(margin, 612), Vector2(260, 46), Color("#3D456D"))
	settings_button.pressed.connect(_on_settings_pressed)
	add_child(settings_button)

	# Right-side panel
	var panel := ColorRect.new()
	panel.position = Vector2(get_viewport_rect().size.x - 360, 150)
	panel.size = Vector2(260, 270)
	panel.color = Color(0.04, 0.05, 0.11, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var p_title := Label.new()
	p_title.text = "NEXT MATCH"
	p_title.position = Vector2(24, 20)
	p_title.add_theme_font_size_override("font_size", 13)
	p_title.add_theme_color_override("font_color", TEXT_MUTED)
	panel.add_child(p_title)

	var p_text := Label.new()
	p_text.text = "NEON DISTRICT"
	p_text.position = Vector2(24, 54)
	p_text.add_theme_font_size_override("font_size", 26)
	p_text.add_theme_color_override("font_color", TEXT_MAIN)
	panel.add_child(p_text)

	var line := ColorRect.new()
	line.position = Vector2(24, 100)
	line.size = Vector2(70, 3)
	line.color = CYAN
	panel.add_child(line)

	var p_info := Label.new()
	p_info.text = "01  ARENA\n\n02  HUNTERS\n\n03  FIGHT"
	p_info.position = Vector2(24, 122)
	p_info.add_theme_font_size_override("font_size", 14)
	p_info.add_theme_color_override("font_color", TEXT_MUTED)
	panel.add_child(p_info)

	# Bottom status
	var footer := Label.new()
	footer.text = "ARROW KEYS / A D  •  SPACE: JUMP  •  ATTACK: J"
	footer.position = Vector2(margin, get_viewport_rect().size.y - 58)
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.55, 0.6, 0.78, 0.8))
	add_child(footer)

	notice = Label.new()
	notice.text = ""
	notice.position = Vector2(get_viewport_rect().size.x - 430, get_viewport_rect().size.y - 72)
	notice.size = Vector2(350, 40)
	notice.add_theme_font_size_override("font_size", 14)
	notice.add_theme_color_override("font_color", CYAN)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(notice)

func _make_button(label_text: String, pos: Vector2, size_value: Vector2, accent: Color) -> Button:
	var b := Button.new()
	b.text = label_text
	b.position = pos
	b.size = size_value
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", TEXT_MAIN)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10

	var hover := normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.23)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.95)

	var pressed := hover.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.35)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _on_play_pressed() -> void:
	notice.text = "Arena prototype coming next..."
	# This button is intentionally ready for the Arena scene we will add next.

func _on_characters_pressed() -> void:
	notice.text = "Character Select coming next..."

func _on_settings_pressed() -> void:
	notice.text = "Settings will be added after the first fight prototype."

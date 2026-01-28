extends Control

signal changed
signal cycle_segments_requested
signal decrease_segments_requested

@export var radius: float = 20.0
@export var filled_segments: int = 0

var _button: TextureButton = null
var _press_start_ms: int = 0
var _press_active: bool = false

const FILL_STEPS := 90
const BORDER_COLOR := Color(0.714, 0.125, 0.145)
const BACKGROUND_COLOR := Color.WHITE
const FILL_COLOR := Color.BLACK
const LONG_PRESS_MS := 350

func _ready() -> void:
	_resolve_nodes()
	_apply_button_size()
	if is_instance_valid(_button) and not _button.gui_input.is_connected(_on_button_gui_input):
		_button.gui_input.connect(_on_button_gui_input)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_button_size()
		queue_redraw()

func set_filled_segments(value: int) -> void:
	_set_filled_segments(value)

func get_filled_segments() -> int:
	return filled_segments

func _apply_button_size() -> void:
	_resolve_nodes()
	var diameter := radius * 2.0
	var current_min = max(custom_minimum_size.x, custom_minimum_size.y)
	if current_min > diameter:
		diameter = current_min
	if is_instance_valid(_button):
		var button_min = max(_button.custom_minimum_size.x, _button.custom_minimum_size.y)
		if button_min > diameter:
			diameter = button_min
	custom_minimum_size = Vector2(diameter, diameter)
	if is_instance_valid(_button):
		_button.custom_minimum_size = Vector2(diameter, diameter)
		_button.anchor_left = 0.0
		_button.anchor_top = 0.0
		_button.anchor_right = 1.0
		_button.anchor_bottom = 1.0
		_button.offset_left = 0.0
		_button.offset_top = 0.0
		_button.offset_right = 0.0
		_button.offset_bottom = 0.0

func _get_segments() -> int:
	var node := get_parent()
	while node:
		if node.has_method("get_segments"):
			return max(1, int(node.get_segments()))
		node = node.get_parent()
	return 1

func _set_filled_segments(value: int) -> void:
	var clamped = clamp(value, 0, _get_segments())
	if clamped == filled_segments:
		return
	filled_segments = clamped
	queue_redraw()
	changed.emit()

func _on_button_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_press_start_ms = Time.get_ticks_msec()
		_press_active = true
		return
	if not _press_active:
		return
	_press_active = false
	var elapsed := Time.get_ticks_msec() - _press_start_ms
	if elapsed >= LONG_PRESS_MS:
		decrease_segments_requested.emit()
	else:
		cycle_segments_requested.emit()

func _draw() -> void:
	var segments := _get_segments()
	var filled = clamp(filled_segments, 0, segments)
	var size := get_rect().size
	var draw_radius := radius
	var center := Vector2(radius, radius)
	if size.x > 0.0 and size.y > 0.0:
		draw_radius = min(radius, min(size.x, size.y) * 0.5)
		center = size * 0.5
	draw_circle(center, draw_radius, BACKGROUND_COLOR, true, -1.0, true)
	if segments <= 0:
		draw_circle(center, draw_radius, BORDER_COLOR, false, 3.0, true)
		return
	var step := TAU / float(segments)
	if filled > 0:
		var start_vec := Vector2(0, draw_radius)
		var sub_step := step / float(FILL_STEPS)
		for i in range(filled):
			var points := PackedVector2Array()
			points.append(center)
			var v := start_vec.rotated(step * float(i))
			for _j in range(FILL_STEPS + 1):
				points.append(center + v)
				v = v.rotated(sub_step)
			draw_colored_polygon(points, FILL_COLOR)
	draw_circle(center, draw_radius, BORDER_COLOR, false, 3.0, true)
	var to := center + Vector2(0, draw_radius)
	for _i in range(segments):
		draw_line(center, to, BORDER_COLOR, 3.0, true)
		to = (to - center).rotated(step) + center

func _resolve_nodes() -> void:
	if not is_instance_valid(_button):
		_button = get_node_or_null(NodePath("TextureButton")) as TextureButton
		if _button == null:
			_button = find_child("TextureButton", true, false) as TextureButton

extends HBoxContainer

signal changed
signal removed

@export var min_segments: int = 2
@export var max_segments: int = 8
@export var segments: int = 4

enum CounterType { NONE, PAYLOAD, CHARGE, GRAYWASH, REFRESH, OTHER }

var _label: LineEdit = null
var _draw_counter: Node = null
var _buttons_box: Control = null
var _button_up: TextureButton = null
var _button_down: TextureButton = null
var _delete_button: TextureButton = null

var _pending_state: Dictionary = {}
var _pending_label: String = ""

func _ready() -> void:
	_resolve_nodes()
	if is_instance_valid(_label) and not _label.text_changed.is_connected(_on_label_changed):
		_label.text_changed.connect(_on_label_changed)
	if is_instance_valid(_draw_counter) and _draw_counter.has_signal("changed") and not _draw_counter.changed.is_connected(_on_draw_changed):
		_draw_counter.changed.connect(_on_draw_changed)
	if is_instance_valid(_draw_counter) and _draw_counter.has_signal("cycle_segments_requested") and not _draw_counter.cycle_segments_requested.is_connected(_on_draw_counter_cycle_segments):
		_draw_counter.cycle_segments_requested.connect(_on_draw_counter_cycle_segments)
	if is_instance_valid(_draw_counter) and _draw_counter.has_signal("decrease_segments_requested") and not _draw_counter.decrease_segments_requested.is_connected(_on_draw_counter_decrease_segments):
		_draw_counter.decrease_segments_requested.connect(_on_draw_counter_decrease_segments)
	if is_instance_valid(_button_up) and _button_up.has_signal("button_up") and not _button_up.button_up.is_connected(_on_texture_button_2_pressed):
		_button_up.button_up.connect(_on_texture_button_2_pressed)
	if is_instance_valid(_button_down) and _button_down.has_signal("button_up") and not _button_down.button_up.is_connected(_on_texture_button_pressed_3):
		_button_down.button_up.connect(_on_texture_button_pressed_3)
	if is_instance_valid(_delete_button) and _delete_button.has_signal("pressed") and not _delete_button.pressed.is_connected(_on_texture_button_pressed):
		_delete_button.pressed.connect(_on_texture_button_pressed)
	_apply_pending_state()
	call_deferred("_apply_layout")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout()

func setup(state: Dictionary = {}, fallback_label: String = "") -> void:
	_pending_state = state
	_pending_label = fallback_label
	if is_inside_tree():
		_apply_pending_state()

func set_delete_visible(show: bool) -> void:
	_resolve_nodes()
	if is_instance_valid(_delete_button):
		_delete_button.visible = show

func get_segments() -> int:
	return segments

func set_filled_segments(value: int) -> void:
	_resolve_nodes()
	if is_instance_valid(_draw_counter) and _draw_counter.has_method("set_filled_segments"):
		_draw_counter.set_filled_segments(value)

func get_state() -> Dictionary:
	_resolve_nodes()
	var filled := 0
	if is_instance_valid(_draw_counter) and _draw_counter.has_method("get_filled_segments"):
		filled = _to_int(_draw_counter.get_filled_segments())
	return {
		"name": _label.text if is_instance_valid(_label) else "",
		"segments": segments,
		"filled_segments": filled
	}

func save() -> Dictionary:
	return get_state()

func _apply_pending_state() -> void:
	_resolve_nodes()
	if not is_instance_valid(_label) or not is_instance_valid(_draw_counter):
		return
	if _pending_state.has("name"):
		_label.text = String(_pending_state.get("name", ""))
	elif _pending_label != "":
		_label.text = _pending_label
	_set_segments(_to_int(_pending_state.get("segments", segments)))
	if _draw_counter.has_method("set_filled_segments"):
		_draw_counter.set_filled_segments(_to_int(_pending_state.get("filled_segments", 0)))
	_pending_state = {}

func _set_segments(value: int) -> void:
	_resolve_nodes()
	var clamped = clamp(value, min_segments, max_segments)
	if clamped == segments:
		return
	var prev_segments := segments
	var prev_filled := 0
	if is_instance_valid(_draw_counter) and _draw_counter.has_method("get_filled_segments"):
		prev_filled = _to_int(_draw_counter.get_filled_segments())
	var prev_unfilled = max(prev_segments - prev_filled, 0)
	segments = clamped
	if is_instance_valid(_draw_counter):
		if _draw_counter.has_method("set_filled_segments"):
			var next_filled := prev_filled
			if clamped > prev_segments and _is_payload_counter():
				next_filled = clamp(segments - prev_unfilled, 0, segments)
			else:
				next_filled = clamp(prev_filled, 0, segments)
			_draw_counter.set_filled_segments(next_filled)
		_draw_counter.queue_redraw()
	changed.emit()

func _on_texture_button_pressed() -> void:
	removed.emit()
	queue_free()

func _on_texture_button_2_pressed() -> void:
	_adjust_segments(1)

func _on_texture_button_pressed_3() -> void:
	_adjust_segments(-1)

func _on_label_changed(_text: String) -> void:
	changed.emit()

func _on_draw_changed() -> void:
	changed.emit()

func _on_draw_counter_cycle_segments() -> void:
	_adjust_filled_segments(1)

func _on_draw_counter_decrease_segments() -> void:
	_adjust_filled_segments(-1)

func _adjust_filled_segments(delta: int) -> void:
	_resolve_nodes()
	if not is_instance_valid(_draw_counter):
		return
	if not _draw_counter.has_method("get_filled_segments") or not _draw_counter.has_method("set_filled_segments"):
		return
	var current := _to_int(_draw_counter.get_filled_segments())
	var next := current + delta
	if delta > 0 and current >= segments:
		next = 0
	_draw_counter.set_filled_segments(next)

func _adjust_segments(delta: int) -> void:
	var next := segments + delta
	if next > max_segments:
		next = min_segments
	if next < min_segments:
		next = max_segments
	_set_segments(next)

func _apply_layout() -> void:
	_resolve_nodes()
	alignment = BoxContainer.ALIGNMENT_CENTER
	var draw_size := _get_draw_size()
	if draw_size <= 0.0:
		return
	if _draw_counter is Control:
		var draw_control := _draw_counter as Control
		draw_control.custom_minimum_size = Vector2(draw_size, draw_size)
	if is_instance_valid(_label):
		var label_size := _label.custom_minimum_size
		_label.custom_minimum_size = Vector2(label_size.x, draw_size)
	if is_instance_valid(_buttons_box) and _buttons_box != self:
		var box_size := _buttons_box.custom_minimum_size
		_buttons_box.custom_minimum_size = Vector2(box_size.x, draw_size)
		var separation := 0.0
		if _buttons_box is BoxContainer:
			separation = float((_buttons_box as BoxContainer).get_theme_constant("separation"))
		var arrow_size = max(0.0, (draw_size - separation) * 0.5)
		if is_instance_valid(_button_up):
			_button_up.custom_minimum_size = Vector2(arrow_size, arrow_size)
		if is_instance_valid(_button_down):
			_button_down.custom_minimum_size = Vector2(arrow_size, arrow_size)
	if is_instance_valid(_delete_button):
		var delete_size := _delete_button.custom_minimum_size
		_delete_button.custom_minimum_size = Vector2(delete_size.x, draw_size)

func _is_payload_counter() -> bool:
	if not has_meta("counter_type"):
		return false
	return _to_int(get_meta("counter_type")) == CounterType.PAYLOAD

func _get_draw_size() -> float:
	var draw_size := 0.0
	if _draw_counter is Control:
		var ctrl := _draw_counter as Control
		draw_size = max(ctrl.custom_minimum_size.x, ctrl.custom_minimum_size.y)
		if draw_size <= 0.0:
			draw_size = max(ctrl.size.x, ctrl.size.y)
	if is_instance_valid(_draw_counter):
		var radius_value = _draw_counter.get("radius")
		if typeof(radius_value) == TYPE_INT or typeof(radius_value) == TYPE_FLOAT:
			draw_size = max(draw_size, float(radius_value) * 2.0)
	return draw_size

func _resolve_nodes() -> void:
	if not is_instance_valid(_draw_counter):
		_draw_counter = get_node_or_null(NodePath("DrawCounter"))
		if _draw_counter == null:
			_draw_counter = find_child("DrawCounter", true, false)
	if not is_instance_valid(_label):
		_label = get_node_or_null(NodePath("Label")) as LineEdit
		if _label == null:
			_label = find_child("Label", true, false) as LineEdit
	if not is_instance_valid(_buttons_box):
		_buttons_box = get_node_or_null(NodePath("VBoxContainer")) as Control
		if _buttons_box == null:
			_buttons_box = find_child("VBoxContainer", true, false) as Control
	if is_instance_valid(_buttons_box):
		if not is_instance_valid(_button_up):
			_button_up = _buttons_box.get_node_or_null(NodePath("TextureButton")) as TextureButton
		if not is_instance_valid(_button_down):
			_button_down = _buttons_box.get_node_or_null(NodePath("TextureButton2")) as TextureButton
	else:
		if not is_instance_valid(_button_up):
			_button_up = _find_child_not_in_drawcounter("TextureButton") as TextureButton
		if not is_instance_valid(_button_down):
			_button_down = _find_child_not_in_drawcounter("TextureButton2") as TextureButton
		if _buttons_box == null and is_instance_valid(_button_up):
			var parent := _button_up.get_parent()
			if parent != self:
				_buttons_box = parent as Control
	if not is_instance_valid(_delete_button):
		_delete_button = get_node_or_null(NodePath("Delete")) as TextureButton
		if _delete_button == null:
			_delete_button = find_child("Delete", true, false) as TextureButton

func _find_child_not_in_drawcounter(name: String) -> Node:
	var node := find_child(name, true, false)
	if node == null:
		return null
	if is_instance_valid(_draw_counter) and _draw_counter.is_ancestor_of(node):
		for child in get_children():
			if child == _draw_counter:
				continue
			var found := child.find_child(name, true, false)
			if found != null:
				return found
		return null
	return node

func _to_int(value) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return int(round(value))
		TYPE_STRING:
			var s := String(value).strip_edges()
			if s == "":
				return 0
			if s.is_valid_int():
				return s.to_int()
			if s.is_valid_float():
				return int(round(s.to_float()))
			return 0
		_:
			return 0

extends PanelContainer

@export var json_path := "res://data/battlegroup_data.json"
@export var title := "Репутации:"
@export var item_scene: PackedScene = preload("res://scenes/option_list/universal_card.tscn")
const ReputationScript = preload("res://scripts/option_list/reputation.gd")
@onready var _title: Label = $MarginContainer/VBoxContainer/Header/Label
@onready var _items: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Items
@onready var _close: Button = $MarginContainer/VBoxContainer/Header/Close

var _is_loaded := false

func _ready() -> void:
	if is_instance_valid(_title):
		_title.text = title
	if not _close.pressed.is_connected(_on_close_pressed):
		_close.pressed.connect(_on_close_pressed)
	visibility_changed.connect(_on_visibility_changed)
	if _has_baked_items():
		_is_loaded = true
	elif visible:
		_ensure_loaded()

func _ensure_loaded() -> void:
	if _is_loaded:
		return
	_is_loaded = true
	_populate()

func _has_baked_items() -> bool:
	return _items.get_child_count() > 0

func bake_rebuild() -> void:
	for child in _items.get_children():
		child.free()
	_populate()
	_is_loaded = true

func _populate() -> void:
	var data = _load_json(json_path)
	if data.is_empty():
		return

	for child in _items.get_children():
		child.queue_free()

	for entry in data.get("reputations", []):
		var item = item_scene.instantiate()
		item.set_script(ReputationScript)
		_items.add_child(item)
		if item.has_method("populate"):
			item.populate(entry)

func _load_json(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open json: %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("Failed to parse json: %s" % path)
		return {}
	return parsed

func _on_visibility_changed() -> void:
	if visible:
		_ensure_loaded()

func _on_close_pressed() -> void:
	if has_node("../character_editer"):
		$"../character_editer".show()
	hide()

extends PanelContainer

@export var json_path := "res://data/battlegroup_data.json"
@export var title := "Способности репутации:"
@export var item_scene: PackedScene = preload("res://scenes/option_list/universal_card.tscn")
const ReputationAdvanceScript = preload("res://scripts/option_list/reputation_advance.gd")

@onready var _title: Label = $MarginContainer/VBoxContainer/Header/Label
@onready var _items: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Items
@onready var _close: Button = $MarginContainer/VBoxContainer/Header/Close

var _is_loaded := false
var _dirty := true

func _ready() -> void:
	if is_instance_valid(_title):
		_title.text = title
	if not _close.pressed.is_connected(_on_close_pressed):
		_close.pressed.connect(_on_close_pressed)
	visibility_changed.connect(_on_visibility_changed)
	if not BattlegroupData.battlegroup_change.is_connected(_on_battlegroup_change):
		BattlegroupData.battlegroup_change.connect(_on_battlegroup_change)
	if visible:
		_ensure_loaded()

func _ensure_loaded() -> void:
	if _is_loaded:
		return
	_is_loaded = true
	_dirty = false
	_populate()

func _on_battlegroup_change() -> void:
	if visible:
		_ensure_loaded()
		_populate()
		_dirty = false
	else:
		_dirty = true

func _on_visibility_changed() -> void:
	if visible:
		if not _is_loaded:
			_ensure_loaded()
		elif _dirty:
			_populate()
			_dirty = false

func _populate() -> void:
	for child in _items.get_children():
		child.queue_free()

	var reps: Array = BattlegroupData.comander.get("reputations", [])
	if reps.is_empty():
		return
	var rep: Dictionary = reps[0]
	for adv in _get_advances(rep):
		var item = item_scene.instantiate()
		item.set_script(ReputationAdvanceScript)
		_items.add_child(item)
		if item.has_method("populate"):
			item.populate(adv)

func _get_advances(rep: Dictionary) -> Array:
	var advances: Array = rep.get("advances", [])
	if not advances.is_empty():
		return advances

	var data = _load_json(json_path)
	if data.is_empty():
		return []
	var rep_name := String(rep.get("name", ""))
	for entry in data.get("reputations", []):
		if String(entry.get("name", "")) == rep_name:
			return entry.get("advances", [])
	return []

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

func _on_close_pressed() -> void:
	if has_node("../character_editer"):
		$"../character_editer".show()
	hide()

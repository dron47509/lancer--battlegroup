extends HBoxContainer

var old_node
var _edit_locked := true
signal change_scene(parent_node)

const CommendationCard = preload("res://scenes/support/item_card.tscn")

@onready var _name : LineEdit = $VBoxContainer/NameComander

@onready var _name_label : Label = $VBoxContainer/Label3

@onready var _name_btn : Button = $VBoxContainer/Label3/Button
@onready var _commendations_label: Label = $VBoxContainer/Label2
@onready var _commendations_list: VBoxContainer = $VBoxContainer/Commendations
@onready var _commendations_separator: HSeparator = $VBoxContainer/HSeparator3
@onready var _commendation_btn: Button = $VBoxContainer/Commendation

func _ready() -> void:
	refesh_comander()
	_set_editable(false)
	if not BattlegroupData.battlegroup_change.is_connected(refesh_comander):
		BattlegroupData.battlegroup_change.connect(refesh_comander)
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_commendations_list):
		BattlegroupData.battlegroup_change.connect(_refresh_commendations_list)
	if not _commendation_btn.pressed.is_connected(_on_commendation_pressed):
		_commendation_btn.pressed.connect(_on_commendation_pressed)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	_refresh_commendations_list()
	_apply_battle_state()


func _on_button_pressed() -> void:
	emit_signal("change_scene", null)

func refesh_comander():
	_edit_locked = true
	_name.text = BattlegroupData.comander["name"]
	_name_label.text = BattlegroupData.comander["name"]

func _set_editable(can_edit: bool) -> void:
	_edit_locked = not can_edit
	_name.editable = can_edit
	_name.focus_mode = Control.FOCUS_NONE
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_btn.disabled = not can_edit


func _on_name_comander_text_changed(new_text: String) -> void:
	if _edit_locked:
		return
	BattlegroupData.comander["name"] = new_text
	BattlegroupData.save_data()

func _on_commendation_pressed() -> void:
	BattlegroupData.change_on_commendations()


func _on_battle_state_changed(_enabled: bool) -> void:
	_apply_battle_state()


func _apply_battle_state() -> void:
	if is_instance_valid(_commendation_btn):
		_commendation_btn.visible = not BattlegroupData.in_battle
	_update_commendations_visibility()

func _refresh_commendations_list() -> void:
	if not is_instance_valid(_commendations_list):
		return
	for child in _commendations_list.get_children():
		child.queue_free()
	for entry in BattlegroupData.comander.get("commendations", []):
		_add_commendation_entry(entry)
	_update_commendations_visibility()

func _add_commendation_entry(data: Dictionary) -> void:
	var card: Control = CommendationCard.instantiate()
	_commendations_list.add_child(card)
	if card.has_method("setup"):
		card.call_deferred("setup", data, true, {}, false, "commendation", true)
		return
	if card.has_method("populate"):
		card.call_deferred("populate", data)
	if card.has_method("set_context"):
		card.call_deferred("set_context", true, {}, false, "commendation")
	if card.has_method("set_collapsed"):
		card.call_deferred("set_collapsed", true)

func _update_commendations_visibility() -> void:
	var has_comm = BattlegroupData.comander.get("commendations", []).size() > 0
	var show_block = not BattlegroupData.in_battle or has_comm
	if is_instance_valid(_commendations_label):
		_commendations_label.visible = show_block
	if is_instance_valid(_commendations_list):
		_commendations_list.visible = show_block
	if is_instance_valid(_commendations_separator):
		_commendations_separator.visible = show_block

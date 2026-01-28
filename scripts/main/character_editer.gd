extends VBoxContainer
class_name CharacterEditer

var parent_node
var text

const ItemCard = preload("res://scenes/support/item_card.tscn")

@onready var _text: TextEdit = $ScrollContainer/VBoxContainer/TextEdit
@onready var _name_label: Label = $ScrollContainer/VBoxContainer/Label3
@onready var _name_btn: Button = $ScrollContainer/VBoxContainer/Label3/Button
@onready var _name_edit: LineEdit = $ScrollContainer/VBoxContainer/NameComander

@onready var _positive1_label: Label = $ScrollContainer/VBoxContainer/Traits/Positive1Row/Label3
@onready var _positive1_edit: LineEdit = $ScrollContainer/VBoxContainer/Traits/Positive1Row/Positive1
@onready var _positive2_label: Label = $ScrollContainer/VBoxContainer/Traits/Positive2Row/Label4
@onready var _positive2_edit: LineEdit = $ScrollContainer/VBoxContainer/Traits/Positive2Row/Positive2

@onready var _positive3_row: HBoxContainer = $ScrollContainer/VBoxContainer/Traits/Positive3Row
@onready var _positive3_label: Label = $ScrollContainer/VBoxContainer/Traits/Positive3Row/Label5
@onready var _positive3_edit: LineEdit = $ScrollContainer/VBoxContainer/Traits/Positive3Row/Positive3

@onready var _negative1_label: Label = $ScrollContainer/VBoxContainer/Traits/Negative1Row/Label4
@onready var _negative1_edit: LineEdit = $ScrollContainer/VBoxContainer/Traits/Negative1Row/Negative

@onready var _negative2_row: HBoxContainer = $ScrollContainer/VBoxContainer/Traits/Negative2Row
@onready var _negative2_label: Label = $ScrollContainer/VBoxContainer/Traits/Negative2Row/Label5
@onready var _negative2_edit: LineEdit = $ScrollContainer/VBoxContainer/Traits/Negative2Row/Negative2

@onready var _reputation_btn: Button = $ScrollContainer/VBoxContainer/Reputaton
@onready var _advance_btn: Button = $ScrollContainer/VBoxContainer/Advance
@onready var _reputation_list: VBoxContainer = $ScrollContainer/VBoxContainer/Reputations
@onready var _advances_label: Label = $ScrollContainer/VBoxContainer/Label2
@onready var _advances_list: VBoxContainer = $ScrollContainer/VBoxContainer/Advances

func _ready() -> void:
	if not _name_btn.pressed.is_connected(_on_name_pressed):
		_name_btn.pressed.connect(_on_name_pressed)
	if not _name_edit.text_changed.is_connected(_on_name_text_changed):
		_name_edit.text_changed.connect(_on_name_text_changed)
	if not _name_edit.text_submitted.is_connected(_on_name_edit_committed):
		_name_edit.text_submitted.connect(_on_name_edit_committed)
	if not _name_edit.focus_exited.is_connected(_on_name_edit_committed):
		_name_edit.focus_exited.connect(_on_name_edit_committed)

	if not _positive1_edit.text_changed.is_connected(_on_positive_1_text_changed):
		_positive1_edit.text_changed.connect(_on_positive_1_text_changed)
	if not _positive2_edit.text_changed.is_connected(_on_positive_2_text_changed):
		_positive2_edit.text_changed.connect(_on_positive_2_text_changed)
	if not _positive3_edit.text_changed.is_connected(_on_positive_3_text_changed):
		_positive3_edit.text_changed.connect(_on_positive_3_text_changed)
	if not _negative1_edit.text_changed.is_connected(_on_negative_text_changed):
		_negative1_edit.text_changed.connect(_on_negative_text_changed)
	if not _negative2_edit.text_changed.is_connected(_on_negative_2_text_changed):
		_negative2_edit.text_changed.connect(_on_negative_2_text_changed)

	if not _reputation_btn.pressed.is_connected(_on_reputation_pressed):
		_reputation_btn.pressed.connect(_on_reputation_pressed)
	if not _advance_btn.pressed.is_connected(_on_advance_pressed):
		_advance_btn.pressed.connect(_on_advance_pressed)
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_reputation_list):
		BattlegroupData.battlegroup_change.connect(_refresh_reputation_list)
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_reputation_ui):
		BattlegroupData.battlegroup_change.connect(_refresh_reputation_ui)
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_advances_list):
		BattlegroupData.battlegroup_change.connect(_refresh_advances_list)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)

func _on_button_pressed() -> void:
	$"../Commander_interface".visible = true
	visible = false


func _on_visibility_changed() -> void:
	if visible == true:
		_text.text = BattlegroupData.comander["backstory"]
		var name_val := String(BattlegroupData.comander.get("name", ""))
		_name_label.text = "Имя персонажа" if name_val == "" else name_val
		_name_edit.text = name_val
		_name_label.show()
		_name_edit.hide()

		_positive1_label.text = BattlegroupData.comander.get("positive_1", "")
		_positive1_edit.text = _positive1_label.text
		_positive2_label.text = BattlegroupData.comander.get("positive_2", "")
		_positive2_edit.text = _positive2_label.text
		_positive3_label.text = BattlegroupData.comander.get("positive_3", "")
		_positive3_edit.text = _positive3_label.text

		_negative1_label.text = BattlegroupData.comander.get("negative", "")
		_negative1_edit.text = _negative1_label.text
		_negative2_label.text = BattlegroupData.comander.get("negative_2", "")
		_negative2_edit.text = _negative2_label.text

		_update_trait_rows()
		_refresh_reputation_list()
		_refresh_advances_list()
		_refresh_reputation_ui()


func _on_text_edit_text_changed() -> void:
	BattlegroupData.comander["backstory"] = _text.text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_name_pressed() -> void:
	var current := String(BattlegroupData.comander.get("name", ""))
	_name_edit.text = current
	_name_label.hide()
	_name_edit.show()
	_name_edit.grab_focus()
	_name_edit.set_caret_column(_name_edit.text.length())

func _on_name_text_changed(new_text: String) -> void:
	BattlegroupData.comander["name"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_name_edit_committed(_value = null) -> void:
	var name_val := String(_name_edit.text)
	_name_label.text = "Имя персонажа" if name_val == "" else name_val
	_name_edit.hide()
	_name_label.show()

func _on_positive_1_text_changed(new_text: String) -> void:
	BattlegroupData.comander["positive_1"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_positive_2_text_changed(new_text: String) -> void:
	BattlegroupData.comander["positive_2"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_positive_3_text_changed(new_text: String) -> void:
	BattlegroupData.comander["positive_3"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_negative_text_changed(new_text: String) -> void:
	BattlegroupData.comander["negative"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_negative_2_text_changed(new_text: String) -> void:
	BattlegroupData.comander["negative_2"] = new_text
	BattlegroupData.emit_signal("battlegroup_change")

func _on_reputation_pressed() -> void:
	BattlegroupData.change_on_reputations()

func _on_advance_pressed() -> void:
	BattlegroupData.change_on_reputation_advances()

func _on_battle_state_changed(_enabled: bool) -> void:
	_refresh_reputation_ui()

func _update_trait_rows() -> void:
	var has_rep = BattlegroupData.comander.get("reputations", []).size() > 0
	_positive3_row.visible = has_rep
	_negative2_row.visible = has_rep

func _refresh_reputation_ui() -> void:
	var has_rep = BattlegroupData.comander.get("reputations", []).size() > 0
	_reputation_btn.visible = not has_rep
	_advance_btn.visible = has_rep and not BattlegroupData.in_battle
	_reputation_list.visible = has_rep
	_advances_label.visible = has_rep
	_advances_list.visible = has_rep
	_update_trait_rows()

func _refresh_reputation_list() -> void:
	for child in _reputation_list.get_children():
		child.queue_free()

	for rep in BattlegroupData.comander.get("reputations", []):
		_add_reputation_entry(rep)

func _refresh_advances_list() -> void:
	for child in _advances_list.get_children():
		child.queue_free()

	for adv in BattlegroupData.comander.get("reputation_advances", []):
		_add_advance_entry(adv)

func _add_advance_entry(data: Dictionary) -> void:
	var card: Control = ItemCard.instantiate()
	_advances_list.add_child(card)
	if card.has_method("setup"):
		card.call_deferred("setup", data, true, {}, false, "reputation_advance", true)
		return
	if card.has_method("populate"):
		card.call_deferred("populate", data)
	if card.has_method("set_context"):
		card.call_deferred("set_context", true, {}, false, "reputation_advance")
	if card.has_method("set_collapsed"):
		card.call_deferred("set_collapsed", true)

func _add_reputation_entry(data: Dictionary) -> void:
	var card: Control = ItemCard.instantiate()
	_reputation_list.add_child(card)
	if card.has_method("setup"):
		card.call_deferred("setup", data, true, {}, false, "reputation", true)
		return
	if card.has_method("populate"):
		card.call_deferred("populate", data)
	if card.has_method("set_context"):
		card.call_deferred("set_context", true, {}, false, "reputation")
	if card.has_method("set_collapsed"):
		card.call_deferred("set_collapsed", true)

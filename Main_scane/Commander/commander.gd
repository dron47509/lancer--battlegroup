extends HBoxContainer

var old_node
signal change_scene(parent_node)

@onready var _name : LineEdit = $VBoxContainer/NameCommander
@onready var _positive1 : LineEdit = $VBoxContainer/HBoxContainer/Positive1
@onready var _positive2 : LineEdit = $VBoxContainer/HBoxContainer/Positive2
@onready var _negative : LineEdit = $VBoxContainer/HBoxContainer3/Negative
@onready var _positive1_check : CheckBox = $VBoxContainer/HBoxContainer/Positive1CheckBox
@onready var _positive2_check : CheckBox = $VBoxContainer/HBoxContainer/Positive2CheckBox
@onready var _negative_check : CheckBox = $VBoxContainer/HBoxContainer3/NegativeCheckBox
@onready var _backstory : RichTextLabel = $VBoxContainer/Backstory

func _ready() -> void:
	refresh_commander()


func _on_button_pressed() -> void:
	emit_signal("change_scene", _backstory)

func refresh_commander():
	_name.text = BattlegroupData.commander["name"]
	_positive1.text = BattlegroupData.commander["positive_1"]
	_positive2.text = BattlegroupData.commander["positive_2"]
	_negative.text = BattlegroupData.commander["negative"]
	_positive1_check.button_pressed = BattlegroupData.commander["positive_1_check"]
	_positive2_check.button_pressed = BattlegroupData.commander["positive_2_check"]
	_negative_check.button_pressed = BattlegroupData.commander["negative_check"]
	_backstory.text = BattlegroupData.commander["backstory"]


func _on_name_commander_text_changed(new_text: String) -> void:
	BattlegroupData.commander["name"] = new_text
	BattlegroupData.save_data()


func _on_positive_1_text_changed(new_text: String) -> void:
	BattlegroupData.commander["positive_1"] = new_text
	BattlegroupData.save_data()


func _on_positive_2_text_changed(new_text: String) -> void:
	BattlegroupData.commander["positive_2"] = new_text
	BattlegroupData.save_data()


func _on_negative_text_changed(new_text: String) -> void:
	BattlegroupData.commander["negative"] = new_text
	BattlegroupData.save_data()


func _on_positive_1_check_box_pressed() -> void:
	BattlegroupData.commander["positive_1_check"] = _positive1_check.button_pressed
	BattlegroupData.save_data()


func _on_positive_2_check_box_pressed() -> void:
	BattlegroupData.commander["positive_2_check"] = _positive2_check.button_pressed
	BattlegroupData.save_data()


func _on_negative_check_box_pressed() -> void:
	BattlegroupData.commander["negative_check"] = _negative_check.button_pressed
	BattlegroupData.save_data()

extends HBoxContainer

var old_node
signal change_scene(parent_node)

@onready var _name : LineEdit = $VBoxContainer/NameComander
@onready var _positive1 : LineEdit = $VBoxContainer/HBoxContainer/Positive1
@onready var _positive2 : LineEdit = $VBoxContainer/HBoxContainer/Positive2
@onready var _negative : LineEdit = $VBoxContainer/HBoxContainer3/Negative
@onready var _positive1_check : CheckBox = $VBoxContainer/HBoxContainer/Positive1CheckBox
@onready var _positive2_check : CheckBox = $VBoxContainer/HBoxContainer/Positive2CheckBox
@onready var _negative_check : CheckBox = $VBoxContainer/HBoxContainer3/NegativeCheckBox
@onready var _backstory : RichTextLabel = $VBoxContainer/Backstory

func _ready() -> void:
	refesh_comander()


func _on_button_pressed() -> void:
	emit_signal("change_scene", _backstory)

func refesh_comander():
	_name.text = BattlegroupData.comander["name"]
	_positive1.text = BattlegroupData.comander["positive_1"]
	_positive2.text = BattlegroupData.comander["positive_2"]
	_negative.text = BattlegroupData.comander["negative"]
	_positive1_check.button_pressed = BattlegroupData.comander["positive_1_check"]
	_positive2_check.button_pressed = BattlegroupData.comander["positive_2_check"]
	_negative_check.button_pressed = BattlegroupData.comander["negative_check"]
	_backstory.text = BattlegroupData.comander["backstory"]


func _on_name_comander_text_changed(new_text: String) -> void:
	BattlegroupData.comander["name"] = new_text


func _on_positive_1_text_changed(new_text: String) -> void:
	BattlegroupData.comander["positive_1"] = new_text


func _on_positive_2_text_changed(new_text: String) -> void:
	BattlegroupData.comander["positive_2"] = new_text


func _on_negative_text_changed(new_text: String) -> void:
	BattlegroupData.comander["negative"] = new_text


func _on_positive_1_check_box_pressed() -> void:
	BattlegroupData.comander["positive_1_check"] = _positive1_check.button_pressed


func _on_positive_2_check_box_pressed() -> void:
	BattlegroupData.comander["positive_2_check"] = _positive2_check.button_pressed


func _on_negative_check_box_pressed() -> void:
	BattlegroupData.comander["negative_check"] = _negative_check.button_pressed

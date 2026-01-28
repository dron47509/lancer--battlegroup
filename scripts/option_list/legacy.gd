extends PanelContainer

const ThemeBody = preload("res://themes/option_list/legacy.tres")
const ThemeHeader = preload("res://themes/option_list/legacy_header.tres")
const LabelTheme = preload("res://themes/option_list/for_label.tres")

@onready var _head: PanelContainer = $VBoxContainer/Head
@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _description: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _separator: HSeparator = $VBoxContainer/HSeparator
@onready var _add_panel: MarginContainer = $VBoxContainer/Button
@onready var _remove_panel: MarginContainer = $VBoxContainer/Button2
@onready var _special_add_panel: MarginContainer = $VBoxContainer/Button3
@onready var _special_remove_panel: MarginContainer = $VBoxContainer/Button4
@onready var _add_btn: Button = $VBoxContainer/Button/Add
@onready var _remove_btn: Button = $VBoxContainer/Button2/Remove
@export_storage var _src: Dictionary = {}

func _ready() -> void:
	theme = ThemeBody
	if is_instance_valid(_head):
		_head.theme = ThemeHeader
	if is_instance_valid(_name):
		_name.theme = LabelTheme
	if is_instance_valid(_tags):
		_tags.visible = false
	if is_instance_valid(_param):
		_param.visible = false
	if is_instance_valid(_separator):
		_separator.visible = true
	if is_instance_valid(_special_add_panel):
		_special_add_panel.hide()
	if is_instance_valid(_special_remove_panel):
		_special_remove_panel.hide()
	_add_btn.text = "Добавить"
	_remove_btn.text = "Убрать"
	if not _add_btn.pressed.is_connected(_on_add_pressed):
		_add_btn.pressed.connect(_on_add_pressed)
	if not _remove_btn.pressed.is_connected(_on_remove_pressed):
		_remove_btn.pressed.connect(_on_remove_pressed)
	if not BattlegroupData.option_change.is_connected(_refresh_buttons):
		BattlegroupData.option_change.connect(_refresh_buttons)
	if not BattlegroupData.legacies_change.is_connected(_refresh_buttons):
		BattlegroupData.legacies_change.connect(_refresh_buttons)
	if not BattlegroupData.battle_state_changed.is_connected(_refresh_buttons):
		BattlegroupData.battle_state_changed.connect(_refresh_buttons)
	_refresh_buttons()

func populate(data: Dictionary) -> void:
	_src = data.duplicate(true)
	_name.text = str(data.get("name", ""))
	_effect.text = str(data.get("effect", ""))
	var desc := str(data.get("discription", ""))
	if desc == "":
		_description.text = ""
	else:
		_description.text = "[i]%s[/i]" % desc
	_refresh_buttons()

func _refresh_buttons() -> void:
	if _src.is_empty():
		_add_panel.hide()
		_remove_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		return
	if BattlegroupData.in_battle:
		_add_panel.hide()
		_remove_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		return
	var can_add := BattlegroupData.can_add_legacy(_src)
	var has := BattlegroupData.has_legacy(_src)
	_add_panel.visible = can_add
	_remove_panel.visible = has
	_add_btn.visible = can_add
	_remove_btn.visible = has

func _on_add_pressed() -> void:
	if _src.is_empty():
		return
	BattlegroupData.add_legacy_to_current(_src)

func _on_remove_pressed() -> void:
	if _src.is_empty():
		return
	BattlegroupData.remove_legacy_from_current(_src)

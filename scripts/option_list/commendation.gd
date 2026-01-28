extends PanelContainer

const ThemeBody = preload("res://themes/option_list/commendation.tres")
const ThemeHeader = preload("res://themes/option_list/commendation_header.tres")
const LabelTheme = preload("res://themes/option_list/for_label.tres")
const HideTheme = preload("res://themes/commander/battlegroup/Hide_button.tres")
const COMMENDATION_COLOR = Color(0.219608, 0.486275, 0.854902, 1)

@onready var _head: PanelContainer = $VBoxContainer/Head
@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _hide_btn: Button = $VBoxContainer/Head/MarginContainer/VBoxContainer/Hide
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _description_container: MarginContainer = $VBoxContainer/Discription
@onready var _description: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _separator: HSeparator = $VBoxContainer/HSeparator
@onready var _add_panel: MarginContainer = $VBoxContainer/Button
@onready var _remove_panel: MarginContainer = $VBoxContainer/Button2
@onready var _special_add_panel: MarginContainer = $VBoxContainer/Button3
@onready var _special_remove_panel: MarginContainer = $VBoxContainer/Button4
@onready var _add_btn: Button = $VBoxContainer/Button/Add
@onready var _remove_btn: Button = $VBoxContainer/Button2/Remove
var _src: Dictionary = {}
var _hide_panel: PanelContainer = null

func _ready() -> void:
	theme = ThemeBody
	if is_instance_valid(_head):
		_head.theme = ThemeHeader
	if is_instance_valid(_name):
		_name.theme = LabelTheme
	if is_instance_valid(_hide_btn):
		_hide_btn.theme = HideTheme
	if is_instance_valid(_tags):
		_tags.visible = false
	if is_instance_valid(_param):
		_param.visible = false
	if is_instance_valid(_separator):
		var line := StyleBoxLine.new()
		line.color = COMMENDATION_COLOR
		line.thickness = 2
		_separator.add_theme_stylebox_override("separator", line)
		_separator.visible = true
	if is_instance_valid(_effect):
		_effect.add_theme_color_override("default_color", COMMENDATION_COLOR)
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
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_buttons):
		BattlegroupData.battlegroup_change.connect(_refresh_buttons)
	BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	visibility_changed.connect(_apply_battle_state)
	_refresh_buttons()
	_apply_battle_state()

func populate(data: Dictionary) -> void:
	_src = data.duplicate(true)
	_name.text = str(data.get("name", ""))
	_sync_hide_button_text()
	_effect.text = str(data.get("effect", ""))
	_description.text = str(data.get("discription", ""))
	_refresh_buttons()
	_apply_battle_state()

func set_pair(panel: PanelContainer) -> void:
	_hide_panel = panel
	if is_instance_valid(_hide_btn):
		_hide_btn.visible = true
		_sync_hide_button_text()
		_name.visible = false
		if not _hide_btn.pressed.is_connected(_on_hide_pressed):
			_hide_btn.pressed.connect(_on_hide_pressed)

func _refresh_buttons() -> void:
	if _src.is_empty():
		_add_panel.hide()
		_remove_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		_apply_battle_state()
		return
	if BattlegroupData.in_battle:
		_add_panel.hide()
		_remove_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		_apply_battle_state()
		return
	var has := BattlegroupData.has_commendation(_src)
	_add_panel.visible = not has
	_remove_panel.visible = has
	_add_btn.visible = not has
	_remove_btn.visible = has
	_apply_battle_state()

func _apply_battle_state() -> void:
	var show_description := not BattlegroupData.in_battle
	if is_instance_valid(_description_container):
		_description_container.visible = show_description
	if is_instance_valid(_description):
		_description.visible = show_description
	if is_instance_valid(_separator):
		_separator.visible = show_description
	if BattlegroupData.in_battle:
		if is_instance_valid(_add_panel):
			_add_panel.hide()
		if is_instance_valid(_remove_panel):
			_remove_panel.hide()
		if is_instance_valid(_add_btn):
			_add_btn.hide()
		if is_instance_valid(_remove_btn):
			_remove_btn.hide()

func _on_battle_state_changed(_enabled: bool) -> void:
	_refresh_buttons()

func _on_add_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.add_commendation(_src):
		_refresh_buttons()

func _on_remove_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.remove_commendation(_src):
		_refresh_buttons()

func _on_hide_pressed() -> void:
	visible = false
	if is_instance_valid(_hide_panel):
		_hide_panel.visible = true

func _sync_hide_button_text() -> void:
	if not is_instance_valid(_hide_btn):
		return
	if _hide_btn.visible:
		_hide_btn.text = _name.text

extends PanelContainer

const ThemeBody = preload("res://themes/option_list/reputation.tres")
const ThemeHeader = preload("res://themes/option_list/reputation_header.tres")
const HideTheme = preload("res://themes/commander/battlegroup/Hide_button.tres")

@onready var _main_head: PanelContainer = $VBoxContainer/Head
@onready var _header_panel: PanelContainer = $VBoxContainer/Header
@onready var _hide_btn: Button = $VBoxContainer/Header/MarginContainer/VBoxContainer/Hide
@onready var _effect_container: MarginContainer = $VBoxContainer/Effect
@onready var _description_container: MarginContainer = $VBoxContainer/Discription
@onready var _separator: HSeparator = $VBoxContainer/HSeparator
@onready var _buttons_container: MarginContainer = $VBoxContainer/Button
@onready var _buttons_container2: MarginContainer = $VBoxContainer/Button2
@onready var _special_add_container: MarginContainer = $VBoxContainer/Button3
@onready var _special_remove_container: MarginContainer = $VBoxContainer/Button4
@onready var _body_panel: MarginContainer = $VBoxContainer/Body
@onready var _name: RichTextLabel = $VBoxContainer/Body/VBoxContainer/Name
@onready var _effect: RichTextLabel = $VBoxContainer/Body/VBoxContainer/Effect
@onready var _buttons_panel: HBoxContainer = $VBoxContainer/Body/VBoxContainer/Buttons
@onready var _add_btn: Button = $VBoxContainer/Body/VBoxContainer/Buttons/Add
@onready var _remove_btn: Button = $VBoxContainer/Body/VBoxContainer/Buttons/Remove

var _src: Dictionary = {}
var _hide_panel: PanelContainer = null

func _ready() -> void:
	theme = ThemeBody
	if is_instance_valid(_header_panel):
		_header_panel.theme = ThemeHeader
	if is_instance_valid(_hide_btn):
		_hide_btn.theme = HideTheme
	if is_instance_valid(_main_head):
		_main_head.visible = false
	if is_instance_valid(_body_panel):
		_body_panel.visible = true
	if is_instance_valid(_effect_container):
		_effect_container.visible = false
	if is_instance_valid(_description_container):
		_description_container.visible = false
	if is_instance_valid(_separator):
		_separator.visible = false
	if is_instance_valid(_buttons_container):
		_buttons_container.visible = false
	if is_instance_valid(_buttons_container2):
		_buttons_container2.visible = false
	if is_instance_valid(_special_add_container):
		_special_add_container.visible = false
	if is_instance_valid(_special_remove_container):
		_special_remove_container.visible = false
	_add_btn.text = "Добавить"
	_remove_btn.text = "Убрать"
	if is_instance_valid(_header_panel):
		_header_panel.visible = false
	if not _add_btn.pressed.is_connected(_on_add_pressed):
		_add_btn.pressed.connect(_on_add_pressed)
	if not _remove_btn.pressed.is_connected(_on_remove_pressed):
		_remove_btn.pressed.connect(_on_remove_pressed)
	if not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)
	if not BattlegroupData.battlegroup_change.is_connected(_refresh_buttons):
		BattlegroupData.battlegroup_change.connect(_refresh_buttons)
	if not BattlegroupData.battle_state_changed.is_connected(_refresh_buttons):
		BattlegroupData.battle_state_changed.connect(_refresh_buttons)
	_refresh_buttons()

func populate(data: Dictionary) -> void:
	_src = data.duplicate(true)
	_name.text = str(data.get("name", ""))
	_effect.text = str(data.get("effect", ""))
	_sync_hide_button_text()
	_refresh_buttons()

func set_pair(panel: PanelContainer) -> void:
	_hide_panel = panel
	if is_instance_valid(_header_panel):
		_header_panel.visible = true
	_hide_btn.visible = true
	_name.visible = false
	_sync_hide_button_text()

func _refresh_buttons() -> void:
	if _src.is_empty():
		_buttons_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		return
	var has := BattlegroupData.has_reputation_advance(_src)
	var has_rep = BattlegroupData.comander.get("reputations", []).size() > 0
	var show_add = not has and has_rep
	var show_remove := has
	_buttons_panel.visible = show_add or (show_remove and not BattlegroupData.in_battle)
	_add_btn.visible = show_add
	_remove_btn.visible = show_remove and not BattlegroupData.in_battle

func _on_add_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.add_reputation_advance(_src):
		_refresh_buttons()

func _on_remove_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.remove_reputation_advance(_src):
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

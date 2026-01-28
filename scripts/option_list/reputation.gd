extends PanelContainer

const ThemeBody = preload("res://themes/option_list/reputation.tres")
const ThemeHeader = preload("res://themes/option_list/reputation_header.tres")
const LabelTheme = preload("res://themes/option_list/for_label.tres")
const HideTheme = preload("res://themes/commander/battlegroup/Hide_button.tres")
const ADVANCES_COLOR = Color(0.756863, 0.137255, 0.156863, 1)

@onready var _head: PanelContainer = $VBoxContainer/Head
@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _hide_btn: Button = $VBoxContainer/Head/MarginContainer/VBoxContainer/Hide
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _description: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _separator: HSeparator = $VBoxContainer/HSeparator
@onready var _effect_container: MarginContainer = $VBoxContainer/Effect
@onready var _advances_panel: MarginContainer = $VBoxContainer/Advances
@onready var _advances_label: RichTextLabel = $VBoxContainer/Advances/Advances
@onready var _advance_containers: Array[MarginContainer] = [
	$VBoxContainer/Advance1,
	$VBoxContainer/Advance2,
	$VBoxContainer/Advance3,
	$VBoxContainer/Advance4,
	$VBoxContainer/Advance5
]
@onready var _advance_names: Array[RichTextLabel] = [
	$VBoxContainer/Advance1/VBoxContainer/Name,
	$VBoxContainer/Advance2/VBoxContainer/Name,
	$VBoxContainer/Advance3/VBoxContainer/Name,
	$VBoxContainer/Advance4/VBoxContainer/Name,
	$VBoxContainer/Advance5/VBoxContainer/Name
]
@onready var _advance_effects: Array[RichTextLabel] = [
	$VBoxContainer/Advance1/VBoxContainer/Effect,
	$VBoxContainer/Advance2/VBoxContainer/Effect,
	$VBoxContainer/Advance3/VBoxContainer/Effect,
	$VBoxContainer/Advance4/VBoxContainer/Effect,
	$VBoxContainer/Advance5/VBoxContainer/Effect
]
@onready var _advance_separators: Array[HSeparator] = [
	$VBoxContainer/HSeparator2,
	$VBoxContainer/HSeparator3,
	$VBoxContainer/HSeparator4,
	$VBoxContainer/HSeparator5
]
@onready var _add_panel: MarginContainer = $VBoxContainer/Button
@onready var _remove_panel: MarginContainer = $VBoxContainer/Button2
@onready var _special_add_panel: MarginContainer = $VBoxContainer/Button3
@onready var _special_remove_panel: MarginContainer = $VBoxContainer/Button4
@onready var _add_btn: Button = $VBoxContainer/Button/Add
@onready var _remove_btn: Button = $VBoxContainer/Button2/Remove
@export_storage var _src: Dictionary = {}
var _show_advances := true
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
		_separator.visible = false
	if is_instance_valid(_effect_container):
		_effect_container.visible = false
	if is_instance_valid(_advances_label):
		_advances_label.theme = LabelTheme
		_advances_label.add_theme_color_override("default_color", ADVANCES_COLOR)
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
	if not BattlegroupData.battle_state_changed.is_connected(_refresh_buttons):
		BattlegroupData.battle_state_changed.connect(_refresh_buttons)
	_refresh_buttons()

func populate(data: Dictionary) -> void:
	_src = data.duplicate(true)
	_name.text = str(data.get("name", ""))
	_sync_hide_button_text()
	_description.text = str(data.get("discription", ""))
	_apply_advances(data)
	_refresh_buttons()

func set_pair(panel: PanelContainer) -> void:
	_hide_panel = panel
	if is_instance_valid(_hide_btn):
		_hide_btn.visible = true
		_sync_hide_button_text()
		_name.visible = false
		if not _hide_btn.pressed.is_connected(_on_hide_pressed):
			_hide_btn.pressed.connect(_on_hide_pressed)

func set_show_advances(show: bool) -> void:
	_show_advances = show
	if not _src.is_empty():
		_apply_advances(_src)

func _apply_advances(data: Dictionary) -> void:
	if not _show_advances:
		for i in range(_advance_containers.size()):
			_advance_names[i].text = ""
			_advance_effects[i].text = ""
			_advance_containers[i].hide()
		_advances_label.visible = false
		_advances_panel.visible = false
		for i in range(_advance_separators.size()):
			_advance_separators[i].visible = false
		return

	var advances: Array = data.get("advances", [])
	var count = min(advances.size(), _advance_containers.size())
	for i in range(_advance_containers.size()):
		if i < advances.size():
			var adv: Dictionary = advances[i]
			_advance_names[i].text = str(adv.get("name", ""))
			_advance_effects[i].text = str(adv.get("effect", ""))
			_advance_containers[i].show()
		else:
			_advance_names[i].text = ""
			_advance_effects[i].text = ""
			_advance_containers[i].hide()

	_advances_label.visible = count > 0
	_advances_panel.visible = count > 0
	for i in range(_advance_separators.size()):
		_advance_separators[i].visible = i < count - 1

func _refresh_buttons() -> void:
	if _src.is_empty():
		_add_panel.hide()
		_remove_panel.hide()
		_add_btn.hide()
		_remove_btn.hide()
		return
	var has := BattlegroupData.has_reputation(_src)
	var has_any = BattlegroupData.comander.get("reputations", []).size() > 0
	var show_add = not has and not has_any
	var show_remove := has
	_add_panel.visible = show_add
	_remove_panel.visible = show_remove and not BattlegroupData.in_battle
	_add_btn.visible = show_add
	_remove_btn.visible = show_remove and not BattlegroupData.in_battle

func _on_add_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.add_reputation(_src):
		_refresh_buttons()

func _on_remove_pressed() -> void:
	if _src.is_empty():
		return
	if BattlegroupData.remove_reputation(_src):
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

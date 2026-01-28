extends Control

##  Управляет интерфейсом и списком кораблей игрока.
##  Оптимизировано: типизация, единообразная работа со счётчиками,
##  enum для классов, одно место, управляющее отображением разделов.

@onready var character_editer: VBoxContainer = $PanelContainer/MarginContainer/character_editer
@onready var main: ScrollContainer        = $PanelContainer/MarginContainer/Commander_interface
@onready var hull_list: VBoxContainer     = $PanelContainer/MarginContainer/Hulls_list
@onready var option_list: PanelContainer  = $PanelContainer/MarginContainer/Option_list
@onready var commendations_list: PanelContainer = $PanelContainer/MarginContainer/Commendations_list
@onready var legacies_list: PanelContainer      = $PanelContainer/MarginContainer/Legacies_list
@onready var reputations_list: PanelContainer   = $PanelContainer/MarginContainer/Reputations_list
@onready var reputation_advances_list: PanelContainer = $PanelContainer/MarginContainer/Reputation_advances_list
@onready var add_hull_button: Button      = $PanelContainer/MarginContainer/Commander_interface/Main/Add_hull
var range_block: Control         = null
@onready var engage_button: Button        = $PanelContainer/MarginContainer/Commander_interface/Main/Engage
@onready var _loading: ColorRect          = $Loading

@export var prewarm_lists := true
@export var prewarm_background := true

const ENGAGE_TEXT := "В бой!"
const DISENGAGE_TEXT := "Выйти из боя"



func _ready() -> void:
	BattlegroupData.option_list_requested.connect(change_on_option)
	BattlegroupData.legacies_change.connect(change_on_legacies)
	BattlegroupData.commendations_change.connect(change_on_commendations)
	BattlegroupData.reputations_change.connect(change_on_reputations)
	BattlegroupData.reputation_advances_change.connect(change_on_reputation_advances)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	range_block = _resolve_range_block()
	_apply_battle_state()
	if prewarm_lists:
		if prewarm_background:
			call_deferred("_prewarm_lists_background")
		else:
			await _prewarm_lists_blocking()


func _prewarm_lists_blocking() -> void:
	_loading.show()
	await _prewarm_lists(false)
	_loading.hide()

func _prewarm_lists_background() -> void:
	await _prewarm_lists(true)

func _prewarm_lists(background: bool) -> void:
	await _prewarm_panel(hull_list, background)
	await _prewarm_panel(option_list, background)
	#await _prewarm_panel(commendations_list, background)
	#await _prewarm_panel(legacies_list, background)
	await _prewarm_panel(reputations_list, background)
	await _prewarm_panel(reputation_advances_list, background)

func _prewarm_panel(panel: Control, background: bool) -> void:
	if panel.visible:
		return
	var prev_modulate := panel.modulate
	var prev_mouse := panel.mouse_filter
	if background:
		var transparent := prev_modulate
		transparent.a = 0.0
		panel.modulate = transparent
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.show()
	await get_tree().process_frame
	panel.hide()
	if background:
		panel.modulate = prev_modulate
		panel.mouse_filter = prev_mouse
	

func change_on_option():
	if legacies_list.visible:
		return
	if option_list.visible:
		return
	_hide_all_sections()
	option_list.show()

func change_on_main():
	_hide_all_sections()
	main.show()

func change_on_legacies():
	_hide_all_sections()
	legacies_list.show()

func change_on_commendations():
	_hide_all_sections()
	commendations_list.show()

func change_on_reputations():
	_hide_all_sections()
	reputations_list.show()

func change_on_reputation_advances():
	_hide_all_sections()
	reputation_advances_list.show()

func _on_hull_list_change_scene() -> void:
	_toggle_sections(true, false)
	print(BattlegroupData.ships, "\n\n")
	print(BattlegroupData.comander)


func _on_engage_pressed() -> void:
	BattlegroupData.set_in_battle(not BattlegroupData.in_battle)


func _on_battle_state_changed(_enabled: bool) -> void:
	_apply_battle_state()


func _apply_battle_state() -> void:
	if not is_instance_valid(engage_button):
		return
	engage_button.text = DISENGAGE_TEXT if BattlegroupData.in_battle else ENGAGE_TEXT
	if is_instance_valid(add_hull_button):
		add_hull_button.visible = not BattlegroupData.in_battle
	if is_instance_valid(range_block):
		range_block.visible = BattlegroupData.in_battle


func _on_commander_change_scene(parent_node: Node) -> void:
	if parent_node != null:
		character_editer.parent_node = parent_node
	character_editer.text = "Предыстория"
	_toggle_sections(false, true)
	

func _toggle_sections(show_hull_list := false, show_note := false) -> void:
	_hide_all_sections()
	main.visible      = not (show_hull_list or show_note)
	hull_list.visible = show_hull_list
	character_editer.visible = show_note

func _hide_all_sections() -> void:
	main.hide()
	character_editer.hide()
	hull_list.hide()
	option_list.hide()
	commendations_list.hide()
	legacies_list.hide()
	reputations_list.hide()
	reputation_advances_list.hide()


func _on_install_pressed() -> void:
	pass # Replace with function body.

func _resolve_range_block() -> Control:
	var root := $PanelContainer/MarginContainer/Commander_interface/Main
	if not is_instance_valid(root):
		return null
	var in_battlegroup := root.get_node_or_null("Battlegroup/Range")
	if in_battlegroup != null:
		return in_battlegroup
	var direct := root.get_node_or_null("Range")
	if direct != null:
		return direct
	return null

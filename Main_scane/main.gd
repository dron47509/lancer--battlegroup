extends Control

##  Управляет интерфейсом и списком кораблей игрока.
##  Оптимизировано: типизация, единообразная работа со счётчиками,
##  enum для классов, одно место, управляющее отображением разделов.

@onready var note: VBoxContainer          = $PanelContainer/MarginContainer/Note
@onready var main: ScrollContainer        = $PanelContainer/MarginContainer/Commander_interface
@onready var hull_list: VBoxContainer     = $PanelContainer/MarginContainer/Hulls_list
@onready var option_list: PanelContainer  = $PanelContainer/MarginContainer/Option_list
@onready var add_hull_button: Button      = $PanelContainer/MarginContainer/Commander_interface/Main/Add_hull



func _ready() -> void:
	# Кратковременно показываем список, чтобы его разметила система UI
	hull_list.show()
	await get_tree().process_frame
	hull_list.hide()
	option_list.show()
	await get_tree().process_frame
	option_list.hide()
	
	BattlegroupData.option_change.connect(change_on_option)
	

func change_on_option():
	main.hide()
	note.hide()
	hull_list.hide()
	option_list.show()

func change_on_main():
	main.show()
	note.hide()
	hull_list.hide()
	option_list.hide()

func _on_hull_list_change_scene() -> void:
	_toggle_sections(true, false)
	print(BattlegroupData.ships, "\n\n")
	print(BattlegroupData.comander)


func _on_commander_change_scene(parent_node: Node) -> void:
	note.parent_node = parent_node
	note.text = "Предыстория"
	_toggle_sections(false, true)
	

func _toggle_sections(show_hull_list := false, show_note := false) -> void:
	main.visible      = not (show_hull_list or show_note)
	hull_list.visible = show_hull_list
	note.visible      = show_note

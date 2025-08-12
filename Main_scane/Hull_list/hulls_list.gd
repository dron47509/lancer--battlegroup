###  HullList.gd  ###
extends VBoxContainer                        # навесьте на узел Hull_list

@export var json_path := "user://battlegroup_data.json"
@export var hull_scene:= preload("res://support_scanes/hull.tscn")    # drag-and-drop Hull.tscn в инспекторе

@onready var _frigate: VBoxContainer = $Hulls_list/VBoxContainer/Frigate
@onready var _carrier: VBoxContainer = $Hulls_list/VBoxContainer/Carrier
@onready var _battleship: VBoxContainer = $Hulls_list/VBoxContainer/Battleship
@onready var _options: OptionButton = $OptionButton
func _ready() -> void:
	var raw := _load_json(json_path)
	if raw.is_empty():
		return

	for hull_data in raw.get("hulls", []):
		_spawn_hull(hull_data)


### utils -----------------------------------------------------------------

func _spawn_hull(hull_data: Dictionary) -> void:
	var hull := hull_scene.instantiate()
	if hull_data["class"] == 0.0:
		_frigate.add_child(hull)
	elif hull_data["class"] == 1.0:
		_carrier.add_child(hull)
	elif hull_data["class"] == 2.0:
		_battleship.add_child(hull)
	hull.get_child(0).populate(hull_data)
	#hull.get_child(0).hull_added.connect(BattlegroupData.add_hull)
	#hull.get_child(0).hull_removed.connect(BattlegroupData.remove_hull)
	#_box.add_child(HSeparator.new())

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Файл %s не найден" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("Ошибка парсинга %s" % path)
		return {}
	return parsed


func _on_option_button_item_selected(index: int) -> void:
	_frigate.hide()
	_carrier.hide()
	_battleship.hide()
	if  _options.selected == 1:
		_frigate.show()
	elif  _options.selected == 2:
		_carrier.show()
	elif  _options.selected == 3:
		_battleship.show()
	elif _options.selected == 0:
		_frigate.show()
		_carrier.show()
		_battleship.show()


func _on_button_pressed() -> void:
	$"../Commander_interface".show()
	hide()

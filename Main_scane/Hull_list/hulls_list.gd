###  HullList.gd  ###
extends VBoxContainer                        # навесьте на узел Hull_list

@export var json_path = "res://battlegroup_data.json"
@export var hull_scene = preload("res://support_scanes/hull.tscn")    # drag-and-drop Hull.tscn в инспекторе
const Opt = preload("res://option_types.gd")

@onready var _frigate: VBoxContainer = $Hulls_list/VBoxContainer/Frigate
@onready var _carrier: VBoxContainer = $Hulls_list/VBoxContainer/Carrier
@onready var _battleship: VBoxContainer = $Hulls_list/VBoxContainer/Battleship
@onready var _options: OptionButton = $OptionButton
@onready var _point = $Inform_panel/Point_container/Label2
@onready var _frigate_count = $Inform_panel/Frigate_container/Label2
@onready var _carrier_count = $Inform_panel/Carrier_container/Label2
@onready var _battleship_count = $Inform_panel/Battleship_container/Label2

func _ready() -> void:
	var raw = _load_json(json_path)
	if raw.is_empty():
		return

	for hull_data in raw.get("hulls", []):
		_spawn_hull(hull_data)

func _process(delta: float) -> void:
	_point.text = str(BattlegroupData.point) + "/20"
	_frigate_count.text = str(BattlegroupData.class_counts[0]) + "/3"
	_carrier_count.text = str(BattlegroupData.class_counts[1]) + "/2"
	_battleship_count.text = str(BattlegroupData.class_counts[2]) + "/1"
### utils -----------------------------------------------------------------

func _spawn_hull(hull_data: Dictionary) -> void:
	var hull = hull_scene.instantiate()
	if int(hull_data["class"]) == BattlegroupData.ShipClass.FRIGATE:
		_frigate.add_child(hull)
	elif int(hull_data["class"]) == BattlegroupData.ShipClass.CARRIER:
		_carrier.add_child(hull)
	elif int(hull_data["class"]) == BattlegroupData.ShipClass.BATTLESHIP:
		_battleship.add_child(hull)
	hull.get_child(0).populate(hull_data)
	#hull.get_child(0).hull_added.connect(BattlegroupData.add_hull)
	#hull.get_child(0).hull_removed.connect(BattlegroupData.remove_hull)
	#_box.add_child(HSeparator.new())

func _load_json(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
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
	if  _options.selected == Opt.HullFilter.BATTLESHIP:
		_frigate.show()
	elif  _options.selected == Opt.HullFilter.CARRIER:
		_carrier.show()
	elif  _options.selected == Opt.HullFilter.FRIGATE:
		_battleship.show()
	elif _options.selected == Opt.HullFilter.ALL:
		_frigate.show()
		_carrier.show()
		_battleship.show()


func _on_button_pressed() -> void:
	$"../Commander_interface".show()
	hide()

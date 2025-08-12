extends VBoxContainer

@export var ship_scene:= preload("res://Main_scane/Commander/ship.tscn") 


@onready var _point = $Inform_panel/Point_container/HBoxContainer/Label
@onready var _frigate = $Inform_panel/Frigate_container/HBoxContainer/Label
@onready var _carrier = $Inform_panel/Carrier_container/HBoxContainer/Label
@onready var _battleship = $Inform_panel/Battleship_container/HBoxContainer/Label
@onready var _ship_list = $Ship_list

func _ready() -> void:
	BattlegroupData.connect("battlegroup_change", refresh_fleet)
	BattlegroupData.connect("option_change", refresh_fleet)

func _process(delta: float) -> void:
	_point.text = str(BattlegroupData.point) + " /"
	_frigate.text = str(BattlegroupData.class_counts[0])
	_carrier.text = str(BattlegroupData.class_counts[1])
	_battleship.text = str(BattlegroupData.class_counts[2])
	
	
func refresh_fleet():
	_clear_children(_ship_list)
	for x in BattlegroupData.ships:
		var ship = ship_scene.instantiate()
		ship.call_deferred("populate", x)
		_ship_list.add_child(ship)

func _clear_children(container: Node) -> void:
	for c in container.get_children():
		c.queue_free()

extends VBoxContainer

@export var ship_scene:= preload("res://scenes/commander/ship.tscn") 

const HESPERIS_HULL_NAME := "FKS\nHESPERIS-CLASS BATTLECRUISER"
const SCKV_FLAG_KEY := "is_sckv"
const SCKV_HOST_KEY := "sckv_host"
const SCKV_INDEX_KEY := "sckv_index"

@onready var _point_container: Control = $Inform_panel/Point_container
@onready var _point = $Inform_panel/Point_container/Label2
@onready var _frigate = $Inform_panel/Frigate_container/Label2
@onready var _carrier = $Inform_panel/Carrier_container/Label2
@onready var _battleship = $Inform_panel/Battleship_container/Label2
@onready var _ship_list = $Ship_list
@onready var _note_edit: TextEdit = $Note/TextEdit

var _note_edit_guard := false

func _ready() -> void:
	BattlegroupData.connect("battlegroup_change", refresh_fleet)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	if is_instance_valid(_note_edit):
		if not _note_edit.text_changed.is_connected(_on_note_text_changed):
			_note_edit.text_changed.connect(_on_note_text_changed)
		_note_edit_guard = true
		_note_edit.text = String(BattlegroupData.battlegroup_note)
		_note_edit_guard = false
	_apply_battle_state()
	refresh_fleet()

func _process(delta: float) -> void:
	_point.text = str(BattlegroupData.point) + "/20"
	_frigate.text = str(_count_alive_by_class(0)) + "/3"
	_carrier.text = str(_count_alive_by_class(1)) + "/2"
	_battleship.text = str(_count_alive_by_class(2)) + "/1"
	
	
func refresh_fleet():
	_clear_children(_ship_list)
	for x in BattlegroupData.ships:
		if _is_sckv(x):
			continue
		var ship = ship_scene.instantiate()
		ship.call_deferred("populate", x)
		_ship_list.add_child(ship)
		if _is_hesperis(x):
			_add_sckv_cards(x)

func _clear_children(container: Node) -> void:
	for c in container.get_children():
		c.queue_free()

func _is_hesperis(ship: Dictionary) -> bool:
	return String(ship.get("name", "")).strip_edges() == HESPERIS_HULL_NAME

func _is_sckv(ship: Dictionary) -> bool:
	return bool(ship.get(SCKV_FLAG_KEY, false))

func _add_sckv_cards(host_ship: Dictionary) -> void:
	var host_name := String(host_ship.get("name", ""))
	var entries: Array = []
	for s in BattlegroupData.ships:
		if not _is_sckv(s):
			continue
		if String(s.get(SCKV_HOST_KEY, "")) != host_name:
			continue
		entries.append(s)
	entries.sort_custom(func(a, b): return int(a.get(SCKV_INDEX_KEY, 0)) < int(b.get(SCKV_INDEX_KEY, 0)))
	for sckv in entries:
		var card = ship_scene.instantiate()
		card.call_deferred("populate", sckv)
		_ship_list.add_child(card)

func _count_alive_by_class(cls: int) -> int:
	var count := 0
	for ship in BattlegroupData.ships:
		if _is_sckv(ship):
			continue
		if int(ship.get("class", -1)) != cls:
			continue
		if _ship_is_alive(ship):
			count += 1
	return count

func _ship_is_alive(ship: Dictionary) -> bool:
	var max_hp := _to_int(ship.get("hp", 0))
	var cur := _to_int(ship.get("current_hp", max_hp))
	return cur > 0

func _to_int(v) -> int:
	match typeof(v):
		TYPE_INT:
			return int(v)
		TYPE_FLOAT:
			return int(round(v))
		TYPE_STRING:
			var s := String(v).strip_edges()
			if s == "":
				return 0
			if s.is_valid_int():
				return s.to_int()
			if s.is_valid_float():
				return int(round(s.to_float()))
			return 0
		_:
			return 0

func _on_battle_state_changed(_enabled: bool) -> void:
	_apply_battle_state()

func _apply_battle_state() -> void:
	if is_instance_valid(_point_container):
		_point_container.visible = not BattlegroupData.in_battle

func _on_note_text_changed() -> void:
	if _note_edit_guard:
		return
	BattlegroupData.battlegroup_note = _note_edit.text
	BattlegroupData.save_data()

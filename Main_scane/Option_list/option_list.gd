extends PanelContainer

const Opt = preload("res://option_types.gd")

## ───────────────────────────────────────────────────────────────────
## 1.  Экспортируемые ресурсы и пути
## ───────────────────────────────────────────────────────────────────
@export var json_path      := "res://battlegroup_data.json"
@export var weapon_scene   := preload("res://Main_scane/Option_list/weapon.tscn")
@export var system_scene   := preload("res://Main_scane/Option_list/system.tscn")
@export var eswg_scene     := preload("res://Main_scane/Option_list/escort_wing.tscn")

## ───────────────────────────────────────────────────────────────────
## 2.  Контейнеры категорий
## ───────────────────────────────────────────────────────────────────
@onready var _slot_info := {          # индекс OptionButton → {key, node}
	Opt.SlotIndex.SUPERHEAVY:  { "key":"superheavy",  "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Superheavy },
	Opt.SlotIndex.PRIMARIES:   { "key":"primaries",   "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Primary   },
	Opt.SlotIndex.AUXILIARIES:{ "key":"auxiliaries","node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Auxiliry  },
	Opt.SlotIndex.SYSTEMS:     { "key":"systems",     "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/System    },
	Opt.SlotIndex.ESCORTS:     { "key":"escorts",     "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Escort    },
	Opt.SlotIndex.WINGS:       { "key":"wings",       "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Wing      },
}

@onready var _close : Button = $MarginContainer/VBoxContainer/HBoxContainer/Button

## ───────────────────────────────────────────────────────────────────
## 3.  Загрузка JSON и наполнение
## ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	_populate_all()
	# слушаем выбор корабля
	BattlegroupData.option_change.connect(_apply_ship_filter)
	# сразу применяем фильтр для первого выбранного корабля (если есть)
	_apply_ship_filter()



func _populate_all() -> void:
	var raw := _load_json(json_path)
	if raw.is_empty():
		return

	# оружие
	for w in raw.get("weapons", []):
		var n := weapon_scene.instantiate()
		_slot_info[_type_to_index(w.get("type", -1))]["node"].add_child(n)
		n.populate(w)

	# системы
	for s in raw.get("systems", []):
		var n := system_scene.instantiate()
		_slot_info[Opt.SlotIndex.SYSTEMS]["node"].add_child(n)     # systems
		n.populate(s)

	# эскорты / крылья
	for e in raw.get("escorts_wings", []):
		var n := eswg_scene.instantiate()
		var idx := Opt.SlotIndex.ESCORTS if e.get("type") == Opt.Support.ESCORT else Opt.SlotIndex.WINGS   # support type
		_slot_info[idx]["node"].add_child(n)
		n.populate(e)

func _type_to_index(t: float) -> int:
	var x
	match int(t):
		Opt.Weapon.SUPERHEAVY: x = Opt.SlotIndex.SUPERHEAVY
		Opt.Weapon.PRIMARY:    x = Opt.SlotIndex.PRIMARIES
		Opt.Weapon.AUXILIARY:  x = Opt.SlotIndex.AUXILIARIES
		_: x = -1
	return x
## ───────────────────────────────────────────────────────────────────
## 4.  Фильтрация по выбранному кораблю
## ───────────────────────────────────────────────────────────────────
func _apply_ship_filter() -> void:
	# скрыть всё по умолчанию
	for d in _slot_info.values():
		d["node"].visible = false

	var idx := int(BattlegroupData.current_ship)
	if idx < 0 or idx >= BattlegroupData.ships.size():
		return                                     # корабль не выбран

	var ship = BattlegroupData.ships[idx]
	var weapon  = ship["weapon_slots"]
	var support = ship["support_slots"]

	# показываем только те категории, где есть слоты (>0)
	for i in _slot_info:
		var k = _slot_info[i]["key"]
		var cnt := int(weapon.get(k, "0")) if k in weapon else int(support.get(k, "0"))
		if cnt > 0:
			_slot_info[i]["node"].visible = true

## ───────────────────────────────────────────────────────────────────
## 5.  Реакция на выбор в OptionButton
## ───────────────────────────────────────────────────────────────────
func _on_option_button_item_selected(index: int) -> void:
	_apply_ship_filter()   # актуализируем visibile = true/false

	# если выбран «Все» — оставляем как есть
	if index == Opt.SlotIndex.ALL:
		return

	# иначе скрываем всё, кроме нужного индекса
	for i in _slot_info:
		_slot_info[i]["node"].visible = (i == index) and _slot_info[i]["node"].visible

## ───────────────────────────────────────────────────────────────────
## 6.  JSON utils
## ───────────────────────────────────────────────────────────────────
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


func _on_button_pressed() -> void:
	$"../Commander_interface".show()
	hide()

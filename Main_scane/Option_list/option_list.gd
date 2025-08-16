extends PanelContainer

const Opt = preload("res://option_types.gd")

## ───────────────────────────────────────────────────────────────────
## 1.  Экспортируемые ресурсы и пути
## ───────────────────────────────────────────────────────────────────
@export var json_path      := "res://battlegroup_data.json"
@export var weapon_scene   := preload("res://Main_scane/Option_list/weapon.tscn")
@export var system_scene   := preload("res://Main_scane/Option_list/system.tscn")
@export var eswg_scene     := preload("res://Main_scane/Option_list/escort_wing.tscn")
@onready var _tag_button: OptionButton = $MarginContainer/VBoxContainer/OptionButton2
var _tag_suffix_re := RegEx.new()

## ───────────────────────────────────────────────────────────────────
## 2.  Контейнеры категорий
## ───────────────────────────────────────────────────────────────────
@onready var _slot_info := {          # индекс OptionButton → {key, node}
	Opt.SlotIndex.SUPERHEAVY:  { "key":"superheavy",  "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Superheavy },
	Opt.SlotIndex.PRIMARIES:   { "key":"primaries",   "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Primary   },
	Opt.SlotIndex.AUXILIARIES:{ "key":"auxiliaries","node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Auxiliry  },
	Opt.SlotIndex.SYSTEMS:     { "key":"systems",     "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/System    },
	Opt.SlotIndex.ESCORTS:     { "key":"escorts",     "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Escort   },
	Opt.SlotIndex.WINGS:       { "key":"wings",       "node": $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Wing      },
}

@onready var _close : Button = $MarginContainer/VBoxContainer/HBoxContainer/Button

## ───────────────────────────────────────────────────────────────────
## 3.  Загрузка JSON и наполнение
## ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	_tag_suffix_re.compile("\\s*[\\-–+]?\\d+$")
	_populate_all()



func _populate_all() -> void:
	var raw = _load_json(json_path)
	if raw.is_empty():
		return

	var tag_map := {}
	_collect_tags(raw, tag_map)

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
		if  int(e.get("type")) == 5:
			_slot_info[4]["node"].add_child(n)
		else:
			_slot_info[5]["node"].add_child(n)
		n.populate(e)

	_populate_tag_button(tag_map.keys())

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
func _apply_filters() -> void:
	# сбросить видимость
	for d in _slot_info.values():
		for c in d["node"].get_children():
			c.visible = true
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

	# фильтр по категории
	var cat_idx = $MarginContainer/VBoxContainer/OptionButton.selected
	if cat_idx != Opt.SlotIndex.ALL:
		for i in _slot_info:
			var n = _slot_info[i]["node"]
			var vis = (i == cat_idx) and n.visible
			n.visible = vis
			if not vis:
				for c in n.get_children():
					c.visible = false

	# фильтр по тегу
	var tag_text := _tag_button.get_item_text(_tag_button.selected)
	if tag_text != "Все":
		for d in _slot_info.values():
			if d["node"].visible:
				var any := false
				for c in d["node"].get_children():
					var has := false
					if c is Label:
						continue
					for t in c._src.get("tags", "").split(",", false):
						if _clean_tag(t) == tag_text:
							has = true
							break
					c.visible = has
					if has:
						any = true
				d["node"].visible = any

## ───────────────────────────────────────────────────────────────────
## 5.  Реакция на выбор в OptionButton
## ───────────────────────────────────────────────────────────────────
func _on_option_button_item_selected(index: int) -> void:
	_apply_filters()

func _on_option_button2_item_selected(index: int) -> void:
	_apply_filters()

## ───────────────────────────────────────────────────────────────────
## 6.  JSON utils
## ───────────────────────────────────────────────────────────────────
func _load_json(path: String):
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

func _clean_tag(t: String) -> String:
	return _tag_suffix_re.sub(t.strip_edges(), "", true)

func _collect_tags(obj, tags: Dictionary) -> void:
	if obj is Dictionary:
		if obj.has("tags"):
			for t in obj["tags"].split(",", false):
				t = _clean_tag(t)
				if t != "":
					tags[t] = true
		for v in obj.values():
			_collect_tags(v, tags)
	elif obj is Array:
		for v in obj:
			_collect_tags(v, tags)

func _populate_tag_button(tag_list: Array) -> void:
	_tag_button.clear()
	_tag_button.add_item("Все")
	tag_list.sort()
	for t in tag_list:
		_tag_button.add_item(t)


func _on_visibility_changed() -> void:
	_apply_filters()

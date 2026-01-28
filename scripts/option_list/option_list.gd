extends PanelContainer

const Opt = preload("res://scripts/core/option_types.gd")

## ───────────────────────────────────────────────────────────────────
## 1.  Экспортируемые ресурсы и пути
## ───────────────────────────────────────────────────────────────────
@export var json_path      = "res://data/battlegroup_data.json"
@export var card_scene: PackedScene = preload("res://scenes/option_list/universal_card.tscn")
const WeaponScript = preload("res://scripts/option_list/weapon.gd")
const SystemScript = preload("res://scripts/option_list/system.gd")
const EscortWingScript = preload("res://scripts/option_list/escort_wing.gd")
@onready var _cat_button: OptionButton = $MarginContainer/VBoxContainer/OptionButton
@onready var _tag_button: OptionButton = $MarginContainer/VBoxContainer/OptionButton2
@onready var _scroll: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
var _tag_suffix_re = RegEx.new()
var _is_loaded := false


## ───────────────────────────────────────────────────────────────────
## 2.  Контейнеры категорий
## ───────────────────────────────────────────────────────────────────
@onready var _slot_info = {          # индекс OptionButton → {key, node}
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
	visibility_changed.connect(_on_visibility_changed)
	_cat_button.visibility_changed.connect(_on_cat_button_visibility_changed)
	_tag_button.visibility_changed.connect(_on_tag_button_visibility_changed)
	BattlegroupData.option_change.connect(_install)
	if _has_baked_cards():
		_is_loaded = true
		if _tag_button.item_count <= 1:
			_populate_tags_from_cards()
	elif visible:
		_ensure_loaded()



func _ensure_loaded() -> void:
	if _is_loaded:
		return
	_populate_all()
	_is_loaded = true

func _populate_all() -> void:
	var raw = _load_json(json_path)
	if raw.is_empty():
		return

	var tag_map = {}
	_collect_tags(raw, tag_map)

	# оружие
	for w in raw.get("weapons", []):
		var n = card_scene.instantiate()
		n.set_script(WeaponScript)
		_slot_info[_type_to_index(w.get("type", -1))]["node"].add_child(n)
		n.populate(w)

	# системы
	for s in raw.get("systems", []):
		var n = card_scene.instantiate()
		n.set_script(SystemScript)
		_slot_info[Opt.SlotIndex.SYSTEMS]["node"].add_child(n)     # systems
		n.populate(s)

	# эскорты / крылья
	for e in raw.get("escorts_wings", []):
		var n = card_scene.instantiate()
		n.set_script(EscortWingScript)
		if  int(e.get("type")) == 5:
			_slot_info[4]["node"].add_child(n)
		else:
			_slot_info[5]["node"].add_child(n)
		n.populate(e)

	_populate_tag_button(tag_map.keys())

func _has_baked_cards() -> bool:
	for d in _slot_info.values():
		for c in d["node"].get_children():
			if c is Label:
				continue
			return true
	return false

func _populate_tags_from_cards() -> void:
	var tag_map = {}
	for d in _slot_info.values():
		for c in d["node"].get_children():
			if c is Label:
				continue
			_collect_tags(c._src, tag_map)
	if tag_map.size() > 0:
		_populate_tag_button(tag_map.keys())

func bake_rebuild() -> void:
	_clear_cards()
	_populate_all()
	_is_loaded = true

func _clear_cards() -> void:
	for d in _slot_info.values():
		for c in d["node"].get_children():
			if c is Label:
				continue
			c.free()

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
	# 1) Сброс видимости: все карточки внутри категорий видимы, сами контейнеры скрыты
	for d in _slot_info.values():
		for c in d["node"].get_children():
			c.visible = true
		d["node"].visible = false

	var idx = int(BattlegroupData.current_ship)
	if idx < 0 or idx >= BattlegroupData.ships.size():
		return                                     # корабль не выбран

	var ship: Dictionary  = BattlegroupData.ships[idx]
	var weapon: Dictionary  = ship.get("weapon_slots", {})
	var support: Dictionary = ship.get("support_slots", {})
	var ship_name = String(ship.get("name", ""))

	# 2) Особые слоты: принудительно делаем нужные категории видимыми
	var force_visible = {}   # ключи — индексы слотов Opt.SlotIndex.*
	if ship_name == "IPS-N\nMINOKAWA-CLASS FRIGATE":
		force_visible[Opt.SlotIndex.ESCORTS] = true
		force_visible[Opt.SlotIndex.WINGS]   = true
	elif ship_name == "HA\nFARRAGUT-CLASS STARFIELD CARRIER":
		force_visible[Opt.SlotIndex.AUXILIARIES] = true
		force_visible[Opt.SlotIndex.SYSTEMS]     = true
		force_visible[Opt.SlotIndex.ESCORTS]     = true
		force_visible[Opt.SlotIndex.WINGS]       = true

	# 3) Показываем только те категории, где есть слоты (>0) ИЛИ они форс-видимы
	for i in _slot_info.keys():
		var k = _slot_info[i]["key"]
		var cnt = 0
		if weapon.has(k):
			cnt = int(weapon.get(k, "0"))
		elif support.has(k):
			cnt = int(support.get(k, "0"))
		var vis = (cnt > 0) or force_visible.has(i)
		_slot_info[i]["node"].visible = vis

	# 4) Фильтр по категории (OptionButton)
	var cat_idx = $MarginContainer/VBoxContainer/OptionButton.selected
	if cat_idx != Opt.SlotIndex.ALL:
		for i in _slot_info.keys():
			var n = _slot_info[i]["node"]
			var vis = (i == cat_idx) and n.visible
			n.visible = vis
			if not vis:
				for c in n.get_children():
					c.visible = false

	# 5) Фильтр по тегу
	var tag_text = _tag_button.get_item_text(_tag_button.selected)
	if tag_text != "Все":
		for d in _slot_info.values():
			if d["node"].visible:
				var any = false
				for c in d["node"].get_children():
					var has = false
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
	_scroll.scroll_vertical = 0

func _on_option_button2_item_selected(index: int) -> void:
	_apply_filters()
	_scroll.scroll_vertical = 0

func _on_visibility_changed() -> void:
	if visible:
		_ensure_loaded()
		_cat_button.select(Opt.SlotIndex.ALL)
		_tag_button.select(0)
		_apply_filters()
		_scroll.scroll_vertical = 0

func _on_cat_button_visibility_changed() -> void:
	if _cat_button.visible:
		_ensure_loaded()
		_cat_button.select(Opt.SlotIndex.ALL)
		_apply_filters()
		_scroll.scroll_vertical = 0

func _on_tag_button_visibility_changed() -> void:
	if _tag_button.visible:
		_ensure_loaded()
		_tag_button.select(0)
		_apply_filters()
		_scroll.scroll_vertical = 0

## ───────────────────────────────────────────────────────────────────
## 6.  JSON utils
## ───────────────────────────────────────────────────────────────────
func _load_json(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
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


func _install():
	if not _is_loaded:
		return
	_apply_filters()

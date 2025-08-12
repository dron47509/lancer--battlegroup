extends PanelContainer
# class_name ShipCard

# ───────────────────────────────────────────
# 0.  Константа FLAGSHIP
# ───────────────────────────────────────────
const FLAGSHIP_OPTION := {
	"description":  "",
	"effect":       "",
	"feats":        [],
	"modification": {
		"HP":          "3",
		"auxiliary":   "0",
		"defence":     "0",
		"escort":      "0",
		"interdiction":"0",
		"point":       "0",
		"primary":     "0",
		"superheavy":  "0",
		"system":      "1",
		"wing":        "0",
	},
	"name":     "FLAGSHIP",
	"points":   0.0,
	"tags":     "Уникальное",
	"tenacity": "1d6",
	"type":     6,            # ← добавили
}


# ───────────────────────────────────────────
# 1.  UI-узлы
# ───────────────────────────────────────────
@onready var _name_edit   : LineEdit    = $Ship_box/MarginContainer2/HBoxContainer/Name
@onready var _flagman_btn : CheckBox    = $Ship_box/Ship_image/MarginContainer/Flagman
@onready var _img         : TextureRect = $Ship_box/Ship_image
@onready var _hull_name   : Label       = $Ship_box/Hulls_name
@onready var _point_lbl   : Label       = $Ship_box/Atributs/VBoxContainer/Point/Label
@onready var _hp_lbl_1    : Label       = $Ship_box/Atributs/HP/HBoxContainer/Label2
@onready var _hp_lbl_2    : Label       = $Ship_box/Atributs/HP/HBoxContainer/Label3
@onready var _def_lbl     : Label       = $Ship_box/Atributs/Defence/Label2

@onready var _opt_labels := {
	"superheavy":  $Ship_box/Options/Superheavies/Superheavy,
	"primaries":   $Ship_box/Options/Primaries/Primary,
	"auxiliaries": $Ship_box/Options/Auxiliaries/Auxiliary,
	"wings":       $Ship_box/Options/Wings/Wing,
	"escorts":     $Ship_box/Options/Escorts/Escort,
	# "systems" — счётчик рендерится внутри _systems_container
}
@onready var _slot_containers := {
	1: $Ship_box/Superheavy,   # Superheavy
	2: $Ship_box/Primary,      # Primaries
	3: $Ship_box/Auxiliary,    # Auxiliaries
	4: $Ship_box/Wing,          # Wings
	5: $Ship_box/Escort,        # Escorts
	6: $Ship_box/System,        # Systems
}

@onready var _systems_container : Control      = $Ship_box/Options/Systems
@onready var _system_count_lbl  : Label        = $Ship_box/Options/Systems/System

@onready var _feat_box      : VBoxContainer = $Ship_box/Feat
@onready var _tactic_box    : VBoxContainer = $Ship_box/Tactic
@onready var _maneuver_box  : VBoxContainer = $Ship_box/Maneuver
@onready var _primary_box   : VBoxContainer = $Ship_box/Primary
@onready var _opt_btn       : Button        = $Ship_box/MarginContainer/Button

# ───────────────────────────────────────────
# 2.  Данные экземпляра
# ───────────────────────────────────────────
var _dict  : Dictionary = {}   # ссылка на словарь корабля
var _index : int        = -1   # позиция в BattlegroupData.ships
var _base_system_slots : int   = 0   # базовое число системных слотов

# ───────────────────────────────────────────
# 3.  Public — populate
# ───────────────────────────────────────────
func populate(src : Dictionary) -> void:
	# 3.1  ссылка + индекс
	_dict = src
	_index = BattlegroupData.ships.find(src)
	if _index == -1:
		for i in BattlegroupData.ships.size():
			if BattlegroupData.ships[i].get("ship_name") == src["ship_name"]:
				_index = i
				break

	# 3.2  базовые данные → UI
	_name_edit.text = src["ship_name"]
	_img.texture = load("res://hulls/%s.png" % src["name"].replace("\n", " "))
	_flagman_btn.set_pressed_no_signal(src.get("flagman", false))
	_hull_name.text = src["name"]

	_base_system_slots = int(src["support_slots"]["systems"])

	# оружейные/поддерж-слоты (кроме systems, он рендерится отдельно)
	for k in ["superheavy", "primaries", "auxiliaries", "wings", "escorts"]:
		var slot_dict = src["weapon_slots"] if k in ["superheavy","primaries","auxiliaries"] else src["support_slots"]
		_opt_labels[k].text = slot_dict[k]

	# 3.3  черты / тактики / манёвры / primary
	_clear_containers()
	for feat in src["feats"]:
		var b := Button.new()
		b.text = feat["name"]
		match int(feat["type"]):
			0: _feat_box.add_child(b)
			1: _tactic_box.add_child(b)
			2: _maneuver_box.add_child(b)
			3: _primary_box.add_child(b)

	# 3.4  сигналы
	if not _name_edit.text_changed.is_connected(_on_name_changed):
		_name_edit.text_changed.connect(_on_name_changed)
	if not _flagman_btn.toggled.is_connected(_on_flagman_toggled):
		_flagman_btn.toggled.connect(_on_flagman_toggled)
	if not _opt_btn.pressed.is_connected(_on_option_pressed):
		_opt_btn.pressed.connect(_on_option_pressed)

	# 3.5  расчёт и отображение
	_recalc_and_update_display()

# ───────────────────────────────────────────
# 4.  Сигналы
# ───────────────────────────────────────────
func _on_name_changed(new_name : String) -> void:
	_dict["ship_name"] = new_name

func _on_flagman_toggled(on : bool) -> void:
	_dict["flagman"] = on
	if on:
		_add_flagship_option()
	else:
		_remove_flagship_option()
	_recalc_and_update_display()
	BattlegroupData.emit_signal("battlegroup_change")

func _on_option_pressed() -> void:
	BattlegroupData.curent_ship = _index
	BattlegroupData.change_on_option()

# ───────────────────────────────────────────
# 5.  Опция FLAGSHIP
# ───────────────────────────────────────────
func _has_flagship_option() -> bool:
	for o in _dict.get("option", []):
		if o.get("name") == "FLAGSHIP":
			return true
	return false

func _add_flagship_option() -> void:
	if _has_flagship_option():
		return
	_dict["option"].append(FLAGSHIP_OPTION.duplicate(true))

func _remove_flagship_option() -> void:
	for i in range(_dict["option"].size() - 1, -1, -1):
		if _dict["option"][i].get("name") == "FLAGSHIP":
			_dict["option"].remove_at(i)
			break

# ───────────────────────────────────────────
# 6.  Пересчёт характеристик + рендер
# ───────────────────────────────────────────
func _recalc_and_update_display() -> void:
	var hp      := int(_dict["hp"])
	var defence := int(_dict["defense"])
	var points  := int(_dict["points"])

	var weapon  = _dict["weapon_slots"].duplicate()
	var support = _dict["support_slots"].duplicate()

	# суммируем модификаторы всех опций
	for o in _dict.get("option", []):
		var m = o.get("modification", {})
		hp      += int(m.get("HP", "0"))
		defence += int(m.get("defence", "0"))
		points  += int(m.get("point", "0"))

		weapon["auxiliaries"] = str(int(weapon["auxiliaries"]) + int(m.get("auxiliary", "0")))
		weapon["primaries"]   = str(int(weapon["primaries"])   + int(m.get("primary", "0")))
		weapon["superheavy"]  = str(int(weapon["superheavy"])  + int(m.get("superheavy", "0")))

		support["systems"] = str(int(support["systems"]) + int(m.get("system", "0")))
		support["wings"]   = str(int(support["wings"])   + int(m.get("wing", "0")))
		support["escorts"] = str(int(support["escorts"]) + int(m.get("escort", "0")))

	# вывод основных чисел
	_hp_lbl_1.text = str(hp)
	_hp_lbl_2.text = str(hp)
	_def_lbl.text  = str(defence)
	_point_lbl.text = str(points)

	_opt_labels["auxiliaries"].text = weapon["auxiliaries"]
	_opt_labels["primaries"].text   = weapon["primaries"]
	_opt_labels["superheavy"].text  = weapon["superheavy"]

	_opt_labels["wings"].text   = support["wings"]
	_opt_labels["escorts"].text = support["escorts"]
	_system_count_lbl.text      = support["systems"]

	# 🔄 обновляем кнопки всех слотов
	_refresh_option_buttons()
# ───────────────────────────────────────────
# 7.  Кнопки Systems
# ───────────────────────────────────────────
func _refresh_system_buttons(total : int) -> void:
	# первый ребёнок контейнера — label-счётчик, остальные — динамические кнопки
	while _systems_container.get_child_count() > 1:
		_systems_container.get_child(1).queue_free()

	for i in range(total):
		var b := Button.new()
		b.text = str(i + 1)
		_systems_container.add_child(b)

# ───────────────────────────────────────────
# 8.  Вспомогательное
# ───────────────────────────────────────────
func _clear_containers() -> void:
	for box in [_feat_box, _tactic_box, _maneuver_box]:
		for c in box.get_children():
			c.queue_free()
	for box in _slot_containers.values():
		for c in box.get_children():
			c.queue_free()

func _refresh_option_buttons() -> void:
	# 3.1 очищаем всё, кроме первого ребёнка-Label в каждом контейнере
	for cont in _slot_containers.values():
		while cont.get_child_count() > 1:
			cont.get_child(1).queue_free()

	# 3.2 создаём кнопку с именем опции в нужном контейнере
	for o in _dict.get("option", []):
		var t := int(o.get("type", -1))
		if _slot_containers.has(t):
			var btn := Button.new()
			btn.text = str(o.get("name", ""))
			_slot_containers[t].add_child(btn)

extends PanelContainer
# class_name ShipCard

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
	"type":     6.0,
}

const FeatCard = preload("res://Main_scane/Commander/Feat_ship.tscn")
const hide_theme = preload("res://Main_scane/Commander/Battlegroup/Theme/Hide_button.tres")
# ───────────────────────────────────────────
# 1. UI-узлы
# ───────────────────────────────────────────
@onready var _name_edit   : LineEdit      = $Ship_box/MarginContainer2/HBoxContainer/Name
@onready var _delete_btn  : Button        = $Ship_box/MarginContainer2/HBoxContainer/Delete_ship
@onready var _flagman_btn : CheckBox      = $Ship_box/Ship_image/MarginContainer/Flagman
@onready var _img         : TextureRect   = $Ship_box/Ship_image
@onready var _hull_name   : Button        = $Ship_box/MarginContainer3/Hulls_name
@onready var _hide_box    : VBoxContainer = $Ship_box/VBoxContainer
@onready var _point_lbl   : Label         = $Ship_box/VBoxContainer/Atributs/Point/Point
@onready var _hp_lbl_1    : Label         = $Ship_box/VBoxContainer/Atributs/HP/HBoxContainer/Max_HP
@onready var _hp_lbl_2    : LineEdit      = $Ship_box/VBoxContainer/Atributs/HP/HBoxContainer/Current_HP
@onready var _def_lbl     : Label         = $Ship_box/VBoxContainer/Atributs/Defence/Defence

# Контейнеры слотов для опций
@onready var _slot_containers := {
	0.0: $Ship_box/VBoxContainer/Superheavy,   # Superheavy
	1.0: $Ship_box/VBoxContainer/Primary,      # Primaries
	2.0: $Ship_box/VBoxContainer/Auxiliary,    # Auxiliaries
	4.0: $Ship_box/VBoxContainer/Wing,         # Wings
	5.0: $Ship_box/VBoxContainer/Escort,       # Escorts
	3.0: $Ship_box/VBoxContainer/System,       # Systems
	6.0: $Ship_box/VBoxContainer/Feat,         # Feats (корпуса)
	7.0: $Ship_box/VBoxContainer/Tactic,       # Tactics (корпуса)
	8.0: $Ship_box/VBoxContainer/Maneuver      # Maneuvers (корпуса)
}

@onready var _feat_box      : VBoxContainer = $Ship_box/VBoxContainer/Feat
@onready var _tactic_box    : VBoxContainer = $Ship_box/VBoxContainer/Tactic
@onready var _maneuver_box  : VBoxContainer = $Ship_box/VBoxContainer/Maneuver
@onready var _primary_box   : VBoxContainer = $Ship_box/VBoxContainer/Primary
@onready var _opt_btn       : Button        = $Ship_box/VBoxContainer/MarginContainer/Add_option
@onready var _overshild     : LineEdit      = $Ship_box/VBoxContainer/Atributs/Overshild/Overshild
# ───────────────────────────────────────────
# 2. Данные экземпляра
# ───────────────────────────────────────────
var ship_cur  : Dictionary = {}  # ссылка на словарь корабля из BattlegroupData.ships
var _index    : int        = -1
var _base_system_slots : int = 0

func _ready() -> void:
	BattlegroupData.option_change.connect(_refresh_option_buttons)
	BattlegroupData.option_change.connect(change_hp)

# ───────────────────────────────────────────
# 3. Public — populate
# ───────────────────────────────────────────
func populate(src : Dictionary) -> void:
	# 3.1  ссылка + индекс
	ship_cur = src
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

	# 3.3  сигналы
	if not _name_edit.text_changed.is_connected(_on_name_changed):
		_name_edit.text_changed.connect(_on_name_changed)
	if not _flagman_btn.toggled.is_connected(_on_flagman_toggled):
		_flagman_btn.toggled.connect(_on_flagman_toggled)
	if not _opt_btn.pressed.is_connected(_on_option_pressed):
		_opt_btn.pressed.connect(_on_option_pressed)
	if not _delete_btn.pressed.is_connected(_on_delete_pressed):
		_delete_btn.pressed.connect(_on_delete_pressed)

	# 3.4  расчёт и отображение
	_recalc_and_update_display()
	_refresh_option_buttons()

# ───────────────────────────────────────────
# 4.  Сигналы
# ───────────────────────────────────────────
func _on_name_changed(new_name : String) -> void:
	ship_cur["ship_name"] = new_name

func _on_flagman_toggled(on : bool) -> void:
	if on:
		BattlegroupData.ships[_index]["option"].append(FLAGSHIP_OPTION)
		BattlegroupData.refresh_point()
		_refresh_option_buttons()
	else:
		var arr = BattlegroupData.ships[_index]["option"]
		for i in range(arr.size() - 1, -1, -1):
			if arr[i].get("name") == FLAGSHIP_OPTION.get("name"):
				arr.remove_at(i)
				BattlegroupData.refresh_point()
				_refresh_option_buttons()
				break

func _on_option_pressed() -> void:
	BattlegroupData.current_ship = _index
	BattlegroupData.change_on_option()

func _on_delete_pressed() -> void:
	var cls := int(ship_cur.get("class", -1))
	var idx := BattlegroupData.ships.find(ship_cur)
	if idx == -1:
		return

	BattlegroupData.ships.remove_at(idx)

	# поправим current_ship, чтобы индексы не поехали
	if BattlegroupData.current_ship == idx:
		BattlegroupData.current_ship = -1
	elif BattlegroupData.current_ship > idx:
		BattlegroupData.current_ship -= 1

	# счётчик классов и очки
	if BattlegroupData.class_counts.has(cls):
		BattlegroupData.class_counts[cls] = max(BattlegroupData.class_counts[cls] - 1, 0)

	BattlegroupData.refresh_point()
	BattlegroupData.emit_signal("battlegroup_change")
	queue_free()

# ───────────────────────────────────────────
# 5. Вспомогательное — построение кнопок + карточек
# ───────────────────────────────────────────

func _clear_containers_keep_titles() -> void:
	# Очищаем динамику; если в контейнере первый ребёнок — Label, оставляем его.
	for cont in _slot_containers.values():
		var to_remove : Array = []
		for i in range(cont.get_child_count()):
			var ch = cont.get_child(i)
			if i == 0 and ch is Label:
				continue
			to_remove.append(ch)
		for n in to_remove:
			n.queue_free()

func _add_button_with_card(to_container: VBoxContainer, data: Dictionary, removable: bool) -> void:
	var btn := Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.theme = hide_theme
	var marg := MarginContainer.new()
	var panel := PanelContainer.new()
	#btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = str(data.get("name", ""))
	panel.add_child(marg)
	marg.add_child(btn)
	to_container.add_child(panel)

	var card: PanelContainer = FeatCard.instantiate()
	card.visible = false
	to_container.add_child(card)

	# передаём данные
	card.call_deferred("populate", data)
	if card.has_method("set_pair"):
		card.call_deferred("set_pair", panel)
	if card.has_method("set_context"):
		card.call_deferred("set_context", removable, ship_cur, false)  # ← ВАЖНО

	btn.pressed.connect(func():
		panel.visible = false
		card.visible = true
	)
	
func _add_button_with_card_special(to_container: VBoxContainer, data: Dictionary, removable: bool) -> void:
	var btn := Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.theme = hide_theme
	var marg := MarginContainer.new()
	var panel := PanelContainer.new()
	btn.text = str(data.get("name", ""))
	panel.add_child(marg)
	marg.add_child(btn)
	to_container.add_child(panel)

	var card: PanelContainer = FeatCard.instantiate()
	card.visible = false
	to_container.add_child(card)

	card.call_deferred("populate", data)
	if card.has_method("set_pair"):
		card.call_deferred("set_pair", panel)
	if card.has_method("set_context"):
		card.call_deferred("set_context", removable, ship_cur, true)  # ← для SPECIAL

	btn.pressed.connect(func():
		panel.visible = false
		card.visible = true
	)

func _build_from_special_options() -> void:
	for o in ship_cur.get("special", []):
		var t = o.get("type", -1)
		if _slot_containers.has(t):
			_add_button_with_card_special(_slot_containers[t], o, true)

		# если у special-опции есть вложенные feats — тоже добавим
		for sub in o.get("feats", []):
			match int(sub.get("type", -1)):
				0:  _add_button_with_card_special(_feat_box,     sub, false)
				1:  _add_button_with_card_special(_maneuver_box, sub, false)
				2:  _add_button_with_card_special(_tactic_box,   sub, false)
				3:  _add_button_with_card_special(_primary_box,  sub, false)
				_:  pass

func _build_from_top_level_feats() -> void:
	# Черты/Тактики/Манёвры/Орудия, заданные в hull.feats
	for f in ship_cur.get("feats", []):
		match int(f.get("type", -1)):
			0:  _add_button_with_card(_feat_box,     f, false)  # Черта
			1:  _add_button_with_card(_maneuver_box, f, false)  # Манёвр
			2:  _add_button_with_card(_tactic_box,   f, false)  # Тактика
			3:  _add_button_with_card(_primary_box,  f, false)  # Орудие (если встречается в списке feats)
			_:  pass

func _build_from_options() -> void:
	# Сами опции — в свои секции слотов
	for o in ship_cur.get("option", []):
		var t = o.get("type", -1)
		if _slot_containers.has(t):
			_add_button_with_card(_slot_containers[t], o, true)

		# Вложенные "feats" внутри опции — добавить как отдельные элементы
		for sub in o.get("feats", []):
			match int(sub.get("type", -1)):
				0:  _add_button_with_card(_feat_box,     sub, false)
				1:  _add_button_with_card(_maneuver_box, sub, false)
				2:  _add_button_with_card(_tactic_box,   sub, false)
				3:  _add_button_with_card(_primary_box,  sub, false)
				_:  pass

func _refresh_option_buttons() -> void:
	_clear_containers_keep_titles()
	_build_from_top_level_feats()
	_build_from_options()
	_build_from_special_options()

# ───────────────────────────────────────────
# 6.  Пересчёт характеристик + рендер
# ───────────────────────────────────────────
func _recalc_and_update_display() -> void:
	var hp      := int(ship_cur["hp"])
	var defence := int(ship_cur["defense"])
	var points  := int(ship_cur["points"])

	var weapon  = ship_cur["weapon_slots"].duplicate()
	var support = ship_cur["support_slots"].duplicate()

	# суммируем модификаторы всех опций
	for o in ship_cur.get("option", []):
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
	_hp_lbl_1.text  = str(hp)
	if ship_cur["name"] == "HA\nLOUIS XIV–CLASS DREADNOUGHT":
		_overshild.text = "5"
	_hp_lbl_2.text  = str(hp)
	_def_lbl.text   = str(defence)
	_point_lbl.text = str(points)


func _on_hulls_name_pressed() -> void:
	if _hide_box.visible:
		_hide_box.hide()
	else:
		_hide_box.show()


func _on_overshild_text_changed(new_text: String) -> void:
	if ship_cur["name"] == "HA\nLOUIS XIV–CLASS DREADNOUGHT":
		if new_text == "0" or new_text == "":
			_def_lbl.text = "13"
		else:
			_def_lbl.text = "15"

func change_hp():
	_hp_lbl_1.text  = ship_cur["hp"]

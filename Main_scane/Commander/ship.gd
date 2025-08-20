extends PanelContainer
# class_name ShipCard

const FLAGSHIP_OPTION := {
	"description":  "",
	"effect":       "",
	"feats":        [],
	"modification": {
		"HP":          "0",
		"auxiliary":   "0",
		"defence":     "0",
		"escort":      "0",
		"interdiction":"0",
		"point":       "0",
		"primary":     "0",
		"superheavy":  "0",
		"system":      "0",   # ← чтобы не было двойного +1 к системам
		"wing":        "0",
	},
	"name":     "FLAGSHIP",
	"points":   "0",
	"tags":     "Уникальное",
	"tenacity": "0",
	"type":     6.0,
}

const FeatCard = preload("res://Main_scane/Commander/Feat_ship.tscn")
const hide_theme = preload("res://Main_scane/Commander/Battlegroup/Theme/Hide_button.tres")
const SlotUtils            = preload("res://slot_utils.gd")
const Opt                  = preload("res://option_types.gd")
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
# 2.1 Вспомогательные утилитыв
# ───────────────────────────────────────────

func _inc_hp(by: int) -> void:
	var hp := _to_int(ship_cur.get("hp", 0)) + by
	ship_cur["hp"] = str(max(hp, 1))  # защита от нуля

func _inc_system_slots(by: int) -> void:
	var ss = ship_cur.get("support_slots", {})
	var cur := _to_int(ss.get("systems", 0)) + by
	ss["systems"] = str(max(cur, 0))
	ship_cur["support_slots"] = ss

func _has_flagship_option() -> int:
	var arr: Array = ship_cur.get("option", [])
	for i in range(arr.size() - 1, -1, -1):
		if String(arr[i].get("name","")) == "FLAGSHIP":
			return i
	return -1

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
	var ship = BattlegroupData.ships[_index]

	if on:
		# Если на этом корабле ещё нет FLAGSHIP — ставим
		if _has_flagship_option() == -1:
			ship["option"].append(FLAGSHIP_OPTION.duplicate(true))
			_inc_system_slots(+1)  # +1 слот систем
			_inc_hp(+3)            # +3 HP
		ship["flagman"] = true
		
		BattlegroupData.refresh_point()
		change_hp()
		_refresh_option_buttons()
	else:
		# Снимаем только если FLAGSHIP действительно стоит на ЭТОМ корабле
		var idx := _has_flagship_option()
		if idx != -1:
			ship["option"].remove_at(idx)
			_inc_system_slots(-1)  # -1 слот систем
			_inc_hp(-3)            # -3 HP
		ship["flagman"] = false
		remove_overflow_by_sum()
		BattlegroupData.refresh_point()
		change_hp()
		_refresh_option_buttons()

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
		card.call_deferred("set_context", removable, ship_cur, false)

	btn.pressed.connect(func():
		panel.visible = false
		card.visible = true
	)

func _add_button_with_card_special(to_container: VBoxContainer, data: Dictionary, removable: bool) -> void:
	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
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
		card.call_deferred("set_context", removable, ship_cur, true)

	btn.pressed.connect(func():
		panel.visible = false
		card.visible = true
	)

func _build_from_special_options() -> void:
	for o in ship_cur.get("special", []):
		var t = o.get("type", -1)
		var base = o
		if _is_apeiron() and int(t) == int(Opt.Support.WING) or int(t) == int(Opt.SlotIndex.WINGS) or float(t) == 4.0:
			base = _apply_range_bonus_if_wing(o)

		if _slot_containers.has(t):
			_add_button_with_card_special(_slot_containers[t], base, true)

		for sub in o.get("feats", []):
			var item = sub
			if base != o:
				item = _apply_range_bonus_if_wing(sub)
			match int(sub.get("type", -1)):
				0:  _add_button_with_card_special(_feat_box,     item, false)
				1:  _add_button_with_card_special(_maneuver_box, item, false)
				2:  _add_button_with_card_special(_tactic_box,   item, false)
				3:  _add_button_with_card_special(_primary_box,  item, false)
				_:  pass

func _build_from_top_level_feats() -> void:
	for f in ship_cur.get("feats", []):
		match int(f.get("type", -1)):
			0:  _add_button_with_card(_feat_box,     f, false)
			1:  _add_button_with_card(_maneuver_box, f, false)
			2:  _add_button_with_card(_tactic_box,   f, false)
			3:  _add_button_with_card(_primary_box,  f, false)
			_:  pass

func _build_from_options() -> void:
	for o in ship_cur.get("option", []):
		var t = o.get("type", -1)
		var base = o
		# если это APEIRON и это крыло — работаем на копии с повышенным range
		if _is_apeiron() and int(t) == int(Opt.Support.WING) or int(t) == int(Opt.SlotIndex.WINGS) or float(t) == 4.0:
			base = _apply_range_bonus_if_wing(o)
		# кнопка/карточка для самой опции
		if _slot_containers.has(t):
			_add_button_with_card(_slot_containers[t], base, true)

		# фичи внутри опции; если родитель — крыло, повышаем и им
		for sub in o.get("feats", []):
			var item = sub
			if _is_apeiron() and int(t) == int(Opt.Support.WING) or int(t) == int(Opt.SlotIndex.WINGS) or float(t) == 4.0:  # значит родитель — крыло и мы уже применили буст
				item = _apply_range_bonus_if_wing(sub)
			match int(sub.get("type", -1)):
				0:  _add_button_with_card(_feat_box,     item, false)
				1:  _add_button_with_card(_maneuver_box, item, false)
				2:  _add_button_with_card(_tactic_box,   item, false)
				3:  _add_button_with_card(_primary_box,  item, false)
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

	# Суммируем модификаторы всех опций (FLAGSHIP ничего не даёт здесь — мы уже учли напрямую)
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


# ─────────────────────────────────────────────────────────────
# Хелперы
# ─────────────────────────────────────────────────────────────
func _is_apeiron() -> bool:
	return String(ship_cur.get("name","")) == "SSC\nAPEIRON-CLASS STRIKE CARRIER"

func _range_plus_one_capped(r: String) -> String:
	if r == null:
		return ""
	var s := String(r).strip_edges().replace("–", "-")  # на случай en dash
	if s == "" or (not s[0].is_valid_int() and "-" not in s):
		return s
	var parts := s.split("-")
	if parts.size() == 1:
		var a = clamp(_to_int(parts[0]) + 1, 0, 5)
		return str(a)
	else:
		var a = clamp(_to_int(parts[0]) + 1, 0, 5)
		var b = clamp(_to_int(parts[1]) + 1, 0, 5)
		return "%d-%d" % [a, b]

func _range_in_text_plus_one_capped(text: String) -> String:
	if text == null:
		return ""
	var s := String(text)
	var re := RegEx.new()
	# Матчим одиночные/двузначные числа по обе стороны дефиса/эн-даша, но не как часть других чисел/слов.
	re.compile(r"(?<!\d)(\d+)\s*(?:-|–)\s*(\d+)(?!\d)")
	var matches := re.search_all(s)
	if matches == null or matches.is_empty():
		return s
	var out := ""
	var pos := 0
	for m in matches:
		var a_str := m.get_string(1)
		var b_str := m.get_string(2)
		var a = clamp(_to_int(a_str) + 1, 0, 5)
		var b = clamp(_to_int(b_str) + 1, 0, 5)
		out += s.substr(pos, m.get_start() - pos)
		out += "%d-%d" % [a, b]
		pos = m.get_end()
	out += s.substr(pos)
	return out

# Рекурсивно применяем бонус к range и к любым строковым полям effect.
func _apply_range_bonus_in_dict(d: Dictionary) -> void:
	if d.has("range") and String(d["range"]).strip_edges() != "":
		d["range"] = _range_plus_one_capped(d["range"])
	if d.has("effect") and String(d["effect"]).strip_edges() != "":
		d["effect"] = _range_in_text_plus_one_capped(d["effect"])
	# Пройтись по вложенным структурам
	for k in d.keys():
		var v = d[k]
		if v is Dictionary:
			_apply_range_bonus_in_dict(v)
		elif v is Array:
			for i in v:
				if i is Dictionary:
					_apply_range_bonus_in_dict(i)

func _apply_range_bonus_if_wing(data: Dictionary) -> Dictionary:
	var copy := data.duplicate(true)
	_apply_range_bonus_in_dict(copy)
	return copy

func _to_int(v) -> int:
	var t := typeof(v)
	if t == TYPE_INT:
		return v
	if t == TYPE_FLOAT:
		return int(round(v))
	if t == TYPE_STRING:
		var s := String(v).strip_edges()
		if s == "":
			return 0
		if s.is_valid_int():
			return s.to_int()
		if s.is_valid_float():
			return int(round(s.to_float()))
		return 0
	return 0

func _dec_support_slot(slot_key: String, by: int) -> void:
	var ss = ship_cur.get("support_slots", {})
	var cur := _to_int(ss.get(slot_key, 0))
	ss[slot_key] = str(max(cur - by, 0))
	ship_cur["support_slots"] = ss

# удалить ПОСЛЕДНИЙ элемент нужного типа и вернуть его ({} если не найден)
func _remove_last_and_get(arr: Array, types_to_match: Array) -> Dictionary:
	for i in range(arr.size() - 1, -1, -1):
		var t := int(arr[i].get("type", -999))
		if t in types_to_match:
			var removed = arr[i]
			arr.remove_at(i)
			return removed
	return {}

# оставить, если где-то ещё используется
func _remove_last_by_types(arr: Array, types_to_match: Array) -> bool:
	for i in range(arr.size() - 1, -1, -1):
		var t := int(arr[i].get("type", -999))
		if t in types_to_match:
			arr.remove_at(i)
			return true
	return false

# ─────────────────────────────────────────────────────────────
# КАСКАДНАЯ обрезка: wings/escorts/systems по SlotUtils.get_slot_sums(ship_cur)
# Если лишней системой оказались SUBLINE BERTH / FIGHTER LAUNCH CATAPULTS,
# дополнительно уменьшаем кап соответствующих слотов и продолжаем цикл.
# Возвращает true, если что-то удалили.
# ─────────────────────────────────────────────────────────────
func remove_overflow_by_sum() -> bool:
	var opts: Array = ship_cur.get("option", [])
	if opts.is_empty():
		return false

	var changed := false
	var guard := 0

	while true:
		guard += 1
		if guard > 64:
			break

		var sums := SlotUtils.get_slot_sums(ship_cur)
		var wing_sum   := _to_int(sums.get("wing",   0))
		var escort_sum := _to_int(sums.get("escort", 0))
		var system_sum := _to_int(sums.get("system", 0))

		# 1) Крылья
		if wing_sum < 0:
			var rem_w := _remove_last_and_get(opts, [Opt.Support.WING, Opt.SlotIndex.WINGS])
			if rem_w.size() == 0:
				break
			changed = true
			BattlegroupData.refresh_point()
			continue

		# 2) Эскорты
		if escort_sum < 0:
			var rem_e := _remove_last_and_get(opts, [Opt.Support.ESCORT, Opt.SlotIndex.ESCORTS])
			if rem_e.size() == 0:
				break
			changed = true
			BattlegroupData.refresh_point()
			continue

		# 3) Системы
		if system_sum < 0:
			var rem_s := _remove_last_and_get(opts, [Opt.SlotIndex.SYSTEMS])
			if rem_s.size() == 0:
				break
			changed = true

			var rname := String(rem_s.get("name", ""))
			# если сняли систему, которая добавляла кап — срежем его тоже
			if rname == "SUBLINE BERTH":
				_dec_support_slot("escorts", 1)
				BattlegroupData.refresh_point()
				continue
			elif rname == "FIGHTER LAUNCH CATAPULTS":
				_dec_support_slot("wings", 1)
				BattlegroupData.refresh_point()
				continue

			BattlegroupData.refresh_point()
			continue

		# ничего не уходит в минус — выходим
		break


	return changed

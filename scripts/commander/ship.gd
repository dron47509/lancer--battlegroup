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
	"points":   "",
	"tags":     "",
	"tenacity": "",
	"type":     6.0,
}

const FeatCard = preload("res://scenes/support/item_card.tscn")
const Opt                  = preload("res://scripts/core/option_types.gd")
const DESTROYED_MODULATE := Color(0.6, 0.6, 0.6, 1.0)
const LOUIS_NAME_FRAGMENT := "LOUIS XIV"
const SCKV_FLAG_KEY := "is_sckv"
# ───────────────────────────────────────────
# 1. UI-узлы
# ───────────────────────────────────────────
@onready var _name_edit   : LineEdit      = $Ship_box/MarginContainer2/HBoxContainer/Name
@onready var _delete_btn  : Button        = $Ship_box/MarginContainer2/HBoxContainer/Delete_ship
@onready var _flagman_btn : CheckBox      = $Ship_box/Ship_image/MarginContainer/Flagman
@onready var _img         : TextureRect   = $Ship_box/Ship_image
@onready var _hull_name   : Button        = $Ship_box/MarginContainer3/Hulls_name
@onready var _hide_box    : VBoxContainer = $Ship_box/VBoxContainer
@onready var _point_container: Control    = $Ship_box/VBoxContainer/Atributs/Point
@onready var _point_lbl   : Label         = $Ship_box/VBoxContainer/Atributs/Point/Point
@onready var _hp_lbl_1    : Label         = $Ship_box/VBoxContainer/Atributs/HP/HBoxContainer/Max_HP
@onready var _hp_lbl_2    : LineEdit      = $Ship_box/VBoxContainer/Atributs/HP/HBoxContainer/Current_HP
@onready var _hp_sep      : Label         = $Ship_box/VBoxContainer/Atributs/HP/HBoxContainer/Sep
@onready var _overshild_container: Control = $Ship_box/VBoxContainer/Atributs/Overshild
@onready var _def_lbl     : Label         = $Ship_box/VBoxContainer/Atributs/Defence/Defence
@onready var _options_panel: Control       = $Ship_box/VBoxContainer/Options
@onready var _options_separator: HSeparator = $Ship_box/VBoxContainer/HSeparator4
@onready var _note_container: Control = $Ship_box/VBoxContainer/MarginContainer2
@onready var _note_edit: TextEdit = $Ship_box/VBoxContainer/MarginContainer2/Note/TextEdit

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
	8.0: $Ship_box/VBoxContainer/Maneuver,     # Maneuvers (корпуса)
	"legacy": $Ship_box/VBoxContainer/Legacy   # Legacies
}

@onready var _feat_box      : VBoxContainer = $Ship_box/VBoxContainer/Feat
@onready var _legacy_box    : VBoxContainer = $Ship_box/VBoxContainer/Legacy
@onready var _tactic_box    : VBoxContainer = $Ship_box/VBoxContainer/Tactic
@onready var _maneuver_box  : VBoxContainer = $Ship_box/VBoxContainer/Maneuver
@onready var _primary_box   : VBoxContainer = $Ship_box/VBoxContainer/Primary
@onready var _opt_btn_container: Control = $Ship_box/VBoxContainer/MarginContainer
@onready var _opt_btn       : Button        = $Ship_box/VBoxContainer/MarginContainer/Add_option
@onready var _legacy_btn_container: Control = $Ship_box/VBoxContainer/MarginContainer_Legacy
@onready var _legacy_btn    : Button        = $Ship_box/VBoxContainer/MarginContainer_Legacy/Add_legacy
@onready var _overshild     : LineEdit      = $Ship_box/VBoxContainer/Atributs/Overshild/Overshild
# ───────────────────────────────────────────
# 2. Данные экземпляра
# ───────────────────────────────────────────
var ship_cur  : Dictionary = {}  # ссылка на словарь корабля из BattlegroupData.ships
var _index    : int        = -1
var _base_system_slots : int = 0
var _seen_tactics: Dictionary = {}
var _seen_maneuvers: Dictionary = {}
var _max_hp_cached: int = 0
var _base_defence_cached: int = 0
var _hp_edit_guard := false
var _overshild_edit_guard := false
var _note_edit_guard := false
var _is_sckv := false

func _ready() -> void:
	BattlegroupData.option_change.connect(_refresh_option_buttons)
	BattlegroupData.option_change.connect(change_hp)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	if not BattlegroupData.flagship_changed.is_connected(_on_flagship_changed):
		BattlegroupData.flagship_changed.connect(_on_flagship_changed)
	_apply_battle_state()

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
	_is_sckv = bool(ship_cur.get(SCKV_FLAG_KEY, false))
	if _is_sckv:
		ship_cur["flagman"] = false
	if not ship_cur.has("hp"):
		ship_cur["hp"] = "0"
	if not ship_cur.has("defense"):
		ship_cur["defense"] = "0"
	if not ship_cur.has("points"):
		ship_cur["points"] = "0"
	if not ship_cur.has("weapon_slots"):
		ship_cur["weapon_slots"] = {"auxiliaries":"0","primaries":"0","superheavy":"0"}
	if not ship_cur.has("support_slots"):
		ship_cur["support_slots"] = {"systems":"0","wings":"0","escorts":"0"}
	if not ship_cur.has("option"):
		ship_cur["option"] = []
	if not ship_cur.has("legacies"):
		ship_cur["legacies"] = []
	if not ship_cur.has("note"):
		ship_cur["note"] = ""
	_index = BattlegroupData.ships.find(src)
	if _index == -1:
		for i in BattlegroupData.ships.size():
			if BattlegroupData.ships[i].get("ship_name") == src["ship_name"]:
				_index = i
				break

	# 3.2  базовые данные → UI
	_name_edit.text = src["ship_name"]
	$Ship_box/MarginContainer2/HBoxContainer/Label.text = src["ship_name"]
	if _is_sckv:
		_img.texture = null
	else:
		var hull_path := "res://assets/hulls/%s.png" % src["name"].replace("\n", " ")
		if ResourceLoader.exists(hull_path):
			_img.texture = load(hull_path)
		else:
			_img.texture = null
	_sync_flagman_state()
	_hull_name.text = src["name"]

	_base_system_slots = int(src["support_slots"]["systems"])

	# 3.3  сигналы
	if not _name_edit.text_changed.is_connected(_on_name_changed):
		_name_edit.text_changed.connect(_on_name_changed)
	if not _flagman_btn.toggled.is_connected(_on_flagman_toggled):
		_flagman_btn.toggled.connect(_on_flagman_toggled)
	_flagman_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if not _hp_lbl_2.text_changed.is_connected(_on_current_hp_changed):
		_hp_lbl_2.text_changed.connect(_on_current_hp_changed)
	if not _opt_btn.pressed.is_connected(_on_option_pressed):
		_opt_btn.pressed.connect(_on_option_pressed)
	if not _legacy_btn.pressed.is_connected(_on_legacy_pressed):
		_legacy_btn.pressed.connect(_on_legacy_pressed)
	if not _delete_btn.pressed.is_connected(_on_delete_pressed):
		_delete_btn.pressed.connect(_on_delete_pressed)
	if is_instance_valid(_note_edit):
		if not _note_edit.text_changed.is_connected(_on_note_text_changed):
			_note_edit.text_changed.connect(_on_note_text_changed)
		_note_edit_guard = true
		_note_edit.text = String(ship_cur.get("note", ""))
		_note_edit_guard = false

	# 3.4  расчёт и отображение
	_recalc_and_update_display()
	_refresh_option_buttons()
	_apply_sckv_overrides()

# ───────────────────────────────────────────
# 4.  Сигналы
# ───────────────────────────────────────────
func _on_name_changed(new_name : String) -> void:
	ship_cur["ship_name"] = new_name
	BattlegroupData.save_data()

func _on_flagman_toggled(on : bool) -> void:
	if _is_sckv:
		_sync_flagman_state()
		return
	if BattlegroupData.in_battle:
		_sync_flagman_state()
		return
	_resolve_current_index()
	if on:
		BattlegroupData.set_flagship(_index)
	else:
		_sync_flagman_state()

func _on_option_pressed() -> void:
	BattlegroupData.current_ship = _resolve_current_index()
	BattlegroupData.request_option_list()

func _on_legacy_pressed() -> void:
	if _is_sckv:
		return
	BattlegroupData.current_ship = _resolve_current_index()
	BattlegroupData.change_on_legacies()

func _on_flagship_changed(_flagship_index: int) -> void:
	_recalc_and_update_display()
	_refresh_option_buttons()
	_sync_flagman_state()

func _sync_flagman_state() -> void:
	if ship_cur.is_empty():
		return
	if is_instance_valid(_flagman_btn):
		var is_flag := bool(ship_cur.get("flagman", false))
		_flagman_btn.set_pressed_no_signal(is_flag)
		_flagman_btn.disabled = BattlegroupData.in_battle

func _on_note_text_changed() -> void:
	if _note_edit_guard:
		return
	if ship_cur.is_empty():
		return
	ship_cur["note"] = _note_edit.text
	BattlegroupData.save_data()


func _on_battle_state_changed(_enabled: bool) -> void:
	_apply_battle_state()


func _apply_battle_state() -> void:
	if not BattlegroupData.in_battle:
		_reset_current_hp_to_max()
	if is_instance_valid(_opt_btn):
		_opt_btn.visible = not BattlegroupData.in_battle
	if is_instance_valid(_opt_btn_container):
		_opt_btn_container.visible = not BattlegroupData.in_battle
	if is_instance_valid(_legacy_btn):
		_legacy_btn.visible = not BattlegroupData.in_battle
	if is_instance_valid(_legacy_btn_container):
		_legacy_btn_container.visible = not BattlegroupData.in_battle
	if is_instance_valid(_delete_btn):
		_delete_btn.visible = not BattlegroupData.in_battle
	if is_instance_valid(_point_container):
		_point_container.visible = not BattlegroupData.in_battle
	if is_instance_valid(_overshild_container):
		_overshild_container.visible = BattlegroupData.in_battle
	if is_instance_valid(_hp_lbl_2):
		_hp_lbl_2.visible = BattlegroupData.in_battle
		_hp_lbl_2.editable = BattlegroupData.in_battle
	if is_instance_valid(_hp_sep):
		_hp_sep.visible = false
	if is_instance_valid(_hp_lbl_1):
		_hp_lbl_1.visible = not BattlegroupData.in_battle
	if is_instance_valid(_options_panel):
		_options_panel.visible = not BattlegroupData.in_battle
	if is_instance_valid(_options_separator):
		_options_separator.visible = not BattlegroupData.in_battle
	if is_instance_valid(_note_container):
		_note_container.visible = BattlegroupData.in_battle
	if is_instance_valid(_note_edit):
		_note_edit.editable = BattlegroupData.in_battle
	_sync_flagman_state()
	_update_defence_label()
	_apply_sckv_overrides()

func _apply_sckv_overrides() -> void:
	if not _is_sckv:
		return
	if is_instance_valid(_delete_btn):
		_delete_btn.visible = false
		_delete_btn.disabled = true
	if is_instance_valid(_flagman_btn):
		_flagman_btn.visible = false
		_flagman_btn.disabled = true
	if is_instance_valid(_img):
		_img.visible = false
	if is_instance_valid(_hull_name):
		_hull_name.visible = false
	if is_instance_valid(_point_container):
		_point_container.visible = false
	if is_instance_valid(_legacy_btn):
		_legacy_btn.visible = false

func _reset_current_hp_to_max() -> void:
	if ship_cur.is_empty():
		return
	var max_hp := _max_hp_cached
	if max_hp <= 0:
		max_hp = _to_int(ship_cur.get("hp", 0))
	if max_hp <= 0:
		_recalc_and_update_display()
		max_hp = _max_hp_cached
	ship_cur["current_hp"] = str(max_hp)
	_set_current_hp(max_hp)
	_apply_destroyed_state()

func _on_delete_pressed() -> void:
	if _is_sckv:
		return
	var cls := int(ship_cur.get("class", -1))
	var idx := BattlegroupData.ships.find(ship_cur)
	if idx == -1:
		return
	var removed_was_flagman := bool(ship_cur.get("flagman", false))
	var removed_name := String(ship_cur.get("name", ""))

	BattlegroupData.ships.remove_at(idx)

	# поправим current_ship, чтобы индексы не поехали
	if BattlegroupData.current_ship == idx:
		BattlegroupData.current_ship = -1
	elif BattlegroupData.current_ship > idx:
		BattlegroupData.current_ship -= 1

	# счётчик классов и очки
	if BattlegroupData.class_counts.has(cls):
		BattlegroupData.class_counts[cls] = max(BattlegroupData.class_counts[cls] - 1, 0)

	if removed_name == BattlegroupData.HESPERIS_HULL_NAME:
		for i in range(BattlegroupData.ships.size() - 1, -1, -1):
			var ship = BattlegroupData.ships[i]
			if not bool(ship.get(BattlegroupData.SCKV_FLAG_KEY, false)):
				continue
			if String(ship.get(BattlegroupData.SCKV_HOST_KEY, "")) != removed_name:
				continue
			BattlegroupData.ships.remove_at(i)
			if BattlegroupData.current_ship == i:
				BattlegroupData.current_ship = -1
			elif BattlegroupData.current_ship > i:
				BattlegroupData.current_ship -= 1

	if removed_was_flagman and not BattlegroupData.ships.is_empty():
		BattlegroupData.ensure_flagship()
	else:
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

func _add_card(to_container: VBoxContainer, data: Dictionary, removable: bool, is_option_item: bool=false, context_mode: String = "option") -> void:
	var card: Control = FeatCard.instantiate()
	to_container.add_child(card)
	if card.has_method("setup"):
		card.call_deferred("setup", data, removable, ship_cur, is_option_item, context_mode, true)
		return
	if card.has_method("populate"):
		card.call_deferred("populate", data)
	if card.has_method("set_context"):
		card.call_deferred("set_context", removable, ship_cur, is_option_item, context_mode)
	if card.has_method("set_collapsed"):
		card.call_deferred("set_collapsed", true)

func _build_from_special_options() -> void:
	for o in _sorted_by_name(ship_cur.get("special", [])):
		var t = o.get("type", -1)

		if _slot_containers.has(t):
			_add_card(_slot_containers[t], o, true, true)

		for sub in _sorted_by_name(o.get("feats", [])):
			match int(sub.get("type", -1)):
				0:  _add_card(_feat_box,     sub, false, true)
				1:
					if _register_feat(_seen_maneuvers, sub):
						_add_card(_maneuver_box, sub, false, true)
				2:
					if _register_feat(_seen_tactics, sub):
						_add_card(_tactic_box,   sub, false, true)
				3:  _add_card(_primary_box,  sub, false, true)
				_:  pass

func _build_from_top_level_feats() -> void:
	for f in _sorted_by_name(ship_cur.get("feats", [])):
		match int(f.get("type", -1)):
			0:  _add_card(_feat_box,     f, false)
			1:
				if _register_feat(_seen_maneuvers, f):
					_add_card(_maneuver_box, f, false)
			2:
				if _register_feat(_seen_tactics, f):
					_add_card(_tactic_box,   f, false)
			3:  _add_card(_primary_box,  f, false)
			_:  pass

func _build_from_options() -> void:
	for o in _sorted_by_name(ship_cur.get("option", [])):
		var t = o.get("type", -1)
		# кнопка/карточка для самой опции
		if _slot_containers.has(t):
			_add_card(_slot_containers[t], o, true)

		# фичи внутри опции; если родитель — крыло, повышаем и им
		for sub in _sorted_by_name(o.get("feats", [])):
			match int(sub.get("type", -1)):
				0:  _add_card(_feat_box,     sub, false)
				1:
					if _register_feat(_seen_maneuvers, sub):
						_add_card(_maneuver_box, sub, false)
				2:
					if _register_feat(_seen_tactics, sub):
						_add_card(_tactic_box,   sub, false)
				3:  _add_card(_primary_box,  sub, false)
				_:  pass


func _build_from_legacies() -> void:
	for l in _sorted_by_name(ship_cur.get("legacies", [])):
		_add_card(_legacy_box, l, true, false, "legacy")

func _refresh_option_buttons() -> void:
	_clear_containers_keep_titles()
	_reset_feat_dedupe()
	_build_from_top_level_feats()
	_build_from_options()
	_build_from_special_options()
	_build_from_legacies()
	call_deferred("_deferred_sort_option_containers")

func _resolve_current_index() -> int:
	var idx := BattlegroupData.ships.find(ship_cur)
	if idx == -1:
		var ship_name := String(ship_cur.get("ship_name", ""))
		if ship_name != "":
			for i in range(BattlegroupData.ships.size()):
				if String(BattlegroupData.ships[i].get("ship_name", "")) == ship_name:
					idx = i
					break
	_index = idx
	return idx

func _deferred_sort_option_containers() -> void:
	await get_tree().process_frame
	_sort_option_containers_by_name()

func _reset_feat_dedupe() -> void:
	_seen_tactics = {}
	_seen_maneuvers = {}

func _register_feat(seen: Dictionary, data: Dictionary) -> bool:
	var key := _canon_feat_name(String(data.get("name", "")))
	if key == "":
		return true
	if seen.has(key):
		return false
	seen[key] = true
	return true

func _canon_feat_name(raw: String) -> String:
	return raw.strip_edges().to_upper().replace("\n", " ")

func _sorted_by_name(items: Array) -> Array:
	if items == null:
		return []
	var arr: Array = items.duplicate()
	arr.sort_custom(func(a, b):
		var a_name := _canon_feat_name(String(a.get("name", "")))
		var b_name := _canon_feat_name(String(b.get("name", "")))
		return a_name < b_name
	)
	return arr

func _sort_option_containers_by_name() -> void:
	for cont in _slot_containers.values():
		if cont == null:
			continue
		_sort_container_children_by_name(cont)

func _sort_container_children_by_name(container: VBoxContainer) -> void:
	var children := container.get_children()
	if children.is_empty():
		return
	var start_idx := 0
	if children[0] is Label:
		start_idx = 1
	var cards: Array = []
	for i in range(start_idx, children.size()):
		cards.append(children[i])
	cards.sort_custom(func(a, b):
		var a_name := _canon_feat_name(_get_card_sort_name(a))
		var b_name := _canon_feat_name(_get_card_sort_name(b))
		return a_name < b_name
	)
	var insert_idx := start_idx
	for card in cards:
		container.move_child(card, insert_idx)
		insert_idx += 1

func _get_card_sort_name(card: Node) -> String:
	if card == null:
		return ""
	var data = card.get("_data")
	if typeof(data) == TYPE_DICTIONARY:
		return String(data.get("name", ""))
	return String(card.name)

# ───────────────────────────────────────────
# 6.  Пересчёт характеристик + рендер
# ───────────────────────────────────────────
func _recalc_and_update_display() -> void:
	if ship_cur.is_empty() or not ship_cur.has("hp"):
		return
	var hp      := _to_int(ship_cur.get("hp", 0))
	var defence := _to_int(ship_cur.get("defense", 0))
	var points  := _to_int(ship_cur.get("points", 0))

	var weapon  = ship_cur.get("weapon_slots", {}).duplicate()
	var support = ship_cur.get("support_slots", {}).duplicate()

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
	if _is_louis_ship():
		_overshild.text = "5"
	_max_hp_cached = hp
	var current_hp := _get_current_hp(hp)
	_hp_lbl_2.text  = str(current_hp)
	_base_defence_cached = defence
	_update_defence_label()
	_point_lbl.text = str(points)
	_apply_destroyed_state()

func _on_hulls_name_pressed() -> void:
	if _hide_box.visible:
		_hide_box.hide()
	else:
		_hide_box.show()

func _on_overshild_text_changed(new_text: String) -> void:
	if _overshild_edit_guard:
		return
	if not BattlegroupData.in_battle:
		return
	var caret_pos := _overshild.caret_column
	var cleaned := _sanitize_digits_with_caret(new_text, caret_pos)
	var cleaned_text := String(cleaned["text"])
	var cleaned_caret := int(cleaned["caret"])
	if cleaned_text == "":
		cleaned_text = "0"
		cleaned_caret = min(cleaned_caret, cleaned_text.length())
	if cleaned_text != new_text:
		_overshild_edit_guard = true
		_overshild.text = cleaned_text
		_overshild.caret_column = min(cleaned_caret, _overshild.text.length())
		_overshild_edit_guard = false
		new_text = cleaned_text
	_update_defence_label()

func _update_defence_label() -> void:
	if ship_cur.is_empty():
		return
	var defence := _base_defence_cached
	if BattlegroupData.in_battle and _is_louis_ship() and _get_overshild_value() > 0:
		defence += 2
	_def_lbl.text = str(defence)

func _get_overshild_value() -> int:
	if not is_instance_valid(_overshild):
		return 0
	return max(_to_int(_overshild.text), 0)

func _is_louis_ship() -> bool:
	if ship_cur.is_empty():
		return false
	return String(ship_cur.get("name", "")).findn(LOUIS_NAME_FRAGMENT) >= 0

func change_hp():
	if ship_cur.is_empty() or not ship_cur.has("hp"):
		return
	_hp_lbl_1.text  = str(ship_cur.get("hp", ""))

func _on_current_hp_changed(new_text: String) -> void:
	if _hp_edit_guard:
		return
	if ship_cur.is_empty():
		return
	var caret_pos := _hp_lbl_2.caret_column
	var cleaned := _sanitize_int_with_caret(new_text, caret_pos)
	if cleaned["text"] != new_text:
		_hp_edit_guard = true
		_hp_lbl_2.text = cleaned["text"]
		_hp_lbl_2.caret_column = cleaned["caret"]
		_hp_edit_guard = false
		new_text = cleaned["text"]
		caret_pos = cleaned["caret"]
	var max_hp := _max_hp_cached
	if max_hp <= 0:
		max_hp = _to_int(ship_cur.get("hp", 0))
	var trimmed := new_text.strip_edges()
	if trimmed == "":
		_set_current_hp(0, caret_pos)
		return
	if trimmed == "-":
		return
	if not _is_valid_signed_int(trimmed):
		_set_current_hp(_get_current_hp(max_hp), caret_pos)
		return
	var value := int(trimmed)
	if value > max_hp:
		value = max_hp
	_set_current_hp(value, caret_pos)

func _set_current_hp(value: int, caret_pos: int = -1) -> void:
	_hp_edit_guard = true
	ship_cur["current_hp"] = str(value)
	_hp_lbl_2.text = str(value)
	if caret_pos >= 0:
		_hp_lbl_2.caret_column = min(caret_pos, _hp_lbl_2.text.length())
	_hp_edit_guard = false
	BattlegroupData.save_data()
	_apply_destroyed_state()

func _get_current_hp(max_hp: int) -> int:
	var cur := _to_int(ship_cur.get("current_hp", max_hp))
	if max_hp > 0 and cur > max_hp:
		cur = max_hp
		ship_cur["current_hp"] = str(cur)
	return cur

func _sanitize_digits_with_caret(raw: String, caret_pos: int) -> Dictionary:
	var out := ""
	var new_caret := 0
	for i in range(raw.length()):
		var code := raw.unicode_at(i)
		if code >= 48 and code <= 57:
			out += String.chr(code)
			if i < caret_pos:
				new_caret += 1
	return {"text": out, "caret": new_caret}

func _sanitize_int_with_caret(raw: String, caret_pos: int) -> Dictionary:
	var out := ""
	var new_caret := 0
	var minus_used := false
	for i in range(raw.length()):
		var code := raw.unicode_at(i)
		if code == 45:
			if i == 0 and not minus_used:
				out += "-"
				minus_used = true
				if i < caret_pos:
					new_caret += 1
			continue
		if code >= 48 and code <= 57:
			out += String.chr(code)
			if i < caret_pos:
				new_caret += 1
	return {"text": out, "caret": new_caret}

func _is_valid_signed_int(text: String) -> bool:
	var t := text
	if t.begins_with("-"):
		if t.length() == 1:
			return false
		t = t.substr(1)
	return t.is_valid_int()

func _apply_destroyed_state() -> void:
	if ship_cur.is_empty():
		return
	var max_hp := _to_int(ship_cur.get("hp", 0))
	var cur := _to_int(ship_cur.get("current_hp", max_hp))
	modulate = DESTROYED_MODULATE if cur <= 0 else Color(1, 1, 1, 1)


# ─────────────────────────────────────────────────────────────
# Хелперы
# ─────────────────────────────────────────────────────────────
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

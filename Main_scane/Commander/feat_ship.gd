extends PanelContainer

const weapon_header        = preload("res://Main_scane/Commander/Battlegroup/Theme/Header/weapon.tres")
const weapon_body          = preload("res://Main_scane/Commander/Battlegroup/Theme/Body/weapon.tres")
const maneuver_header      = preload("res://Main_scane/Commander/Battlegroup/Theme/Header/maneuver.tres")
const maneuver_body        = preload("res://Main_scane/Commander/Battlegroup/Theme/Body/maneuver.tres")
const system_header        = preload("res://Main_scane/Commander/Battlegroup/Theme/Header/system.tres")
const system_body          = preload("res://Main_scane/Commander/Battlegroup/Theme/Body/system.tres")
const tactic_header        = preload("res://Main_scane/Commander/Battlegroup/Theme/Header/tactic.tres")
const tactic_body          = preload("res://Main_scane/Commander/Battlegroup/Theme/Body/tactic.tres")
const wing_escort_header   = preload("res://Main_scane/Commander/Battlegroup/Theme/Header/wing_escort.tres")
const wing_escort_body     = preload("res://Main_scane/Commander/Battlegroup/Theme/Body/wing_escort.tres")
const SlotUtils            = preload("res://slot_utils.gd")
const Opt                  = preload("res://option_types.gd")
# --- ссылки на виджеты ---------------------------------------------------
@onready var _name        : Button          = $Feat/Header/MarginContainer/Header/Hide
@onready var _tags        : RichTextLabel   = $Feat/Header/MarginContainer/Header/Tags
@onready var _damage      : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Damage
@onready var _range       : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Range
@onready var _point       : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Point
@onready var _tenacity    : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Tenacity
@onready var _hp          : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/HP
@onready var _effect      : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Effect
@onready var _discription : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Discription
@onready var _header      : PanelContainer  = $Feat/Header
@onready var _hide_btn    : Button          = $Feat/Header/MarginContainer/Header/Hide
@onready var _remove_btn  : Button          = $Feat/MarginContainer/VBoxContainer/HBoxContainer/Remove

var _hide_panel    : PanelContainer = null
var _removable     : bool = false
var _host_ship     : Dictionary = {}
var _data          : Dictionary = {}   # что именно показываем в карточке
var _is_option_item: bool = false      # ← флаг, что это элемент из option-пула

# контекст для демонтажа (если используется внешним кодом)
var _is_option  : bool = false
var _ship_ref   : Dictionary = {}
var _option_ref : Dictionary = {}

func _ready() -> void:
	if is_instance_valid(_hide_btn) and not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)
	if is_instance_valid(_remove_btn) and not _remove_btn.pressed.is_connected(_on_remove_pressed):
		_remove_btn.pressed.connect(_on_remove_pressed)

func set_pair(panel: PanelContainer) -> void:
	_hide_panel = panel
	if is_instance_valid(_hide_btn) and not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)

# получает флаг «можно ли удалять» и ссылку на корабль
func set_context(removable: bool, host_ship: Dictionary, is_option_item: bool=false) -> void:
	_removable      = removable
	_host_ship      = host_ship
	_is_option_item = is_option_item
	_update_remove_visibility()

func _update_remove_visibility() -> void:
	var t := int(_data.get("type", -999))
	# Прятать Remove только для option-элементов, если это слоты 7/8 (Тактика/Манёвр как опция)
	var is_tactic_or_maneuver_option := _is_option_item and (t == 7 or t == 8)
	_remove_btn.visible = _removable and not is_tactic_or_maneuver_option and not _data.get("name") == "FLAGSHIP"

func _on_hide_pressed() -> void:
	self.visible = false
	if is_instance_valid(_hide_panel):
		_hide_panel.visible = true

func _on_remove_pressed() -> void:
	if not _removable or _host_ship.is_empty():
		return
	
	var removed := false
	var removed_from := ""  # "special" | "option" (для логики отката бонусов)

	# Если эта карточка — ПОСЛЕДНЯЯ в своём контейнере, сперва пробуем удалить из special
	if _is_last_in_parent() and _host_ship.has("special") and (_host_ship["special"] is Array):
		removed = _remove_from_array_by_template(_host_ship["special"])
		if removed:
			removed_from = "special"

	# Если не удалилось из special (или карточка не последняя) — удаляем из option
	if not removed:
		var opts: Array = _host_ship.get("option", [])
		removed = _remove_from_array_by_template(opts)
		if removed and removed_from == "":
			removed_from = "option"

	if not removed:
		return

	# --- ПРИ УСПЕШНОМ УДАЛЕНИИ: откатываем соответствующие изменения корабля ---
	_apply_on_remove_effects(_data.get("name", ""))
	remove_overflow_by_sum()
	# Обновляем UI/счётчики
	var root := get_parent()
	if root and root.get_parent() and root.get_parent().get_parent() and root.get_parent().get_parent().get_parent():
		root.get_parent().get_parent().get_parent()._refresh_option_buttons()

	# Пересчёт очков и оповещения
	if "BattlegroupData" in Engine.get_singleton_list():
		BattlegroupData.refresh_point()
		if "option_change" in BattlegroupData:
			BattlegroupData.option_change.emit()

	if is_instance_valid(_hide_panel):
		_hide_panel.queue_free()
	queue_free()

# вызывать из Ship.gd ТОЛЬКО для опций
func set_context_for_option(ship_ref: Dictionary, option_ref: Dictionary) -> void:
	_is_option  = true
	_ship_ref   = ship_ref
	_option_ref = option_ref
	if _remove_btn:
		_remove_btn.visible = true

func _is_last_in_parent() -> bool:
	var p := get_parent()
	if p == null:
		return false
	return p.get_child_count() > 0 and p.get_child(p.get_child_count() - 1) == self

func _remove_from_array_by_template(arr: Array) -> bool:
	# Пытаемся по точной ссылке
	var idx := arr.find(_data)
	# Если не нашли — по имени (шаблонному совпадению)
	if idx == -1:
		for i in range(arr.size() - 1, -1, -1):
			if String(arr[i].get("name", "")) == String(_data.get("name", "")):
				idx = i
				break
	if idx != -1:
		arr.remove_at(idx)
		return true
	return false

# ---------- ЛОГИКА ОТКАТА БОНУСОВ ПРИ СНЯТИИ ОПЦИИ -------------------------

func _apply_on_remove_effects(opt_name: String) -> void:
	# Снятие опций должно уменьшать ранее выданные бонусы.
	# Структура корабля:
	#   "hp": String
	#   "support_slots": { "wings": String, "escorts": String, "systems": String }
	# Все числа хранятся строками → преобразуем безопасно.

	match opt_name.strip_edges():
		"FIGHTER LAUNCH CATAPULTS":
			_dec_support_slot("wings", 1)
		"BULWARK REDUNDANCIES":
			_dec_hp(3)
		"SUBLINE BERTH":
			_dec_support_slot("escorts", 1)
		_:
			# Ничего не нужно откатывать
			pass

func _dec_support_slot(which: String, by: int) -> void:
	if not _host_ship.has("support_slots"):
		return
	var ss = _host_ship.get("support_slots", {})
	var cur := _to_int(ss.get(which, "0"))
	cur = max(cur - by, 0)
	ss[which] = str(cur)
	_host_ship["support_slots"] = ss

func _dec_hp(by: int) -> void:
	# HP не должен опуститься ниже 1 (страховка)
	var cur_hp := _to_int(_host_ship.get("hp", "0"))
	cur_hp = max(cur_hp - by, 1)
	_host_ship["hp"] = str(cur_hp)

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
			return int(s)
		_:
			return 0

# --- утилиты ---------------------------------------------------
func _hide_if_text_empty(node: Node) -> void:
	if "text" in node:
		var txt = node.get("text")
		if typeof(txt) == TYPE_STRING and txt.strip_edges() == "":
			(node as CanvasItem).visible = false
		else:
			(node as CanvasItem).visible = true
	for child in node.get_children():
		if child is Node:
			_hide_if_text_empty(child)

func _change_theme() -> void:
	if get_parent().name in ["Auxiliary", "Primary", "Superheavy"]:
		_header.theme = weapon_header
		theme = weapon_body
	elif get_parent().name in ["Wing", "Escort"]:
		_header.theme = wing_escort_header
		theme = wing_escort_body
	elif get_parent().name == "System":
		_header.theme = system_header
		theme = system_body
	elif get_parent().name == "Tactic":
		_header.theme = tactic_header
		theme = tactic_body
	elif get_parent().name == "Maneuver":
		_header.theme = maneuver_header
		theme = maneuver_body

func populate(data: Dictionary) -> void:
	_data = data  # ← запоминаем, нужно для удаления/логики
	_name.text = data.get("name", "")
	_tags.text = data.get("tags", "")

	_damage.text = ""
	_range.text = ""
	if str(data.get("damage", "")).strip_edges() != "":
		_damage.text = "[Урон %s]" % data.get("damage")
	if str(data.get("range", "")).strip_edges() != "":
		_range.text = "[Дистанция %s]" % data.get("range")
	if str(data.get("points", "")).strip_edges() != "":
		_point.text = "[Очки %s]" % data.get("points")
	if str(data.get("tenacity", "")).strip_edges() != "":
		_tenacity.text = "[Упорство %s]" % data.get("tenacity")
	if str(data.get("hp", "")).strip_edges() != "":
		_hp.text = "[HP %s]" % data.get("hp")

	_effect.text = data.get("effect", "")
	_discription.text = "[i]" + data.get("discription", "")

	_hide_if_text_empty(self)
	_change_theme()
	_update_remove_visibility()


func remove_overflow_by_sum() -> bool:
	var opts: Array = _host_ship.get("option", [])
	if opts.is_empty():
		return false

	var changed := false

	# Берём суммы (должны содержать "wings" и "escorts")
	var sums := SlotUtils.get_slot_sums(_host_ship)

	# Если крыльев больше лимита → по одному снимаем последние, пока не станет неотрицательно
	while sums.get("wing") < 0:
		if _remove_last_by_types(opts, [Opt.Support.WING, Opt.SlotIndex.WINGS]):
			changed = true
			sums = SlotUtils.get_slot_sums(_host_ship)  # пересчитать после каждого удаления
		else:
			break

	# Если эскортов больше лимита → аналогично
	while sums.get("escort") < 0:
		if _remove_last_by_types(opts, [Opt.Support.ESCORT, Opt.SlotIndex.ESCORTS]):
			changed = true
			sums = SlotUtils.get_slot_sums(_host_ship)
		else:
			break

	# при желании можно сразу дёрнуть пересчёт/сигналы
	if changed:
		BattlegroupData.refresh_point()
		#BattlegroupData.option_change.emit()

	return changed


# Хелпер: удалить ПОСЛЕДНЮЮ опцию, у которой type совпадает с любым из types_to_match
func _remove_last_by_types(arr: Array, types_to_match: Array) -> bool:
	for i in range(arr.size() - 1, -1, -1):
		var t := int(arr[i].get("type", -999))
		if t in types_to_match:
			arr.remove_at(i)
			return true
	return false

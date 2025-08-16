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

# Подкарточки для вложенных манёвров/тактик в опциях
@onready var _m1_root     : MarginContainer = $Feat/MarginContainer/VBoxContainer/Maneveue1
@onready var _m1_name     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Name
@onready var _m1_tags     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Tags
@onready var _m1_eff      : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/MarginContainer/Effect

@onready var _t1_root     : MarginContainer = $Feat/MarginContainer/VBoxContainer/Tactic1
@onready var _t1_name     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Name
@onready var _t1_tags     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Tags
@onready var _t1_eff      : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/MarginContainer/Effect

@onready var _t2_root     : MarginContainer = $Feat/MarginContainer/VBoxContainer/Tactic2
@onready var _t2_name     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Name
@onready var _t2_tags     : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Tags
@onready var _t2_eff      : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/MarginContainer/Effect
@onready var _remove_btn  : Button          = $Feat/MarginContainer/VBoxContainer/HBoxContainer/Remove

var _hide_panel    :PanelContainer = null
var _removable     : bool = false
var _host_ship     : Dictionary = {}
var _data          : Dictionary = {}   # что именно показываем в карточке
var _is_option_item: bool = false   # ← новый флаг
# контекст для демонтажа
var _is_option  : bool = false
var _ship_ref   : Dictionary = {}
var _option_ref : Dictionary = {}

func _ready() -> void:
	# Подстраховка: привязываем Hide, даже если set_pair не вызван
	if is_instance_valid(_hide_btn) and not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)
	if is_instance_valid(_remove_btn) and not _remove_btn.pressed.is_connected(_on_remove_pressed):
		_remove_btn.pressed.connect(_on_remove_pressed)

func set_pair(panel: PanelContainer) -> void:
	_hide_panel = panel
	if is_instance_valid(_hide_btn) and not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)

# новый метод — получает флаг «можно ли удалять» и ссылку на корабль
func set_context(removable: bool, host_ship: Dictionary, is_option_item: bool=false) -> void:
	_removable      = removable
	_host_ship      = host_ship
	_is_option_item = is_option_item
	_update_remove_visibility()

func _update_remove_visibility() -> void:

	var t := int(_data.get("type", -999))
	# Прятать Remove только для option-элементов, если это слоты 7/8 (Тактика/Манёвр как опция)
	var is_tactic_or_maneuver_option := _is_option_item and (t == 7 or t == 8)
	_remove_btn.visible = _removable and not is_tactic_or_maneuver_option

func _on_hide_pressed() -> void:
	self.visible = false
	if is_instance_valid(_hide_panel):
		_hide_panel.visible = true

func _on_remove_pressed() -> void:
	# Демонтаж опции с корабля
	if not _removable or _host_ship.is_empty():
		return
	var opts: Array = _host_ship.get("option", [])
	var idx := opts.find(_data)
	if idx == -1:
		# редкий случай: ищем по имени как запасной вариант
		for i in opts.size():
			if String(opts[i].get("name", "")) == String(_data.get("name", "")):
				idx = i
				break
	if idx == -1:
		return

	opts.remove_at(idx)
	BattlegroupData.refresh_point()
	#BattlegroupData.emit_signal("battlegroup_change")

	# чистим UI: убираем кнопку и карточку
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

func _fill_subcard(root: MarginContainer, name_lbl: RichTextLabel, tags_lbl: RichTextLabel, eff_lbl: RichTextLabel, data: Dictionary) -> void:
	name_lbl.text = str(data.get("name", ""))
	tags_lbl.text = str(data.get("tags", ""))
	eff_lbl.text  = str(data.get("effect", ""))
	root.visible  = true

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

	# Вложенные элементы (для опций, содержащих feats[])
	if data.has("feats") and data["feats"] is Array:
		var t_count := 0
		for sub in data["feats"]:
			var t := int(sub.get("type", -1))
			if t == 1 and !_m1_root.visible:
				_fill_subcard(_m1_root, _m1_name, _m1_tags, _m1_eff, sub)
			elif t == 2:
				if !_t1_root.visible:
					_fill_subcard(_t1_root, _t1_name, _t1_tags, _t1_eff, sub)
					t_count += 1
				elif !_t2_root.visible:
					_fill_subcard(_t2_root, _t2_name, _t2_tags, _t2_eff, sub)
					t_count += 1
	
	_hide_if_text_empty(self)
	_change_theme()
	# Обновляем видимость Remove c учётом полученных data/set_context
	_update_remove_visibility()

extends VBoxContainer

const weapon_header        = preload("res://themes/commander/battlegroup/Header/weapon.tres")
const weapon_body          = preload("res://themes/commander/battlegroup/Body/weapon.tres")
const maneuver_header      = preload("res://themes/commander/battlegroup/Header/maneuver.tres")
const maneuver_body        = preload("res://themes/commander/battlegroup/Body/maneuver.tres")
const system_header        = preload("res://themes/commander/battlegroup/Header/system.tres")
const system_body          = preload("res://themes/commander/battlegroup/Body/system.tres")
const tactic_header        = preload("res://themes/commander/battlegroup/Header/tactic.tres")
const tactic_body          = preload("res://themes/commander/battlegroup/Body/tactic.tres")
const wing_escort_header   = preload("res://themes/commander/battlegroup/Header/wing_escort.tres")
const wing_escort_body     = preload("res://themes/commander/battlegroup/Body/wing_escort.tres")
const legacy_header        = preload("res://themes/commander/battlegroup/Header/legacy.tres")
const legacy_body          = preload("res://themes/commander/battlegroup/Body/legacy.tres")
const commendation_header  = preload("res://themes/commander/battlegroup/Header/commendation.tres")
const commendation_body    = preload("res://themes/commander/battlegroup/Body/commendation.tres")
const reputation_header    = preload("res://themes/commander/battlegroup/Header/reputation.tres")
const reputation_body      = preload("res://themes/commander/battlegroup/Body/reputation.tres")
const feat_header          = preload("res://themes/commander/battlegroup/Header/feat.tres")
const feat_body            = preload("res://themes/commander/battlegroup/Body/feat.tres")
const hide_theme           = preload("res://themes/commander/battlegroup/Hide_button.tres")
const hide_theme_legacy    = preload("res://themes/commander/battlegroup/Hide_button_legacy.tres")
const legacy_list_theme    = preload("res://themes/commander/battlegroup/Header/legacy.tres")
const Opt                  = preload("res://scripts/core/option_types.gd")
const APEIRON_NAME := "SSC\nAPEIRON-CLASS STRIKE CARRIER"
const TAWA_NAME := "IPS-N\nTAWA-CLASS MEDIUM CARRIER"
const TAG_BOARDING := "Абордаж"
const USES_BUTTON_PREFIX   = "UseBtn"
const USES_CHECKBOX_THEME  = preload("res://themes/support/uses_checkbox.tres")
const COUNTER_SCENE        = preload("res://counter/Counter.tscn")
const COUNTERS_KEY         = "counters"
const COUNTER_UID_KEY      = "counter_uid"
const COUNTER_NAME_CACHE_KEY = "counter_name_cache"
const LEGACY_COUNTER_KEY   = "counter"
const COUNTER_MIN_SEGMENTS = 2
const COUNTER_MAX_SEGMENTS = 8
const CHARGE_SEGMENTS_REGEX = "(?i)заряжаем[^0-9]*(\\d+)"
const REFRESH_SEGMENTS_REGEX = "(?i)обновляем[^0-9]*(\\d+)"
const PAYLOAD_MOD_REGEX = "(?i)боезаряд\\s*([+\\-])\\s*(\\d+)"
const COUNTER_LABEL_CHARGE = "Счетчик заряда:"
const COUNTER_LABEL_PAYLOAD = "Счетчик боезаряда:"
const COUNTER_LABEL_REFRESH = "Счетчик обновления:"
const COUNTER_LABEL_GRAYWASH = "Счетчики Graywash:"
const COUNTER_LABEL_SALVO = "Счетчик залпа:"
const COUNTER_LABEL_OTHER = "Счетчик перегрузки:"
const COUNTER_LABEL_OVERLOAD = "Счетчик перегрузки"
const COUNTER_OVERLOAD_KIND = "overload"
const COUNTER_SALVO_KIND = "salvo"
const COUNTER_OVERLOAD_SEGMENTS = 4
const PAYLOAD_MIN_SEGMENTS = 0
const MODULE_HP_CURRENT_KEY := "module_hp_current"
const TAG_HP_REGEX := "(?i)(?:\\bHP|\\bХП)\\s*[^0-9]*(\\d+)"

enum CounterType { NONE, PAYLOAD, CHARGE, GRAYWASH, REFRESH, OTHER }
const TAG_COUNTER_ORDER = [CounterType.CHARGE, CounterType.PAYLOAD, CounterType.REFRESH, CounterType.GRAYWASH]
static var _counter_uid_seed := 0
# --- ссылки на виджеты ---------------------------------------------------
@onready var _card_panel  : PanelContainer  = $Card
@onready var _collapsed_panel: PanelContainer = $Collapsed
@onready var _collapsed_btn: Button          = $Collapsed/MarginContainer/Button
@onready var _name        : Button          = $Card/Feat/Header/MarginContainer/Header/Hide
@onready var _tags        : RichTextLabel   = $Card/Feat/Header/MarginContainer/Header/Tags
@onready var _damage      : Label           = $Card/Feat/Header/MarginContainer/Header/Damage_range_container/Damage
@onready var _range       : Label           = $Card/Feat/Header/MarginContainer/Header/Damage_range_container/Range
@onready var _point       : Label           = $Card/Feat/Header/MarginContainer/Header/Damage_range_container/Point
@onready var _tenacity    : Label           = $Card/Feat/Header/MarginContainer/Header/Damage_range_container/Tenacity
@onready var _hp          : Label           = $Card/Feat/Header/MarginContainer/Header/Damage_range_container/HP
@onready var _effect      : RichTextLabel   = $Card/Feat/MarginContainer/VBoxContainer/Effect
@onready var _effect_separator: HSeparator = $Card/Feat/MarginContainer/VBoxContainer/HSeparator
@onready var _discription : RichTextLabel   = $Card/Feat/MarginContainer/VBoxContainer/Discription
@onready var _header      : PanelContainer  = $Card/Feat/Header
@onready var _hide_btn    : Button          = $Card/Feat/Header/MarginContainer/Header/Hide
@onready var _remove_btn  : Button          = $Card/Feat/MarginContainer/VBoxContainer/HBoxContainer/Remove
@onready var _hp_block    : VBoxContainer   = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/HP")
@onready var _hp_line     : LineEdit        = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/HP/LineEdit")
@onready var _uses_block: BoxContainer = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/Uses")
@onready var _uses_separator: HSeparator = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/Uses/HSeparator")
var _uses_encounter_container: HBoxContainer = null
var _uses_round_container: HBoxContainer = null
var _uses_encounter_label: Label = null
var _uses_round_label: Label = null
var _uses_nodes_resolved := false
@onready var _counter_block: BoxContainer = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/CounterBlock")
var _counter_label: Label = null
var _counter_label_other: Label = null
var _counter_btn: Button = null
var _counter_btn_other: Button = null
var _counter_list: Container = null
var _counter_list_other: Container = null

var _removable     : bool = false
var _host_ship     : Dictionary = {}
var _data          : Dictionary = {}   # что именно показываем в карточке
var _is_option_item: bool = false      # ← флаг, что это элемент из option-пула
var _context_mode  : String = "option"
var _collapsed     : bool = true
var _hp_max: int = 0
var _hp_edit_guard := false

# контекст для демонтажа (если используется внешним кодом)
var _is_option  : bool = false
var _ship_ref   : Dictionary = {}
var _option_ref : Dictionary = {}

func _ready() -> void:
	_resolve_counter_nodes()
	if is_instance_valid(_hide_btn) and not _hide_btn.pressed.is_connected(_on_hide_pressed):
		_hide_btn.pressed.connect(_on_hide_pressed)
	if is_instance_valid(_collapsed_btn) and not _collapsed_btn.pressed.is_connected(_on_collapsed_pressed):
		_collapsed_btn.pressed.connect(_on_collapsed_pressed)
	if is_instance_valid(_remove_btn) and not _remove_btn.pressed.is_connected(_on_remove_pressed):
		_remove_btn.pressed.connect(_on_remove_pressed)
	if is_instance_valid(_remove_btn):
		_remove_btn.text = "Убрать"
	if is_instance_valid(_hp_line) and not _hp_line.text_changed.is_connected(_on_hp_text_changed):
		_hp_line.text_changed.connect(_on_hp_text_changed)
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	if not BattlegroupData.counters_changed.is_connected(_on_counters_changed):
		BattlegroupData.counters_changed.connect(_on_counters_changed)
	if not BattlegroupData.range_changed.is_connected(_on_range_changed):
		BattlegroupData.range_changed.connect(_on_range_changed)
	if is_instance_valid(_name) and not _name.resized.is_connected(_on_name_button_resized):
		_name.resized.connect(_on_name_button_resized)
	if is_instance_valid(_collapsed_btn) and not _collapsed_btn.resized.is_connected(_on_name_button_resized):
		_collapsed_btn.resized.connect(_on_name_button_resized)
	_apply_collapsed_theme()
	set_collapsed(true)
	_update_battle_visibility()

func setup(data: Dictionary, removable: bool, host_ship: Dictionary, is_option_item: bool=false, context_mode: String = "option", collapsed: bool=true) -> void:
	set_context(removable, host_ship, is_option_item, context_mode)
	populate(data)
	set_collapsed(collapsed)

func set_collapsed(collapsed: bool) -> void:
	_collapsed = collapsed
	if is_instance_valid(_collapsed_panel):
		_collapsed_panel.visible = collapsed
	if is_instance_valid(_card_panel):
		_card_panel.visible = not collapsed

func _on_collapsed_pressed() -> void:
	set_collapsed(false)

func _on_name_button_resized() -> void:
	_apply_name_wrap()

func _apply_collapsed_theme() -> void:
	if not is_instance_valid(_collapsed_btn) or not is_instance_valid(_collapsed_panel):
		return
	var kind := _resolve_theme_kind()
	if kind == "legacy":
		_collapsed_panel.theme = legacy_list_theme
		_collapsed_btn.theme = hide_theme_legacy
		return
	var header_theme := _get_header_theme_for_kind(kind)
	if header_theme != null:
		_collapsed_panel.theme = header_theme
		_collapsed_btn.theme = hide_theme
		return
	_collapsed_panel.theme = null
	_collapsed_btn.theme = hide_theme

func _update_battle_visibility() -> void:
	if _context_mode == "commendation":
		var show_description := not BattlegroupData.in_battle
		if is_instance_valid(_discription):
			var has_text := String(_discription.text).strip_edges() != ""
			_discription.visible = show_description and has_text
		_update_separators_visibility()
	_update_hp_visibility()

func _update_hp_visibility() -> void:
	if not is_instance_valid(_hp_block) or not is_instance_valid(_hp_line):
		return
	_hp_max = _get_hp_tag_value()
	var show := BattlegroupData.in_battle and _hp_max > 0
	_hp_block.visible = show
	_hp_line.visible = show
	_hp_line.editable = show
	if not show:
		return
	_ensure_hp_initialized()
	_sync_hp_line()

func _get_hp_tag_value() -> int:
	var tags := String(_data.get("tags", "")).strip_edges()
	if tags != "":
		for raw in tags.split(",", false):
			var t := raw.strip_edges()
			if t == "":
				continue
			var lower := t.to_lower()
			var start_index := -1
			if lower.begins_with("hp"):
				start_index = 2
			elif lower.begins_with("хп"):
				start_index = 2
			if start_index < 0:
				continue
			var digits := ""
			for i in range(start_index, t.length()):
				var code := t.unicode_at(i)
				if code >= 48 and code <= 57:
					digits += String.chr(code)
				elif digits != "":
					break
			if digits != "":
				return int(digits)
	for raw in tags.split(",", false):
		var t := raw.strip_edges()
		if t == "":
			continue
		var lower := t.to_lower()
		var start_index := -1
		if lower.begins_with("hp"):
			start_index = 2
		elif lower.begins_with("хп"):
			start_index = 2
		if start_index < 0:
			continue
		var digits := ""
		for i in range(start_index, t.length()):
			var code := t.unicode_at(i)
			if code >= 48 and code <= 57:
				digits += String.chr(code)
			elif digits != "":
				break
		if digits != "":
			return int(digits)
	var regex := RegEx.new()
	if regex.compile(TAG_HP_REGEX) == OK:
		var match := regex.search(tags)
		if match != null:
			return int(match.get_string(1))
	var hp_value := _to_int(_data.get("hp", 0))
	return hp_value if hp_value > 0 else 0

func _ensure_hp_initialized() -> void:
	if _data.is_empty():
		return
	if not _data.has(MODULE_HP_CURRENT_KEY):
		_data[MODULE_HP_CURRENT_KEY] = str(_hp_max)
		BattlegroupData.save_data()

func _get_module_hp_value() -> int:
	var value := _to_int(_data.get(MODULE_HP_CURRENT_KEY, _hp_max))
	if _hp_max > 0:
		value = clamp(value, 0, _hp_max)
	return value

func _sync_hp_line() -> void:
	if not is_instance_valid(_hp_line):
		return
	var value := _get_module_hp_value()
	if _hp_line.text != str(value):
		_hp_edit_guard = true
		_hp_line.text = str(value)
		_hp_line.caret_column = min(_hp_line.caret_column, _hp_line.text.length())
		_hp_edit_guard = false

func _on_hp_text_changed(new_text: String) -> void:
	if _hp_edit_guard:
		return
	if not BattlegroupData.in_battle:
		return
	if _hp_max <= 0:
		return
	if not is_instance_valid(_hp_line):
		return
	var caret_pos := _hp_line.caret_column
	var cleaned := _sanitize_digits_with_caret(new_text, caret_pos)
	var cleaned_text := String(cleaned["text"])
	var cleaned_caret := int(cleaned["caret"])
	if cleaned_text != new_text:
		_hp_edit_guard = true
		_hp_line.text = cleaned_text
		_hp_line.caret_column = min(cleaned_caret, _hp_line.text.length())
		_hp_edit_guard = false
		new_text = cleaned_text
		caret_pos = cleaned_caret
	var trimmed := new_text.strip_edges()
	if trimmed == "":
		_set_module_hp_value(0, caret_pos)
		return
	var value := int(trimmed)
	if value > _hp_max:
		value = _hp_max
	_set_module_hp_value(value, caret_pos)

func _set_module_hp_value(value: int, caret_pos: int = -1) -> void:
	if _data.is_empty():
		return
	if value < 0:
		value = 0
	if _hp_max > 0:
		value = min(value, _hp_max)
	_hp_edit_guard = true
	_data[MODULE_HP_CURRENT_KEY] = str(value)
	if is_instance_valid(_hp_line):
		_hp_line.text = str(value)
		if caret_pos >= 0:
			_hp_line.caret_column = min(caret_pos, _hp_line.text.length())
	_hp_edit_guard = false
	BattlegroupData.save_data()

func _update_uses() -> void:
	if not is_instance_valid(_uses_block):
		return
	if not BattlegroupData.in_battle:
		_uses_block.visible = false
		_update_separators_visibility()
		return
	_resolve_uses_nodes()
	_clear_uses_buttons()
	var counts := _extract_uses_counts()
	var encounter_count := int(counts.get("encounter", 0))
	var round_count := int(counts.get("round", 0))
	var limit_count := int(counts.get("limit", 0))
	var generic_count := int(counts.get("generic", 0))
	var primary_count := 0
	var secondary_count := 0
	var primary_label := ""
	var secondary_label := ""
	var primary_is_encounter := false
	var secondary_is_encounter := false
	if round_count > 0:
		primary_count = round_count
		primary_label = "Использование в раунд:"
		if encounter_count > 0:
			secondary_count = encounter_count
			secondary_label = "Использование в столкновение:"
			secondary_is_encounter = true
		elif limit_count > 0:
			secondary_count = limit_count
			secondary_label = "Ограничение:"
	elif encounter_count > 0:
		primary_count = encounter_count
		primary_label = "Использование в столкновение:"
		primary_is_encounter = true
		if limit_count > 0:
			secondary_count = limit_count
			secondary_label = "Ограничение:"
	elif limit_count > 0:
		primary_count = limit_count
		primary_label = "Ограничение:"
	elif generic_count > 0:
		primary_count = generic_count
		primary_label = "Использование:"
	var has_any := primary_count > 0 or secondary_count > 0
	var has_container := is_instance_valid(_uses_encounter_container) or is_instance_valid(_uses_round_container)
	if not has_container:
		_uses_block.visible = false
		_update_separators_visibility()
		return
	_uses_block.visible = has_any
	_set_uses_section_visible(_uses_round_container, _uses_round_label, primary_count > 0)
	_set_uses_section_visible(_uses_encounter_container, _uses_encounter_label, secondary_count > 0)
	if not has_any:
		_update_separators_visibility()
		return
	var is_azure := _is_azure_star()
	if primary_count > 0:
		if is_instance_valid(_uses_round_label) and primary_label != "":
			_uses_round_label.text = primary_label
		_fill_uses_buttons(_uses_round_container, primary_count, primary_is_encounter and is_azure)
	if secondary_count > 0:
		if is_instance_valid(_uses_encounter_label) and secondary_label != "":
			_uses_encounter_label.text = secondary_label
		_fill_uses_buttons(_uses_encounter_container, secondary_count, secondary_is_encounter and is_azure)
	_update_separators_visibility()
	_update_counter_visibility()

func _clear_uses_buttons() -> void:
	_resolve_uses_nodes()
	_clear_uses_container(_uses_encounter_container)
	if _uses_round_container != _uses_encounter_container:
		_clear_uses_container(_uses_round_container)

func _clear_uses_container(container: HBoxContainer) -> void:
	if not is_instance_valid(container):
		return
	for child in container.get_children():
		if child is CheckBox or child.name == "UsesSpacer":
			container.remove_child(child)
			child.queue_free()

func _resolve_uses_nodes() -> void:
	if _uses_nodes_resolved:
		return
	_uses_nodes_resolved = true
	if not is_instance_valid(_uses_block):
		return
	var children := _uses_block.get_children()
	for i in range(children.size() - 1):
		var lbl := children[i]
		if not (lbl is Label):
			continue
		var next_node := children[i + 1]
		if not (next_node is HBoxContainer):
			continue
		var name_lower := String(lbl.name).to_lower()
		var text_lower := String(lbl.text).to_lower()
		if _matches_round(name_lower) or _matches_round(text_lower):
			_uses_round_label = lbl
			_uses_round_container = next_node
			continue
		if _matches_encounter(name_lower) or _matches_encounter(text_lower):
			_uses_encounter_label = lbl
			_uses_encounter_container = next_node
	var hboxes: Array = _uses_block.find_children("*", "HBoxContainer", true, false)
	for h in hboxes:
		var name_lower := String(h.name).to_lower()
		if _uses_round_container == null and _matches_round(name_lower):
			_uses_round_container = h
		elif _uses_encounter_container == null and _matches_encounter(name_lower):
			_uses_encounter_container = h
	var labels: Array = _uses_block.find_children("*", "Label", true, false)
	for lbl in labels:
		var name_lower := String(lbl.name).to_lower()
		var text_lower := String(lbl.text).to_lower()
		if _uses_round_label == null and (_matches_round(name_lower) or _matches_round(text_lower)):
			_uses_round_label = lbl
		elif _uses_encounter_label == null and (_matches_encounter(name_lower) or _matches_encounter(text_lower)):
			_uses_encounter_label = lbl
	if _uses_encounter_container == null and not hboxes.is_empty():
		_uses_encounter_container = hboxes[0]
	if _uses_round_container == null and hboxes.size() > 1:
		for h in hboxes:
			if h != _uses_encounter_container:
				_uses_round_container = h
				break

func _fill_uses_buttons(container: HBoxContainer, count: int, persist_azure: bool) -> void:
	if not is_instance_valid(container) or count <= 0:
		return
	for i in range(count):
		var btn = CheckBox.new()
		btn.name = "%s%d" % [USES_BUTTON_PREFIX, i + 1]
		btn.theme = USES_CHECKBOX_THEME
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.custom_minimum_size = Vector2(24, 24)
		if persist_azure and i == 0:
			btn.button_pressed = _get_azure_star_used()
		container.add_child(btn)
		if persist_azure and i == 0:
			btn.toggled.connect(_on_azure_star_use_toggled.bind(i))

func _set_uses_section_visible(container: HBoxContainer, label: Label, visible: bool) -> void:
	if is_instance_valid(container):
		container.visible = visible
	if is_instance_valid(label):
		label.visible = visible

func _matches_encounter(value: String) -> bool:
	var v := value.to_lower()
	return v.find("encounter") != -1 or v.find("encaunter") != -1 or v.find("столк") != -1

func _matches_round(value: String) -> bool:
	var v := value.to_lower()
	return v.find("round") != -1 or v.find("раунд") != -1

func _extract_limit_uses_from_text(text: String) -> int:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return 0
	var lower := trimmed.to_lower()
	var best := 0
	var start := 0
	while start < lower.length():
		var idx_limit := lower.find("ограничение", start)
		var idx_alt := lower.find("ограниченно", start)
		var idx := idx_limit
		if idx == -1 or (idx_alt != -1 and idx_alt < idx):
			idx = idx_alt
		if idx == -1:
			break
		var num := _extract_digits_after_keyword(trimmed, idx)
		if num > best:
			best = num
		start = idx + 1
	return best

func _extract_uses_counts() -> Dictionary:
	var text := String(_data.get("effect", "")) + " " + String(_data.get("discription", "")) + " " + String(_data.get("tags", ""))
	if text.strip_edges() == "":
		return {"encounter": 0, "round": 0, "limit": 0, "generic": 0}
	var encounter_uses := _max_regex_count(text, "(?i)(\\d+)\\s*/\\s*столкнов\\p{L}*")
	var round_uses := _max_regex_count(text, "(?i)(\\d+)\\s*/\\s*раунд\\p{L}*")
	var limit_uses := 0
	var tags_text := String(_data.get("tags", ""))
	if tags_text != "":
		limit_uses = max(limit_uses, _extract_limit_uses_from_text(tags_text))
	if limit_uses <= 0:
		limit_uses = _extract_limit_uses_from_text(text)
	var generic_uses := 0
	if encounter_uses <= 0 and round_uses <= 0 and limit_uses <= 0:
		generic_uses = max(generic_uses, _max_regex_count(text, "(\\d+)\\s*/\\s*\\p{L}+"))
	if _is_azure_star():
		encounter_uses = max(encounter_uses, 1)
	return {"encounter": encounter_uses, "round": round_uses, "limit": limit_uses, "generic": generic_uses}

func _update_separators_visibility() -> void:
	var effect_text := String(_data.get("effect", "")).strip_edges()
	var desc_text := String(_data.get("discription", "")).strip_edges()
	var has_effect := effect_text != ""
	var has_description := desc_text != ""
	if is_instance_valid(_effect):
		has_effect = has_effect and _effect.visible
	if is_instance_valid(_discription):
		has_description = has_description and _discription.visible
	if is_instance_valid(_effect_separator):
		_effect_separator.visible = has_effect and has_description
	if is_instance_valid(_uses_separator):
		var show_uses := (has_effect or has_description)
		if is_instance_valid(_uses_block):
			show_uses = show_uses and _uses_block.visible
		_uses_separator.visible = show_uses

func _update_counter_visibility() -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_block):
		return
	if _is_counter_forbidden():
		_counter_block.visible = false
		return
	if not BattlegroupData.in_battle:
		_counter_block.visible = false
		return
	var tag_types := _get_tag_counter_types()
	var has_tag_counters := is_instance_valid(_counter_list) and _counter_list.get_child_count() > 0
	var is_salvo_weapon := _is_three_by_three_weapon()
	var has_salvo := is_salvo_weapon and _has_counter_kind_in_list(_counter_list, COUNTER_SALVO_KIND)
	var can_add_salvo := is_salvo_weapon and not has_salvo
	var same_list := is_instance_valid(_counter_list_other) and _counter_list_other == _counter_list
	var other_count := 0
	if is_instance_valid(_counter_list_other) and not same_list:
		other_count = _count_counters_of_type(_counter_list_other, CounterType.OTHER)
	var has_other_counters := other_count > 0
	var allow_other := _allow_other_counters(tag_types)
	var can_add_tag := _can_add_tag_counter(tag_types)
	var can_add_other := not same_list and _can_add_other_counter(tag_types, other_count)
	var show_tag_block := has_tag_counters or not tag_types.is_empty() or is_salvo_weapon
	var show_other_block := not same_list and allow_other
	_counter_block.visible = show_tag_block or show_other_block or can_add_tag or can_add_other
	if not _counter_block.visible:
		return
	if is_instance_valid(_counter_label):
		var label_text := _get_tag_block_label(tag_types)
		_counter_label.text = label_text
		_counter_label.visible = label_text != "" and show_tag_block
	if is_instance_valid(_counter_list):
		_counter_list.visible = show_tag_block
	if is_instance_valid(_counter_label_other):
		_counter_label_other.text = COUNTER_LABEL_OTHER
		_counter_label_other.visible = show_other_block
	if is_instance_valid(_counter_list_other):
		_counter_list_other.visible = show_other_block
	if is_instance_valid(_counter_btn):
		_counter_btn.visible = can_add_tag or can_add_salvo
	if is_instance_valid(_counter_btn_other):
		_counter_btn_other.visible = can_add_other

func _get_counter_text() -> String:
	return (
		String(_data.get("tags", "")) + " " +
		String(_data.get("name", "")) + " " +
		String(_data.get("effect", "")) + " " +
		String(_data.get("discription", ""))
	)

func _normalize_text(text: String) -> String:
	return text.to_lower().replace("ё", "е")

func _get_display_range(data: Dictionary) -> String:
	var raw := String(data.get("range", "")).strip_edges()
	if raw == "":
		return ""
	if _should_apply_apeiron_range(data):
		return _shift_range(raw)
	return raw

func _get_display_tenacity(data: Dictionary) -> String:
	var raw := String(data.get("tenacity", "")).strip_edges()
	if raw == "" or not raw.is_valid_int():
		return raw
	if _should_apply_tawa_tenacity(data):
		return str(int(raw) + 2)
	return raw

func _should_apply_apeiron_range(data: Dictionary) -> bool:
	if not _is_apeiron_ship():
		return false
	var t := int(data.get("type", -1))
	if t == Opt.Support.WING:
		return true
	if t != 1 and t != 2:
		return false
	return _is_wing_feat(data)

func _should_apply_tawa_tenacity(data: Dictionary) -> bool:
	if not _is_tawa_ship():
		return false
	return _has_boarding_tag(data)

func _is_apeiron_ship() -> bool:
	return String(_host_ship.get("name", "")).strip_edges() == APEIRON_NAME

func _is_tawa_ship() -> bool:
	return String(_host_ship.get("name", "")).strip_edges() == TAWA_NAME

func _has_boarding_tag(data: Dictionary) -> bool:
	for t in String(data.get("tags", "")).split(",", false):
		if t.strip_edges().to_lower() == TAG_BOARDING.to_lower():
			return true
	return false

func _is_wing_feat(data: Dictionary) -> bool:
	if _host_ship.is_empty():
		return false
	var feat_name := String(data.get("name", "")).strip_edges()
	if feat_name == "":
		return false
	var feat_type := int(data.get("type", -1))
	for opt in _host_ship.get("option", []):
		if _is_wing_option(opt) and _option_has_feat(opt, feat_name, feat_type):
			return true
	for opt in _host_ship.get("special", []):
		if _is_wing_option(opt) and _option_has_feat(opt, feat_name, feat_type):
			return true
	return false

func _is_wing_option(opt: Dictionary) -> bool:
	return int(opt.get("type", -1)) == Opt.Support.WING

func _option_has_feat(opt: Dictionary, feat_name: String, feat_type: int) -> bool:
	for f in opt.get("feats", []):
		if String(f.get("name", "")).strip_edges() != feat_name:
			continue
		if feat_type == -1 or int(f.get("type", -1)) == feat_type:
			return true
	return false

func _shift_range(raw: String) -> String:
	var text := raw.strip_edges()
	if text == "":
		return text
	var regex := RegEx.new()
	if regex.compile("^(\\d+)\\s*([^0-9]+)\\s*(\\d+)$") != OK:
		return text
	var match := regex.search(text)
	if match == null:
		return text
	var max_val := int(match.get_string(1))
	var sep := match.get_string(2)
	var min_val := int(match.get_string(3))
	return "%d%s%d" % [max_val + 1, sep, min_val + 1]

func _get_tag_counter_types() -> Array:
	var tags := _normalize_text(String(_data.get("tags", "")))
	var types: Array = []
	if tags.find("заряжаем") != -1:
		types.append(CounterType.CHARGE)
	if tags.find("боезаряд") != -1:
		types.append(CounterType.PAYLOAD)
	if tags.find("greywash") != -1 or tags.find("graywash") != -1 or tags.find("грейвош") != -1:
		types.append(CounterType.GRAYWASH)
	if tags.find("обновляем") != -1:
		types.append(CounterType.REFRESH)
	return types

func _get_primary_counter_type(tag_types: Array = []) -> int:
	if tag_types.is_empty():
		tag_types = _get_tag_counter_types()
	if CounterType.CHARGE in tag_types:
		return CounterType.CHARGE
	if CounterType.PAYLOAD in tag_types:
		return CounterType.PAYLOAD
	if CounterType.REFRESH in tag_types:
		return CounterType.REFRESH
	if CounterType.GRAYWASH in tag_types:
		return CounterType.GRAYWASH
	if _has_unclassified_counter(_get_counter_text()):
		return CounterType.OTHER
	return CounterType.NONE

func _is_trait() -> bool:
	var type_value := _to_int(_data.get("type", -1))
	return type_value == 0 and not _data.has("modification") and not _data.has("points")

func _is_maneuver_or_tactic() -> bool:
	var type_value := _to_int(_data.get("type", -1))
	if type_value != 1 and type_value != 2:
		return false
	return not _data.has("modification") and not _data.has("points")

func _is_counter_forbidden() -> bool:
	return _is_trait() or _is_maneuver_or_tactic()

func _has_unclassified_counter(text: String) -> bool:
	var normalized := _normalize_text(text)
	var keyword := "счетчик"
	var idx := normalized.find(keyword)
	while idx != -1:
		var window := normalized.substr(idx, min(48, normalized.length() - idx))
		if not _window_has_known_counter(window):
			return true
		idx = normalized.find(keyword, idx + keyword.length())
	return false

func _window_has_known_counter(window: String) -> bool:
	return (
		window.find("боезаряд") != -1 or
		window.find("заряжаем") != -1 or
		window.find("заряд") != -1 or
		window.find("полет") != -1 or
		window.find("грейвош") != -1 or
		window.find("greywash") != -1 or
		window.find("graywash") != -1 or
		window.find("обновл") != -1 or
		window.find("перезаряд") != -1
	)

func _has_counter_kind(entries: Array, kind: String) -> bool:
	for entry in entries:
		if entry is Dictionary and String(entry.get("counter_kind", "")) == kind:
			return true
	return false

func _has_counter_kind_in_list(list: Container, kind: String) -> bool:
	if not is_instance_valid(list):
		return false
	for child in list.get_children():
		if child.has_meta("counter_kind") and String(child.get_meta("counter_kind")) == kind:
			return true
	return false

func _get_tag_block_label(tag_types: Array) -> String:
	if tag_types.is_empty():
		if _is_three_by_three_weapon():
			return COUNTER_LABEL_SALVO
		return ""
	for counter_type in TAG_COUNTER_ORDER:
		if counter_type in tag_types:
			return _get_counter_label_text(counter_type)
	return ""

func _get_counter_label_text(counter_type: int) -> String:
	match counter_type:
		CounterType.PAYLOAD:
			return COUNTER_LABEL_PAYLOAD
		CounterType.CHARGE:
			return COUNTER_LABEL_CHARGE
		CounterType.GRAYWASH:
			return COUNTER_LABEL_GRAYWASH
		CounterType.REFRESH:
			return COUNTER_LABEL_REFRESH
		_:
			return ""

func _get_counter_default_name(counter_type: int, kind: String = "") -> String:
	var cached := _get_cached_counter_name(counter_type, kind)
	if cached != "":
		return cached
	return _get_ship_display_name()

func _get_counter_name_cache() -> Dictionary:
	var cache = _data.get(COUNTER_NAME_CACHE_KEY, {})
	if cache == null or not (cache is Dictionary):
		cache = {}
	_data[COUNTER_NAME_CACHE_KEY] = cache
	return cache

func _counter_name_key(counter_type: int, kind: String = "") -> String:
	if kind != "":
		return "kind:%s" % kind
	return "type:%d" % counter_type

func _get_cached_counter_name(counter_type: int, kind: String = "") -> String:
	var cache := _get_counter_name_cache()
	var cached := String(cache.get(_counter_name_key(counter_type, kind), "")).strip_edges()
	return cached

func _set_cached_counter_name(counter_type: int, kind: String, name: String) -> void:
	var trimmed := name.strip_edges()
	if trimmed == "":
		return
	var cache := _get_counter_name_cache()
	cache[_counter_name_key(counter_type, kind)] = trimmed
	_data[COUNTER_NAME_CACHE_KEY] = cache

func _cache_counter_name_from_state(state: Dictionary, fallback_type: int) -> void:
	if not (state is Dictionary):
		return
	var name := String(state.get("name", "")).strip_edges()
	if name == "":
		return
	var ctype := _get_counter_type_from_entry(state, fallback_type)
	if ctype == CounterType.NONE:
		ctype = fallback_type
	if ctype == CounterType.NONE:
		ctype = CounterType.OTHER
	var kind := String(state.get("counter_kind", ""))
	_set_cached_counter_name(ctype, kind, name)

func _cache_counter_name_from_node(counter: Node, fallback_type: int) -> void:
	if counter == null or not is_instance_valid(counter):
		return
	var state: Dictionary = {}
	if counter.has_method("get_state"):
		state = counter.get_state()
	var ctype := _get_counter_type_from_node(counter, fallback_type)
	if ctype == CounterType.NONE:
		ctype = fallback_type
	if ctype == CounterType.NONE:
		ctype = _get_primary_counter_type()
	state["type"] = ctype
	if counter.has_meta("counter_kind"):
		state["counter_kind"] = String(counter.get_meta("counter_kind"))
	_cache_counter_name_from_state(state, ctype)

func _get_ship_display_name() -> String:
	var ship_name := String(_host_ship.get("ship_name", "")).strip_edges()
	if ship_name != "":
		return ship_name
	var fallback := String(_host_ship.get("name", "")).strip_edges()
	if fallback != "":
		return fallback
	return String(_data.get("name", ""))

func _get_counter_limit(counter_type: int) -> int:
	match counter_type:
		CounterType.PAYLOAD:
			if String(_data.get("name", "")) == "TANDEM-SPREAD TORPEDOES":
				return 2
			return 1
		CounterType.GRAYWASH:
			return 0
		CounterType.CHARGE, CounterType.REFRESH:
			return 1
		_:
			return 0

func _should_add_overload_counter(tag_types: Array = []) -> bool:
	if tag_types.is_empty():
		tag_types = _get_tag_counter_types()
	if not (CounterType.CHARGE in tag_types):
		return false
	return String(_host_ship.get("name", "")).strip_edges() == "FKS\nCALENDULA-CLASS BATTLECRUISER"

func _is_three_by_three_weapon() -> bool:
	return String(_data.get("name", "")).strip_edges() == "3X3 BLOCK SHORT-SPOOL CANNONS"

func _allow_other_counters(tag_types: Array = []) -> bool:
	if tag_types.is_empty():
		tag_types = _get_tag_counter_types()
	if CounterType.GRAYWASH in tag_types:
		return false
	return _should_add_overload_counter(tag_types)

func _get_other_counter_limit(tag_types: Array = []) -> int:
	if tag_types.is_empty():
		tag_types = _get_tag_counter_types()
	if CounterType.GRAYWASH in tag_types:
		return -1
	if _should_add_overload_counter(tag_types):
		return 1
	return -1

func _can_add_other_counter(tag_types: Array, current_count: int) -> bool:
	var limit := _get_other_counter_limit(tag_types)
	if limit < 0:
		return false
	if limit == 0:
		return true
	return current_count < limit

func _extract_charge_segments_from_text(text: String) -> int:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return 0
	var value := _max_regex_count(trimmed, CHARGE_SEGMENTS_REGEX)
	if value > 0:
		return value
	for raw in trimmed.split(",", false):
		var token := raw.strip_edges()
		if token == "":
			continue
		var idx := _find_charge_keyword(token)
		if idx == -1:
			continue
		var num := _extract_digits_after_keyword(token, idx)
		if num > 0:
			return num
	var idx_all := _find_charge_keyword(trimmed)
	if idx_all != -1:
		var num_all := _extract_digits_after_keyword(trimmed, idx_all)
		if num_all > 0:
			return num_all
	return 0

func _find_charge_keyword(text: String) -> int:
	var idx := text.find("Заряжаем")
	if idx != -1:
		return idx
	idx = text.find("заряжаем")
	if idx != -1:
		return idx
	idx = text.find("ЗАРЯЖАЕМ")
	if idx != -1:
		return idx
	var lower := text.to_lower()
	if lower != text:
		idx = lower.find("заряжаем")
		if idx != -1:
			return idx
	return -1

func _extract_digits_after_keyword(text: String, start_idx: int) -> int:
	var digits := ""
	var end_idx = min(text.length(), start_idx + 24)
	for i in range(start_idx, end_idx):
		var ch := text[i]
		if ch.is_valid_int():
			digits += ch
		elif digits != "":
			break
	if digits == "":
		return 0
	return digits.to_int()

func _get_charge_segments() -> int:
	var tags := String(_data.get("tags", "")).strip_edges()
	var value := 0
	if tags != "":
		value = _extract_charge_segments_from_text(tags)
	if value <= 0:
		var text := (
			String(_data.get("name", "")) + " " +
			String(_data.get("effect", "")) + " " +
			String(_data.get("discription", ""))
		)
		value = _extract_charge_segments_from_text(text)
	if value <= 0:
		return 0
	return clamp(value, COUNTER_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)

func _extract_refresh_segments_from_text(text: String) -> int:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return 0
	var value := _max_regex_count(trimmed, REFRESH_SEGMENTS_REGEX)
	if value > 0:
		return value
	for raw in trimmed.split(",", false):
		var token := raw.strip_edges()
		if token == "":
			continue
		var idx := _find_refresh_keyword(token)
		if idx == -1:
			continue
		var num := _extract_digits_after_keyword(token, idx)
		if num > 0:
			return num
	var idx_all := _find_refresh_keyword(trimmed)
	if idx_all != -1:
		var num_all := _extract_digits_after_keyword(trimmed, idx_all)
		if num_all > 0:
			return num_all
	return 0

func _find_refresh_keyword(text: String) -> int:
	var idx := text.find("Обновляем")
	if idx != -1:
		return idx
	idx = text.find("обновляем")
	if idx != -1:
		return idx
	idx = text.find("ОБНОВЛЯЕМ")
	if idx != -1:
		return idx
	var lower := text.to_lower()
	if lower != text:
		idx = lower.find("обновляем")
		if idx != -1:
			return idx
	return -1

func _get_refresh_segments() -> int:
	var tags := String(_data.get("tags", "")).strip_edges()
	var value := 0
	if tags != "":
		value = _extract_refresh_segments_from_text(tags)
	if value <= 0:
		value = _extract_refresh_segments_from_text(_get_counter_text())
	if value <= 0:
		return 0
	return clamp(value, COUNTER_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)

func _extract_payload_modifier_from_text(text: String) -> int:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return 0
	var normalized := _normalize_payload_signs(trimmed).to_lower()
	var regex := RegEx.new()
	var err := regex.compile(PAYLOAD_MOD_REGEX)
	if err != OK:
		return 0
	var match := regex.search(normalized)
	if match == null:
		return 0
	var sign := match.get_string(1)
	var value := int(match.get_string(2))
	if value <= 0:
		return 0
	if sign == "+":
		return value
	return -value

func _normalize_payload_signs(text: String) -> String:
	var result := text
	result = result.replace(char(8211), "-") # en dash
	result = result.replace(char(8212), "-") # em dash
	result = result.replace(char(8722), "-") # minus sign
	result = result.replace(char(8209), "-") # non-breaking hyphen
	result = result.replace(char(8208), "-") # hyphen
	return result

func _get_payload_segments() -> int:
	var base := BattlegroupData.get_range_value()
	var modifier := _extract_payload_modifier_from_text(String(_data.get("tags", "")))
	var value := base + modifier
	if value <= 0:
		value = 1
	return clamp(value, PAYLOAD_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)

func _apply_payload_segments_to_entry(entry: Dictionary, next_segments: int, preserve_unfilled: bool) -> bool:
	var target_segments := next_segments
	if target_segments <= 0:
		target_segments = 0
	elif target_segments == 1:
		target_segments = 2
	var clamped = clamp(target_segments, PAYLOAD_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)
	var prev_segments := _to_int(entry.get("segments", clamped))
	var prev_filled := _to_int(entry.get("filled_segments", clamped))
	var had_filled := entry.has("filled_segments")
	var changed := false
	if prev_segments != clamped:
		entry["segments"] = clamped
		changed = true
	var next_filled := prev_filled
	if next_segments == 1:
		next_filled = clamp(prev_filled, 0, 1)
		if not had_filled:
			next_filled = 1
	elif preserve_unfilled:
		if clamped > prev_segments:
			var prev_unfilled = max(prev_segments - prev_filled, 0)
			next_filled = clamp(clamped - prev_unfilled, 0, clamped)
		else:
			next_filled = clamp(prev_filled, 0, clamped)
	else:
		next_filled = clamp(prev_filled, 0, clamped)
	if not had_filled:
		next_filled = 0
	if not had_filled or next_filled != prev_filled:
		entry["filled_segments"] = next_filled
		changed = true
	return changed

func _is_auto_counter_type(counter_type: int) -> bool:
	return counter_type == CounterType.CHARGE or counter_type == CounterType.REFRESH

func _get_counter_list_for_type(counter_type: int) -> Container:
	if counter_type == CounterType.OTHER:
		if _is_three_by_three_weapon():
			return _counter_list
		if is_instance_valid(_counter_list_other):
			return _counter_list_other
		return _counter_list
	return _counter_list

func _get_counter_type_from_entry(entry: Dictionary, fallback_type: int) -> int:
	if entry.has("type"):
		return _to_int(entry.get("type", fallback_type))
	if entry.has("counter_type"):
		return _to_int(entry.get("counter_type", fallback_type))
	return fallback_type

func _get_counter_type_from_node(node: Node, fallback_type: int) -> int:
	if node == null:
		return fallback_type
	if node.has_meta("counter_type"):
		return _to_int(node.get_meta("counter_type"))
	return fallback_type

func _count_counters_of_type(list: Container, counter_type: int) -> int:
	if not is_instance_valid(list):
		return 0
	var count := 0
	for child in list.get_children():
		if _get_counter_type_from_node(child, counter_type) == counter_type:
			count += 1
	return count

func _can_add_tag_counter(tag_types: Array) -> bool:
	for counter_type in TAG_COUNTER_ORDER:
		if not (counter_type in tag_types):
			continue
		if counter_type == CounterType.PAYLOAD and _get_payload_segments() <= 0:
			continue
		var count = _count_counters_of_type(_counter_list, counter_type)
		if _is_auto_counter_type(counter_type) and count > 0:
			continue
		var limit = _get_counter_limit(counter_type)
		if limit <= 0:
			return true
		if count < limit:
			return true
	return false

func _resolve_counter_nodes() -> void:
	if not is_instance_valid(_counter_block):
		_counter_block = get_node_or_null("Card/Feat/MarginContainer/VBoxContainer/CounterBlock")
		if not is_instance_valid(_counter_block):
			_counter_block = find_child("CounterBlock", true, false) as BoxContainer
	if not is_instance_valid(_counter_block):
		return
	if not is_instance_valid(_counter_label):
		_counter_label = _counter_block.find_child("CounterLabel", true, false) as Label
	if not is_instance_valid(_counter_label_other):
		_counter_label_other = _counter_block.find_child("CounterLabel2", true, false) as Label
	if not is_instance_valid(_counter_btn):
		_counter_btn = _counter_block.find_child("CounterAdd", true, false) as Button
		if is_instance_valid(_counter_btn) and not _counter_btn.pressed.is_connected(_on_counter_pressed):
			_counter_btn.pressed.connect(_on_counter_pressed)
	if not is_instance_valid(_counter_btn_other):
		_counter_btn_other = _counter_block.find_child("CounterAdd2", true, false) as Button
		if is_instance_valid(_counter_btn_other) and not _counter_btn_other.pressed.is_connected(_on_counter_other_pressed):
			_counter_btn_other.pressed.connect(_on_counter_other_pressed)
	if not is_instance_valid(_counter_list):
		var list_node: Node = _counter_block.find_child("CounterContainer", true, false)
		if list_node == null:
			list_node = _counter_block.find_child("CounterConainer", true, false)
		if list_node == null:
			list_node = _counter_block.find_child("CounterList", true, false)
		_counter_list = list_node as Container
	if not is_instance_valid(_counter_list_other):
		var other_node: Node = _counter_block.find_child("CounterContainer2", true, false)
		if other_node == null:
			var legacy_node: Node = _counter_block.find_child("CounterList", true, false)
			if legacy_node != _counter_list:
				other_node = legacy_node
		if other_node == null:
			other_node = _counter_list
		_counter_list_other = other_node as Container

func _rebuild_counters() -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_list):
		return
	_clear_counter_list()
	if _is_counter_forbidden():
		var had_data := false
		if _data.has(COUNTERS_KEY):
			var stored = _data.get(COUNTERS_KEY, [])
			if stored is Array and not stored.is_empty():
				had_data = true
			_data[COUNTERS_KEY] = []
		if _data.has(LEGACY_COUNTER_KEY):
			if _to_int(_data.get(LEGACY_COUNTER_KEY, 0)) != 0:
				had_data = true
			_data.erase(LEGACY_COUNTER_KEY)
		if had_data:
			BattlegroupData.save_data()
		return
	var tag_types := _get_tag_counter_types()
	var primary_type := _get_primary_counter_type(tag_types)
	var refresh_segments := 0
	if CounterType.REFRESH in tag_types:
		refresh_segments = _get_refresh_segments()
	var payload_segments := -1
	if CounterType.PAYLOAD in tag_types:
		payload_segments = _get_payload_segments()
	var counters: Array = []
	var migrated := false
	var auto_created := false
	var trimmed := false
	var normalized := false
	var moved := false
	if _data.has(COUNTERS_KEY):
		var stored = _data.get(COUNTERS_KEY, [])
		if stored is Array:
			counters = stored
	else:
		var legacy_value := _to_int(_data.get(LEGACY_COUNTER_KEY, 0))
		if legacy_value > 0 and not (CounterType.GRAYWASH in tag_types):
			var legacy_state := _make_legacy_counter_state(legacy_value)
			legacy_state["type"] = primary_type if primary_type != CounterType.NONE else CounterType.OTHER
			counters = [legacy_state]
			migrated = true
	var counters_by_type := {}
	for entry in counters:
		if not (entry is Dictionary):
			continue
		var ctype := _get_counter_type_from_entry(entry, primary_type)
		if ctype == CounterType.NONE:
			ctype = CounterType.OTHER
		if not counters_by_type.has(ctype):
			counters_by_type[ctype] = []
		counters_by_type[ctype].append(entry)
	if CounterType.CHARGE in tag_types:
		if not counters_by_type.has(CounterType.CHARGE) or counters_by_type[CounterType.CHARGE].is_empty():
			counters_by_type[CounterType.CHARGE] = [{}]
			auto_created = true
	if CounterType.REFRESH in tag_types:
		if not counters_by_type.has(CounterType.REFRESH) or counters_by_type[CounterType.REFRESH].is_empty():
			var refresh_entry := {}
			if refresh_segments > 0:
				refresh_entry["segments"] = refresh_segments
			counters_by_type[CounterType.REFRESH] = [refresh_entry]
			auto_created = true
	if _should_add_overload_counter(tag_types):
		var other_entries: Array = counters_by_type.get(CounterType.OTHER, [])
		if not _has_counter_kind(other_entries, COUNTER_OVERLOAD_KIND):
			var overload_entry := {
				"name": _get_counter_default_name(CounterType.OTHER, COUNTER_OVERLOAD_KIND),
				"segments": COUNTER_OVERLOAD_SEGMENTS,
				"filled_segments": 0,
				"type": CounterType.OTHER,
				"counter_kind": COUNTER_OVERLOAD_KIND
			}
			other_entries.append(overload_entry)
			counters_by_type[CounterType.OTHER] = other_entries
			auto_created = true
	if _is_three_by_three_weapon():
		var other_entries: Array = counters_by_type.get(CounterType.OTHER, [])
		if not other_entries.is_empty() and not _has_counter_kind(other_entries, COUNTER_SALVO_KIND):
			var first_entry = other_entries[0]
			if first_entry is Dictionary:
				first_entry["counter_kind"] = COUNTER_SALVO_KIND
				if String(first_entry.get("name", "")).strip_edges() == "":
					var cached_name := _get_cached_counter_name(CounterType.OTHER, COUNTER_SALVO_KIND)
					if cached_name != "":
						first_entry["name"] = cached_name
						normalized = true
				normalized = true
		if other_entries.is_empty():
			var three_entry := {
				"name": _get_counter_default_name(CounterType.OTHER, COUNTER_SALVO_KIND),
				"segments": COUNTER_MIN_SEGMENTS,
				"filled_segments": 0,
				"type": CounterType.OTHER,
				"counter_kind": COUNTER_SALVO_KIND
			}
			other_entries.append(three_entry)
			counters_by_type[CounterType.OTHER] = other_entries
			auto_created = true
	for counter_type in TAG_COUNTER_ORDER:
		if not (counter_type in tag_types):
			continue
		var list: Array = counters_by_type.get(counter_type, [])
		var limit := _get_counter_limit(counter_type)
		var count := 0
		for entry in list:
			if not (entry is Dictionary):
				continue
			if limit > 0 and count >= limit:
				trimmed = true
				continue
			if counter_type == CounterType.PAYLOAD:
				var entry_segments := _to_int(entry.get("segments", 0))
				if entry_segments <= 0:
					if payload_segments <= 0:
						trimmed = true
						continue
					if _apply_payload_segments_to_entry(entry, payload_segments, true):
						normalized = true
			elif counter_type == CounterType.REFRESH and refresh_segments > 0:
				if _to_int(entry.get("segments", 0)) != refresh_segments:
					entry["segments"] = refresh_segments
					normalized = true
			else:
				var segments := _to_int(entry.get("segments", 0))
				if segments <= 0:
					entry["segments"] = COUNTER_MAX_SEGMENTS
					normalized = true
			_spawn_counter(entry, counter_type, _get_counter_default_name(counter_type))
			count += 1
	var other_list: Array = counters_by_type.get(CounterType.OTHER, [])
	for key in counters_by_type.keys():
		var t := _to_int(key)
		if t == CounterType.OTHER:
			continue
		if not (t in tag_types):
			for entry in counters_by_type[key]:
				if entry is Dictionary:
					other_list.append(entry)
					moved = true
	if CounterType.GRAYWASH in tag_types and not other_list.is_empty():
		other_list = []
		trimmed = true
	var allow_other := _allow_other_counters(tag_types)
	if not allow_other and not _is_three_by_three_weapon() and not other_list.is_empty():
		other_list = []
		trimmed = true
	var other_limit := _get_other_counter_limit(tag_types)
	if other_limit > 0 and other_list.size() > other_limit:
		var kept: Array = []
		for entry in other_list:
			if entry is Dictionary and String(entry.get("counter_kind", "")) == COUNTER_OVERLOAD_KIND:
				kept.append(entry)
				break
		for entry in other_list:
			if kept.size() >= other_limit:
				break
			if kept.has(entry):
				continue
			kept.append(entry)
		other_list = kept
		trimmed = true
	for entry in other_list:
		if entry is Dictionary:
			var kind := String(entry.get("counter_kind", ""))
			_spawn_counter(entry, CounterType.OTHER, _get_counter_default_name(CounterType.OTHER, kind))
	if migrated or trimmed or auto_created or normalized or moved:
		_sync_counters_data(true)

func _clear_counter_list() -> void:
	_resolve_counter_nodes()
	_clear_counter_container(_counter_list)
	if is_instance_valid(_counter_list_other) and _counter_list_other != _counter_list:
		_clear_counter_container(_counter_list_other)

func _clear_counter_container(container: Container) -> void:
	if not is_instance_valid(container):
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _spawn_counter(state: Dictionary, counter_type: int, fallback_label: String = "") -> void:
	_resolve_counter_nodes()
	var target_list := _get_counter_list_for_type(counter_type)
	if COUNTER_SCENE == null or not is_instance_valid(target_list):
		return
	var payload_value := -1
	if counter_type == CounterType.PAYLOAD:
		payload_value = _to_int(state.get("segments", 0))
		if payload_value <= 0:
			payload_value = _get_payload_segments()
		if payload_value <= 0:
			return
	var counter = COUNTER_SCENE.instantiate()
	target_list.add_child(counter)
	counter.set_meta("counter_type", counter_type)
	if counter_type == CounterType.PAYLOAD:
		counter.min_segments = COUNTER_MIN_SEGMENTS
	if counter.has_method("setup"):
		var prepared_state := state.duplicate(true)
		if counter_type != CounterType.OTHER:
			if counter_type == CounterType.PAYLOAD:
				var draw_segments := payload_value
				if draw_segments == 1:
					draw_segments = 2
					if not prepared_state.has("filled_segments"):
						prepared_state["filled_segments"] = 0
				draw_segments = clamp(draw_segments, PAYLOAD_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)
				prepared_state["segments"] = draw_segments
			else:
				var segments := _to_int(prepared_state.get("segments", 0))
				if segments <= 0:
					prepared_state["segments"] = COUNTER_MAX_SEGMENTS
		prepared_state["type"] = counter_type
		if prepared_state.has("counter_kind"):
			counter.set_meta("counter_kind", String(prepared_state.get("counter_kind")))
		var label := fallback_label
		if label == "":
			label = _get_ship_display_name()
		counter.setup(prepared_state, label)
		_apply_default_counter_fill(counter, counter_type, prepared_state)
		_apply_counter_delete_visibility(counter, counter_type)
	_connect_counter_signals(counter)

func _apply_default_counter_fill(counter: Node, counter_type: int, state: Dictionary) -> void:
	if state.has("filled_segments"):
		return
	if counter_type == CounterType.PAYLOAD:
		if counter.has_method("get_segments") and counter.has_method("set_filled_segments"):
			counter.set_filled_segments(0)
	elif counter_type == CounterType.CHARGE:
		if counter.has_method("set_filled_segments"):
			counter.set_filled_segments(0)
	elif counter_type == CounterType.REFRESH:
		if counter.has_method("get_segments") and counter.has_method("set_filled_segments"):
			counter.set_filled_segments(int(counter.get_segments()))
	elif counter_type == CounterType.GRAYWASH:
		if counter.has_method("set_filled_segments"):
			counter.set_filled_segments(0)

func _apply_counter_delete_visibility(counter: Node, counter_type: int) -> void:
	if not counter.has_method("set_delete_visible"):
		return
	counter.set_delete_visible(true)

func _connect_counter_signals(counter: Node) -> void:
	if counter.has_signal("changed"):
		var changed_cb = Callable(self, "_on_counter_changed")
		if not counter.changed.is_connected(changed_cb):
			counter.changed.connect(changed_cb)
	if counter.has_signal("removed"):
		var removed_cb = Callable(self, "_on_counter_removed").bind(counter)
		if not counter.removed.is_connected(removed_cb):
			counter.removed.connect(removed_cb)

func _get_counter_uid() -> String:
	if _data.has(COUNTER_UID_KEY):
		return String(_data.get(COUNTER_UID_KEY, ""))
	return ""

func get_counter_uid() -> String:
	return _get_counter_uid()

func _ensure_counter_uid() -> String:
	var existing := _get_counter_uid()
	if existing != "":
		return existing
	_counter_uid_seed += 1
	var uid := "%d_%d" % [Time.get_ticks_usec(), _counter_uid_seed]
	_data[COUNTER_UID_KEY] = uid
	return uid

func _sync_counters_data(save: bool = true) -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_list):
		return
	_ensure_counter_uid()
	var arr: Array = []
	_append_counter_states(_counter_list, arr, CounterType.NONE)
	if is_instance_valid(_counter_list_other) and _counter_list_other != _counter_list:
		_append_counter_states(_counter_list_other, arr, CounterType.OTHER)
	var primary_type := _get_primary_counter_type()
	for entry in arr:
		if entry is Dictionary:
			_cache_counter_name_from_state(entry, primary_type)
	_data[COUNTERS_KEY] = arr
	if save:
		BattlegroupData.save_data()
	BattlegroupData.counters_changed.emit(self, _get_counter_uid())

func _append_counter_states(container: Container, arr: Array, fallback_type: int) -> void:
	if not is_instance_valid(container):
		return
	for child in container.get_children():
		if not child.has_method("get_state"):
			continue
		var state: Dictionary = child.get_state()
		var counter_type := _to_int(state.get("type", CounterType.NONE))
		if counter_type == CounterType.NONE:
			counter_type = _get_counter_type_from_node(child, fallback_type)
		if counter_type == CounterType.NONE:
			counter_type = _get_primary_counter_type()
		if counter_type == CounterType.NONE:
			counter_type = CounterType.OTHER
		state["type"] = counter_type
		if child.has_meta("counter_kind"):
			var kind := String(child.get_meta("counter_kind"))
			if kind != "":
				state["counter_kind"] = kind
		arr.append(state)

func _make_legacy_counter_state(value: int) -> Dictionary:
	var segments = clamp(max(value, COUNTER_MIN_SEGMENTS), COUNTER_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)
	var filled = clamp(value, 0, segments)
	return {
		"name": String(_data.get("name", "")),
		"segments": segments,
		"filled_segments": filled
	}

func _apply_name_wrap() -> void:
	if _data.is_empty():
		return
	var raw := String(_data.get("name", ""))
	if is_instance_valid(_name):
		_name.text = _wrap_button_text(_name, raw)
	if is_instance_valid(_collapsed_btn):
		_collapsed_btn.text = _wrap_button_text(_collapsed_btn, raw)

func _wrap_button_text(btn: Button, raw_text: String) -> String:
	if raw_text.strip_edges() == "":
		return raw_text
	var font := btn.get_theme_font("font")
	if font == null:
		return raw_text
	var font_size := btn.get_theme_font_size("font_size")
	if font_size <= 0:
		font_size = -1
	var max_width := btn.size.x
	if max_width <= 0:
		max_width = btn.get_combined_minimum_size().x
	var stylebox := btn.get_theme_stylebox("normal")
	if stylebox:
		max_width -= stylebox.get_margin(SIDE_LEFT) + stylebox.get_margin(SIDE_RIGHT)
	max_width -= btn.get_theme_constant("h_separation")
	if max_width <= 0:
		return raw_text
	return _wrap_text_to_width(font, font_size, raw_text, max_width)

func _wrap_text_to_width(font: Font, font_size: int, raw_text: String, max_width: float) -> String:
	var lines := []
	for part in raw_text.split("\n"):
		lines.append_array(_wrap_line_to_width(font, font_size, part, max_width))
	return "\n".join(lines)

func _wrap_line_to_width(font: Font, font_size: int, text: String, max_width: float) -> Array:
	var words := text.split(" ", false)
	if words.is_empty():
		return [""]
	var lines := []
	var current := ""
	for w in words:
		var candidate := w if current == "" else current + " " + w
		if _text_width(font, font_size, candidate) <= max_width:
			current = candidate
			continue
		if current != "":
			lines.append(current)
			current = ""
		if _text_width(font, font_size, w) <= max_width:
			current = w
			continue
		lines.append_array(_split_long_word(font, font_size, w, max_width))
	if current != "":
		lines.append(current)
	return lines

func _split_long_word(font: Font, font_size: int, word: String, max_width: float) -> Array:
	var parts := []
	var current := ""
	for ch in word:
		var candidate := current + ch
		if _text_width(font, font_size, candidate) <= max_width:
			current = candidate
			continue
		if current != "":
			parts.append(current)
		current = ch
	if current != "":
		parts.append(current)
	return parts

func _text_width(font: Font, font_size: int, text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func _is_azure_star() -> bool:
	return String(_data.get("name", "")) == BattlegroupData.AZURE_STAR_NAME

func _get_azure_star_used() -> bool:
	return bool(_data.get(BattlegroupData.AZURE_STAR_USE_KEY, false))

func _on_azure_star_use_toggled(pressed: bool, _index: int) -> void:
	if not _is_azure_star():
		return
	_data[BattlegroupData.AZURE_STAR_USE_KEY] = pressed
	BattlegroupData.save_data()

func _max_regex_count(text: String, pattern: String) -> int:
	var regex := RegEx.new()
	var err := regex.compile(pattern)
	if err != OK:
		return 0
	var matches := regex.search_all(text)
	var max_uses := 0
	for m in matches:
		var n := int(m.get_string(1))
		if n > max_uses:
			max_uses = n
	return max_uses

# получает флаг «можно ли удалять» и ссылку на корабль
func set_context(removable: bool, host_ship: Dictionary, is_option_item: bool=false, context_mode: String = "option") -> void:
	_removable      = removable
	_host_ship      = host_ship
	_is_option_item = is_option_item
	_context_mode   = context_mode
	_apply_collapsed_theme()
	_apply_name_wrap()
	_update_remove_visibility()
	_update_battle_visibility()

func _update_remove_visibility() -> void:
	if not is_instance_valid(_remove_btn):
		return
	var t := int(_data.get("type", -999))
	# Прятать Remove только для option-элементов, если это слоты 7/8 (Тактика/Манёвр как опция)
	var is_tactic_or_maneuver_option := _is_option_item and (t == 7 or t == 8)
	_remove_btn.visible = _removable and not BattlegroupData.in_battle and not is_tactic_or_maneuver_option and not _data.get("name") == "FLAGSHIP"

func _on_battle_state_changed(enabled: bool) -> void:
	_update_remove_visibility()
	_update_battle_visibility()
	_update_uses()
	if enabled:
		_reset_counters_for_battle()
	_update_counter_visibility()

func _on_range_changed(_value: int) -> void:
	_update_payload_segments_for_range()

func _update_payload_segments_for_range() -> void:
	if _data.is_empty():
		return
	var tag_types := _get_tag_counter_types()
	if not (CounterType.PAYLOAD in tag_types):
		return
	# Payload counters keep their segment count after creation.
	return

func _reset_counters_for_battle() -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_block):
		return
	if _is_counter_forbidden():
		return
	var tag_types: Array = _get_tag_counter_types()
	var primary_type = _get_primary_counter_type(tag_types)
	var counters = _data.get(COUNTERS_KEY, [])
	if not (counters is Array):
		counters = []
	var payload_segments := _get_payload_segments() if CounterType.PAYLOAD in tag_types else 0
	var charge_segments := _get_charge_segments() if CounterType.CHARGE in tag_types else 0
	var refresh_segments := _get_refresh_segments() if CounterType.REFRESH in tag_types else 0
	var fresh: Array = []
	var counts := {}
	var kinds := {}
	if not counters.is_empty():
		_ensure_counter_uid()
	for entry in counters:
		if not (entry is Dictionary):
			continue
		var state = entry.duplicate(true)
		var ctype = _get_counter_type_from_entry(state, primary_type)
		if ctype == CounterType.NONE:
			ctype = CounterType.OTHER
		if ctype == CounterType.PAYLOAD:
			_cache_counter_name_from_state(state, primary_type)
			continue
		var kind = String(state.get("counter_kind", ""))
		var cached_name := _get_cached_counter_name(ctype, kind)
		if String(state.get("name", "")).strip_edges() == "" and cached_name != "":
			state["name"] = cached_name
		if ctype == CounterType.PAYLOAD and payload_segments > 0:
			_apply_payload_segments_to_entry(state, payload_segments, true)
		elif ctype == CounterType.CHARGE and charge_segments > 0:
			state["segments"] = charge_segments
		elif ctype == CounterType.REFRESH and refresh_segments > 0:
			state["segments"] = refresh_segments
		elif kind == COUNTER_OVERLOAD_KIND:
			state["segments"] = COUNTER_OVERLOAD_SEGMENTS
		elif kind == COUNTER_SALVO_KIND:
			state["segments"] = COUNTER_MIN_SEGMENTS
		elif _to_int(state.get("segments", 0)) <= 0:
			state["segments"] = COUNTER_MAX_SEGMENTS
		state["filled_segments"] = 0
		fresh.append(state)
		if ctype in tag_types:
			counts[ctype] = int(counts.get(ctype, 0)) + 1
		if kind != "":
			kinds[kind] = true

	for counter_type in tag_types:
		if counter_type == CounterType.PAYLOAD:
			continue
		var limit := _get_counter_limit(counter_type)
		var current_count := int(counts.get(counter_type, 0))
		if limit > 0 and current_count >= limit:
			continue
		var state := {}
		var cached_name := _get_cached_counter_name(counter_type, "")
		if cached_name != "":
			state["name"] = cached_name
		if counter_type == CounterType.PAYLOAD:
			_apply_payload_segments_to_entry(state, payload_segments, true)
		elif counter_type == CounterType.CHARGE:
			if charge_segments > 0:
				state["segments"] = charge_segments
		elif counter_type == CounterType.REFRESH:
			if refresh_segments > 0:
				state["segments"] = refresh_segments
		state["filled_segments"] = 0
		state["type"] = counter_type
		fresh.append(state)
		counts[counter_type] = current_count + 1

	if _should_add_overload_counter(tag_types) and not kinds.has(COUNTER_OVERLOAD_KIND):
		var overload_state := {
			"type": CounterType.OTHER,
			"counter_kind": COUNTER_OVERLOAD_KIND,
			"segments": COUNTER_OVERLOAD_SEGMENTS,
			"filled_segments": 0,
		}
		var cached_name := _get_cached_counter_name(CounterType.OTHER, COUNTER_OVERLOAD_KIND)
		if cached_name != "":
			overload_state["name"] = cached_name
		fresh.append(overload_state)

	if _is_three_by_three_weapon() and not kinds.has(COUNTER_SALVO_KIND):
		var salvo_state := {
			"type": CounterType.OTHER,
			"counter_kind": COUNTER_SALVO_KIND,
			"segments": COUNTER_MIN_SEGMENTS,
			"filled_segments": 0,
		}
		var cached_name := _get_cached_counter_name(CounterType.OTHER, COUNTER_SALVO_KIND)
		if cached_name != "":
			salvo_state["name"] = cached_name
		fresh.append(salvo_state)

	_data[COUNTERS_KEY] = fresh
	BattlegroupData.save_data()
	BattlegroupData.counters_changed.emit(self, _get_counter_uid())
	_rebuild_counters()

func _on_counters_changed(source: Object, counter_uid: String) -> void:
	if source == self:
		return
	if counter_uid == "":
		return
	if _get_counter_uid() != counter_uid:
		return
	_rebuild_counters()
	_update_counter_visibility()


func _on_hide_pressed() -> void:
	set_collapsed(true)

func _on_counter_pressed() -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_list) or COUNTER_SCENE == null:
		return
	var tag_types := _get_tag_counter_types()
	var added := false
	if _is_three_by_three_weapon() and not _has_counter_kind_in_list(_counter_list, COUNTER_SALVO_KIND):
		var salvo_state = {
			"segments": COUNTER_MIN_SEGMENTS,
			"counter_kind": COUNTER_SALVO_KIND
		}
		_spawn_counter(salvo_state, CounterType.OTHER, _get_counter_default_name(CounterType.OTHER, COUNTER_SALVO_KIND))
		added = true
	if not added:
		for counter_type in TAG_COUNTER_ORDER:
			if not (counter_type in tag_types):
				continue
			var count = _count_counters_of_type(_counter_list, counter_type)
			if _is_auto_counter_type(counter_type) and count > 0:
				continue
			var limit = _get_counter_limit(counter_type)
			if limit > 0 and count >= limit:
				continue
			var state = {}
			if counter_type == CounterType.CHARGE:
				var charge_segments = _get_charge_segments()
				if charge_segments > 0:
					state["segments"] = charge_segments
			elif counter_type == CounterType.PAYLOAD:
				var payload_segments = _get_payload_segments()
				if payload_segments <= 0:
					continue
				if payload_segments == 1:
					state["segments"] = 2
					state["filled_segments"] = 0
				else:
					state["segments"] = payload_segments
			elif counter_type == CounterType.REFRESH:
				var refresh_segments = _get_refresh_segments()
				if refresh_segments > 0:
					state["segments"] = refresh_segments
			_spawn_counter(state, counter_type, _get_counter_default_name(counter_type))
			added = true
			break
	if added:
		_sync_counters_data(true)
		_update_counter_visibility()

func _on_counter_other_pressed() -> void:
	_resolve_counter_nodes()
	if not is_instance_valid(_counter_list_other) or COUNTER_SCENE == null:
		return
	if _counter_list_other == _counter_list:
		return
	var tag_types := _get_tag_counter_types()
	var current_count := _count_counters_of_type(_counter_list_other, CounterType.OTHER)
	if not _can_add_other_counter(tag_types, current_count):
		return
	_spawn_counter({}, CounterType.OTHER, _get_counter_default_name(CounterType.OTHER))
	_sync_counters_data(true)
	_update_counter_visibility()

func _on_counter_changed() -> void:
	_sync_counters_data(true)

func _on_counter_removed(counter: Node) -> void:
	_cache_counter_name_from_node(counter, _get_primary_counter_type())
	call_deferred("_sync_counters_after_remove")

func _sync_counters_after_remove() -> void:
	await get_tree().process_frame
	_sync_counters_data(true)
	_update_counter_visibility()

func _on_remove_pressed() -> void:
	if not _removable:
		return

	match _context_mode:
		"commendation":
			if BattlegroupData.remove_commendation(_data):
				queue_free()
			return
		"reputation":
			if BattlegroupData.remove_reputation(_data):
				queue_free()
			return
		"reputation_advance":
			if BattlegroupData.remove_reputation_advance(_data):
				queue_free()
			return
		"legacy":
			if _host_ship.is_empty():
				return
			var arr: Array = _host_ship.get("legacies", [])
			if not (arr is Array):
				return
			if _remove_from_array_by_template(arr):
				_host_ship["legacies"] = arr
				var root := get_parent()
				if root and root.get_parent() and root.get_parent().get_parent() and root.get_parent().get_parent().get_parent():
					root.get_parent().get_parent().get_parent()._refresh_option_buttons()
				BattlegroupData.option_change.emit()
				queue_free()
			return
		_:
			pass

	if _host_ship.is_empty():
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
	BattlegroupData.refresh_point()
	BattlegroupData.option_change.emit()
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
	var kind := _resolve_theme_kind()
	var header_theme := _get_header_theme_for_kind(kind)
	var body_theme := _get_body_theme_for_kind(kind)
	if header_theme != null:
		_header.theme = header_theme
	if body_theme != null:
		_card_panel.theme = body_theme
	_apply_collapsed_theme()

func _resolve_theme_kind() -> String:
	if _context_mode == "legacy":
		return "legacy"
	if _context_mode == "commendation":
		return "commendation"
	if _context_mode == "reputation" or _context_mode == "reputation_advance":
		return "reputation"
	var type_value := _to_int(_data.get("type", -1))
	var is_option := _data.has("modification") or _data.has("points")
	if is_option:
		match type_value:
			0, 1, 2:
				return "weapon"
			3:
				return "system"
			4, 5:
				return "wing_escort"
			7:
				return "tactic"
			8:
				return "maneuver"
	else:
		match type_value:
			0:
				return "feat"
			1:
				return "maneuver"
			2:
				return "tactic"
			3:
				return "weapon"
			4, 5:
				return "wing_escort"
			7:
				return "tactic"
			8:
				return "maneuver"
	return "feat"

func _get_header_theme_for_kind(kind: String) -> Theme:
	match kind:
		"weapon":
			return weapon_header
		"system":
			return system_header
		"maneuver":
			return maneuver_header
		"tactic":
			return tactic_header
		"wing_escort":
			return wing_escort_header
		"legacy":
			return legacy_header
		"commendation":
			return commendation_header
		"reputation":
			return reputation_header
		"feat":
			return feat_header
		_:
			return null

func _get_body_theme_for_kind(kind: String) -> Theme:
	match kind:
		"weapon":
			return weapon_body
		"system":
			return system_body
		"maneuver":
			return maneuver_body
		"tactic":
			return tactic_body
		"wing_escort":
			return wing_escort_body
		"legacy":
			return legacy_body
		"commendation":
			return commendation_body
		"reputation":
			return reputation_body
		"feat":
			return feat_body
		_:
			return null

func populate(data: Dictionary) -> void:
	_data = data  # ← запоминаем, нужно для удаления/логики
	_apply_name_wrap()
	_tags.text = data.get("tags", "")

	_damage.text = ""
	_range.text = ""
	if str(data.get("damage", "")).strip_edges() != "":
		_damage.text = "[Урон %s]" % data.get("damage")
	var display_range := _get_display_range(data)
	if display_range != "":
		_range.text = "[Дистанция %s]" % display_range
	if str(data.get("points", "")).strip_edges() != "":
		_point.text = "[Очки %s]" % data.get("points")
	var display_tenacity := _get_display_tenacity(data)
	if display_tenacity != "":
		_tenacity.text = "[Упорство %s]" % display_tenacity
	if str(data.get("hp", "")).strip_edges() != "":
		_hp.text = "[HP %s]" % data.get("hp")

	_effect.text = data.get("effect", "")
	_discription.text = "[i]" + data.get("discription", "")

	_hide_if_text_empty(_card_panel)
	_change_theme()
	_update_remove_visibility()
	_update_battle_visibility()
	_rebuild_counters()
	_update_uses()
	_update_counter_visibility()


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

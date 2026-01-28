extends VBoxContainer

const COUNTER_SCENE = preload("res://counter/Counter.tscn")
const COUNTERS_KEY = "counters"
const COUNTER_UID_KEY = "counter_uid"
const COUNTER_NAME_CACHE_KEY = "counter_name_cache"
const COUNTER_MIN_SEGMENTS = 2
const COUNTER_MAX_SEGMENTS = 8
const PAYLOAD_MIN_SEGMENTS = 0
const COUNTER_OVERLOAD_KIND = "overload"
const COUNTER_SALVO_KIND = "salvo"
const SALVO_OPTION_NAME = "3X3 BLOCK SHORT-SPOOL CANNONS"
const LINK_ICON = preload("res://assets/icons/link-svgrepo-com.svg")

enum CounterType { NONE, PAYLOAD, CHARGE, GRAYWASH, REFRESH, OTHER }

@onready var _group_charge: VBoxContainer = $VBoxContainer
@onready var _group_payload: VBoxContainer = $VBoxContainer2
@onready var _group_refresh: VBoxContainer = $VBoxContainer3
@onready var _group_graywash: VBoxContainer = $VBoxContainer4
@onready var _group_overload: VBoxContainer = $VBoxContainer5
@onready var _group_salvo: VBoxContainer = $VBoxContainer6
@onready var _group_other: VBoxContainer = $VBoxContainer7

var _groups: Dictionary = {}
var _group_order: Array = []
var _option_by_uid: Dictionary = {}
var _refresh_guard = false
var _has_any_counters := false
static var _counter_uid_seed = 0

func _ready() -> void:
	_groups = {
		"charge": _group_charge,
		"payload": _group_payload,
		"refresh": _group_refresh,
		"graywash": _group_graywash,
		"overload": _group_overload,
		"salvo": _group_salvo,
		"other": _group_other,
	}
	_group_order = ["charge", "payload", "refresh", "graywash", "overload", "salvo", "other"]
	if not BattlegroupData.battle_state_changed.is_connected(_on_battle_state_changed):
		BattlegroupData.battle_state_changed.connect(_on_battle_state_changed)
	if not BattlegroupData.option_change.is_connected(_on_option_change):
		BattlegroupData.option_change.connect(_on_option_change)
	if not BattlegroupData.counters_changed.is_connected(_on_counters_changed):
		BattlegroupData.counters_changed.connect(_on_counters_changed)
	_apply_battle_visibility()
	call_deferred("_rebuild")

func _on_battle_state_changed(_enabled: bool) -> void:
	_apply_battle_visibility()
	if BattlegroupData.in_battle:
		call_deferred("_rebuild")

func _on_option_change() -> void:
	if not BattlegroupData.in_battle:
		return
	call_deferred("_rebuild")

func _on_counters_changed(source: Object, _counter_uid: String) -> void:
	if source == self:
		return
	if not BattlegroupData.in_battle:
		return
	call_deferred("_rebuild")

func _apply_battle_visibility() -> void:
	visible = BattlegroupData.in_battle and _has_any_counters

func _rebuild() -> void:
	if _refresh_guard or not BattlegroupData.in_battle:
		return
	_refresh_guard = true
	_clear_groups()
	_option_by_uid = {}
	var grouped: Dictionary = {}
	for key in _group_order:
		grouped[key] = []
	for ship in BattlegroupData.ships:
		var opts: Array = ship.get("option", [])
		for opt in opts:
			var counters = opt.get(COUNTERS_KEY, [])
			if not (counters is Array) or counters.is_empty():
				continue
			var uid = _ensure_option_uid(opt)
			_option_by_uid[uid] = opt
			var ship_label = _get_ship_display_name(ship)
			for entry in counters:
				if not (entry is Dictionary):
					continue
				var state: Dictionary = entry.duplicate(true)
				var group_key = _get_group_key(state, opt)
				if not grouped.has(group_key):
					group_key = "other"
				grouped[group_key].append({
					"uid": uid,
					"ship_label": ship_label,
					"state": state,
				})
	for key in _group_order:
		var group: VBoxContainer = _groups.get(key)
		if not is_instance_valid(group):
			continue
		var entries: Array = grouped.get(key, [])
		for entry in entries:
			_spawn_counter(group, key, entry)
		group.visible = entries.size() > 0
	var total := 0
	for key in _group_order:
		total += int(grouped.get(key, []).size())
	_has_any_counters = total > 0
	_apply_battle_visibility()
	_refresh_guard = false

func _clear_groups() -> void:
	for key in _group_order:
		var group: VBoxContainer = _groups.get(key)
		if not is_instance_valid(group):
			continue
		for child in group.get_children():
			if child is Label:
				continue
			group.remove_child(child)
			child.queue_free()

func _get_group_key(state: Dictionary, option_ref: Dictionary) -> String:
	var kind = String(state.get("counter_kind", ""))
	if kind == COUNTER_OVERLOAD_KIND:
		return "overload"
	if kind == COUNTER_SALVO_KIND:
		return "salvo"
	if _is_salvo_option(option_ref):
		return "salvo"
	var ctype = _to_int(state.get("type", CounterType.NONE))
	match ctype:
		CounterType.CHARGE:
			return "charge"
		CounterType.REFRESH:
			return "refresh"
		CounterType.PAYLOAD:
			return "payload"
		CounterType.GRAYWASH:
			return "graywash"
		_:
			return "other"

func _spawn_counter(group: VBoxContainer, group_key: String, entry: Dictionary) -> void:
	if COUNTER_SCENE == null or not is_instance_valid(group):
		return
	var counter = COUNTER_SCENE.instantiate()
	group.add_child(counter)
	var state: Dictionary = entry.get("state", {}).duplicate(true)
	var uid = String(entry.get("uid", ""))
	var counter_type = _to_int(state.get("type", CounterType.NONE))
	if counter_type == CounterType.NONE:
		counter_type = CounterType.OTHER
	counter.set_meta("counter_type", counter_type)
	if counter_type == CounterType.PAYLOAD:
		counter.min_segments = COUNTER_MIN_SEGMENTS
	counter.set_meta("counter_uid", uid)
	if state.has("counter_kind"):
		counter.set_meta("counter_kind", String(state.get("counter_kind")))
	var segments = _to_int(state.get("segments", 0))
	if counter_type == CounterType.PAYLOAD:
		segments = clamp(segments, PAYLOAD_MIN_SEGMENTS, COUNTER_MAX_SEGMENTS)
		state["segments"] = segments
	elif segments <= 0:
		state["segments"] = COUNTER_MAX_SEGMENTS
	state["type"] = counter_type
	var fallback_label = _get_fallback_label(entry.get("ship_label", ""), state)
	if counter.has_method("setup"):
		counter.setup(state, fallback_label)
	_apply_default_counter_fill(counter, counter_type, state)
	_apply_counter_delete_visibility(counter, counter_type, group_key)
	_connect_counter_signals(counter)
	_setup_link_button(counter)

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

func _apply_counter_delete_visibility(counter: Node, counter_type: int, group_key: String) -> void:
	if not counter.has_method("set_delete_visible"):
		return
	counter.set_delete_visible(true)

func _connect_counter_signals(counter: Node) -> void:
	if counter.has_signal("changed"):
		var changed_cb = Callable(self, "_on_counter_changed").bind(counter)
		if not counter.changed.is_connected(changed_cb):
			counter.changed.connect(changed_cb)
	if counter.has_signal("removed"):
		var removed_cb = Callable(self, "_on_counter_removed").bind(counter)
		if not counter.removed.is_connected(removed_cb):
			counter.removed.connect(removed_cb)

func _setup_link_button(counter: Node) -> void:
	if counter == null:
		return
	var button = counter.get_node_or_null(NodePath("Delete")) as TextureButton
	if button == null:
		button = counter.find_child("Delete", true, false) as TextureButton
	if button == null:
		return
	if LINK_ICON != null:
		button.texture_normal = LINK_ICON
		button.texture_hover = LINK_ICON
		button.texture_pressed = LINK_ICON
		button.texture_focused = LINK_ICON
		button.texture_disabled = LINK_ICON
	var delete_cb = Callable(counter, "_on_texture_button_pressed")
	if button.pressed.is_connected(delete_cb):
		button.pressed.disconnect(delete_cb)
	var nav_cb = Callable(self, "_on_link_pressed").bind(counter)
	if not button.pressed.is_connected(nav_cb):
		button.pressed.connect(nav_cb)

func _on_link_pressed(counter: Node) -> void:
	if counter == null or not is_instance_valid(counter):
		return
	var uid = String(counter.get_meta("counter_uid", ""))
	if uid == "":
		return
	var signature = _build_counter_signature(counter)
	call_deferred("_navigate_to_counter", uid, signature)

func _navigate_to_counter(uid: String, signature: String) -> void:
	if uid == "":
		return
	var item_card = _find_item_card_by_uid(uid)
	if item_card == null:
		return
	_expand_item_card(item_card)
	await get_tree().process_frame
	var target = _find_matching_counter(item_card, signature)
	if target == null:
		target = item_card
	_ensure_control_visible(target)
	_focus_counter(target)

func _find_item_card_by_uid(uid: String) -> Node:
	var ship_list = _get_ship_list()
	if ship_list == null:
		return null
	var nodes = ship_list.find_children("*", "", true, false)
	for node in nodes:
		if not node.has_method("get_counter_uid"):
			continue
		if String(node.get_counter_uid()) == uid:
			return node
	return null

func _get_ship_list() -> Node:
	var root = get_parent()
	if root == null:
		return null
	return root.get_node_or_null("Ship_list")

func _expand_ship_for_item(item_card: Node) -> void:
	if item_card == null:
		return
	var ship_node = _find_ship_node(item_card)
	if ship_node == null:
		return
	var hide_box = ship_node.get_node_or_null("Ship_box/VBoxContainer") as VBoxContainer
	if hide_box != null and not hide_box.visible:
		hide_box.show()

func _expand_item_card(item_card: Node) -> void:
	if item_card == null:
		return
	_expand_ship_for_item(item_card)
	if item_card is CanvasItem:
		(item_card as CanvasItem).show()
	if item_card.has_method("set_collapsed"):
		item_card.set_collapsed(false)
	if item_card.has_method("_update_counter_visibility"):
		item_card.call_deferred("_update_counter_visibility")

func _find_ship_node(node: Node) -> Node:
	var current = node
	while current != null:
		if current.get_node_or_null("Ship_box/VBoxContainer") != null:
			return current
		current = current.get_parent()
	return null

func _find_matching_counter(item_card: Node, signature: String) -> Control:
	if signature == "" or item_card == null:
		return null
	var nodes = item_card.find_children("*", "", true, false)
	for node in nodes:
		if not node.has_method("get_state"):
			continue
		if not node.has_meta("counter_type"):
			continue
		var node_signature = _build_counter_signature(node)
		if node_signature == signature:
			return node as Control
	return null

func _build_counter_signature(counter: Node) -> String:
	if counter == null:
		return ""
	var state: Dictionary = {}
	if counter.has_method("get_state"):
		state = counter.get_state()
	var name = String(state.get("name", "")).strip_edges()
	var segments = _to_int(state.get("segments", 0))
	var filled = _to_int(state.get("filled_segments", 0))
	var ctype = _to_int(state.get("type", CounterType.NONE))
	if ctype == CounterType.NONE and counter.has_meta("counter_type"):
		ctype = _to_int(counter.get_meta("counter_type"))
	var kind = ""
	if counter.has_meta("counter_kind"):
		kind = String(counter.get_meta("counter_kind"))
	return "%d|%s|%d|%d|%s" % [ctype, name, segments, filled, kind]

func _ensure_control_visible(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	var current = target.get_parent()
	while current != null:
		if current is ScrollContainer:
			var scroller = current as ScrollContainer
			scroller.ensure_control_visible(target)
			return
		current = current.get_parent()

func _focus_counter(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	var label = target.get_node_or_null(NodePath("Label")) as LineEdit
	if label == null:
		label = target.find_child("Label", true, false) as LineEdit
	if label != null:
		label.grab_focus()


func _on_counter_changed(counter: Node) -> void:
	_sync_option_counters(counter)

func _on_counter_removed(counter: Node) -> void:
	_cache_counter_name_from_node(counter)
	call_deferred("_sync_option_counters", counter)

func _sync_option_counters(counter: Node) -> void:
	if _refresh_guard or counter == null:
		return
	if not is_instance_valid(counter):
		return
	var uid = String(counter.get_meta("counter_uid", ""))
	if uid == "":
		return
	var option_ref: Dictionary = _option_by_uid.get(uid, {})
	if option_ref.is_empty():
		option_ref = _find_option_by_uid(uid)
	if option_ref.is_empty():
		return
	var arr: Array = []
	for key in _group_order:
		var group: VBoxContainer = _groups.get(key)
		if not is_instance_valid(group):
			continue
		for child in group.get_children():
			if child is Label or child.is_queued_for_deletion():
				continue
			if String(child.get_meta("counter_uid", "")) != uid:
				continue
			if not child.has_method("get_state"):
				continue
			var state: Dictionary = child.get_state()
			var ctype = _to_int(state.get("type", CounterType.NONE))
			if ctype == CounterType.NONE:
				ctype = _to_int(child.get_meta("counter_type", CounterType.OTHER))
			if ctype == CounterType.NONE:
				ctype = CounterType.OTHER
			state["type"] = ctype
			if child.has_meta("counter_kind"):
				var kind = String(child.get_meta("counter_kind"))
				if kind != "":
					state["counter_kind"] = kind
			arr.append(state)
	_update_counter_name_cache(option_ref, arr)
	option_ref[COUNTERS_KEY] = arr
	BattlegroupData.save_data()
	BattlegroupData.counters_changed.emit(self, uid)
	_refresh_group_visibility()

func _cache_counter_name_from_node(counter: Node) -> void:
	if counter == null or not is_instance_valid(counter):
		return
	var uid = String(counter.get_meta("counter_uid", ""))
	if uid == "":
		return
	var option_ref: Dictionary = _option_by_uid.get(uid, {})
	if option_ref.is_empty():
		option_ref = _find_option_by_uid(uid)
	if option_ref.is_empty():
		return
	var state: Dictionary = {}
	if counter.has_method("get_state"):
		state = counter.get_state()
	if counter.has_meta("counter_type") and not state.has("type"):
		state["type"] = _to_int(counter.get_meta("counter_type"))
	if counter.has_meta("counter_kind") and not state.has("counter_kind"):
		state["counter_kind"] = String(counter.get_meta("counter_kind"))
	_cache_counter_name_from_state(option_ref, state)

func _update_counter_name_cache(option_ref: Dictionary, entries: Array) -> void:
	if option_ref.is_empty():
		return
	for entry in entries:
		if entry is Dictionary:
			_cache_counter_name_from_state(option_ref, entry)

func _cache_counter_name_from_state(option_ref: Dictionary, state: Dictionary) -> void:
	if option_ref.is_empty() or not (state is Dictionary):
		return
	var name := String(state.get("name", "")).strip_edges()
	if name == "":
		return
	var ctype := _to_int(state.get("type", CounterType.NONE))
	if ctype == CounterType.NONE and state.has("counter_type"):
		ctype = _to_int(state.get("counter_type"))
	if ctype == CounterType.NONE:
		ctype = CounterType.OTHER
	var kind := String(state.get("counter_kind", ""))
	_set_cached_counter_name(option_ref, ctype, kind, name)

func _set_cached_counter_name(option_ref: Dictionary, counter_type: int, kind: String, name: String) -> void:
	var trimmed := name.strip_edges()
	if trimmed == "":
		return
	var cache := _get_counter_name_cache(option_ref)
	cache[_counter_name_key(counter_type, kind)] = trimmed
	option_ref[COUNTER_NAME_CACHE_KEY] = cache

func _get_counter_name_cache(option_ref: Dictionary) -> Dictionary:
	var cache = option_ref.get(COUNTER_NAME_CACHE_KEY, {})
	if cache == null or not (cache is Dictionary):
		cache = {}
	option_ref[COUNTER_NAME_CACHE_KEY] = cache
	return cache

func _counter_name_key(counter_type: int, kind: String = "") -> String:
	if kind != "":
		return "kind:%s" % kind
	return "type:%d" % counter_type

func _refresh_group_visibility() -> void:
	var total := 0
	for key in _group_order:
		var group: VBoxContainer = _groups.get(key)
		if not is_instance_valid(group):
			continue
		var count = 0
		for child in group.get_children():
			if child is Label or child.is_queued_for_deletion():
				continue
			count += 1
		group.visible = count > 0
		total += count
	_has_any_counters = total > 0
	_apply_battle_visibility()

func _find_option_by_uid(uid: String) -> Dictionary:
	for ship in BattlegroupData.ships:
		var opts: Array = ship.get("option", [])
		for opt in opts:
			if String(opt.get(COUNTER_UID_KEY, "")) == uid:
				return opt
	return {}

func _ensure_option_uid(option_ref: Dictionary) -> String:
	var existing = String(option_ref.get(COUNTER_UID_KEY, ""))
	if existing != "":
		return existing
	_counter_uid_seed += 1
	var uid = "%d_%d" % [Time.get_ticks_usec(), _counter_uid_seed]
	option_ref[COUNTER_UID_KEY] = uid
	return uid

func _is_salvo_option(option_ref: Dictionary) -> bool:
	return String(option_ref.get("name", "")).strip_edges() == SALVO_OPTION_NAME

func _get_ship_display_name(ship: Dictionary) -> String:
	var ship_name = String(ship.get("ship_name", "")).strip_edges()
	if ship_name != "":
		return ship_name
	return String(ship.get("name", ""))

func _get_fallback_label(ship_label: String, state: Dictionary) -> String:
	var name = String(state.get("name", "")).strip_edges()
	if name != "":
		return name
	return ship_label

func _to_int(v) -> int:
	match typeof(v):
		TYPE_INT:
			return int(v)
		TYPE_FLOAT:
			return int(round(v))
		TYPE_STRING:
			var s = String(v).strip_edges()
			if s == "":
				return 0
			if s.is_valid_int():
				return s.to_int()
			if s.is_valid_float():
				return int(round(s.to_float()))
			return 0
		_:
			return 0

extends Node    # BattlegroupData

enum ShipClass { FRIGATE, CARRIER, BATTLESHIP }

const AZURE_STAR_NAME := "Азурная Звезда"
const AZURE_STAR_USE_KEY := "azure_star_used"
const HESPERIS_HULL_NAME := "FKS\nHESPERIS-CLASS BATTLECRUISER"
const SCKV_HULL_NAME := "SELF-CONTAINED KILL VEHICLE"
const SCKV_COUNT := 2
const SCKV_FLAG_KEY := "is_sckv"
const SCKV_HOST_KEY := "sckv_host"
const SCKV_INDEX_KEY := "sckv_index"

signal battlegroup_change
signal option_change
signal option_list_requested
signal legacies_change
signal commendations_change
signal reputations_change
signal reputation_advances_change
signal battle_state_changed
signal flagship_changed
signal counters_changed
signal range_changed

var point = 0
var in_battle := false
var range_value := 5
var battlegroup_note := ""

func _is_sckv(ship: Dictionary) -> bool:
	return bool(ship.get(SCKV_FLAG_KEY, false))

func _build_sckv_ship(index: int) -> Dictionary:
	return {
		"name": SCKV_HULL_NAME,
		"ship_name": SCKV_HULL_NAME,
		"class": ShipClass.BATTLESHIP,
		"defense": "10",
		"hp": "10",
		"points": "0",
		"weapon_slots": {"auxiliaries": "1", "primaries": "0", "superheavy": "0"},
		"support_slots": {"systems": "0", "wings": "0", "escorts": "0"},
		"option": [],
		"legacies": [],
		"feats": [],
		"flagman": false,
		"note": "",
		SCKV_FLAG_KEY: true,
		SCKV_HOST_KEY: HESPERIS_HULL_NAME,
		SCKV_INDEX_KEY: index,
	}

func _ensure_hesperis_sckv() -> void:
	var has_hesperis := false
	for ship in ships:
		if _is_sckv(ship):
			continue
		if String(ship.get("name", "")) == HESPERIS_HULL_NAME:
			has_hesperis = true
			break
	if not has_hesperis:
		_remove_sckv_for_host(HESPERIS_HULL_NAME)
		return
	var existing := {}
	for ship in ships:
		if not _is_sckv(ship):
			continue
		if String(ship.get(SCKV_HOST_KEY, "")) != HESPERIS_HULL_NAME:
			continue
		var idx := _to_int(ship.get(SCKV_INDEX_KEY, 0))
		if idx > 0:
			existing[idx] = true
	for i in range(1, SCKV_COUNT + 1):
		if not existing.has(i):
			ships.append(_build_sckv_ship(i))

func _remove_sckv_for_host(host_name: String) -> void:
	for i in range(ships.size() - 1, -1, -1):
		var ship = ships[i]
		if not _is_sckv(ship):
			continue
		if String(ship.get(SCKV_HOST_KEY, "")) != host_name:
			continue
		ships.remove_at(i)

func set_in_battle(enabled: bool) -> void:
	if in_battle == enabled:
		return
	in_battle = enabled
	if in_battle:
		set_range_value(5)
	save_data()
	emit_signal("battle_state_changed", in_battle)

func set_range_value(value: int) -> void:
	var clamped = clamp(value, 0, 5)
	if range_value == clamped:
		return
	range_value = clamped
	emit_signal("range_changed", range_value)
	save_data()

func get_range_value() -> int:
	return range_value

const SAVE_PATH = "user://battlegroup_save.json"

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
		"system":      "0",
		"wing":        "0",
	},
	"name":     "FLAGSHIP",
	"points":   "",
	"tags":     "",
	"tenacity": "",
	"type":     6.0,
}

# 1️⃣ максимумы
const MAX_COUNTS := {
	ShipClass.FRIGATE:    3,
	ShipClass.CARRIER:    2,
	ShipClass.BATTLESHIP: 1,
}

const SHIP_CLASS_ORDER := [
	ShipClass.BATTLESHIP,
	ShipClass.CARRIER,
	ShipClass.FRIGATE,
]

# 2️⃣ текущее количество взятых корпусов
var class_counts := {
	ShipClass.FRIGATE:    0,
	ShipClass.CARRIER:    0,
	ShipClass.BATTLESHIP: 0,
}

var current_ship = -1

var ships: Array = []

func _sort_ships_by_class() -> void:
	if ships.size() <= 1:
		return
	var current_ref: Dictionary = {}
	if current_ship >= 0 and current_ship < ships.size():
		current_ref = ships[current_ship]
	var ordered: Array = []
	for cls in SHIP_CLASS_ORDER:
		for s in ships:
			if _is_sckv(s):
				continue
			if int(s.get("class", -1)) == cls:
				ordered.append(s)
	for s in ships:
		if _is_sckv(s):
			continue
		var cls := int(s.get("class", -1))
		if not SHIP_CLASS_ORDER.has(cls):
			ordered.append(s)
	for s in ships:
		if _is_sckv(s):
			ordered.append(s)
	ships = ordered
	if current_ref.is_empty():
		if current_ship >= ships.size():
			current_ship = -1
	else:
		current_ship = ships.find(current_ref)

func _first_real_ship_index() -> int:
	for i in range(ships.size()):
		if not _is_sckv(ships[i]):
			return i
	return -1

var comander: Dictionary = {
	"name": "",
	"positive_1": "",
	"positive_2": "",
	"positive_3": "",
	"negative": "",
	"negative_2": "",
	"positive_1_check": false,
	"positive_2_check": false,
	"positive_3_check": false,
	"negative_check": false,
	"negative_2_check": false,
	"backstory": "Очень большая предыстория...",
	"commendations": [],
	"reputations": [],
	"reputation_advances": []
}
	
	


# Добавление.  ➜ true — успех, false — отказ (лимит/неизвестный класс/уже есть).
func add_hull(hull: Dictionary) -> bool:
	var cls := int(hull.get("class", -1))
	var was_empty := ships.is_empty()
	if class_counts[cls] >= MAX_COUNTS[cls] or point + int(hull.get("points")) > 20:
		return false

	# 🔑 создаём глубокую копию, чтобы объект был уникален
	var new_hull := hull.duplicate(true)   # true → deep copy

	# 1. находим первый свободный номер
	var used := {}
	for s in ships:
		var parts := str(s.get("ship_name", "")).split(" ")
		if parts.size() == 2 and parts[0] == "Имя":
			used[int(parts[1])] = true
	var idx := 1
	while used.has(idx):
		idx += 1

	# 2. заполняем поля нового корпуса
	new_hull["ship_name"] = "Имя %d" % idx
	new_hull["option"]    = []
	new_hull["legacies"]  = []
	new_hull["flagman"]   = false
	new_hull["note"]      = ""
	if new_hull.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER", "IPS-N\nMINOKAWA-CLASS FRIGATE"]:
		new_hull["special"]    = []


	# 3. кладём уже *уникальный* словарь в массив
	ships.append(new_hull)
	class_counts[cls] += 1
	if String(new_hull.get("name", "")) == HESPERIS_HULL_NAME:
		_ensure_hesperis_sckv()
	_sort_ships_by_class()
	if was_empty:
		ensure_flagship()
	else:
		refresh_point()
		emit_signal("battlegroup_change")
	return true

# Удаление.  ➜ true — удалил, false — не нашёл.
func remove_hull(hull: Dictionary) -> bool:
	var target_name = hull.get("name", "")
	var idx := -1

	# идём с конца в начало
	for i in range(ships.size() - 1, -1, -1):
		if ships[i].get("name", "") == target_name:
			idx = i
			break
	
	if idx == -1:
		return false        # корпус с таким name не найден

	# определяем класс удаляемого корпуса, чтобы корректно уменьшить счётчики
	var removed_was_flagman := bool(ships[idx].get("flagman", false))
	var cls := int(ships[idx].get("class", -1))
	var removed_name := String(ships[idx].get("name", ""))

	ships.remove_at(idx)
	class_counts[cls] = max(class_counts[cls] - 1, 0)
	if removed_name == HESPERIS_HULL_NAME:
		_remove_sckv_for_host(HESPERIS_HULL_NAME)
	if removed_was_flagman and not ships.is_empty():
		ensure_flagship()
	else:
		refresh_point()
		emit_signal("battlegroup_change")
	return true

# Сколько корпусов этого класса уже взяли
func get_hull_count(cls: int) -> int:
	return class_counts.get(cls, 0)

# Доступен ли ещё хотя бы один корпус данного класса
func can_add(cls: int) -> bool:
	return class_counts[cls] < MAX_COUNTS[cls]

func get_flagship_index() -> int:
	for i in range(ships.size()):
		if bool(ships[i].get("flagman", false)):
			return i
	return -1

func set_flagship(index: int) -> void:
	if index < 0 or index >= ships.size():
		return
	if _is_sckv(ships[index]):
		return
	var changed := false
	for i in range(ships.size()):
		var ship: Dictionary = ships[i]
		var want_flag := i == index
		var is_flag := bool(ship.get("flagman", false))

		if want_flag:
			if not is_flag:
				ship["flagman"] = true
				changed = true
			if _find_flagship_option_idx(ship) == -1:
				var opts: Array = ship.get("option", [])
				if opts == null or not (opts is Array):
					opts = []
				opts.append(FLAGSHIP_OPTION.duplicate(true))
				ship["option"] = opts
				_apply_flagship_bonus(ship, true)
				changed = true
		else:
			if is_flag:
				ship["flagman"] = false
				changed = true
			var idx := _find_flagship_option_idx(ship)
			if idx != -1:
				ship.get("option", []).remove_at(idx)
				_apply_flagship_bonus(ship, false)
				changed = true

	if changed:
		refresh_point()
		emit_signal("battlegroup_change")
		emit_signal("flagship_changed", index)

func ensure_flagship() -> void:
	if ships.is_empty():
		return
	var idx := get_flagship_index()
	if idx == -1:
		var first_real := _first_real_ship_index()
		if first_real != -1:
			set_flagship(first_real)
	else:
		if _is_sckv(ships[idx]):
			var first_real := _first_real_ship_index()
			if first_real != -1:
				set_flagship(first_real)
		else:
			set_flagship(idx)

func _find_flagship_option_idx(ship: Dictionary) -> int:
	var opts: Array = ship.get("option", [])
	for i in range(opts.size() - 1, -1, -1):
		if String(opts[i].get("name", "")) == "FLAGSHIP":
			return i
	return -1

func _apply_flagship_bonus(ship: Dictionary, enabled: bool) -> void:
	var delta := 1 if enabled else -1
	var ss = ship.get("support_slots", {})
	var systems := _to_int(ss.get("systems", 0)) + delta
	ss["systems"] = str(max(systems, 0))
	ship["support_slots"] = ss

	var hp := _to_int(ship.get("hp", 0)) + (3 * delta)
	ship["hp"] = str(max(hp, 1))

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
			if s.is_valid_int():
				return s.to_int()
			if s.is_valid_float():
				return int(round(s.to_float()))
			return 0
		_:
			return 0

func refresh_point():
	point = 0
	for ship in ships:
		if _is_sckv(ship):
			continue
		var total := int(ship.get("points", 0))
		var spec = 0
		for opt in ship.get("option", []):
			if ship.get("class") == 1.0 and (opt.get("type") == 5.0 or opt.get("type") == 4.0):
				spec += int(opt.get("points", 0))
				spec += int(opt.get("modification", {}).get("point", 0))
			elif ship.get("name") == "IPS-N\nEILAND-CLASS COMMAND CARRIER" and (opt.get("type") == 5.0):
				spec += int(opt.get("points", 0))
				spec += int(opt.get("modification", {}).get("point", 0))
			elif (opt.get("type") == 0.0) and (ship.get("name") == "HA\nCREIGHTON-CLASS FRIGATE\n(CALIBRATED FIRING PLATFORM)" or ship.get("name") == "HA\nCREIGHTON-CLASS FRIGATE\n(VEGA)"):
				if int(opt.get("points", 0)) == 0.0:
					total += int(opt.get("points", 0))
					total += int(opt.get("modification", {}).get("point", 0))
				else:
					total += int(opt.get("points", 0)) - 1
					total += int(opt.get("modification", {}).get("point", 0))
			else:
				total += int(opt.get("points", 0))
				total += int(opt.get("modification", {}).get("point", 0))
		if spec > 3:
			spec -= 3
		else:
			spec = 0
		if ship.get("name") == "GMS\nAMAZON-CLASS LINE CARRIER":
			if spec > 1:
				spec -= 1
			else:
				spec = 0
		point += total + spec

func will_exceed_20(opt: Dictionary) -> bool:
	var total_points := 0
	
	for i in range(ships.size()):
		var ship = ships[i]
		if _is_sckv(ship):
			continue
		var ship_total := 0
		var spec := 0
		
		# Собираем список опций для подсчёта.
		# Для целевого корабля добавляем "виртуально" новую опцию.
		var opts: Array = ship.get("option", []).duplicate()
		if i == current_ship and opt != null:
			opts.append(opt)
		
		# Подсчёт очков по правилам
		for o in opts:
			var o_points := int(o.get("points", 0))
			var o_type = o.get("type")
			var s_class = ship.get("class")
			var s_name := String(ship.get("name", ""))
			
			if s_class == 1.0 and (o_type == 5.0 or o_type == 4.0):
				spec += o_points
			elif s_name == "IPS-N\nEILAND-CLASS COMMAND CARRIER" and (o_type == 5.0):
				spec += o_points
			elif (o_type == 0.0) and (s_name == "HA\nCREIGHTON-CLASS FRIGATE\n(CALIBRATED FIRING PLATFORM)" or s_name == "HA\nCREIGHTON-CLASS FRIGATE\n(VEGA)"):
				if o_points == 0:
					ship_total += o_points 
				else:
					ship_total += (o_points - 1)
			else:
				ship_total += o_points 
		
		# Порог для спец-очков
		if spec > 3:
			spec -= 3
		else:
			spec = 0
		
		# Исключение для AMAZON
		if String(ship.get("name","")) == "GMS\nAMAZON-CLASS LINE CARRIER":
			if spec > 1:
				spec -= 1
			else:
				spec = 0
		
		total_points += ship_total + spec + int(ship.get("points"))
	
	return total_points > 20

func change_on_option():
	emit_signal("option_change")

func request_option_list():
	emit_signal("option_list_requested")

func change_on_legacies():
	emit_signal("legacies_change")

func change_on_commendations():
	emit_signal("commendations_change")

func change_on_reputations():
	emit_signal("reputations_change")

func change_on_reputation_advances():
	emit_signal("reputation_advances_change")

func _get_current_ship_ref() -> Dictionary:
	if current_ship < 0 or current_ship >= ships.size():
		return {}
	return ships[current_ship]

func _ensure_ship_legacies(ship: Dictionary) -> Array:
	var arr = ship.get("legacies", [])
	if arr == null or not (arr is Array):
		arr = []
	ship["legacies"] = arr
	return arr

func has_legacy(legacy: Dictionary) -> bool:
	var ship = _get_current_ship_ref()
	if ship.is_empty():
		return false

	var arr = _ensure_ship_legacies(ship)
	var name = String(legacy.get("name", ""))
	for l in arr:
		if String(l.get("name", "")) == name:
			return true
	return false

func can_add_legacy(legacy: Dictionary) -> bool:
	var ship = _get_current_ship_ref()
	if ship.is_empty():
		return false
	var arr = _ensure_ship_legacies(ship)
	if arr.size() >= 2:
		return false
	var name = String(legacy.get("name", ""))
	for l in arr:
		if String(l.get("name", "")) == name:
			return false
	return true

func add_legacy_to_current(legacy: Dictionary) -> bool:
	var ship = _get_current_ship_ref()
	if ship.is_empty():
		return false
	var arr = _ensure_ship_legacies(ship)
	if arr.size() >= 2:
		return false
	var name = String(legacy.get("name", ""))
	for l in arr:
		if String(l.get("name", "")) == name:
			return false
	arr.append(legacy.duplicate(true))
	ship["legacies"] = arr
	option_change.emit()
	return true

func remove_legacy_from_current(legacy: Dictionary) -> bool:
	var ship = _get_current_ship_ref()
	if ship.is_empty():
		return false
	var arr = _ensure_ship_legacies(ship)
	var name = String(legacy.get("name", ""))
	for i in range(arr.size() - 1, -1, -1):
		if String(arr[i].get("name", "")) == name:
			arr.remove_at(i)
			ship["legacies"] = arr
			option_change.emit()
			return true
	return false

func _ensure_commander_list(key: String) -> Array:
	var arr = comander.get(key, [])
	if arr == null or not (arr is Array):
		arr = []
	comander[key] = arr
	return arr

func _commander_has(key: String, name: String) -> bool:
	var arr = _ensure_commander_list(key)
	for item in arr:
		if String(item.get("name", "")) == name:
			return true
	return false

func add_commendation(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	if _commander_has("commendations", name):
		return false
	var arr = _ensure_commander_list("commendations")
	var entry := item.duplicate(true)
	if name == AZURE_STAR_NAME:
		entry[AZURE_STAR_USE_KEY] = false
	arr.append(entry)
	comander["commendations"] = arr
	emit_signal("battlegroup_change")
	return true

func remove_commendation(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	var arr = _ensure_commander_list("commendations")
	for i in range(arr.size() - 1, -1, -1):
		if String(arr[i].get("name", "")) == name:
			arr.remove_at(i)
			comander["commendations"] = arr
			emit_signal("battlegroup_change")
			return true
	return false

func has_commendation(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	return _commander_has("commendations", name)

func add_reputation(item: Dictionary) -> bool:
	if comander.get("reputations", []).size() > 0:
		return false
	var name = String(item.get("name", ""))
	if _commander_has("reputations", name):
		return false
	var arr = _ensure_commander_list("reputations")
	arr.append(item.duplicate(true))
	comander["reputations"] = arr
	comander["reputation_advances"] = []
	emit_signal("battlegroup_change")
	return true

func remove_reputation(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	var arr = _ensure_commander_list("reputations")
	for i in range(arr.size() - 1, -1, -1):
		if String(arr[i].get("name", "")) == name:
			arr.remove_at(i)
			comander["reputations"] = arr
			comander["reputation_advances"] = []
			emit_signal("battlegroup_change")
			return true
	return false

func has_reputation(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	return _commander_has("reputations", name)

func add_reputation_advance(item: Dictionary) -> bool:
	if comander.get("reputations", []).is_empty():
		return false
	var name = String(item.get("name", ""))
	if _commander_has("reputation_advances", name):
		return false
	var arr = _ensure_commander_list("reputation_advances")
	arr.append(item.duplicate(true))
	comander["reputation_advances"] = arr
	emit_signal("battlegroup_change")
	return true

func remove_reputation_advance(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	var arr = _ensure_commander_list("reputation_advances")
	for i in range(arr.size() - 1, -1, -1):
		if String(arr[i].get("name", "")) == name:
			arr.remove_at(i)
			comander["reputation_advances"] = arr
			emit_signal("battlegroup_change")
			return true
	return false

func has_reputation_advance(item: Dictionary) -> bool:
	var name = String(item.get("name", ""))
	return _commander_has("reputation_advances", name)

func _enter_tree() -> void:
	battlegroup_change.connect(save_data)
	option_change.connect(save_data)
	load_data()

func save_data() -> void:
	var data = {
		"ships": ships,
		"comander": comander,
		"battlegroup_note": battlegroup_note,
		"in_battle": in_battle,
		"range_value": range_value
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var result = JSON.parse_string(text)
			if typeof(result) == TYPE_DICTIONARY:
				ships = result.get("ships", [])
				comander = result.get("comander", comander)
				battlegroup_note = String(result.get("battlegroup_note", battlegroup_note))
				var loaded_in_battle = result.get("in_battle", in_battle)
				if typeof(loaded_in_battle) == TYPE_BOOL:
					in_battle = loaded_in_battle
				elif typeof(loaded_in_battle) == TYPE_STRING:
					var lowered = String(loaded_in_battle).strip_edges().to_lower()
					in_battle = lowered == "true" or lowered == "1"
				else:
					in_battle = bool(loaded_in_battle)
				range_value = clamp(_to_int(result.get("range_value", range_value)), 0, 5)
				if not comander.has("commendations"):
					comander["commendations"] = []
				if not comander.has("reputations"):
					comander["reputations"] = []
				if not comander.has("reputation_advances"):
					comander["reputation_advances"] = []
				if not comander.has("positive_3"):
					comander["positive_3"] = ""
				if not comander.has("negative_2"):
					comander["negative_2"] = ""
				if not comander.has("positive_3_check"):
					comander["positive_3_check"] = false
				if not comander.has("negative_2_check"):
					comander["negative_2_check"] = false
				class_counts[ShipClass.FRIGATE] = 0
				class_counts[ShipClass.CARRIER] = 0
				class_counts[ShipClass.BATTLESHIP] = 0
				for s in ships:
					if _is_sckv(s):
						continue
					if not s.has("legacies"):
						s["legacies"] = []
					if not s.has("flagman"):
						s["flagman"] = false
					if not s.has("note"):
						s["note"] = ""
					var cls = int(s.get("class", -1))
					if class_counts.has(cls):
						class_counts[cls] = class_counts[cls] + 1
				_ensure_hesperis_sckv()
				_sort_ships_by_class()
				refresh_point()
				ensure_flagship()

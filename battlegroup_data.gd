extends Node    # BattlegroupData

enum ShipClass { FRIGATE, CARRIER, BATTLESHIP }

signal battlegroup_change
signal option_change

var point = 0

const SAVE_PATH = "user://battlegroup_save.json"

# 1️⃣ максимумы
const MAX_COUNTS := {
	ShipClass.FRIGATE:    3,
	ShipClass.CARRIER:    2,
	ShipClass.BATTLESHIP: 1,
}

# 2️⃣ текущее количество взятых корпусов
var class_counts := {
	ShipClass.FRIGATE:    0,
	ShipClass.CARRIER:    0,
	ShipClass.BATTLESHIP: 0,
}

var current_ship = -1

var ships: Array = []

var comander: Dictionary = {
	"name": "",
	"positive_1": "",
	"positive_2": "",
	"negative": "",
	"positive_1_check": false,
	"positive_2_check": false,
	"negative_check": false,
	"backstory": "Очень большая предыстория..."
}
	
	


# Добавление.  ➜ true — успех, false — отказ (лимит/неизвестный класс/уже есть).
func add_hull(hull: Dictionary) -> bool:
	var cls := int(hull.get("class", -1))
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
	if new_hull.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER", "IPS-N\nMINOKAWA-CLASS FRIGATE"]:
		new_hull["special"]    = []


	# 3. кладём уже *уникальный* словарь в массив
	ships.append(new_hull)
	class_counts[cls] += 1
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
	var cls := int(ships[idx].get("class", -1))

	ships.remove_at(idx)
	class_counts[cls] = max(class_counts[cls] - 1, 0)
	refresh_point()
	emit_signal("battlegroup_change")
	return true

# Сколько корпусов этого класса уже взяли
func get_hull_count(cls: int) -> int:
	return class_counts.get(cls, 0)

# Доступен ли ещё хотя бы один корпус данного класса
func can_add(cls: int) -> bool:
	return class_counts[cls] < MAX_COUNTS[cls]


func refresh_point():
	point = 0
	for ship in ships:
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
			var o_mod_points := int(o.get("modification", {}).get("point", 0))
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

func _enter_tree() -> void:
	battlegroup_change.connect(save_data)
	option_change.connect(save_data)
	load_data()

func save_data() -> void:
	var data = {
		"ships": ships,
		"comander": comander
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
				class_counts[ShipClass.FRIGATE] = 0
				class_counts[ShipClass.CARRIER] = 0
				class_counts[ShipClass.BATTLESHIP] = 0
				for s in ships:
					var cls = int(s.get("class", -1))
					if class_counts.has(cls):
						class_counts[cls] = class_counts[cls] + 1
				refresh_point()

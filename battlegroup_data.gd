extends Node    # BattlegroupData

enum ShipClass { FRIGATE, CARRIER, BATTLESHIP }

signal battlegroup_change
signal option_change

var point = 0

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

var ships: Array = []     # хранит сами словари-корпуса

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
	new_hull["flagman"]   = false

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
				for opt in ship.get("option", []):
						total += int(opt.get("points", 0))
						total += int(opt.get("modification", {}).get("point", 0))
				point += total


func change_on_option():
	emit_signal("option_change")

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

var ships: Array = [{ "class": 2.0, "defense": "12", "discription": "Murie — это стандартный проект линкора GMS, представляющий собой сбалансированный корпус, вооружённый и оснащённый для работы в различных сценариях, на разных театрах военных действий и в рамках различных доктрин. Хотя чаще всего он используется Флотом Союза как тяжёлый корабль линии, Murie можно встретить практически в каждом крупном военноморском флоте (и во многих малых), включая Арсенал Харрисона и Торговые Баронии Карракина. Служба на Murie является значимым назначением, которым любой командир может гордиться, так как у этого линкора богатая история и длинный список знаменитых имён в родословной. Многими считается иконой в мире линкоров, и он часто появляется во множестве драм и игр омнинета.", "feats": [{ "damage": "", "discription": "", "effect": "1/раунд ты можешь добавить +1 к Точности к любому броску, совершённому тобой или союзной боевой группой в той же Дистанционной полосе. 1/столкновение ты можешь вместо этого добавить +3 к Точности.", "name": "PARAGON", "range": "", "tags": "", "type": 0.0 }], "hp": "25", "name": "GMS\nMURIE-CLASS BATTLESHIP", "points": "6", "support_slots": { "escorts": "0", "systems": "1", "wings": "0" }, "weapon_slots": { "auxiliaries": "2", "primaries": "1", "superheavy": "1" }, "ship_name": "Имя 1", "option": [{ "damage": "12", "discription": "Галактический стандарт вооружения для любого тяжёлого линейного корабля, LCPL включает в себя широкий спектр орудий направленной энергии и пучков частиц, все из которых имеют один исход: немедленное и полное уничтожение врага при точном попадании.\nБлагодаря сбалансированному времени заряда и высокой мощности LCPL является надёжным основным орудием для любого корабля, который может его установить.", "effect": "", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "-1", "system": "0", "wing": "0" }, "name": "LONG-CYCLE PRIMARY LANCE", "points": "0", "range": "4-0", "tags": "По одной цели, Заряжаемое 3, Критическое, Надёжное 3", "tenacity": "", "type": 0.0 }, { "damage": "1d3+5", "discription": "Старые, надёжные и доведённые до совершенства системы, CONICAL KINETIC PROJECTORS — это простое оружие для ближнего боя. Морской эквивалент дробовика, CKP выпускают облака микропроектилей с регулируемым разлётом, предназначенные для покрытия площадей, а не для прицеливания в конкретные точки.\nНа скорости «убийственные облака», выпускаемые CKP, могут разнести неосторожные корабли. Несмотря на свою разрушительность, эти орудия быстро теряют эффективность на дистанции, вынуждая командиров рисковать и сближаться до опасных расстояний, чтобы использовать их на полную мощность.", "effect": "Атаки с этим орудием на дальности больше чем 1 получают +1 Сложности.", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "-1", "superheavy": "0", "system": "0", "wing": "0" }, "name": "CONICAL KINETIC PROJECTORS", "points": "0", "range": "2–0", "tags": "По одной цели, Критическое", "tenacity": "", "type": 1.0 }, { "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "discription": "Доктрина боя вашей боевой группы делает акцент на агрессивном движении, сокращении дистанций и прокладывании курсов, которых избегали бы более осторожные командиры.\nЭтот импульс не обходится без жертв, часто требуя обмена оборонительными позициями и предсказуемостью на шанс навязать бой врагу напрямую.", "effect": "Все атаки по одной цели, совершаемые вами и против вас на дистанции 2–0, получают +1 Точности.\nДополнительно, 1/столкновение, вы можете выбрать одно:\n\n• Когда враждебный эффект или способность вынуждает вашу боевую группу продвинуться вперёд на любое количество дистанционных полос, один из ваших КАПИТАЛЬНЫХ КОРАБЛЕЙ получает 5 Сверхщита.\n• Когда враждебный эффект или способность вынуждает союзную боевую группу продвинуться вперёд на любое количество дистанционных полос, вместо этого перемещается ваша боевая группа. Если это предотвращает возможность враждебного корабля атаковать союзную боевую группу или применять к ней способность в рамках того же действия, он может вместо этого выбрать вас в качестве цели.", "feats": [], "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "-1", "wing": "0" }, "name": "AGGRESSIVE COMMANDERS", "points": "0", "tags": "Уникальное", "tenacity": "", "type": 3.0 }], "flagman": false }, { "class": 1.0, "defense": "14", "discription": "Современные доктрины признают две различные роли авианосцев в сражении флотов: запуск ударных кораблей и поддержка сублинейных кораблей. Сублинейные корабли, то есть корабли, меньшие так называемых «кораблей линии», как правило, требуют дополнительной логистической поддержки для поддержания эффективной боеготовности. Авианосецы, построенные для поддержки эскадрилий боевых сублинейных кораблей низкого и среднего тоннажа, делают это не обязательно размещая их в ангарах, но доставляя их и их экипажи в зоны развертывания, а затем обеспечивая тактическую координацию и базу для пополнения боезапаса и снабжения после начала столкновения. Линейный авианосец класса Tongass является основным кораблём поддержки сублинейных кораблей Союза, и его специальные стыковочные узлы (дорсальные и вентральные) и оптимизированные логистические комплексы позволяют ему поддерживать свои эскорты в миссиях огневой поддержки без необходимости возвращения на верфи второго или третьего эшелона.", "feats": [{ "damage": "", "discription": "", "effect": "Союзные боевые группы в твоей Дистанционной полосе могут использовать тактики, предоставляемые Эскортами этого корабля, как если бы они находились под их управлением.", "name": "CLOSE SUPPORT", "range": "", "tags": "", "type": 0.0 }], "hp": "17", "name": "GMS\nTONGASS-CLASS LINE CARRIER", "points": "4", "support_slots": { "escorts": "2", "systems": "1", "wings": "0" }, "weapon_slots": { "auxiliaries": "2", "primaries": "0", "superheavy": "0" }, "ship_name": "Имя 2", "option": [{ "discription": "Дизайн морских абордажных судов мало изменился за последние 100 лет флотовых войн. Минимально вооружённые и умеренно бронированные, построенные для скорости и вместимости, эти суда созданы исключительно для того, чтобы сблизиться с вражескими кораблями и пробить их внешнюю обшивку, позволяя своим пассажирам начать опасную задачу проведения абордажных операций. У ветеранов-морпехов есть множество красочных прозвищ для этих судов, и немногие из них подходят для приличной компании.", "effect": "", "feats": [], "hp": "", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "-1", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "MARINE LANDERS", "points": "0", "range": "3–0", "tags": "Абордаж", "tenacity": "10", "type": 5.0 }, { "discription": "Дизайн морских абордажных судов мало изменился за последние 100 лет флотовых войн. Минимально вооружённые и умеренно бронированные, построенные для скорости и вместимости, эти суда созданы исключительно для того, чтобы сблизиться с вражескими кораблями и пробить их внешнюю обшивку, позволяя своим пассажирам начать опасную задачу проведения абордажных операций. У ветеранов-морпехов есть множество красочных прозвищ для этих судов, и немногие из них подходят для приличной компании.", "effect": "", "feats": [], "hp": "", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "-1", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "MARINE LANDERS", "points": "0", "range": "3–0", "tags": "Абордаж", "tenacity": "10", "type": 5.0 }, { "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "description": "", "effect": "", "feats": [], "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLAGSHIP", "points": "0", "tags": "Уникальное", "tenacity": "0", "type": 6.0 }], "flagman": true }, { "class": 1.0, "defense": "14", "discription": "Современные доктрины признают две различные роли авианосцев в сражении флотов: запуск ударных кораблей и поддержка сублинейных кораблей. Сублинейные корабли, то есть корабли, меньшие так называемых «кораблей линии», как правило, требуют дополнительной логистической поддержки для поддержания эффективной боеготовности. Авианосецы, построенные для поддержки эскадрилий боевых сублинейных кораблей низкого и среднего тоннажа, делают это не обязательно размещая их в ангарах, но доставляя их и их экипажи в зоны развертывания, а затем обеспечивая тактическую координацию и базу для пополнения боезапаса и снабжения после начала столкновения. Линейный авианосец класса Tongass является основным кораблём поддержки сублинейных кораблей Союза, и его специальные стыковочные узлы (дорсальные и вентральные) и оптимизированные логистические комплексы позволяют ему поддерживать свои эскорты в миссиях огневой поддержки без необходимости возвращения на верфи второго или третьего эшелона.", "feats": [{ "damage": "", "discription": "", "effect": "Союзные боевые группы в твоей Дистанционной полосе могут использовать тактики, предоставляемые Эскортами этого корабля, как если бы они находились под их управлением.", "name": "CLOSE SUPPORT", "range": "", "tags": "", "type": 0.0 }], "hp": "14", "name": "GMS\nTONGASS-CLASS LINE CARRIER", "points": "4", "support_slots": { "escorts": "2", "systems": "0", "wings": "0" }, "weapon_slots": { "auxiliaries": "2", "primaries": "0", "superheavy": "0" }, "ship_name": "Имя 3", "option": [{ "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "damage": "", "discription": "Под большими орудиями любого линейного корабля находятся вспомогательные системы вооружения, задачей которых является управление угрозами, которые капитану стоит воспринимать всерьёз: вражескими ударными кораблями.", "effect": "Когда используется вместе с любым ОСНОВНЫМ орудием, это орудие наносит 2 урона двум КРЫЛЬЯМ в боевой группе цели.", "modification": { "HP": "0", "auxiliary": "-1", "defence": "0", "escort": "0", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "FLYSWATTER MISSILES", "points": "0", "range": "3-0", "tags": "", "tenacity": "", "type": 2.0 }, { "discription": "Дизайн морских абордажных судов мало изменился за последние 100 лет флотовых войн. Минимально вооружённые и умеренно бронированные, построенные для скорости и вместимости, эти суда созданы исключительно для того, чтобы сблизиться с вражескими кораблями и пробить их внешнюю обшивку, позволяя своим пассажирам начать опасную задачу проведения абордажных операций. У ветеранов-морпехов есть множество красочных прозвищ для этих судов, и немногие из них подходят для приличной компании.", "effect": "", "feats": [], "hp": "", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "-1", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "MARINE LANDERS", "points": "0", "range": "3–0", "tags": "Абордаж", "tenacity": "10", "type": 5.0 }, { "discription": "Дизайн морских абордажных судов мало изменился за последние 100 лет флотовых войн. Минимально вооружённые и умеренно бронированные, построенные для скорости и вместимости, эти суда созданы исключительно для того, чтобы сблизиться с вражескими кораблями и пробить их внешнюю обшивку, позволяя своим пассажирам начать опасную задачу проведения абордажных операций. У ветеранов-морпехов есть множество красочных прозвищ для этих судов, и немногие из них подходят для приличной компании.", "effect": "", "feats": [], "hp": "", "modification": { "HP": "0", "auxiliary": "0", "defence": "0", "escort": "-1", "interdiction": "0", "point": "0", "primary": "0", "superheavy": "0", "system": "0", "wing": "0" }, "name": "MARINE LANDERS", "points": "0", "range": "3–0", "tags": "Абордаж", "tenacity": "10", "type": 5.0 }] }]
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
				emit_signal("battlegroup_change")
				emit_signal("option_change")

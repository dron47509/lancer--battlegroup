extends PanelContainer

const SlotUtils = preload("res://slot_utils.gd")
const Opt = preload("res://option_types.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _description: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _add: MarginContainer = $VBoxContainer/Button
@onready var _remove: MarginContainer = $VBoxContainer/Button2
@onready var _add_special:    MarginContainer = $VBoxContainer/Button3
@onready var _remove_special: MarginContainer = $VBoxContainer/Button4
var _src: Dictionary

func _process(delta: float) -> void:
		_update_buttons()

func _update_buttons() -> void:
	if _src.size() != 0 and BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		if BattlegroupData.ships[BattlegroupData.current_ship]["option"].size() != 0:
			_add.show()
			var sum = SlotUtils.get_slot_sums(ship)
			if _src["type"] == Opt.Weapon.SUPERHEAVY and sum["superheavy"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Weapon.PRIMARY and sum["primary"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Weapon.AUXILIARY and sum["auxiliary"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src) or super_condition():
				_add.hide()

			# УНИКАЛЬНОЕ
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()

			if _src in ship["option"]:
				_remove.show()
			else:
				_remove.hide()

			# ----- SPECIAL UI (только для вспомогательных орудий) -----
			var special_arr = ship.get("special", [])
			var in_special = false
			for o in special_arr:
				if _is_same_template(o):
					in_special = true
					break

			# Кнопка добавления special показывается только для AUXILIARY
			if ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and  _src.get("type") == Opt.Weapon.AUXILIARY and special_arr.size() < 1 and not in_special:
				_add_special.show()
			else:
				_add_special.hide()

			# Кнопка удаления special — если именно это орудие уже в special
			if in_special:
				_remove_special.show()
			else:
				_remove_special.hide()

		else:
			var sum = SlotUtils.get_slot_sums(ship)
			if _src["type"] == Opt.Weapon.SUPERHEAVY and sum["superheavy"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Weapon.PRIMARY and sum["primary"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Weapon.AUXILIARY and sum["auxiliary"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src) or super_condition():
				_add.hide()
			else:
				_add.show()

			# УНИКАЛЬНОЕ (и при пустых опциях)
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()

			_remove.hide()

			# ----- SPECIAL UI (только для вспомогательных орудий) -----
			var special_arr2 = ship.get("special", [])
			var in_special2 = false
			for o in special_arr2:
				if _is_same_template(o):
					in_special2 = true
					break

			if ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and _src.get("type") == Opt.Weapon.AUXILIARY and special_arr2.size() < 1 and not in_special2:
				_add_special.show()
			else:
				_add_special.hide()

			if in_special2:
				_remove_special.show()
			else:
				_remove_special.hide()

	else:
		if BattlegroupData.will_exceed_20(_src) or super_condition():
			_add.hide()
		else:
			_add.show()

		if _has_unique_tag(_src) and _is_unique_taken():
			_add.hide()

		_remove.hide()
		_add_special.hide()
		_remove_special.hide()


func _has_unique_tag(opt: Dictionary) -> bool:
		for t in opt.get("tags", "").split(",", false):
				if t.strip_edges().to_lower() == "уникальное":
						return true
		return false

func _is_unique_taken() -> bool:
		for s in BattlegroupData.ships:
				for o in s.get("option", []):
						if o.get("name") == _src.get("name"):
								return true
		return false

func _is_same_template(o: Dictionary) -> bool:
		return o.get("name") == _src.get("name")

func _count_added(ship: Dictionary) -> int:
		var n = 0
		for o in ship.get("option", []):
				if _is_same_template(o):
						n += 1
		return n


func populate(weapon):
	_src = weapon.duplicate(true)
	_name.text = weapon.get("name")
	if weapon.get("type") == Opt.Weapon.SUPERHEAVY:
		_tags.text = "Серхтяжелое, " + weapon.get("tags")
	elif weapon.get("type") == Opt.Weapon.PRIMARY:
		_tags.text = "Основное, " + weapon.get("tags")
	elif weapon.get("type") == Opt.Weapon.AUXILIARY:
		_tags.text = "Вспомогательное"
		if weapon.get("tags") != "":
			_tags.text += ", " + weapon.get("tags")
	_param.text = ""
	if weapon.get("range") != "":
		_param.text += "[Дистанция " +  weapon.get("range") + "] "
	if weapon.get("damage") != "":
		_param.text += "[Урон " + weapon.get("damage") + "] "

	if  weapon.get("tenacity") != "":
		_param.text += "[Упорство " + weapon.get("tenacity") + "] "
	_param.text += "[Очки " + str(int(weapon.get("points"))) + "]"
	_effect.text = weapon.get("effect")
	_description.text = "[i]" + weapon.get("discription") + "[/i]"


func _on_add_pressed() -> void:
		var opt = _src.duplicate(true)
		BattlegroupData.ships[BattlegroupData.current_ship]["option"].append(opt)
		BattlegroupData.refresh_point()
		BattlegroupData.option_change.emit()

func _on_remove_pressed() -> void:
		var arr = BattlegroupData.ships[BattlegroupData.current_ship]["option"]
		for i in range(arr.size() - 1, -1, -1):
				if _is_same_template(arr[i]):
						arr.remove_at(i)
						break
		BattlegroupData.refresh_point()
		BattlegroupData.option_change.emit()

func super_condition():
	if BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		var sum = SlotUtils.get_slot_usage(ship)
		if ship.get("name") == "FKS\nCALENDULA-CLASS BATTLECRUISER" and _src.get("type") == Opt.Weapon.SUPERHEAVY:
			if sum["superheavy"] == 0:
				return false
			for x in ship.get("option"):
				if x.get("tags").contains("Заряжаемое"):
					return false
			if _src.get("tags").contains("Заряжаемое"):
				return false
			return true
		if ship.get("name") == "HA\nCREIGHTON-CLASS FRIGATE\n(CALIBRATED FIRING PLATFORM)" or ship.get("name") == "HA\nCREIGHTON-CLASS FRIGATE\n(VEGA)" and _src.get("type") == Opt.Weapon.SUPERHEAVY:
			if _src.get("tags").contains("Заряжаемое"):
				return false
			return true
		if ship.get("name") == "FKS\nTOLUMNIA-CLASS FRIGATE" and _src.get("type") == Opt.Weapon.PRIMARY:
			if _src.get("tags").contains("Боезаряд"):
				return true
			return false
		if ship.get("name") == "IPS-N\nLAHO-CLASS FRIGATE" and _src.get("type") == Opt.Weapon.PRIMARY:
			if _src.get("tags").contains("Боезаряд"):
				return false
			return true
	return false
	
func _on_add_special_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	if not ship.has("special") or ship.get("special") == null:
		ship["special"] = []

	# только вспомогательные
	if _src.get("type") != Opt.Weapon.AUXILIARY:
		return

	# без дублей одного и того же шаблона
	for o in ship["special"]:
		if _is_same_template(o):
			return

	var opt = _src.duplicate(true)
	ship["special"].append(opt)

	# UI обновится через _process/_update_buttons, но подсветим намерение
	_remove_special.show()
	_add_special.hide()

	BattlegroupData.option_change.emit()


func _on_remove_special_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	var arr = ship.get("special", [])
	for i in range(arr.size() - 1, -1, -1):
		if _is_same_template(arr[i]):
			arr.remove_at(i)
			break

	_remove_special.hide()
	# _add_special покажется в _update_buttons при выполнении условий
	BattlegroupData.option_change.emit()

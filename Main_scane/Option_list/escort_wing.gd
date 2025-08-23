extends PanelContainer

const SlotUtils = preload("res://slot_utils.gd")
const Opt = preload("res://option_types.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _description: RichTextLabel = $VBoxContainer/Description/Description
@onready var _tactic1: MarginContainer = $VBoxContainer/Tactic1
@onready var _tactic1_name: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _tactic1_tag: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _tactic1_range: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label3
@onready var _tactic1_effect: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _tactic2: MarginContainer = $VBoxContainer/Tactic2
@onready var _tactic2_name: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _tactic2_tag: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _tactic2_range: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label3
@onready var _tactic2_effect: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _maneuver1: MarginContainer = $VBoxContainer/Maneuver1
@onready var _maneuver1_name: RichTextLabel = $VBoxContainer/Maneuver1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _maneuver1_tag: RichTextLabel = $VBoxContainer/Maneuver1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _maneuver1_effect: RichTextLabel = $VBoxContainer/Maneuver1/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _add: MarginContainer = $VBoxContainer/Button
@onready var _add_special: MarginContainer = $VBoxContainer/Button3
@onready var _remove_special: MarginContainer = $VBoxContainer/Button4
@onready var _remove: MarginContainer = $VBoxContainer/Button2


var _src: Dictionary

func _process(delta: float) -> void:
		_update_buttons()

func _update_buttons() -> void:
	if _src.size() != 0 and BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0 and visible:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		_add.show()
		if BattlegroupData.ships[BattlegroupData.current_ship]["option"].size() != 0:
			var sum = SlotUtils.get_slot_sums(ship)
			if _src["type"] == Opt.Support.ESCORT and sum["escort"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Support.WING and sum["wing"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src):
				_add.hide()

			# УНИКАЛЬНОЕ: запретить добавление, если такая уже стоит где-то в группе
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()

			if _src in ship["option"]:
				_remove.show()
			else:
				_remove.hide()

			# ----- SPECIAL UI (ветка: опции НЕ пустые) -----
			var special_arr = ship.get("special", [])
			var in_special =  false
			for o in special_arr:
				if _is_same_template(o):
					in_special = true
					break

			# показываем add_special только если выполнены условия и ещё нет спец-опции
			if ship.get("name") in ["IPS-N\nMINOKAWA-CLASS FRIGATE"] and _has_boarding_tag(_src) and special_arr.size() < 1 and not in_special:
				_add_special.show()
			elif ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and special_arr.size() < 1 and not in_special:
				_add_special.show()
			else:
				_add_special.hide()

			# remove_special — если именно эта опция уже в special
			if in_special:
				_remove_special.show()
			else:
				_remove_special.hide()

		else:
			var sum = SlotUtils.get_slot_sums(ship)
			if _src["type"] == Opt.Support.ESCORT and sum["escort"] <= 0:
				_add.hide()
			elif _src["type"] == Opt.Support.WING and sum["wing"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src):
				_add.hide()
			else:
				_add.show()

			# УНИКАЛЬНОЕ (даже при пустых опциях текущего корабля)
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()

			_remove.hide()

			# ----- SPECIAL UI (ветка: опции пустые) -----
			var special_arr2 = ship.get("special", [])
			var in_special2 =  false
			for o in special_arr2:
				if _is_same_template(o):
					in_special2 = true
					break

			# тут раньше не было size()<1 — добавил, чтобы поведение совпадало с верхней веткой
			if ship.get("name") in ["IPS-N\nMINOKAWA-CLASS FRIGATE"] and _has_boarding_tag(_src) and special_arr2.size() < 1 and not in_special2:
				_add_special.show()
			elif ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and special_arr2.size() < 1 and not in_special2:
				_add_special.show()
			else:
				_add_special.hide()

			if in_special2:
				_remove_special.show()
			else:
				_remove_special.hide()

	else:
		if int(_src["points"]) + BattlegroupData.point > 20:
			_add.hide()
		else:
			_add.show()

		# УНИКАЛЬНОЕ: правило действует и вне выбранного корабля/видимости
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

func _has_boarding_tag(opt: Dictionary) -> bool:
	for t in opt.get("tags", "").split(",", false):
			if t.strip_edges().to_lower() == "абордаж":
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
		var n =  0
		for o in ship.get("option", []):
				if _is_same_template(o):
						n += 1
		return n

func populate(system):
	_src = system.duplicate(true)
	_name.text = system.get("name")
	if system.get("type") == Opt.Support.ESCORT:
		_tags.text = "Эскорт"
	elif system.get("type") == Opt.Support.WING:
		_tags.text = "Крыло"
	if system.get("tags") != "":
		_tags.text += ", " + system.get("tags")
	_param.text = ""
	if system.get("hp") != "":
		_param.text += "[HP " + system.get("hp") + "] "
	if system.get("tenacity") != "":
		_param.text += "[Упорство " + system.get("tenacity") + "] "
	_param.text += "[Очки " + str(int(system.get("points"))) + "]"
	_effect.text = system.get("effect")
    _description.text = "[i]" + system.get("discription") + "[/i]"
	if system.get("feats").size() > 0:
		var feat1 = system.get("feats").get(0)
		if feat1.get("type") == Opt.FEAT_TACTIC:
			_tactic1.visible = true
			_tactic1_name.text = feat1.get("name")
			_tactic1_tag.text = feat1.get("tags")
			if feat1.get("range") != "":
				_tactic1_range.text = "[Дистанция %s]" % feat1.get("range")
			_tactic1_effect.text = feat1.get("effect")
		else:
                    _maneuver1.visible = true
                    _maneuver1_name.text = feat1.get("name")
                    _maneuver1_tag.text = feat1.get("tags")
                    _maneuver1_effect.text = feat1.get("effect")
	if system.get("feats").size() > 1:
		var feat1 = system.get("feats").get(1)
		if feat1.get("type") == Opt.FEAT_TACTIC:
			_tactic2.visible = true
			_tactic2_name.text = feat1.get("name")
			_tactic2_tag.text = feat1.get("tags")
			if feat1.get("range") != "":
				_tactic2_range.text = "[Дистанция %s]" % feat1.get("range")
			_tactic2_effect.text = feat1.get("effect")
		else:
                    _maneuver1.visible = true
                    _maneuver1_name.text = feat1.get("name")
                    _maneuver1_tag.text = feat1.get("tags")
                    _maneuver1_effect.text = feat1.get("effect")

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


func _on_add_special_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	if not ship.has("special") or ship.get("special") == null:
		ship["special"] = []

	# не добавляем дубликаты одной и той же «спец»-опции
	for o in ship["special"]:
		if _is_same_template(o):
			return

	var opt =  _src.duplicate(true)
	ship["special"].append(opt)

	# Обновляем UI: у тебя _process → _update_buttons() всё равно перерисует,
	# но локально можно подсветить намерение
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
	# Кнопка добавления отобразится по условиям в _update_buttons()
	BattlegroupData.option_change.emit()

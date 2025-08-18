extends PanelContainer

const SlotUtils = preload("res://slot_utils.gd")
const Opt = preload("res://option_types.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _discription: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _tactic1: MarginContainer = $VBoxContainer/Tactic1
@onready var _tactic1_name: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _tactic1_tag: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _range: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label3
@onready var _tactic1_effect: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _tactic2: MarginContainer = $VBoxContainer/Tactic2
@onready var _tactic2_name: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _tactic2_tag: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _tactic2_effect: RichTextLabel = $VBoxContainer/Tactic2/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _maneveue1: MarginContainer = $VBoxContainer/Maneveue1
@onready var _maneveue1_name: RichTextLabel = $VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _maneveue1_tag: RichTextLabel = $VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
@onready var _maneveue1_effect: RichTextLabel = $VBoxContainer/Maneveue1/PanelContainer2/VBoxContainer/MarginContainer/RichTextLabel
@onready var _add: MarginContainer = $VBoxContainer/Button
@onready var _remove: MarginContainer = $VBoxContainer/Button2
@onready var _add_special:    MarginContainer = $VBoxContainer/Button3
@onready var _remove_special: MarginContainer = $VBoxContainer/Button4

var _src: Dictionary


# ───────────────────────────────────────────
# 0) УТИЛИТЫ ДЛЯ МОДИФИКАЦИЙ ОПЦИЙ
# ───────────────────────────────────────────

func _to_int(v) -> int:
	if typeof(v) == TYPE_INT: return v
	return int(str(v))

func _apply_option_side_effects(ship: Dictionary, opt: Dictionary, delta: int) -> void:
	# delta: +1 при установке, -1 при демонтаже
	var name := str(opt.get("name", ""))

	# безопасно достаём вложенные словари
	if not ship.has("support_slots") or ship.get("support_slots") == null:
		ship["support_slots"] = {"wings": "0", "escorts": "0", "systems": ship.get("support_slots", {}).get("systems", "0")}
	if not ship.has("weapon_slots") or ship.get("weapon_slots") == null:
		ship["weapon_slots"] = {"auxiliaries":"0","primaries":"0","superheavy":"0"}

	# 1) FIGHTER LAUNCH CATAPULTS → +1 слот крыльев
	if name == "FIGHTER LAUNCH CATAPULTS":
		var wings := _to_int(ship["support_slots"].get("wings", 0)) + delta
		ship["support_slots"]["wings"] = str(max(wings, 0))

	# 2) SUBLINE BERTH → +1 слот эскортов
	elif name == "SUBLINE BERTH":
		var escorts := _to_int(ship["support_slots"].get("escorts", 0)) + delta
		ship["support_slots"]["escorts"] = str(max(escorts, 0))

	# 3) BULWARK REDUNDANCIES → +3 HP
	elif name == "BULWARK REDUNDANCIES":
		var hp := _to_int(ship.get("hp", 0)) + (3 * delta)
		ship["hp"] = str(max(hp, 0))

	# при изменении конфигурации слотов может влиять на доступность кнопок
	# и подсчёты — дёрнем пересчёт очков/сигнал
	BattlegroupData.refresh_point()
	BattlegroupData.option_change.emit()
	


func _process(delta: float) -> void:
	_update_buttons()

func _update_buttons() -> void:
	if _src.size() != 0 and BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0 and visible:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		_add.show()
		if BattlegroupData.ships[BattlegroupData.current_ship]["option"].size() != 0:
			var sum = SlotUtils.get_slot_sums(ship)
			if sum["system"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src):
				_add.hide()
			if _src in ship["option"]:
				_remove.show()
			else:
				_remove.hide()
			# уникальные
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()
			# запретить дубль BULWARK REDUNDANCIES
			if _src.get("name") == "BULWARK REDUNDANCIES":
				for o in ship["option"]:
					if o.get("name") == "BULWARK REDUNDANCIES":
						_add.hide()
						break

			# SPECIAL блок для Farragut
			var special_arr = ship.get("special", [])
			var in_special := false
			for o in special_arr:
				if _is_same_template(o):
					in_special = true
					break
			if ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and special_arr.size() < 1 and not in_special:
				_add_special.show()
			else:
				_add_special.hide()
			if in_special:
				_remove_special.show()
			else:
				_remove_special.hide()
		else:
			var sum2 = SlotUtils.get_slot_sums(ship)
			if sum2["system"] <= 0:
				_add.hide()
			elif BattlegroupData.will_exceed_20(_src):
				_add.hide()
			else:
				_add.show()
			if _has_unique_tag(_src) and _is_unique_taken():
				_add.hide()
			_remove.hide()

			# SPECIAL блок для Farragut
			var special_arr2 = ship.get("special", [])
			var in_special2 := false
			for o in special_arr2:
				if _is_same_template(o):
					in_special2 = true
					break
			if ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER"] and special_arr2.size() < 1 and not in_special2:
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
	var n := 0
	for o in ship.get("option", []):
		if _is_same_template(o):
			n += 1
	return n


func populate(system):
	_src = system.duplicate(true)
	_name.text = system.get("name")
	_tags.text = "Система"
	if system.get("tags") != "":
		_tags.text += ", " + system.get("tags")
	if system.get("tenacity") != "":
		_param.text = "[Упорство " + system.get("tenacity") + "] "
	_param.text += "[Очки " + str(int(system.get("points"))) + "]"
	_effect.text = system.get("effect")
	_discription.text = "[i]" + system.get("discription") + "[/i]"
	if system.get("feats").size() > 0:
		var feat1 = system.get("feats").get(0)
		if feat1.get("type") == Opt.FEAT_TACTIC:
			_tactic1.visible = true
			_tactic1_name.text = feat1.get("name")
			_tactic1_tag.text = feat1.get("tags")
			if feat1.get("range") != "":
				_range.text = "[Дистанция %s]" % feat1.get("range")
			_tactic1_effect.text = feat1.get("effect")
		else:
			_maneveue1.visible = true
			_maneveue1_name.text = feat1.get("name")
			_maneveue1_tag.text = feat1.get("tags")
			_maneveue1_effect.text = feat1.get("effect")
	if system.get("feats").size() > 1:
		var feat2 = system.get("feats").get(1)
		if feat2.get("type") == Opt.FEAT_TACTIC:
			_tactic2.visible = true
			_tactic2_name.text = feat2.get("name")
			_tactic2_tag.text = feat2.get("tags")
			_tactic2_effect.text = feat2.get("effect")
		else:
			_maneveue1.visible = true
			_maneveue1_name.text = feat2.get("name")
			_maneveue1_tag.text = feat2.get("tags")
			_maneveue1_effect.text = feat2.get("effect")


# ───────────────────────────────────────────
# 1) ДОБАВИТЬ / УДАЛИТЬ в обычные опции
# ───────────────────────────────────────────

func _on_add_pressed() -> void:
	var opt = _src.duplicate(true)
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	ship["option"].append(opt)

	# ← применяем эффекты
	_apply_option_side_effects(ship, opt, +1)

	# Баллы и сигнал уже внутри _apply_option_side_effects,
	# но пусть останется безопасно:
	BattlegroupData.refresh_point()
	BattlegroupData.option_change.emit()


func _on_remove_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	var arr = ship["option"]
	for i in range(arr.size() - 1, -1, -1):
		if _is_same_template(arr[i]):
			# ← снимаем эффекты прямо перед удалением
			_apply_option_side_effects(ship, arr[i], -1)
			arr.remove_at(i)
			break

	BattlegroupData.refresh_point()
	BattlegroupData.option_change.emit()


# ───────────────────────────────────────────
# 2) ДОБАВИТЬ / УДАЛИТЬ в SPECIAL
# ───────────────────────────────────────────

func _on_add_special_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	if not ship.has("special") or ship.get("special") == null:
		ship["special"] = []

	for o in ship["special"]:
		if _is_same_template(o):
			return

	var opt := _src.duplicate(true)
	ship["special"].append(opt)

	# ← эффекты тоже применим (если вдруг эти названия попадут в special)
	_apply_option_side_effects(ship, opt, +1)

	_remove_special.show()
	_add_special.hide()
	BattlegroupData.option_change.emit()


func _on_remove_special_pressed() -> void:
	var ship = BattlegroupData.ships[BattlegroupData.current_ship]
	var arr = ship.get("special", [])
	for i in range(arr.size() - 1, -1, -1):
		if _is_same_template(arr[i]):
			# ← снимаем эффекты
			_apply_option_side_effects(ship, arr[i], -1)
			arr.remove_at(i)
			break

	_remove_special.hide()
	BattlegroupData.option_change.emit()

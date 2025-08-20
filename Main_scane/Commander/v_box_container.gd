extends VBoxContainer
# Godot 4.x

@export var update_interval := 0.2   # как часто пересчитывать (в секундах)
@onready var _label: Label = $Label2

const NAME_FLAGSHIP     := "FLAGSHIP"
const NAME_SANDSTORM    := "SANDSTORM"
const NAME_LOUIS_XIV    := "LOUIS XIV"
const NAME_FIGHTER_WING := "FIGHTER WING"
const TYPE_WING         := 4

var _accum := 0.0
var _last_text := ""
var _last_tooltip := ""

func _ready() -> void:
	set_process(true)
	_recompute(true)

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= update_interval:
		_accum = 0.0
		_recompute()

func _recompute(force: bool = false) -> void:
	var bd = get_node_or_null("/root/BattlegroupData")
	if not bd:
		if _label and (_last_text != "0" or force):
			_last_text = "0"
			_label.text = _last_text
		return

	var ships: Array = bd.ships

	var d6 := 0
	var flat := 0
	var src_count := {
		"FLAGSHIP_d6": 0,
		"LOUIS_XIV_d6": 0,
		"FIGHTER_WING_flat": 0,
		"SANDSTORM_flat": 0,
	}

	for ship in ships:
		var sname := _canon_name(ship.get("name", ""))

		# HA LOUIS XIV–CLASS DREADNOUGHT → +1d6 за каждый
		if sname.find(NAME_LOUIS_XIV) != -1:
			d6 += 1
			src_count["LOUIS_XIV_d6"] += 1

		# Опции/прикреплённые элементы к корпусу
		for opt in ship.get("option", []):
			var oname := _canon_name(opt.get("name", ""))
			var otype := int(opt.get("type", -1))

			# FLAGSHIP как опция
			if oname.find(NAME_FLAGSHIP) != -1:
				d6 += 1
				src_count["FLAGSHIP_d6"] += 1

			# “SANDSTORM” VANGUARD → +2
			if oname.find(NAME_SANDSTORM) != -1:
				flat += 2
				src_count["SANDSTORM_flat"] += 2

			# FIGHTER WING как опция (или по типу)
			if oname.find(NAME_FIGHTER_WING) != -1 or otype == TYPE_WING:
				src_count["FIGHTER_WING_flat"] += 1

		# На случай, если крыло задано как отдельный «корабль»
		if sname.find(NAME_FIGHTER_WING) != -1 or int(ship.get("type", -1)) == TYPE_WING:
			src_count["FIGHTER_WING_flat"] += 1

	# Лимит на FIGHTER WING: максимум +4
	var fw_bonus = src_count["FIGHTER_WING_flat"]
	if fw_bonus > 4:
		fw_bonus = 4
	flat += fw_bonus

	# Собираем текст в стиле 2d6+6
	var text := ""
	if d6 > 0 and flat != 0:
		text = "%dd6%+d" % [d6, flat]
	elif d6 > 0:
		text = "%dd6" % d6
	elif flat != 0:
		text = str(flat)
	else:
		text = "0"

	# Обновляем лейбл только если что-то реально поменялось
	var tooltip := _build_tooltip(src_count, d6, flat)
	if _label and (text != _last_text or tooltip != _last_tooltip or force):
		_last_text = text
		_last_tooltip = tooltip
		_label.text = text
		_label.tooltip_text = tooltip

func _canon_name(raw: String) -> String:
	return raw.replace("\n", " ").to_upper()

func _build_tooltip(src: Dictionary, d6: int, flat: int) -> String:
	var sum_line := ""
	if d6 > 0 and flat != 0:
		sum_line = "%dd6 %+d" % [d6, flat]
	elif d6 > 0:
		sum_line = "%dd6" % d6
	else:
		sum_line = str(flat)

	var lines: Array[String] = []
	lines.append("Итог: %s" % sum_line)
	if int(src["FLAGSHIP_d6"]) > 0:
		lines.append("• FLAGSHIP: +1d6 × %d" % int(src["FLAGSHIP_d6"]))
	if int(src["LOUIS_XIV_d6"]) > 0:
		lines.append("• HA LOUIS XIV–CLASS DREADNOUGHT: +1d6 × %d" % int(src["LOUIS_XIV_d6"]))
	if int(src["FIGHTER_WING_flat"]) > 0:
		lines.append("• FIGHTER WING: +1 × %d (кап 4)" % int(src["FIGHTER_WING_flat"]))
	if int(src["SANDSTORM_flat"]) > 0:
		lines.append("• “SANDSTORM” VANGUARD: +%d" % int(src["SANDSTORM_flat"]))
	return "\n".join(lines)

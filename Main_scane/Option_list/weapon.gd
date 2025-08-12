extends PanelContainer

const OptionTypes = preload("res://option_types.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _discription: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _add: MarginContainer = $VBoxContainer/Button
@onready var _remove: MarginContainer = $VBoxContainer/Button2
var _src: Dictionary    

func _process(delta: float) -> void:
	if _src.size() != 0 and BattlegroupData.curent_ship != -1:
		var ship = BattlegroupData.ships[BattlegroupData.curent_ship]
		if BattlegroupData.ships[BattlegroupData.curent_ship]["option"].size() != 0:
			var sum = {
				"auxiliary": int(ship["weapon_slots"]["auxiliaries"]),
				"escort": int(ship["support_slots"]["escorts"]),
				"primary": int(ship["weapon_slots"]["primaries"]),
				"superheavy": int(ship["weapon_slots"]["superheavy"]),
				"system": int(ship["support_slots"]["systems"]),
				"wing": int(ship["support_slots"]["wings"])
			}
			for x in BattlegroupData.ships[BattlegroupData.curent_ship]["option"]:
				sum["auxiliary"] += int(x["modification"]["auxiliary"])
				sum["escort"] += int(x["modification"]["escort"])
				sum["primary"] += int(x["modification"]["primary"])
				sum["superheavy"] += int(x["modification"]["superheavy"])
				sum["system"] += int(x["modification"]["system"])
				sum["wing"] += int(x["modification"]["wing"])
			if _src["type"] == OptionTypes.WEAPON_SUPERHEAVY and sum["superheavy"] <= 0:
				_add.hide()
			elif _src["type"] == OptionTypes.WEAPON_PRIMARY and sum["primary"] <= 0:
				_add.hide()
			elif _src["type"] == OptionTypes.WEAPON_AUXILIARY and sum["auxiliary"] <= 0:
				_add.hide()
			if _src in ship["option"]:
				_remove.show()
			else:
				_remove.hide()
		else:
			_add.show()
			_remove.hide()
	else:
		_add.show()
		_remove.hide()
		
		
		
func populate(weapon):
	_src = weapon.duplicate(true)
	_name.text = weapon.get("name")
	if weapon.get("type") == OptionTypes.WEAPON_SUPERHEAVY:
		_tags.text = "Серхтяжелое, " + weapon.get("tags")
	elif weapon.get("type") == OptionTypes.WEAPON_PRIMARY:
		_tags.text = "Основное, " + weapon.get("tags")
	elif weapon.get("type") == OptionTypes.WEAPON_AUXILIARY:
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
	_discription.text = "[i]" + weapon.get("discription") + "[/i]"


func _on_add_pressed() -> void:
	BattlegroupData.ships[BattlegroupData.curent_ship]["option"].append(_src)


func _on_remove_pressed() -> void:
	BattlegroupData.ships[BattlegroupData.curent_ship]["option"].erase(_src)

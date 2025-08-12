extends PanelContainer

const SlotUtils = preload("res://slot_utils.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _discription: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _tactic1: MarginContainer = $VBoxContainer/Tactic1
@onready var _tactic1_name: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var _tactic1_tag: RichTextLabel = $VBoxContainer/Tactic1/PanelContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Label2
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

var _src: Dictionary    

func _process(delta: float) -> void:
	if _src.size() != 0 and BattlegroupData.current_ship != -1:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		if BattlegroupData.ships[BattlegroupData.current_ship]["option"].size() != 0:
			var sum = SlotUtils.get_slot_sums(ship)
			if sum["system"] <= 0:
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
	if len(system.get("feats")) > 0:
		var feat1 = system.get("feats").get(0)
		if feat1.get("type") == 2.0:
			_tactic1.visible = true
			_tactic1_name.text = feat1.get("name")
			_tactic1_tag.text = feat1.get("tags")
			_tactic1_effect.text = feat1.get("effect")
		else:
			_maneveue1.visible = true
			_maneveue1_name.text = feat1.get("name")
			_maneveue1_tag.text = feat1.get("tags")
			_maneveue1_effect.text = feat1.get("effect")
	if len(system.get("feats")) > 1:
		var feat1 = system.get("feats").get(1)
		if feat1.get("type") == 2.0:
			_tactic2.visible = true
			_tactic2_name.text = feat1.get("name")
			_tactic2_tag.text = feat1.get("tags")
			_tactic2_effect.text = feat1.get("effect")
		else:
			_maneveue1.visible = true
			_maneveue1_name.text = feat1.get("name")
			_maneveue1_tag.text = feat1.get("tags")
			_maneveue1_effect.text = feat1.get("effect")

func _on_add_pressed() -> void:
	BattlegroupData.ships[BattlegroupData.current_ship]["option"].append(_src)


func _on_remove_pressed() -> void:
	BattlegroupData.ships[BattlegroupData.current_ship]["option"].erase(_src)

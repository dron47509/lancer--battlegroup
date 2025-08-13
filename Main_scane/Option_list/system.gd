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
		_update_buttons()

func _update_buttons() -> void:
	if _src.size() != 0 and BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0 and visible:
		var ship = BattlegroupData.ships[BattlegroupData.current_ship]
		_add.show()
		if BattlegroupData.ships[BattlegroupData.current_ship]["option"].size() != 0:
			var sum = SlotUtils.get_slot_sums(ship)
			if sum["system"] <= 0:
				_add.hide()
			if _src in ship["option"]:
				_remove.show()
			else:
				_remove.hide()
		else:
			if int(_src["points"]) + BattlegroupData.point > 20:
				_add.hide()
			else:
				_add.show()
			_remove.hide()
	else:
		if int(_src["points"]) + BattlegroupData.point > 20:
			_add.hide()
		else:
			_add.show()
		_remove.hide()

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
			_tactic1_effect.text = feat1.get("effect")
		else:
			_maneveue1.visible = true
			_maneveue1_name.text = feat1.get("name")
			_maneveue1_tag.text = feat1.get("tags")
			_maneveue1_effect.text = feat1.get("effect")
	if system.get("feats").size() > 1:
		var feat1 = system.get("feats").get(1)
		if feat1.get("type") == Opt.FEAT_TACTIC:
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

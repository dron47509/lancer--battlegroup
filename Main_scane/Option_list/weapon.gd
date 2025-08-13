extends PanelContainer

const SlotUtils = preload("res://slot_utils.gd")
const Opt = preload("res://option_types.gd")

@onready var _name: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Name
@onready var _tags: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Tags
@onready var _param: RichTextLabel = $VBoxContainer/Head/MarginContainer/VBoxContainer/Param
@onready var _effect: RichTextLabel = $VBoxContainer/Effect/Effect
@onready var _discription: RichTextLabel = $VBoxContainer/Discription/Discription
@onready var _add: MarginContainer = $VBoxContainer/Button
@onready var _remove: MarginContainer = $VBoxContainer/Button2
var _src: Dictionary

func _process(delta: float) -> void:
        _update_buttons()

func _update_buttons() -> void:
        var show_add := false
        var show_remove := false
        if _src.size() != 0 and BattlegroupData.current_ship != -1 and BattlegroupData.ships.size() != 0:
                var ship = BattlegroupData.ships[BattlegroupData.current_ship]
                var sum = SlotUtils.get_slot_sums(ship)
                var used = SlotUtils.get_slot_usage(ship)
                var key := ""
                match int(_src.get("type", -1)):
                        Opt.Weapon.SUPERHEAVY: key = "superheavy"
                        Opt.Weapon.PRIMARY:    key = "primary"
                        Opt.Weapon.AUXILIARY:  key = "auxiliary"
                var capacity := sum.get(key, 0) + int(_src.get("modification", {}).get(key, 0))
                var points := int(_src.get("points", 0)) + int(_src.get("modification", {}).get("point", 0))
                show_add = used.get(key, 0) < capacity \
                        and BattlegroupData.point + points <= 20 \
                        and not (_has_unique_tag(_src) and _is_unique_taken())
                show_remove = _count_added(ship) > 0
        _add.visible = show_add
        _remove.visible = show_remove

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
	_discription.text = "[i]" + weapon.get("discription") + "[/i]"


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

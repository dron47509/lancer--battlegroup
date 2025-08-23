extends GridContainer

const SlotUtils = preload("res://slot_utils.gd")

@onready var _labels = {
	"point":$Points/Point,
	"superheavy": $Superheavies/Superheavy,
	"primaries": $Primaries/Primary,
	"auxiliaries": $Auxiliaries/Auxiliary,
	"wings": $Wings/Wing,
	"escorts": $Escorts/Escort,
	"systems": $Systems/System,
	"special": $Special/Special,
}


func _process(delta: float) -> void:
	_update_from_ship()


func _update_from_ship() -> void:
                var idx = int(BattlegroupData.current_ship)
		if idx < 0 or idx >= BattlegroupData.ships.size():
				return
		var ship = BattlegroupData.ships[idx]
		var sum = SlotUtils.get_slot_total(ship)
		var used = SlotUtils.get_slot_usage(ship)
		_labels["point"].text = "%d/20" % BattlegroupData.point
		_labels["superheavy"].text = "%d/%d" % [used["superheavy"], sum["superheavy"]]
		_labels["primaries"].text = "%d/%d" % [used["primary"], sum["primary"]]
		_labels["auxiliaries"].text = "%d/%d" % [used["auxiliary"], sum["auxiliary"]]
		_labels["wings"].text = "%d/%d" % [used["wing"], sum["wing"]]
		_labels["escorts"].text = "%d/%d" % [used["escort"], sum["escort"]]
		_labels["systems"].text = "%d/%d" % [used["system"], sum["system"]]
		if ship.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER", "IPS-N\nMINOKAWA-CLASS FRIGATE"]:
			_labels["special"].text = "%d/1" % ship["special"].size()
		else:
			_labels["special"].text = "0/0"
		_refresh_visibility()

func _refresh_visibility() -> void:
        var any_visible = false
	for c in get_children():
		if c.get_child(1).text != "0/0":
			c.visible = true
		else:
			c.visible = false

extends HFlowContainer

const SlotUtils = preload("res://slot_utils.gd")

@onready var _labels := {
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
		var ship = $"../../..".ship_cur
		var sum = SlotUtils.get_slot_total(ship)
		var used = SlotUtils.get_slot_usage(ship)
		_labels["superheavy"].text = "%d/%d" % [used["superheavy"], sum["superheavy"]]
		_labels["primaries"].text = "%d/%d" % [used["primary"], sum["primary"]]
		_labels["auxiliaries"].text = "%d/%d" % [used["auxiliary"], sum["auxiliary"]]
		_labels["wings"].text = "%d/%d" % [used["wing"], sum["wing"]]
		_labels["escorts"].text = "%d/%d" % [used["escort"], sum["escort"]]
		_labels["systems"].text = "%d/%d" % [used["system"], sum["system"]]
		if get_parent().get_parent().get_parent().ship_cur.get("name") in ["HA\nFARRAGUT-CLASS STARFIELD CARRIER", "IPS-N\nMINOKAWA-CLASS FRIGATE"]:
			_labels["special"].text = "%d/1" % ship["special"].size()
		_refresh_visibility()

func _refresh_visibility() -> void:
	var any_visible := false
	for c in get_children():
		if c.get_child(1).text != "0/0":
			c.visible = true
		else:
			c.visible = false

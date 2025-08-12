extends HBoxContainer

const SlotUtils = preload("res://slot_utils.gd")

@onready var _labels := {
	"superheavy": $Superheavies/Superheavy,
	"primaries": $Primaries/Primary,
	"auxiliaries": $Auxiliaries/Auxiliary,
	"wings": $Wings/Wing,
	"escorts": $Escorts/Escort,
	"systems": $Systems/System,
}

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_update_from_ship()

func _on_visibility_changed() -> void:
	if visible:
		_update_from_ship()

func _update_from_ship() -> void:
	var idx := int(BattlegroupData.current_ship)
	if idx < 0 or idx >= BattlegroupData.ships.size():
		return
	var ship = BattlegroupData.ships[idx]
	var sum := SlotUtils.get_slot_sums(ship)
	_labels["superheavy"].text = str(sum["superheavy"])
	_labels["primaries"].text = str(sum["primary"])
	_labels["auxiliaries"].text = str(sum["auxiliary"])
	_labels["wings"].text = str(sum["wing"])
	_labels["escorts"].text = str(sum["escort"])
	_labels["systems"].text = str(sum["system"])
	_refresh_visibility()

func _refresh_visibility() -> void:
	var any_visible := false
	for c in get_children():
		if c.get_child_count() > 1:
			var lbl = c.get_child(1)
			var show = lbl.text != "0"
			c.visible = show
			if show:
				any_visible = true
		else:
			push_warning("%s has no second child; skipping" % c.name)
			c.visible = true
			any_visible = true
	visible = any_visible

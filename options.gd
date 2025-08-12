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
        var ship := BattlegroupData.ships[idx]
        var sum := SlotUtils.get_slot_sums(ship)
        var used := SlotUtils.get_slot_usage(ship)
        _labels["superheavy"].text = "%d/%d" % [used["superheavy"], sum["superheavy"]]
        _labels["primaries"].text = "%d/%d" % [used["primary"], sum["primary"]]
        _labels["auxiliaries"].text = "%d/%d" % [used["auxiliary"], sum["auxiliary"]]
        _labels["wings"].text = "%d/%d" % [used["wing"], sum["wing"]]
        _labels["escorts"].text = "%d/%d" % [used["escort"], sum["escort"]]
        _labels["systems"].text = "%d/%d" % [used["system"], sum["system"]]
        _refresh_visibility()

func _refresh_visibility() -> void:
        var any_visible := false
        for c in get_children():
                if c.get_child_count() > 1:
                        var lbl = c.get_child(1)
                        var parts = lbl.text.split("/")
                        var show := parts.size() == 2 and int(parts[1]) > 0
                        c.visible = show
                        if show:
                                any_visible = true
                else:
                        push_warning("%s has no second child; skipping" % c.name)
			c.visible = true
			any_visible = true
	visible = any_visible

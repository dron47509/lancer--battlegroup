class_name SlotUtils

static func get_slot_sums(ship: Dictionary) -> Dictionary:
	var sum := {
		"auxiliary": int(ship["weapon_slots"]["auxiliaries"]),
		"escort": int(ship["support_slots"]["escorts"]),
		"primary": int(ship["weapon_slots"]["primaries"]),
		"superheavy": int(ship["weapon_slots"]["superheavy"]),
		"system": int(ship["support_slots"]["systems"]),
		"wing": int(ship["support_slots"]["wings"]),
	}
	for option in ship.get("option", []):
		var mod := option.get("modification", {})
		sum["auxiliary"] += int(mod.get("auxiliary", 0))
		sum["escort"] += int(mod.get("escort", 0))
		sum["primary"] += int(mod.get("primary", 0))
		sum["superheavy"] += int(mod.get("superheavy", 0))
		sum["system"] += int(mod.get("system", 0))
		sum["wing"] += int(mod.get("wing", 0))
	return sum

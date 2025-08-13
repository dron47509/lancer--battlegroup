class_name SlotUtils

const Opt = preload("res://option_types.gd")

static func get_slot_sums(ship: Dictionary) -> Dictionary:
	var sum = {
		"auxiliary": int(ship["weapon_slots"]["auxiliaries"]),
		"escort": int(ship["support_slots"]["escorts"]),
		"primary": int(ship["weapon_slots"]["primaries"]),
		"superheavy": int(ship["weapon_slots"]["superheavy"]),
		"system": int(ship["support_slots"]["systems"]),
		"wing": int(ship["support_slots"]["wings"]),
	}
	for option in ship.get("option", []):
		var mod = option.get("modification", {})
		sum["auxiliary"] += int(mod.get("auxiliary", 0))
		sum["escort"] += int(mod.get("escort", 0))
		sum["primary"] += int(mod.get("primary", 0))
		sum["superheavy"] += int(mod.get("superheavy", 0))
		sum["system"] += int(mod.get("system", 0))
		sum["wing"] += int(mod.get("wing", 0))
	return sum


static func get_slot_usage(ship: Dictionary) -> Dictionary:
	var used = {
			"auxiliary": 0,
			"escort": 0,
			"primary": 0,
			"superheavy": 0,
			"system": 0,
			"wing": 0,
	}
	for option in ship.get("option", []):
		if option.has("type"):
			match int(option["type"]):
				Opt.Weapon.SUPERHEAVY:
					used["superheavy"] += 1
				Opt.Weapon.PRIMARY:
					used["primary"] += 1
				Opt.Weapon.AUXILIARY:
					used["auxiliary"] += 1
				Opt.Support.ESCORT:
					used["escort"] += 1
				Opt.Support.WING:
					used["wing"] += 1
				3:
					used["system"] += 1
			
	return used

static func get_slot_total(ship: Dictionary) -> Dictionary:
	var sum = {
		"auxiliary": int(ship["weapon_slots"]["auxiliaries"]),
		"escort": int(ship["support_slots"]["escorts"]),
		"primary": int(ship["weapon_slots"]["primaries"]),
		"superheavy": int(ship["weapon_slots"]["superheavy"]),
		"system": int(ship["support_slots"]["systems"]),
		"wing": int(ship["support_slots"]["wings"]),
	}
	return sum

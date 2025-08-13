class_name OptionTypes

# Weapon categories
enum Weapon {
	SUPERHEAVY,
	PRIMARY,
	AUXILIARY,
}

# Support options (escorts and wings)
enum Support {
	ESCORT = 5,
	WING = 4,
}

# Indices of option categories in option lists
enum SlotIndex {
	SUPERHEAVY,
	PRIMARIES,
	AUXILIARIES,
	SYSTEMS,
	ESCORTS,
	WINGS,
	ALL,
}

# Filter values for hull list OptionButton
enum HullFilter {
	ALL,
	FRIGATE,
	CARRIER,
	BATTLESHIP,
}

# Feat type identifier
const FEAT_TACTIC = 2

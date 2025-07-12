extends VBoxContainer
# Скрипт для узла Weapon_vbox
# Управление орудиями (Weapon) с сохранением в JSON.
#  ▸ add_weapon_button — создает/обновляет запись орудия в JSON и кнопку в списке.
#  ▸ При загрузке существующего орудия все поля формы заполняются.

# -----------------------------------------------------------------------------
#  КОНСТАНТЫ
# -----------------------------------------------------------------------------
const JSON_PATH := "user://battlegroup_data.json"   # Файл‑хранилище
# -----------------------------------------------------------------------------
#  UI‑ССЫЛКИ
# -----------------------------------------------------------------------------
@onready var name_edit            : TextEdit      = $Weapons_name_text_edit
@onready var weapon_option        : OptionButton  = $Weapon_type_option_button
@onready var tags_edit            : TextEdit      = $Tags_text_edit
@onready var point_edit           : TextEdit      = $Stats_hbox/Point_vbox/Point_text_edit
@onready var damage_edit          : TextEdit      = $Stats_hbox/Damage_vbox/Damage_text_edit
@onready var range_edit           : TextEdit      = $Stats_hbox/Range_vbox/Range_text_edit
@onready var effect_edit          : TextEdit      = $Effect_text_edit
@onready var discription_edit     : TextEdit      = $Discription_text_edit

# Модификации
@onready var m_point_edit         : TextEdit        = $Stats_hbox2/Point_vbox/Point_text_edit
@onready var m_HP_edit            : TextEdit        = $Stats_hbox2/HP_vbox/HP_text_edit
@onready var m_defence_edit       : TextEdit        = $Stats_hbox2/Defense_vbox/Defense_text_edit
@onready var m_superheavy_edit    : TextEdit        = $Options_hbox/Superheavies_vbox/Superheavy_text_edit
@onready var m_primary_edit       : TextEdit        = $Options_hbox/Primaries_vbox/Primaries_text_edit
@onready var m_auxiliary_edit     : TextEdit        = $Options_hbox/Auxiliaries_vbox/Auxiliaries_text_edit
@onready var m_wing_edit          : TextEdit        = $Options2_hbox/Wings_vbox/Wings_text_edit
@onready var m_escort_edit        : TextEdit        = $Options2_hbox/Escorts_vbox/Escorts_text_edit
@onready var m_system_edit        : TextEdit        = $Options2_hbox/Systems_vbox/Systems_text_edit
@onready var m_interdiction_edit  : TextEdit        = $Options3_hbox/Interdiction_vbox/Interdiction_text_edit

@onready var add_weapon_button      : Button        = $Add_weapon_button

@onready var weapons_list_container : VBoxContainer = $Weapons_vbox         # Контейнер кнопок корпусов

# -----------------------------------------------------------------------------
#  ПЕРЕМЕННЫЕ
# -----------------------------------------------------------------------------
var data : Dictionary = {}                # Данные JSON

# ============================================================================
#  READY
# ============================================================================
func _ready() -> void:
	_ensure_json()
	_populate_weapon_buttons()

	add_weapon_button.pressed.connect(_on_add_weapon_pressed)


# ============================================================================
#  JSON HELPERS
# ============================================================================
func _ensure_json() -> void:
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file == null:
		data = {"weapons": []}
		_save_json()
	else:
		data = JSON.parse_string(file.get_as_text())
		if typeof(data) != TYPE_DICTIONARY:
			data = {}
		if not data.has("weapons"):
			data["weapons"] = []

func _save_json() -> void:
	var file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

# ============================================================================
#  ADD / UPDATE WEAPON
# ============================================================================
func _on_add_weapon_pressed() -> void:
	var weapon_name := name_edit.text.strip_edges()
	if weapon_name == "":
		push_warning("Введите название корпуса.")
		return

	var weapon_dict := {
		"name": weapon_name,
		"type": weapon_option.selected,
		"tags": tags_edit.text.strip_edges(),
		"points": int(point_edit.text.strip_edges()),
		"damage": damage_edit.text.strip_edges(),
		"range": range_edit.text.strip_edges(),
		"effect": effect_edit.text.strip_edges(),
		"discription": discription_edit.text.strip_edges(),
		"modification":{
			"point": m_point_edit.text.strip_edges(),
			"HP": m_HP_edit.text.strip_edges(),
			"defence": m_defence_edit.text.strip_edges(),
			"superheavy": m_superheavy_edit.text.strip_edges(),
			"primary": m_primary_edit.text.strip_edges(),
			"auxiliary": m_auxiliary_edit.text.strip_edges(),
			"wing": m_wing_edit.text.strip_edges(),
			"escort": m_escort_edit.text.strip_edges(),
			"system": m_system_edit.text.strip_edges(),
			"interdiction": m_interdiction_edit.text.strip_edges(),
		},
	}

	var idx := _find_weapon_index(weapon_name)
	if idx == -1:
		data["weapons"].append(weapon_dict)
		_create_weapon_button(weapon_dict)
	else:
		data["weapons"][idx] = weapon_dict
	_save_json()
	_clear_text_edit()
	

func _clear_text_edit() -> void:
	name_edit.text = ""
	tags_edit.text = ""
	point_edit.text = ""
	damage_edit.text = ""
	range_edit.text = ""
	effect_edit.text = ""
	discription_edit.text = ""
	
func _find_weapon_index(name:String) -> int:
	for i in range(data["weapons"].size()):
		if data["weapons"][i]["name"].to_lower() == name.to_lower():
			return i
	return -1

# ============================================================================
#  WEAPON LIST UI
# ============================================================================
func _populate_weapon_buttons() -> void:
	_clear_children(weapons_list_container)
	for h in data["weapons"]:
		_create_weapon_button(h)

func _create_weapon_button(weapon:Dictionary) -> void:
	var btn := Button.new()
	btn.text = weapon["name"]
	btn.pressed.connect(func(): _load_weapon_to_form(weapon))
	weapons_list_container.add_child(btn)

func _load_weapon_to_form(weapon:Dictionary) -> void:
	# Текстовые поля
	name_edit.text          = weapon["name"]
	weapon_option.selected  = weapon["type"]
	tags_edit.text          = weapon["tags"]
	point_edit.text         = str(weapon["points"])
	damage_edit.text        = weapon["damage"]
	range_edit.text     	= weapon["range"]
	m_point_edit.text         = weapon["modification"]["point"]
	m_HP_edit.text            = weapon["modification"]["HP"]
	m_defence_edit.text       = weapon["modification"]["defence"]
	m_superheavy_edit.text    = weapon["modification"]["superheavy"]
	m_primary_edit.text       = weapon["modification"]["primary"]
	m_auxiliary_edit.text     = weapon["modification"]["auxiliary"]
	m_wing_edit.text          = weapon["modification"]["wing"]
	m_escort_edit.text        = weapon["modification"]["escort"]
	m_system_edit.text        = weapon["modification"]["system"]
	m_interdiction_edit.text  = weapon["modification"]["interdiction"]
	effect_edit.text = str(weapon["effect"])
	discription_edit.text = str(weapon["discription"])

# ============================================================================
#  UTILS
# ============================================================================
func _clear_children(container: Node) -> void:
	for c in container.get_children():
		c.queue_free()

# Удаляет всех детей, кроме исключений
func _clear_children_except(container: Node, exception1: Node, exception2: Node = null) -> void:
	for c in container.get_children():
		if c != exception1 and c != exception2:
			c.queue_free()

extends VBoxContainer

# Скрипт для узла System_vbox
# Управление корпусами (System) и их чертами (Feat) с сохранением в JSON.
#  ▸ Add_feat_button      — добавляет новую сцену Feat.tscn прямо над кнопкой.
#  ▸ Delete_feat_button   — удаляет конкретный узел Feat (или очищает, если он один).
#  ▸ Add_system_button      — создает/обновляет запись системы в JSON и кнопку в списке.
#  ▸ При загрузке существующей системы все поля формы и список Feat заполняются.

# -----------------------------------------------------------------------------
#  КОНСТАНТЫ
# -----------------------------------------------------------------------------
const JSON_PATH := "res://battlegroup_data.json"   # Файл‑хранилище
const FEAT_SCENE := preload("res://Feat.tscn")      # Сцена черты

# -----------------------------------------------------------------------------
#  UI‑ССЫЛКИ
# -----------------------------------------------------------------------------
@onready var name_edit            : TextEdit        = $Name_text_edit
@onready var tags_edit            : TextEdit        = $Tag_text_edit
@onready var point_edit           : TextEdit        = $Point_text_edit
@onready var tenacity_edit        : TextEdit        = $Tenacity_text_edit
@onready var effect_edit          : TextEdit        = $Effect_text_edit
@onready var discription_edit     : TextEdit        = $Discription_text_edit

# Модификации
@onready var m_point_edit         : TextEdit        = $Stats_hbox/Point_vbox/Point_text_edit
@onready var m_HP_edit            : TextEdit        = $Stats_hbox/HP_vbox/HP_text_edit
@onready var m_defence_edit       : TextEdit        = $Stats_hbox/Defense_vbox/Defense_text_edit
@onready var m_superheavy_edit    : TextEdit        = $Options_hbox/Superheavies_vbox/Superheavy_text_edit
@onready var m_primary_edit       : TextEdit        = $Options_hbox/Primaries_vbox/Primaries_text_edit
@onready var m_auxiliary_edit     : TextEdit        = $Options_hbox/Auxiliaries_vbox/Auxiliaries_text_edit
@onready var m_wing_edit          : TextEdit        = $Options2_hbox/Wings_vbox/Wings_text_edit
@onready var m_escort_edit        : TextEdit        = $Options2_hbox/Escorts_vbox/Escorts_text_edit
@onready var m_system_edit        : TextEdit        = $Options2_hbox/Systems_vbox/Systems_text_edit
@onready var m_interdiction_edit  : TextEdit        = $Options3_hbox/Interdiction_vbox/Interdiction_text_edit

@onready var feats_parent       : VBoxContainer     = $Feat_vbox   
@onready var add_feat_button      : Button          = $Feat_vbox/Add_feat_button
@onready var add_system_button      : Button        = $Add_system_button

@onready var systems_list_container : VBoxContainer = $System_vbox          # Контейнер кнопок систем

# -----------------------------------------------------------------------------
#  ПЕРЕМЕННЫЕ
# -----------------------------------------------------------------------------
var data : Dictionary = {}                # Данные JSON

# ============================================================================
#  READY
# ============================================================================
func _ready() -> void:
	_ensure_json()
	_populate_system_buttons()

	add_feat_button.pressed.connect(_add_feat_box)
	add_system_button.pressed.connect(_on_add_system_pressed)


# ============================================================================
#  JSON HELPERS
# ============================================================================
func _ensure_json() -> void:
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file == null:
		data = {"systems": []}
		_save_json()
	else:
		data = JSON.parse_string(file.get_as_text())
		if typeof(data) != TYPE_DICTIONARY:
			data = {}
		if not data.has("systems"):
			data["systems"] = []

func _save_json() -> void:
	var file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

# ============================================================================
#  FEAT LOGIC
# ============================================================================
func _setup_feat_box(box: VBoxContainer) -> void:
	# Очистка полей (для новых боксов)
	for c in box.get_children():
		if c is TextEdit:
			c.text = ""
	# Подключаем delete
	var del_btn := box.get_node_or_null("Feat_hbox/Delete_feat_button")
	if del_btn and not del_btn.pressed.is_connected(_on_delete_feat_pressed):
		del_btn.pressed.connect(func(): _on_delete_feat_pressed(box))

func _add_feat_box() -> void:
	var new_box : VBoxContainer = FEAT_SCENE.instantiate()
	_setup_feat_box(new_box)
	var parent := add_feat_button.get_parent()
	parent.add_child(new_box)
	parent.move_child(new_box, add_feat_button.get_index())

func _on_delete_feat_pressed(box: VBoxContainer) -> void:
	var boxes := _get_all_feat_boxes()
	if boxes.size() == 1:
		# Единственная — очищаем
		for c in box.get_children():
			if c is TextEdit:
				c.text = ""
	else:
		box.queue_free()

func _get_all_feat_boxes() -> Array:
	var arr : Array = []
	for node in feats_parent.get_children():
		if node.has_node("Feat_hbox/Feat_name_text_edit"):
			arr.append(node)
	return arr

func _collect_feats() -> Array:
	var feats : Array = []
	for box in _get_all_feat_boxes():
		var n : TextEdit = box.get_node("Feat_hbox/Feat_name_text_edit")
		var t : OptionButton = box.get_node("Feat_type_option_button")
		var g : TextEdit = box.get_node("Tags_text_edit")
		var m : TextEdit = box.get_node("Stats_hbox/Damage_vbox/Damage_text_edit")
		var r : TextEdit = box.get_node("Stats_hbox/Range_vbox/Range_text_edit")
		var e : TextEdit = box.get_node("Feat_effect_text_edit")
		var d : TextEdit = box.get_node("Feat_discription_text_edit")
		if n.text.strip_edges() != "":
			feats.append({
				"name": n.text.strip_edges(),
				"type": t.selected,
				"tags": g.text.strip_edges(),
				"damage": m.text.strip_edges(),
				"range": r.text.strip_edges(),
				"effect": e.text.strip_edges(),
				"discription": d.text.strip_edges()
			})
	return feats


# ============================================================================
#  ADD / UPDATE SYSTEM
# ============================================================================
func _on_add_system_pressed() -> void:
	var system_name := name_edit.text.strip_edges()
	if system_name == "":
		push_warning("Введите название системы.")
		return

	var system_dict := {
		"name": system_name,
		"tags": tags_edit.text.strip_edges(),
		"points": int(point_edit.text.strip_edges()),
		"tenacity": int(tenacity_edit.text.strip_edges()),
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
		"feats": _collect_feats(),
	}

	var idx := _find_system_index(system_name)
	if idx == -1:
		data["systems"].append(system_dict)
		_create_system_button(system_dict)
	else:
		data["systems"][idx] = system_dict
	_save_json()
	
	_clear_children_except(feats_parent, add_feat_button)
	name_edit.text            = ""
	tags_edit.text            = ""
	point_edit.text           = "0"
	tenacity_edit.text        = ""
	effect_edit.text          = ""
	discription_edit.text     = ""
	m_point_edit.text         = "0"
	m_HP_edit.text            = "0"
	m_defence_edit.text       = "0"
	m_superheavy_edit.text    = "0"
	m_primary_edit.text       = "0"
	m_auxiliary_edit.text     = "0"
	m_wing_edit.text          = "0"
	m_escort_edit.text        = "0"
	m_system_edit.text        = "-1"
	m_interdiction_edit.text  = "0"
	
	
func _find_system_index(name:String) -> int:
	for i in range(data["systems"].size()):
		if data["systems"][i]["name"].to_lower() == name.to_lower():
			return i
	return -1


# ============================================================================
#  SYSTEM LIST UI
# ============================================================================
func _populate_system_buttons() -> void:
	_clear_children(systems_list_container)
	for h in data["systems"]:
		_create_system_button(h)

func _create_system_button(system:Dictionary) -> void:
	var btn := Button.new()
	btn.text = system["name"]
	btn.pressed.connect(func(): _load_system_to_form(system))
	systems_list_container.add_child(btn)

func _load_system_to_form(system:Dictionary) -> void:
	# Текстовые поля
	name_edit.text            = system["name"]
	tags_edit.text            = system["tags"]
	point_edit.text           = str(system["points"])
	tenacity_edit.text        = str(system["tenacity"])
	effect_edit.text          = str(system["effect"])
	discription_edit.text     = str(system["discription"])
	m_point_edit.text         = system["modification"]["point"]
	m_HP_edit.text            = system["modification"]["HP"]
	m_defence_edit.text       = system["modification"]["defence"]
	m_superheavy_edit.text    = system["modification"]["superheavy"]
	m_primary_edit.text       = system["modification"]["primary"]
	m_auxiliary_edit.text     = system["modification"]["auxiliary"]
	m_wing_edit.text          = system["modification"]["wing"]
	m_escort_edit.text        = system["modification"]["escort"]
	m_system_edit.text        = system["modification"]["system"]
	m_interdiction_edit.text  = system["modification"]["interdiction"]
	# ---------- FEATS ----------

	_clear_children_except(feats_parent, add_feat_button)

	var feats_arr : Array = system.get("feats", [])
	for i in range(feats_arr.size()):
		var feat_dict = feats_arr[i]
		var box : VBoxContainer = FEAT_SCENE.instantiate()
		_setup_feat_box(box)
		feats_parent.add_child(box)
		feats_parent.move_child(box, add_feat_button.get_index())
		box.get_node("Feat_hbox/Feat_name_text_edit").text           = feat_dict.get("name", "")
		box.get_node("Feat_type_option_button").selected             = int(feat_dict.get("type", ""))
		box.get_node("Tags_text_edit").text                          = feat_dict.get("tags", "")
		box.get_node("Stats_hbox/Damage_vbox/Damage_text_edit").text = feat_dict.get("damage", "")
		box.get_node("Stats_hbox/Range_vbox/Range_text_edit").text   = feat_dict.get("range", "")
		box.get_node("Feat_effect_text_edit").text                   = feat_dict.get("effect", "")
		box.get_node("Feat_discription_text_edit").text              = feat_dict.get("discription", "")


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

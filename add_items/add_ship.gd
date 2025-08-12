extends VBoxContainer
# Скрипт для узла Hull_vbox
# Управление корпусами (Hull) и их чертами (Feat) с сохранением в JSON.
#  ▸ Add_feat_button      — добавляет новую сцену Feat.tscn прямо над кнопкой.
#  ▸ Delete_feat_button   — удаляет конкретный узел Feat (или очищает, если он один).
#  ▸ Load_image_button    — открывает FileDialog для выбора изображения корпуса.
#  ▸ Add_hull_button      — создает/обновляет запись корпуса в JSON и кнопку в списке.
#  ▸ При загрузке существующего корпуса все поля формы и список Feat заполняются.

# -----------------------------------------------------------------------------
#  КОНСТАНТЫ
# -----------------------------------------------------------------------------
const JSON_PATH := "res://battlegroup_data.json"   # Файл‑хранилище
const HULLS_DIR  := "res://hulls/"                 # Каталог для картинок
const FEAT_SCENE := preload("res://Feat.tscn")      # Сцена черты

# -----------------------------------------------------------------------------
#  UI‑ССЫЛКИ
# -----------------------------------------------------------------------------
@onready var name_edit            : TextEdit   = $Hulls_name_text_edit
@onready var class_option         : OptionButton = $Class_hull_option_button
@onready var point_edit           : TextEdit   = $Stats_hbox/Point_vbox/Point_text_edit
@onready var hp_edit              : TextEdit   = $Stats_hbox/HP_vbox/HP_text_edit
@onready var defense_edit         : TextEdit   = $Stats_hbox/Defense_vbox/Defense_text_edit
@onready var superheavy_edit      : TextEdit   = $Options_hbox/Superheavies_vbox/Superheavy_text_edit
@onready var primaries_edit       : TextEdit   = $Options_hbox/Primaries_vbox/Primaries_text_edit
@onready var auxiliaries_edit     : TextEdit   = $Options_hbox/Auxiliaries_vbox/Auxiliaries_text_edit
@onready var wings_edit           : TextEdit   = $Options2_hbox/Wings_vbox/Wings_text_edit
@onready var escorts_edit         : TextEdit   = $Options2_hbox/Escorts_vbox/Escorts_text_edit
@onready var systems_edit         : TextEdit   = $Options2_hbox/Systems_vbox/Systems_text_edit
@onready var discription_edit     : TextEdit   = $Discription_text_edit

@onready var feats_parent       : VBoxContainer   = $Feat_vbox   
@onready var add_feat_button      : Button        = $Feat_vbox/Add_feat_button
@onready var load_image_button    : Button        = $Load_image_button
@onready var add_hull_button      : Button        = $Add_hull_button

@onready var hulls_list_container : VBoxContainer = $Hulls_vbox         # Контейнер кнопок корпусов
@onready var file_dialog          : FileDialog    = $FileDialog

# -----------------------------------------------------------------------------
#  ПЕРЕМЕННЫЕ
# -----------------------------------------------------------------------------
var selected_image_path : String = ""     # Путь к выбранной картинке
var data : Dictionary = {}                # Данные JSON

# ============================================================================
#  READY
# ============================================================================
func _ready() -> void:
	_ensure_json()
	_populate_hull_buttons()


	add_feat_button.pressed.connect(_add_feat_box)
	load_image_button.pressed.connect(_on_load_image_pressed)
	add_hull_button.pressed.connect(_on_add_hull_pressed)
	file_dialog.file_selected.connect(_on_image_chosen)

	file_dialog.add_filter("*.png ; PNG")
	#file_dialog.add_filter("*.jpg, *.jpeg ; JPEG")

# ============================================================================
#  JSON HELPERS
# ============================================================================
func _ensure_json() -> void:
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file == null:
		data = {"hulls": []}
		_save_json()
	else:
		data = JSON.parse_string(file.get_as_text())
		if typeof(data) != TYPE_DICTIONARY:
			data = {}
		if not data.has("hulls"):
			data["hulls"] = []

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
				"effect": e.text.strip_edges().replace("\r", " ").replace("\n", " "),
				"discription": d.text.strip_edges().replace("\r", " ").replace("\n", " ")
			})
	return feats


# ============================================================================
#  IMAGE DIALOG
# ============================================================================
func _on_load_image_pressed() -> void:
	file_dialog.popup_centered()

func _on_image_chosen(path:String) -> void:
	selected_image_path = path

# ============================================================================
#  ADD / UPDATE HULL
# ============================================================================
func _on_add_hull_pressed() -> void:
	var hull_name := name_edit.text.strip_edges()
	if hull_name == "":
		push_warning("Введите название корпуса.")
		return

	var hull_dict := {
		"name": hull_name,
		"class": class_option.selected,
		"points": point_edit.text.strip_edges(),
		"hp": hp_edit.text.strip_edges(),
		"defense": defense_edit.text.strip_edges(),
		"discription": discription_edit.text.strip_edges().replace("\r", " ").replace("\n", " "),
		"weapon_slots": {
			"superheavy": superheavy_edit.text.strip_edges(),
			"primaries" : primaries_edit.text.strip_edges(),
			"auxiliaries": auxiliaries_edit.text.strip_edges()
		},
		"support_slots": {
			"wings"  : wings_edit.text.strip_edges(),
			"escorts": escorts_edit.text.strip_edges(),
			"systems": systems_edit.text.strip_edges()
		},
		"feats": _collect_feats(),
	}

	var idx := _find_hull_index(hull_name)
	if idx == -1:
		data["hulls"].append(hull_dict)
		_create_hull_button(hull_dict)
	else:
		data["hulls"][idx] = hull_dict
	_save_json()
	name_edit.text = ""
	point_edit.text = ""
	hp_edit.text = ""
	defense_edit.text = ""
	discription_edit.text = ""
	superheavy_edit.text = "0"
	primaries_edit.text = "0"
	auxiliaries_edit.text = "0"
	wings_edit.text = "0"
	escorts_edit.text = "0"
	systems_edit.text  = "0"
	_clear_children_except(feats_parent, add_feat_button)

func _find_hull_index(name:String) -> int:
	for i in range(data["hulls"].size()):
		if data["hulls"][i]["name"].to_lower() == name.to_lower():
			return i
	return -1

# ============================================================================
#  IMAGE COPY
# ============================================================================
func _copy_image_if_needed(hull_name:String) -> String:
	if selected_image_path == "":
		return ""
	var ext := selected_image_path.get_extension()
	var dst := HULLS_DIR + hull_name + "." + ext
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HULLS_DIR))
	if not FileAccess.file_exists(dst):
		var err := DirAccess.copy_absolute(selected_image_path, ProjectSettings.globalize_path(dst))
		if err != OK:
			push_warning("Не удалось скопировать изображение: %s" % str(err))
			return ""
	return dst

# ============================================================================
#  HULL LIST UI
# ============================================================================
func _populate_hull_buttons() -> void:
	_clear_children(hulls_list_container)
	for h in data["hulls"]:
		_create_hull_button(h)

func _create_hull_button(hull:Dictionary) -> void:
	var btn := Button.new()
	btn.text = hull["name"]
	btn.pressed.connect(func(): _load_hull_to_form(hull))
	hulls_list_container.add_child(btn)

func _load_hull_to_form(hull:Dictionary) -> void:
	# Текстовые поля
	name_edit.text        = hull["name"]
	class_option.selected = hull["class"]

	point_edit.text       = str(hull["points"])
	hp_edit.text          = str(hull["hp"])
	defense_edit.text     = str(hull["defense"])

	superheavy_edit.text  = str(hull["weapon_slots"]["superheavy"])
	primaries_edit.text   = str(hull["weapon_slots"]["primaries"])
	auxiliaries_edit.text = str(hull["weapon_slots"]["auxiliaries"])

	wings_edit.text       = str(hull["support_slots"]["wings"])
	escorts_edit.text     = str(hull["support_slots"]["escorts"])
	systems_edit.text     = str(hull["support_slots"]["systems"])
	discription_edit.text = str(hull["discription"])
	
	# ---------- FEATS ----------
	_clear_children_except(feats_parent, add_feat_button)

	var feats_arr : Array = hull.get("feats", [])
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


	# Сохраняем путь картинки для последующего обновления
	selected_image_path = hull.get("image", "")

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

extends PanelContainer

# --- ссылки на виджеты ---------------------------------------------------
@onready var _name        : Label           = $Feat/Header/MarginContainer/Header/Name
@onready var _type        : Label           = $Feat/Header/MarginContainer/Header/Type
@onready var _tags        : Label           = $Feat/Header/MarginContainer/Header/Tags
@onready var _damage      : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Damage
@onready var _range       : Label           = $Feat/Header/MarginContainer/Header/Damage_range_container/Range
@onready var _effect      : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Effect
@onready var _description : RichTextLabel   = $Feat/MarginContainer/VBoxContainer/Description
@onready var _header      : PanelContainer  = $Feat/Header

# --- темы ---------------------------------------------------
var feat_theme = preload("res://Main_scane/Hull_list/Themes/Feat.tres")
var feat_header_theme = preload("res://Main_scane/Hull_list/Themes/Feat_header.tres")
var maneuver_theme = preload("res://Main_scane/Hull_list/Themes/Maneuver.tres")
var maneuver_header_theme = preload("res://Main_scane/Hull_list/Themes/Maneuver_header.tres")
var tactic_theme = preload("res://Main_scane/Option_list/Theme/Tactic.tres")
var tactic_header_theme = preload("res://Main_scane/Hull_list/Themes/Tactic_header.tres")
var weapon_theme = preload("res://Main_scane/Hull_list/Themes/Weapon.tres")
var weapon_header_theme = preload("res://Main_scane/Hull_list/Themes/Weapon_header.tres")

func _hide_if_text_empty(node: Node) -> void:
	# 1. Проверяем наличие свойства `text`
	if "text" in node:
		var txt = node.get("text")
		if typeof(txt) == TYPE_STRING and txt.strip_edges() == "":
			node.visible = false
		else:
			node.visible = true


	# 3. Рекурсивно идём дальше
	for child in node.get_children():
		_hide_if_text_empty(child)


func populate(data) -> void:
	_name.text = data.get("name")
	match data.get("type"):
		0.0:
			_type.text = "Черта"
		1.0:
			_type.text = "Маневр"
		2.0:
			_type.text = "Тактика"
		3.0:
			_type.text = "Орудие"
	_tags.text = data.get("tags")
	if data.get("damage") != "":
		_damage.text = "[Урон %s]" % data.get("damage")
	if data.get("range") != "":
		_range.text = "[Дистанция %s]" % data.get("range")
		_effect.text = data.get("effect")
		_description.text = data.get("discription")
	_change_theme()
	_hide_if_text_empty(self)

func _change_theme():
	match _type.text:
		"Черта":
			theme = feat_theme
			_header.theme = feat_header_theme
		"Маневр":
			theme = maneuver_theme
			_header.theme = maneuver_header_theme
		"Тактика":
			theme = tactic_theme
			_header.theme = tactic_header_theme
		"Орудие":
			theme = weapon_theme
			_header.theme = weapon_header_theme

###  Hull.gd  ###
extends VBoxContainer

#signal hull_added(hull_data)     # чтобы подписаться извне
#signal hull_removed(hull_data)     # чтобы подписаться извне

const FEAT_SCENE := preload("res://Main_scane/Hull_list/Feat_for_showing.tscn")

# --- ссылки на виджеты ---------------------------------------------------
@onready var _name        : Label          = $Name
@onready var _type        : Label          = $Type
@onready var _image       : TextureRect    = $Image
@onready var _points      : Label          = $Paramets/Point_Container/Point
@onready var _hp          : Label          = $Paramets/HP_Container/HP
@onready var _defense     : Label          = $Paramets/Defence_Container/Defence
@onready var _option_1    : HBoxContainer  = $Options
@onready var _option_2    : HBoxContainer  = $Options2
@onready var _superheavy  : Label          = $Options/Superheavies/Superheavy
@onready var _primary     : Label          = $Options/Primaries/Primary
@onready var _auxiliary   : Label          = $Options/Auxiliaries/Auxiliary
@onready var _wing        : Label          = $Options/Wings/Wing
@onready var _escort      : Label          = $Options/Escorts/Escort
@onready var _system      : Label          = $Options/Systems/System
@onready var _feat_box    : VBoxContainer  = $MarginContainer/Feats_container
@onready var _discription : RichTextLabel  = $MarginContainer2/Discription
@onready var _add_btn     : Button         = $Button
@onready var _remove_btn  : Button         = $Button2

var _src: Dictionary                     # сохраним оригинал

func _process(delta: float) -> void:
	_update_buttons()
# -------------------------------------------------------------------------
func populate(data: Dictionary) -> void:
	_src = data.duplicate(true)
	_name.text     = data.get("name")
	_image.texture = load("res://hulls/" + data.get("name").replace("\n", " ") + ".png")
	match int(data.get("class")):
		BattlegroupData.ShipClass.FRIGATE:
			_type.text = "Фрегат"
		BattlegroupData.ShipClass.CARRIER:
			_type.text = "Авианосец"
		BattlegroupData.ShipClass.BATTLESHIP:
			_type.text = "Эсминец"

	_points.text     = str(data.get("points"))
	_hp.text         = str(data.get("hp"))
	_defense.text    = str(data.get("defense"))
	_superheavy.text = str(data.get("weapon_slots").get("superheavy"))
	_primary.text    = str(data.get("weapon_slots").get("primaries"))
	_auxiliary.text  = str(data.get("weapon_slots").get("auxiliaries"))
	_wing.text       = str(data.get("support_slots").get("wings"))
	_escort.text     = str(data.get("support_slots").get("escorts"))
	_system.text     = str(data.get("support_slots").get("systems"))
	_discription.text= str(data.get("discription"))
	# описание и черта (feats[0])
	for x in data.get("feats"):
		_spawn_feat(x)

	_option_1.refresh_visibility()
	_connect_buttons()           # см. ниже
	_update_buttons()            # выставляем видимость

func _connect_buttons() -> void:
	_add_btn.pressed.connect(_on_add_pressed)
	_remove_btn.pressed.connect(_on_remove_pressed)


# ------------------------------------------------------------------------------
# 👉 Единое место, которое решает «показать/спрятать»
func _update_buttons() -> void:
	var cls: int = _src["class"]
	var already_added := _count_added()
	var reached_limit := not BattlegroupData.can_add(cls)

	_remove_btn.visible = already_added > 0
	_add_btn.visible    = not reached_limit \
						  and BattlegroupData.point + int(_src.get("points")) <= 20

# ------------------------------------------------------------------------------
func _on_add_pressed() -> void:
	BattlegroupData.add_hull(_src)

func _on_remove_pressed() -> void:
	# ищем последнюю копию нашего шаблона в списке BattlegroupData.ships
	for i in range(BattlegroupData.ships.size() - 1, -1, -1):
		var hull = BattlegroupData.ships[i]
		if _is_same_template(hull):
			BattlegroupData.remove_hull(hull)  # передаём сам словарь-экземпляр
			break


func _spawn_feat(feat_data) -> void:
	var feat := FEAT_SCENE.instantiate()
	_feat_box.add_child(feat)
	feat.populate(feat_data)

func _is_same_template(h: Dictionary) -> bool:
	# сравниваем по «базовому» имени корпуса, остальные поля (ship_name/option/flagman) игнорируем
	return h.get("name") == _src.get("name")

func _count_added() -> int:
	var n := 0
	for s in BattlegroupData.ships:
		if _is_same_template(s):
			n += 1
	return n

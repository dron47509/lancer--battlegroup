extends VBoxContainer

@onready var _range_text: RichTextLabel = $RichTextLabel
@onready var _range_select: OptionButton = $OptionButton

const RANGE_TEXTS := [
	"""• атаки ЗАРЯЖАЕМЫМ орудием получают +1 Точность
• все прочие атаки по одной цели получают +1 Сложность
• атаки Боезарядом совершаются с 5 Счётчиками Полета
• атаки по области, совершаемые из и против боевых групп на этой Дистанционной полосе, наносят половину урона до перехвата.""",
	"""• атаки ЗАРЯЖАЕМЫМ орудием получают +1 Точность
• все прочие атаки по одной цели получают +1 Сложность
• атаки Боезарядом совершаются с 4 Счётчиками Полета.""",
	"""• атаки Боезарядом совершаются с 3 Счётчиками Полета.""",
	"""• атаки Боезарядом совершаются с 2 Счётчиками Полета.""",
	"""• атаки по одной цели (кроме ЗАРЯЖАЕМОГО орудия) получают +1 Точность
• атаки Боезарядом совершаются с 1 Счётчиком Полета
• атаки по области, совершаемые из и против боевых групп на этой Дистанционной полосе, наносят +2 урона.""",
	"""• атаки по одной цели (кроме ЗАРЯЖАЕМОГО орудия) получают +1 Точность
• атаки по области, совершаемые из и против боевых групп на этой Дистанционной полосе, наносят +4 урона
• атаки Боезарядом попадают мгновенно, но также наносят половину урона атакующему (или его боевой группе в случае атак по области), и этот урон нельзя снизить каким бы то ни было способом
• атаки, совершаемые из и против этой дистанции, не могут быть перехвачены.""",
]
const RANGE_VALUES := [5, 4, 3, 2, 1, 0]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_range_select.item_selected.connect(_on_range_selected)
	if not BattlegroupData.range_changed.is_connected(_on_range_changed):
		BattlegroupData.range_changed.connect(_on_range_changed)
	_sync_from_range_value()


func _on_range_selected(index: int) -> void:
	_apply_range_text(index)

func _on_range_changed(value: int) -> void:
	var index := RANGE_VALUES.find(value)
	if index == -1:
		return
	if _range_select.selected != index:
		_range_select.select(index)
	_apply_range_text(index)

func _sync_from_range_value() -> void:
	var index := RANGE_VALUES.find(BattlegroupData.get_range_value())
	if index == -1:
		index = 0
	_range_select.select(index)
	_apply_range_text(index)


func _apply_range_text(index: int) -> void:
	if index < 0 or index >= RANGE_TEXTS.size():
		_range_text.text = ""
		return
	_range_text.text = RANGE_TEXTS[index]
	if index >= 0 and index < RANGE_VALUES.size():
		BattlegroupData.set_range_value(RANGE_VALUES[index])

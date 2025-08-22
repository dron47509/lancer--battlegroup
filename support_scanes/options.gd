extends HBoxContainer  # или VBoxContainer – подставьте свой базовый класс

# индекс того самого «второго Label» внутри каждого контейнера.
# по умолчанию считаем, что в контейнере порядок узлов такой:
#   0 - подпись / иконка
#   1 - числовой Label, который показывает сколько «крыльев / эскортов / систем»
@onready var special_slot = $Special/Special
@export var value_label_index:int = 1


func _process(delta: float) -> void:
	refresh_visibility()
	
# Вызывай этот метод, когда цифры в Label-ах меняются,
# например из другого скрипта или после загрузки данных.
func refresh_visibility() -> void:
	var any_container_visible = false

	for container in get_children():
		# Проверяем, что это действительно контейнер с дочерними узлами.
		if not (container is Control):
			continue

		# Пытаемся достать второй Label по индексу.
		var label_to_check:Label = null

		if container.get_child_count() > value_label_index:
			var candidate = container.get_child(value_label_index)
			if candidate is Label:
				label_to_check = candidate

		# Если второй Label не найден – считаем, что контейнер нужно показать,
		# чтобы не пропустить случай неправильной разметки.
		if label_to_check == null:
			container.visible = true
			any_container_visible = true
			continue

		var number = int(label_to_check.text.strip_edges())
		var show = number != 0
		container.visible = show

		if show:
			any_container_visible = true

	# Если ни один из трёх контейнеров не остался видимым – прячем option2 целиком.
	self.visible = any_container_visible

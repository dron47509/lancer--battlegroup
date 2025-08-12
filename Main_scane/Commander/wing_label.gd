extends Label


func _process(delta: float) -> void:
	if $"../Wing".get_child_count() > 0:
		visible = true
		$"../Wing".visible = true
	else:
		visible = false
		$"../Wing".visible = false

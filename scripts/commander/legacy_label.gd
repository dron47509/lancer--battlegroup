extends Label

func _process(delta: float) -> void:
	if $"../Legacy".get_child_count() > 0:
		visible = true
		$"../Legacy".visible = true
	else:
		visible = false
		$"../Legacy".visible = false

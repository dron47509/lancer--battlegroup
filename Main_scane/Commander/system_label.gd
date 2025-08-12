extends Label


func _process(delta: float) -> void:
	if $"../System".get_child_count() > 0:
		visible = true
		$"../System".visible = true
	else:
		visible = false
		$"../System".visible = false

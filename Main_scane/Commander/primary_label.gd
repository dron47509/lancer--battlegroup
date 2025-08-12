extends Label


func _process(delta: float) -> void:
	if $"../Primary".get_child_count() > 0:
		visible = true
		$"../Primary".visible = true
	else:
		visible = false
		$"../Primary".visible = false

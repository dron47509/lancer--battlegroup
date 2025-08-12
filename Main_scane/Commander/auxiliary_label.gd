extends Label


func _process(delta: float) -> void:
	if $"../Auxiliary".get_child_count() > 0:
		visible = true
		$"../Auxiliary".visible = true
	else:
		visible = false
		$"../Auxiliary".visible = false

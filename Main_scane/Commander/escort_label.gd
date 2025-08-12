extends Label


func _process(delta: float) -> void:
	if $"../Escort".get_child_count() > 0:
		visible = true
		$"../Escort".visible = true
	else:
		visible = false
		$"../Escort".visible = false

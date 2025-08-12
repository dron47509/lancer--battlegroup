extends Label


func _process(delta: float) -> void:
	if $"../Feat".get_child_count() > 0:
		visible = true
		$"../Feat".visible = true
	else:
		visible = false
		$"../Feat".visible = false

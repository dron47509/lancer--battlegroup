extends Label


func _process(delta: float) -> void:
	if $"../Maneuver".get_child_count() > 0:
		visible = true
		$"../Maneuver".visible = true
	else:
		visible = false
		$"../Maneuver".visible = false

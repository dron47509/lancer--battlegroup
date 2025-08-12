extends Label


func _process(delta: float) -> void:
	if $"../Tactic".get_child_count() > 0:
		visible = true
		$"../Tactic".visible = true
	else:
		visible = false
		$"../Tactic".visible = false

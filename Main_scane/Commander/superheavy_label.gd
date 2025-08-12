extends Label


func _process(delta: float) -> void:
	if $"../Superheavy".get_child_count() > 0:
		visible = true
		$"../Superheavy".visible = true
	else:
		visible = false
		$"../Superheavy".visible = false

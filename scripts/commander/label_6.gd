extends Label

func _process(delta: float) -> void:
	if text == "":
		text = "Положительная"

func _on_button_pressed() -> void:
	if text == "Положительная":
		$"../Positive3".text = ""
	else:
		$"../Positive3".text = text
	$"../Positive3".show()
	$"../Positive3".grab_focus()
	$"../Positive3".set_caret_column($"../Positive3".text.length())
	hide()

func _on_name_text_submitted(new_text: String) -> void:
	text = $"../Positive3".text
	$"../Positive3".hide()
	show()

func _on_name_focus_exited() -> void:
	text = $"../Positive3".text
	$"../Positive3".hide()
	show()

func _on_positive_3_mouse_exited() -> void:
	text = $"../Positive3".text
	$"../Positive3".hide()
	show()

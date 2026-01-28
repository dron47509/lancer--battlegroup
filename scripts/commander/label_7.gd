extends Label

func _process(delta: float) -> void:
	if text == "":
		text = "Отрицательная"

func _on_button_pressed() -> void:
	if text == "Отрицательная":
		$"../Negative2".text = ""
	else:
		$"../Negative2".text = text
	$"../Negative2".show()
	$"../Negative2".grab_focus()
	$"../Negative2".set_caret_column($"../Negative2".text.length())
	hide()

func _on_name_text_submitted(new_text: String) -> void:
	text = $"../Negative2".text
	$"../Negative2".hide()
	show()

func _on_name_focus_exited() -> void:
	text = $"../Negative2".text
	$"../Negative2".hide()
	show()

func _on_negative_2_mouse_exited() -> void:
	text = $"../Negative2".text
	$"../Negative2".hide()
	show()

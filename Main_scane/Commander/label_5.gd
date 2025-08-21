extends Label

func _process(delta: float) -> void:
	if text == "":
		text = "Отрицательная"

func _on_button_pressed() -> void:
	if text == "Отрицательная":
		$"../Negative".text = ""
	else:
		$"../Negative".text = text
	$"../Negative".show()
	$"../Negative".grab_focus()
	$"../Negative".set_caret_column($"../Negative".text.length())
	hide()

func _on_name_text_submitted(new_text: String) -> void:
	text = $"../Negative".text
	$"../Negative".hide()
	show()


func _on_name_focus_exited() -> void:
	text = $"../Negative".text
	$"../Negative".hide()
	show()


func _on_positive_1_mouse_exited() -> void:
	text = $"../Negative".text
	$"../Negative".hide()
	show()

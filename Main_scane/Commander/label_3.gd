extends Label

func _process(delta: float) -> void:
	if text == "":
		text = "Положительная"


func _on_button_pressed() -> void:
	if text == "Положительная":
		$"../Positive1".text = ""
	else:
		$"../Positive1".text = text
	$"../Positive1".show()
	$"../Positive1".grab_focus()
	$"../Positive1".set_caret_column($"../Positive1".text.length())
	hide()

func _on_name_text_submitted(new_text: String) -> void:
	text = $"../Positive1".text
	$"../Positive1".hide()
	show()


func _on_name_focus_exited() -> void:
	text = $"../Positive1".text
	$"../Positive1".hide()
	show()




func _on_positive_1_mouse_exited() -> void:
	text = $"../Positive1".text
	$"../Positive1".hide()
	show()

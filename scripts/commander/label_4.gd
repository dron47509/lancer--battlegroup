extends Label

func _process(delta: float) -> void:
	if text == "":
		text = "Положительная"

func _on_button_pressed() -> void:
	if text == "Положительная":
		$"../Positive2".text = ""
	else:
		$"../Positive2".text = text
	$"../Positive2".show()
	$"../Positive2".grab_focus()
	$"../Positive2".set_caret_column($"../Positive2".text.length())
	hide()

func _on_name_text_submitted(new_text: String) -> void:
	text = $"../Positive2".text
	$"../Positive2".hide()
	show()


func _on_positive_2_mouse_exited() -> void:
	text = $"../Positive2".text
	$"../Positive2".hide()
	show()


func _on_positive_2_focus_exited() -> void:
	text = $"../Positive2".text
	$"../Positive2".hide()
	show()

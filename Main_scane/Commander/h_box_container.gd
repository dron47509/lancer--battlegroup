extends HBoxContainer


func _on_button_pressed() -> void:
	$Name.text = $Label.text
	$Name.show()
	$Name.grab_focus()
	$Name.set_caret_column($Name.text.length())
	$Label.hide()

func _on_name_text_submitted(new_text: String) -> void:
	$Label.text = $Name.text
	$Name.hide()
	$Label.show()


func _on_name_focus_exited() -> void:
	$Label.text = $Name.text
	$Name.hide()
	$Label.show()


func _on_name_mouse_exited() -> void:
	$Label.text = $Name.text
	$Name.hide()
	$Label.show()

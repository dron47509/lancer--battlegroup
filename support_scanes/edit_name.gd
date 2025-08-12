extends HBoxContainer

func _on_button_pressed() -> void:
	if $VBoxContainer/Label.visible != false:
		$VBoxContainer/Label.visible = false
		$VBoxContainer/LineEdit.visible = true
	else:
		$VBoxContainer/Label.text = $VBoxContainer/LineEdit.text
		
		$VBoxContainer/Label.visible = true
		$VBoxContainer/LineEdit.visible = false
		

func _on_line_edit_text_submitted(new_text: String) -> void:
	$VBoxContainer/Label.text = new_text
	
	$VBoxContainer/Label.visible = true
	$VBoxContainer/LineEdit.visible = false

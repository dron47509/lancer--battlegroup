extends VBoxContainer

func _process(delta: float) -> void:
	if $Label3.text == "":
		$Label3.text = "Имя персонажа"

func _on_button_pressed() -> void:
	if $Label3.text == "Имя персонажа":
		$NameComander.text = ""
	else :
		$NameComander.text = $Label3.text
	$NameComander.show()
	$NameComander.grab_focus()
	$NameComander.set_caret_column($NameComander.text.length())
	$Label3.hide()

func _on_name_comander_text_submitted(new_text: String) -> void:
	$Label3.text = $NameComander.text
	$NameComander.hide()
	$Label3.show()


func _on_name_comander_focus_exited() -> void:
	$Label3.text = $NameComander.text
	$NameComander.hide()
	$Label3.show()


func _on_name_comander_mouse_exited() -> void:
	$Label3.text = $NameComander.text
	$NameComander.hide()
	$Label3.show()

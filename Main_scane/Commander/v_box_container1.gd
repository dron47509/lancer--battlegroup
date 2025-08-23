extends VBoxContainer

func _process(delta: float) -> void:
	if $Label3.text == "":
		$Label3.text = "Имя персонажа"

func _on_button_pressed() -> void:
	if $Label3.text == "Имя персонажа":
                $NameCommander.text = ""
	else :
                $NameCommander.text = $Label3.text
        $NameCommander.show()
        $NameCommander.grab_focus()
        $NameCommander.set_caret_column($NameCommander.text.length())
	$Label3.hide()

func _on_NameCommander_text_submitted(new_text: String) -> void:
        $Label3.text = $NameCommander.text
        $NameCommander.hide()
	$Label3.show()


func _on_NameCommander_focus_exited() -> void:
        $Label3.text = $NameCommander.text
        $NameCommander.hide()
	$Label3.show()


func _on_NameCommander_mouse_exited() -> void:
        $Label3.text = $NameCommander.text
        $NameCommander.hide()
	$Label3.show()

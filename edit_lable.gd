extends VBoxContainer

@onready var label = $Label
@onready var text_edit = $LineEdit

func _on_button_pressed() -> void:
	text_edit.text = label.text
	label.visible = false
	text_edit.visible = true
	text_edit.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	label.text = text_edit.text
	label.visible = true
	text_edit.visible = false


func _on_line_edit_focus_exited() -> void:
	label.text = text_edit.text
	label.visible = true
	text_edit.visible = false

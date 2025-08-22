extends VBoxContainer


var parent_node
var text

@onready var _text = $TextEdit

func _on_button_pressed() -> void:
	parent_node.text = $TextEdit.text
	$"../Commander_interface".visible = true
	visible = false


func _on_visibility_changed() -> void:
	if visible == true:
		$HBoxContainer/Label.text = text
		_text.text = parent_node.text 


func _on_text_edit_text_changed() -> void:
	BattlegroupData.commander["backstory"] = $TextEdit.text
	BattlegroupData.save_data()

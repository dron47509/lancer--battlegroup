extends VBoxContainer


var parent_node
var text

func _on_button_pressed() -> void:
	parent_node.text = $TextEdit.text
	$"../ScrollContainer".visible = true
	visible = false


func _on_visibility_changed() -> void:
	if visible == true:
		$HBoxContainer/Label.text = text
		$TextEdit.text = parent_node.text 

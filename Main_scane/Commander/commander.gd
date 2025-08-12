extends HBoxContainer

var old_node
signal change_scene(parent_node)

func _ready() -> void:
	pass


func _on_button_pressed() -> void:
	emit_signal("change_scene", $VBoxContainer/RichTextLabel)

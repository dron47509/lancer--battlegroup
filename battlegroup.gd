extends Control

@onready var note = $Note
@onready var main = $ScrollContainer
	


func _on_commander_change_scene(parent_node) -> void:
	note.parent_node = parent_node
	note.text = "Предыстория"
	main.visible = false
	note.visible = true

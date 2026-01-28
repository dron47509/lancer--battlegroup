@tool
extends EditorScript

const SCENES := [
	"res://scenes/option_list/option_list.tscn",
	"res://scenes/option_list/legacies_list.tscn",
	"res://scenes/option_list/reputations_list.tscn",
	"res://scenes/hull_list/Hulls_list.tscn",
]

func _run() -> void:
	for path in SCENES:
		await _bake_scene(path)
	print("Bake complete")

func _bake_scene(path: String) -> void:
	var tree := _get_editor_tree()
	if tree == null:
		push_error("Bake failed, editor tree unavailable")
		return
	var packed = load(path)
	if packed == null:
		push_error("Bake failed, missing scene: %s" % path)
		return
	var root = packed.instantiate()
	var temp = Node.new()
	tree.root.add_child(temp)
	temp.add_child(root)
	await tree.process_frame
	if root.has_method("bake_rebuild"):
		root.bake_rebuild()
	_set_owner_recursive(root, root)

	var out = PackedScene.new()
	var ok = out.pack(root)
	if ok != OK:
		push_error("Bake failed to pack: %s" % path)
	else:
		var err = ResourceSaver.save(out, path)
		if err != OK:
			push_error("Bake failed to save: %s" % path)

	temp.queue_free()

func _get_editor_tree() -> SceneTree:
	var base := get_editor_interface().get_base_control()
	if base == null:
		return null
	return base.get_tree()

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)

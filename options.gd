extends HBoxContainer



func _ready() -> void:
        for x in get_children():
                if x.get_child_count() > 1:
                        if x.get_child(1).text == "0":
                                x.visible = false
                        else:
                                x.visible = true
                else:
                        push_warning("%s has no second child; skipping" % x.name)

extends VBoxContainer



func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var ok = typeof(data) == TYPE_DICTIONARY and data.has("panel")
	print(">>> can_drop_data? ", ok, " at pos ", at_position)   # DEBUG
	return ok

func _drop_data(at_position: Vector2, data: Variant) -> void:
	print(">>> Dropped on VBox at ", at_position, " with panel: ", data["panel"].name)
	var panel: Control = data["panel"]

	var idx := get_child_count()
	for i in range(get_child_count()):
		var child := get_child(i)
		if at_position.y < child.position.y + child.size.y * 0.5:
			idx = i
			break

	if panel.get_parent() == self:
		remove_child(panel)
		add_child(panel)
		move_child(panel, idx)

	#% Update indices after final position is known:
	for i in range(get_child_count()):
		var child := get_child(i)
		if child.has_node("HBox/Index"):
			child.get_node("HBox/Index").text = str(i)


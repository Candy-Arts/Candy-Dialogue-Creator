extends Tree

@onready var main = get_node("/root/MainUI")



func _get_drag_data(at_position: Vector2) -> Variant:
	var item = get_item_at_position(at_position)
	if item == null:
		return null

	var preview
	if main.sort_dialogue:
		#% Only drag one item at a time in sort mode:
		preview = Label.new()
		preview.text = item.get_text(0)
		set_drag_preview(preview)
		drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
		#% Store whether it's a conversation or block:
		var is_block = item.get_parent() != get_root()
		return {"sort_mode": true, "text": item.get_text(0), "is_block": is_block, "conv": item.get_parent().get_text(0) if is_block else ""}

	#% Normal line drag:
	var indices: Array = []
	var selected = get_next_selected(null)
	while selected != null:
		indices.append(selected.get_metadata(0))
		selected = get_next_selected(selected)

	if not item.get_metadata(0) in indices:
		indices = [item.get_metadata(0)]

	preview = Label.new()
	preview.text = str(indices.size()) + " line(s)"
	set_drag_preview(preview)
	drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	return {"indices": indices}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	var section
	if main.sort_dialogue and data.has("sort_mode"):
		var target = get_item_at_position(at_position)
		if target == null:
			return false
		section = get_drop_section_at_position(at_position)
		var target_is_block = target.get_parent() != get_root()

		if data["is_block"]:
			#% Block can drop between blocks or on a conversation:
			return true
		else:
			#% Conversation can only drop between conversations (not on blocks):
			return not target_is_block and section != 0

	if not data.has("indices"):
		return false
	section = get_drop_section_at_position(at_position)
	return get_item_at_position(at_position) != null and section != 0


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var section
	if main.sort_dialogue and data.has("sort_mode"):
		var target = get_item_at_position(at_position)
		if target == null:
			return
		section = get_drop_section_at_position(at_position)
		var target_is_block = target.get_parent() != get_root()
		var dragged_name: String = data["text"]
		var is_block: bool = data["is_block"]
		if is_block:
			_drop_block(dragged_name, data["conv"], target, target_is_block, section)
		else:
			_drop_conversation(dragged_name, target, section)
		globals.current_line = -1
		drop_mode_flags = 0
		main.save_undo_step()
		main.call_deferred("update_line_list")
		return

	#% Normal line drop:
	var target_item = get_item_at_position(at_position)
	if target_item == null:
		return
	var indices: Array = data["indices"]
	var to_index: int = target_item.get_metadata(0)
	section = get_drop_section_at_position(at_position)
	var source: Dictionary = {}
	if globals.current_conversation == "USER PRESETS":
		source = globals.user_presets
	elif globals.current_conversation == "PROFILE PRESETS":
		source = globals.profile_presets
	else:
		source = globals.dialogue
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	indices.sort()
	var moved_lines: Array = []
	for i in indices:
		moved_lines.append(lines[i])
	for i in range(indices.size() - 1, -1, -1):
		lines.remove_at(indices[i])
	var removed_before = 0
	for i in indices:
		if i < to_index:
			removed_before += 1
	to_index -= removed_before
	if section == 1:
		to_index += 1
	to_index = clamp(to_index, 0, lines.size())
	for i in range(moved_lines.size()):
		lines.insert(to_index + i, moved_lines[i])
	globals.current_line = to_index
	globals.current_line_type = lines[to_index].keys()[0]
	drop_mode_flags = 0
	main.save_undo_step()
	get_node("/root/MainUI").call_deferred("update_line_list")


func _drop_conversation(conv_name: String, target: TreeItem, section: int) -> void:
	var dialogue = globals.dialogue
	var target_name = target.get_text(0)

	#% Extract all keys and values:
	var keys = dialogue.keys()
	var values = dialogue.values()
	var from_idx = keys.find(conv_name)
	var to_idx = keys.find(target_name)

	if from_idx == -1 or to_idx == -1 or from_idx == to_idx:
		return

	#% Remove from original position:
	keys.remove_at(from_idx)
	values.remove_at(from_idx)

	#% Adjust to_idx:
	if to_idx > from_idx:
		to_idx -= 1
	if section == 1:
		to_idx += 1
	to_idx = clamp(to_idx, 0, keys.size())

	keys.insert(to_idx, conv_name)
	values.insert(to_idx, globals.dialogue[conv_name])

	#% Rebuild dialogue:
	globals.dialogue.clear()
	for i in range(keys.size()):
		globals.dialogue[keys[i]] = values[i]

	main.update_conversation_selector(true)


func _drop_block(block_name: String, source_conv: String, target: TreeItem, target_is_block: bool, section: int) -> void:
	var dialogue = globals.dialogue

	#% Validate source:
	if source_conv == "" or not dialogue.has(source_conv) or not dialogue[source_conv].has(block_name):
		return

	#% Determine target conversation and position:
	var target_conv := ""
	var target_block := ""
	if target_is_block:
		target_conv = target.get_parent().get_text(0)
		target_block = target.get_text(0)
	else:
		target_conv = target.get_text(0)
		target_block = ""

	#% Handle name conflict:
	var final_name = block_name
	if target_conv != source_conv and dialogue[target_conv].has(final_name):
		final_name = main._resolve_block_name_conflict(final_name, target_conv)

	#% Remove from source:
	var block_data = dialogue[source_conv][block_name]
	var source_keys = dialogue[source_conv].keys()
	var source_values = dialogue[source_conv].values()
	var from_idx = source_keys.find(block_name)
	source_keys.remove_at(from_idx)
	source_values.remove_at(from_idx)
	dialogue[source_conv].clear()
	for i in range(source_keys.size()):
		dialogue[source_conv][source_keys[i]] = source_values[i]

	#% Insert into target conversation:
	var target_keys = dialogue[target_conv].keys()
	var target_values = dialogue[target_conv].values()
	var to_idx = 0
	if target_block != "":
		to_idx = target_keys.find(target_block)
		if to_idx == -1:
			to_idx = target_keys.size()
		elif section == 1:
			to_idx += 1
	else:
		to_idx = target_keys.size()

	target_keys.insert(to_idx, final_name)
	target_values.insert(to_idx, block_data)
	dialogue[target_conv].clear()
	for i in range(target_keys.size()):
		dialogue[target_conv][target_keys[i]] = target_values[i]

	main.update_block_selector(false)

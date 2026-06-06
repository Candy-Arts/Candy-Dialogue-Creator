extends Tree

@onready var main = get_node("/root/MainUI")

func _get_drag_data(at_position: Vector2) -> Variant:
	var item = get_item_at_position(at_position)
	if item == null:
		return null
	var meta = item.get_metadata(0)
	if meta["type"] != "choice" and meta["type"] != "category" and meta["type"] != "timer":
		return null
	var preview = Label.new()
	preview.text = meta["name"]
	set_drag_preview(preview)
	drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	return {"type": meta["type"], "name": meta["name"], "category": meta.get("category", "")}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not data.has("type"):
		return false
	var target = get_item_at_position(at_position)
	if target == null:
		return false
	var target_meta = target.get_metadata(0)
	match data["type"]:
		"choice":
			return target_meta["type"] == "choice" or target_meta["type"] == "category"
		"category":
			return target_meta["type"] == "category"
		"timer":
			return target_meta["type"] == "timer"
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target = get_item_at_position(at_position)
	if target == null:
		return
	var target_meta = target.get_metadata(0)
	var section = get_drop_section_at_position(at_position)

	var line_data = main._get_choice_list_data()
	if line_data.is_empty():
		return

	match data["type"]:
		"choice":
			_drop_choice(data, target_meta, section, line_data)
		"category":
			_drop_category(data, target_meta, section, line_data)
		"timer":
			_drop_timer(data, target_meta, section, line_data)

	drop_mode_flags = 0
	main.refresh_choice_tree()


func _drop_choice(data: Dictionary, target_meta: Dictionary, section: int, line_data: Dictionary) -> void:
	var source_choice = data["name"]
	var source_category = data["category"]
	var target_category = target_meta["name"] if target_meta["type"] == "category" else target_meta["category"]

	var choice_data = null
	for category_entry in line_data["Categories"]:
		if category_entry.keys()[0] == source_category:
			var choices = category_entry[source_category]["Choices"]
			for i in range(choices.size()):
				if choices[i].keys()[0] == source_choice:
					choice_data = choices[i]
					choices.remove_at(i)
					break
			break

	if choice_data == null:
		return

	var final_name = source_choice
	for category_entry in line_data["Categories"]:
		if category_entry.keys()[0] == target_category:
			var existing_names = []
			for c in category_entry[target_category]["Choices"]:
				existing_names.append(c.keys()[0])
			if existing_names.has(final_name):
				var suffix = 1
				while existing_names.has(final_name + "_(" + str(suffix) + ")"):
					suffix += 1
				var old_data = choice_data[source_choice]
				choice_data.erase(source_choice)
				final_name = source_choice + "_(" + str(suffix) + ")"
				choice_data[final_name] = old_data

			var choices = category_entry[target_category]["Choices"]
			var target_index = choices.size()
			if target_meta["type"] == "choice" and target_meta["category"] == target_category:
				for i in range(choices.size()):
					if choices[i].keys()[0] == target_meta["name"]:
						target_index = i
						if section == 1:
							target_index += 1
						break
			choices.insert(target_index, choice_data)
			break

	drop_mode_flags = 0
	main.save_undo_step()
	main.refresh_choice_tree()


func _drop_category(data: Dictionary, target_meta: Dictionary, section: int, line_data: Dictionary) -> void:
	var source_name = data["name"]
	var categories = line_data["Categories"]

	var from_idx = -1
	for i in range(categories.size()):
		if categories[i].keys()[0] == source_name:
			from_idx = i
			break
	if from_idx == -1:
		return

	var category_data = categories[from_idx]
	categories.remove_at(from_idx)

	var to_idx = -1
	for i in range(categories.size()):
		if categories[i].keys()[0] == target_meta["name"]:
			to_idx = i
			break
	if to_idx == -1:
		to_idx = categories.size()
	elif section == 1:
		to_idx += 1

	to_idx = clamp(to_idx, 0, categories.size())
	categories.insert(to_idx, category_data)

	drop_mode_flags = 0
	main.save_undo_step()
	main.refresh_choice_tree()


func _drop_timer(data: Dictionary, target_meta: Dictionary, section: int, line_data: Dictionary) -> void:
	var source_name = data["name"]
	var timers = line_data["Timers"]

	var from_idx = -1
	for i in range(timers.size()):
		if timers[i].keys()[0] == source_name:
			from_idx = i
			break
	if from_idx == -1:
		return

	var timer_data = timers[from_idx]
	timers.remove_at(from_idx)

	var to_idx = -1
	for i in range(timers.size()):
		if timers[i].keys()[0] == target_meta["name"]:
			to_idx = i
			break
	if to_idx == -1:
		to_idx = timers.size()
	elif section == 1:
		to_idx += 1

	to_idx = clamp(to_idx, 0, timers.size())
	timers.insert(to_idx, timer_data)

	drop_mode_flags = 0
	main.save_undo_step()
	main.refresh_choice_tree()
extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var file = get_node("Menu/VBox/File/Path/File")
@onready var export_tree = get_node("Menu/VBox/Options/Tree")
@onready var mode_1 = get_node("Menu/VBox/Options/Controls/Mode1")
@onready var mode_2 = get_node("Menu/VBox/Options/Controls/Mode2")
@onready var error = get_node("Menu/VBox/Error")



#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


#* Populate the tree:
func spawn_convo_tree() -> void:
	export_tree.clear()
	export_tree.set_column_titles_visible(false)
	export_tree.set_column_expand(0, false)
	export_tree.set_column_custom_minimum_width(0, 32)
	export_tree.hide_root = true
	var root = export_tree.create_item()

	for conv_name in globals.dialogue.keys():
		var conv_item = export_tree.create_item(root)
		conv_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		conv_item.set_checked(0, true)
		conv_item.set_editable(0, true)
		conv_item.set_text(1, conv_name)

		for block_name in globals.dialogue[conv_name].keys():
			var block_item = export_tree.create_item(conv_item)
			block_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			block_item.set_checked(0, true)
			block_item.set_editable(0, true)
			block_item.set_text(1, block_name)


#* Export the dialogue:
func export_dialogue() -> void:
	#@ Step 1 - Get export path:
	var path: String = file.text.strip_edges()
	if not path.ends_with(".txt"):
		error.text = "No valid .txt file selected."
		return

	#@ Step 2 - Get checked items:
	var checked = _get_checked_items()
	if checked.is_empty():
		error.text = "No conversations selected."
		return

	#@ Step 3 - Get modes:
	var primary_mode: String = mode_1.get_item_text(mode_1.selected)
	var secondary_mode: String = mode_2.get_item_text(mode_2.selected)

	#@ Step 4 - Load existing file if present:
	var existing_dialogue: Dictionary = {}
	if FileAccess.file_exists(path):
		var f1 := FileAccess.open(path, FileAccess.READ)
		if f1:
			var raw = f1.get_as_text()
			f1.close()
			#% Strip comment lines:
			var lines = raw.split("\n")
			var cleaned = []
			for line in lines:
				if not line.strip_edges().begins_with("\u0023"):
					cleaned.append(line)
			raw = "\n".join(cleaned)
			var parsed = str_to_var(raw)
			if parsed is Dictionary and parsed.has("Dialogue"):
				existing_dialogue = parsed["Dialogue"]

	#@ Step 5 - Build output based on modes:
	var output_data: Dictionary = {}
	if primary_mode == "Overwrite":
		#% Export only checked conversations and their checked blocks:
		for conv_name in checked.keys():
			output_data[conv_name] = {}
			for block_name in checked[conv_name]:
				output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name]
	else:
		output_data = existing_dialogue.duplicate(true)
		for conv_name in checked.keys():
			var conv_in_file = output_data.has(conv_name)
			match secondary_mode:
				"Conversations":
					match primary_mode:
						"Add":
							if not conv_in_file:
								output_data[conv_name] = globals.dialogue[conv_name].duplicate(true)
						"Update":
							if conv_in_file:
								output_data[conv_name] = globals.dialogue[conv_name].duplicate(true)
						"Add & Update":
							output_data[conv_name] = globals.dialogue[conv_name].duplicate(true)
				"Blocks":
					if not conv_in_file:
						continue
					for block_name in checked[conv_name]:
						var block_in_file = output_data[conv_name].has(block_name)
						match primary_mode:
							"Add":
								if not block_in_file:
									output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)
							"Update":
								if block_in_file:
									output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)
							"Add & Update":
								output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)
				"All":
					match primary_mode:
						"Add":
							if not conv_in_file:
								output_data[conv_name] = globals.dialogue[conv_name].duplicate(true)
							else:
								for block_name in checked[conv_name]:
									if not output_data[conv_name].has(block_name):
										output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)
						"Update":
							if conv_in_file:
								for block_name in checked[conv_name]:
									if output_data[conv_name].has(block_name):
										output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)
						"Add & Update":
							if not conv_in_file:
								output_data[conv_name] = globals.dialogue[conv_name].duplicate(true)
							else:
								for block_name in checked[conv_name]:
									output_data[conv_name][block_name] = globals.dialogue[conv_name][block_name].duplicate(true)

	#@ Step 6 - Remove variants with no text:
	_clean_variants(output_data)

	#@ Step 7 - Wrap with metadata and write:
	var ascii_hash := "\u0023"
	var final_export: Dictionary = {
		"Meta": {
			"Exported By": "Candy Dialogue Creator",
			"Creator Version": globals.dc_version,
			"Dialogue Version": globals.dialogue_version,
		},
		"Dialogue": output_data
	}
	var f2 := FileAccess.open(path, FileAccess.WRITE)
	if f2 == null:
		error.text = "Failed to open file for writing."
		return
	f2.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
	f2.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
	f2.store_string(ascii_hash + " Dialogue Version: " + str(globals.dialogue_version) + "\n\n")
	f2.store_string(main._pretty_var(final_export))
	f2.close()
	print("Export completed: ", primary_mode, " (", secondary_mode, ") → ", path)
	_on_cancel_pressed()
	main.show_warning("Dialogue exported to " + path)

#* Strip empty variants and legacy keys from export data:
func _clean_variants(data: Dictionary) -> void:
	for conv in data.values():
		for block in conv.values():
			for i in range(block["Text"].size()):
				var entry = block["Text"][i]
				var line_type = entry.keys()[0]
				if line_type != "Spoken Line":
					continue
				var spoken_line = entry["Spoken Line"]
				var cleaned_variants := []
				for variant_dict in spoken_line.get("Variants", []):
					for variant_name in variant_dict.keys():
						var text_val := str(variant_dict[variant_name].get("Text", "")).strip_edges()
						if text_val != "":
							variant_dict[variant_name].erase("Enabled")
							variant_dict[variant_name].erase("Auto")
							cleaned_variants.append(variant_dict)
						break
				spoken_line["Variants"] = cleaned_variants


#* Collect checked Conversations/Blocks in an array for export:
func _get_checked_items() -> Dictionary:
	var result: Dictionary = {}
	var root = export_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		if conv_item.is_checked(0):
			var conv_name = conv_item.get_text(1)
			result[conv_name] = []
			var block_item = conv_item.get_first_child()
			while block_item != null:
				if block_item.is_checked(0):
					result[conv_name].append(block_item.get_text(1))
				block_item = block_item.get_next()
		conv_item = conv_item.get_next()
	return result


#* Mark all Conversations and Blocks:
func _on_mark_all_pressed() -> void:
	var root = export_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, true)
		var block = conv_item.get_first_child()
		while block != null:
			block.set_checked(0, true)
			block = block.get_next()
		conv_item = conv_item.get_next()


#* Unmark all Conversations and Blocks:
func _on_unmark_all_pressed() -> void:
	var root = export_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, false)
		var block = conv_item.get_first_child()
		while block != null:
			block.set_checked(0, false)
			block = block.get_next()
		conv_item = conv_item.get_next()


#* Mark all Conversations only:
func _on_mark_conv_pressed() -> void:
	var root = export_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, true)
		conv_item = conv_item.get_next()


#* Unmark all Conversations only: 
func _on_unmark_conv_pressed() -> void:
	var root = export_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, false)
		conv_item = conv_item.get_next()


#* Mark all Blocks in the selected Conversation:
func _on_mark_blocks_pressed() -> void:
	var selected = export_tree.get_selected()
	if selected == null:
		return
	#% If a block is selected, use its parent conversation:
	var conv_item = selected if selected.get_parent() == export_tree.get_root() else selected.get_parent()
	var block = conv_item.get_first_child()
	while block != null:
		block.set_checked(0, true)
		block = block.get_next()


#* Unmark all Blocks in the selected Conversation:
func _on_unmark_blocks_pressed() -> void:
	var selected = export_tree.get_selected()
	if selected == null:
		return
	var conv_item = selected if selected.get_parent() == export_tree.get_root() else selected.get_parent()
	var block = conv_item.get_first_child()
	while block != null:
		block.set_checked(0, false)
		block = block.get_next()


#* Open file browser:
func _on_file_browser_pressed() -> void:
	var dialogues_path = globals.project_path.path_join(globals.custom_project_paths.get("Dialogues", ""))
	if dialogues_path != "" and DirAccess.dir_exists_absolute(dialogues_path):
		main.export_dialogue.current_path = dialogues_path + "/"
	elif globals.project_path != "" and DirAccess.dir_exists_absolute(globals.project_path):
		main.export_dialogue.current_path = globals.project_path + "/"
	else:
		main.export_dialogue.current_path = "user://"
	main.shield.visible = true
	if main.export_dialogue.current_file == "":
		main.export_dialogue.current_file = ".txt"
	main.export_dialogue.visible = true


#* Export button pressed → display prompt:
func _on_export_pressed() -> void:
	main.prompt_menu.setup("Export")


#* Cancel:
func _on_cancel_pressed() -> void:
	globals.editor_state = "Main"
	self.visible = false
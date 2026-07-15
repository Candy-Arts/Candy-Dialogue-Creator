extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var file = get_node("Menu/VBox/File/Path/File")
@onready var import_tree = get_node("Menu/VBox/Options/Tree")
@onready var mode_1 = get_node("Menu/VBox/Options/Controls/Mode1")
@onready var mode_2 = get_node("Menu/VBox/Options/Controls/Mode2")
@onready var error = get_node("Menu/VBox/Error")

var imported_dialogue: Dictionary = {}

#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


#* Load file and populate tree:
func load_file(path: String) -> void:
	imported_dialogue.clear()
	import_tree.clear()

	if not FileAccess.file_exists(path):
		error.text = "File not found."
		return

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		error.text = "Failed to open file."
		return

	var raw := f.get_as_text()
	f.close()

	#@ Strip comment lines:
	var lines = raw.split("\n")
	var cleaned = []
	for line in lines:
		if not line.strip_edges().begins_with("\u0023"):
			cleaned.append(line)
	raw = "\n".join(cleaned)

	var parsed = str_to_var(raw)

	if not parsed is Dictionary or not parsed.has("Dialogue"):
		error.text = "Invalid file format."
		return

	var version := str(parsed.get("Meta", {}).get("Dialogue Version", parsed.get("Dialogue Version", "unknown"))).strip_edges()
	if version != globals.dialogue_version:
		error.text = "Wrong version: " + version
		main.show_warning("[color=yellow]The selected file uses the " + version + " format. Please use the Converter tool to convert it to 1.1 format.[/color]")
		return

	imported_dialogue = parsed["Dialogue"]
	error.text = ""
	spawn_convo_tree()


#* Populate the tree from imported_dialogue:
func spawn_convo_tree() -> void:
	import_tree.clear()
	import_tree.columns = 2
	import_tree.set_column_titles_visible(false)
	import_tree.set_column_expand(0, false)
	import_tree.set_column_custom_minimum_width(0, 32)
	import_tree.hide_root = true
	var root = import_tree.create_item()

	for conv_name in imported_dialogue.keys():
		var conv_item = import_tree.create_item(root)
		conv_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		conv_item.set_checked(0, true)
		conv_item.set_editable(0, true)
		conv_item.set_text(1, conv_name)

		for block_name in imported_dialogue[conv_name].keys():
			var block_item = import_tree.create_item(conv_item)
			block_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			block_item.set_checked(0, true)
			block_item.set_editable(0, true)
			block_item.set_text(1, block_name)


#* Update tree when file path is submitted or focus lost:
func _on_file_text_submitted(new_text: String) -> void:
	load_file(new_text.strip_edges())

func _on_file_focus_exited() -> void:
	load_file(file.text.strip_edges())


#* Import the dialogue:
func import_dialogue() -> void:
	var path: String = file.text.strip_edges()
	if not path.ends_with(".txt"):
		error.text = "No valid .txt file selected."
		return

	if imported_dialogue.is_empty():
		error.text = "No file loaded."
		return

	var checked = _get_checked_items()
	if checked.is_empty():
		error.text = "No conversations selected."
		return

	var primary_mode: String = mode_1.get_item_text(mode_1.selected)
	var secondary_mode: String = mode_2.get_item_text(mode_2.selected)

	if primary_mode == "Overwrite":
		globals.dialogue.clear()
		for conv_name in checked.keys():
			globals.dialogue[conv_name] = {}
			for block_name in checked[conv_name]:
				globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)

	else:
		for conv_name in checked.keys():
			var conv_in_dialogue = globals.dialogue.has(conv_name)

			match secondary_mode:
				"Conversations":
					match primary_mode:
						"Add":
							if not conv_in_dialogue:
								globals.dialogue[conv_name] = imported_dialogue[conv_name].duplicate(true)
						"Update":
							if conv_in_dialogue:
								globals.dialogue[conv_name] = imported_dialogue[conv_name].duplicate(true)
						"Add & Update":
							globals.dialogue[conv_name] = imported_dialogue[conv_name].duplicate(true)

				"Blocks":
					if not conv_in_dialogue:
						continue
					for block_name in checked[conv_name]:
						var block_in_dialogue = globals.dialogue[conv_name].has(block_name)
						match primary_mode:
							"Add":
								if not block_in_dialogue:
									globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)
							"Update":
								if block_in_dialogue:
									globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)
							"Add & Update":
								globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)

				"All":
					match primary_mode:
						"Add":
							if not conv_in_dialogue:
								globals.dialogue[conv_name] = imported_dialogue[conv_name].duplicate(true)
							else:
								for block_name in checked[conv_name]:
									if not globals.dialogue[conv_name].has(block_name):
										globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)
						"Update":
							if conv_in_dialogue:
								for block_name in checked[conv_name]:
									if globals.dialogue[conv_name].has(block_name):
										globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)
						"Add & Update":
							if not conv_in_dialogue:
								globals.dialogue[conv_name] = imported_dialogue[conv_name].duplicate(true)
							else:
								for block_name in checked[conv_name]:
									globals.dialogue[conv_name][block_name] = imported_dialogue[conv_name][block_name].duplicate(true)

	#@ Import languages and variants from imported dialogue:
	var keys := []
	for conv_name in checked.keys():
		if not globals.dialogue.has(conv_name):
			continue
		for block in globals.dialogue[conv_name].values():
			for line_entry in block.get("Text", []):
				var line_type = line_entry.keys()[0]
				if line_type == "Spoken Line":
					for entry in line_entry["Spoken Line"].get("Variants", []):
						keys.append(entry.keys()[0])
				elif line_type in ["§If", "§Elif", "§Else", "§For", "§While"]:
					var commands = line_entry[line_type].get("Commands", {})
					if commands.has("Spoken Line"):
						for entry in commands["Spoken Line"].get("Variants", []):
							keys.append(entry.keys()[0])

	main._import_languages_from_keys(keys)
	main._populate_all_spoken_lines()

	main.update_conversation_selector(false)
	print("Import completed: ", primary_mode, " (", secondary_mode, ")")
	_on_cancel_pressed()
	main.update_line_list()
	main.save_undo_step()


#* Collect checked Conversations/Blocks in an array for import:
func _get_checked_items() -> Dictionary:
	var result: Dictionary = {}
	var root = import_tree.get_root()
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
	var root = import_tree.get_root()
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
	var root = import_tree.get_root()
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
	var root = import_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, true)
		conv_item = conv_item.get_next()

#* Unmark all Conversations only:
func _on_unmark_conv_pressed() -> void:
	var root = import_tree.get_root()
	var conv_item = root.get_first_child()
	while conv_item != null:
		conv_item.set_checked(0, false)
		conv_item = conv_item.get_next()

#* Mark all Blocks in the selected Conversation:
func _on_mark_blocks_pressed() -> void:
	var selected = import_tree.get_selected()
	if selected == null:
		return
	#% If a block is selected, use its parent conversation:
	var conv_item = selected if selected.get_parent() == import_tree.get_root() else selected.get_parent()
	var block = conv_item.get_first_child()
	while block != null:
		block.set_checked(0, true)
		block = block.get_next()

#* Unmark all Blocks in the selected Conversation:
func _on_unmark_blocks_pressed() -> void:
	var selected = import_tree.get_selected()
	if selected == null:
		return
	var conv_item = selected if selected.get_parent() == import_tree.get_root() else selected.get_parent()
	var block = conv_item.get_first_child()
	while block != null:
		block.set_checked(0, false)
		block = block.get_next()


#* Open file browser:
func _on_file_browser_pressed() -> void:
	var dialogues_path = globals.project_path.path_join(globals.custom_project_paths.get("Dialogues", ""))
	if dialogues_path != "" and DirAccess.dir_exists_absolute(dialogues_path):
		main.import_dialogue.current_path = dialogues_path + "/"
	elif globals.project_path != "" and DirAccess.dir_exists_absolute(globals.project_path):
		main.import_dialogue.current_path = globals.project_path + "/"
	else:
		main.import_dialogue.current_path = "user://"
	main.shield.visible = true
	main.import_dialogue.visible = true


#* Import button pressed → display prompt:
func _on_import_pressed() -> void:
	main.prompt_menu.setup("Import")


#* Cancel:
func _on_cancel_pressed() -> void:
	globals.editor_state = "Main"
	self.visible = false

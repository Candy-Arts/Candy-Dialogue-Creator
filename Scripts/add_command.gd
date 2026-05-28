extends Button


@onready var main = get_node("/root/MainUI")

@export var command = "§"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(func(): pass)
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		main.show_favorites_context_menu({"type": "command", "command": command})


#* Add line when button pressed:
func _on_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.current_conversation == "" or globals.current_block == "" or main.sort_dialogue == true:
		return

	#% Deep copy the template:
	var template = globals.line_templates.get(command, null)
	if template == null:
		return

	#% Determine target dictionary:
	var target: Dictionary = {}
	if globals.current_conversation == "USER PRESETS":
		target = globals.user_presets
	elif globals.current_conversation == "PROFILE PRESETS":
		target = globals.profile_presets
	else:
		target = globals.dialogue

	if not target.has(globals.current_conversation) or not target[globals.current_conversation].has(globals.current_block):
		return

	var lines = target[globals.current_conversation][globals.current_block]["Text"]
	var ctrl_held = Input.is_key_pressed(KEY_CTRL)
	var selected = main.selected_lines

	#% No selection - add at end or start:
	if selected.is_empty():
		var new_line = {command: template.duplicate(true)}
		if command == "Spoken Line":
			main._populate_spoken_line_variants(new_line["Spoken Line"])
		if ctrl_held:
			lines.insert(0, new_line)
		else:
			lines.append(new_line)

	#% Add after or before each selected line:
	else:
		var sorted = selected.duplicate()
		sorted.sort()

		#% Insert before each selected line, track offset:
		if ctrl_held:
			var offset = 0
			for i in sorted:
				var new_line = {command: template.duplicate(true)}
				if command == "Spoken Line":
					main._populate_spoken_line_variants(new_line["Spoken Line"])
				lines.insert(i + offset, new_line)
				offset += 1

		#% Insert after each selected line, reverse to preserve indices:
		else:
			sorted.reverse()
			for i in sorted:
				var new_line = {command: template.duplicate(true)}
				if command == "Spoken Line":
					main._populate_spoken_line_variants(new_line["Spoken Line"])
				lines.insert(i + 1, new_line)

	main.update_line_list()

	#% Deselect all and select newly added lines:
	main.line_tree.deselect_all()
	var new_indices: Array = []

	if selected.is_empty():
		if ctrl_held:
			new_indices = [0]
		else:
			new_indices = [lines.size() - 1]
	else:
		var sorted = selected.duplicate()
		sorted.sort()
		if ctrl_held:
			for i in range(sorted.size()):
				new_indices.append(sorted[i] + i)
		else:
			for i in range(sorted.size()):
				new_indices.append(sorted[i] + i + 1)

	#% Select new items in tree:
	var root = main.line_tree.get_root()
	if root:
		var child = root.get_first_child()
		while child != null:
			if child.get_metadata(0) in new_indices:
				child.select(0)
			child = child.get_next()

	#% Scroll to center the newly added line:
	if not new_indices.is_empty():
		if root:
			var child = root.get_first_child()
			while child != null:
				if child.get_metadata(0) == new_indices[0]:
					main.line_tree.scroll_to_item(child, true)
					break
				child = child.get_next()

	#% Set current line to lowest new index:
	new_indices.sort()
	if not new_indices.is_empty():
		globals.current_line = new_indices[0]
	main.selected_lines = new_indices

	#% Determine type of the current line:
	globals.current_line_type = lines[globals.current_line].keys()[0]

	#% Display the data for the line type:
	if globals.current_line != -1 and not main.sort_dialogue == true:
		main._suppress_undo_save = true
		main._show_line_editor()
		main._suppress_undo_save = false
	main.save_undo_step()

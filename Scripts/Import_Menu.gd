extends CanvasLayer

@onready var main = get_node("/root/UI")

@onready var file_field = get_node("Panel/VBox/File/LineEdit")
@onready var mode_select = get_node("Panel/VBox/HBox/Mode/OptionButton")
@onready var convo_list = get_node("Panel/VBox/Conversations/Scroll/VBox")
@onready var file_browser = get_node("FileDialog")
@onready var error_display = get_node("Panel/VBox/Warnings/RichTextLabel")


#* Conversations to export:
#% Leave empty.
var import_conversations = []


#* Called when Import Menu is opened:
func open_import_menu():
	#% Create Conversation buttons if a fiel is already selected:
	if file_field.text != "":
		spawn_convo_buttons(null)


#* Spawn a button for each conversation:
func spawn_convo_buttons(_new_text):
	#@ Step 1: Clear imported conversations list:
	import_conversations.clear()

	#@ Step 2: Clear all buttons:
	for button in convo_list.get_children():
		button.queue_free()

	await get_tree().process_frame

	#@ Step 3: Read file path:
	var path: String = file_field.text.strip_edges()
	if path == "":
		push_warning("No import file specified.")
		return
	if not path.ends_with(".txt"):
		push_warning("The import file must end with '.txt'.")
		return
	if not FileAccess.file_exists(path):
		push_warning("Import file not found: " + path)
		return

	#@ Step 4: Load text file:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open import file: " + path)
		return

	var text_data := file.get_as_text()
	file.close()

	#@ Step 5 - Clean and normalize exported syntax:
	text_data = text_data.replace("<null>", "null")
	text_data = text_data.replace("<Null>", "null")

	var regex_trailing := RegEx.new()
	regex_trailing.compile(",(\\s*[}\\]])")
	text_data = regex_trailing.sub(text_data, "$1", true)

	text_data = text_data.strip_edges()
	if text_data.ends_with(","):
		text_data = text_data.substr(0, text_data.length() - 1)

	#@ Step 6 - Parse using Expression (like Candy DE):
	var expr := Expression.new()
	if expr.parse(text_data) != OK:
		push_error("Failed to parse .txt dialogue file: " + path)
		return

	var result = expr.execute()
	if expr.has_execute_failed():
		push_error("Runtime error while evaluating .txt dialogue file: " + path)
		return

	if typeof(result) != TYPE_DICTIONARY:
		push_error("Dialogue file root must be a Dictionary: " + path)
		return

	var dialogue_data: Dictionary = result

	#@ Step 7: Create buttons for each conversation key:
	for c in dialogue_data.keys():
		#% Skip special preset container:
		if c == "CUSTOM_PRESETS":
			continue

		var b := Button.new()

		#% Button text:
		b.text = str(c)

		#% Store conversation key:
		b.set_meta("convo_key", c)

		#% Connect signal:
		b.connect("pressed", Callable(self, "_on_convo_button_pressed").bind(b))

		#% Add to UI:
		convo_list.add_child(b)

		#% Track for import:
		import_conversations.append(c)


#* Called when a conversation button is pressed:
func _on_convo_button_pressed(button: Button):
	#@ Retrieve the conversation key from the button metadata:
	var key: String = button.get_meta("convo_key")

	#@ Toggle add/remove in import_conversations:
	if key in import_conversations:
		import_conversations.erase(key)
		button.modulate = Color(0.5, 0.5, 0.5, 1)	#/ Dimmed
	else:
		import_conversations.append(key)
		button.modulate = Color(1, 1, 1, 1)			#/ Full color



func _on_cancel_pressed() -> void:
	self.visible = false
	main.get_node("MainMenu").visible = false		#/ Close Main Menu as well - less disorienting.
	for button in convo_list.get_children():
		button.queue_free()
	import_conversations.clear()
	candy_dc.editor_state = "ui"

func _on_file_browser_pressed() -> void:
	$"Shield2".visible = true
	file_browser.visible = true

func _on_file_dialog_canceled() -> void:
	file_browser.visible = false
	$"Shield2".visible = false

func _on_file_dialog_file_selected(path: String) -> void:
	file_field.text = path
	spawn_convo_buttons(path)
	$"Shield2".visible = false


#* Import selected conversations from .txt (Variant text format with metadata wrapper):
func _on_import_pressed() -> void:
	#@ Step 1 - Get import path and mode:
	var path: String = file_field.text.strip_edges()

	if not path.ends_with(".txt"):
		error_display.text = "No valid .txt file selected."
		return

	if import_conversations.is_empty():
		error_display.text = "No conversation(s) selected."
		return

	var mode: String = mode_select.get_item_text(mode_select.selected)

	#@ Step 2 - Load file (must exist for import):
	if not FileAccess.file_exists(path):
		error_display.text = "Import file not found: " + path
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		error_display.text = "Failed to open import file: " + path
		return

	var content := file.get_as_text()
	file.close()

	#@ Step 3 - Parse Variant text:
	var parsed = str_to_var(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		error_display.text = "Invalid or corrupt .txt file: " + path
		return

	#@ Step 4 - Extract Dialogue section only:
	if not parsed.has("Dialogue"):
		error_display.text = "Invalid dialogue export format: Missing 'Dialogue' section."
		return

	if typeof(parsed["Dialogue"]) != TYPE_DICTIONARY:
		error_display.text = "Invalid dialogue section in file: " + path
		return

	var import_data: Dictionary = parsed["Dialogue"]

	#@ Step 5 - Apply import behavior based on mode:
	match mode:
		#% Clear existing Conversations, import only selected ones:
		"Replace":
			candy_dc.conversations.clear()
			candy_dc.conversations["CUSTOM_PRESETS"] = candy_dc.custom_presets.duplicate(true)

			for key in import_conversations:
				if import_data.has(key):
					candy_dc.conversations[key] = import_data[key]

		#% Replace existing Conversations and add new one, but keep others intact:
		"Update":
			for key in import_conversations:
				if import_data.has(key):
					candy_dc.conversations[key] = import_data[key]

		#% Add only missing Conversations:
		"Add":
			for key in import_conversations:
				if import_data.has(key) and not candy_dc.conversations.has(key):
					candy_dc.conversations[key] = import_data[key]

	#@ Step 6 - Update current Conversation/Block if necessary:
	for conversation in candy_dc.conversations:
		if conversation != "CUSTOM_PRESETS":
			candy_dc.current_conversation = conversation
			for block in candy_dc.conversations[conversation]:
				candy_dc.current_block = block
				continue

	#@ Step 7 - Confirm import completed:
	print("Import completed:", mode, "←", path)
	main._load_active_block()
	_on_cancel_pressed()


func _on_select_all_pressed() -> void:
	import_conversations.clear()

	for button in convo_list.get_children():
		var key: String = button.get_meta("convo_key")
		import_conversations.append(key)
		button.modulate = Color(1, 1, 1, 1)			#/ Full color


func _on_deselect_all_pressed() -> void:
	import_conversations.clear()

	for button in convo_list.get_children():
		button.modulate = Color(0.5, 0.5, 0.5, 1)	#/ Dimmed

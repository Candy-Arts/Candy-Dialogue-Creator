extends CanvasLayer

@onready var main = get_node("/root/UI")

@onready var file_field = get_node("Panel/VBox/File/LineEdit")
@onready var mode_select = get_node("Panel/VBox/HBox/Mode/OptionButton")
@onready var convo_list = get_node("Panel/VBox/Conversations/Scroll/VBox")
@onready var file_browser = get_node("FileDialog")
@onready var error_display = get_node("Panel/VBox/Warnings/RichTextLabel")



#* Conversations to export:
#% Leave empty.
var export_conversations = []


#* Spawn a button for each conversation:
func spawn_convo_buttons():
	#@ Clear exported conversations list:
	export_conversations.clear()

	#@ Clear all buttons:
	for button in convo_list.get_children():
		button.queue_free()

	await get_tree().process_frame

	#@ Add buttons:
	for c in candy_dc.conversations:
		#% Skip the "CUSTOM_PRESETS" conversation:
		if c == "CUSTOM_PRESETS":
			continue

		var b := Button.new()

		#% Button text:
		b.text = str(c)

		#% Store the conversation key on the button:
		b.set_meta("convo_key", c)

		#% Connect the pressed signal:
		b.connect("pressed", Callable(self, "_on_convo_button_pressed").bind(b))

		#% Add to the UI
		convo_list.add_child(b)

		#% Add to list of conversations to export:
		export_conversations.append(c)


#* Called when a conversation button is pressed:
func _on_convo_button_pressed(button: Button):
	#@ Retrieve the conversation key from the button metadata:
	var key: String = button.get_meta("convo_key")

	#@ Toggle add/remove in export_conversations:
	if key in export_conversations:
		export_conversations.erase(key)
		button.modulate = Color(0.5, 0.5, 0.5, 1)	#/ Dimmed
	else:
		export_conversations.append(key)
		button.modulate = Color(1, 1, 1, 1)			#/ Full color



func _on_cancel_pressed() -> void:
	self.visible = false
	for button in convo_list.get_children():
		button.queue_free()
	export_conversations.clear()
	candy_dc.editor_state = "main_menu"


#* Open the file browser menu:
func _on_file_browser_pressed() -> void:
	$"Shield2".visible = true
	file_browser.visible = true

#* Cancel file selection in file browser:
func _on_file_dialog_canceled() -> void:
	file_browser.visible = false
	$"Shield2".visible = false

#* Confirm file selection in file browser:
func _on_file_dialog_file_selected(path: String) -> void:
	$"Shield2".visible = false
	file_field.text = path


#* Export selected conversations to .txt:
func _on_export_pressed() -> void:
	#@ Step 1 - Get export path and mode:
	var path: String = file_field.text.strip_edges()

	if not path.ends_with(".txt"):
		error_display.text = "No valid .txt file selected."
		return

	if export_conversations.is_empty():
		error_display.text = "No conversation(s) selected."
		return

	var mode: String = mode_select.get_item_text(mode_select.selected)

	#@ Step 2 - Load existing file (optional merge):
	var existing_dialogue: Dictionary = {}

	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()

			var parsed = str_to_var(content)

			if typeof(parsed) == TYPE_DICTIONARY:
				if parsed.has("Dialogue") and typeof(parsed["Dialogue"]) == TYPE_DICTIONARY:
					existing_dialogue = parsed["Dialogue"]

	#@ Step 3 - Build export dictionary based on mode:
	var output_data: Dictionary = {}
	match mode:
		#% Clear existing Conversations, export only selected ones:
		"Replace":
			for key in export_conversations:
				if candy_dc.conversations.has(key):
					output_data[key] = candy_dc.conversations[key]

		#% Replace existing Conversations and add new one, but keep others intact:
		"Update":
			output_data = existing_dialogue.duplicate(true)
			for key in export_conversations:
				if candy_dc.conversations.has(key):
					output_data[key] = candy_dc.conversations[key]

		#% Add only missing Conversations:
		"Add":
			output_data = existing_dialogue.duplicate(true)
			for key in export_conversations:
				if candy_dc.conversations.has(key) and not output_data.has(key):
					output_data[key] = candy_dc.conversations[key]

	#@ Step 4 - Clean empty variants before export:
	for conv_key in output_data.keys():
		var conv = output_data[conv_key]

		for block_key in conv.keys():
			var block = conv[block_key]

			if not block.has("Text"):
				continue

			var lines = block["Text"]

			for i in range(lines.size()):
				var entry = lines[i]

				if entry.has("Spoken Line"):
					var spoken_line = entry["Spoken Line"]

					if spoken_line.has("Variants"):
						var variants = spoken_line["Variants"]
						var cleaned_variants: Array = []

						for variant_dict in variants:
							for variant_name in variant_dict.keys():
								var text_val := str(
									variant_dict[variant_name].get("Text", "")
								).strip_edges()

								if text_val != "":
									cleaned_variants.append(variant_dict)
									break

						spoken_line["Variants"] = cleaned_variants
						entry["Spoken Line"] = spoken_line
						lines[i] = entry

			block["Text"] = lines
			conv[block_key] = block

		output_data[conv_key] = conv

	#@ Step 5 - Wrap with metadata and write Variant file:
	var final_export: Dictionary = {
		"Meta": {
			"Exported By": "Candy Dialogue Creator",
			"Version": candy_dc.dc_version,
			"Dialogue Version": candy_dc.dialogue_version,
		},
		"Dialogue": output_data
	}

	var file := FileAccess.open(path, FileAccess.WRITE)

	if file:
		var text_data = main.to_gdstring(final_export)
		file.store_string(text_data)
		file.close()

		print("Export completed:", mode, "→", path)
		_on_cancel_pressed()
	else:
		push_error("Failed to open file for writing: " + path)


#* Select all conversations:
func _on_select_all_pressed() -> void:
	export_conversations.clear()

	for button in convo_list.get_children():
		var key: String = button.get_meta("convo_key")
		export_conversations.append(key)
		button.modulate = Color(1, 1, 1, 1)			#/ Full color


#* Deselect all conversations:
func _on_deselect_all_pressed() -> void:
	export_conversations.clear()

	for button in convo_list.get_children():
		button.modulate = Color(0.5, 0.5, 0.5, 1)	#/ Dimmed

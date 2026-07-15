extends Control

class_name DataInput

@onready var main = get_node("/root/MainUI")
@onready var text_field = get_node("HBox/LineEdit")
@onready var menu_button = get_node("HBox/Button")
@onready var label = get_node("Label")

@onready var parent_command

enum InputLogic {STANDARD, VARIANT, CONDITION_EFFECT, CHOICE_CATEGORY, CHOICE_BUTTON, CHOICE_TIMER, MENU_SETUP, CATEGORY_SETUP, CHOICE_SETUP, TIMER_SETUP, CHOICE_SELECTED, CHOICE_TIMER_TIMEOUT}

@export var label_text := ""


#? Path to the parent node.
## Path to the parent node, from the root.
@export var parent_path := "/root/"

@export var parent_container: Node

#? Which code logic to use to handle written data.
## Which code logic to use to handle written data.[br]
## STANDARD: For regular line data.[br]
## VARIANT: For data specific to spoken line variants.[br]
@export var input_logic: InputLogic = InputLogic.STANDARD

@export var line_key = ""

#? Which arrays or dictionaries to populate the list from.
## Which list creation logic to use.
@export var list_logic := ""
## Which dictionary of options to include in the list.

#? Append data from the drop-down menu (true) or replace existing data (false).
## Append data from the drop-down menu (true) or replace existing data (false).
@export var append_data := false

#? Characters for separating data in the text field.
#? Only used if append_data = true
## Characters for separating data in the text field.[br][br]
## [i]Only used if append_data = true[/i]
@export var data_separator := ", "

#? Append the data field to main.data_fields.
## Set to true if this data field represets line data.
@export var is_line_data := true

## The tooltip that displays when the data field's label is hovered.
@export_multiline var label_tooltip := ""

var parent: Node




#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#% Get the command container this node is in:
	if parent_container == null:
		parent_container = get_parent().get_parent()

	#% Write the parent container's command:
	parent_command = parent_container.get_meta("command")

	#% Register self in database:
	if not main.line_data_fields.has(parent_command):
		main.line_data_fields[parent_command] = {}
	main.line_data_fields[parent_command][line_key + "_" + str(input_logic)] = self

	#% Set label text:
	label.text = label_text

	#% Set label tooltip:
	label.tooltip_text = label_tooltip

	#% Hide button:
	if list_logic == "":
		menu_button.visible = false

#	parent = get_node(parent_path)
#	if parent_path == "/root/":
#		push_error("TextInputDropdown: parent_path is root -- ", self)
#	elif parent == null:
#		push_error("TextInputDropdown: parent_path is invalid -- ", parent_path, " -- ", self)


#* Called when data is entered in the text field:
func _on_line_edit_text_changed(_new_text: String) -> void:
	data_entry()


#* Called when the ⫶ button is pressed:
func _on_button_pressed() -> void:
	pass


#* Enter data to text field when selected from the list:
func _data_selected(data) -> void:
	if append_data == false:
		text_field.text = data

	elif append_data == true:
		if text_field.text.is_empty():
			text_field.text = data
		else:
			text_field.text = text_field.text + data_separator + data

	data_entry()


#* Helper: Check if a command is a condition command:
func _is_condition_command(command: String) -> bool:
	return command in ["§If", "§Elif", "§Else", "§For", "§While"]


#* Update data in the dialogue (or presets) based on input_logic:
func data_entry():
	if line_key == "Title":
		print("data_entry: line_key=Title text=", text_field.text, " line=", globals.current_line)

	#@ Identify the source:
	var source = main._get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return

	#@ Identify the line:
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]

	#@ Match logic:
	match input_logic:
		InputLogic.STANDARD:
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				line[line_type]["Commands"][parent_command][line_key] = text_field.text
			else:
				if line[line_type].has(line_key):
					line[line_type][line_key] = text_field.text
			#@ Refresh portrait and voice regardless of condition command nesting:
			if line_key == "Portrait" or line_key == "Reference":
				main.refresh_portrait_display()
			if line_key == "Voice" or line_key == "Reference":
				main._reset_voice(true, true)

		InputLogic.VARIANT:
			for entry in line[line_type].get("Variants", []):
				if entry.keys()[0] == globals.current_variant:

					#% Save data differently if the Spoken Line is part of a condition command:
					if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
						if not line[line_type]["Commands"].has(parent_command):
							line[line_type]["Commands"][parent_command] = {}
						line[line_type]["Commands"][parent_command][line_key] = text_field.text
					else:
						entry[globals.current_variant][line_key] = text_field.text

					#% Change text direction if data field is "Direction":
					if line_key == "Direction":
						var direction
						if text_field.text.to_lower() == "rtl":
							direction = Control.TEXT_DIRECTION_RTL
						else:
							direction = Control.TEXT_DIRECTION_LTR
						main.spoken_text_preview.text_direction = direction

					#% Save caret position:
					var caret
					if line_key == "Direction" or line_key == "Weight":
						caret = text_field.get_caret_column()

					#% Refresh UI:
					main.refresh_variant_tree()
					main.refresh_translation_tree()
					main.update_line_list()

					#% Restore caret:
					if line_key == "Direction" or line_key == "Weight":
						text_field.set_caret_column(caret)

					return

		InputLogic.CONDITION_EFFECT:
			#% Update data from text field:
			line[line_type][line_key] = text_field.text

			#@ Effect is empty:
			if text_field.text == "":
				#% Hide all command containers:
				for container in main.line_data_containers:
					#% Don't hide the current condition command:
					if container != globals.current_line_type:
						main.line_data_containers[container].visible = false

			#@ Effect is a known command:
			elif main.line_data_containers.has(text_field.text):
				var effect_type = text_field.text
				if not line[line_type]["Commands"].has(effect_type):
					var template = globals.line_templates.get(effect_type, {})
					line[line_type]["Commands"][effect_type] = template.duplicate(true)
					if effect_type == "Spoken Line":
						main._populate_spoken_line_variants(line[line_type]["Commands"]["Spoken Line"])
				for container in main.line_data_containers:
					if container != globals.current_line_type:
						main.line_data_containers[container].visible = false
				main.line_data_containers[effect_type].visible = true
				if main.line_data_fields.has(effect_type):
					for data_field in main.line_data_fields[effect_type]:
						main.line_data_fields[effect_type][data_field].data_load()

				#% Refresh variant and translation trees if effect is a Spoken Line:
				if effect_type == "Spoken Line":
					main.refresh_portrait_display()
					main.refresh_variant_tree()
					main.refresh_translation_tree()

				#% Refresh choice tree if effect is §Choice_List:
				elif effect_type == "§Choice_List":
					main.refresh_choice_tree()

			#@ Effect is variable or unknown command:
			else:
				for container in main.line_data_containers:
					#% Hide all condition commands except current:
					if container != globals.current_line_type and (_is_condition_command(container) or container == "§Comment"):
						main.line_data_containers[container].visible = false

					#% Unhide all other commands:
					else:
						main.line_data_containers[container].visible = true

		InputLogic.CHOICE_CATEGORY:
			if globals.current_choice_category == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					var cat = category_entry[globals.current_choice_category]
					if cat.has(line_key):
						cat[line_key] = text_field.text
					main._updating_ui = true
					main.update_line_list()
					main._updating_ui = false
					return

		InputLogic.CHOICE_BUTTON:
			if globals.current_choice_item == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							var choice = choice_entry[globals.current_choice_item]
							if choice.has(line_key):
								choice[line_key] = text_field.text
							main._updating_ui = true
							main.update_line_list()
							main._updating_ui = false
							return

		InputLogic.CHOICE_TIMER:
			if globals.current_choice_timer == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					var timer = timer_entry[globals.current_choice_timer]
					if timer.has(line_key):
						timer[line_key] = text_field.text
					main._updating_ui = true
					main.update_line_list()
					main._updating_ui = false
					return

		InputLogic.MENU_SETUP:
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				if not line[line_type]["Commands"][parent_command].has("Setup"):
					line[line_type]["Commands"][parent_command]["Setup"] = {}
				line[line_type]["Commands"][parent_command]["Setup"][line_key] = text_field.text
			else:
				if line[line_type].has("Setup"):
					line[line_type]["Setup"][line_key] = text_field.text

		InputLogic.CATEGORY_SETUP:
			if globals.current_choice_category == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					var cat = category_entry[globals.current_choice_category]
					if cat.has("Setup"):
						cat["Setup"][line_key] = text_field.text
					main._updating_ui = true
					main.update_line_list()
					main._updating_ui = false
					return

		InputLogic.CHOICE_SETUP:
			if globals.current_choice_item == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							var choice = choice_entry[globals.current_choice_item]
							if choice.has("Setup"):
								choice["Setup"][line_key] = text_field.text
							main._updating_ui = true
							main.update_line_list()
							main._updating_ui = false
							return

		InputLogic.TIMER_SETUP:
			if globals.current_choice_timer == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					var timer = timer_entry[globals.current_choice_timer]
					if timer.has("Setup"):
						timer["Setup"][line_key] = text_field.text
					main._updating_ui = true
					main.update_line_list()
					main._updating_ui = false
					return

		InputLogic.CHOICE_SELECTED:
			if globals.current_choice_item == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							var choice = choice_entry[globals.current_choice_item]
							if choice.has("Finish"):
								choice["Finish"][line_key] = text_field.text
							main._updating_ui = true
							main.update_line_list()
							main._updating_ui = false
							return

		InputLogic.CHOICE_TIMER_TIMEOUT:
			if globals.current_choice_timer == "":
				main._updating_ui = true
				main.update_line_list()
				main._updating_ui = false
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if not line[line_type]["Commands"].has(parent_command):
					line[line_type]["Commands"][parent_command] = {}
				choice_source = line[line_type]["Commands"][parent_command]
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					var timer = timer_entry[globals.current_choice_timer]
					if timer.has("Timeout"):
						timer["Timeout"][line_key] = text_field.text
					main._updating_ui = true
					main.update_line_list()
					main._updating_ui = false
					return

	main._updating_ui = true
	main.update_line_list()
	main._updating_ui = false


#* Load and display data from the line:
func data_load():
	if line_key == "Title":
		print("data_load: line_key=Title line=", globals.current_line, " value=", text_field.text, " focused=", text_field.has_focus())

	#@ Identify the source:
	var source = main._get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return

	#@ Identify the line:
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]

	#@ Match logic:
	match input_logic:
		InputLogic.STANDARD:
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if line[line_type]["Commands"].has(parent_command) and line[line_type]["Commands"][parent_command].has(line_key):
					text_field.text = line[line_type]["Commands"][parent_command][line_key]
				else:
					text_field.text = ""
			else:
				if line[line_type].has(line_key):
					text_field.text = line[line_type][line_key]
				else:
					text_field.text = ""

		InputLogic.VARIANT:
			for entry in line[line_type].get("Variants", []):
				if entry.keys()[0] == globals.current_variant:
					if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
						if line[line_type]["Commands"].has(parent_command) and line[line_type]["Commands"][parent_command].has(line_key):
							text_field.text = line[line_type]["Commands"][parent_command][line_key]
					else:
						text_field.text = entry[globals.current_variant].get(line_key, "")
					if line_key == "Direction":
						var direction
						if text_field.text.to_lower() == "rtl":
							direction = Control.TEXT_DIRECTION_RTL
						else:
							direction = Control.TEXT_DIRECTION_LTR
						main.spoken_text_preview.text_direction = direction
					return

		InputLogic.CONDITION_EFFECT:
			#% Update text field:
			text_field.text = line[line_type].get(line_key, "")

			#@ Effect is empty:
			if text_field.text == "":
				#% Hide all command containers:
				for container in main.line_data_containers:
					#% Don't hide the current condition command:
					if container != globals.current_line_type:
						main.line_data_containers[container].visible = false

			#@ Effect is a known command:
			elif main.line_data_containers.has(text_field.text):
				for container in main.line_data_containers:
					if container != globals.current_line_type:
						main.line_data_containers[container].visible = false
				main.line_data_containers[text_field.text].visible = true
				if main.line_data_fields.has(text_field.text):
					for data_field in main.line_data_fields[text_field.text]:
						main.line_data_fields[text_field.text][data_field].data_load()

				#% Refresh variant and translation trees if effect is a Spoken Line:
				if text_field.text == "Spoken Line":
					main.refresh_portrait_display()
					main.refresh_variant_tree()
					main.refresh_translation_tree()

				#% Refresh choice tree if effect is §Choice_List:
				elif text_field.text == "§Choice_List":
					main.refresh_choice_tree()

			#@ Effect is variable or unknown command:
			else:
				for container in main.line_data_containers:
					if container != globals.current_line_type and (_is_condition_command(container) or container == "§Comment"):
						main.line_data_containers[container].visible = false
					else:
						main.line_data_containers[container].visible = true
						#% Don't call data_load on the condition command itself — that's what called us:
						if container != globals.current_line_type and main.line_data_fields.has(container):
							for data_field in main.line_data_fields[container]:
								main.line_data_fields[container][data_field].data_load()

		InputLogic.CHOICE_CATEGORY:
			if globals.current_choice_category == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					text_field.text = category_entry[globals.current_choice_category].get(line_key, "")
					return

		InputLogic.CHOICE_BUTTON:
			if globals.current_choice_item == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							text_field.text = choice_entry[globals.current_choice_item].get(line_key, "")
							return

		InputLogic.CHOICE_TIMER:
			if globals.current_choice_timer == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					text_field.text = timer_entry[globals.current_choice_timer].get(line_key, "")
					return

		InputLogic.MENU_SETUP:
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				if line[line_type]["Commands"].has(parent_command) and line[line_type]["Commands"][parent_command].has("Setup"):
					text_field.text = line[line_type]["Commands"][parent_command]["Setup"].get(line_key, "")
			else:
				if line[line_type].has("Setup"):
					text_field.text = line[line_type]["Setup"].get(line_key, "")

		InputLogic.CATEGORY_SETUP:
			if globals.current_choice_category == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					var cat = category_entry[globals.current_choice_category]
					if cat.has("Setup"):
						text_field.text = cat["Setup"].get(line_key, "")
					return

		InputLogic.CHOICE_SETUP:
			if globals.current_choice_item == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							var choice = choice_entry[globals.current_choice_item]
							if choice.has("Setup"):
								text_field.text = choice["Setup"].get(line_key, "")
							return

		InputLogic.TIMER_SETUP:
			if globals.current_choice_timer == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					var timer = timer_entry[globals.current_choice_timer]
					if timer.has("Setup"):
						text_field.text = timer["Setup"].get(line_key, "")
					return

		InputLogic.CHOICE_SELECTED:
			if globals.current_choice_item == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for category_entry in choice_source.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == globals.current_choice_item:
							var choice = choice_entry[globals.current_choice_item]
							if choice.has("Finish"):
								text_field.text = choice["Finish"].get(line_key, "")
							return

		InputLogic.CHOICE_TIMER_TIMEOUT:
			if globals.current_choice_timer == "":
				return
			var choice_source = line[line_type]
			if _is_condition_command(globals.current_line_type) and not _is_condition_command(parent_command):
				choice_source = line[line_type]["Commands"].get(parent_command, {})
			for timer_entry in choice_source.get("Timers", []):
				if timer_entry.keys()[0] == globals.current_choice_timer:
					var timer = timer_entry[globals.current_choice_timer]
					if timer.has("Timeout"):
						text_field.text = timer["Timeout"].get(line_key, "")
					return


#* Mark as last focused and store previous data:
func _on_line_edit_focus_entered(source) -> void:
	globals.original_data = text_field.text
	globals.last_focused_field = source


#* When data field loses focus, save undo step if data has changed:
func _on_line_edit_focus_exited(source) -> void:
	if globals.last_focused_field == source and text_field.text != globals.original_data:
		globals.original_data = ""
		main.save_undo_step()


#* Helper - set item name and meta value in one pass:
func _add_dropdown_item(item_label: String, meta: Variant) -> void:
	main.dropdown_list.add_item(item_label)
	main.dropdown_list.set_item_metadata(main.dropdown_list.get_item_count() - 1, meta)


#* Populate drop-down lists:
func populate_dropdown() -> void:
	var vbox = main.dropdown_list.get_node("ScrollContainer/VBoxContainer")
	for child in vbox.get_children():
		child.queue_free()
	await main.get_tree().process_frame

	match list_logic:
		"Bool":
			_build_dropdown([["True", "true"], ["False", "false"]])

		"BoolNum2":
			_build_dropdown([["True", "1"], ["False", "0"]])

		"BoolToggle":
			_build_dropdown([["True", "true"], ["False", "false"], ["Toggle", "toggle"]])

		"SpokenLineOverride":
			_build_dropdown([["Forbid", "-1"], ["Default", "0"], ["Force", "1"]])

		"PauseLinesMedia":
			_build_dropdown([["Spoken Lines", "0"], ["All Lines", "1"]])

		"ShowHide":
			_build_dropdown([["Ignore", "0"], ["Hide", "1"]])

		"ShowHideMedia":
			_build_dropdown([["Hide", "-1"], ["Ignore", "0"], ["Show", "1"]])

		"Loop":
			_build_dropdown([["Infinite", "-1"], ["Disable", "0"]])

		"StopFrame":
			_build_dropdown([["Last Frame", "-1"], ["Current frame", "0"]])

		"SpeechDirection":
			_build_dropdown([["Left to Right", "LtR"], ["Right to Left", "RtL"]])

		"Mirror":
			_build_dropdown([
				["Mirror horizontally", "h flip"],
				["Mirror vertically", "v flip"],
				["Mirror both axes", "both"],
				["Reset", "reset"]
			])

		"Look_Axes":
			_build_dropdown([
				["+Z", "+Z"],
				["-Z", "-Z"],
				["+X", "+X"],
				["-X", "-X"],
				["+Y", "+Y"],
				["-Y", "-Y"],
			])

		"BasicOperators":
			_build_dropdown([["=", "="], ["+", "+"], ["-", "-"], ["*", "*"], ["/", "/"]])

		"Operators":
			var operator_categories = {
				"Basic": ["=", "+=", "-=", "*=", "/=", "//=", "%=", "^="],
				"Type Conversion": ["to_int", "to_float", "to_string", "to_bool", "toggle_bool", "var_to_str", "str_to_var", "json_to_str", "str_to_json"],
				"Type Check": ["typeof", "type_string", "is_array", "is_dict", "is_object", "is_nan", "is_inf", "var_to_bytes", "bytes_to_var"],
				"String": ["strip_edges", "to_upper", "to_lower", "replace", "substr", "split", "split_to_array", "join", "path_join"],
				"Array": ["append", "append_first", "insert", "erase", "remove_at", "clear", "slice", "reverse", "sort", "shuffle", "unique"],
				"Dictionary": ["merge", "get", "set_key", "duplicate", "deep_duplicate"],
				"Random": ["randi", "randf", "randi_range", "randf_range", "rand_pick"],
				"Rounding": ["floor", "ceil", "round"],
				"Arithmetic": ["abs", "sign", "sqrt", "min", "max"],
				"Interpolation": ["lerp", "clamp", "wrap"],
				"Trigonometry": ["sin", "cos", "tan", "asin", "acos", "atan", "deg_to_rad", "rad_to_deg"],
				"Logarithmic": ["log", "log10", "log_base"],
				"Nodes": ["get_node", "get_node_or_null"],
			}
			var submenu_groups = []
			for category in operator_categories.keys():
				var sub_items = []
				for command in operator_categories[category]:
					sub_items.append([command, command])
				submenu_groups.append([category, sub_items])
			_build_dropdown([], submenu_groups)

		"ExportFormats":
			_build_dropdown([
				[".txt", ".txt"],
				[".cfg", ".cfg"],
				[".ini", ".ini"],
				[".json", ".json"],
				[".csv", ".csv"],
				[".bin", ".bin"],
				["base64", "base64"],
				[".tres", ".tres"],
				[".res", ".res"],
				["Dialogue", ".dialogue"],
			])

		"ExportMethod":
			_build_dropdown([
				["Overwrite", "Overwrite"],
				["Skip", "Skip"],
				["Duplicate", "Duplicate"],
				["Timestamp", "Timestamp"],
			])

		"MouseMode":
			_build_dropdown([
				["Visible", "Visible"],
				["Captured", "Captured"],
				["Hidden", "Hidden"],
				["Confined", "Confined"],
				["Confined_Hidden", "Confined_Hidden"],
			])

		"MouseModeCommand":
			_build_dropdown([
				["Visible", "Visible"],
				["Captured", "Captured"],
				["Hidden", "Hidden"],
				["Confined", "Confined"],
				["Confined_Hidden", "Confined_Hidden"],
				["Dialogue_Start", "Dialogue_Start"],
				["Dialogue_End", "Dialogue_End"],
				["Choice", "Choice"],
			])

		"MouseModeDefaultNone":
			_build_dropdown([
				["None", ""],
				["Default", "Default"],
				["Visible", "Visible"],
				["Captured", "Captured"],
				["Hidden", "Hidden"],
				["Confined", "Confined"],
				["Confined_Hidden", "Confined_Hidden"],
			])

		"MouseModeMenuDefaultNone":
			_build_dropdown([
				["Menu", "Menu"],
				["None", ""],
				["Default", "Default"],
				["Visible", "Visible"],
				["Captured", "Captured"],
				["Hidden", "Hidden"],
				["Confined", "Confined"],
				["Confined_Hidden", "Confined_Hidden"],
			])

		"TransConversation":
			var items = []
			for conversation in globals.dialogue.keys():
				items.append([conversation, conversation])
			_build_dropdown(items)

		"TransBlock":
			var conversation_field = get_parent().get_node("Conversation").text_field
			var conversation = conversation_field.text if conversation_field.text != "" else globals.current_conversation
			var items = []
			if globals.dialogue.has(conversation):
				for block in globals.dialogue[conversation].keys():
					items.append([block, block])
			_build_dropdown(items)

		"TransLine":
			var conversation_field = get_parent().get_node("Conversation").text_field
			var block_field = get_parent().get_node("Block").text_field
			var conversation = conversation_field.text if conversation_field.text != "" else globals.current_conversation
			var block = block_field.text if block_field.text != "" else globals.current_block
			var items = []
			if globals.dialogue.has(conversation) and globals.dialogue[conversation].has(block):
				var lines = globals.dialogue[conversation][block]["Text"]
				for line in lines:
					if line.has("§LM"):
						var reference = line["§LM"].get("Reference", "")
						if reference != "":
							items.append([reference, reference])
			_build_dropdown(items)

		"ActorRef":
			var items = []
			for item in globals.project_scripts["Actors"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					items.append([entry, entry])
			_build_dropdown(items)

		"RoleRef":
			var items = []
			for item in globals.project_scripts["Roles"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					items.append([entry, entry])
			_build_dropdown(items)

		"SpeakerRef":
			var role_items = []
			for item in globals.project_scripts["Roles"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					role_items.append([entry, entry])
			var actor_items = []
			for item in globals.project_scripts["Actors"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					actor_items.append([entry, entry])
			_build_dropdown(actor_items, [["Roles", role_items]])

		"Flags":
			var flag_items = []
			for item in globals.project_scripts["Flags"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					flag_items.append([entry, entry])
			_build_dropdown(flag_items)

		"Dispositions":
			var disposition_items = []
			for item in globals.project_scripts["Dispositions"]["Data"].strip_edges().trim_suffix(",").split(","):
				var entry = item.strip_edges()
				if entry != "":
					disposition_items.append([entry, entry])
			_build_dropdown(disposition_items)

		"Portraits":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var reference = line_data.get("Reference", "")
			if reference == "":
				_build_dropdown([["Speaker Reference required", null]])
				return
			if not globals.project_resources["*Portraits"].has(reference):
				_build_dropdown([["No match to Speaker Reference", null]])
				return

			var sprite_regex = RegEx.new()
			sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")

			var char_folder = globals.project_resources["*Portraits"][reference]
			var items = []
			var animated_items = []
			var sprite_frames_items = []

			for filename in char_folder.keys():
				var file_path = char_folder[filename]
				if filename == "Animated" and file_path is Dictionary:
					for anim_name in file_path.keys():
						animated_items.append([anim_name, anim_name])
				elif filename == "Sprite_Frames" and file_path is Dictionary:
					for sf_name in file_path.keys():
						var sf_path = file_path[sf_name]
						if not sf_path is Dictionary and FileAccess.file_exists(sf_path):
							var tres_file = FileAccess.open(sf_path, FileAccess.READ)
							if tres_file:
								var content = tres_file.get_as_text()
								tres_file.close()
								var anim_regex = RegEx.new()
								anim_regex.compile('"name":\\s*&?"([^"]+)"')
								for result in anim_regex.search_all(content):
									sprite_frames_items.append([result.get_string(1), result.get_string(1)])
							break
				elif not file_path is Dictionary:
					var ext = filename.get_extension().to_lower()
					var sprite_match = sprite_regex.search(filename)
					if sprite_match:
						items.append([filename, filename, file_path, "sprite", sprite_match])
					elif ext == "ogv":
						items.append([filename, filename, file_path, "video"])
					else:
						items.append([filename, filename, file_path, "image"])

			var submenu_groups = []
			if not animated_items.is_empty():
				submenu_groups.append(["Animated", animated_items])
			if not sprite_frames_items.is_empty():
				submenu_groups.append(["Sprite Frames", sprite_frames_items])

			if items.is_empty() and animated_items.is_empty() and sprite_frames_items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, submenu_groups, false, false, false, false, true, false)

		"Busts":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var reference = line_data.get("Reference", "")
			if reference == "":
				_build_dropdown([["Speaker Reference required", null]])
				return
			if not globals.project_resources["*Busts"].has(reference):
				_build_dropdown([["No match to Speaker Reference", null]])
				return

			var sprite_regex = RegEx.new()
			sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")

			var char_folder = globals.project_resources["*Busts"][reference]
			var items = []
			var animated_items = []
			var sprite_frames_items = []

			for filename in char_folder.keys():
				var file_path = char_folder[filename]
				if filename == "Animated" and file_path is Dictionary:
					for anim_name in file_path.keys():
						animated_items.append([anim_name, anim_name])
				elif filename == "Sprite_Frames" and file_path is Dictionary:
					for sf_name in file_path.keys():
						if not file_path[sf_name] is Dictionary:
							sprite_frames_items.append([sf_name, sf_name])
				elif not file_path is Dictionary:
					var sprite_match = sprite_regex.search(filename)
					if sprite_match:
						items.append([filename, filename, file_path, "sprite", sprite_match])
					else:
						items.append([filename, filename, file_path, "image"])

			var submenu_groups = []
			if not animated_items.is_empty():
				submenu_groups.append(["Animated", animated_items])
			if not sprite_frames_items.is_empty():
				submenu_groups.append(["Sprite Frames", sprite_frames_items])

			if items.is_empty() and animated_items.is_empty() and sprite_frames_items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, submenu_groups, false, false, false, false, false, true)

		"VNBustAnimation":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var reference = line_data.get("Reference", "")
			var file = line_data.get("File", "")
			if reference == "" or file == "":
				_build_dropdown([["No files available.", null]])
				return
			if not globals.project_resources["*Busts"].has(reference):
				_build_dropdown([["No match to Speaker Reference", null]])
				return

			var char_folder = globals.project_resources["*Busts"][reference]
			if not char_folder.has("Sprite_Frames") or not char_folder["Sprite_Frames"].has(file):
				_build_dropdown([["No files available.", null]])
				return

			var resource_path = char_folder["Sprite_Frames"][file]
			if not FileAccess.file_exists(resource_path):
				_build_dropdown([["No files available.", null]])
				return

			var sprite_frames_res = ResourceLoader.load(resource_path)
			if sprite_frames_res == null or not sprite_frames_res is SpriteFrames:
				_build_dropdown([["No files available.", null]])
				return

			var items = []
			for anim_name in sprite_frames_res.get_animation_names():
				items.append([anim_name, anim_name])

			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"VoiceFiles":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var reference = line_data.get("Reference", "")
			if reference == "":
				_build_dropdown([["Speaker Reference required", null]])
				return
			if not globals.project_resources["*Voice_Files"].has(reference):
				_build_dropdown([["No match to Speaker Reference", null]])
				return

			var char_folder = globals.project_resources["*Voice_Files"][reference]
			if not char_folder.has(globals.current_conversation):
				_build_dropdown([["No files available.", null]])
				return
			var conv_folder = char_folder[globals.current_conversation]
			if not conv_folder.has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var block_folder = conv_folder[globals.current_block]

			var items = []
			for filename in block_folder.keys():
				var file_path = block_folder[filename]
				if not file_path is Dictionary:
					var ext = filename.get_extension().to_lower()
					if ext in ["mp3", "ogg", "wav"]:
						items.append([filename, filename, file_path])

			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, [], true)

		"ImagePlayers":
			var items = []
			for folder in globals.project_resources["Images"].keys():
				if globals.project_resources["Images"][folder] is Dictionary:
					items.append([folder, folder])
			_build_dropdown(items)

		"AudioPlayers":
			var items = []
			for folder in globals.project_resources["Audio"].keys():
				if globals.project_resources["Audio"][folder] is Dictionary:
					items.append([folder, folder])
			_build_dropdown(items)

		"VideoPlayers":
			var items = []
			for folder in globals.project_resources["Videos"].keys():
				if globals.project_resources["Videos"][folder] is Dictionary:
					items.append([folder, folder])
			_build_dropdown(items)

		"MediaImage":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var node = line_data.get("Node", "")
			if node == "" or not globals.project_resources["Images"].has(node):
				_build_dropdown([["No files available.", null]])
				return
			var items = []
			var animated_items = []

			for filename in globals.project_resources["Images"][node].keys():
				var file_path = globals.project_resources["Images"][node][filename]
				if filename == "Animated" and file_path is Dictionary:
					for anim_name in file_path.keys():
						animated_items.append([anim_name, anim_name])
				elif not file_path is Dictionary:
					items.append([filename, filename, file_path])

			var submenu_groups = []
			if not animated_items.is_empty():
				submenu_groups.append(["Animated", animated_items])

			if items.is_empty() and animated_items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, submenu_groups, false, false, true)

		"MediaAudio":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			   not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var node = line_data.get("Node", "")
			if node == "" or not globals.project_resources["Audio"].has(node):
				_build_dropdown([["No files available.", null]])
				return
			var items = []
			for filename in globals.project_resources["Audio"][node].keys():
				if not globals.project_resources["Audio"][node][filename] is Dictionary:
					items.append([filename, filename, globals.project_resources["Audio"][node][filename]])
			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, [], true)

		"MediaVideo":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var node = line_data.get("Node", "")
			if node == "" or not globals.project_resources["Videos"].has(node):
				_build_dropdown([["No files available.", null]])
				return
			var items = []
			for filename in globals.project_resources["Videos"][node].keys():
				var file_path = globals.project_resources["Videos"][node][filename]
				if not file_path is Dictionary:
					items.append([filename, filename, file_path])
			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, [], false, true)

		"CSSprites":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var targets_raw = line_data.get("Targets", "")
			if targets_raw == "":
				_build_dropdown([["No files available.", null]])
				return

			var actors = []
			for t in targets_raw.split(","):
				var actor = t.strip_edges()
				if actor != "":
					actors.append(actor)

			if actors.is_empty():
				_build_dropdown([["No files available.", null]])
				return

			var submenu_groups = []
			for actor in actors:
				if not globals.project_resources["*Sprites"].has(actor):
					continue
				var actor_folder = globals.project_resources["*Sprites"][actor]
				var sprite_items = []
				var sprite_frames_items = []
				var frame_paths = []
				for filename in actor_folder.keys():
					var file_path = actor_folder[filename]
					if not file_path is Dictionary:
						frame_paths.append(file_path)
				for filename in actor_folder.keys():
					var file_path = actor_folder[filename]
					if filename == "Sprite_Frames" and file_path is Dictionary:
						for sf_name in file_path.keys():
							if not file_path[sf_name] is Dictionary:
								sprite_frames_items.append([sf_name, sf_name])
					elif not file_path is Dictionary:
						sprite_items.append([filename, filename, file_path, frame_paths])
				if not sprite_items.is_empty():
					submenu_groups.append([actor + ": Sprites", sprite_items, true])
				if not sprite_frames_items.is_empty():
					submenu_groups.append([actor + ": Sprite Frames", sprite_frames_items])

			if submenu_groups.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown([], submenu_groups)

		"Backgrounds":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var layer = line_data.get("Layers", "")
			if layer == "" or not globals.project_resources["Backgrounds"].has(layer):
				_build_dropdown([["No files available.", null]])
				return

			var sprite_regex = RegEx.new()
			sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")

			var items = []
			var animated_items = []
			var sprite_frames_items = []

			for filename in globals.project_resources["Backgrounds"][layer].keys():
				var file_path = globals.project_resources["Backgrounds"][layer][filename]
				if filename == "Animated" and file_path is Dictionary:
					for anim_name in file_path.keys():
						animated_items.append([anim_name, anim_name])
				elif filename == "Sprite_Frames" and file_path is Dictionary:
					for sf_name in file_path.keys():
						if not file_path[sf_name] is Dictionary:
							sprite_frames_items.append([sf_name, sf_name])
				elif not file_path is Dictionary:
					var ext = filename.get_extension().to_lower()
					var sprite_match = sprite_regex.search(filename)
					if sprite_match:
						items.append([filename, filename, file_path, "sprite", sprite_match])
					elif ext == "ogv":
						items.append([filename, filename, file_path, "video"])
					else:
						items.append([filename, filename, file_path, "image"])

			var submenu_groups = []
			if not animated_items.is_empty():
				submenu_groups.append(["Animated", animated_items])
			if not sprite_frames_items.is_empty():
				submenu_groups.append(["Sprite Frames", sprite_frames_items])

			if items.is_empty() and animated_items.is_empty() and sprite_frames_items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items, submenu_groups, false, false, false, true)

		"BGAnimation":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			var layer = line_data.get("Layers", "")
			var file = line_data.get("File", "")
			if layer == "" or file == "":
				_build_dropdown([["No files available.", null]])
				return
			if not globals.project_resources["Backgrounds"].has(layer):
				_build_dropdown([["No files available.", null]])
				return
			var sf_folder = globals.project_resources["Backgrounds"][layer].get("Sprite_Frames", {})
			if not sf_folder.has(file):
				_build_dropdown([["No files available.", null]])
				return
			var file_path = sf_folder[file]
			if not FileAccess.file_exists(file_path):
				_build_dropdown([["No files available.", null]])
				return

			var tres_file = FileAccess.open(file_path, FileAccess.READ)
			if tres_file == null:
				_build_dropdown([["No files available.", null]])
				return
			var content = tres_file.get_as_text()
			tres_file.close()

			var anim_regex = RegEx.new()
			anim_regex.compile('"name":\\s*&?"([^"]+)"')
			var results = anim_regex.search_all(content)

			var items = []
			for result in results:
				var anim_name = result.get_string(1)
				items.append([anim_name, anim_name])

			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"BGScenes":
			var items = []
			for scene_name in globals.project_resources["BG_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"VNScenes":
			var items = []
			for scene_name in globals.project_resources["VN_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"BGLayers":
			var submenu_groups = []
			for scene_name in globals.project_resources["BG_Layer_Nodes"].keys():
				var sub_items = []
				for node in globals.project_resources["BG_Layer_Nodes"][scene_name]:
					sub_items.append([node, node])
				submenu_groups.append([scene_name, sub_items])
			_build_dropdown([], submenu_groups)

		"BustNodes":
			var submenu_groups = []
			for scene_name in globals.project_resources["VN_Bust_Nodes"].keys():
				var sub_items = []
				for node in globals.project_resources["VN_Bust_Nodes"][scene_name]:
					sub_items.append([node, node])
				submenu_groups.append([scene_name, sub_items])
			_build_dropdown([], submenu_groups)

		"BGAnimationLibraries":
			var anim_libs = globals.project_resources["Backgrounds"].get("Animation_Libraries", {})
			if anim_libs.is_empty():
				_build_dropdown([["No files available.", null]])
				return
			var items = []
			for filename in anim_libs.keys():
				if not anim_libs[filename] is Dictionary:
					items.append([filename, filename])
			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"VNAnimationLibraries":
			var anim_libs = globals.project_resources["*Busts"].get("Animation_Libraries", {})
			if anim_libs.is_empty():
				_build_dropdown([["No files available.", null]])
				return
			var items = []
			for filename in anim_libs.keys():
				if not anim_libs[filename] is Dictionary:
					items.append([filename, filename])
			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"BGEffects":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var library_file = line_data.get("Library", "")
			if library_file == "":
				_build_dropdown([["No files available.", null]])
				return

			#% Find library file in the general Animation_Libraries folder:
			var anim_libs = globals.project_resources["Backgrounds"].get("Animation_Libraries", {})
			if not anim_libs.has(library_file):
				_build_dropdown([["No files available.", null]])
				return
			var library_path = anim_libs[library_file]
			if not FileAccess.file_exists(library_path):
				_build_dropdown([["No files available.", null]])
				return

			#% Load animation names from the library resource:
			var library_res = ResourceLoader.load(library_path)
			if library_res == null:
				_build_dropdown([["No files available.", null]])
				return

			var items = []
			for anim_name in library_res.get_animation_list():
				items.append([anim_name, anim_name])

			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"VNEffects":
			var source = main._get_line_source()
			if not source.has(globals.current_conversation) or \
			not source[globals.current_conversation].has(globals.current_block):
				_build_dropdown([["No files available.", null]])
				return
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line < 0 or globals.current_line >= lines.size():
				_build_dropdown([["No files available.", null]])
				return
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has(parent_command):
				line_data = line_data["Commands"][parent_command]
			var library_file = line_data.get("Library", "")
			if library_file == "":
				_build_dropdown([["No files available.", null]])
				return

			#% Find library file in the general Animation_Libraries folder:
			var anim_libs = globals.project_resources["*Busts"].get("Animation_Libraries", {})
			if not anim_libs.has(library_file):
				_build_dropdown([["No files available.", null]])
				return
			var library_path = anim_libs[library_file]
			if not FileAccess.file_exists(library_path):
				_build_dropdown([["No files available.", null]])
				return

			#% Load animation names from the library resource:
			var library_res = ResourceLoader.load(library_path)
			if library_res == null:
				_build_dropdown([["No files available.", null]])
				return

			var items = []
			for anim_name in library_res.get_animation_list():
				items.append([anim_name, anim_name])

			if items.is_empty():
				_build_dropdown([["No files available.", null]])
			else:
				_build_dropdown(items)

		"ConditionEffects":
			var command_categories = {
				"Control": ["§Call", "§Emit", "§Await", "§Set", "§Role", "§Flag", "§Name", "§Disposition", "§Export", "§Import"],
				"Transitions": ["§Jump", "§Bridge", "§Return", "§End"],
				"Input": ["§Input", "§Mouse"],
				"Choices": ["§Choice_List", "§Choice_Status", "§Timer_Status"],
				"Effects": ["§Effect", "§Effect_Stop", "§Effect_Wait", "§Wait", "§Hide", "§Clear"],
				"Images": ["§Image", "§I_Wait", "§I_Pause", "§I_Resume", "§I_Show", "§I_Stop"],
				"Audio": ["§Audio", "§A_Wait", "§A_Volume", "§A_Pause", "§A_Resume", "§A_Skip", "§A_Stop"],
				"Video": ["§Video", "§V_Wait", "§V_Volume", "§V_Pause", "§V_Resume", "§V_Skip", "§V_Stop", "§V_Show"],
				"Backgrounds": ["§BG_Scene", "§BG", "§BG_Stop", "§BG_Wait", "§BG_Remove", "§BG_Mirror", "§BG_Effect", "§BG_Effect_Stop", "§BG_Effect_Wait"],
				"Visual Novels": ["§VN_Scene", "§VN_Bust", "§VN_Move", "§VN_Bust_Stop", "§VN_Mirror", "§VN_Bust_Wait", "§VN_Remove", "§VN_Effects", "§VN_Effects_Stop", "§VN_Effects_Wait"],
				"Cutscenes": ["§CS_Scene", "§CS_Visible", "§CS_Cam", "§CS_Light", "§CS_Toggle", "§CS_Move", "§CS_Anim", "§CS_Anim_Wait", "§CS_Anim_Stop", "§CS_Sprite", "§CS_Sprite_Wait", "§CS_Sprite_Stop"],
				"Custom": ["§Custom"],
			}

			#@ Spoken Line as a direct item:
			var submenu_groups = []
			for category in command_categories.keys():
				var sub_items = []
				for command in command_categories[category]:
					sub_items.append([command, command])
				submenu_groups.append([category, sub_items])
			_build_dropdown([["Spoken Line", "Spoken Line"]], submenu_groups)

		"InputScenes":
			var items = []
			for scene_name in globals.project_resources["Player_Input_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"ChoiceCategories":
			var items = []
			var line_data = main._get_choice_list_data()
			if not line_data.is_empty():
				for category_entry in line_data.get("Categories", []):
					var category_name = category_entry.keys()[0]
					items.append([category_name, category_name])
			if items.is_empty():
				_build_dropdown([["No categories available.", null]])
			else:
				_build_dropdown(items)

		"ChoiceMenuScenes":
			var items = []
			for scene_name in globals.project_resources["Choice_Menu_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"ChoiceCategoryScenes":
			var items = []
			for scene_name in globals.project_resources["Choice_Category_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"ChoiceButtonScenes":
			var items = []
			for scene_name in globals.project_resources["Choice_Button_Scenes"].keys():
				items.append([scene_name, scene_name])
			_build_dropdown(items)

		"ChoiceStatusMenuMode":
			_build_dropdown([["Last Created", "Last"], ["All", "All"], ["Tags", "Tags"]])

		"ChoiceStatusCategoryMode":
			_build_dropdown([["Last Selected", "Last"], ["All", "All"], ["Tags", "Tags"]])

		"ChoiceStatusChoiceMode":
			_build_dropdown([["Last Selected", "Last"], ["All", "All"], ["Tags", "Tags"]])

		"ChoiceStatusTimerMode":
			_build_dropdown([["Last Timeout", "Last"], ["All", "All"], ["Tags", "Tags"]])

		"ChoiceStatusEnable":
			_build_dropdown([["-", "-"], ["Enable", "Enable"], ["Disable", "Disable"], ["Toggle", "Toggle"]])

		"ChoiceStatusActivate":
			_build_dropdown([["-", "-"], ["Activate", "Activate"], ["Deactivate", "Deactivate"], ["Toggle", "Toggle"]])

		"ChoiceStatusShow":
			_build_dropdown([["-", "-"], ["Show", "Show"], ["Hide", "Hide"], ["Toggle", "Toggle"]])

		"ChoiceTransitionType":
			_build_dropdown([["Continue", "Continue"], ["Bridge", "Bridge"], ["Jump", "Jump"], ["Return", "Return"], ["End", "End"], ["Close", "Close"]])

		"ChoiceTimerAuto":
			_build_dropdown([["Start", "Start"], ["Hold", "Hold"]])

		"TimerChoiceSelect":
			var data = main._get_choice_list_data()
			if data.is_empty():
				_build_dropdown([["No categories available.", null]])
			else:
				var submenu_groups = []
				for category_entry in data.get("Categories", []):
					var category_name = category_entry.keys()[0]
					var sub_items = []
					for choice_entry in category_entry[category_name].get("Choices", []):
						var choice_name = choice_entry.keys()[0]
						sub_items.append([choice_name, category_name + ", " + choice_name])
					submenu_groups.append([category_name, sub_items])
				if submenu_groups.is_empty():
					_build_dropdown([["No categories available.", null]])
				else:
					_build_dropdown([], submenu_groups)

		"TimerStatus":
			_build_dropdown([["-", "-"], ["Start/Resume", "Start/Resume"], ["Pause", "Pause"], ["Stop", "Stop"]])

		"TimerStatusNode":
			_build_dropdown([["Ignore", "Ignore"], ["Restart", "Restart"], ["Update", "Update"]])

	_show_dropdown()


#* Build primary dropdown with optional submenu groups and audio preview:
#% items: [[label, value], ...]
#% submenu_groups: [[group_label, [[label, value], ...]], ...]
#% audio_preview: if true, hovering plays the file via main.audio_player
func _build_dropdown(items: Array, submenu_groups: Array = [], audio_preview: bool = false, video_preview: bool = false, image_preview: bool = false, bg_preview: bool = false, portrait_preview: bool = false, busts_preview: bool = false) -> void:
	var vbox = main.dropdown_list.get_node("ScrollContainer/VBoxContainer")

	#@ Add submenu trigger buttons:
	for group in submenu_groups:
		var group_label = group[0]
		var group_items = group[1]
		var group_image_preview = group[2] if group.size() > 2 else false
		var btn = Button.new()
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = group_label + " ▶"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_entered.connect(func():
			_hide_dropdown_2_delayed()
			main.image_preview_popup.hide()
			main.video_preview_popup.hide()
			globals.sprite_preview_cancelled = true
			main.sprite_preview_popup.hide()
			_build_dropdown_2(group_items, group_image_preview)
			_show_dropdown_2(btn))
		btn.mouse_exited.connect(func():
			_hide_dropdown_2_delayed())
		vbox.add_child(btn)

	#@ Add separator if both submenu groups and items exist:
#	if not submenu_groups.is_empty() and not items.is_empty():
#		vbox.add_child(HSeparator.new())

	#@ Add regular items:
	for item in items:
		var item_label = item[0]
		var value = item[1]
		var btn = Button.new()
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = item_label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if value == null:
			btn.disabled = true
		else:
			#% Audio:
			if audio_preview:
				var audio_path = item[2] if item.size() > 2 else value
				btn.mouse_entered.connect(func():
					globals.sprite_preview_cancelled = true
					main.audio_player.stop()
					if FileAccess.file_exists(audio_path):
						var stream = main._load_audio_stream(audio_path)
						if stream:
							main.audio_player.stream = stream
							main.audio_player.play())
				btn.mouse_exited.connect(func():
					main.audio_player.stop())

			#% Videos:
			if video_preview:
				main.image_preview_player.texture = null
				main.image_preview_popup.hide()
				btn.mouse_entered.connect(func():
					var video_path = item[2] if item.size() > 2 else ""
					globals.sprite_preview_cancelled = true
					if FileAccess.file_exists(video_path):
						var stream = VideoStreamTheora.new()
						stream.file = video_path
						main.video_preview_player.stop()
						main.video_preview_player.stream = stream
						var aspect = main.video_preview_player.get_video_texture().get_height() / float(main.video_preview_player.get_video_texture().get_width())
						var preview_width = globals.video_preview_width
						var preview_height = int(preview_width * aspect)
						main.video_preview_popup.size = Vector2i(preview_width, preview_height)
						main.video_preview_popup.position = Vector2i(
							main.dropdown_list.position.x + main.dropdown_list.size.x,
							main.dropdown_list.position.y
						)
						main.video_preview_popup.popup()
						main.video_preview_player.play())

				btn.mouse_exited.connect(func():
					main.video_preview_player.stop()
					main.video_preview_popup.call_deferred("hide"))

			#% Images:
			if image_preview:
				var image_path = item[2] if item.size() > 2 else ""
				main.video_preview_popup.hide()
				btn.mouse_entered.connect(func():
					main.video_preview_player.stop()
					main.video_preview_popup.hide()
					globals.sprite_preview_cancelled = true
					if FileAccess.file_exists(image_path):
						var img = Image.new()
						if img.load(image_path) == OK:
							var tex = ImageTexture.create_from_image(img)
							main.image_preview_player.texture = tex
							var aspect = float(img.get_height()) / float(img.get_width())
							var preview_width = globals.image_preview_width
							var preview_height = int(preview_width * aspect)
							main.image_preview_popup.size = Vector2i(preview_width, preview_height)
							main.image_preview_popup.position = Vector2i(
								main.dropdown_list.position.x + main.dropdown_list.size.x,
								main.dropdown_list.position.y)
							main.image_preview_popup.popup())

				btn.mouse_exited.connect(func():
					main.image_preview_player.texture = null
					main.image_preview_popup.call_deferred("hide"))

			btn.pressed.connect(func():
				_on_dropdown_item_selected(value)
				main.dropdown_list.hide())

			#% Backgrounds:
			if bg_preview:
				var file_path = item[2] if item.size() > 2 else ""
				var preview_type = item[3] if item.size() > 3 else "image"
				var sprite_match = item[4] if item.size() > 4 else null
				btn.mouse_entered.connect(func():
					main.video_preview_player.stop()
					main.video_preview_popup.hide()
					match preview_type:
						"image":
							main.video_preview_popup.hide()
							main.sprite_preview_popup.hide()
							globals.sprite_preview_cancelled = true
							if FileAccess.file_exists(file_path):
								var img = Image.new()
								if img.load(file_path) == OK:
									var tex = ImageTexture.create_from_image(img)
									main.image_preview_player.texture = tex
									var aspect = float(img.get_height()) / float(img.get_width())
									var preview_width = globals.bg_preview_width
									var preview_height = int(preview_width * aspect)
									main.image_preview_popup.size = Vector2i(preview_width, preview_height)
									main.image_preview_popup.position = Vector2i(
										main.dropdown_list.position.x + main.dropdown_list.size.x,
										main.dropdown_list.position.y)
									main.image_preview_popup.popup()

						"video":
							main.image_preview_popup.hide()
							main.sprite_preview_popup.hide()
							globals.sprite_preview_cancelled = true
							if FileAccess.file_exists(file_path):
								var stream = VideoStreamTheora.new()
								stream.file = file_path
								main.video_preview_player.stop()
								main.video_preview_player.stream = stream
								main.video_preview_popup.size = Vector2i(globals.bg_preview_width, globals.bg_preview_width)
								main.video_preview_popup.position = Vector2i(
									main.dropdown_list.position.x + main.dropdown_list.size.x,
									main.dropdown_list.position.y)
								main.video_preview_popup.popup()
								main.video_preview_player.play()

						"sprite":
							main.image_preview_popup.hide()
							main.video_preview_popup.hide()
							if FileAccess.file_exists(file_path) and sprite_match != null:
								var cols = sprite_match.get_string(1).to_int()
								var rows = sprite_match.get_string(2).to_int()
								var missing = sprite_match.get_string(3).to_int() if sprite_match.get_string(3) != "" else 0
								var total_frames = cols * rows - missing
								var img = Image.new()
								if img.load(file_path) == OK:
									var tex = ImageTexture.create_from_image(img)
									main.sprite_preview_player.texture = tex
									main.sprite_preview_player.hframes = cols
									main.sprite_preview_player.vframes = rows
									main.sprite_preview_player.frame = 0
									var frame_width = float(img.get_width()) / cols
									var frame_height = float(img.get_height()) / rows
									var aspect = frame_height / frame_width
									var preview_width = globals.bg_preview_width
									var preview_height = int(preview_width * aspect)
									var scale_factor = preview_width / frame_width
									main.sprite_preview_player.scale = Vector2(scale_factor, scale_factor)
									main.sprite_preview_popup.size = Vector2i(preview_width, preview_height)
									main.sprite_preview_popup.position = Vector2i(
										main.dropdown_list.position.x + main.dropdown_list.size.x,
										main.dropdown_list.position.y)
								main.sprite_preview_popup.popup()
								_animate_sprite_preview(total_frames)
					)

				btn.mouse_exited.connect(func():
					globals.sprite_preview_cancelled = true
					match preview_type:
						"image":
							var mouse_pos = main.get_viewport().get_mouse_position()
							var rect = Rect2(main.dropdown_list.position, main.dropdown_list.size)
							if not rect.has_point(mouse_pos):
								main.image_preview_player.texture = null
								main.image_preview_popup.call_deferred("hide")
						"video":
							main.video_preview_player.stop()
							main.video_preview_popup.call_deferred("hide")
						"sprite":
							globals.sprite_preview_cancelled = true
							main.sprite_preview_popup.call_deferred("hide")
				)

		#% Portraits:
		if portrait_preview:
			var preview_width = globals.portrait_preview_width if portrait_preview else globals.bust_preview_width
			var file_path = item[2] if item.size() > 2 else ""
			var preview_type = item[3] if item.size() > 3 else "image"
			var sprite_match = item[4] if item.size() > 4 else null

			btn.mouse_entered.connect(func():
				main.video_preview_player.stop()
				main.video_preview_popup.hide()
				match preview_type:
					"image":
						main.video_preview_popup.hide()
						main.sprite_preview_popup.hide()
						globals.sprite_preview_cancelled = true
						if FileAccess.file_exists(file_path):
							var img = Image.new()
							if img.load(file_path) == OK:
								var tex = ImageTexture.create_from_image(img)
								main.image_preview_player.texture = tex
								var aspect = float(img.get_height()) / float(img.get_width())
								var preview_height = int(preview_width * aspect)
								main.image_preview_popup.size = Vector2i(preview_width, preview_height)
								main.image_preview_popup.position = Vector2i(
									main.dropdown_list.position.x + main.dropdown_list.size.x,
									main.dropdown_list.position.y)
								main.image_preview_popup.popup()

					"video":
						main.image_preview_popup.hide()
						main.sprite_preview_popup.hide()
						globals.sprite_preview_cancelled = true
						if FileAccess.file_exists(file_path):
							var stream = VideoStreamTheora.new()
							stream.file = file_path
							main.video_preview_player.stop()
							main.video_preview_player.stream = stream
							var preview_height = preview_width
							main.video_preview_popup.size = Vector2i(preview_width, preview_height)
							main.video_preview_popup.position = Vector2i(
								main.dropdown_list.position.x + main.dropdown_list.size.x,
								main.dropdown_list.position.y)
							main.video_preview_popup.popup()
							main.video_preview_player.play()

					"sprite":
						main.image_preview_popup.hide()
						main.video_preview_popup.hide()
						if FileAccess.file_exists(file_path) and sprite_match != null:
							var cols = sprite_match.get_string(1).to_int()
							var rows = sprite_match.get_string(2).to_int()
							var missing = sprite_match.get_string(3).to_int() if sprite_match.get_string(3) != "" else 0
							var total_frames = cols * rows - missing
							var img = Image.new()
							if img.load(file_path) == OK:
								var tex = ImageTexture.create_from_image(img)
								main.sprite_preview_player.texture = tex
								main.sprite_preview_player.hframes = cols
								main.sprite_preview_player.vframes = rows
								main.sprite_preview_player.frame = 0
								var frame_width = float(img.get_width()) / cols
								var frame_height = float(img.get_height()) / rows
								var aspect = frame_height / frame_width
								var preview_height = int(preview_width * aspect)
								var scale_factor = preview_width / frame_width
								main.sprite_preview_player.scale = Vector2(scale_factor, scale_factor)
								main.sprite_preview_popup.size = Vector2i(preview_width, preview_height)
								main.sprite_preview_popup.position = Vector2i(
									main.dropdown_list.position.x + main.dropdown_list.size.x,
									main.dropdown_list.position.y)
								main.sprite_preview_popup.popup()
								_animate_sprite_preview(total_frames)
				)

			btn.mouse_exited.connect(func():
				var mouse_pos = main.get_viewport().get_mouse_position()
				var rect = Rect2(main.dropdown_list.position, main.dropdown_list.size)
				if not rect.has_point(mouse_pos):
					match preview_type:
						"image":
							main.image_preview_player.texture = null
							main.image_preview_popup.call_deferred("hide")
						"video":
							main.video_preview_player.stop()
							main.video_preview_popup.call_deferred("hide")
						"sprite":
							globals.sprite_preview_cancelled = true
							main.sprite_preview_popup.call_deferred("hide")
			)

		#% Busts:
		if busts_preview:
			var preview_width = globals.portrait_preview_width if portrait_preview else globals.bust_preview_width
			var file_path = item[2] if item.size() > 2 else ""
			var preview_type = item[3] if item.size() > 3 else "image"
			var sprite_match = item[4] if item.size() > 4 else null

			btn.mouse_entered.connect(func():
				main.video_preview_player.stop()
				main.video_preview_popup.hide()
				match preview_type:
					"image":
						main.video_preview_popup.hide()
						main.sprite_preview_popup.hide()
						globals.sprite_preview_cancelled = true
						if FileAccess.file_exists(file_path):
							var img = Image.new()
							if img.load(file_path) == OK:
								var tex = ImageTexture.create_from_image(img)
								main.image_preview_player.texture = tex
								var aspect = float(img.get_height()) / float(img.get_width())
								var preview_height = int(preview_width * aspect)
								main.image_preview_popup.size = Vector2i(preview_width, preview_height)
								main.image_preview_popup.position = Vector2i(
									main.dropdown_list.position.x + main.dropdown_list.size.x,
									main.dropdown_list.position.y)
								main.image_preview_popup.popup()

					"video":
						main.image_preview_popup.hide()
						main.sprite_preview_popup.hide()
						globals.sprite_preview_cancelled = true
						if FileAccess.file_exists(file_path):
							var stream = VideoStreamTheora.new()
							stream.file = file_path
							main.video_preview_player.stop()
							main.video_preview_player.stream = stream
							var preview_height = preview_width
							main.video_preview_popup.size = Vector2i(preview_width, preview_height)
							main.video_preview_popup.position = Vector2i(
								main.dropdown_list.position.x + main.dropdown_list.size.x,
								main.dropdown_list.position.y)
							main.video_preview_popup.popup()
							main.video_preview_player.play()

					"sprite":
						main.image_preview_popup.hide()
						main.video_preview_popup.hide()
						if FileAccess.file_exists(file_path) and sprite_match != null:
							var cols = sprite_match.get_string(1).to_int()
							var rows = sprite_match.get_string(2).to_int()
							var missing = sprite_match.get_string(3).to_int() if sprite_match.get_string(3) != "" else 0
							var total_frames = cols * rows - missing
							var img = Image.new()
							if img.load(file_path) == OK:
								var tex = ImageTexture.create_from_image(img)
								main.sprite_preview_player.texture = tex
								main.sprite_preview_player.hframes = cols
								main.sprite_preview_player.vframes = rows
								main.sprite_preview_player.frame = 0
								var frame_width = float(img.get_width()) / cols
								var frame_height = float(img.get_height()) / rows
								var aspect = frame_height / frame_width
								var preview_height = int(preview_width * aspect)
								var scale_factor = preview_width / frame_width
								main.sprite_preview_player.scale = Vector2(scale_factor, scale_factor)
								main.sprite_preview_popup.size = Vector2i(preview_width, preview_height)
								main.sprite_preview_popup.position = Vector2i(
									main.dropdown_list.position.x + main.dropdown_list.size.x,
									main.dropdown_list.position.y)
								main.sprite_preview_popup.popup()
								_animate_sprite_preview(total_frames)
				)

			btn.mouse_exited.connect(func():
				var mouse_pos = main.get_viewport().get_mouse_position()
				var rect = Rect2(main.dropdown_list.position, main.dropdown_list.size)
				if not rect.has_point(mouse_pos):
					match preview_type:
						"image":
							main.image_preview_player.texture = null
							main.image_preview_popup.call_deferred("hide")
						"video":
							main.video_preview_player.stop()
							main.video_preview_popup.call_deferred("hide")
						"sprite":
							globals.sprite_preview_cancelled = true
							main.sprite_preview_popup.call_deferred("hide")
			)

		vbox.add_child(btn)


#* Build secondary dropdown:
func _build_dropdown_2(items: Array, image_preview: bool = false) -> void:
	_cancel_hide_dropdown_2()
	var vbox = main.dropdown_list_2.get_node("ScrollContainer/VBoxContainer")
	for child in vbox.get_children():
		child.queue_free()
	for item in items:
		var item_label = item[0]
		var value = item[1]
		var btn = Button.new()
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = item_label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if image_preview and item.size() > 2:
			var image_path = item[2]
			var frame_paths = item[3] if item.size() > 3 else [image_path]
			btn.mouse_entered.connect(func():
				_cancel_hide_dropdown_2()
				globals.sprite_preview_cancelled = true
				main.sprite_preview_popup.hide()
				var sprite_regex = RegEx.new()
				sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
				var sprite_match = sprite_regex.search(image_path.get_file())
				if sprite_match and FileAccess.file_exists(image_path):
					var cols = sprite_match.get_string(1).to_int()
					var rows = sprite_match.get_string(2).to_int()
					var img = Image.new()
					if img.load(image_path) == OK:
						var tex = ImageTexture.create_from_image(img)
						main.sprite_preview_player.texture = tex
						main.sprite_preview_player.hframes = cols
						main.sprite_preview_player.vframes = rows
						main.sprite_preview_player.frame = 0
						var frame_width = float(img.get_width()) / cols
						var frame_height = float(img.get_height()) / rows
						var preview_width = globals.sprite_preview_width
						var scale_factor = float(preview_width) / frame_width
						main.sprite_preview_player.scale = Vector2(scale_factor, scale_factor)
						var preview_height = int(frame_height * scale_factor)
						main.sprite_preview_popup.size = Vector2i(preview_width, preview_height)
						main.sprite_preview_popup.position = Vector2i(
							main.dropdown_list_2.position.x + main.dropdown_list_2.size.x,
							main.dropdown_list_2.position.y)
						main.sprite_preview_popup.popup()
						_animate_cs_sprite_preview(frame_paths, preview_width))
			btn.mouse_exited.connect(func():
				globals.sprite_preview_cancelled = true
				main.sprite_preview_popup.call_deferred("hide"))
		else:
			btn.mouse_entered.connect(func():
				_cancel_hide_dropdown_2())
		btn.pressed.connect(func():
			_on_dropdown_item_selected(value)
			main.dropdown_list.hide()
			main.dropdown_list_2.hide())
		vbox.add_child(btn)


#* Position and show primary dropdown:
func _show_dropdown() -> void:
	var vbox = main.dropdown_list.get_node("ScrollContainer/VBoxContainer")
	await main.get_tree().process_frame

	if vbox.get_child_count() == 0:
		return

	var item_count = vbox.get_child_count()
	var item_height = 0.0
	var item_width = 0.0
	if item_count > 0:
		item_height = vbox.get_child(0).get_combined_minimum_size().y
	for child in vbox.get_children():
		item_width = max(item_width, child.get_combined_minimum_size().x + 8)

	var visible_items = min(item_count, 15)
	var popup_height = 4 + (item_height * visible_items)
	var popup_width = 12 + item_width

	var scroll = main.dropdown_list.get_node("ScrollContainer")
	scroll.custom_minimum_size.y = popup_height
	main.dropdown_list.size = Vector2i(int(popup_width), int(popup_height))

	var screen_height = DisplayServer.screen_get_size().y
	var field_pos = text_field.get_screen_position()
	if field_pos.y + text_field.size.y + popup_height > screen_height:
		main.dropdown_list.position = Vector2i(int(field_pos.x), int(field_pos.y) - int(popup_height))
	else:
		main.dropdown_list.position = Vector2i(int(field_pos.x), int(field_pos.y + text_field.size.y))

	main.invisishield.visible = true
	main.dropdown_list.popup()


#* Position and show secondary dropdown:
func _show_dropdown_2(trigger_btn: Button) -> void:
	_cancel_hide_dropdown_2()
	var vbox = main.dropdown_list_2.get_node("ScrollContainer/VBoxContainer")
	await main.get_tree().process_frame

	var item_count = vbox.get_child_count()
	var item_height = 0.0
	var item_width = 0.0
	if item_count > 0:
		item_height = vbox.get_child(0).get_combined_minimum_size().y
	for child in vbox.get_children():
		item_width = max(item_width, child.get_combined_minimum_size().x + 8)

	var visible_items = min(item_count, 15)
	var popup_height = 4 + (item_height * visible_items)
	var popup_width = 12 + item_width + 16

	var scroll = main.dropdown_list_2.get_node("ScrollContainer")
	scroll.custom_minimum_size.y = popup_height
	main.dropdown_list_2.size = Vector2i(int(popup_width), int(popup_height))

	var screen_height = DisplayServer.screen_get_size().y
	var btn_pos = trigger_btn.get_screen_position()
	var x = main.dropdown_list.position.x + main.dropdown_list.size.x

	var y = 0
	if btn_pos.y > screen_height / 2.0:
		y = int(btn_pos.y + trigger_btn.size.y) - int(popup_height)
	else:
		y = int(btn_pos.y)

	main.dropdown_list_2.position = Vector2i(x, y)
	main.dropdown_list_2.popup()


#* Hide secondary dropdown with delay:
func _hide_dropdown_2_delayed() -> void:
	globals.hide_dropdown_2_cancelled = false
	globals.hide_dropdown_2_timer = main.get_tree().create_timer(0.2)
	await globals.hide_dropdown_2_timer.timeout
	if globals.hide_dropdown_2_cancelled:
		return
	var mouse_pos = main.dropdown_list_2.get_mouse_position()
	var rect = Rect2(Vector2.ZERO, main.dropdown_list_2.size)
	if not rect.has_point(mouse_pos):
		main.dropdown_list_2.hide()


func _cancel_hide_dropdown_2() -> void:
	globals.hide_dropdown_2_cancelled = true


#* Handle item selection:
func _on_dropdown_item_selected(value: String) -> void:
	main.video_preview_player.stop()
	main.audio_player.stop()
	main.image_preview_popup.hide()
	main.video_preview_popup.hide()
	main.sprite_preview_popup.hide()
	globals.sprite_preview_cancelled = true
	if not append_data:
		text_field.text = value
	else:
		var current = text_field.text.strip_edges().trim_suffix(",").strip_edges()
		text_field.text = current + (", " if current != "" else "") + value
	data_entry()
	main.invisishield.visible = false


func _animate_sprite_preview(total_frames: int) -> void:
	globals.sprite_preview_cancelled = false
	while not globals.sprite_preview_cancelled:
		for i in range(total_frames):
			if globals.sprite_preview_cancelled:
				return
			main.sprite_preview_player.frame = i
			await main.get_tree().create_timer(1.0 / globals.bg_sprite_fps).timeout
		#% Hide for 1 second at end of loop:
		if not globals.sprite_preview_cancelled:
			main.sprite_preview_popup.hide()
			if not globals.sprite_preview_cancelled:
				main.sprite_preview_popup.popup()


func _animate_cs_sprite_preview(frame_paths: Array, preview_width: int) -> void:
	globals.sprite_preview_cancelled = false
	while not globals.sprite_preview_cancelled:
		for path in frame_paths:
			if globals.sprite_preview_cancelled:
				return
			var sprite_regex = RegEx.new()
			sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
			var sprite_match = sprite_regex.search(path.get_file())
			if sprite_match and FileAccess.file_exists(path):
				var cols = sprite_match.get_string(1).to_int()
				var rows = sprite_match.get_string(2).to_int()
				var missing = sprite_match.get_string(3).to_int() if sprite_match.get_string(3) != "" else 0
				var total_frames = cols * rows - missing
				var img = Image.new()
				if img.load(path) == OK:
					var tex = ImageTexture.create_from_image(img)
					main.sprite_preview_player.texture = tex
					main.sprite_preview_player.hframes = cols
					main.sprite_preview_player.vframes = rows
					var frame_width = float(img.get_width()) / cols
					var frame_height = float(img.get_height()) / rows
					var scale_factor = float(preview_width) / frame_width
					main.sprite_preview_player.scale = Vector2(scale_factor, scale_factor)
					var preview_height = int(frame_height * scale_factor)
					main.sprite_preview_popup.size = Vector2i(preview_width, preview_height)
					for i in range(total_frames):
						if globals.sprite_preview_cancelled:
							return
						main.sprite_preview_player.frame = i
						await main.get_tree().create_timer(1.0 / globals.sprite_preview_fps).timeout
			else:
				await main.get_tree().create_timer(1.0 / globals.sprite_preview_fps).timeout

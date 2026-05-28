extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var title = get_node("PromptMessage/VBox/Title")
@onready var input_field = get_node("PromptMessage/VBox/Input")
@onready var warning = get_node("PromptMessage/VBox/Warning")
@onready var message = get_node("PromptMessage/VBox/Message")
@onready var notice = get_node("PromptMessage/VBox/Notice")
@onready var error = get_node("PromptMessage/VBox/Error")
@onready var cancel_button = get_node("PromptMessage/VBox/Buttons/Cancel")
@onready var special_button = get_node("PromptMessage/VBox/Buttons/Special")
@onready var confirm_button = get_node("PromptMessage/VBox/Buttons/Confirm")

#? What the prompt menu is doing:
var prompt_type = ""
var old_editor_state = ""

#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	clear()


#* Setup when prompt menu opened:
func setup(type: String) -> void:
	old_editor_state = globals.editor_state
	globals.editor_state = "Prompt"
	#% Store prompt type:
	prompt_type = type

	#% Update editor state:
	globals.editor_state = prompt_type

	#% Setup menu:
	match prompt_type:
		"New User":
			title.text = "New User:"
			input_field.visible = true
			error.visible = true
		"New Profile":
			title.text = "New Profile:"
			input_field.visible = true
			error.visible = true
		"Rename Profile":
			title.text = "Rename Profile:"
			input_field.visible = true
			error.visible = true
		"Delete Profile":
			title.text = "Delete Profile?"
		"New Conversation":
			title.text = "New Conversation:"
			input_field.text = globals.conversation_default_name
			input_field.visible = true
			error.visible = true
		"New Block":
			title.text = "New Block:"
			input_field.text = globals.block_default_name
			input_field.visible = true
			error.visible = true
		"Rename Conversation":
			title.text = "Rename Conversation:"
			input_field.visible = true
			error.visible = true
		"Rename Block":
			title.text = "Rename Block:"
			input_field.visible = true
			error.visible = true

		"Export":
			title.text = "Export this dialogue?"
		"Import":
			title.text = "Import this dialogue?"
			warning.text = "This may overwrite the current dialogue."
			warning.visible = true

		"New Choice Category":
			title.text = "New category:"
			input_field.visible = true
			error.visible = true
		"New Choice Item":
			title.text = "New choice:"
			input_field.visible = true
			error.visible = true
		"New Choice Timer":
			title.text = "New timer:"
			input_field.visible = true
			error.visible = true
		"Rename Choice Category":
			title.text = "Rename category:"
			input_field.visible = true
			error.visible = true
		"Rename Choice Item":
			title.text = "Rename choice:"
			input_field.visible = true
			error.visible = true
		"Rename Choice Timer":
			title.text = "Rename timer:"
			input_field.visible = true
			error.visible = true

		"New Language":
			title.text = "New language:"
			input_field.visible = true
			error.visible = true
		"New Variant":
			title.text = "New variant:"
			input_field.visible = true
			error.visible = true
		"Rename_Language":
			title.text = "Rename Language: " + main.settings_menu.to_delete_or_rename
			input_field.visible = true
			error.visible = true
		"Rename_Variant":
			title.text = "Rename Variant: " + main.settings_menu.to_delete_or_rename
			input_field.visible = true
			error.visible = true
		"Delete Language":
			title.text = "Delete Language: " + main.settings_menu.to_delete_or_rename
			warning.text = "WARNING: This will delete all text for this language and its variants inside all Spoken Lines. Proceed?"
			warning.visible = true
		"Delete Variant":
			title.text = "Delete Variant: " + main.settings_menu.to_delete_or_rename
			warning.text = "WARNING: This will delete all text for this variant, for all languages, inside all Spoken Lines. Proceed?"
			warning.visible = true

		"New Dialogue":
			title.text = "Create new dialogue?"
			warning.text = "You will lose any unsaved work in the current dialogue."
			warning.visible = true

		"Change Profile":
			title.text = "Change profile?"
			warning.text = "You will lose any unsaved work in the current dialogue."
			warning.visible = true

		"Quit":
			confirm_button.text = "EXIT"
			title.text = "Exit Candy DC:"
			warning.text = "WARNING: You have unsaved work. Exit anyway?"
			warning.visible = true

		_:		#/ Cancel opening the prompt menu
			return

	if input_field.visible == true:
		input_field.grab_focus()
		input_field.set_caret_column(input_field.text.length())
	elif cancel_button.visible == true:
		cancel_button.grab_focus()
	elif confirm_button.visible == true:
		cancel_button.grab_focus()

	#% Make menu visible after setup:
	self.visible = true


#* Clear prompt menu when cancel:
func clear() -> void:
	self.visible = false
	title.text = ""
	warning.visible = false
	warning.text = ""
	message.visible = false
	message.text = ""
	input_field.text = ""
	input_field.visible = false
	notice.text = ""
	notice.visible = false
	error.text = ""
	error.visible = false
	cancel_button.visible = true
	cancel_button.text = "Cancel"
	special_button.visible = false
	special_button.text = "Special"
	confirm_button.visible = true
	confirm_button.text = "Confirm"
	prompt_type = ""
	globals.editor_state = old_editor_state


#* Confirm button pressed:
func _on_confirm_pressed() -> void:
	#@ Match prompt_type logic:
	match prompt_type:
		"New User":
			var user_name = input_field.text.strip_edges()
			if user_name == "":
				return
			#% Check for invalid characters:
			var invalid_chars = RegEx.new()
			invalid_chars.compile("[/\\\\:*?\"<>|]")
			if invalid_chars.search(user_name):
				error.text = "Only letters, numbers, spaces, hyphens and underscores are allowed."
				return
			#% Check if folder already exists:
			if DirAccess.dir_exists_absolute("user://" + user_name):
				error.text = "A user with that name already exists."
				return
			main.landing_screen.create_user(user_name)

		"New Profile":
			var profile_name = input_field.text.strip_edges()
			if profile_name == "":
				return
			#% Check for invalid characters:
			var invalid_chars_p = RegEx.new()
			invalid_chars_p.compile("[/\\\\:*?\"<>|]")
			if invalid_chars_p.search(profile_name):
				error.text = "Only letters, numbers, spaces, hyphens and underscores are allowed."
				return
			#% Check if profile already exists:
			var profile_path = "user://Users/" + main.landing_screen.selected_user + "/" + profile_name
			if DirAccess.dir_exists_absolute(profile_path):
				error.text = "A profile with that name already exists."
				return
			main.landing_screen.create_profile(profile_name)

		"Rename Profile":
			var new_name = input_field.text.strip_edges()
			if new_name == "":
				return
			#% Check for invalid characters:
			var invalid_chars_r = RegEx.new()
			invalid_chars_r.compile("[/\\\\:*?\"<>|]")
			if invalid_chars_r.search(new_name):
				error.text = "Only letters, numbers, spaces, hyphens and underscores are allowed."
				return
			#% Check if profile already exists:
			var new_path = "user://Users/" + main.landing_screen.selected_user + "/" + new_name
			if DirAccess.dir_exists_absolute(new_path):
				error.text = "A profile with that name already exists."
				return
			main.landing_screen.rename_profile(new_name)

		"Delete Profile":
			main.landing_screen.delete_profile()

		"New Conversation":
			var conv_name = input_field.text.strip_edges()
			if conv_name == "":
				return
			#% Check for reserved names:
			if conv_name == "USER PRESETS" or conv_name == "PROFILE PRESETS":
				error.text = "That name is reserved."
				return
			#% Check if conversation already exists:
			if globals.dialogue.has(conv_name):
				error.text = "A conversation with that name already exists."
				return
			main.create_new_conversation(conv_name)

		"New Block":
			var block_name = input_field.text.strip_edges()
			if block_name == "":
				return
			#% Check if block already exists in current conversation:
			if globals.dialogue.has(globals.current_conversation) and globals.dialogue[globals.current_conversation].has(block_name):
				error.text = "A block with that name already exists in this conversation."
				return
			main.create_new_block(block_name)

		"Rename Conversation":
			var conv_name = input_field.text.strip_edges()
			if conv_name == "":
				return
			#% Check for reserved names:
			if conv_name == "USER PRESETS" or conv_name == "PROFILE PRESETS":
				error.text = "That name is reserved."
				return
			#% Check if conversation already exists:
			if globals.dialogue.has(conv_name):
				error.text = "A conversation with that name already exists."
				return
			main.rename_conversation(conv_name)

		"Rename Block":
			var block_name = input_field.text.strip_edges()
			if block_name == "":
				return
			#% Check if block already exists in current conversation:
			if globals.dialogue.has(globals.current_conversation) and globals.dialogue[globals.current_conversation].has(block_name):
				error.text = "A block with that name already exists in this conversation."
				return
			main.rename_block(block_name)

		"New Language":
			var language_name = input_field.text.strip_edges()
			if language_name == "":
				return
			#% Check for invalid characters:
			if " " in language_name or "_" in language_name:
				error.text = "Language names cannot contain spaces or underscores."
				return
			#% Check if language already exists:
			if globals.languages.has(language_name):
				error.text = "A language with that name already exists."
				return
			main.settings_menu.create_language(language_name)

		"New Variant":
			var variant_name = input_field.text.strip_edges()
			if variant_name == "":
				return
			#% Check that name starts with underscore and has no spaces:
			if not variant_name.begins_with("_"):
				error.text = "Variant names must start with an underscore."
				return
			if " " in variant_name:
				error.text = "Variant names cannot contain spaces."
				return
			#% Check if variant already exists:
			if globals.variants.has(variant_name):
				error.text = "A variant with that name already exists."
				return
			main.settings_menu.create_variant(variant_name)

		"Rename Language":
			var language_name = input_field.text.strip_edges()
			if language_name == "":
				return
			if " " in language_name or "_" in language_name:
				error.text = "Language names cannot contain spaces or underscores."
				return
			if globals.languages.has(language_name):
				error.text = "A language with that name already exists."
				return
			main.settings_menu._rename_language(language_name)

		"Rename Variant":
			var variant_name = input_field.text.strip_edges()
			if variant_name == "":
				return
			if not variant_name.begins_with("_"):
				error.text = "Variant names must start with an underscore."
				return
			if " " in variant_name:
				error.text = "Variant names cannot contain spaces."
				return
			if globals.variants.has(variant_name):
				error.text = "A variant with that name already exists."
				return
			main.settings_menu._rename_variant(variant_name)

		"Delete Language":
			main.settings_menu._delete_language(main.settings_menu.to_delete_or_rename)

		"Delete Variant":
			main.settings_menu._delete_variant(main.settings_menu.to_delete_or_rename)

		"New Choice Category":
			var category_name = input_field.text.strip_edges()
			if category_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for category_entry in data.get("Categories", []):
				if category_entry.keys()[0] == category_name:
					error.text = "A category with that name already exists."
					return
			main._add_choice_category(category_name)

		"New Choice Item":
			var choice_name = input_field.text.strip_edges()
			if choice_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for category_entry in data.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == choice_name:
							error.text = "A choice with that name already exists in this category."
							return
					break
			main._add_choice_item(choice_name)

		"New Choice Timer":
			var timer_name = input_field.text.strip_edges()
			if timer_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for timer_entry in data.get("Timers", []):
				if timer_entry.keys()[0] == timer_name:
					error.text = "A timer with that name already exists."
					return
			main._add_choice_timer(timer_name)

		"Rename Choice Category":
			var category_name = input_field.text.strip_edges()
			if category_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for category_entry in data.get("Categories", []):
				if category_entry.keys()[0] == category_name:
					error.text = "A category with that name already exists."
					return
			main._rename_choice_category(category_name)

		"Rename Choice Item":
			var choice_name = input_field.text.strip_edges()
			if choice_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for category_entry in data.get("Categories", []):
				if category_entry.keys()[0] == globals.current_choice_category:
					for choice_entry in category_entry[globals.current_choice_category].get("Choices", []):
						if choice_entry.keys()[0] == choice_name:
							error.text = "A choice with that name already exists in this category."
							return
					break
			main._rename_choice_item(choice_name)

		"Rename Choice Timer":
			var timer_name = input_field.text.strip_edges()
			if timer_name == "":
				return
			var data = main._get_choice_list_data()
			if data.is_empty():
				return
			for timer_entry in data.get("Timers", []):
				if timer_entry.keys()[0] == timer_name:
					error.text = "A timer with that name already exists."
					return
			main._rename_choice_timer(timer_name)

		"Export":
			main.export_menu.export_dialogue()

		"Import":
			main.import_menu.import_dialogue()

		"New Dialogue":
			main.new_dialogue()

		"Change Profile":
			main.change_profile()

		"Quit":
			await main.save_profile()
			await get_tree().process_frame
			get_tree().quit()

		_:
			pass

	#@ If no errors, return:
	clear()


#* Cancel button pressed:
func _on_cancel_pressed() -> void:
	#@ Match prompt_type logic:
	match prompt_type:
		_:
			clear()


#* Special button pressed:
func _on_special_pressed() -> void:
	match prompt_type:
		_:
			pass

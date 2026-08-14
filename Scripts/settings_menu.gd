extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var project_path = get_node("Menu/VBox/Tabs/ProjectPaths/VBox/Project/Path/LineEdit")
@onready var path_inputs = get_node("Menu/VBox/Tabs/ProjectPaths/VBox/SubPaths/PathInputs")
@onready var project_data_normal = get_node("Menu/VBox/Tabs/ProjectData/ScrollContainer/VBox/Normal")

@onready var message = get_node("Menu/VBox/Message")

@onready var variant_tree = get_node("Menu/VBox/Tabs/Variants/VBox/Tree")

@onready var symbol_script_path_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Script/LineEdit")
@onready var singleton_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Singleton/LineEdit")
@onready var node_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Node/LineEdit")
@onready var vardict_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Vardict/LineEdit")
@onready var super_singleton_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/SuperSingleton/LineEdit")
@onready var super_node_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/SuperNode/LineEdit")
@onready var super_vardict_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/SuperVardict/LineEdit")
@onready var role_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Role/LineEdit")
@onready var speech_start_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/SpeechStart/LineEdit")
@onready var speech_end_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/SpeechEnd/LineEdit")
@onready var substitution_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Substitution/LineEdit")
@onready var separator_symbol_field = get_node("Menu/VBox/Tabs/Symbols/VBox/Separator/LineEdit")

@onready var line_color_list = get_node("Menu/VBox/Tabs/Colors/Line Colors/VBox/ScrollContainer/VBox")

var to_delete_or_rename = ""

#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Menu/VBox/Tabs/Preferences".visible = true
	setup()

	variant_tree.button_clicked.connect(_on_variant_tree_button_clicked)
	variant_tree.item_mouse_selected.connect(_on_variant_tree_item_mouse_button)

	create_project_data_input()
	refresh_variant_tree()


func create_project_data_input() -> void:
	for child in project_data_normal.get_children():
		child.queue_free()
	for key in globals.project_scripts.keys():
		var input = load("res://Scenes/ProjectData.tscn").instantiate()
		input.set_meta("project_data_key", key)
		project_data_normal.add_child(input)


#* Setup the Settings Menu data fields when menu opens:
func setup() -> void:
	#@ Preferences:
	#% Default Conversation/Block names:
	$"Menu/VBox/Tabs/Preferences/VBox/NewConversation/LineEdit".text = globals.conversation_new_name
	$"Menu/VBox/Tabs/Preferences/VBox/DefaultBlock/LineEdit".text = globals.block_default_name
	$"Menu/VBox/Tabs/Preferences/VBox/NewBlock/LineEdit".text = globals.block_new_name

	#% Save settings:
	$"Menu/VBox/Tabs/Preferences/VBox/Save/LineEdit".select(globals.default_save_mode)
	$"Menu/VBox/Tabs/Preferences/VBox/QuickSaves/LineEdit".text = globals.quick_saves_max
	$"Menu/VBox/Tabs/Preferences/VBox/AutoSaves/LineEdit".text = globals.auto_saves_max
	$"Menu/VBox/Tabs/Preferences/VBox/AutoSaveFreq/LineEdit".text = globals.auto_save_freq

	#% Warning display:
	$"Menu/VBox/Tabs/Preferences/VBox/WarningDuration/LineEdit".text = globals.warning_display_time

	#% Speech limit settings:
	$"Menu/VBox/Tabs/Preferences/VBox/Limit/LineEdit".text = globals.spoken_text_limit
	$"Menu/VBox/Tabs/Preferences/VBox/NearLimit/LineEdit".text = globals.limit_margin

	#% Undo settings:
	$"Menu/VBox/Tabs/Preferences/VBox/UndoMinSteps/LineEdit".text = str(globals.undo_steps_min)
	$"Menu/VBox/Tabs/Preferences/VBox/UndoMaxSteps/LineEdit".text = str(globals.undo_steps_max)
	$"Menu/VBox/Tabs/Preferences/VBox/UndoMinMemory/LineEdit".text = str(globals.undo_memory_min)
	$"Menu/VBox/Tabs/Preferences/VBox/UndoMaxMemory/LineEdit".text = str(globals.undo_memory_max)

	#% Preview settings:
	$"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewWidth/LineEdit".text = str(globals.portrait_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewFPS/LineEdit".text = str(globals.portrait_sprite_fps)
	$"Menu/VBox/Tabs/Preferences/VBox/BustPreviewWidth/LineEdit".text = str(globals.bust_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/BustPreviewFPS/LineEdit".text = str(globals.bust_sprite_fps)
	$"Menu/VBox/Tabs/Preferences/VBox/SpritePreviewWidth/LineEdit".text = str(globals.sprite_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/SpritePreviewFPS/LineEdit".text = str(globals.sprite_preview_fps)
	$"Menu/VBox/Tabs/Preferences/VBox/VideoPreviewWidth/LineEdit".text = str(globals.video_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/ImagePreviewWidth/LineEdit".text = str(globals.image_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/BGPreviewWidth/LineEdit".text = str(globals.bg_preview_width)
	$"Menu/VBox/Tabs/Preferences/VBox/BGPreviewFPS/LineEdit".text = str(globals.bg_sprite_fps)

	#@ Load symbols:
	symbol_script_path_field.text = globals.symbol_script_path
	singleton_symbol_field.text = globals.singleton_symbol
	node_symbol_field.text = globals.node_symbol
	vardict_symbol_field.text = globals.vardict_symbol
	super_singleton_symbol_field.text = globals.super_singleton_symbol
	super_node_symbol_field.text = globals.super_node_symbol
	super_vardict_symbol_field.text = globals.super_vardict_symbol
	role_symbol_field.text = globals.role_symbol
	speech_start_symbol_field.text = globals.text_var_symbol_start
	speech_end_symbol_field.text = globals.text_var_symbol_end
	substitution_symbol_field.text = globals.substitution_symbol
	separator_symbol_field.text = globals.separator_symbol

	#@ Project Paths:
	project_path.text = globals.project_path
	for child in path_inputs.get_children():
		child.update_data()

	#@ Load project data:
	for child in project_data_normal.get_children():
		child.load_data()

	#@ Load languages and variants:
	refresh_variant_tree()

#* Close Settings Menu:
func _on_close_pressed() -> void:
	self.visible = false
	globals.editor_state = "Main"

	#@ Update numerical values if the value is a valid type:
	if $"Menu/VBox/Tabs/Preferences/VBox/WarningDuration/LineEdit".text.is_valid_float():
		globals.warning_display_time = $"Menu/VBox/Tabs/Preferences/VBox/WarningDuration/LineEdit".text

	if $"Menu/VBox/Tabs/Preferences/VBox/QuickSaves/LineEdit".text.is_valid_int():
		globals.quick_saves_max = $"Menu/VBox/Tabs/Preferences/VBox/QuickSaves/LineEdit".text
	if $"Menu/VBox/Tabs/Preferences/VBox/AutoSaves/LineEdit".text.is_valid_int():
		globals.auto_saves_max = $"Menu/VBox/Tabs/Preferences/VBox/AutoSaves/LineEdit".text
	if $"Menu/VBox/Tabs/Preferences/VBox/AutoSaveFreq/LineEdit".text.is_valid_int():
		globals.auto_save_freq = $"Menu/VBox/Tabs/Preferences/VBox/AutoSaveFreq/LineEdit".text

	if $"Menu/VBox/Tabs/Preferences/VBox/Limit/LineEdit".text.is_valid_int():
		globals.spoken_text_limit = $"Menu/VBox/Tabs/Preferences/VBox/Limit/LineEdit".text
	if $"Menu/VBox/Tabs/Preferences/VBox/NearLimit/LineEdit".text.is_valid_int():
		globals.limit_margin = $"Menu/VBox/Tabs/Preferences/VBox/NearLimit/LineEdit".text

	if $"Menu/VBox/Tabs/Preferences/VBox/UndoMinSteps/LineEdit".text.is_valid_int():
		globals.undo_steps_min = int($"Menu/VBox/Tabs/Preferences/VBox/UndoMinSteps/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/UndoMaxSteps/LineEdit".text.is_valid_int():
		globals.undo_steps_max = int($"Menu/VBox/Tabs/Preferences/VBox/UndoMaxSteps/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/UndoMinMemory/LineEdit".text.is_valid_int():
		globals.undo_memory_min = int($"Menu/VBox/Tabs/Preferences/VBox/UndoMinMemory/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/UndoMaxMemory/LineEdit".text.is_valid_int():
		globals.undo_memory_max = int($"Menu/VBox/Tabs/Preferences/VBox/UndoMaxMemory/LineEdit".text)

	if $"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewWidth/LineEdit".text.is_valid_int():
		globals.portrait_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewFPS/LineEdit".text.is_valid_float():
		globals.portrait_sprite_fps = float($"Menu/VBox/Tabs/Preferences/VBox/PortraitPreviewFPS/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BustPreviewWidth/LineEdit".text.is_valid_int():
		globals.bust_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/BustPreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BustPreviewFPS/LineEdit".text.is_valid_float():
		globals.bust_sprite_fps = float($"Menu/VBox/Tabs/Preferences/VBox/BustPreviewFPS/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BustPreviewWidth/LineEdit".text.is_valid_int():
		globals.sprite_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/SpritePreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BustPreviewFPS/LineEdit".text.is_valid_float():
		globals.sprite_preview_fps = float($"Menu/VBox/Tabs/Preferences/VBox/SpritePreviewFPS/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/VideoPreviewWidth/LineEdit".text.is_valid_int():
		globals.video_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/VideoPreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/ImagePreviewWidth/LineEdit".text.is_valid_int():
		globals.image_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/ImagePreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BGPreviewWidth/LineEdit".text.is_valid_int():
		globals.bg_preview_width = int($"Menu/VBox/Tabs/Preferences/VBox/BGPreviewWidth/LineEdit".text)
	if $"Menu/VBox/Tabs/Preferences/VBox/BGPreviewFPS/LineEdit".text.is_valid_float():
		globals.bg_sprite_fps = float($"Menu/VBox/Tabs/Preferences/VBox/BGPreviewFPS/LineEdit".text)

	#@ Save project data inputs:
	for child in project_data_normal.get_children():
		child.save_data()

	#@ Save symbols:
	globals.symbol_script_path = symbol_script_path_field.text
	globals.singleton_symbol = singleton_symbol_field.text
	globals.node_symbol = node_symbol_field.text
	globals.vardict_symbol = vardict_symbol_field.text
	globals.super_singleton_symbol = super_singleton_symbol_field.text
	globals.super_node_symbol = super_node_symbol_field.text
	globals.super_vardict_symbol = super_vardict_symbol_field.text
	globals.role_symbol = role_symbol_field.text
	globals.text_var_symbol_start = speech_start_symbol_field.text
	globals.text_var_symbol_end = speech_end_symbol_field.text
	globals.substitution_symbol = substitution_symbol_field.text
	globals.separator_symbol = separator_symbol_field.text

	#@ Update symbol inserts buttons:
	main.update_variable_insert_buttons()

	#@ Scan project resources:
	main.scan_project_resources()

	#@ Refresh variant/translation trees in spoken lines in case of new variants/languages:
	main.refresh_variant_tree()
	main.refresh_translation_tree()
	main.display_line_data(globals.current_line_type)

	main.save_profile()

#& Project Paths:
#* Type new project path:
func _on_project_path_changed(new_text: String) -> void:
	globals.project_path = new_text

#* Open the file browser:
func _on_project_file_browser_pressed() -> void:
	main.shield.visible = true
	main.path_dialogue.target_path = "Project"
	main.path_dialogue.title = "Select Project Folder"
	main.path_dialogue.visible = true

func _on_new_conversation_changed(new_text: String) -> void:
	globals.conversation_new_name = new_text

func _on_default_block_text_changed(new_text: String) -> void:
	globals.block_default_name = new_text

func _on_new_block_text_changed(new_text: String) -> void:
	globals.block_new_name = new_text


func _on_save_mode_selected(index: int) -> void:
	globals.default_save_mode = index


#& Variants Tab:
func _on_add_language_pressed() -> void:
	main.prompt_menu.setup("New Language")


func _on_add_variant_pressed() -> void:
	main.prompt_menu.setup("New Variant")


func create_language(language_string: String, direction: String) -> void:
	var language_list = language_string.split(",")
	for language in language_list:
		language = language.strip_edges()
		var variants_dict = {}
		for variant in globals.variants:
			variants_dict[variant] = {}
		globals.languages[language] = {
			"Default_Direction": direction,
			"Variants": variants_dict,
		}

	main._populate_all_spoken_lines()
	refresh_variant_tree()
	main.save_undo_step()

func create_variant(variant_string: String) -> void:
	var variant_list = variant_string.split(",")
	for variant in variant_list:
		variant = variant.strip_edges()
		globals.variants[variant] = {}
		for language in globals.languages:
			globals.languages[language]["Variants"][variant] = {}

	main._populate_all_spoken_lines()
	refresh_variant_tree()
	main.save_undo_step()

func refresh_variant_tree() -> void:
	variant_tree.clear()
	variant_tree.columns = 3
	variant_tree.set_column_expand(0, false)
	variant_tree.set_column_custom_minimum_width(0, 40)
	variant_tree.set_column_expand(1, true)
	variant_tree.set_column_expand(2, false)
	variant_tree.set_column_custom_minimum_width(2, 60)
	var root = variant_tree.create_item()
	variant_tree.hide_root = true
	var languages_sorted = globals.languages.keys()
	languages_sorted.erase("Default")
	languages_sorted.sort()
	languages_sorted.push_front("Default")

	for language in languages_sorted:
		var lang_item = variant_tree.create_item(root)
		lang_item.set_metadata(0, {"type": "language", "language": language})
		lang_item.add_button(0, preload("res://Resources/Delete Icon.png"))
		lang_item.set_text(1, language)
		var direction = globals.languages[language]["Default_Direction"]
		lang_item.add_button(2, preload("res://Resources/LtR.png") if direction == "LtR" else preload("res://Resources/RtL.png"))
		var variants_sorted = globals.languages[language]["Variants"].keys()
		variants_sorted.erase("")
		variants_sorted.sort()
		variants_sorted.push_front("")

		for variant in variants_sorted:
			var combined = language + variant
			var var_item = variant_tree.create_item(lang_item)
			var_item.set_metadata(0, {"type": "variant", "language": language, "variant": variant, "combined": combined})
			var_item.add_button(0, preload("res://Resources/Delete Icon.png"))
			var_item.set_text(1, "    " + combined)
			var is_disabled = combined in globals.disabled_variants
			var_item.add_button(2, preload("res://Resources/Auto_Off.png") if is_disabled else preload("res://Resources/Auto_On.png"))


func _on_variant_tree_button_clicked(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	var meta = item.get_metadata(0)
	if column == 0:
		if meta["type"] == "language":
			to_delete_or_rename = meta["language"]
			main.prompt_menu.setup("Delete Language")
		elif meta["type"] == "variant":
			to_delete_or_rename = meta["variant"]
			main.prompt_menu.setup("Delete Variant")
	elif column == 2:
		if meta["type"] == "language":
			var current = globals.languages[meta["language"]]["Default_Direction"]
			globals.languages[meta["language"]]["Default_Direction"] = "RtL" if current == "LtR" else "LtR"
			refresh_variant_tree()
		elif meta["type"] == "variant":
			var combined = meta["combined"]
			if combined in globals.disabled_variants:
				globals.disabled_variants.erase(combined)
			else:
				globals.disabled_variants.append(combined)
			refresh_variant_tree()


func _on_variant_tree_item_mouse_button(_mouse_pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	main.settings_variant_context_menu.clear()
	main.settings_variant_context_menu.add_item("Rename", 0)
	main.settings_variant_context_menu.add_item("Delete", 1)
	main.settings_variant_context_menu.position = Vector2i(get_viewport().get_mouse_position())
	main.settings_variant_context_menu.popup()


func _on_settings_variant_context_menu_id_pressed(id: int) -> void:
	var item = variant_tree.get_selected()
	if item == null:
		return
	var meta = item.get_metadata(0)
	match id:
		0: #% Rename
			if meta["type"] == "language":
				to_delete_or_rename = meta["language"]
				main.prompt_menu.setup("Rename Language")
			elif meta["type"] == "variant":
				to_delete_or_rename = meta["variant"]
				main.prompt_menu.setup("Rename Variant")
		1: #% Delete
			if meta["type"] == "language":
				to_delete_or_rename = meta["language"]
				main.prompt_menu.setup("Delete Language")
			elif meta["type"] == "variant":
				to_delete_or_rename = meta["variant"]
				main.prompt_menu.setup("Delete Variant")


func _delete_language(language: String) -> void:
	if language == "Default":
		main.show_warning("Can't delete language \"Default\".")
		return
	if globals.languages.size() <= 1:
		main.show_warning("[color=yellow]Cannot delete the last language.[/color]")
		return

	globals.languages.erase(language)

	#@ Remove from dialogue and presets:
	for source in [globals.dialogue, globals.user_presets, globals.profile_presets]:
		for conv in source.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					var spoken_lines = main._get_spoken_lines_from_entry(line_entry)
					for spoken in spoken_lines:
						var variants = spoken.get("Variants", [])
						var cleaned = []
						for entry in variants:
							var key = entry.keys()[0]
							if key != language and not key.begins_with(language + "_"):
								cleaned.append(entry)
						spoken["Variants"] = cleaned

	_reset_variant_selection()
	refresh_variant_tree()
	main.export_user_presets()
	main.export_profile_presets()
	main.save_undo_step()


func _delete_variant(variant: String) -> void:
	if variant == "":
		main.show_warning("Can't delete variant \"\".")
		return
	if globals.variants.size() <= 1:
		main.show_warning("[color=yellow]Cannot delete the last variant.[/color]")
		return

	globals.variants.erase(variant)
	
	#@ Remove from all languages:
	for language in globals.languages:
		globals.languages[language]["Variants"].erase(variant)

	#@ Remove from dialogue and presets:
	for source in [globals.dialogue, globals.user_presets, globals.profile_presets]:
		for conv in source.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					var spoken_lines = main._get_spoken_lines_from_entry(line_entry)
					for spoken in spoken_lines:
						var variants = spoken.get("Variants", [])
						var cleaned = []
						for entry in variants:
							var key = entry.keys()[0]
							var underscore = key.find("_")
							var key_variant = "" if underscore == -1 else key.substr(underscore)
							if key_variant != variant:
								cleaned.append(entry)
						spoken["Variants"] = cleaned

	_reset_variant_selection()
	refresh_variant_tree()
	main.export_user_presets()
	main.export_profile_presets()
	main.save_undo_step()


func _reset_variant_selection() -> void:
	var default_exists = globals.languages.has("Default")
	var fallback = "Default" if default_exists else ""
	if fallback == "" and not globals.languages.is_empty():
		var first_lang = globals.languages.keys()[0]
		fallback = first_lang + globals.languages[first_lang]["Variants"].keys()[0]

	if not _variant_exists(globals.current_variant):
		globals.current_variant = fallback
	if not _variant_exists(globals.current_translation):
		globals.current_translation = fallback


func _variant_exists(combined: String) -> bool:
	for language in globals.languages:
		for variant in globals.languages[language]["Variants"]:
			if language + variant == combined:
				return true
	return false


func _rename_language(new_name: String) -> void:
	var item = variant_tree.get_selected()
	if item == null:
		return
	var old_name = item.get_metadata(0)["language"]

	#@ Rename in globals.languages:
	var language_data = globals.languages[old_name]
	globals.languages.erase(old_name)
	globals.languages[new_name] = language_data

	#@ Update globals.current_variant and current_translation:
	if globals.current_variant.begins_with(old_name + "_") or globals.current_variant == old_name:
		globals.current_variant = new_name + globals.current_variant.substr(old_name.length())
	if globals.current_translation.begins_with(old_name + "_") or globals.current_translation == old_name:
		globals.current_translation = new_name + globals.current_translation.substr(old_name.length())

	#@ Update spoken lines in dialogue and presets:
	for source in [globals.dialogue, globals.user_presets, globals.profile_presets]:
		for conv in source.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					var spoken_lines = main._get_spoken_lines_from_entry(line_entry)
					for spoken in spoken_lines:
						for entry in spoken.get("Variants", []):
							var key = entry.keys()[0]
							if key == old_name or key.begins_with(old_name + "_"):
								var new_key = new_name + key.substr(old_name.length())
								var data = entry[key]
								entry.erase(key)
								entry[new_key] = data

	main.export_user_presets()
	main.export_profile_presets()
	_reset_variant_selection()
	refresh_variant_tree()
	main.save_undo_step()


func _rename_variant(new_name: String) -> void:
	var item = variant_tree.get_selected()
	if item == null:
		return
	var old_name = item.get_metadata(0)["variant"]

	#@ Rename in globals.variants:
	var variant_data = globals.variants[old_name]
	globals.variants.erase(old_name)
	globals.variants[new_name] = variant_data

	#@ Rename in all languages:
	for language in globals.languages:
		if globals.languages[language]["Variants"].has(old_name):
			var vdata = globals.languages[language]["Variants"][old_name]
			globals.languages[language]["Variants"].erase(old_name)
			globals.languages[language]["Variants"][new_name] = vdata

	#@ Update globals.current_variant and current_translation:
	if globals.current_variant.ends_with(old_name):
		globals.current_variant = globals.current_variant.substr(0, globals.current_variant.length() - old_name.length()) + new_name
	if globals.current_translation.ends_with(old_name):
		globals.current_translation = globals.current_translation.substr(0, globals.current_translation.length() - old_name.length()) + new_name

	#@ Update spoken lines in dialogue and presets:
	for source in [globals.dialogue, globals.user_presets, globals.profile_presets]:
		for conv in source.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					var spoken_lines = main._get_spoken_lines_from_entry(line_entry)
					for spoken in spoken_lines:
						for entry in spoken.get("Variants", []):
							var key = entry.keys()[0]
							var underscore = key.find("_")
							var key_variant = "" if underscore == -1 else key.substr(underscore)
							if key_variant == old_name:
								var key_language = key if underscore == -1 else key.substr(0, underscore)
								var new_key = key_language + new_name
								var data = entry[key]
								entry.erase(key)
								entry[new_key] = data

	main.export_user_presets()
	main.export_profile_presets()
	_reset_variant_selection()
	refresh_variant_tree()
	main.save_undo_step()


#* Line color logic:
func _populate_line_color_list() -> void:
	for child in line_color_list.get_children():
		child.queue_free()
	for key in globals.line_colors.keys():
		var item = load("res://Scenes/LineColorItem.tscn").instantiate()
		var label = item.get_node("HBox/Line")
		var text_picker = item.get_node("HBox/HBox/Text")
		var bg_picker = item.get_node("HBox/HBox/BG")

		text_picker.color = globals.line_colors[key]["Text"]
		bg_picker.color = globals.line_colors[key]["BG"]

		var update_preview = func():
			label.clear()
			label.push_bgcolor(bg_picker.color)
			label.push_color(text_picker.color)
			label.add_text(key)
			label.pop()
			label.pop()

		update_preview.call()

		text_picker.color_changed.connect(func(color: Color):
			globals.line_colors[key]["Text"] = color
			update_preview.call()
			main.update_line_list())
		bg_picker.color_changed.connect(func(color: Color):
			globals.line_colors[key]["BG"] = color
			update_preview.call()
			main.update_line_list())

		line_color_list.add_child(item)


#* Open a file dialogue to find the .gd script that contains the Candy DE symbols:
func _on_symbols_script_path_pressed() -> void:
	main.script_dialogue.target_script = self
	if globals.project_path != "" and DirAccess.dir_exists_absolute(globals.project_path):
		main.script_dialogue.current_path = globals.project_path + "/"
		main.script_dialogue.root_subfolder = globals.project_path
	else:
		main.script_dialogue.current_path = "user://"
	main.shield.visible = true
	main.script_dialogue.visible = true


#* Update the Candy DE symbols:
func _on_symbols_update_pressed() -> void:
	var script_path = globals.project_path.path_join(symbol_script_path_field.text.strip_edges())
	if not FileAccess.file_exists(script_path):
		push_error("Script file not found: " + script_path)
		return

	var file := FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + script_path)
		return
	var content := file.get_as_text()
	file.close()

	#@ Match: var variable_name = "value"
	var symbol_fields := {
		"singleton_symbol": singleton_symbol_field,
		"node_symbol": node_symbol_field,
		"vardict_symbol": vardict_symbol_field,
		"super_singleton_symbol": super_singleton_symbol_field,
		"super_node_symbol": super_node_symbol_field,
		"super_vardict_symbol": super_vardict_symbol_field,
		"role_symbol": role_symbol_field,
		"text_var_symbol_start": speech_start_symbol_field,
		"text_var_symbol_end": speech_end_symbol_field,
		"substitution_symbol": substitution_symbol_field,
		"separator_symbol": separator_symbol_field,
	}

	for var_name in symbol_fields.keys():
		var r := RegEx.new()
		r.compile("var\\s+" + var_name + "\\s*=\\s*\"([^\"]*)\"")
		var result = r.search(content)
		if result:
			symbol_fields[var_name].text = result.get_string(1)
		else:
			push_error("Variable not found in script: " + var_name)

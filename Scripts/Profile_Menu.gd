extends CanvasLayer

@onready var main = get_node("/root/UI")

var selected_profile = ""

var name_mode = ""

func _ready() -> void:
	refresh_profile_list()


#* Select a profile from the list:
func _on_item_list_item_selected(index: int) -> void:
	var list: ItemList = $"ProfileList"
	selected_profile = list.get_item_text(index)


#* Create new profile:
func _on_new_pressed() -> void:
	name_mode = "new"
	$"NameProfile".visible = true
	$"NameProfile/LineEdit".grab_focus()

#* Copy an existing profile:
func _on_copy_pressed() -> void:
	if selected_profile != "":
		name_mode = "copy"
		$"NameProfile".visible = true
		$"NameProfile/LineEdit".grab_focus()


#* Rename a profile:
func _on_rename_pressed() -> void:
	if selected_profile != "":
		name_mode = "rename"
		$"NameProfile".visible = true
		$"NameProfile/LineEdit".text = selected_profile
		$"NameProfile/LineEdit".grab_focus()


#* Load a profile and go:
func _on_select_pressed() -> void:
	#% Check that a profile is selected:
	if selected_profile != "":
		#% If the selected profile is not already loaded, load it:
		if selected_profile != candy_dc.current_profile:
			load_profile()
			main._build_command_presets()
			if candy_dc.auto_saves_frequency > 0.0:
				main.get_node("AutoSaveTimer").wait_time = candy_dc.auto_saves_frequency * 60
				main.get_node("AutoSaveTimer").start()
			candy_dc.current_profile = selected_profile
			candy_dc.loaded_save = ""

		main.get_node("MainMenu").visible = false
		main.get_node("Intro").visible = false
		main.get_node("SettingsMenu").visible = false
		self.visible = false
		candy_dc.editor_state = "ui"

		if candy_dc.use_default_project_folders == false:
			candy_dc.resource_paths = candy_dc.custom_resource_paths
		elif candy_dc.use_default_project_folders == true:
			candy_dc.resource_paths = candy_dc.default_resource_paths


#* Delete a profile:
func _on_delete_pressed() -> void:
	if selected_profile != "":
		$"DeleteProfile/ProfileName".text = selected_profile
		$"DeleteProfile".visible = true

func _on_delete_enter_pressed():
	delete_profile()
	$"DeleteProfile".visible = false
	$"DeleteProfile/ProfileName".text = ""

func _on_delete_cancel_pressed():
	selected_profile = ""
	$"DeleteProfile".visible = false
	$"DeleteProfile/ProfileName".text = ""


#* Recursively deletes all contents of a folder, then the folder itself:
func _delete_folder_recursive(path: String) -> void:
	print("  _delete_folder_recursive called on: ", path)
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Could not open folder for deletion: " + path)
		return

	dir.list_dir_begin()
	var item := dir.get_next()

	while item != "":
		#% Skip the "." and ".." entries that every directory listing contains:
		if not item.begins_with("."):
			var full_path := path.path_join(item)

			#% Check whether this item is a directory BEFORE advancing the cursor:
			if DirAccess.dir_exists_absolute(full_path):
				#% It's a subfolder — recurse into it first:
				_delete_folder_recursive(full_path)
			else:
				#% It's a file — delete it directly:
				DirAccess.remove_absolute(full_path)

		item = dir.get_next()

	dir.list_dir_end()

	#% Remove the empty folder:
	DirAccess.remove_absolute(path)


#* Delete a profile:
func delete_profile() -> void:
	var folder_path := "user://Profiles".path_join(selected_profile)
	print("Attempting to delete: ", folder_path)
	print("selected_profile value: '", selected_profile, "'")
	if not DirAccess.dir_exists_absolute(folder_path):
		push_error("Folder does not exist: " + folder_path)
		return

	_delete_folder_recursive(folder_path)
	print("Deleted profile folder:", folder_path)

	selected_profile = ""
	refresh_profile_list()


#* Cancel renaming profile:
func _on_cancel_name_pressed() -> void:
	$"NameProfile".visible = false

#* Confirm renaming profile:
func _on_enter_name_pressed() -> void:
	var name_field: LineEdit = $"NameProfile/LineEdit"
	var error_label: Label = $"NameProfile/Error"
	var new_name := name_field.text.strip_edges()
	error_label.text = ""
	name_field.text = ""

	if name_mode == "rename" or name_mode == "copy":
		name_field.text = selected_profile

	#@ Validate input:
	if new_name == "":
		error_label.text = "Please enter a name."
		return

	var base_path := "user://Profiles"
	DirAccess.make_dir_absolute(base_path)
	var new_profile_path := base_path.path_join(new_name)

	#@ Check for existing folder:
	if DirAccess.dir_exists_absolute(new_profile_path):
		error_label.text = "A profile with this name already exists."
		return

	#@ Handle "new" mode:
	if name_mode == "new":
		var dir := DirAccess.open(base_path)
		if dir == null:
			push_error("Cannot open base Profiles directory.")
			return
		dir.make_dir(new_name)

		#% Create subfolders:
		DirAccess.make_dir_recursive_absolute(new_profile_path.path_join("Saves/AutoSaves"))
		DirAccess.make_dir_recursive_absolute(new_profile_path.path_join("Saves/Manual Saves"))
		DirAccess.make_dir_recursive_absolute(new_profile_path.path_join("Saves/QuickSaves"))
		DirAccess.make_dir_recursive_absolute(new_profile_path.path_join("Exported Dialogues"))

		#% Create full Config.json using helper:
		create_config_file(new_name)

		print("Created new profile folder:", new_profile_path)

	#@ Handle "copy" mode:
	elif name_mode == "copy":
		var source_path := base_path.path_join(str(selected_profile))
		var dir := DirAccess.open(base_path)
		dir.make_dir(new_name)

		#% Copy entire folder:
		_copy_folder_recursive(source_path, new_profile_path)

		#% Update profile in copied Config.json:
		var config_path := new_profile_path.path_join("Config.json")
		var file := FileAccess.open(config_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		data["profile_name"] = new_name

		file = FileAccess.open(config_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

		print("Copied profile_name folder: ", source_path, " → ", new_profile_path)

	#@ Handle "rename" mode:
	elif name_mode == "rename":
		var old_name := str(selected_profile)
		var old_path := base_path.path_join(old_name)
		if not DirAccess.dir_exists_absolute(old_path):
			error_label.text = "Source profile_name folder not found."
			return

		var dir := DirAccess.open(base_path)
		var err := dir.rename(old_name, new_name)
		if err != OK:
			error_label.text = "Failed to rename profile_name."
			push_error("Failed to rename profile_name: " + old_name + " → " + new_name)
			return

		#% Update profile_name in Config.json:
		var config_path := base_path.path_join(new_name).path_join("Config.json")
		var file := FileAccess.open(config_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		data["profile_name"] = new_name

		file = FileAccess.open(config_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

		print("Renamed profile folder:", old_name, "→", new_name)


	#@ Hide name entry UI after success:
	$"NameProfile".visible = false
	name_field.text = ""
	error_label.text = ""
	refresh_profile_list()


#* Recursively copy a folder and its contents:
func _copy_folder_recursive(src_path: String, dst_path: String) -> void:
	var dir := DirAccess.open(src_path)
	if dir == null:
		push_error("Failed to open source directory: " + src_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var src_full := src_path.path_join(file_name)
		var dst_full := dst_path.path_join(file_name)

		if dir.current_is_dir():
			DirAccess.open(dst_path).make_dir(file_name)
			_copy_folder_recursive(src_full, dst_full)
		else:
			var data := FileAccess.get_file_as_bytes(src_full)
			var file := FileAccess.open(dst_full, FileAccess.WRITE)
			if file:
				file.store_buffer(data)
				file.close()

		file_name = dir.get_next()

	dir.list_dir_end()


#* Setup when Profile Menu is opened:
func _on_visibility_changed() -> void:
	if self.visible == true:
		refresh_profile_list()


#* Refresh the profile list:
func refresh_profile_list() -> void:
	var list: ItemList = $"ProfileList"
	list.clear()

	var base_path := "user://Profiles"
	DirAccess.make_dir_absolute(base_path)
	var dir := DirAccess.open(base_path)
	if dir == null:
		push_error("Cannot open Profiles directory: " + base_path)
		return

	dir.list_dir_begin()
	var input_name = dir.get_next()

	while input_name != "":
		if not input_name.begins_with(".") and dir.current_is_dir():
			list.add_item(input_name)
		input_name = dir.get_next()

	dir.list_dir_end()


#* Create the Config.json file for a given profile:
func create_config_file(profile_name: String) -> void:
	var base_path := "user://Profiles"
	var config_path := base_path.path_join(profile_name).path_join("Config.json")
	var project_path := ""

	#@ Build config data:
	var config_data := {
		"profile_name": profile_name,

		#% Project Path:
		"project_path": project_path,

		#% Default Resource Paths:
		"default_resource_paths": {
			"Dialogues": "",

			"*Portraits": "",
			"*Busts": "",
			"*Voices": "",

			"Images": "",
			"Audio": "",
			"Videos": "",
			"Backgrounds": "",

			"Input Menus": "",
			"Choice Menus": "",
			"Choice Categories": "",
			"Choice Buttons": "",
			"VN Scenes": "",
			"BG Scenes": "",
		},

		#% Custom Resource Paths:
		"custom_resource_paths": {
			"Dialogues": "",

			"*Portraits": "",
			"*Busts": "",
			"*Voices": "",

			"Images": "",
			"Audio": "",
			"Videos": "",
			"Backgrounds": "",

			"Input Menus": "",
			"Choice Menus": "",
			"Choice Categories": "",
			"Choice Buttons": "",
			"VN Scenes": "",
			"BG Scenes": "",
		},

		#% Data lists:
		"data_scripts": {
			"Flag": {
				"Script": "Candy_DE/Scripts/Candy_Database.gd",
				"Variable": "flags",
			},
			"Disposition": {
				"Script": "Candy_DE/Scripts/Candy_Database.gd",
				"Variable": "creator_disposition_list",
			},
			"Actor": {
				"Script": "Candy_DE/Scripts/Candy_Database.gd",
				"Variable": "actors",
			},
			"Role": {
				"Script": "Candy_DE/Scripts/Candy_Database.gd",
				"Variable": "roles",
			},
		},

		"flag_list": [],
		"disposition_list": [],
		"actor_list": [],
		"role_list": [],
		"bust_list": [],
		"layer_list": [],
		"effect_list": [],

		#% Symbols:
		"autoload_symbol": "£",
		"node_symbol": "$",
		"candy_symbol": "€",
		"super_autoload_symbol": "££",
		"super_node_symbol": "$$",
		"super_candy_symbol": "€€",

		"role_symbol": "°",
		"var_in_speech_start": "{)",
		"var_in_speech_end": "}",
		"substitution_symbol": "•",
		"separator_symbol": "¦",

		#% Folder Settings:
		"use_default_project_folders": true,

		#% Safety Prompts:
		"confirm_delete_line": false,

		#% Dialogue Settings:
		"default_text_direction": "ltr",
		"spoken_line_limit": 250,
		"spoken_line_near_limit": 25,

		#% Defaults for New Content:
		"new_conversation_name": "",
		"new_block_name": "",

		#% Portrait Preview:
		"portrait_preview_max_h": 200,
		"portrait_preview_max_w": 200,

		"bust_preview_max_w": 200,
		"bust_preview_max_h": 500,

		"image_preview_max_w": 300,
		"image_preview_max_h": 300,

		"video_preview_max_w": 500,
		"video_preview_max_h": 500,

		"bg_preview_max_w": 500,
		"bg_preview_max_h": 500,

		#% Saving System:
		"incremental_saves": false,
		"auto_saves": 5,
		"auto_saves_frequency": 15.0,
		"quick_saves": 5,

		#% Variants Dictionary:
		"variants_dict": {},

		#% Custom Presets:
		"custom_presets": {
			"[Category_A]Preset_1": {
				"Text": []
			}
		},

		#% Custom Writer inserts:
		"custom_writer_inserts": [],

		#% Color mode:
		"color_mode": 0,

		#% UI Visibility Toggles:
		"hide_commands": false,
		"hide_indexes": false,
		"hide_tags": false,
		"hide_disposition": false,
		"hide_voice": false,
		"hide_portrait": false,
		"hide_limit": false,

		#% Undo:
		"undo_memory": 100,
	}

	#@ Write TXT file:
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to create Config.json at: " + config_path)
		return

	file.store_string(JSON.stringify(config_data, "\t"))
	file.close()

	print("Created Config.json for:",profile_name)


#* Save all current editor settings to the active profile:
func save_profile() -> void:
	if candy_dc.active_profile == "":
		push_error("No active profile selected.")
		return

	var config_path := "user://Profiles".path_join(candy_dc.active_profile).path_join("Config.json")
	if not FileAccess.file_exists(config_path):
		push_error("Config.json not found for profile: " + candy_dc.active_profile)
		return

	#@ Load existing TXT:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open Config.json for profile: " + candy_dc.active_profile)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	#@ Overwrite data from globals:
	data["project_path"] = candy_dc.project_path
	data["default_resource_paths"] = candy_dc.default_resource_paths
	data["custom_resource_paths"] = candy_dc.custom_resource_paths

	data["data_scripts"] = candy_dc.data_scripts

	data["flag_list"] = candy_dc.flag_list
	data["disposition_list"] = candy_dc.disposition_list
	data["actor_list"] = candy_dc.actor_list
	data["role_list"] = candy_dc.role_list
	data["bust_list"] = candy_dc.bust_list
	data["layer_list"] = candy_dc.layer_list
	data["effect_list"] = candy_dc.effect_list

	data["autoload_symbol"] = candy_dc.autoload_symbol
	data["node_symbol"] = candy_dc.node_symbol
	data["candy_symbol"] = candy_dc.candy_symbol
	data["super_autoload_symbol"] = candy_dc.super_autoload_symbol
	data["super_node_symbol"] = candy_dc.super_node_symbol
	data["super_candy_symbol"] = candy_dc.super_candy_symbol

	data["var_in_speech_start"] = candy_dc.var_in_speech_start
	data["var_in_speech_end"] = candy_dc.var_in_speech_end
	data["role_symbol"] = candy_dc.role_symbol
	data["substitution_symbol"] = candy_dc.substitution_symbol
	data["separator_symbol"] = candy_dc.separator_symbol

	data["use_default_project_folders"] = candy_dc.use_default_project_folders
	data["confirm_delete_line"] = candy_dc.confirm_delete_line

	data["default_text_direction"] = candy_dc.default_text_direction
	data["spoken_line_limit"] = candy_dc.spoken_line_limit
	data["spoken_line_near_limit"] = candy_dc.spoken_line_near_limit

	data["new_conversation_name"] = candy_dc.new_conversation_name
	data["new_block_name"] = candy_dc.new_block_name

	data["portrait_preview_max_w"] = candy_dc.portrait_preview_max_w
	data["portrait_preview_max_h"] = candy_dc.portrait_preview_max_h

	data["bust_preview_max_w"] = candy_dc.bust_preview_max_w
	data["bust_preview_max_h"] = candy_dc.bust_preview_max_h

	data["image_preview_max_w"] = candy_dc.image_preview_max_w
	data["image_preview_max_h"] = candy_dc.image_preview_max_h

	data["video_preview_max_w"] = candy_dc.video_preview_max_w
	data["video_preview_max_h"] = candy_dc.video_preview_max_h

	data["bg_preview_max_w"] = candy_dc.bg_preview_max_w
	data["bg_preview_max_h"] = candy_dc.bg_preview_max_h

	data["incremental_saves"] = candy_dc.incremental_saves
	data["auto_saves"] = candy_dc.auto_saves
	data["auto_saves_frequency"] = candy_dc.auto_saves_frequency
	data["quick_saves"] = candy_dc.quick_saves

	data["variants_dict"] = candy_dc.variants_dict
	data["custom_presets"] = candy_dc.custom_presets
	data["custom_writer_inserts"] = candy_dc.custom_writer_inserts

	data["color_mode"] = candy_dc.color_mode

	data["hide_commands"] = candy_dc.hide_commands
	data["hide_indexes"] = candy_dc.hide_indexes
	data["hide_tags"] = candy_dc.hide_tags
	data["hide_disposition"] = candy_dc.hide_disposition
	data["hide_voice"] = candy_dc.hide_voice
	data["hide_portrait"] = candy_dc.hide_portrait
	data["hide_limit"] = candy_dc.hide_limit
	data["undo_memory"] = candy_dc.undo_memory

	data["custom_presets"] = candy_dc.custom_presets

	#@ Write updated TXT:
	file = FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write Config.json for profile: " + candy_dc.active_profile)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("Profile saved:", candy_dc.active_profile)


#* Load an editor profile and apply its settings:
func load_profile() -> void:
	if selected_profile == "":
		push_error("No active profile selected.")
		return

	var profile_path := "user://Profiles".path_join(selected_profile).path_join("Config.json")
	if not FileAccess.file_exists(profile_path):
		push_error("Config.json not found for profile: " + selected_profile)
		return

	#@ Read TXT file:
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open Config.json for profile: " + selected_profile)
		return

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	candy_dc.active_profile = selected_profile

	#@ Load Data:
	candy_dc.project_path = data.get("project_path", "")
	candy_dc.default_resource_paths = data.get("default_resource_paths", {})
	candy_dc.custom_resource_paths = data.get("custom_resource_paths", {})

	candy_dc.data_scripts = data.get("data_scripts", {})

	candy_dc.flag_list = data.get("flag_list", [])
	candy_dc.disposition_list = data.get("disposition_list", [])
	candy_dc.actor_list = data.get("actor_list", [])
	candy_dc.role_list = data.get("role_list", [])
	candy_dc.bust_list = data.get("bust_list", [])
	candy_dc.layer_list = data.get("layer_list", [])
	candy_dc.effect_list = data.get("effect_list", [])

	candy_dc.autoload_symbol = data.get("autoload_symbol", "")
	candy_dc.node_symbol = data.get("node_symbol", "")
	candy_dc.candy_symbol = data.get("candy_symbol", "")
	candy_dc.super_autoload_symbol = data.get("super_autoload_symbol", "")
	candy_dc.super_node_symbol = data.get("super_node_symbol", "")
	candy_dc.super_candy_symbol = data.get("super_candy_symbol", "")

	candy_dc.var_in_speech_start = data.get("var_in_speech_start", "")
	candy_dc.var_in_speech_start = data.get("var_in_speech_start", "")
	candy_dc.role_symbol = data.get("role_symbol", "")
	candy_dc.substitution_symbol = data.get("substitution_symbol", "")
	candy_dc.separator_symbol = data.get("separator_symbol", "")

	candy_dc.use_default_project_folders = data.get("use_default_project_folders", true)
	candy_dc.confirm_delete_line = data.get("confirm_delete_line", false)

	candy_dc.default_text_direction = data.get("default_text_direction", "ltr")
	candy_dc.spoken_line_limit = data.get("spoken_line_limit", 250)
	candy_dc.spoken_line_near_limit = data.get("spoken_line_near_limit", 25)

	candy_dc.new_conversation_name = data.get("new_conversation_name", "")
	candy_dc.new_block_name = data.get("new_block_name", "")

	candy_dc.portrait_preview_max_w = data.get("portrait_preview_max_w", 200)
	candy_dc.portrait_preview_max_h = data.get("portrait_preview_max_h", 200)

	candy_dc.bust_preview_max_w = data.get("bust_preview_max_w", 200)
	candy_dc.bust_preview_max_h = data.get("bust_preview_max_h", 200)

	candy_dc.image_preview_max_w = data.get("image_preview_max_w", 200)
	candy_dc.image_preview_max_h = data.get("image_preview_max_h", 200)

	candy_dc.video_preview_max_w = data.get("video_preview_max_w", 200)
	candy_dc.video_preview_max_h = data.get("video_preview_max_h", 200)

	candy_dc.bg_preview_max_w = data.get("bg_preview_max_w", 200)
	candy_dc.bg_preview_max_h = data.get("bg_preview_max_h", 200)

	candy_dc.incremental_saves = data.get("incremental_saves", false)
	candy_dc.auto_saves = data.get("auto_saves", 0)
	candy_dc.auto_saves_frequency = data.get("auto_saves_frequency", 15.0)
	candy_dc.quick_saves = data.get("quick_saves", 0)

	candy_dc.variants_dict = data.get("variants_dict", {})
	candy_dc.custom_presets = data.get("custom_presets", [])
	candy_dc.custom_writer_inserts = data.get("custom_writer_inserts", [])

	candy_dc.color_mode = data.get("color_mode", 0)

	candy_dc.hide_commands = data.get("hide_commands", false)
	candy_dc.hide_indexes = data.get("hide_indexes", false)
	candy_dc.hide_tags = data.get("hide_tags", false)
	candy_dc.hide_disposition = data.get("hide_disposition", false)
	candy_dc.hide_voice = data.get("hide_voice", false)
	candy_dc.hide_portrait = data.get("hide_portrait", false)
	candy_dc.hide_limit = data.get("hide_limit", false)

	candy_dc.undo_memory = data.get("undo_memory", 100)

	candy_dc.custom_presets = data.get("custom_presets", {
		"[Category_A]Preset_1": {
			"Text": []
		}
	})
	candy_dc.conversations["CUSTOM_PRESETS"] = candy_dc.custom_presets.duplicate(true)


	print("Loaded profile:", selected_profile)

	#@ Setup UI:
	if candy_dc.hide_indexes == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/Index").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideIndex")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/Index").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideIndex")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	if candy_dc.hide_tags == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/LLM").visible = true
			line.get_node("HBox/SpeechLine/BubbleExempt").visible = true
			line.get_node("HBox/SpeechLine/ForcePortrait").visible = true
			line.get_node("HBox/SpeechLine/TTS").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideTags")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/LLM").visible = false
			line.get_node("HBox/SpeechLine/BubbleExempt").visible = false
			line.get_node("HBox/SpeechLine/ForcePortrait").visible = false
			line.get_node("HBox/SpeechLine/TTS").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideTags")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	if candy_dc.hide_disposition == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Disposition").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideDisposition")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Disposition").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideDisposition")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	if candy_dc.hide_voice == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Voice").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideVoice")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Voice").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideVoice")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	if candy_dc.hide_portrait == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Portrait").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HidePortrait")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/Portrait").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HidePortrait")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	if candy_dc.hide_limit == false:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/PanelC").visible = true
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideLimit")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		for line in main.get_node("VBox/HBox/WorkArea/Lines").get_children():
			line.get_node("HBox/SpeechLine/PanelC").visible = false
		var btn = main.get_node("VBox/TopBar/HBox/Hide/HideLimit")
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

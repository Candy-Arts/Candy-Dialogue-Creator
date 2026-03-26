extends CanvasLayer

@onready var main = get_node("/root/UI")

var selecting_resource_folder = ""
var selecting_script = ""

var edited_variant = ""
var variant_name_mode = ""
var deleting_variant = ""

var folder_select_mode = ""

#* Setup variant line buttons:
func _ready() -> void:
	#@ Get container reference:
	var lines_container = $"TabContainer/Variants/VBox/HBox/Lines"

	#@ Connect each button once:
	for line in lines_container.get_children():
		var label = line.get_node("HBox/RichTextLabel")
		var btn_direction = line.get_node("HBox/Buttons/Direction")
		var btn_auto = line.get_node("HBox/Buttons/Auto")
		var btn_rename = line.get_node("HBox/Buttons/Rename")
		var btn_delete = line.get_node("HBox/Buttons/Delete")

		#% Disconnect old signals if they exist (avoids duplicates when refreshing scene):
		if btn_direction.is_connected("pressed", Callable(self, "_on_variant_direction_pressed")):
			btn_direction.disconnect("pressed", Callable(self, "_on_variant_direction_pressed"))
		if btn_auto.is_connected("pressed", Callable(self, "_on_variant_auto_pressed")):
			btn_auto.disconnect("pressed", Callable(self, "_on_variant_auto_pressed"))
		if btn_rename.is_connected("pressed", Callable(self, "_on_variant_rename_pressed")):
			btn_rename.disconnect("pressed", Callable(self, "_on_variant_rename_pressed"))
		if btn_delete.is_connected("pressed", Callable(self, "_on_variant_delete_pressed")):
			btn_delete.disconnect("pressed", Callable(self, "_on_variant_delete_pressed"))

		#% Connect signals dynamically with lambdas capturing the label’s text:
		btn_direction.pressed.connect(func(): variant_toggle_direction(label.text))
		btn_auto.pressed.connect(func(): variant_toggle_auto(label.text))
		btn_rename.pressed.connect(func(): variant_rename(label.text))
		btn_delete.pressed.connect(func(): variant_delete(label.text))


#* Write data from globals to settings menu fields:
func setup_menu():
	#@ Preferences:
	$"TabContainer/Preferences/ConversationOption".text = candy_dc.new_conversation_name
	$"TabContainer/Preferences/BlockOption".text = candy_dc.new_block_name

	$"TabContainer/Preferences/ColorMode".text = str(candy_dc.color_mode)

	if candy_dc.confirm_delete_line == true:
		$"TabContainer/Preferences/DeleteOption".button_pressed = true
	elif candy_dc.confirm_delete_line == false:
		$"TabContainer/Preferences/DeleteOption".button_pressed = false

	$"TabContainer/Preferences/PortraitHOption".text = str(candy_dc.portrait_preview_max_h)
	$"TabContainer/Preferences/PortraitWOption".text = str(candy_dc.portrait_preview_max_w)

	$"TabContainer/Preferences/BustHOption".text = str(candy_dc.bust_preview_max_h)
	$"TabContainer/Preferences/BustWOption".text = str(candy_dc.bust_preview_max_w)

	$"TabContainer/Preferences/BGHOption".text = str(candy_dc.bg_preview_max_h)
	$"TabContainer/Preferences/BGWOption".text = str(candy_dc.bg_preview_max_w)

	$"TabContainer/Preferences/ImageHOption".text = str(candy_dc.image_preview_max_h)
	$"TabContainer/Preferences/ImageWOption".text = str(candy_dc.image_preview_max_w)

	$"TabContainer/Preferences/VideoHOption".text = str(candy_dc.video_preview_max_h)
	$"TabContainer/Preferences/VideoWOption".text = str(candy_dc.video_preview_max_w)

	$"TabContainer/Preferences/LineLimitOption".text = str(candy_dc.spoken_line_limit)
	$"TabContainer/Preferences/NearLimitOption".text = str(candy_dc.spoken_line_near_limit)

	if candy_dc.default_text_direction == "ltr":
		$"TabContainer/Preferences/DeleteOption".button_pressed = false
	elif candy_dc.default_text_direction == "rtl":
		$"TabContainer/Preferences/DeleteOption".button_pressed = true

	$"TabContainer/Preferences/AutoSaveOption".text = str(candy_dc.auto_saves)
	$"TabContainer/Preferences/AutoSaveFreqOption".text = str(candy_dc.auto_saves_frequency)
	$"TabContainer/Preferences/QuickSaveOption".text = str(candy_dc.quick_saves)

	#@ Project Files:
	$"TabContainer/ProjectFiles/Project".text = candy_dc.project_path

	for h_line in $"TabContainer/ProjectFiles/CustomFolders/VBox".get_children():
		var line_name: String = str(h_line.name)  #/ ensure it's a pure string
		if candy_dc.custom_resource_paths.has(line_name):
			h_line.get_node("LineEdit").text = candy_dc.custom_resource_paths[line_name]

	if candy_dc.use_default_project_folders == false:
		$"TabContainer/ProjectFiles/Defaults".text = "X"
		candy_dc.resource_paths = candy_dc.custom_resource_paths
		$"TabContainer/ProjectFiles/ColorRect".visible = false
	elif candy_dc.use_default_project_folders == true:
		$"TabContainer/ProjectFiles/Defaults".text = ""
		candy_dc.resource_paths = candy_dc.default_resource_paths
		$"TabContainer/ProjectFiles/ColorRect".visible = true

	update_project_paths()

	#@ Project Data:
	$"TabContainer/ProjectData/Data/VBox/Flags/List".text = ", ".join(candy_dc.flag_list)
	$"TabContainer/ProjectData/Data/VBox/Dispositions/List".text = ", ".join(candy_dc.disposition_list)
	$"TabContainer/ProjectData/Data/VBox/Actors/List".text = ", ".join(candy_dc.actor_list)
	$"TabContainer/ProjectData/Data/VBox/Roles/List".text = ", ".join(candy_dc.role_list)
	$"TabContainer/ProjectData/Data/VBox/Busts/List".text = ", ".join(candy_dc.bust_list)

	$"TabContainer/ProjectData/Data/VBox/VariableSymbols/Autoload".text = candy_dc.autoload_symbol
	$"TabContainer/ProjectData/Data/VBox/VariableSymbols/Node".text = candy_dc.node_symbol
	$"TabContainer/ProjectData/Data/VBox/VariableSymbols/Candy".text = candy_dc.candy_symbol
	$"TabContainer/ProjectData/Data/VBox/SuperSymbols/Autoload".text = candy_dc.super_autoload_symbol
	$"TabContainer/ProjectData/Data/VBox/SuperSymbols/Node".text = candy_dc.super_node_symbol
	$"TabContainer/ProjectData/Data/VBox/SuperSymbols/Candy".text = candy_dc.super_candy_symbol

	$"TabContainer/ProjectData/Data/VBox/RoleSymbol/Symbol".text = candy_dc.role_symbol
	$"TabContainer/ProjectData/Data/VBox/TextVar/TextVarStart".text = candy_dc.var_in_speech_start
	$"TabContainer/ProjectData/Data/VBox/TextVar/TextVarEnd".text = candy_dc.var_in_speech_end
	$"TabContainer/ProjectData/Data/VBox/SubSymbol/Symbol".text = candy_dc.substitution_symbol
	$"TabContainer/ProjectData/Data/VBox/SeparatorSymbol/Symbol".text = candy_dc.separator_symbol

	#% Update script paths:
	for key in candy_dc.data_scripts:
		$"TabContainer/ProjectData/Data/VBox".get_node(key).get_node("Script").text = candy_dc.data_scripts[key]["Script"]
		$"TabContainer/ProjectData/Data/VBox".get_node(key).get_node("Variable").text = candy_dc.data_scripts[key]["Variable"]

	#@ Refresh variant list:
	refresh_variant_list()


#* Display stored project paths in input fields:
func update_project_paths():
	$"TabContainer/ProjectFiles/Project".text = candy_dc.project_path
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Dialogues/LineEdit".text = candy_dc.custom_resource_paths["Dialogues"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/*Portraits/LineEdit".text = candy_dc.custom_resource_paths["*Portraits"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/*Busts/LineEdit".text = candy_dc.custom_resource_paths["*Busts"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/*Voices/LineEdit".text = candy_dc.custom_resource_paths["*Voices"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Audio/LineEdit".text = candy_dc.custom_resource_paths["Audio"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Videos/LineEdit".text = candy_dc.custom_resource_paths["Videos"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Images/LineEdit".text = candy_dc.custom_resource_paths["Images"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Backgrounds/LineEdit".text = candy_dc.custom_resource_paths["Backgrounds"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Input Menus/LineEdit".text = candy_dc.custom_resource_paths["Input Menus"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Choice Menus/LineEdit".text = candy_dc.custom_resource_paths["Choice Menus"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Choice Categories/LineEdit".text = candy_dc.custom_resource_paths["Choice Categories"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/Choice Buttons/LineEdit".text = candy_dc.custom_resource_paths["Choice Buttons"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/VN Scenes/LineEdit".text = candy_dc.custom_resource_paths["VN Scenes"]
	$"TabContainer/ProjectFiles/CustomFolders/VBox/BG Scenes/LineEdit".text = candy_dc.custom_resource_paths["BG Scenes"]


#* Close settings menu:
func _on_close_pressed() -> void:
	self.visible = false
	main.get_node("ProfileMenu").save_profile()

	#% Adjust the auto-save timer count if it's greater than the new frequency:
	if main.get_node("AutoSaveTimer").wait_time > candy_dc.auto_saves_frequency:
		main.get_node("AutoSaveTimer").wait_time = candy_dc.auto_saves_frequency * 60


#& Project Files
func _on_defaults_pressed() -> void:
	if candy_dc.use_default_project_folders == false:
		$"TabContainer/ProjectFiles/Defaults".text = ""
		candy_dc.use_default_project_folders = true
		$"TabContainer/ProjectFiles/ColorRect".visible = true
		candy_dc.resource_paths = candy_dc.default_resource_paths

	elif candy_dc.use_default_project_folders == true:
		$"TabContainer/ProjectFiles/Defaults".text = "X"
		candy_dc.use_default_project_folders = false
		$"TabContainer/ProjectFiles/ColorRect".visible = false
		candy_dc.resource_paths = candy_dc.custom_resource_paths


func _on_project_text_changed(new_text: String) -> void:
	candy_dc.project_path = new_text
	
	#% Update default paths:
	for key in candy_dc.default_resource_paths:
		candy_dc.default_resource_paths[key] = candy_dc.project_path.path_join(candy_dc.default_path_ends[key])


func _on_folder_path_text_changed(new_text: String, source) -> void:
	var folder = source.get_parent().name
	candy_dc.custom_resource_paths[folder] = new_text
	print(folder)
	print(candy_dc.custom_resource_paths[folder])


#* Select the project path:
func _on_select_project_folder_pressed() -> void:
	folder_select_mode = "Project"
	$"TabContainer/ProjectFiles/FolderSelect".visible = true


#* Select a custom folder path:
func _on_select_resource_folder_pressed(source:BaseButton) -> void:
	folder_select_mode = "Custom"
	selecting_resource_folder = source.get_parent()
	$"TabContainer/ProjectFiles/FolderSelect".visible = true


#* Assign selected path:
func _on_folder_select_file_selected(path: String) -> void:
	if folder_select_mode == "Custom":
		candy_dc.custom_resource_paths[selecting_resource_folder.name] = path
		selecting_resource_folder.get_node("LineEdit").text = path
	elif folder_select_mode == "Project":
		candy_dc.project_path = path
		$"TabContainer/ProjectFiles/Project".text = path

	#% Update default paths:
	for key in candy_dc.default_resource_paths:
		candy_dc.default_resource_paths[key] = candy_dc.project_path.path_join(candy_dc.default_path_ends[key])

	$"TabContainer/ProjectFiles/FolderSelect".visible = false
	folder_select_mode = ""


#& Project Data
func _on_flags_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Flags/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.flags_list = result


func _on_dispositions_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Dispositions/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.disposition_list = result


func _on_actors_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Actors/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.actor_list = result


func _on_roles_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Roles/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.role_list = result


func _on_busts_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Busts/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.bust_list = result


func _on_effects_list_text_changed() -> void:
	var raw_text: String = $"TabContainer/ProjectData/Data/VBox/Effects/List".text
	var items := raw_text.split(",", false)  #/ split by commas
	var result: Array = []

	for item in items:
		var trimmed = item.strip_edges()
		if trimmed != "":
			result.append(trimmed)

	candy_dc.effect_list = result


func _on_settings_autoload_symbol_text_changed(new_text: String) -> void:
	candy_dc.autoload_symbol = new_text


func _on_settings_node_symbol_text_changed(new_text: String) -> void:
	candy_dc.node_symbol = new_text


func _on_settings_candy_symbol_text_changed(new_text: String) -> void:
	candy_dc.candy_symbol = new_text


func _on_settings_super_autoload_symbol_text_changed(new_text: String) -> void:
	candy_dc.super_autoload_symbol = new_text


func _on_settings_super_node_symbol_text_changed(new_text: String) -> void:
	candy_dc.super_node_symbol = new_text


func _on_settings_super_candy_symbol_text_changed(new_text: String) -> void:
	candy_dc.super_candy_symbol = new_text


func _on_settings_text_var_start_text_changed(new_text: String) -> void:
	candy_dc.var_in_speech_start = new_text


func _on_settings_text_var_end_text_changed(new_text: String) -> void:
	candy_dc.var_in_speech_end = new_text


func _on_settings_role_symbol_text_changed(new_text: String) -> void:
	candy_dc.role_symbol = new_text


func _on_settings_substitution_symbol_text_changed(new_text: String) -> void:
	candy_dc.substitution_symbol = new_text


func _on_settings_separator_symbol_text_changed(new_text: String) -> void:
	candy_dc.separator_symbol = new_text


#& Preferences
func _on_conversation_option_text_changed(new_text: String) -> void:
	candy_dc.new_conversation_name = new_text


func _on_block_option_text_changed(new_text: String) -> void:
	candy_dc.new_block_name = new_text


func _on_delete_option_toggled(toggled_on: bool) -> void:
	candy_dc.confirm_delete_line = toggled_on


func _on_portrait_h_option_text_changed(new_text: String) -> void:
	candy_dc.portrait_preview_max_h = int(new_text)


func _on_portrait_w_option_text_changed(new_text: String) -> void:
	candy_dc.portrait_preview_max_w = int(new_text)


func _on_bust_h_option_text_changed(new_text: String) -> void:
	candy_dc.bust_preview_max_h = int(new_text)


func _on_bust_w_option_text_changed(new_text: String) -> void:
	candy_dc.bust_preview_max_w = int(new_text)


func _on_bg_h_option_text_changed(new_text: String) -> void:
	candy_dc.bg_preview_max_h = int(new_text)


func _on_bg_w_option_text_changed(new_text: String) -> void:
	candy_dc.bg_preview_max_w = int(new_text)


func _on_image_h_option_text_changed(new_text: String) -> void:
	candy_dc.image_preview_max_h = int(new_text)


func _on_image_w_option_text_changed(new_text: String) -> void:
	candy_dc.image_preview_max_w = int(new_text)


func _on_video_h_option_text_changed(new_text: String) -> void:
	candy_dc.video_preview_max_h = int(new_text)


func _on_video_w_option_text_changed(new_text: String) -> void:
	candy_dc.video_preview_max_w = int(new_text)


func _on_line_limit_option_text_changed(new_text: String) -> void:
	candy_dc.spoken_line_limit = int(new_text)


func _on_near_limit_option_text_changed(new_text: String) -> void:
	candy_dc.spoken_line_near_limit = int(new_text)


func _on_alignment_option_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		candy_dc.default_text_direction = "rtl"
		for v in candy_dc.command_templates["Spoken Line"]["Spoken"]["Variants"]:
			if v.has("Default"):
				v["Default"]["Direction"] = "rtl"
			if v.has("DevCom"):
				v["DevCom"]["Direction"] = "rtl"
		$"TabContainer/Preferences/AlignmentOption".tooltip_text = "Right to Left"
	elif toggled_on == false:
		candy_dc.default_text_direction = "ltr"
		for v in candy_dc.command_templates["Spoken Line"]["Spoken"]["Variants"]:
			if v.has("Default"):
				v["Default"]["Direction"] = "ltr"
			if v.has("DevCom"):
				v["DevCom"]["Direction"] = "ltr"
		$"TabContainer/Preferences/AlignmentOption".tooltip_text = "Left to Right"

	print(candy_dc.default_text_direction)


func _on_save_mode_option_pressed() -> void:
	if candy_dc.incremental_saves == false:
		candy_dc.incremental_saves = true
		$"TabContainer/Preferences/SaveModeOption".text = "Incremental"
	elif candy_dc.incremental_saves == true:
		candy_dc.incremental_saves = false
		$"TabContainer/Preferences/SaveModeOption".text = "Normal"


func _on_auto_save_option_text_changed(new_text: String) -> void:
	candy_dc.auto_saves = int(new_text)


#* Prevent auto save frequency being 0:
func _on_auto_save_freq_option_focus_exited() -> void:
	if float($"TabContainer/Preferences/AutoSaveFreqOption".text) <= 0.0:
		candy_dc.auto_saves_frequency = 1.0		#/ Default to 1 minute
		$"TabContainer/Preferences/AutoSaveFreqOption".text = str(candy_dc.auto_saves_frequency)


func _on_quick_save_option_text_changed(new_text: String) -> void:
	candy_dc.quick_saves = int(new_text)


func _on_color_mode_text_changed(new_text: String) -> void:
	candy_dc.color_mode = int(new_text)


func _on_update_symbols_pressed() -> void:
	pass


#* Update global key list based on external data script:
func _on_update_data_pressed(source) -> void:
	var key = source.get_parent().name
	if not candy_dc.data_scripts.has(key):
		push_error("Data script not found for key: " + key)
		return

	#@ Step 1 - Retrieve script path and variable name:
	var script_path := str(candy_dc.data_scripts[key].get("Script", ""))
	var var_name := str(candy_dc.data_scripts[key].get("Variable", ""))
	if script_path == "" or var_name == "":
		push_error("Missing Script or Variable for key: " + key)
		return

	#% Build full path to the file:
	var full_path = candy_dc.project_path.path_join(script_path)
	if not FileAccess.file_exists(full_path):
		push_error("Script file not found: " + full_path)
		return

	#@ Step 2 - Read script contents:
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + full_path)
		return
	var content := file.get_as_text()
	file.close()

	#@ Step 3 - Find the dictionary OR array definition inside the script:
	var regex_dict := RegEx.new()
	regex_dict.compile("var\\s+" + var_name + "\\s*=\\s*\\{([\\s\\S]*)\\}")

	var regex_array := RegEx.new()
	regex_array.compile("var\\s+" + var_name + "\\s*=\\s*\\[([\\s\\S]*)\\]")

	var result_dict := regex_dict.search(content)
	var result_array := regex_array.search(content)

	var data_str := ""

	if result_dict:
		data_str = "{" + result_dict.get_string(1) + "}"
	elif result_array:
		data_str = "[" + result_array.get_string(1) + "]"
	else:
		push_error("Variable not found or unsupported format: " + var_name)
		return

	#@ Step 4 - Clean up and sanitize content before parsing:
	var ascii_hash := "\u0023"		#/ Regular #
	var full_hash  := "\uFF03"		#/ Fullwidth ＃

	var clean_lines := []
	for line in data_str.split("\n"):
		var cut := line
		cut = cut.split("%s/" % ascii_hash)[0]
		cut = cut.split("%s" % ascii_hash)[0]
		cut = cut.split("%s/" % full_hash)[0]
		cut = cut.split("%s" % full_hash)[0]
		cut = cut.split("//")[0]
		clean_lines.append(cut)
	data_str = "\n".join(clean_lines)

	data_str = data_str.replace("\r", "")
	data_str = data_str.replace("\t", "")
	data_str = data_str.replace(",\n\t}", "\n}")
	data_str = data_str.replace(",\n}", "\n}")
	data_str = data_str.replace(", }", "}")
	data_str = data_str.replace(",}", "}")
	data_str = data_str.replace(", ]", "]")
	data_str = data_str.replace(",]", "]")

	#% Ensure braces/brackets are balanced:
	var open_brace := data_str.count("{")
	var close_brace := data_str.count("}")
	var open_bracket := data_str.count("[")
	var close_bracket := data_str.count("]")

	if open_brace > close_brace:
		data_str += "}"
	if open_bracket > close_bracket:
		data_str += "]"

	#% Parse with Expression:
	var expr := Expression.new()
	var parse_error := expr.parse(data_str, [])
	if parse_error != OK:
		push_error("Failed to parse structure in: " + var_name)
		print("DATA STRING:\n", data_str)
		return

	var eval_result = expr.execute()
	var parsed_dict := {}
	var parsed_array := []

	if typeof(eval_result) == TYPE_DICTIONARY:
		parsed_dict = eval_result
	elif typeof(eval_result) == TYPE_ARRAY:
		parsed_array = eval_result
	else:
		push_error("Parsed variable is neither Dictionary nor Array: " + var_name)
		return

	#@ Step 5 - Merge top-level keys into the correct global list:
	var list_name = key.to_lower() + "_list"

	var target_data = candy_dc.get(list_name)

	if target_data == null:
		push_error("Global list not found: candy_dc." + list_name)
		return

	match typeof(target_data):
		TYPE_ARRAY:
			if parsed_array.size() > 0:
				for v in parsed_array:
					if not (v in target_data):
						target_data.append(v)
			else:
				for k in parsed_dict.keys():
					if not (k in target_data):
						target_data.append(k)

		TYPE_DICTIONARY:
			if parsed_array.size() > 0:
				for i in range(parsed_array.size()):
					var v = parsed_array[i]
					if not target_data.has(str(v)):
						target_data[str(v)] = null
			else:
				for k in parsed_dict.keys():
					if not target_data.has(k):
						target_data[k] = parsed_dict[k]

	#@ Step 6 - Update the array display:
	var settings_array_path := "TabContainer/ProjectData/Data/VBox".path_join(key + "s").path_join("List")
	var settings_array := get_node_or_null(settings_array_path)

	if settings_array and settings_array is TextEdit:
		#% Build display string of all entries from globals:
		var values = candy_dc.get(list_name)
		var existing_text = settings_array.text.strip_edges()

		if existing_text == "":
			#% Case 1 - Nothing in TextEdit yet:
			settings_array.text = ", ".join(values)
		else:
			#% Case 2 - Merge only new items:
			var current_values = existing_text.split(",", false)
			for i in range(current_values.size()):
				current_values[i] = current_values[i].strip_edges()

			for v in values:
				if not (v in current_values):
					current_values.append(v)

			settings_array.text = ", ".join(current_values)
	else:
		push_warning("List node not found or not a TextEdit: " + settings_array_path)


func _on_find_script_pressed(source) -> void:
	selecting_script = source.get_parent().name
	if candy_dc.project_path == "":
		return
	$"TabContainer/ProjectData/ScriptSelect".root_subfolder = candy_dc.project_path
	$"TabContainer/ProjectData/ScriptSelect".visible = true


func _on_variable_name_text_changed(new_text: String, source) -> void:
	var key = source.get_parent().name
	candy_dc.data_scripts[key]["Variable"] = new_text


func _on_script_path_text_changed(new_text: String, source) -> void:
	var key = source.get_parent().name
	candy_dc.data_scripts[key]["Script"] = new_text


func _on_script_select_file_selected(path: String) -> void:
	if selecting_script == "Flag":
		$"TabContainer/ProjectData/Data/VBox/Flag/Script".text = path
	elif selecting_script == "Disposition":
		$"TabContainer/ProjectData/Data/VBox/Disposition/Script".text = path
	elif selecting_script == "Actor":
		$"TabContainer/ProjectData/Data/VBox/Actor/Script".text = path
	elif selecting_script == "Role":
		$"TabContainer/ProjectData/Data/VBox/Role/Script".text = path


#& VARIANTS
#* Refresh the variant list:
func refresh_variant_list() -> void:
	#@ Sort variant dictionary alphabetically:
	var sorted_names: Array = candy_dc.variants_dict.keys()
	sorted_names.sort()

	#@ Get container references:
	var lines_container = $"TabContainer/Variants/VBox/HBox/Lines"
	var scrollbar = $"TabContainer/Variants/VBox/HBox/VScrollBar"
	var total_lines := lines_container.get_child_count()
	var total_variants := sorted_names.size()

	#@ Determine scroll offset (integer index for current first visible variant):
	var scroll_offset := int(scrollbar.value)

	#@ Iterate through each visible line:
	for i in range(total_lines):
		var line = lines_container.get_child(i)
		var label = line.get_node("HBox/RichTextLabel")
		var btn_direction = line.get_node("HBox/Buttons/Direction")
		var btn_auto = line.get_node("HBox/Buttons/Auto")

		var variant_index := i + scroll_offset
		if variant_index < total_variants:
			#% Show and populate active lines:
			var variant_name = sorted_names[variant_index]
			var variant_data = candy_dc.variants_dict.get(variant_name, {})

			#% Update label:
			label.text = variant_name

			#% Update Direction button:
			var direction := str(variant_data.get("Direction", "ltr"))
			match direction:
				"rtl":
					btn_direction.text = "⇠"
				_:
					btn_direction.text = "⇢"

			#% Update Auto button color:
			var is_auto := bool(variant_data.get("Auto", true))
			btn_auto.modulate = Color.WHITE if is_auto else Color(0.5, 0.5, 0.5, 1.0)

			line.visible = true
		else:
			#% Hide unused lines:
			line.visible = false

	#@ Update scrollbar limits:
	scrollbar.max_value = max(total_variants - total_lines, 0)
	scrollbar.page = total_lines


#* Add 'Auto' variants to lines without them:
func _on_add_missing_variants_pressed() -> void:
	#@ Iterate through all conversations:
	for conv_name in candy_dc.conversations.keys():
		var conv = candy_dc.conversations[conv_name]
		for block_name in conv.keys():
			var block = conv[block_name]
			if not block.has("Text") or typeof(block["Text"]) != TYPE_ARRAY:
				continue

			for line_wrapper in block["Text"]:
				for template_key in line_wrapper.keys():
					if template_key != "Spoken Line":
						continue

					var payload = line_wrapper[template_key]
					if not payload.has("Variants") or typeof(payload["Variants"]) != TYPE_ARRAY:
						payload["Variants"] = []

					var variants: Array = payload["Variants"]

					#% Build lookup of existing variants in this line:
					var existing: Dictionary = {}
					for entry in variants:
						for k in entry.keys():
							existing[k] = true

					#% Add missing Auto variants:
					for vname in candy_dc.variants_dict.keys():
						var vdata = candy_dc.variants_dict[vname]
						if bool(vdata.get("Auto", false)) == true:
							if not existing.has(vname):
								var new_entry := {
									vname: {
										"Text": "",
										"Enabled": true,
										"Hide": false,
										"Direction": str(vdata.get("Direction", "ltr")),
									}
								}
								variants.append(new_entry)

	print("[DEBUG] Missing Auto variants added where necessary.")

	#% Store undo step:
	main.save_undo_step()


#* Create a new variant:
func _on_new_variant_pressed() -> void:
	variant_name_mode = "NewVariant"
	$"NameVariant/Name".text = ""
	$"NameVariant".visible = true
	$"NameVariant/Name".grab_focus()


#* Submit variant name:
func _on_confirm_variant_name_pressed() -> void:
	var variant_name = $"NameVariant/Name".text
	var exit = false

	#@ New variant:
	if variant_name_mode == "NewVariant":

		if not candy_dc.variants_dict.has(variant_name):
			#% Add new variant:
			candy_dc.variants_dict[variant_name] = {"Direction": "ltr", "Auto": true}
			exit = true
			print("[DEBUG] New variant '%s' added." % variant_name)
		else:
			#% Display error:
			$"NameVariant/Warning".text = "A variant with this name already exists."
			print("[DEBUG] Variant '%s' already exists." % variant_name)

	#@ Rename variant:
	elif variant_name_mode == "RenameVariant":
		if not candy_dc.variants_dict.has(variant_name):
			#% Duplicate old variant with new name:
			var old_data = candy_dc.variants_dict.get(edited_variant, {"Direction": "ltr", "Auto": true})
			candy_dc.variants_dict[variant_name] = old_data.duplicate(true)
			#% Remove old variant:
			candy_dc.variants_dict.erase(edited_variant)

			#@ Propagate variant rename through all conversations:
			for conv_name in candy_dc.conversations.keys():
				var conv = candy_dc.conversations[conv_name]
				for block_name in conv.keys():
					var block = conv[block_name]
					if not block.has("Text") or typeof(block["Text"]) != TYPE_ARRAY:
						continue

					for line_wrapper in block["Text"]:
						for template_key in line_wrapper.keys():
							if template_key != "Spoken Line":
								continue
							var payload = line_wrapper[template_key]
							if not payload.has("Variants") or typeof(payload["Variants"]) != TYPE_ARRAY:
								continue
							for entry in payload["Variants"]:
								if entry.has(edited_variant):
									var data = entry[edited_variant]
									entry.erase(edited_variant)
									entry[variant_name] = data
			exit = true
			print("[DEBUG] Variant '%s' renamed to '%s'." % [edited_variant, variant_name])

		else:
			#% Display error:
			$"NameVariant/Warning".text = "A variant with this name already exists."
			print("[DEBUG] Variant '%s' already exists." % variant_name)

	#@ Exit menu:
	if exit == true:
		#% Store undo step:
		main.save_undo_step()
		#% Close menu:
		_on_cancel_variant_name_pressed()
		#% Refresh list:
		refresh_variant_list()

#* Close variant name/rename
func _on_cancel_variant_name_pressed():
	$"NameVariant/Name".text = ""
	$"NameVariant/Warning".text = ""
	$"NameVariant".visible = false
	variant_name_mode = ""
	edited_variant = ""
	refresh_variant_list()

#* Toggle variant direction:
func variant_toggle_direction(v: String) -> void:
	if not candy_dc.variants_dict.has(v):
		return

	#% Fetch current data:
	var data = candy_dc.variants_dict[v]
	var dir := str(data.get("Direction", "ltr"))

	#% Swap direction value:
	if dir == "ltr":
		data["Direction"] = "rtl"
	else:
		data["Direction"] = "ltr"

	#% Update button arrow in UI:
	var lines_container = $"TabContainer/Variants/VBox/HBox/Lines"
	for line in lines_container.get_children():
		var label = line.get_node("HBox/RichTextLabel")
		if label.text == v:
			var btn_dir = line.get_node("HBox/Buttons/Direction")
			btn_dir.text = "⇠" if data["Direction"] == "rtl" else "⇢"
			break

	#% Save back to global dictionary:
	candy_dc.variants_dict[v] = data
	print("[DEBUG] Variant '%s' direction toggled to '%s'." % [v, data["Direction"]])


#* Toggle variant Auto:
func variant_toggle_auto(v: String) -> void:
	if not candy_dc.variants_dict.has(v):
		return

	#% Fetch current data:
	var data = candy_dc.variants_dict[v]
	var is_auto := bool(data.get("Auto", true))

	#% Swap Auto value:
	data["Auto"] = not is_auto

	#% Update button modulate in UI:
	var lines_container = $"TabContainer/Variants/VBox/HBox/Lines"
	for line in lines_container.get_children():
		var label = line.get_node("HBox/RichTextLabel")
		if label.text == v:
			var btn_auto = line.get_node("HBox/Buttons/Auto")
			btn_auto.modulate = Color.WHITE if data["Auto"] else Color(0.5, 0.5, 0.5, 1.0)
			break

	#% Save back to global dictionary:
	candy_dc.variants_dict[v] = data
	print("[DEBUG] Variant '%s' Auto toggled to %s." % [v, str(data["Auto"])])

#* Rename button pressed:
func variant_rename(v: String) -> void:
	variant_name_mode = "RenameVariant"
	edited_variant = v
	$"NameVariant/Name".text = ""
	$"NameVariant".visible = true
	$"NameVariant/Name".grab_focus()

#* Delete button pressed:
func variant_delete(v: String) -> void:
	deleting_variant = v
	$"DeleteVariant".visible = true
	$"DeleteVariant/Cancel".grab_focus()

#* Cancel variant deletion:
func _on_cancel_variant_delete_pressed() -> void:
	$"DeleteVariant".visible = false
	deleting_variant = ""
	refresh_variant_list()

#* Confirm variant deletion:
func _on_confirm_variant_delete_pressed() -> void:
	#@ Ensure the variant exists before deleting:
	if candy_dc.variants_dict.has(deleting_variant):
		#% Remove from global registry:
		candy_dc.variants_dict.erase(deleting_variant)

		#@ Propagate deletion through all conversations:
		for conv_name in candy_dc.conversations.keys():
			var conv = candy_dc.conversations[conv_name]
			for block_name in conv.keys():
				var block = conv[block_name]
				if not block.has("Text") or typeof(block["Text"]) != TYPE_ARRAY:
					continue
				for line_wrapper in block["Text"]:
					for template_key in line_wrapper.keys():
						if template_key != "Spoken Line":
							continue
						var payload = line_wrapper[template_key]
						if not payload.has("Variants") or typeof(payload["Variants"]) != TYPE_ARRAY:
							continue
						var variants: Array = payload["Variants"]

						#@ Remove matching variant entries safely:
						for i in range(variants.size() - 1, -1, -1):
							var entry = variants[i]
							if entry.has(deleting_variant):
								variants.remove_at(i)
		print("[DEBUG] Variant '%s' deleted." % deleting_variant)

	else:
		print("[DEBUG] Variant '%s' not found for deletion." % deleting_variant)

	#% Hide confirmation menu and refresh list:
	$"DeleteVariant".visible = false
	main.save_undo_step()
	refresh_variant_list()

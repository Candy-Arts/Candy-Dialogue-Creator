#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyProjectPathsPage
extends CandySettingsPage

const ROOT_KEY := "project_path"
const PATHS_KEY := "custom_project_paths"
const SCRIPT_KEY := CandySymbolsPage.SCRIPT_KEY
const PROJECT_PREFIX := "res://"

#^ Each Candy DE folder's [label, setting key, Candy_Properties.gd variable], in display order:
#? No variable (""): Update leaves it alone. Defaults come from CandyProfileDefaults.
const FOLDERS := [
	["Dialogues",		#/ translatable
		"Dialogues", "dialogues_folder"],
	["Portraits",		#/ translatable
		"*Portraits", "portraits_folder"],
	["Busts",		#/ translatable
		"*Busts", "busts_folder"],
	["Voice files",		#/ translatable
		"*Voice_Files", "voice_folder"],
	["Character sprites",		#/ translatable
		"*Sprites", "sprite_folder"],
	["Backgrounds",		#/ translatable
		"Backgrounds", "background_folder"],
	["Images",		#/ translatable
		"Images", "image_folder"],
	["Audio",		#/ translatable
		"Audio", "audio_folder"],
	["Videos",		#/ translatable
		"Videos", "video_folder"],
	["Effects",		#/ translatable
		"Effects", "effects_folder"],
	["Background scenes",		#/ translatable
		"BG_Scenes", "bg_scenes_folder"],
	["VN scenes",		#/ translatable
		"VN_Scenes", "bust_scenes_folder"],
	["Dialogue UI scenes",		#/ translatable
		"Dialogue_UI_Scenes", "dialogue_ui_folder"],
	["Dialogue box scenes",		#/ translatable
		"Dialogue_Box_Scenes", "dialogue_boxes_folder"],
	["Subtitles scenes",		#/ translatable
		"Subtitles_Scenes", "subtitles_folder"],
	["Speech bubble scenes (2D)",		#/ translatable
		"Speech_Bubble_2D_Scenes", "speech_bubbles_2d_folder"],
	["Speech bubble scenes (3D)",		#/ translatable
		"Speech_Bubble_3D_Scenes", "speech_bubbles_3d_folder"],
	["Bark scenes (2D)",		#/ translatable
		"Bark_2D_Scenes", "barks_2d_folder"],
	["Bark scenes (3D)",		#/ translatable
		"Bark_3D_Scenes", "barks_3d_folder"],
	["History menu scenes",		#/ translatable
		"History_Menu_Scenes", "history_menus_folder"],
	["Image player scenes",		#/ translatable
		"Image_Player_Scenes", "image_players_folder"],
	["Chat box scenes",		#/ translatable
		"Chat_Box_Scenes", "chat_boxes_folder"],
	["Chat channel scenes",		#/ translatable
		"Chat_Channel_Scenes", "chat_channels_folder"],
	["Chat line scenes",		#/ translatable
		"Chat_Line_Scenes", "chat_lines_folder"],
	["Chat separator scenes",		#/ translatable
		"Chat_Separator_Scenes", "chat_separators_folder"],
	["Player input scenes",		#/ translatable
		"Player_Input_Scenes", "input_menus_folder"],
	["Choice menu scenes",		#/ translatable
		"Choice_Menu_Scenes", "choice_menus_folder"],
	["Choice category scenes",		#/ translatable
		"Choice_Category_Scenes", "choice_categories_folder"],
	["Choice button scenes",		#/ translatable
		"Choice_Button_Scenes", "choice_buttons_folder"],
	["Testing scenes",		#/ translatable
		"Testing_Scenes", "testing_scenes_folder"],
	["Dialogue mode scripts",		#/ translatable
		"Dialogue_Modes", ""],
]


var _import_status: Label


func build() -> void:
	add_heading(CandyLocale.t("Godot project"))
	add_path(ROOT_KEY, CandyLocale.t("Project root"),
		CandyLocale.t("The folder containing project.godot — what Candy DE sees as res://"))
	add_file(SCRIPT_KEY, CandyLocale.t("Candy Properties"),
		CandyLocale.t("Candy_Properties.gd in your project. Also set on the Symbols page."), ROOT_KEY,
		PackedStringArray(CandySymbolsPage.GD_FILTER))
	add_button("", CandyLocale.t("Update folders from script"), _import,
		CandyLocale.t("Read the Candy DE folders below out of Candy_Properties.gd."))
	_import_status = add_note(" ")

	add_separator()

	add_heading(CandyLocale.t("Candy Dialogue Engine folders"))
	var note := Label.new()
	note.text = CandyLocale.t("Relative to the project root.")
	note.theme_type_variation = CandyThemeDefaults.NOTE
	add_child(note)

	var defaults: Dictionary = CandyProfileDefaults.create("", "", CandyProfiles.VERSION).get(PATHS_KEY, {})
	for folder in FOLDERS:
		var label: String = CandyLocale.t(folder[0])
		var key: String = folder[1]
		add_path("%s/%s" % [PATHS_KEY, key], label, CandyLocale.t("Stored as %s") % key,
			ROOT_KEY, str(defaults.get(key, "")))


#* Read the folders from Candy_Properties.gd:
func _import() -> void:
	var script_path := resolve_path(str(draft.get_value(SCRIPT_KEY, "")), ROOT_KEY)
	if script_path == "":
		_import_status.text = CandyLocale.t("Set the path to Candy_Properties.gd first.")
		return
	if not FileAccess.file_exists(script_path):
		_import_status.text = CandyLocale.t("No file at %s") % script_path
		return

	var found := 0
	var missing: Array = []
	var outside: Array = []
	for folder in FOLDERS:
		var variable: String = folder[2]
		if variable == "":
			continue
		var value := CandyProjectScripts.read_string(script_path, variable)
		if value == "":
			missing.append(variable)
			continue
		#% Skip paths outside res://:
		if not value.begins_with(PROJECT_PREFIX):
			outside.append(variable)
			continue
		var relative := value.substr(PROJECT_PREFIX.length()).rstrip("/\\")	#/ Relative to the root
		draft.set_value("%s/%s" % [PATHS_KEY, str(folder[1])], relative)
		found += 1

	refresh()
	var message := CandyLocale.t("Updated %d folders.") % found
	if not missing.is_empty():
		message += " " + CandyLocale.t("Not found: %s.") % ", ".join(missing)
	if not outside.is_empty():
		message += " " + CandyLocale.t("Not a res:// path: %s.") % ", ".join(outside)
	_import_status.text = message
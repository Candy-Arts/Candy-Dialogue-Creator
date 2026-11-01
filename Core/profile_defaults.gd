#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyProfileDefaults

#^ Settings holding fixed slots rather than the user's entries:
const SLOT_KEYS := ["custom_project_paths", "project_scripts", "symbols", "speech_insert_scripts"]


static func create(user_name: String, profile_name: String, version: String) -> Dictionary:
	return {
		"User Name": user_name,
		"Profile Name": profile_name,
		"Candy DC Version": version,

		#% Area / Panel layout:
		"ui_layout": {},
		#? Edit Layout mode (Areas show their headers):
		"edit_layout": false,
		#? Changed shortcuts: { action id: [ "Ctrl+Z", ... ] } (CandyShortcuts):
		"shortcuts": {},
		#? Ctrl-drag divider step, in pixels:
		"layout_resize_step": 16,
		#? Keys held when dropping a dragged Area: copy it, swap the two (CandyAreaDrag.KEYS):
		"layout_drag_copy_key": "ctrl",
		"layout_drag_swap_key": "alt",
		#? Window menu's layouts: [{ "name", "level" }] (CandyLayoutLibrary):
		"quick_layouts": [],

		"current_variant": "Default",
		"current_translation": "Default",

		"meta_visible": true,
		"dev_comments_visible": true,
		"overrides_area_visible": true,
		"translate_area_visible": false,
		"portrait_area_visible": true,
		"voice_area_visible": true,
		"disposition_area_visible": true,

		"choice_general_prompt_visible": false,
		"choice_general_mouse_visible": false,
		"choice_general_setup_visible": false,
		"choice_general_scenes_visible": false,
		"choice_general_tags_visible": false,
		"choice_general_custom_visible": false,
		"choice_category_prompt_visible": false,
		"choice_category_mouse_visible": false,
		"choice_category_setup_visible": false,
		"choice_category_scenes_visible": false,
		"choice_category_tags_visible": false,
		"choice_category_custom_visible": false,
		"choice_item_tooltip_visible": false,
		"choice_item_setup_visible": false,
		"choice_item_scene_visible": false,
		"choice_item_tags_visible": false,
		"choice_item_custom_visible": false,
		"choice_timer_setup_visible": false,
		"choice_timer_timeout_visible": false,
		"choice_timer_display_visible": false,
		"choice_timer_tags_visible": false,
		"choice_timer_custom_visible": false,

		"video_preview_width": 512,
		"image_preview_width": 512,
		"bg_preview_width": 256,
		"bg_sprite_fps": 30.0,
		"portrait_preview_width": 128,
		#? Actors' and roles' portrait backgrounds (CandyPortraitBackgrounds):
		"portrait_backgrounds": {"actors": {}, "roles": {}},
		"portrait_sprite_fps": 30.0,
		"bust_preview_width": 256,
		"bust_sprite_fps": 30.0,

		#? Advanced Speech Editor tag markers, for widgets set to Default:
		#? mode ("off", "on", "smart"), character, colors { theme id: Color }.
		"tag_markers": "on",
		"tag_marker_character": "◊",
		"tag_marker_colors": {},

		"undo_steps_min": 0,
		"undo_steps_max": 25,
		"undo_memory_min": 0,
		"undo_memory_max": 0,

		"selected_ui_colors": "Default",
		"ui_colors": {
			"Default": {"On": Color(0, 0, 1, 1), "Off": Color(1, 0, 0, 1), "Normal": Color(1, 1, 1, 1), "Caution": Color(1, 1, 0, 1), "Disabled": Color(0.5, 0.5, 0.5, 1), "Selected": Color(0.5, 0.5, 1, 1), "Primary": Color(1, 0, 1, 1), "Secondary": Color(1, 0.5, 1, 1)},
			"Red-Green Contrast": {"On": Color(0, 0.45, 0.7, 1), "Off": Color(0.9, 0.62, 0, 1), "Normal": Color(1, 1, 1, 1), "Caution": Color(0.94, 0.89, 0.26, 1), "Disabled": Color(0.5, 0.5, 0.5, 1), "Selected": Color(0, 0.62, 0.45, 1), "Primary": Color(0, 0.45, 0.7, 1), "Secondary": Color(0.35, 0.7, 0.9, 1)},
			"Blue-Yellow Contrast": {"On": Color(0, 0.6, 0, 1), "Off": Color(0.8, 0, 0, 1), "Normal": Color(1, 1, 1, 1), "Caution": Color(0.9, 0.49, 0.13, 1), "Disabled": Color(0.5, 0.5, 0.5, 1), "Selected": Color(0.55, 0, 0.55, 1), "Primary": Color(0.8, 0, 0, 1), "Secondary": Color(0.9, 0.49, 0.13, 1)},
			"Monochrome": {"On": Color(1, 1, 1, 1), "Off": Color(0.2, 0.2, 0.2, 1), "Normal": Color(0.75, 0.75, 0.75, 1), "Caution": Color(1, 1, 1, 1), "Disabled": Color(0.4, 0.4, 0.4, 1), "Selected": Color(0.9, 0.9, 0.9, 1), "Primary": Color(1, 1, 1, 1), "Secondary": Color(0.6, 0.6, 0.6, 1)},
			"IBM": {"On": Color(0.392, 0.561, 1, 1), "Off": Color(0.996, 0.38, 0, 1), "Normal": Color(1, 1, 1, 1), "Caution": Color(1, 0.69, 0, 1), "Disabled": Color(0.5, 0.5, 0.5, 1), "Selected": Color(0.471, 0.369, 0.941, 1), "Primary": Color(0.863, 0.149, 0.498, 1), "Secondary": Color(0.392, 0.561, 1, 1)},
		},

		"conversation_new_name": "Conversation_1",
		"block_default_name": "Block_1",
		"block_new_name": "Block_",
		"warning_display_time": "0.05",
		"spoken_text_limit": "250",
		"limit_margin": "50",
		#? Counters colors: { theme id: { "counter_color_more": Color(...), ... } }:
		"counter_colors": {},

		"default_save_mode": 0,
		"quick_saves_max": "5",
		"auto_save_freq": "60",
		"auto_saves_max": "5",
		#? Save and load folders (empty: the profile's own Saves/...):
		"load_path": "",
		"manual_saves_path": "",
		"auto_saves_path": "",
		"quick_saves_path": "",

		"symbol_script_path": "Candy_DE/Scripts/User_Data/Candy_Properties.gd",
		"candy_ref_script_path": "Candy_DE/Scripts/User_Data/CandyRef_Shortcuts.gd",

		#? 1.2 symbols, imported from Candy_Properties.gd:
		"symbols": {
			"expression": "¢",
			"vardict": "€",
			"role": "°",
			"text_var_start": "¤",
			"text_var_end": "¤",
			"substitution_start": "•",
			"substitution_end": "•",
			"separator": "¦",
			"text_event_start": "‡",
			"text_event_end": "‡",
			"lexicon_escape_start": "¬",
			"lexicon_escape_end": "¬",
		},

		#? CandyRef_Shortcuts.gd's symbols, imported - [{ "kind", "symbol", "target" | "keys" + "entries" }]:
		"candy_ref_symbols": [],

		#? 1.1 symbols, entered by hand, for the converter:
		"singleton_symbol": "£",
		"node_symbol": "$",
		"vardict_symbol": "€",
		"super_singleton_symbol": "££",
		"super_node_symbol": "$$",
		"super_vardict_symbol": "€€",
		"role_symbol": "°",
		"text_var_symbol_start": "{)",
		"text_var_symbol_end": "}",
		"substitution_symbol": "•",
		"separator_symbol": "¦",
		"file_var_symbol": "",
		#? The 1.1 project, for the converter (CandyDialogueConverter.default_project()):
		"converter_project": {
			"tts": "Simple",
			"ui_elements": ["dialogue_box_path", "subtitles_path", "chat_path", "barks_path"],
			"portrait_node": "sprite",
			"bg_layers": "",
		},

		"project_path": "",
		"custom_project_paths": {
			"Dialogues": "Candy_DE/Dialogues",
			"*Portraits": "Candy_DE/Media/Actors/Portraits",
			"*Busts": "Candy_DE/Media/Actors/Busts",
			"*Voice_Files": "Candy_DE/Media/Actors/Voices",
			"*Sprites": "Candy_DE/Media/Actors/Sprites",
			"Backgrounds": "Candy_DE/Media/General/Backgrounds",
			"Images": "Candy_DE/Media/General/Images",
			"Audio": "Candy_DE/Media/General/Audio",
			"Videos": "Candy_DE/Media/General/Videos",
			"BG_Scenes": "Candy_DE/Scenes/Background_Scenes",
			"VN_Scenes": "Candy_DE/Scenes/VN_Scenes",
			"Player_Input_Scenes": "Candy_DE/Scenes/Input_Menus",
			"Choice_Menu_Scenes": "Candy_DE/Scenes/Choice_Menus",
			"Choice_Category_Scenes": "Candy_DE/Scenes/Choice_Categories",
			"Choice_Button_Scenes": "Candy_DE/Scenes/Choice_Buttons",
			"Effects": "Candy_DE/Media/General/Effects",
			#% Candy DE's other scene folders:
			"Dialogue_UI_Scenes": "Candy_DE/Scenes/Dialogue_UI",
			"Dialogue_Box_Scenes": "Candy_DE/Scenes/Dialogue_Boxes",
			"Subtitles_Scenes": "Candy_DE/Scenes/Subtitles",
			"Speech_Bubble_2D_Scenes": "Candy_DE/Scenes/Speech_Bubbles_2D",
			"Speech_Bubble_3D_Scenes": "Candy_DE/Scenes/Speech_Bubbles_3D",
			"Bark_2D_Scenes": "Candy_DE/Scenes/Barks_2D",
			"Bark_3D_Scenes": "Candy_DE/Scenes/Barks_3D",
			"History_Menu_Scenes": "Candy_DE/Scenes/History_Menus",
			"Image_Player_Scenes": "Candy_DE/Scenes/Image_Players",
			"Chat_Box_Scenes": "Candy_DE/Scenes/Chat_Boxes",
			"Chat_Channel_Scenes": "Candy_DE/Scenes/Chat_Channels",
			"Chat_Line_Scenes": "Candy_DE/Scenes/Chat_Lines",
			"Chat_Separator_Scenes": "Candy_DE/Scenes/Chat_Separators",
			"Testing_Scenes": "Candy_DE/Scenes/Testing_Scenes",
			#? Dialogue mode scripts, for Dialogue Mode fields (CandyResources.dialogue_modes()):
			"Dialogue_Modes": "Candy_DE/Scripts/Dialogue_Modes",
		},
		#? Test run (CandyTestRun): scene (empty: Candy Wizard's) and start (empty: first):
		"test_start": {"Scene": "", "Conversation": "", "Block": "", "Line": ""},
		#? Data, read everywhere, is computed from Loaded / Exclude / Add:
		"project_scripts": {
			"Actors": {"Script": "Candy_DE/Scripts/User_Data/Data_Tables/Actors.gd", "Variable": "actors", "Loaded": "", "Exclude": "", "Add": "", "Data": ""},
			"Roles": {"Script": "Candy_DE/Scripts/User_Data/Data_Tables/Roles.gd", "Variable": "roles", "Loaded": "", "Exclude": "", "Add": "", "Data": ""},
			"Flags": {"Script": "Candy_DE/Scripts/User_Data/Data_Tables/Flags.gd", "Variable": "flags", "Loaded": "", "Exclude": "", "Add": "", "Data": ""},
			"Dispositions": {"Script": "", "Variable": "", "Loaded": "", "Exclude": "", "Add": "Like, Dislike", "Data": "Like, Dislike"},
			#? Exclude drops media_players_paths' media players:
			"Effect_Players": {"Script": "Candy_DE/Scripts/Candy_Engine.gd", "Variable": "media_players_paths", "Loaded": "Voice, Effect, Image, Splash, Video, Sound, Ambient, Music, Speech", "Exclude": "Voice, Image, Splash, Video, Sound, Ambient, Music, Speech", "Add": "", "Data": "Effect"},
			"CS_Paths": {"Script": "Candy_DE/Scripts/Candy_Engine.gd", "Variable": "cs_paths", "Loaded": "Player, Actors, Vehicles, Objects, Cameras, Markers, WP, Lights", "Exclude": "", "Add": "", "Data": "Player, Actors, Vehicles, Objects, Cameras, Markers, WP, Lights"},
		},
		#? Speech Inserts tables, read at each scan (CandyResources.speech_insert_tables):
		"speech_insert_scripts": {
			"Lexicon": {"Script": "Candy_DE/Scripts/User_Data/Data_Tables/Lexicon.gd", "Variable": "lexicon"},
			"Text_Events": {"Script": "Candy_DE/Scripts/User_Data/Data_Tables/Text_Events.gd", "Variable": "text_events"},
		},
		"direct_data": {
			"Functions": "", "Set_Variables": "", "Names": "", "Flags": "",
			"Role_References": "", "Actor_References": "", "Set_Operators": "", "Flag_Operators": "",
		},
		"favorites": [],

		#? Navigator colors: { theme id: { conversation, block, categories, commands } }
		#? (CandyNavigatorColors):
		"navigator_colors": {},
		#? Navigator Custom mode: { line type: "full" | "short" | "meta" } (default full):
		"navigator_line_modes": {},

		#? Variations: languages, tags, disabled combinations:
		"variation_data": {
			"languages": [{"name": "Default", "hidden": false, "direction": "LtR"}],
			"custom_tags": [],
			"random_tags": [],
			"disabled": [],
		},

		"preview_bg_color": "Color(0.109375, 0.109375, 0.109375, 1)",
		"preview_text_color": "Color(1, 1, 1, 1)",
		"preview_portrait_color": "Color(0.51953125, 0.988739, 1, 1)",
	}


#* Merge the profile file over the defaults (see SLOT_KEYS):
static func merge_file(defaults: Dictionary, file: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	for key in file:
		if SLOT_KEYS.has(key) and result.get(key) is Dictionary and file[key] is Dictionary:
			result[key] = _merge_slots(result[key], file[key])
		else:
			result[key] = file[key]
	return result


static func _merge_slots(defaults: Dictionary, file: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	for key in file:
		if result.get(key) is Dictionary and file[key] is Dictionary:
			result[key] = _merge_slots(result[key], file[key])
		else:
			result[key] = file[key]
	return result

extends Node

#° META:
var dc_version = "1.1.1"
var dialogue_version = "1.1.0"

var editor_state = ""

var auto_save_index: int = 1
var quick_save_index: int = 1

#? "Standalone" or "Integrated":
var use_mode = "Standalone"

var current_user = ""
var current_profile = ""
var current_save = ""

var current_conversation = "Conversation_1"
var current_block = "Block_1"
var current_line = -1
var current_line_type = "§Comment"

var current_variant = "Default"
var current_translation = "Default"

var current_choice_category = ""
var current_choice_item = ""
var current_choice_timer = ""

var last_focused_field: Node
var last_selected_text = ""
var last_selection_from: int = 0
var last_selection_to: int = 0
var last_selection_from_line: int = 0
var last_selection_from_col: int = 0
var last_selection_to_line: int = 0
var last_selection_to_col: int = 0


var hide_dropdown_2_timer = null
var hide_dropdown_2_cancelled := false
var sprite_preview_cancelled := false

var undo_stack: Array = []
var current_undo_step: int
var original_data = ""

var selected_choice_item

var tools_color_mode = "Code"

var unsaved_work = false


#° SETTINGS:
#region
#^ UI Element Visibility:
var meta_visible = true
var dev_comments_visible = true
var overrides_area_visible = false
var translate_area_visible = false
var portrait_area_visible = true
var voice_area_visible = true
var disposition_area_visible = true

var choice_general_prompt_visible = false
var choice_general_mouse_visible = false
var choice_general_setup_visible = false
var choice_general_scenes_visible = false
var choice_general_tags_visible = false
var choice_general_custom_visible = false

var choice_category_prompt_visible = false
var choice_category_mouse_visible = false
var choice_category_setup_visible = false
var choice_category_scenes_visible = false
var choice_category_tags_visible = false
var choice_category_custom_visible = false

var choice_item_tooltip_visible = false
var choice_item_setup_visible = false
var choice_item_scene_visible = false
var choice_item_tags_visible = false
var choice_item_custom_visible = false

var choice_timer_setup_visible = false
var choice_timer_timeout_visible = false
var choice_timer_display_visible = false
var choice_timer_tags_visible = false
var choice_timer_custom_visible = false

#^ Media Preview:
var video_preview_width = 512
var image_preview_width = 512
var bg_preview_width = 512
var bg_sprite_fps = 30.0
var portrait_preview_width = 128
var portrait_sprite_fps = 30.0
var bust_preview_width = 128
var bust_sprite_fps = 30.0
var sprite_preview_width = 128
var sprite_preview_fps = 30.0

#^ Undo:
var undo_steps_min = 0
var undo_steps_max = 0
var undo_memory_min = 0
var undo_memory_max = 0

#^ Line Tree filters:
var line_tree_meta = false
var line_tree_comments = true
var line_tree_control = true
var line_tree_conditions = true
var line_tree_transitions = true
var line_tree_choices = true
var line_tree_input = true
var line_tree_effects = true
var line_tree_images = true
var line_tree_audio = true
var line_tree_video = true
var line_tree_bg = true
var line_tree_vn = true
var line_tree_cs = true
var line_tree_custom = true

#^ UI Colors:
var selected_ui_colors = "Default"

var ui_colors = {
    "Default": {
        "On": Color(0.0, 0.0, 1.0),
        "Off": Color(1.0, 0.0, 0.0),
        "Normal": Color(1.0, 1.0, 1.0),
        "Caution": Color(1.0, 1.0, 0.0),
        "Disabled": Color(0.5, 0.5, 0.5),
        "Selected": Color(0.5, 0.5, 1.0),
        "Primary": Color(1.0, 0.0, 1.0),
        "Secondary": Color(1.0, 0.5, 1.0),
    },
    # Safe for Deuteranopia & Protanopia (red-green color-blindness)
    # Uses blue/orange contrast instead of red/green
    "Red-Green Contrast": {
        "On": Color(0.0, 0.45, 0.70),			# Blue
        "Off": Color(0.90, 0.62, 0.0),			# Orange
        "Normal": Color(1.0, 1.0, 1.0),			# White
        "Caution": Color(0.94, 0.89, 0.26),		# Yellow (still visible)
        "Disabled": Color(0.5, 0.5, 0.5),		# Grey
        "Selected": Color(0.0, 0.62, 0.45),		# Bluish-green
        "Primary": Color(0.0, 0.45, 0.70),		# Blue
        "Secondary": Color(0.35, 0.70, 0.90),	# Light blue
    },
    # Safe for Tritanopia (blue-yellow color-blindness)
    # Uses red/green contrast instead of blue/yellow
    "Blue-Yellow Contrast": {
        "On": Color(0.0, 0.60, 0.0),			# Green
        "Off": Color(0.80, 0.0, 0.0),			# Red
        "Normal": Color(1.0, 1.0, 1.0),			# White
        "Caution": Color(0.90, 0.49, 0.13),		# Orange
        "Disabled": Color(0.5, 0.5, 0.5),		# Grey
        "Selected": Color(0.55, 0.0, 0.55),		# Magenta
        "Primary": Color(0.80, 0.0, 0.0),		# Red
        "Secondary": Color(0.90, 0.49, 0.13),	# Orange
    },
    # High contrast monochrome — works for all types of color-blindness
    "Monochrome": {
        "On": Color(1.0, 1.0, 1.0),
        "Off": Color(0.2, 0.2, 0.2),
        "Normal": Color(0.75, 0.75, 0.75),
        "Caution": Color(1.0, 1.0, 1.0),
        "Disabled": Color(0.4, 0.4, 0.4),
        "Selected": Color(0.9, 0.9, 0.9),
        "Primary": Color(1.0, 1.0, 1.0),
        "Secondary": Color(0.6, 0.6, 0.6),
    },
    # IBM Design Language — Color Blind-Safe palette
    # Designed by IBM to be safe across protanopia, deuteranopia, and tritanopia.
    "IBM": {
        "On": Color(0.392, 0.561, 1.0),			# Ultramarine 40	#648fff
        "Off": Color(0.996, 0.380, 0.0),		# Orange 40			#fe6100
        "Normal": Color(1.0, 1.0, 1.0),			# White				#ffffff
        "Caution": Color(1.0, 0.690, 0.0),		# Gold 20			#ffb000
        "Disabled": Color(0.5, 0.5, 0.5),		# (no IBM gray in palette, kept neutral)
        "Selected": Color(0.471, 0.369, 0.941),	# Indigo 50			#785ef0
        "Primary": Color(0.863, 0.149, 0.498),	# Magenta 50		#dc267f
        "Secondary": Color(0.392, 0.561, 1.0),	# Ultramarine 40	#648fff
    },
}

var conversation_new_name = "Conversation_"
var block_default_name = "Block_1"
var block_new_name = "Block_"

var default_text_direction = "LtR"

var warning_display_time = "0.05"

var spoken_text_limit = "250"
var limit_margin = "50"

var default_save_mode = 0
var quick_saves_max = "20"
var auto_saves_max = "20"
var auto_save_freq = "60"


#^ Symbols:
var symbol_script_path = "Candy_DE/Scripts/User_Data/Candy_Properties.gd"
var singleton_symbol = "£"
var node_symbol = "$"
var vardict_symbol = "€"
var super_singleton_symbol = "££"
var super_node_symbol = "$$"
var super_vardict_symbol = "€€"
var role_symbol = "°"
var text_var_symbol_start = "{)"
var text_var_symbol_end = "}"
var substitution_symbol = "•"
var separator_symbol = "|"


#^ Project Paths:
var project_path = ""

var default_project_paths = {
	"Dialogues": "Candy_DE/Dialogues",

	"*Portraits": "Candy_DE/Media/Characters/Portraits",
	"*Busts": "Candy_DE/Media/Characters/Busts",
	"*Voice_Files": "Candy_DE/Media/Characters/Voices",
	"*Sprites": "Candy_DE/Media/Characters/Sprites",

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
}

var custom_project_paths = {
	"Dialogues": "Candy_DE/Dialogues",

	"*Portraits": "Candy_DE/Media/Characters/Portraits",
	"*Busts": "Candy_DE/Media/Characters/Busts",
	"*Voice_Files": "Candy_DE/Media/Characters/Voices",
	"*Sprites": "Candy_DE/Media/Characters/Sprites",

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
}

#^ Variants:
var languages = {
	"Default": {
		"Default_Direction": "LtR",
		"Variants": {
			"": {
				"Auto": true,
			},
		},
	},
}

var variants = {
	"": {},
}

var disabled_variants: Array = []

var preview_bg_color = Color(0, 0, 0, 1)
var preview_text_color = Color(1, 1, 1, 1)
var preview_portrait_color = Color(0, 0, 0, 1)

var shortcut_keys = {
	"Quick_Save": KEY_F4,
	"Quick_Load": KEY_F5,
}

#endregion


#° DATA:
#region
#? List of resources, read from the project folder:
var project_resources = {
	"*Portraits": {},
	"*Busts": {},
	"*Voice_Files": {},
	"*Sprites": {},
	"Backgrounds": {},
	"Images": {},
	"Audio": {},
	"Videos": {},

	"BG_Scenes": {},
	"VN_Scenes": {},
	"Player_Input_Scenes": {},
	"Choice_Menu_Scenes": {},
	"Choice_Category_Scenes": {},
	"Choice_Button_Scenes": {},

	#% Read from scenes:
	"BG_Layer_Nodes": {},
	"VN_Bust_Nodes": {},
}

#? Scripts and variables where Candy DC can find specific data:
var project_scripts = {
	"Actors": {
		"Script": "Candy_DE/Scripts/User_Data/Candy_Database.gd",
		"Variable": "actors",
		"Data": "",
	},
	"Roles": {
		"Script": "Candy_DE/Scripts/User_Data/Candy_Database.gd",
		"Variable": "roles",
		"Data": "",
	},
	"Flags": {
		"Script": "Candy_DE/Scripts/User_Data/Candy_Database.gd",
		"Variable": "flags",
		"Data": "",
	},
	"Dispositions": {
		"Script": "Candy_DE/Scripts/User_Data/Candy_Database.gd",
		"Variable": "creator_disposition_list",
		"Data": "",
	},
}

#? Data provided directly by the user in Candy DC:
#? For populating drop-down lists.
#& Unused at this time.
var direct_data = {
	"Functions": "",
	"Set_Variables": "",
	"Names": "",
	"Flags": "",
	"Role_References": "",
	"Actor_References": "",
	"Set_Operators": "",
	"Flag_Operators": "",
}

var user_inserts = {}
var profile_inserts = {}

var favorites: Array = []

var user_presets = {
	"USER PRESETS": {
		"[Category_1] User_Preset_1": {
			"Text": [
				{"§Comment": {
					"Color": "Color(1, 1, 1, 1)",
					"Comment": "",
				}},
			]
		}
	}
}

var profile_presets = {
	"PROFILE PRESETS": {
		"[Category_1] Profile_Preset_1": {
			"Text": [
				{"§Comment": {
					"Color": "Color(1, 1, 1, 1)",
					"Comment": "",
				}},
			]
		}
	}
}

var dialogue = {
	"Conversation_1": {
		"Block_1": {
			"Text":[
				{"§Comment": {
					"Color": "Color(1, 1, 1, 1)",
					"Comment": "",
				}},
			]
		},
	}
}

#endregion


#° BBCODE:
#region
#^ List of all BBCode tags supported by Godot:
#% Used by functions that need to distinguish BBCode tags from regular text.
#TODO: Add your own custom tags if you have any.
#^ Type 1 — single-word tags (no params):
const BBCODE_TAGS_SIMPLE = [
	"b", "i", "u", "s", "code",
    "url", "img",
	"center", "left", "right", "fill", "indent",
	"ul", "ol", "li", "hr", "br", "p",
	"sub", "sup", "lb", "rb",
    "pulse", "wave", "tornado", "shake", "fade", "rainbow"
]

#^ Type 2 — tags followed by '=' syntax (color, size, font, etc.):
const BBCODE_TAGS_EQUALS = [
	"color", "bgcolor", "fgcolor",
	"font", "font_size",
	"outline_size", "outline_color",
	"url", "hint", "img",
	"table", "cell", "dropcap",
	"lang", "opentype_features",
	"char"
]

#^ Type 3 — tags followed by space-delimited parameters (animation, formatting, etc.):
const BBCODE_TAGS_SPACE = [
	"pulse", "shake", "wave", "tornado", "fade", "rainbow",
	"font", "img", "table", "cell", "dropcap", "p", "ul", "ol", "hr"
]
#endregion


#° COMMAND COLORS:
#region
#^Line Colors:
#? Custom colors for all lines.
#TODO: Add colors for new commands.
var line_colors = {
	#@ COMMENT
	"§Comment":			{"Text": Color(1.00, 1.00, 1.00, 1.00),		"BG": Color(0.50, 0.50, 0.50, 1.00)},

	#@ SPOKEN LINE
	"Spoken Line":		{"Text": Color(1.00, 1.00, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ CONTROL
	"§Set":				{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Call":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Emit":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Await":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Flag":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Name":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Disposition":		{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Role":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Export":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Import":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ CONDITIONS
	"§If":				{"Text": Color(0.87, 0.62, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Elif":			{"Text": Color(0.87, 0.62, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Else":			{"Text": Color(0.87, 0.62, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§For":				{"Text": Color(0.87, 0.62, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§While":			{"Text": Color(0.87, 0.62, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ TRANSITIONS
	"§Jump":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.70, 0.00, 0.00, 0.50)},
	"§Bridge": 			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.80, 0.50, 0.00, 0.50)},
	"§Return": 			{"Text": Color(0.80, 0.50, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§End": 			{"Text": Color(0.80, 0.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§LM": 				{"Text": Color(0.94, 0.25, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ INPUT
	"§Mouse": 			{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Input": 			{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Player_Advance":	{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ CHOICES
	"§Choice_List":		{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Choice_Status":	{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§Timer_Status":	{"Text": Color(0.33, 0.70, 1.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ EFFECTS
	"§Effect":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.50, 0.50, 1.00)},
	"§Effect_Stop":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.50, 0.50, 1.00)},
	"§Effect_Wait":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.50, 0.50, 1.00)},
	"§Wait":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.30, 0.30, 0.30, 1.00)},
	"§Hide":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.30, 0.30, 0.30, 1.00)},
	"§Clear":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.30, 0.30, 0.30, 1.00)},

	#@ IMAGE
	"§Image":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},
	"§I_Pause":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},
	"§I_Wait":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},
	"§I_Resume":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},
	"§I_Show":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},
	"§I_Stop":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.00, 0.61, 0.21, 1.00)},

	#@ SOUND
	"§Audio":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Volume":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Pause":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Wait":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Resume":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Skip":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},
	"§A_Stop":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.14, 0.35, 1.00, 1.00)},

	#@ VIDEO
	"§Video":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Volume":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Wait":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Pause":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Resume":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Skip":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Stop":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},
	"§V_Show":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.68, 0.00, 0.72, 1.00)},

	#@ BACKGROUND
	"§BG_Scene":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG":				{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Stop":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Remove":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Wait":			{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Mirror":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Effect":		{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Effect_Stop":	{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},
	"§BG_Effect_Wait":	{"Text": Color(0.90, 0.90, 0.90, 1.00),		"BG": Color(0.59, 0.59, 0.00, 1.00)},

	#@ VISUAL NOVEL
	"§VN_Scene":		{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Bust":			{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Move":			{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Bust_Stop":	{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Mirror":		{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Bust_Wait":	{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Remove":		{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Effect":		{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Effect_Wait":	{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§VN_Effect_Stop":	{"Text": Color(1.00, 1.00, 0.00, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ CUTSCENE
	"§CS_Scene":		{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Visible":		{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Loc":			{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Look":			{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Move":			{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Anim":			{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Anim_Wait":	{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Anim_Stop":	{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Sprite":		{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Sprite_Wait":	{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Sprite_Stop":	{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Toggle":		{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Cam":			{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
	"§CS_Light":		{"Text": Color(0.41, 0.70, 0.70, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},

	#@ CUSTOM
	"§Custom":			{"Text": Color(0.45, 1.00, 0.45, 1.00),		"BG": Color(0.00, 0.00, 0.00, 0.50)},
}

#endregion

#° COMMAND DATA:
#region
#^ Command Templates
#? List of all commands, in the dialogue script writing format.
#TODO: Add new commands here.
var line_templates = {
	#@ Spoken Line
	"Spoken Line": {
		"AI": "0",				#! Converted to string
		"TTS": "0",				#! Converted to string
		"ForceBubbles": "0",	#! Converted to string + Renamed from "BubbleExempt"
		"ForcePortrait": "0",
		"Disposition": "",
		"Reference": "",
		"Portrait": "",
		"PortraitPlay": "1",
		"Voice": "",
		"Variants": [
			{"Default": {
				"Text": "",
				"Direction": default_text_direction,
				"Weight": "1"
			}},
		]
	},

	#@ Core Logic
	"§Call": {
		"Await": "1",		#! Converted to string
		"Function": "",
		"Arguments": "",
		"Variable": ""
	},
	"§Emit": {
		"Signal": "",
		"Arguments": "",
	},
	"§Await": {
		"Signal": "",
		"Variable": "",
	},
	"§Set": {
		"Variable": "",
		"Operator": "=",
		"Expression": "",
	},
	"§Flag": {
		"Flag": "",
		"Operator": "=",
		"Expression": "",
	},
	"§Name": {
		"Reference": "",
		"Name": "",
		"Table": "",
		"Actor_Key": ""
	},
	"§Disposition": {
		"Reference": "",
		"Disposition": "",
	},
	"§Role": {
		"Role": "",
		"Reference": "",
	},
	"§Export": {
		"Path": "",
		"File": "",
		"Format": "",
		"Method": "Timestamp",
		"Data": "",
	},
	"§Import": {
		"Path": "",
		"File": "",
		"Format": "",
		"Dictionary": "",
	},
	"§Custom": {
		"Command": "",
		"Data": "",
	},

	#@ Conditions:
	"§If": {
		"Condition": "",
		"Type": "",
		"Commands": {},
	},
	"§Elif": {
		"Condition": "",
		"Type": "",
		"Commands": {},
	},
	"§Else": {
		"Type": "",
		"Commands": {},
	},
	"§For": {
		"Condition": "",
		"Type": "",
		"Commands": {},
	},
	"§While": {
		"Condition": "",
		"Type": "",
		"Commands": {},
	},

	#@ Transitions:
	"§Jump": {
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§Bridge": {
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§LM": {
		"Reference": "",
	},
	"§Return": {
	},
	"§End": {
	},

	#@ Input & Interaction
	"§Input": {
		"File": "",
		"Mode": "",
		"Variable": "",
		"Placeholder": "",
		"Instructions": "",
		"Text": "",
	},
	"§Mouse": {
		"Mouse Mode": "Visible",
	},

	#@ Choices
	"§Choice_List": {
		"Reference": "",
		"Title": "",
		"Main": "",
		"Mouse": "Default",
		"Tags": "",
		"Prompt": "",
		"Menu Scene": "",
		"Category Scene": "",
		"Button Scene": "",
		"Setup": {
			"Type": "Bridge",
			"Conversation": "",
			"Block": "",
			"Line": "",
		},
		"Custom": "",

		"Timers": [
		],

		"Categories": [
		],
	},

	"§Choice_Status": {
		"Menu Mode": "Last",
		"Menu Tags": "",
		"Category Mode": "Last",
		"Category Tags": "",
		"Choice Mode": "Last",
		"Choice Tags": "",
		"Enable": "-",
		"Activate": "-",
		"Show": "-",
		"Label": "",
		"Tooltip": "",
	},

	"§Timer_Status": {
		"Menu Mode": "Last",
		"Menu Tags": "",
		"Timer Mode": "Last",
		"Timer Tags": "",
		"Time": "",
		"Loop": "",
		"Show": "",
		"Status": "-",
		"Timer Node": "Ignore",
	},

	#@ Miscellaneous
	"§Comment": {
		"Color": "",
		"Comment": "",
	},

	#@ Background
	"§BG_Scene": {
		"Scene": "",
	},
	"§BG": {
		"Layers": "",
		"File": "",
		"Animation": "",
		"Loop": "0",
		"Wait": "0",
		"Time": ""
	},
	"§BG_Stop": {
		"Layers": "",
		"Default": "0",		#! Converted to string
	},
	"§BG_Wait": {
		"Layers": "",
		"Wait": "0",
		"Time": "",
	},
	"§BG_Remove": {
		"Layers": "",
	},
	"§BG_Mirror": {
		"Layers": "",
		"Axis": "H Flip",
	},	
	"§BG_Effect": {
		"Layers": "",
		"Library": "",
		"Effects": "",
		"Loop": "0",
		"Wait": "0",
		"Time": ""
	},
	"§BG_Effect_Stop": {
		"Layers": "",
		"Effects": "",
	},
	"§BG_Effect_Wait": {
		"Layers": "",
		"Effects": "",
		"Wait": "0",
		"Time": ""
	},

	#@ Effects
	"§Effect": {
		"Node": "",
		"Animation": "",
		"Loop": "1",
		"Wait": "0",
		"Time": "",
	},
	"§Effect_Stop": {
		"Node": "",
	},
	"§Effect_Wait": {
		"Node": "",
		"Wait": "0",
		"Time": "",
	},
	"§Wait": {
		"Time": "",
	},
	"§Player_Advance": {
	},
	"§Hide": {
		"Box": "1",
		"Portrait": "1",
	},
	"§Clear": {
		"Box": "1",
		"Bubbles": "1",
		"Subtitles": "1",
		"Portraits": "1",
		"Busts": "1",
		"Backgrounds": "1",
	},

	#@ Video
	"§Video": {
		"Node": "",
		"File": "",
		"Time": "",
		"Wait": "0",
		"Loop": "1",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§V_Wait": {
		"Node": "",
		"Time": "",
		"Wait": "0",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§V_Volume": {
		"Node": "",
		"Volume": "0",		#! Converted to string
		"Time": "0"
	},
	"§V_Pause": {
		"Node": "",
		"Lines": "0",		#! Converted to string
		"All": "0",			#! Converted to string
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§V_Resume": {
		"Node": "",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§V_Skip": {
		"Node": "",
		"Time": "",
	},
	"§V_Stop": {
		"Node": "",
	},
	"§V_Show": {
		"Node": "",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},

	#@ Image
	"§Image": {
		"Node": "",
		"File": "",
		"Animated": "0",	#! Converted to string
		"Duration": "0.0",
		"Loop": "1",
		"Time": "",
		"Wait": "0",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§I_Wait": {
		"Node": "",
		"Time": "",
		"Wait": "0",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§I_Pause": {
		"Node": "",
		"Lines": "0",		#! Converted to string
		"All": "0",			#! Converted to string
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§I_Resume": {
		"Node": "",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§I_Show": {
		"Node": "",
		"Box": 	"0",		#! Converted to string
		"Portrait": "0",	#! Converted to string
	},
	"§I_Stop": {
		"Node": "",
	},

	#@ Audio
	"§Audio": {
		"Node": "",
		"File": "",
		"Loop": "1",
		"Time": "",
		"Wait": "0",
	},
	"§A_Volume": {
		"Node": "",
		"Volume": "0",
		"Time": "0"
	},
	"§A_Wait": {
		"Node": "",
		"Time": "",
		"Wait": "0",
	},
	"§A_Pause": {
		"Node": "",
		"Lines": "0",
		"All": "0",			#! Converted to string
	},
	"§A_Resume": {
		"Node": "",
	},
	"§A_Skip": {
		"Node": "",
		"Time": "",
	},
	"§A_Stop": {
		"Node": ""
	},

	#@ Visual Novel (VN)
	"§VN_Scene": {
		"Scene": "",
	},
	"§VN_Bust": {
		"Bust": "",
		"Reference": "",
		"File": "",
		"Animation": "",
		"Loop": "1",
		"Wait": "0",
		"Time": "",
	},
	"§VN_Move": {
		"Bust": "",
		"Reference": "",
	},
	"§VN_Bust_Stop": {
		"Actors": "",
		"Default": "0",			#! Converted to string
	},
	"§VN_Mirror": {
		"Actors": "",
		"Axis": "H Flip",
	},
	"§VN_Bust_Wait": {
		"Actors": "",
		"Wait": "0",
		"Time": "",
	},
	"§VN_Remove": {
		"Actors": "",
	},
	"§VN_Effect": {
		"Actors": "",
		"Library": "",
		"Effects": "",
		"Loop": "1",
		"Wait": "0",
		"Time": "",
	},
	"§VN_Effect_Stop": {
		"Actors": "",
		"Effects": "",	
	},
	"§VN_Effect_Wait": {
		"Actors": "",
		"Effects": "",
		"Wait": "0",
		"Time": ""
	},

	#@ Cutscene
	"§CS_Scene": {
		"Path 1": "",
		"Targets": "",
		"Scene": "",
	},
	"§CS_Visible": {
		"Path 1": "",
		"Targets": "",
		"Visibility": "toggle",
	},
	"§CS_Loc": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Markers": "",
		"Rotate": "1"
	},
	"§CS_Look": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Markers": "",
		"Axis": "-Z"
	},
	"§CS_Move": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Markers": "",
		"Animation": "",
		"Method": "",
		"Properties": "",
		"Loop": "",
		"Wait": "0",
		"Time": "0",
		"Default": "",
	},
	"§CS_Anim": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Animation": "",
		"Loop": "1",
		"Wait": "0",
		"Time": "",
	},
	"§CS_Anim_Wait": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Wait": "0",
		"Time": "",
	},
	"§CS_Anim_Stop": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Default": "1"
	},
	"§CS_Sprite": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"File": "",
		"Animation": "",
		"Loop": "1",
		"Wait": "0",
		"Time": "",
	},
	"§CS_Sprite_Wait": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Wait": "0",
		"Time": "",
	},
	"§CS_Sprite_Stop": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Default": "1",
	},
	"§CS_Cam": {
		"Path 1": "",
		"Targets": "",
	},
	"§CS_Light": {
		"Path 1": "",
		"Targets": "",
		"Operator": "=",
		"Energy": "",
		"Color": "",
	},
	"§CS_Toggle": {
		"Path 1": "",
		"Targets": "",
		"Method": "",
		"Properties": "",
		"Value": "",
	},
}

#endregion
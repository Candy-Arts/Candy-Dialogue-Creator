extends Node


#& CUSTOMIZABLE

var current_profile = "Godot Project"

#^ Path to local export folder:
#? Unused
var local_export_folder = "user://Profiles".path_join(current_profile).path_join("Exports")

#^ Paths to resource files in the project folder:
var project_path = ""

var default_path_ends = {
	"Dialogues": "Candy_DE/Dialogues",

	"*Portraits": "Candy_DE/Media/Characters/Portraits",
	"*Busts": "Candy_DE/Media/Characters/Busts",
	"*Voices": "Candy_DE/Media/Characters/Voices",

	"Images": "Candy_DE/Media/General/Images",
	"Audio": "Candy_DE/Media/General/Audio",
	"Videos": "Candy_DE/Media/General/Videos",
	"Backgrounds": "Candy_DE/Media/General/Backgrounds",

	"Input Menus": "Candy_DE/Scenes/Input Menus",
	"Choice Menus": "Candy_DE/Scenes/Choice Menus",
	"Choice Categories": "Candy_DE/Scenes/Choice Categories",
	"Choice Buttons": "Candy_DE/Scenes/Choice Buttons",
	"VN Scenes": "Candy_DE/Scenes/VN Scenes",
	"BG Scenes": "Candy_DE/Scenes/Background Scenes",	
}

var default_resource_paths = {
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
}

var custom_resource_paths = {
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
}

var resource_paths = default_resource_paths

var data_scripts = {
	"Flag": {
		"Script": "",
		"Variable": "",
	},
	"Disposition": {
		"Script": "",
		"Variable": "",
	},
	"Actor": {
		"Script": "",
		"Variable": "",
	},
	"Role": {
		"Script": "",
		"Variable": "",
	},
}

var properties_script_path = ""

var operator_list = ["=", "+=", "-=", "×=", "÷=", "append"]
var flag_list = []
var disposition_list = []
var actor_list = []
var role_list = []
var bust_list = []
var layer_list = []
var effect_list = []

var autoload_symbol = "£"
var node_symbol = "$"
var candy_symbol = "€"
var super_autoload_symbol = "££"
var super_node_symbol = "$$"
var super_candy_symbol = "€€"

var role_symbol = "°"

var var_in_speech_start = "{)"
var var_in_speech_end = "}"

var substitution_symbol = "•"
var separator_symbol = "|"


#& SETTINGS
var active_profile = ""

var use_default_project_folders = false

var confirm_delete_line = false

var default_text_direction = "ltr"

var spoken_line_limit: int = 250
var spoken_line_near_limit: int = 50

var new_conversation_name = ""
var new_block_name = ""

#^ Size limit for portrait previews:
#% 0 = no limit
var portrait_preview_max_w = 200
var portrait_preview_max_h = 200

var bust_preview_max_w = 200
var bust_preview_max_h = 500

var image_preview_max_w = 300
var image_preview_max_h = 300

var video_preview_max_w = 300
var video_preview_max_h = 300

var bg_preview_max_w = 500
var bg_preview_max_h = 500

#^ Save settings:
var after_save = ""

var incremental_saves = false
var auto_saves = 0
var auto_saves_frequency = 0.0
var quick_saves: int = 0

var variants_dict = {}

var custom_presets = {}

var custom_writer_inserts = [
	#/["Test", "[TEST INSERT]", "[END INSERT]"],
]

var color_mode: int = 0

var color_models = {
	0: {
		"On": Color(0, 1, 0),				#/ green
		"Off": Color(1, 0, 0),				#/ red
		"Neutral": Color(1, 1, 0),			#/ yellow
		"Selected": Color(0, 1, 1),			#/ light blue
		"Null": Color(1, 1, 1),				#/ white
		"Fade": Color(0.5, 0.5, 0.5),		#/ grey
	},

	1: {
		"On": Color(0, 158, 115),			#/ teal
		"Off": Color(0.9, 0.62, 0.0),		#/ orange
		"Neutral": Color(255, 193, 7),		#/ amber
		"Selected": Color(64, 191, 193),	#/ turquoise
		"Null": Color(1, 1, 1),				#/ white
		"Fade": Color(0.5, 0.5, 0.5),		#/ grey
	}

}


#& DATA

var dc_version = "1.0.3"
var dialogue_version = "1.0.0"


var loaded_save = ""
var quick_save_index = -1

var hide_commands = false
var hide_indexes = false
var hide_tags = false
var hide_disposition = false
var hide_voice = false
var hide_portrait = false
var hide_limit = false

var undo_memory = 100
var undo_array = []
var undo_step = 0

var current_conversation = "Conversation_1"
var current_block = "Block_1"

#^ Saved Conversations:
#% Format:
#%	"Conversation Test": {
#%		"Block_1": {
#%			"Text": []
#%		}
#%	}
var conversations = {
	"CUSTOM_PRESETS": {
		"[Category_A]Preset_1": {
			"Text": []
		}
	},

	"Conversation_1": {
		"Block_1": {
			"Text": [
				{"§Comment": {
					"Color": null,
					"Comment": "",
				}},
			]
		}
	}
}


#^ Fold command groups in the sidebar:
var command_groups_fold = 0

#^ Are we deleting a conversation, block or variant
var rc_target

#^ Track resource folder modification date:
var folder_mtimes = {}

#^ List all resource files:
var resources = {}

#^ Line that called the writer:
var write_line_index = -1
var write_variant = ""

#^ Line that called the ConditionEditor:
var condition_line
var condition_line_index = -1

var comment_line
var comment_line_index = -1

var variant_filter_mode = "Restrict"
var variant_filter_match = "Exact"
var variant_show = false
var variant_filter = []

#^ Line moving and selection data
var selected_lines: Array = []			#/ List of dictionary indices
var last_clicked_line: int = -1			#/ For shift-range selection
var alt_click_line_index: int = -1   	#/ Set by line on ALT+click; main will act on it
var alt_click_move_below: bool = false

var line_delete_index: int = -1   		#/ Temporary holder for right-clicked line index

var clipboard_lines = []     			#/ Array of dictionaries

#^ Conversation/Block browsing history:
var browsing_history: Array = []
var browsing_index: int = 0


signal alt_click_target_set(target_idx: int, move_below: bool)

signal line_right_clicked(line_idx: int)

var refresh_conv_block_selectors = false

var editor_state = "project"

var color_pick_mode = ""
var	cs_line_index
var	cs_line


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



#^Line Colors:
#? Custom colors for all lines.
#TODO: Add colors for new commands.
var line_colors = {
	#@ SPOKEN LINE
	"Spoken Line": {
		"BG": Color(0.4, 0.65, 0.85),
		"Border": Color(0.0, 0.0, 0.0),
	},

	#@ CORE LOGIC
	"§Set":				{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Call":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Emit":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Await":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Flag":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Name":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Disposition":		{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Role":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Export":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},	
	"§Import":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},
	"§Custom":			{"BG": Color(0.45, 0.75, 0.45), "Border": Color(0.0, 0.0, 0.0)},

	#@ CONDITIONS
	"§If":				{"BG": Color(0.7, 0.5, 0.8), "Border": Color(0.0, 0.0, 0.0)},
	"§Elif":			{"BG": Color(0.7, 0.5, 0.8), "Border": Color(0.0, 0.0, 0.0)},
	"§Else":			{"BG": Color(0.7, 0.5, 0.8), "Border": Color(0.0, 0.0, 0.0)},
	"§For":				{"BG": Color(0.7, 0.5, 0.8), "Border": Color(0.0, 0.0, 0.0)},
	"§While":			{"BG": Color(0.7, 0.5, 0.8), "Border": Color(0.0, 0.0, 0.0)},

	#@ TRANSITIONS
	"§Jump":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.7, 0.0, 0.0)},
	"§Bridge": 			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.8, 0.5, 0.0)},
	"§Return": 			{"BG": Color(0.8, 0.5, 0.0), "Border": Color(0.0, 0.0, 0.0)},
	"§End": 			{"BG": Color(0.7, 0.0, 0.0), "Border": Color(0.0, 0.0, 0.0)},
	"§LM": 				{"BG": Color(0.9, 0.9, 0.9), "Border": Color(0.0, 0.0, 0.0)},

	#@ INPUT
	"§Input": 			{"BG": Color(0.5, 0.4, 0.75), "Border": Color(0.0, 0.0, 0.0)},
	"§Mouse": 			{"BG": Color(0.5, 0.4, 0.75), "Border": Color(0.0, 0.0, 0.0)},

	#@ CHOICES
	"§Choice_List":		{"BG": Color(0.5, 0.4, 0.75), "Border": Color(0.0, 0.0, 0.0)},
	"§Choice_Status":	{"BG": Color(0.5, 0.4, 0.75), "Border": Color(0.0, 0.0, 0.0)},
	"§Timer_Status":	{"BG": Color(0.5, 0.4, 0.75), "Border": Color(0.0, 0.0, 0.0)},

	#@ MISCELLANEOUS
	"§Comment":			{"BG": Color(0.5, 0.5, 0.5), "Border": Color(0.0, 0.0, 0.0)},

	#@ BACKGROUND
	"§BG_Scene":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG":				{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Stop":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Remove":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Wait":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Mirror":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Effect":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Effect_Stop":	{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},
	"§BG_Effect_Wait":	{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Forest_Green")},

	#@ EFFECTS
	"§Effect":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Teal")},
	"§Effect_Stop":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Teal")},
	"§Effect_Wait":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Teal")},
	"§Wait":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color("Teal")},
	"§Hide":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.5, 0.5)},
	"§Clear":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.5, 0.5)},

	#@ IMAGE
	"§Image":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},
	"§I_Pause":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},
	"§I_Wait":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},
	"§I_Resume":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},
	"§I_Show":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},
	"§I_Stop":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.4, 0.65, 0.85)},

	#@ SOUND
	"§Audio":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Volume":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Pause":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Wait":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Resume":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Skip":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},
	"§A_Stop":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.75, 0.0, 0.75)},

	#@ VIDEO
	"§Video":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Volume":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Wait":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Pause":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Resume":		{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Skip":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Stop":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},
	"§V_Show":			{"BG": Color(0.25, 0.25, 0.25), "Border": Color(0.5, 0.4, 0.75)},

	#@ VISUAL NOVEL
	"§VN_Scene":		{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Bust":			{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Move":			{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Bust_Stop":	{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Mirror":		{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Bust_Wait":	{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Remove":		{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Effect":		{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Effect_Wait":	{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},
	"§VN_Effect_Stop":	{"BG": Color(0.75, 0.75, 0.4), "Border": Color(0.0, 0.0, 0.0)},

	#@ CUTSCENE
	"§CS_Scene":		{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Visible":		{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Loc":			{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Move":			{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Anim":			{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Anim_Wait":	{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Anim_Stop":	{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Sprite":		{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Sprite_Wait":	{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Sprite_Stop":	{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Toggle":		{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Cam":			{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
	"§CS_Light":		{"BG": Color("Dark_Slate_Gray"), "Border": Color(0.0, 0.0, 0.0)},
}


#^ Command Templates
#? List of all commands, in the dialogue script writing format.
#TODO: Add new commands here.
var command_templates = {
	#@ Spoken Line
	"Spoken Line": {
		"AI": 0,
		"TTS": 0,
		"BubbleExempt": false,
		"ForcePortrait": "0",
		"Disposition": "",
		"Reference": "",
		"Portrait": "",
		"PortraitPlay": "1",
		"Voice": "",
		"ShowVariants": false,
		"Variants": [
			{"Default": {
				"Text": "",
				"Enabled": true,
				"Hide": false,
				"Direction": default_text_direction,
			}},
			{"DevCom": {
				"Text": "",
				"Enabled": true,
				"Hide": false,
				"Direction": default_text_direction,
			}},
		]
	},

	#@ Core Logic
	"§Call": {
		"Await": true,
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
		"Type": "Transition",
		"Variable": "",
		"Flag": "",
		"Operator": "=",
		"Expression": "",
		"Role": "",
		"Reference": "",
		"Disposition": "",
		"Name": "",
		"Table": "",
		"Actor_Key": "",
		"Await": true,
		"Function": "",
		"Signal": "",
		"Arguments": "",
		"Transition": "Bridge",
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§Elif": {
		"Condition": "",
		"Type": "Transition",
		"Variable": "",
		"Flag": "",
		"Operator": "=",
		"Expression": "",
		"Role": "",
		"Reference": "",
		"Disposition": "",
		"Name": "",
		"Table": "",
		"Actor_Key": "",
		"Await": true,
		"Function": "",
		"Signal": "",
		"Arguments": "",		
		"Transition": "Bridge",
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§Else": {
		"Type": "Transition",
		"Variable": "",
		"Flag": "",
		"Operator": "=",
		"Expression": "",
		"Role": "",
		"Reference": "",
		"Disposition": "",
		"Name": "",
		"Table": "",
		"Actor_Key": "",
		"Await": true,
		"Function": "",
		"Signal": "",
		"Arguments": "",		
		"Transition": "Bridge",
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§For": {
		"Condition": "",
		"Type": "Transition",
		"Variable": "",
		"Flag": "",
		"Operator": "=",
		"Expression": "",
		"Role": "",
		"Reference": "",
		"Disposition": "",
		"Name": "",
		"Table": "",
		"Actor_Key": "",
		"Await": true,
		"Function": "",
		"Signal": "",
		"Arguments": "",		
		"Transition": "Bridge",
		"Conversation": "",
		"Block": "",
		"Line": "",
	},
	"§While": {
		"Condition": "",
		"Type": "Transition",
		"Variable": "",
		"Flag": "",
		"Operator": "=",
		"Expression": "",
		"Role": "",
		"Reference": "",
		"Disposition": "",
		"Name": "",
		"Table": "",
		"Actor_Key": "",
		"Await": true,
		"Function": "",
		"Signal": "",
		"Arguments": "",		
		"Transition": "Bridge",
		"Conversation": "",
		"Block": "",
		"Line": "",
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
		"Color": null,
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
		"Default": 0,
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
		"Box": 0,
		"Portrait": 0,
	},
	"§V_Wait": {
		"Node": "",
		"Time": "",
		"Wait": "0",
		"Frame": 0,
		"Box": 0,
		"Portrait": 0,
	},
	"§V_Volume": {
		"Node": "",
		"Volume": 0,
		"Time": "0"
	},
	"§V_Pause": {
		"Node": "",
		"Lines": 0,
		"All": 0,
		"Box": 0,
		"Portrait": 0,
	},
	"§V_Resume": {
		"Node": "",
		"Box": 0,
		"Portrait": 0,
	},
	"§V_Skip": {
		"Node": "",
		"Time": "",
		"Frame": 0,
	},
	"§V_Stop": {
		"Node": "",
	},
	"§V_Show": {
		"Node": "",
		"Box": 0,
		"Portrait": 0,
	},

	#@ Image
	"§Image": {
		"Node": "",
		"File": "",
		"Animated": 0,
		"Duration": "0.0",
		"Loop": "1",
		"Time": "",
		"Wait": "0",
		"Box": 0,
		"Portrait": 0,

	},
	"§I_Wait": {
		"Node": "",
		"Time": "",
		"Wait": "0",
		"Box": 0,
		"Portrait": 0,
	},
	"§I_Pause": {
		"Node": "",
		"Lines": 0,
		"All": 0,
		"Box": 0,
		"Portrait": 0,
	},
	"§I_Resume": {
		"Node": "",
		"Box": 0,
		"Portrait": 0,
	},
	"§I_Show": {
		"Node": "",
		"Box": 0,
		"Portrait": 0,
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
		"All": 0,
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
		"Default": 0,
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
		"Visibility": "Toggle",
	},
	"§CS_Loc": {
		"Path 1": "",
		"Targets": "",
		"Path 2": "",
		"Markers": "",
		"Rotate": "1"
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
		"Play": "1",
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
		"Play": "1",
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

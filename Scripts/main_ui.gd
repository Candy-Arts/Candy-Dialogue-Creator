extends Control


@onready var top_text = get_node("UI/VBox/TopText")

#^ Top Bar Buttons:
@onready var conversation_selector = get_node("UI/VBox/Top/HBox/Conversations/OptionButton")
@onready var block_selector = get_node("UI/VBox/Top/HBox/Blocks/OptionButton")
@onready var dialogue_sort_button = get_node("UI/VBox/Top/HBox/Sort")

#^ Misc. UI Elements:
@onready var main_menu_button = get_node("UI/VBox/Top/HBox/Menu")
@onready var line_tree = get_node("UI/VBox/VSplit/Middle/HSplit/LineOverview/VBox/Tree")
@onready var line_container_list = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox")
@onready var shield = get_node("Shield")
@onready var invisishield = get_node("InvisiShield")
@onready var sidebar = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar")
@onready var side_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideButton")
@onready var meta_block = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/Meta")
@onready var custom_data_block = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/CustomData")
@onready var devcom_block = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/DevComment")
@onready var meta_field = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/Meta/TextEdit")
@onready var custom_data_field = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/CustomData/TextEdit")
@onready var devcom_field = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/DevComment/TextEdit")

@onready var tools_color_picker = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Color/Color/ColorPicker")
@onready var tools_color_mode = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Color/Color/Mode")
@onready var tools_hex_color = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Color/Hex/Label")
@onready var tools_rgb_color = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Color/RGB/Label")

@onready var role_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Variables/Role")
@onready var singleton_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Variables/Singleton")
@onready var node_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Variables/Node")
@onready var vardict_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Variables/VarDict")
@onready var super_singleton_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Super/Singleton")
@onready var super_node_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Super/Node")
@onready var super_vardict_insert_button = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Tools/VBox/Super/VarDict")

#^ Add Line Buttons:
@onready var spoken_line_btn = get_node("UI/VBox/VSplit/PanelContainer/HBox/BasicLines/SpokenLine")
@onready var comment_line_btn = get_node("UI/VBox/VSplit/PanelContainer/HBox/BasicLines/Comment")
@onready var command_menu = get_node("UI/VBox/VSplit/PanelContainer/HBox/Commands")
@onready var favorites_container = get_node("UI/VBox/VSplit/PanelContainer/HBox/Commands/Favorites")
@onready var user_presets_container = get_node("UI/VBox/VSplit/PanelContainer/HBox/Commands/UserPresets")
@onready var profile_presets_container = get_node("UI/VBox/VSplit/PanelContainer/HBox/Commands/ProfilePresets")

#^ Context Menus:
@onready var dropdown_list = get_node("UI/DropDownList")
@onready var dropdown_list_2 = get_node("UI/DropDownList2")

@onready var choice_tree_context_menu = get_node("UI/ChoiceTreeContextMenu")
@onready var line_context_menu = get_node("UI/LineContextMenu")
@onready var sort_context_menu = get_node("UI/SortContextMenu")
@onready var conversation_context_menu = get_node("UI/ConversationContextMenu")
@onready var block_context_menu = get_node("UI/BlockContextMenu")
@onready var favorites_context_menu = get_node("UI/FavoritesContextMenu")
@onready var save_context_menu = get_node("UI/SaveContextMenu")
@onready var insert_context_menu = get_node("UI/InsertContextMenu")
@onready var main_menu = get_node("UI/MainMenu")
@onready var settings_variant_context_menu = get_node("UI/SettingsVariantsContextMenu")

#^ File Dialogues:
@onready var path_dialogue = get_node("PathDialogue")
@onready var script_dialogue = get_node("ScriptDialogue")
@onready var save_dialogue = get_node("SaveDialogue")
@onready var load_dialogue = get_node("LoadDialogue")
@onready var export_dialogue = get_node("ExportDialogue")
@onready var import_dialogue = get_node("ImportDialogue")
@onready var convert_dialogue = get_node("VersionConverter")

#^ Audio Players:
@onready var audio_player = get_node("AudioPlayer")
@onready var voice_player_1 = get_node("VoicePlayer1")
@onready var variant_voice_player = get_node("VoicePlayer2")
@onready var translation_voice_player = get_node("VoicePlayer3")

@onready var video_preview_popup = get_node("UI/VideoPreview/")
@onready var video_preview_player = get_node("UI/VideoPreview/VideoStreamPlayer")

@onready var image_preview_popup = get_node("UI/ImagePreview/")
@onready var image_preview_player = get_node("UI/ImagePreview/TextureRect")

@onready var sprite_preview_popup = get_node("UI/SpritePreview/")
@onready var sprite_preview_player = get_node("UI/SpritePreview/Sprite2D")

#^ Timers:
@onready var auto_save_timer = get_node("AutoSaveTimer")

#^ Warning:
@onready var warning_panel = get_node("Warning")
@onready var warning_message = get_node("Warning/PanelContainer/RichTextLabel")
@onready var warning_player = get_node("Warning/AnimationPlayer")
@onready var warning_timer = get_node("Warning/Timer")

#^ Choices:
@onready var choice_tree = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/ChoiceTree/Tree")
@onready var choice_category_settings = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings")
@onready var choice_item_settings = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings")
@onready var choice_timer_settings = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings")

@onready var choice_general_prompt = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Prompt")
@onready var choice_general_mouse = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Mouse")
@onready var choice_general_setup = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Setup")
@onready var choice_general_self_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/MenuScene")
@onready var choice_general_category_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategoryScene")
@onready var choice_general_item_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceScene")
@onready var choice_general_tags = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Tags")
@onready var choice_general_custom = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Custom")

@onready var choice_category_prompt = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Prompt")
@onready var choice_category_mouse = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Mouse")
@onready var choice_category_setup = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Setup")
@onready var choice_category_self_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/CategoryScene")
@onready var choice_category_item_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/ChoiceScene")
@onready var choice_category_tags = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Tags")
@onready var choice_category_custom = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Custom")

@onready var choice_item_tooltip = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Tooltip")
@onready var choice_item_setup = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Setup")
@onready var choice_item_self_scene = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/ChoiceScene")
@onready var choice_item_tags = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Tags")
@onready var choice_item_custom = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Custom")

@onready var choice_timer_setup = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Setup")
@onready var choice_timer_timeout = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Timeout")
@onready var choice_timer_tags = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Tags")
@onready var choice_timer_custom = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Custom")

#^ Spoken Line Data Fields:
@onready var overrides_area = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Tags")
@onready var variant_voice_area = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Voice")
@onready var variant_volume_slider = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Voice/VoiceControls/Sliders/Volume/Slider")
@onready var variant_translation_volume_slider = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Voice/VoiceControls/Sliders/Progress/Slider")
@onready var translation_area = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation")
@onready var portrait_bg = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay/PortraitBGColor")
@onready var portrait_file = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/VBox/PortraitFile")
@onready var portrait_play = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/VBox/PlayPortrait")
@onready var portrait_box = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay")
@onready var portrait_display = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay/TextureRect")
@onready var portrait_video = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay/VideoStreamPlayer")
@onready var portrait_sprite = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay/Sprite2D")
@onready var portrait_animated_sprite = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/PortraitDisplay/AnimatedSprite2D")
@onready var disposition_field = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Speaker/VBox/Disposition")

@onready var variant_tree = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Variants/Tree")
@onready var spoken_text_edit = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/TextEdit")
@onready var spoken_text_preview = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/Preview/SpeechPreview")
@onready var spoken_text_preview_bg = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/Preview/ColorRect")
@onready var variant_weight = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/Weight")
@onready var variant_direction_field = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/Direction")

@onready var translation_tree = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/Variants/Tree")
@onready var translation_preview_raw = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/PreviewRaw/SpeechPreview")
@onready var translation_preview_final = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/PreviewFinal/SpeechPreview")
@onready var translation_preview_raw_bg = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/PreviewRaw/ColorRect")
@onready var translation_preview_final_bg = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/PreviewFinal/ColorRect")
@onready var translation_voice_area = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/VoiceControls")
@onready var translation_volume_slider = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/VoiceControls/Sliders/Volume/Slider")
@onready var translation_progress_slider = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/VoiceControls/Sliders/Progress/Slider")

@onready var preview_bg_color_picker = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/PreviewBGColor/PreviewBGColor")
@onready var preview_text_color_picker = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/PreviewTextColor2/PreviewTextColor")

@onready var user_inserts_list = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/User/VBox")
@onready var profile_inserts_list = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/SideBar/VBox/TabContainer/Profile/VBox")

@onready var variant_characters = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/HBoxContainer/Counters/Characters/Count")
@onready var variant_words = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/HBoxContainer/Counters/Words/Count")
@onready var variant_limit = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Writing/Speech/HBox/HBoxContainer/Limit/Count")
@onready var translation_characters = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/Counters/Characters/Count/Count")
@onready var translation_character_difference = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/Counters/Characters/Difference/Count")
@onready var translation_words = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/Counters/Words/Count/Count")
@onready var translation_word_difference = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/VBox/Translation/HBox/VBox/Counters/Counters/Words/Difference/Count")

#^ Visibility Filters:
@onready var translation_area_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Filters/Translation")
@onready var portrait_play_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Filters/Portrait")
@onready var variant_voice_area_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Filters/Voice")
@onready var disposition_field_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Filters/Disposition")
@onready var overrides_area_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/SpokenLine/Data/Filters/Tags")

@onready var choice_general_prompt_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Prompt")
@onready var choice_general_mouse_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Mouse")
@onready var choice_general_setup_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Setup")
@onready var choice_general_scenes_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Scenes")
@onready var choice_general_tags_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Tags")
@onready var choice_general_custom_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/Filters/Custom")

@onready var choice_category_prompt_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Prompt")
@onready var choice_category_mouse_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Mouse")
@onready var choice_category_setup_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Setup")
@onready var choice_category_scenes_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Scenes")
@onready var choice_category_tags_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Tags")
@onready var choice_category_custom_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/CategorySettings/Filters/Custom")

@onready var choice_item_tooltip_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Filters/Tooltip")
@onready var choice_item_setup_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Filters/Setup")
@onready var choice_item_scenes_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Filters/Scene")
@onready var choice_item_tags_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Filters/Tags")
@onready var choice_item_custom_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/ChoiceSettings/Filters/Custom")

@onready var choice_timer_setup_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Filters/Setup")
@onready var choice_timer_timeout_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Filters/Timeout")
@onready var choice_timer_tags_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Filters/Tags")
@onready var choice_timer_custom_filter = get_node("UI/VBox/VSplit/Middle/HSplit/EditArea/HBox/Editor/ScrollContainer/VBox/ChoiceList/HBox/Data/TimerSettings/Filters/Custom")


var line_data_containers = {}
var line_data_fields = {}


#^ Standalone Scenes:
var insert_menu
var export_menu
var import_menu
var prompt_menu
var landing_screen
var settings_menu
var about_menu

var selected_lines = []

var sort_dialogue = false
var clipboard: Array = []
var _selection_changing := false
var sort_context_target: TreeItem = null

var _favorites_context_target: Dictionary = {}

#? Number of frames inside the current sprite sheet for the speaker portrait:
var _portrait_sprite_total_frames := 0

#? Don't call save_undo_step() if true:
#% Prevents saving multiple undo steps for the same action.
var _suppress_undo_save := false
var _applying_undo_step := false
var _updating_ui := false



#* Input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == globals.shortcut_keys["Quick_Save"]:
			quick_save()
		elif event.keycode == globals.shortcut_keys["Quick_Load"]:
			quick_load()

	var hovered = get_viewport().gui_get_hovered_control()

	if not event is InputEventMouseButton or not event.pressed:
		return

	#@ Left-click:
	if event is InputEventMouseButton and event.pressed:
		#% Hide drop-down menus:
		if dropdown_list.visible:
			var rect = Rect2(dropdown_list.position, dropdown_list.size)
			var rect2 = Rect2(dropdown_list_2.position, dropdown_list_2.size)
			if not rect.has_point(event.position) and not rect2.has_point(event.position):
				dropdown_list.hide()
				dropdown_list_2.hide()

	#@ Right-click on tree → show context menu:
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if (hovered == line_tree or line_tree.is_ancestor_of(hovered)) and sort_dialogue == false:
			if not selected_lines.is_empty():
				#% Clear last focus:
				globals.last_focused_field = null

				line_context_menu.popup()
				line_context_menu.position = Vector2i(event.global_position)
				get_viewport().set_input_as_handled()
			return

		elif (hovered == line_tree or line_tree.is_ancestor_of(hovered)) and sort_dialogue == true:
			#% Clear last focus:
			globals.last_focused_field = null

			var item = line_tree.get_item_at_position(line_tree.get_local_mouse_position())
			if item == null:
				return
			sort_context_target = item
			var is_block = item.get_parent() != line_tree.get_root()
			#% Grey out Delete if last conversation or last block:
			var delete_idx = sort_context_menu.get_item_index(2)
			if is_block:
				var conv_name = item.get_parent().get_text(0)
				sort_context_menu.set_item_disabled(delete_idx, globals.dialogue[conv_name].size() <= 1)
			else:
				sort_context_menu.set_item_disabled(delete_idx, globals.dialogue.size() <= 1)
			sort_context_menu.popup()
			sort_context_menu.position = Vector2i(event.global_position)
			get_viewport().set_input_as_handled()
			return

		elif hovered == conversation_selector or conversation_selector.is_ancestor_of(hovered):
			#% Clear last focus:
			globals.last_focused_field = null

			if globals.current_conversation == "USER PRESETS" or globals.current_conversation == "PROFILE PRESETS":
				return
			#% Grey out Delete if last conversation:
			var delete_idx = conversation_context_menu.get_item_index(1)
			conversation_context_menu.set_item_disabled(delete_idx, globals.dialogue.size() <= 1)
			conversation_context_menu.popup()
			conversation_context_menu.position = Vector2i(event.global_position)
			get_viewport().set_input_as_handled()
			return

		elif hovered == block_selector or block_selector.is_ancestor_of(hovered):
			globals.last_focused_field = null
			#% Grey out Delete if last block, accounting for presets:
			var delete_idx = block_context_menu.get_item_index(1)
			var block_count := 0
			if globals.current_conversation == "USER PRESETS":
				block_count = globals.user_presets.get("USER PRESETS", {}).size()
			elif globals.current_conversation == "PROFILE PRESETS":
				block_count = globals.profile_presets.get("PROFILE PRESETS", {}).size()
			else:
				block_count = globals.dialogue[globals.current_conversation].size()
			block_context_menu.set_item_disabled(delete_idx, block_count <= 1)
			block_context_menu.popup()
			block_context_menu.position = Vector2i(event.global_position)
			get_viewport().set_input_as_handled()
			return


#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	insert_menu = get_node("InsertCreator")
	export_menu = get_node("ExportMenu")
	import_menu = get_node("ImportMenu")
	prompt_menu = get_node("PromptMessage")
	landing_screen = get_node("LandingScreen")
	settings_menu = get_node("SettingsMenu")
	about_menu = get_node("AboutMenu")

	dropdown_list.borderless = true
	dropdown_list.transparent = true
	dropdown_list.unresizable = true
	dropdown_list.popup_window = false
	dropdown_list.exclusive = false

	dropdown_list_2.borderless = true
	dropdown_list_2.transparent = true
	dropdown_list_2.unresizable = true
	dropdown_list_2.popup_window = false
	dropdown_list_2.exclusive = false

	video_preview_popup.borderless = true
	video_preview_popup.transparent = true
	video_preview_popup.unresizable = true
	video_preview_popup.popup_window = false
	video_preview_popup.exclusive = false

	image_preview_popup.borderless = true
	image_preview_popup.transparent = true
	image_preview_popup.unresizable = true
	image_preview_popup.popup_window = false
	image_preview_popup.exclusive = false

	sprite_preview_popup.borderless = true
	sprite_preview_popup.transparent = true
	sprite_preview_popup.unresizable = true
	sprite_preview_popup.popup_window = false
	sprite_preview_popup.exclusive = false


	#% Populate context menus:
	populate_line_context_menu()
	populate_sort_context_menu()
	populate_conversation_context_menu()
	populate_block_context_menu()
	populate_favorites_context_menu()

	for line_container in line_container_list.get_children():
		if line_container.has_meta("command"):
			var command_key = line_container.get_meta("command")
			line_data_containers[command_key] = line_container

	#% Connect variant tree button signals:
	variant_tree.item_selected.connect(_on_variant_tree_item_selected)
	translation_tree.item_selected.connect(_on_translation_tree_item_selected)

	#% Connect choice tree button signals:
	choice_tree.item_selected.connect(_on_choice_tree_item_selected)
	choice_tree.set_drag_forwarding(_get_drag_data_fw, _can_drop_data_fw, _drop_data_fw)

	#% Connect main menu buttons:
	main_menu.id_pressed.connect(_on_main_menu_id_pressed)

	#% Connect insert context menu button signals:
	insert_context_menu.id_pressed.connect(_on_insert_context_menu_id_pressed)

	settings_variant_context_menu.id_pressed.connect(settings_menu._on_settings_variant_context_menu_id_pressed)

	dropdown_list.popup_hide.connect(func():
		invisishield.visible = false)

	dropdown_list.mouse_exited.connect(func():
		var mouse_pos = get_viewport().get_mouse_position()
		var rect = Rect2(dropdown_list.position, dropdown_list.size)
		var rect2 = Rect2(dropdown_list_2.position, dropdown_list_2.size)
		if not rect.has_point(mouse_pos) and not rect2.has_point(mouse_pos):
			image_preview_popup.hide()
			video_preview_player.stop()
			video_preview_popup.hide()
			globals.sprite_preview_cancelled = true
			sprite_preview_popup.hide())

	dropdown_list_2.mouse_exited.connect(func():
		var mouse_pos = get_viewport().get_mouse_position()
		var rect = Rect2(dropdown_list.position, dropdown_list.size)
		if not rect.has_point(mouse_pos):
			image_preview_popup.hide()
			video_preview_player.stop()
			video_preview_popup.hide()
			globals.sprite_preview_cancelled = true
			sprite_preview_popup.hide())

	update_conversation_selector(false)
	#/ No need to update Block selector: update_conversation_selector() calls it
	update_line_list()

	hide_line_data(false)

	#% Display profile selector at startup:
	landing_screen.display()

	#% Make control commands visible by default:
	$"UI/VBox/VSplit/PanelContainer/HBox/Commands/Control".visible = true


func _process(_delta: float) -> void:
	if variant_voice_player.playing and not variant_voice_player.stream_paused:
		var length = variant_voice_player.stream.get_length()
		if length > 0:
			variant_translation_volume_slider.value = variant_voice_player.get_playback_position() / length

	if translation_voice_player.playing and not translation_voice_player.stream_paused:
		var length = translation_voice_player.stream.get_length()
		if length > 0:
			translation_progress_slider.value = translation_voice_player.get_playback_position() / length


#?######################################################################################
#& POPULATE CONTEXT MENUS:
#?########################
#region
#* Populate the save context menu with options:
func populate_save_context_menu() -> void:
	save_context_menu.add_item("Save", 0)
	save_context_menu.add_item("Save As", 1)
	save_context_menu.add_item("Save Incremental", 2)
	save_context_menu.id_pressed.connect(_on_save_context_menu_pressed)
	save_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			save_context_menu.hide())


#* Populate the line context menu with options:
func populate_line_context_menu() -> void:
	line_context_menu.add_item("Copy", 0)
	line_context_menu.add_item("Cut", 1)
	line_context_menu.add_separator()
	line_context_menu.add_item("Paste Above", 2)
	line_context_menu.add_item("Paste Below", 3)
	line_context_menu.add_separator()
	line_context_menu.add_item("Duplicate", 4)
	line_context_menu.add_separator()
	line_context_menu.add_item("Delete", 5)
	line_context_menu.id_pressed.connect(_on_line_context_menu_pressed)
	line_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			favorites_context_menu.hide())


#* Populate the Conversation/Block sorting context menu with options:
func populate_sort_context_menu() -> void:
	sort_context_menu.add_item("Rename", 0)
	sort_context_menu.add_separator()
	sort_context_menu.add_item("Duplicate", 1)
	sort_context_menu.add_separator()
	sort_context_menu.add_item("Delete", 2)
	sort_context_menu.id_pressed.connect(_on_sort_context_menu_pressed)
	sort_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			favorites_context_menu.hide())

#* Populate the Conversation context menu with options:
func populate_conversation_context_menu() -> void:
	conversation_context_menu.add_item("Rename", 0)
	conversation_context_menu.add_separator()
	conversation_context_menu.add_item("Delete", 1)
	conversation_context_menu.id_pressed.connect(_on_conversation_context_menu_pressed)
	conversation_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			favorites_context_menu.hide())

#* Populate the Block context menu with options:
func populate_block_context_menu() -> void:
	block_context_menu.add_item("Rename", 0)
	block_context_menu.add_separator()
	block_context_menu.add_item("Delete", 1)
	block_context_menu.id_pressed.connect(_on_block_context_menu_pressed)
	block_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			favorites_context_menu.hide())


func populate_favorites_context_menu() -> void:
	favorites_context_menu.add_item("Add to Favorites", 0)
	favorites_context_menu.add_item("Remove from Favorites", 1)
	favorites_context_menu.id_pressed.connect(_on_favorites_context_menu_pressed)
	favorites_context_menu.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			favorites_context_menu.hide())

#endregion


#?######################################################################################
#& SCAN RESOURCES:
#?################
#region
func scan_project_resources() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	globals.project_resources.clear()
	globals.project_resources = {
		"*Portraits": {},
		"*Busts": {},
		"*Voice_Files": {},
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
		"BG_Layer_Nodes": {},
		"VN_Bust_Nodes": {},
	}

	#% Scan general data:
	for key in globals.custom_project_paths.keys():
		if not globals.project_resources.has(key):
			continue
		var folder_path = globals.project_path.path_join(globals.custom_project_paths[key])
		if not DirAccess.dir_exists_absolute(folder_path):
			continue

		if key.begins_with("*"):
			#% Character subfolders:
			_scan_character_folder(key, folder_path)
		else:
			#% General folder:
			_scan_general_folder(key, folder_path)

	#% Scan BG scenes for layer nodes:
	for scene_name in globals.project_resources["BG_Scenes"].keys():
		var scene_path = globals.project_resources["BG_Scenes"][scene_name]
		if scene_path is String:
			var layers = _scan_bg_scene(scene_path)
			globals.project_resources["BG_Layer_Nodes"][scene_name] = layers
			for layer in layers:
				if not layer in globals.project_resources["BG_Layer_Nodes"].get("All", []):
					if not globals.project_resources["BG_Layer_Nodes"].has("All"):
						globals.project_resources["BG_Layer_Nodes"]["All"] = []
					globals.project_resources["BG_Layer_Nodes"]["All"].append(layer)

	#% Scan VN scenes for bust nodes:
	for scene_name in globals.project_resources["VN_Scenes"].keys():
		var scene_path = globals.project_resources["VN_Scenes"][scene_name]
		if scene_path is String:
			var busts = _scan_vn_scene(scene_path)
			globals.project_resources["VN_Bust_Nodes"][scene_name] = busts
			for bust in busts:
				if not bust in globals.project_resources["VN_Bust_Nodes"].get("All", []):
					if not globals.project_resources["VN_Bust_Nodes"].has("All"):
						globals.project_resources["VN_Bust_Nodes"]["All"] = []
					globals.project_resources["VN_Bust_Nodes"]["All"].append(bust)

	#% Sort all resources alphabetically:
	for key in globals.project_resources.keys():
		var resource = globals.project_resources[key]
		if resource is Dictionary:
			var sorted = {}
			var inner_keys = resource.keys()
			inner_keys.sort()
			for inner_key in inner_keys:
				var value = resource[inner_key]
				if value is Array:
					value.sort()
				sorted[inner_key] = value
			globals.project_resources[key] = sorted
		elif resource is Array:
			resource.sort()

	#print(globals.project_resources)
	#print("custom_project_paths: ", globals.custom_project_paths)
	#print("project_path: ", globals.project_path)

#* Scan a folder with character subfolders (Portraits, Busts, Voices):
func _scan_character_folder(key: String, folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var char_name = dir.get_next()
	while char_name != "":
		if dir.current_is_dir():
			var char_path = folder_path.path_join(char_name)
			globals.project_resources[key][char_name] = {}
			_scan_folder_recursive(globals.project_resources[key][char_name], char_path)
		char_name = dir.get_next()
	dir.list_dir_end()


#* Scan a general folder recursively:
func _scan_general_folder(key: String, folder_path: String) -> void:
	_scan_folder_recursive(globals.project_resources[key], folder_path)


#* Recursively scan a folder and populate a dictionary with file paths:
func _scan_folder_recursive(target: Dictionary, folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".uid") or fname.ends_with(".import"):
			fname = dir.get_next()
			continue
		var full_path = folder_path.path_join(fname)
		if dir.current_is_dir():
			target[fname] = {}
			_scan_folder_recursive(target[fname], full_path)
		else:
			target[fname] = full_path
		fname = dir.get_next()
	dir.list_dir_end()


#* Read a .tscn file to find its script:
#% Returns the path, in the project folder, of the script attached to the root node.
func _get_script_path_from_scene(scene_content: String) -> String:
	#% Find script ext_resource id:
	var ext_regex := RegEx.new()
	ext_regex.compile('\\[ext_resource type="Script"[^\\]]*path="([^"]+)"[^\\]]*id="([^"]+)"\\]')
	var ext_result = ext_regex.search(scene_content)
	if ext_result == null:
		#% Try alternate id order:
		ext_regex.compile('\\[ext_resource type="Script"[^\\]]*id="([^"]+)"[^\\]]*path="([^"]+)"\\]')
		ext_result = ext_regex.search(scene_content)
		if ext_result == null:
			return ""
		return ext_result.get_string(2)
	return ext_result.get_string(1)


#* BG/VN Scenes - Get the name of the layer/bust container node:
func _get_container_node_name(script_path: String, var_name: String) -> String:
	var fs_path = script_path.replace("res://", globals.project_path)
	if not FileAccess.file_exists(fs_path):
		return ""
	var file = FileAccess.open(fs_path, FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	file.close()
	var regex := RegEx.new()
	regex.compile('@onready var ' + var_name + '\\s*=\\s*get_node\\("([^"]+)"\\)')
	var result = regex.search(content)
	if result:
		return result.get_string(1)
	return ""


#* Find and list the names of layer nodes in BG scenes:
func _scan_bg_scene(scene_path: String) -> Array:
	var nodes: Array = []
	if not FileAccess.file_exists(scene_path):
		return nodes

	var file = FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return nodes
	var content = file.get_as_text()
	file.close()

	#% Get script path from scene:
	var script_path = _get_script_path_from_scene(content)
	if script_path == "":
		return nodes

	#% Get container node name from script:
	var container_name = _get_container_node_name(script_path, "bg_container")
	if container_name == "":
		return nodes

	#% Find direct children of container in scene:
	var name_regex := RegEx.new()
	name_regex.compile('name="([^"]+)"')
	for line in content.split("\n"):
		if line.begins_with("[node") and ('parent="' + container_name + '"') in line:
			var result = name_regex.search(line)
			if result:
				nodes.append(result.get_string(1))

	return nodes


#* Find and list the names of bust nodes in VN scenes:
func _scan_vn_scene(scene_path: String) -> Array:
	var nodes: Array = []
	if not FileAccess.file_exists(scene_path):
		return nodes

	var file = FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return nodes
	var content = file.get_as_text()
	file.close()

	var script_path = _get_script_path_from_scene(content)
	if script_path == "":
		return nodes

	var container_name = _get_container_node_name(script_path, "busts_container")
	if container_name == "":
		return nodes

	var name_regex := RegEx.new()
	name_regex.compile('name="([^"]+)"')
	for line in content.split("\n"):
		if line.begins_with("[node") and ('parent="' + container_name + '"') in line:
			var result = name_regex.search(line)
			if result:
				nodes.append(result.get_string(1))

	return nodes


#* Scan project scripts to collect data:
func scan_project_scripts() -> void:
	#% Clear script-based resources:
	globals.project_resources["Actors"] = []
	globals.project_resources["Roles"] = []
	globals.project_resources["Flags"] = []
	globals.project_resources["Dispositions"] = []

	#% Scan Candy_Symbols:
	var symbols_path = globals.project_scripts.get("Candy_Symbols", "")
	if symbols_path != "" and FileAccess.file_exists(symbols_path):
		_import_symbols_from_script(symbols_path)

	#% Scan Actor_References:
	_scan_script_variable("Actors", globals.project_scripts.get("Actor_References", []))

	#% Scan Role_References:
	_scan_script_variable("Roles", globals.project_scripts.get("Role_References", []))

	#% Scan Flags:
	_scan_script_variable("Flags", globals.project_scripts.get("Flags", []))

	#% Scan Disposition_List:
	_scan_script_variable("Dispositions", globals.project_scripts.get("Disposition_List", []))


#* Import symbol variables from a script file:
func _import_symbols_from_script(script_path: String) -> void:
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	file.close()

	var symbol_vars = {
		"singleton_symbol": "singleton_symbol",
		"node_symbol": "node_symbol",
		"vardict_symbol": "vardict_symbol",
		"super_singleton_symbol": "super_singleton_symbol",
		"super_node_symbol": "super_node_symbol",
		"super_vardict_symbol": "super_vardict_symbol",
		"role_symbol": "role_symbol",
		"text_var_symbol_start": "text_var_symbol_start",
		"text_var_symbol_end": "text_var_symbol_end",
		"substitution_symbol": "substitution_symbol",
		"separator_symbol": "separator_symbol",
	}

	for var_name in symbol_vars.keys():
		var regex := RegEx.new()
		regex.compile('var\\s+' + var_name + '\\s*=\\s*"([^"]*)"')
		var result = regex.search(content)
		if result:
			globals.set(symbol_vars[var_name], result.get_string(1))


#* Scan a script variable and collect keys or items into project_resources:
func _scan_script_variable(resource_key: String, script_entry: Array) -> void:
	if script_entry.size() < 2:
		return

	var script_path: String = script_entry[0]
	var var_name: String = script_entry[1]

	if script_path == "" or var_name == "":
		return

	if not FileAccess.file_exists(script_path):
		return

	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	file.close()

	#@ Find the variable definition:
	var regex_dict := RegEx.new()
	regex_dict.compile("var\\s+" + var_name + "\\s*=\\s*\\{([\\s\\S]*)\\}")
	var regex_array := RegEx.new()
	regex_array.compile("var\\s+" + var_name + "\\s*=\\s*\\[([\\s\\S]*)\\]")

	var result_dict = regex_dict.search(content)
	var result_array = regex_array.search(content)
	var data_str := ""

	if result_dict:
		data_str = "{" + result_dict.get_string(1) + "}"
	elif result_array:
		data_str = "[" + result_array.get_string(1) + "]"
	else:
		return

	#@ Strip comments:
	var clean_lines := []
	for line in data_str.split("\n"):
		var ascii_hash := "\u0023"
		var cut = line.split(ascii_hash + "/")[0].split(ascii_hash)[0].split("//")[0]
		clean_lines.append(cut)
	data_str = "\n".join(clean_lines)

	#@ Sanitize:
	data_str = data_str.replace("\r", "")
	data_str = data_str.replace("\t", "")
	data_str = data_str.replace(",\n}", "\n}")
	data_str = data_str.replace(",}", "}")
	data_str = data_str.replace(",]", "]")

	#@ Balance braces:
	if data_str.count("{") > data_str.count("}"):
		data_str += "}"
	if data_str.count("[") > data_str.count("]"):
		data_str += "]"

	#@ Parse with Expression:
	var expr := Expression.new()
	if expr.parse(data_str, []) != OK:
		push_error("_scan_script_variable: Failed to parse: " + var_name)
		return

	var eval_result = expr.execute()

	#@ Collect top-level keys or items:
	if eval_result is Dictionary:
		for key in eval_result.keys():
			if not str(key) in globals.project_resources[resource_key]:
				globals.project_resources[resource_key].append(str(key))
	elif eval_result is Array:
		for item in eval_result:
			if not str(item) in globals.project_resources[resource_key]:
				globals.project_resources[resource_key].append(str(item))

#endregion


#?######################################################################################
#& TOP BAR:
#?#########
#region
func _on_main_menu_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	main_menu.clear()
	main_menu.add_item("New Dialogue", 0)
	main_menu.add_item("Profiles", 1)
	main_menu.add_item("Convert Dialogues", 2)
	main_menu.add_item("Convert Saves", 3)
	main_menu.add_item("Convert Presets", 4)
	var btn_pos = main_menu_button.get_screen_position()
	main_menu.position = Vector2i(int(btn_pos.x), int(btn_pos.y + main_menu_button.size.y))
	main_menu.popup()


func _on_main_menu_id_pressed(id: int) -> void:
	match id:

		0: #% New dialogue:
			prompt_menu.setup("New Dialogue")

		1: #% Open profiles menu (landing screen): 
			prompt_menu.setup("Change Profile")

		2: #% Convert Dialogues:
			globals.editor_state = "Converter"
			convert_dialogue.setup("Dialogue")

		3: #% Convert Saves:
			globals.editor_state = "Converter"
			convert_dialogue.setup("Save")

		4: #% Convert Presets:
			globals.editor_state = "Converter"
			convert_dialogue.setup("Presets")


#* New dialogue:
func new_dialogue() -> void:
	globals.current_save = ""
	globals.dialogue = {
		"Conversation_1": {
			"Block_1": {
				"Text":[
					{"§Comment": {
						"Color": "",
						"Comment": "",
					}},
				]
			},
		}
	}
	globals.current_conversation = "Conversation_1"
	globals.current_block = "Block_1"
	globals.current_line = 0
	globals.current_line_type = "§Comment"
	globals.current_choice_category = ""
	globals.current_choice_item = ""
	globals.current_choice_timer = ""
	globals.undo_stack = []
	globals.current_undo_step = -1
	globals.original_data = ""
	update_conversation_selector(false)
	var source = _get_line_source()
	if source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
		var lines = source[globals.current_conversation][globals.current_block]["Text"]
		if lines.size() > 0:
			globals.current_line = 0
			globals.current_line_type = lines[0].keys()[0]
			_show_line_editor()
	save_undo_step()


#* Open profiles menu:
func change_profile() -> void:
	new_dialogue()
	auto_save_timer.stop()
	globals.user_presets = {
		"USER PRESETS": {
			"[Category_1] User_Preset_1": {
				"Text": [
					{"§Comment": {
						"Color": "",
						"Comment": "",
					}},
				]
			}
		}
	}
	globals.profile_presets = {
		"PROFILE PRESETS": {
			"[Category_1] Profile_Preset_1": {
				"Text": [
					{"§Comment": {
						"Color": "",
						"Comment": "",
					}},
				]
			}
		}
	}
	globals.user_inserts = {}
	globals.profile_inserts = {}
	landing_screen.display()




#* Open Export Menu:
func _on_export_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	globals.editor_state = "Export Menu"
	export_menu.spawn_convo_tree()
	export_menu.visible = true


#* Open Import Menu:
func _on_import_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	globals.editor_state = "Import Menu"
	import_menu.spawn_convo_tree()
	import_menu.visible = true


#* Toggle between lines or dialogue sorting:
func _on_sort_dialogue_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if sort_dialogue == true:
		sort_dialogue = false
		line_tree.select_mode = Tree.SELECT_MULTI
		line_tree.add_theme_constant_override("item_margin", 0)

	elif sort_dialogue == false:
		sort_dialogue = true
		line_tree.select_mode = Tree.SELECT_SINGLE
		line_tree.add_theme_constant_override("item_margin", 4)

	globals.current_line = -1
	selected_lines = []
	update_line_list()


#* Open Settings Menu:
func _on_settings_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	settings_menu.setup()
	settings_menu.visible = true
	globals.editor_state = "Settings"


#* Open About Menu:
func _on_about_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	about_menu.visible = true
	globals.editor_state = "About"


#* Undo:
func _on_undo_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	undo()


#* Redo:
func _on_redo_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	redo()
#endregion


#?######################################################################################
#& LINE CONTEXT MENU:
#?###################
#region
#* Select line_context_menu action:
func _on_line_context_menu_pressed(id: int) -> void:
	match id:
		0: _lines_copy()
		1: _lines_cut()
		2: _lines_paste_above()
		3: _lines_paste_below()
		4: _lines_duplicate()
		5: _lines_delete()


#* Get the current block's lines array:
func _get_current_lines() -> Array:
	var target: Dictionary = {}
	if globals.current_conversation == "USER PRESETS":
		target = globals.user_presets
	elif globals.current_conversation == "PROFILE PRESETS":
		target = globals.profile_presets
	else:
		target = globals.dialogue
	return target[globals.current_conversation][globals.current_block]["Text"]


#* Copy selected lines to clipboard:
func _lines_copy() -> void:
	clipboard.clear()
	var lines = _get_current_lines()
	var sorted = selected_lines.duplicate()
	sorted.sort()
	for i in sorted:
		clipboard.append(lines[i].duplicate(true))


#* Cut selected lines to clipboard:
func _lines_cut() -> void:
	_lines_copy()
	_lines_delete()


#* Paste above selected lines:
func _lines_paste_above() -> void:
	if clipboard.is_empty():
		return
	var lines = _get_current_lines()
	var sorted = selected_lines.duplicate()
	sorted.sort()
	var offset = 0
	for i in sorted:
		for j in range(clipboard.size()):
			lines.insert(i + offset, clipboard[j].duplicate(true))
			offset += 1
	update_line_list()
	save_undo_step()

#* Paste below selected lines:
func _lines_paste_below() -> void:
	if clipboard.is_empty():
		return
	var lines = _get_current_lines()
	var sorted = selected_lines.duplicate()
	sorted.sort()
	var offset = 0
	for i in sorted:
		for j in range(clipboard.size()):
			lines.insert(i + 1 + offset, clipboard[j].duplicate(true))
			offset += 1
	update_line_list()
	save_undo_step()

#* Duplicate selected lines (copy immediately below each):
func _lines_duplicate() -> void:
	var lines = _get_current_lines()
	var sorted = selected_lines.duplicate()
	sorted.sort()
	var offset = 0
	for i in sorted:
		lines.insert(i + 1 + offset, lines[i + offset].duplicate(true))
		offset += 1
	update_line_list()
	save_undo_step()

#* Delete selected lines:
func _lines_delete() -> void:
	var lines = _get_current_lines()
	var sorted = selected_lines.duplicate()
	sorted.sort()
	sorted.reverse()
	for i in sorted:
		lines.remove_at(i)
	selected_lines.clear()
	globals.current_line = -1
	update_line_list()
	hide_line_data(false)
	save_undo_step()


func _on_sort_context_menu_pressed(id: int) -> void:
	if sort_context_target == null:
		return
	var is_block = sort_context_target.get_parent() != line_tree.get_root()
	var entry_name = sort_context_target.get_text(0)
	match id:
		0:
			if is_block:
				prompt_menu.setup("Rename Block")
			else:
				prompt_menu.setup("Rename Conversation")
		1:
			if is_block:
				_duplicate_block(entry_name)
			else:
				_duplicate_conversation(entry_name)
		2:
			if is_block:
				_delete_block_from_sort(entry_name)
			else:
				_delete_conversation_from_sort(entry_name)


#* Duplicate a Conversation in the tree:
func _duplicate_conversation(conv_name: String) -> void:
	var keys = globals.dialogue.keys()
	var values = globals.dialogue.values()
	var idx = keys.find(conv_name)
	var new_name = _resolve_conversation_name_conflict(conv_name)
	keys.insert(idx + 1, new_name)
	values.insert(idx + 1, globals.dialogue[conv_name].duplicate(true))
	globals.dialogue.clear()
	for i in range(keys.size()):
		globals.dialogue[keys[i]] = values[i]
	update_line_list()
	save_undo_step()


#* Duplicate a Block in the tree:
func _duplicate_block(block_name: String) -> void:
	var conv_name = sort_context_target.get_parent().get_text(0)
	var keys = globals.dialogue[conv_name].keys()
	var values = globals.dialogue[conv_name].values()
	var idx = keys.find(block_name)
	var new_name = _resolve_block_name_conflict(block_name, conv_name)
	keys.insert(idx + 1, new_name)
	values.insert(idx + 1, globals.dialogue[conv_name][block_name].duplicate(true))
	globals.dialogue[conv_name].clear()
	for i in range(keys.size()):
		globals.dialogue[conv_name][keys[i]] = values[i]
	update_line_list()
	save_undo_step()

#* Delete a Conversation in the tree:
func _delete_conversation_from_sort(conv_name: String) -> void:
	globals.dialogue.erase(conv_name)
	if globals.current_conversation == conv_name:
		globals.current_conversation = ""
		globals.current_block = ""
	update_conversation_selector(globals.current_conversation != "")
	update_line_list()
	save_undo_step()

#* Delete a Block in the tree:
func _delete_block_from_sort(block_name: String) -> void:
	var conv_name = sort_context_target.get_parent().get_text(0)
	globals.dialogue[conv_name].erase(block_name)
	if globals.current_conversation == conv_name and globals.current_block == block_name:
		globals.current_block = ""
	update_block_selector(globals.current_block != "")
	update_line_list()
	save_undo_step()

#* Automatically resolve Conversation name conflict:
func _resolve_conversation_name_conflict(conversation_name: String) -> String:
	if not globals.dialogue.has(conversation_name):
		return conversation_name
	var regex = RegEx.new()
	regex.compile("^(.+)_\\((\\d+)\\)$")
	var result = regex.search(conversation_name)
	var base_name: String
	var counter: int
	if result:
		base_name = result.get_string(1)
		counter = int(result.get_string(2)) + 1
	else:
		base_name = conversation_name
		counter = 1
	var candidate = "%s_(%d)" % [base_name, counter]
	while globals.dialogue.has(candidate):
		counter += 1
		candidate = "%s_(%d)" % [base_name, counter]
	return candidate

#* Automatically resolve Block name conflict:
func _resolve_block_name_conflict(block_name: String, conv: String) -> String:
	var dialogue = globals.dialogue
	if not dialogue[conv].has(block_name):
		return block_name

	#% Check if block name already ends with _(N):
	var regex = RegEx.new()
	regex.compile("^(.+)_\\((\\d+)\\)$")
	var result = regex.search(block_name)
	var base_name: String
	var counter: int

	if result:
		base_name = result.get_string(1)
		counter = int(result.get_string(2)) + 1
	else:
		base_name = block_name
		counter = 1

	var candidate = "%s_(%d)" % [base_name, counter]
	while dialogue[conv].has(candidate):
		counter += 1
		candidate = "%s_(%d)" % [base_name, counter]

	return candidate

#endregion


#?######################################################################################
#& CONVERSATION/BLOCK HANDLING:
#?#############################
#region
#* Click to create new Conversation:
func _on_new_conversation_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.current_conversation == "USER_PRESETS":
		export_user_presets()
	elif globals.current_conversation == "PROFILE_PRESETS":
		export_profile_presets()
	prompt_menu.setup("New Conversation")


#* Click to create new Block:
func _on_new_block_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.current_conversation == "USER_PRESETS":
		export_user_presets()
	elif globals.current_conversation == "PROFILE_PRESETS":
		export_profile_presets()
	prompt_menu.setup("New Block")


#* Create a new conversation:
func create_new_conversation(conv_name: String) -> void:
	globals.dialogue[conv_name] = {globals.block_default_name: {"Text": [{"§Comment": globals.line_templates["§Comment"].duplicate(true)}]}}
	globals.current_conversation = conv_name
	globals.current_block = globals.block_default_name
	update_conversation_selector(true)
	update_block_selector(false)


#* Create a new block:
func create_new_block(block_name: String) -> void:
	if globals.current_conversation == "":
		return
	elif globals.current_conversation == "USER PRESETS":
		globals.user_presets[globals.current_conversation][block_name] = {"Text": [{"§Comment": globals.line_templates["§Comment"].duplicate(true)}]}
	elif globals.current_conversation == "PROFILE PRESETS":
		globals.profile_presets[globals.current_conversation][block_name] = {"Text": [{"§Comment": globals.line_templates["§Comment"].duplicate(true)}]}
	else:
		globals.dialogue[globals.current_conversation][block_name] = {"Text": [{"§Comment": globals.line_templates["§Comment"].duplicate(true)}]}
	globals.current_block = block_name
	update_block_selector(true)


#* Select Conversation:
func _on_conversation_selected(index: int) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	print(globals.current_conversation)
	if globals.current_conversation == "USER PRESETS":
		export_user_presets()
	elif globals.current_conversation == "PROFILE PRESETS":
		export_profile_presets()

	globals.current_conversation = conversation_selector.get_item_text(index)

	#% Update the Block selector and select the first Block:
	update_block_selector(false)
	populate_preset_buttons()


#* Select Block:
func _on_block_selected(index: int) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.current_conversation == "USER PRESETS":
		export_user_presets()
	elif globals.current_conversation == "PROFILE PRESETS":
		export_profile_presets()

	globals.current_block = block_selector.get_item_text(index)
	globals.current_line = -1
	selected_lines.clear()
	line_tree.deselect_all()
	populate_preset_buttons()
	_reset_voice(true, true)
	update_line_list()


#* Update the conversation selector to list all conversations and select globals.current_conversation:
func update_conversation_selector(keep_current: bool) -> void:
	#@ Clear the list:
	conversation_selector.clear()

	#@ Populate the list:
	#% Add presets first:
	conversation_selector.add_item("USER PRESETS")
	conversation_selector.add_item("PROFILE PRESETS")

	#% Add dialogue Conversations:
	for conversation_name in globals.dialogue.keys():
		if conversation_name == "USER PRESETS" or conversation_name == "PROFILE PRESETS":
			continue
		conversation_selector.add_item(conversation_name)

	#@ Only refresh the list, unless the current Conversation is missing:
	#% This keeps the current Conversation.
	if keep_current == true and globals.dialogue.has(globals.current_conversation):
		for i in range(conversation_selector.item_count):
			if conversation_selector.get_item_text(i) == globals.current_conversation:
				conversation_selector.select(i)
				break

	#@ Select the first Conversation in the list:
	#% This selects a different Conversation.
	else:
		conversation_selector.select(2)
		globals.current_conversation = conversation_selector.get_item_text(2)

		#@ Update the Block selector and select the first Block:
		#% Required because we're switching to a different Conversation.
		update_block_selector(false)


#* Update the block selector to list all blocks and select globals.current_block:
func update_block_selector(keep_current: bool) -> void:
	#@ Clear selection state:
	globals.current_line = -1
	selected_lines.clear()
	line_tree.deselect_all()

	#@ Clear the list:
	block_selector.clear()

	#@ Populate the list:
	#% Get presets:
	var source: Dictionary = {}
	if globals.current_conversation == "USER PRESETS":
		source = globals.user_presets.get("USER PRESETS", {})
	elif globals.current_conversation == "PROFILE PRESETS":
		source = globals.profile_presets.get("PROFILE PRESETS", {})

	#% Get actual dialogue Blocks:
	else:
		if globals.current_conversation == "" or not globals.dialogue.has(globals.current_conversation):
			return
		source = globals.dialogue[globals.current_conversation]
	for block_name in source.keys():
		block_selector.add_item(block_name)

	#@ Only refresh the list, unless the current Block is missing:
	var source_has_block: bool = false
	if globals.current_conversation == "USER PRESETS":
		source_has_block = globals.user_presets.get("USER PRESETS", {}).has(globals.current_block)
	elif globals.current_conversation == "PROFILE PRESETS":
		source_has_block = globals.profile_presets.get("PROFILE PRESETS", {}).has(globals.current_block)
	else:
		source_has_block = globals.dialogue.has(globals.current_conversation) and globals.dialogue[globals.current_conversation].has(globals.current_block)

	if keep_current and source_has_block:
		for i in range(block_selector.item_count):
			if block_selector.get_item_text(i) == globals.current_block:
				block_selector.select(i)
				break
	else:
		block_selector.select(0)
		globals.current_block = block_selector.get_item_text(0)

	_reset_voice(true, true)
	update_line_list()


#* Right-click Conversation selector:
func _on_conversation_context_menu_pressed(id: int) -> void:
	match id:
		0: prompt_menu.setup("Rename Conversation")
		1: _delete_conversation()

#* Right-click Block selector:
func _on_block_context_menu_pressed(id: int) -> void:
	match id:
		0: prompt_menu.setup("Rename Block")
		1: _delete_block()


#* Rename the current conversation:
func rename_conversation(new_name: String) -> void:
	if globals.current_conversation == "USER PRESETS" or globals.current_conversation == "PROFILE PRESETS":
		return
	var blocks = globals.dialogue[globals.current_conversation]
	globals.dialogue.erase(globals.current_conversation)
	globals.dialogue[new_name] = blocks
	globals.current_conversation = new_name
	update_conversation_selector(true)

#* Rename the current block:
func rename_block(new_name: String) -> void:
	if globals.current_conversation == "USER PRESETS":
		var block = globals.user_presets["USER PRESETS"][globals.current_block]
		globals.user_presets["USER PRESETS"].erase(globals.current_block)
		globals.user_presets["USER PRESETS"][new_name] = block
		export_user_presets()
	elif globals.current_conversation == "PROFILE PRESETS":
		var block = globals.profile_presets["PROFILE PRESETS"][globals.current_block]
		globals.profile_presets["PROFILE PRESETS"].erase(globals.current_block)
		globals.profile_presets["PROFILE PRESETS"][new_name] = block
		export_profile_presets()
	else:
		var lines = globals.dialogue[globals.current_conversation][globals.current_block]["Text"]
		globals.dialogue[globals.current_conversation].erase(globals.current_block)
		globals.dialogue[globals.current_conversation][new_name] = {"Text": lines}
	globals.current_block = new_name
	update_block_selector(true)


#* Delete Conversation:
func _delete_conversation() -> void:
	if globals.current_conversation == "USER PRESETS" or globals.current_conversation == "PROFILE PRESETS":
		return
	globals.dialogue.erase(globals.current_conversation)
	globals.current_conversation = ""
	globals.current_block = ""
	update_conversation_selector(false)

#* Delete Block:
func _delete_block() -> void:
	if globals.current_conversation == "USER PRESETS":
		globals.user_presets["USER PRESETS"].erase(globals.current_block)
		export_user_presets()
	elif globals.current_conversation == "PROFILE PRESETS":
		globals.profile_presets["PROFILE PRESETS"].erase(globals.current_block)
		export_profile_presets()
	else:
		globals.dialogue[globals.current_conversation].erase(globals.current_block)
	globals.current_block = ""
	update_block_selector(false)

#endregion


#?######################################################################################
#& LINE TREE:
#?###########
#region
#* Update the line list in the Tree node:
func update_line_list() -> void:
	line_tree.clear()
	line_tree.set_column_titles_visible(false)
	var root = line_tree.create_item()
	line_tree.hide_root = true

	#% Display conversations and blocks for reordering:
	if sort_dialogue == true:
		for conv_name in globals.dialogue.keys():
			var conv_item = line_tree.create_item(root)
			conv_item.set_text(0, conv_name)
			for block_name in globals.dialogue[conv_name].keys():
				var block_item = line_tree.create_item(conv_item)
				block_item.set_text(0, block_name)
		return

	#% Determine source:
	var source = _get_line_source()

	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return

	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	for i in range(lines.size()):
		var line = lines[i]
		var item = line_tree.create_item(root)
		item.set_text(0, _get_line_display_text(line, i))
		item.set_metadata(0, i)
		var key = line.keys()[0]
		if key == "§Comment":
			var comment_color = str_to_var(str(line[key].get("Color", "")))
			if comment_color is Color:
				item.set_custom_color(0, comment_color)
			elif globals.line_colors.has(key):
				item.set_custom_color(0, globals.line_colors[key]["Text"])
		elif globals.line_colors.has(key):
			var colors = globals.line_colors[key]
			item.set_custom_bg_color(0, colors["BG"])
			item.set_custom_color(0, colors["Text"])
		else:
			item.clear_custom_bg_color(0)
			item.clear_custom_color(0)

	#% Reselect previously selected lines after rebuild:
	var line_item = line_tree.get_root().get_first_child()
	while line_item:
		var idx = line_item.get_metadata(0)
		if idx in selected_lines:
			line_item.select(0)
		line_item = line_item.get_next()


#* Get display text for a line:
func _get_line_display_text(line: Dictionary, index: int) -> String:
	var key = line.keys()[0]
	var data = line[key]

	#@ Display 'meta' field if enabled:
	if globals.line_tree_meta == true:
		var meta = data.get("Meta", "")
		return str(index) + " | " + key + ": " + meta

	#@ Otherwise, display regular data:
	match key:
		"Spoken Line":
			#% Basic data:
			var speaker = data.get("Reference", "")
			var disposition = data.get("Disposition", "")

			#% Get the text of the current variant:
			var text = ""
			for entry in data.get("Variants", []):
				if entry.keys()[0] == globals.current_variant:
					text = strip_bbcode(entry[globals.current_variant].get("Text", ""))
					break

			var result = str(index) + " | " + speaker + ": " + text

			if disposition != null:
				result = str(index) + " | " + "(" + disposition + ") " + speaker + ": " + text

			#% Full text to display:
			return result

		"§Comment":
			#% Basic data:
			var comment = data.get("Comment", "")
			return str(index) + " | " + key + ": " + comment

		"§If", "§Elif", "§For", "§While":
			var condition = data.get("Condition", "")
			var effect_type = data.get("Type", "")
			var effect_text = ""
			if effect_type != "" and data["Commands"].has(effect_type):
				var effect_line = {effect_type: data["Commands"][effect_type]}
				effect_text = _get_line_display_text(effect_line, index)
				effect_text = effect_text.trim_prefix(str(index) + " | ")
			return str(index) + " | " + key + ": " + condition + " | " + effect_text

		"§Else":
			var effect_type = data.get("Type", "")
			var effect_text = ""
			if effect_type != "" and data["Commands"].has(effect_type):
				var effect_line = {effect_type: data["Commands"][effect_type]}
				effect_text = _get_line_display_text(effect_line, index)
				effect_text = effect_text.trim_prefix(str(index) + " | ")
			return str(index) + " | " + key + ": " + effect_text

		"§Jump", "§Bridge":
			var conversation = data.get("Conversation", "")
			var block = data.get("Block", "")
			var transition_line = data.get("Line", "")
			var conv_display = conversation if conversation != "" else "this Conversation"
			var block_display = block if block != "" else "this Block"
			var result = str(index) + " | " + key + ": " + conv_display + " → " + block_display
			if transition_line != "":
				result += " → " + transition_line
			return result

		"§LM":
			var reference = data.get("Reference", "")
			return str(index) + " | " + key + ": " + reference

		"§Return":
			return str(index) + " | " + key + ": " + "---------------------------------------------------------------------------"

		"§End":
			return str(index) + " | " + key + ": " + "============================================="

		"§Call":
			var await_flag = data.get("Await", "1")
			var function = data.get("Function", "")
			var arguments = data.get("Arguments", "")
			var variable = data.get("Variable", "")
			var result = str(index) + " | " + key + ": "
			if await_flag == "1":
				result += "*await* "
			if variable != "":
				result += variable + " = "
			result += function + "(" + arguments + ")"
			return result

		"§Emit":
			var signal_name = data.get("Signal", "")
			var arguments = data.get("Arguments", "")
			return str(index) + " | " + key + ": " + signal_name + "(" + arguments + ")"

		"§Await":
			var signal_name = data.get("Signal", "")
			var variable = data.get("Variable", "")
			var result = str(index) + " | " + key + ": "
			if variable != "":
				result += variable + " = "
			result += signal_name + "()"
			return result

		"§Set":
			var variable = data.get("Variable", "")
			var operator = data.get("Operator", "")
			var expression = data.get("Expression", "")
			return str(index) + " | " + key + ": " + variable + " " + operator + " [" + expression + "]"

		"§Flag":
			var flag = data.get("Flag", "")
			var operator = data.get("Operator", "")
			var expression = data.get("Expression", "")
			return str(index) + " | " + key + ": " + flag + " " + operator + " [" + expression + "]"

		"§Role":
			var role = data.get("Role", "")
			var reference = data.get("Reference", "")
			return str(index) + " | " + key + ": " + role + " → " + reference

		"§Name":
			var new_name = data.get("Name", "")
			var reference = data.get("Reference", "")
			var actor_key = data.get("Actor_Key", "")
			if actor_key == "":
				actor_key = "Display Name"
			return str(index) + " | " + key + ": " + "[" + actor_key + "]" + reference + " → " + new_name

		"§Disposition":
			var disposition = data.get("Disposition", "")
			var reference = data.get("Reference", "")
			return str(index) + " | " + key + ": " + reference + " → " + disposition

		"§Export":
			var path = data.get("Path", "")
			var file = data.get("File", "")
			var format = data.get("Format", "")
			var full_file = file
			if format != "" and not file.ends_with(format):
				full_file += format
			return str(index) + " | " + key + ": " + path + full_file

		"§Import":
			var path = data.get("Path", "")
			var file = data.get("File", "")
			var format = data.get("Format", "")
			var full_file = file
			if format != "" and not file.ends_with(format):
				full_file += format
			return str(index) + " | " + key + ": " + path + full_file

		"§Mouse":
			var mode = data.get("Mouse Mode", "")
			return str(index) + " | " + key + ": " + mode

		"§Input":
			var meta = data.get("Meta", "")
			return str(index) + " | " + key + ": " + meta

		"§Choice_List":
			var reference = data.get("Reference", "")
			return str(index) + " | " + key + ": " + reference

		"§Choice_Status":
			var menu_mode = data.get("Menu Mode", "")
			var category_mode = data.get("Category Mode", "")
			var choice_mode = data.get("Choice Mode", "")
			var enable = data.get("Enable", "").strip_edges()
			var activate = data.get("Activate", "").strip_edges()
			var show_choice = data.get("Show", "").strip_edges()
			var label = data.get("Label", "").strip_edges()
			var tooltip = data.get("Tooltip", "").strip_edges()

			var status_string = ""
			if enable == "":
				enable = "-"
			if activate == "":
				activate = "-"
			if show_choice == "":
				show_choice = "-"
			if enable != "-" and activate != "-" and show_choice != "-":
				status_string = " [ " + enable + " / " + activate + " / " + show_choice + " ]"

			var label_string = ""
			if label != "":
				label_string = " [ LABEL ]"

			var tooltip_string = ""
			if tooltip != "":
				tooltip_string = " [ TOOLTIP ]"

			return str(index) + " | " + key + ": " + "{" + menu_mode + " ¦ " + category_mode + " ¦ " + choice_mode + "}" + status_string + label_string + tooltip_string

		"§Timer_Status":
			var menu_mode = data.get("Menu Mode", "")
			var timer_mode = data.get("Timer Mode", "")
			var time = data.get("Time", "")
			var loop = data.get("Loop", "")
			var status = data.get("Status", "")
			var node = data.get("Timer Node", "")

			var time_string = ""
			if time != "":
				time_string = " Time: " + time

			var loop_string = ""
			if loop != "":
				if time_string == "":
					loop_string = " / Loops: " + loop
				else:
					loop_string = " Loops: " + loop

			var status_string = ""
			if status != "" or status != "-":
				status_string = " [" + status + "]"

			var node_string = " (" + node + ")"

			return str(index) + " | " + key + ": " + "{" + menu_mode + " ¦ " + timer_mode + "}" + time_string + loop_string + status_string + node_string

		"§BG_Scene":
			var scene = data.get("Scene", "")
			return str(index) + " | " + key + ": " + scene

		"§BG":
			var layers = data.get("Layers", "")
			var file = data.get("File", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + layers + " → " + file + " (" + loop + ") | Wait: " + wait + " + " + time

		"§BG_Stop":
			var layers = data.get("Layers", "")
			return str(index) + " | " + key + ": " + layers

		"§BG_Wait":
			var layers = data.get("Layers", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + layers + " | Wait: " + wait + " + " + time

		"§BG_Remove":
			var layers = data.get("Layers", "")
			return str(index) + " | " + key + ": " + layers

		"§BG_Mirror":
			var layers = data.get("Layers", "")
			var axis = data.get("Axis", "")
			return str(index) + " | " + key + ": " + layers + " → " + axis

		"§BG_Effect":
			var layers = data.get("Layers", "")
			var effect = data.get("Effect", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + layers + " ▶ " + effect + " (" + loop + ") | Wait: " + wait + " + " + time

		"§BG_Effect_Stop":
			var layers = data.get("Layers", "")
			var effect = data.get("Effect", "")
			return str(index) + " | " + key + ": " + layers + " ⏹ " + effect

		"§BG_Effect_Wait":
			var layers = data.get("Layers", "")
			var effect = data.get("Effect", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + layers + " - " + effect + " | Wait: " + wait + " + " + time

		"§Effect":
			var node = data.get("Node", "")
			var animation = data.get("Animation", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + node + " ▶ " + animation + " (" + loop + ") | Wait: " + wait + " + " + time

		"§Effect_Stop":
			var node = data.get("Node", "")
			return str(index) + " | " + key + ": " + node

		"§Effect_Wait":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + node + " | Wait: " + wait + " + " + time

		"§Wait":
			var time = data.get("Time", "")
			return str(index) + " | " + key + ": " + time

		"§Hide":
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			return str(index) + " | " + key + ": " + " / ".join(active)

		"§Clear":
			var box = data.get("Box", "0")
			var bubbles = data.get("Bubbles", "0")
			var subtitles = data.get("Subtitles", "0")
			var portraits = data.get("Portraits", "0")
			var busts = data.get("Busts", "0")
			var backgrounds = data.get("Backgrounds", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if bubbles == "1":
				active.append("Bubbles")
			if subtitles == "1":
				active.append("Subtitles")
			if portraits == "1":
				active.append("Portraits")
			if busts == "1":
				active.append("Busts")
			if backgrounds == "1":
				active.append("Backgrounds")
			return str(index) + " | " + key + ": " + " / ".join(active)

		"§Video":
			var node = data.get("Node", "")
			var file = data.get("File", "")
			var loop = data.get("Loop", "1")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " → " + file + " (" + loop + ") | Wait: " + wait + " + " + time
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§V_Wait":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " | Wait: " + wait + " + " + time
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§V_Volume":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var volume = data.get("Volume", "")
			if time != "":
				time = " / " + time
			return str(index) + " | " + key + ": " + node + "(" + volume + time + ")"

		"§V_Pause":
			var node = data.get("Node", "")
			var lines = data.get("Lines", "")
			var all = data.get("All", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			if all == "0":
				all = " (spoken)"
			elif all == "1":
				all = " (any)"
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " ⏸︎ " + lines + all
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§V_Resume":
			var node = data.get("Node", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§V_Skip":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			return str(index) + " | " + key + ": " + node + " ▸▸ " + time

		"§V_Stop":
			var node = data.get("Node", "")
			return str(index) + " | " + key + ": " + node

		"§V_Show":
			var node = data.get("Node", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§Image":
			var node = data.get("Node", "")
			var file = data.get("File", "")
			var duration = data.get("Duration", "")
			var loop = data.get("Loop", "1")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " → " + file + " (" + loop + " + " + duration + ") | Wait: " + wait + " + " + time
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§I_Wait":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " | Wait: " + wait + " + " + time
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§I_Pause":
			var node = data.get("Node", "")
			var lines = data.get("Lines", "")
			var all = data.get("All", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			if all == "0":
				all = " (spoken)"
			elif all == "1":
				all = " (any)"
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node + " ⏸︎ " + lines + all
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§I_Resume":
			var node = data.get("Node", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§I_Show":
			var node = data.get("Node", "")
			var box = data.get("Box", "0")
			var portrait = data.get("Portrait", "0")
			var active = []
			if box == "1":
				active.append("Box")
			if portrait == "1":
				active.append("Portrait")
			var hide_str = " / ".join(active)
			var result = str(index) + " | " + key + ": " + node
			if hide_str != "":
				result += " | Hide: " + hide_str
			return result

		"§I_Stop":
			var node = data.get("Node", "")
			return str(index) + " | " + key + ": " + node

		"§Audio":
			var node = data.get("Node", "")
			var file = data.get("File", "")
			var loop = data.get("Loop", "1")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			return str(index) + " | " + key + ": " + node + " → " + file + " (" + loop + ") | Wait: " + wait + " + " + time

		"§A_Wait":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "0")
			return str(index) + " | " + key + ": " + node + " | Wait: " + wait + " + " + time

		"§A_Volume":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			var volume = data.get("Volume", "")
			if time != "":
				time = " / " + time
			return str(index) + " | " + key + ": " + node + "(" + volume + time + ")"

		"§A_Pause":
			var node = data.get("Node", "")
			var lines = data.get("Lines", "")
			var all = data.get("All", "")
			if all == "0":
				all = " (spoken)"
			elif all == "1":
				all = " (any)"
			return str(index) + " | " + key + ": " + node + " ⏸︎ " + lines + all

		"§A_Resume":
			var node = data.get("Node", "")
			return str(index) + " | " + key + ": " + node

		"§A_Skip":
			var node = data.get("Node", "")
			var time = data.get("Time", "")
			return str(index) + " | " + key + ": " + node + " ▸▸ " + time

		"§A_Stop":
			var node = data.get("Node", "")
			return str(index) + " | " + key + ": " + node

		"§VN_Scene":
			var scene = data.get("Scene", "")
			return str(index) + " | " + key + ": " + scene

		"§VN_Bust":
			var bust = data.get("Bust", "")
			var reference = data.get("Reference", "")
			var file = data.get("File", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + bust + " → " + reference + " (" + file + " (" + loop + ")) | Wait: " + wait + " + " + time

		"§VN_Move":
			var bust = data.get("Bust", "")
			var reference = data.get("Reference", "")
			return str(index) + " | " + key + ": " + reference + " → " + bust

		"§VN_Bust_Stop":
			var actors = data.get("Actors", "")
			return str(index) + " | " + key + ": " + actors

		"§VN_Mirror":
			var actors = data.get("Actors", "")
			var axis = data.get("Axis", "")
			return str(index) + " | " + key + ": " + actors + " → " + axis

		"§VN_Bust_Wait":
			var actors = data.get("Actors", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + actors + " | Wait: " + wait + " + " + time

		"§VN_Remove":
			var actors = data.get("Actors", "")
			return str(index) + " | " + key + ": " + actors

		"§VN_Effect":
			var actors = data.get("Actors", "")
			var effect = data.get("Effect", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + actors + " ▶ " + effect + " (" + loop + ") | Wait: " + wait + " + " + time

		"§VN_Effect_Stop":
			var actors = data.get("Actors", "")
			var effect = data.get("Effect", "")
			return str(index) + " | " + key + ": " + actors + " ⏹ " + effect

		"§VN_Effect_Wait":
			var actors = data.get("Actors", "")
			var effect = data.get("Effect", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + actors + " - " + effect + " | Wait: " + wait + " + " + time

		"§CS_Scene":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var scene = data.get("Scene", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " → " + scene

		"§CS_Visible":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var visibility = data.get("Visibility", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " = " + visibility

		"§CS_Loc":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var path_2 = data.get("Path 2", "")
			var markers = data.get("Markers", "")
			var rotate = data.get("Rotate", "")
			if rotate == "1":
				rotate = " (Rotate)"
			else:
				rotate = ""
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " → " + path_2 + "/" + markers + rotate

		"§CS_Look":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var path_2 = data.get("Path 2", "")
			var markers = data.get("Markers", "")
			var axis = data.get("Axis", "")
			if axis == "1":
				axis = " (Rotate)"
			else:
				axis = ""
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " → " + path_2 + "/" + markers + axis

		"§CS_Move":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var path_2 = data.get("Path 2", "")
			var markers = data.get("Markers", "")
			var animation = data.get("Animation", "")
			var method = data.get("Method", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			var parts = []
			if animation != "":
				parts.append(animation)
			if method != "":
				parts.append(method)
			var move_data = ""
			if not parts.is_empty():
				move_data = " (" + " / ".join(parts) + ")"
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " → " + path_2 + "/" + markers + move_data + " | Wait: " + wait + " + " + time

		"§CS_Anim":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var animation = data.get("Animation", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " ▶ " + animation + " (" + loop + ") | Wait: " + wait + " + " + time

		"§CS_Anim_Wait":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " | Wait: " + wait + " + " + time

		"§CS_Anim_Stop":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets

		"§CS_Sprite":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var file = data.get("File", "")
			var animation = data.get("Animation", "")
			var loop = data.get("Loop", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " → " + file + " ▶ " + animation + " (" + loop + ") | Wait: " + wait + " + " + time

		"§CS_Sprite_Wait":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var time = data.get("Time", "")
			var wait = data.get("Wait", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets + " | Wait: " + wait + " + " + time

		"§CS_Sprite_Stop":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets

		"§CS_Cam":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			return str(index) + " | " + key + ": " + path_1 + "/" + targets

		"§CS_Light":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var operator = data.get("Operator", "")
			var energy = data.get("Energy", "")
			var color = data.get("Color", "")
			var result = str(index) + " | " + key + ": " + path_1 + "/" + targets
			if energy != "":
				result += " | Energy " + operator + " " + energy
			if color != "":
				result += " (" + color + ")"
			return result

		"§CS_Toggle":
			var path_1 = data.get("Path 1", "")
			var targets = data.get("Targets", "")
			var method = data.get("Method", "")
			var properties = data.get("Properties", "")
			var value = data.get("Value", "")
			var result = str(index) + " | " + key + ": " + path_1 + "/" + targets
			if method != "":
				result += " → " + method
			if properties != "":
				result += " [" + properties + "]"
			if value != "":
				result += " = " + value
			return result

		"§Custom":
			var command = data.get("Command", "")
			var command_data = data.get("Data", "")
			return str(index) + " | " + key + ": " + command + " [" + command_data + "]"

		_:
			return "[" + key.trim_prefix("§").to_upper() + "]"


#* Drop item after dragging:
func _on_line_tree_item_dropped(dropped_item: TreeItem, target_item: TreeItem, at_position: int) -> void:
	var from_index = dropped_item.get_metadata(0)
	var to_index = target_item.get_metadata(0) if target_item else -1

	#% Determine source:
	var source = _get_line_source()

	var lines = source[globals.current_conversation][globals.current_block]["Text"]

	#% Move line from_index to to_index:
	var moved = lines[from_index]
	lines.remove_at(from_index)
	if to_index > from_index:
		to_index -= 1
	if at_position == Tree.DROP_MODE_INBETWEEN:
		to_index = clamp(to_index, 0, lines.size())
	lines.insert(to_index, moved)

	update_line_list()


#* Single item selected:
func _on_line_tree_item_selected() -> void:
	#% Clear last focus:
	globals.last_focused_field = null
	_on_selection_changed()
	if not _updating_ui:
		save_undo_step()


#* Multi item selected:
func _on_line_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	#% Clear last focus:
	globals.last_focused_field = null
	_on_selection_changed()
	if _selected and not _updating_ui:
		save_undo_step()


#* When item in the line tree is selected:
func _on_selection_changed() -> void:
	if _selection_changing:
		return

	_selection_changing = true
	globals.last_focused_field = null
	_reset_voice(true, true)

	#% If no modifier held, deselect all except the last clicked:
	if not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_SHIFT):
		var last = line_tree.get_selected()
		line_tree.deselect_all()
		if last != null:
			last.select(0)

	#% Sync selected_lines with tree's actual selection:
	selected_lines.clear()
	var item = line_tree.get_next_selected(null)
	while item != null:
		selected_lines.append(item.get_metadata(0))
		item = line_tree.get_next_selected(item)

	#% Set current line to last selected:
	var last_selected = line_tree.get_selected()
	if last_selected != null:
		globals.current_line = last_selected.get_metadata(0)
	else:
		globals.current_line = -1

	if globals.current_line == -1 or globals.current_conversation == "" or globals.current_block == "" or sort_dialogue == true:
		_selection_changing = false
		return

	#% Set current_line_type:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		_selection_changing = false
		return
	if not source[globals.current_conversation].has(globals.current_block):
		_selection_changing = false
		return

	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	print(globals.current_line)
	if globals.current_line >= lines.size():
		_selection_changing = false
		return

	#% Determine type of the current line:
	globals.current_line_type = lines[globals.current_line].keys()[0]
	print(globals.current_line_type)

	#% Display the data for the line type:
	if globals.current_line != -1 and not sort_dialogue == true:
		_suppress_undo_save = true
		_show_line_editor()
		_suppress_undo_save = false

	_selection_changing = false


#* Display line data in the edit area when a line is clicked:
func _show_line_editor() -> void:
	hide_line_data(false)

	#% Refresh variant tree if displaying a spoken line or a condition with a spoken line effect:
	var has_spoken_line = globals.current_line_type == "Spoken Line"
	if not has_spoken_line and _is_condition_command(globals.current_line_type):
		var source = _get_line_source()
		if source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line >= 0 and globals.current_line < lines.size():
				var line_data = lines[globals.current_line][globals.current_line_type]
				has_spoken_line = line_data.get("Type", "") == "Spoken Line" and line_data.get("Commands", {}).has("Spoken Line")

	if has_spoken_line:
		refresh_portrait_display()
		refresh_variant_tree()
		refresh_translation_tree()

	#% Refresh choice tree if displaying §Choice_List or a condition with §Choice_List effect:
	var has_choice_list = globals.current_line_type == "§Choice_List"
	if not has_choice_list and _is_condition_command(globals.current_line_type):
		var source = _get_line_source()
		if source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line >= 0 and globals.current_line < lines.size():
				var line_data = lines[globals.current_line][globals.current_line_type]
				has_choice_list = line_data.get("Type", "") == "§Choice_List" and line_data.get("Commands", {}).has("§Choice_List")

	if has_choice_list:
		refresh_choice_tree()

	display_line_data(globals.current_line_type)


func hide_line_data(condition_mode: bool):
	#@ Hide all data fields:
	for key in line_data_containers:
		line_data_containers[key].visible = false

	#@ Make exemption for condition commands:
	#% Used when the data fields being hidden are part of a condition effect.
	#% Unhides the condition data fields.
	if condition_mode == true:
		match globals.current_line_data:
			"§If", "§Elif", "§For", "§While":
				line_data_containers["condition"].visible = true
				line_data_containers["condition_effect"].visible = true

			"§Else":
				line_data_containers["condition_effect"].visible = true

			_:
				pass


#* Display data fields for each line type:
func display_line_data(line_type):
	#@ Guard against commands that have no data fields:
	if not line_data_containers.has(line_type):
		return

	#@ Display relevant command container:
	line_data_containers[line_type].visible = true

	#@ Display data in data fields:
	if line_data_fields.has(line_type):
		for data_field in line_data_fields[line_type]:
			line_data_fields[line_type][data_field].data_load()

	#@ Retrieve Meta, Custom Data, Dev Comment:
	var source = _get_line_source()
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	var line = lines[globals.current_line]
	var line_data = line[line_type]
	meta_field.text = line_data.get("Meta", "")
	custom_data_field.text = line_data.get("CustomData", "")
	devcom_field.text = line_data.get("DevComment", "")

	#@ Special rules:
	match line_type:
		"Spoken Line":
			_apply_spoken_line_display(line_data)
		"§If", "§Elif", "§Else", "§For", "§While":
			var effect_type = line_data.get("Type", "")
			if effect_type == "Spoken Line" and line_data["Commands"].has("Spoken Line"):
				_apply_spoken_line_display(line_data["Commands"]["Spoken Line"])


#* Display data for Spoken Line specifically:
func _apply_spoken_line_display(spoken_data: Dictionary) -> void:
	spoken_text_edit.text = ""
	spoken_text_preview.text = ""
	for entry in spoken_data.get("Variants", []):
		var key = entry.keys()[0]
		if key == globals.current_variant:
			var text = entry[globals.current_variant].get("Text", "")
			spoken_text_edit.text = text
			spoken_text_preview.text = text
			var variant_direction
			if entry[globals.current_variant].get("Direction", "LtR").to_lower() == "rtl":
				variant_direction = Control.TEXT_DIRECTION_RTL
			else:
				variant_direction = Control.TEXT_DIRECTION_LTR
			spoken_text_preview.text_direction = variant_direction
		if key == globals.current_translation:
			var text = entry[globals.current_translation].get("Text", "")
			translation_preview_raw.text = text
			translation_preview_final.text = text
			var translation_direction
			if entry[globals.current_translation].get("Direction", "LtR").to_lower() == "rtl":
				translation_direction = Control.TEXT_DIRECTION_RTL
			else:
				translation_direction = Control.TEXT_DIRECTION_LTR
			translation_preview_raw.text_direction = translation_direction
			translation_preview_final.text_direction = translation_direction

#endregion


#?######################################################################################
#& FAVORITES:
#?###########
#region
func show_favorites_context_menu(target: Dictionary) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	_favorites_context_target = target
	var is_favorite = globals.favorites.any(func(f): return f.hash() == target.hash())
	favorites_context_menu.clear()
	if is_favorite:
		favorites_context_menu.add_item("Remove from Favorites", 1)
	else:
		favorites_context_menu.add_item("Add to Favorites", 0)
	favorites_context_menu.popup()
	await get_tree().process_frame
	var mouse_pos = Vector2i(get_viewport().get_mouse_position())
	favorites_context_menu.position = Vector2i(mouse_pos.x, mouse_pos.y - favorites_context_menu.size.y)


func _on_favorites_context_menu_pressed(id: int) -> void:
	match id:
		0: _add_to_favorites(_favorites_context_target)
		1: _remove_from_favorites(_favorites_context_target)


func _add_to_favorites(target: Dictionary) -> void:
	globals.favorites.append(target)
	_rebuild_favorites()
	save_undo_step()


func _remove_from_favorites(target: Dictionary) -> void:
	for i in range(globals.favorites.size()):
		if globals.favorites[i].hash() == target.hash():
			globals.favorites.remove_at(i)
			break
	_rebuild_favorites()
	save_undo_step()

func _rebuild_favorites() -> void:
	for c in favorites_container.get_children():
		c.queue_free()

	#% Sort alphabetically by display name:
	var sorted_favs = globals.favorites.duplicate()
	sorted_favs.sort_custom(func(a, b):
		var a_name = a.get("display", a.get("command", ""))
		var b_name = b.get("display", b.get("command", ""))
		return a_name < b_name)

	for fav in sorted_favs:
		var btn := Button.new()
		if fav["type"] == "command":
			btn.text = fav["command"].trim_prefix("§")
			btn.pressed.connect(func():
				_insert_command_line(fav["command"]))
		elif fav["type"] == "preset":
			btn.text = fav["display"]
			btn.pressed.connect(func():
				_insert_preset_lines(fav["block_lines"].duplicate(true)))
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				show_favorites_context_menu(fav))
		favorites_container.add_child(btn)


func _insert_command_line(command: String) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	var template = globals.line_templates.get(command, null)
	if template == null:
		return
	var lines = _get_current_lines()
	var new_line = {command: template.duplicate(true)}
	if globals.current_line == -1 or globals.current_line >= lines.size():
		lines.append(new_line)
	else:
		lines.insert(globals.current_line + 1, new_line)
	update_line_list()
	save_undo_step()

#endregion


#?######################################################################################
#& PRESETS:
#?#########
#region
#* Populate preset buttons:
func populate_preset_buttons() -> void:
	#% Clear existing buttons:
	for c in user_presets_container.get_children():
		c.queue_free()
	for c in profile_presets_container.get_children():
		c.queue_free()

	_populate_preset_container(user_presets_container, globals.user_presets, "USER PRESETS")
	_populate_preset_container(profile_presets_container, globals.profile_presets, "PROFILE PRESETS")


#* Populate a preset tab with category tabs and buttons:
func _populate_preset_container(container: Node, presets: Dictionary, conv_key: String) -> void:
	if not presets.has(conv_key):
		return

	var blocks = presets[conv_key]
	#% category_name -> HFlowContainer:
	var categories: Dictionary = {}

	for block_name in blocks.keys():
		var category := ""
		var display_name = block_name

		#% Parse category from block name:
		if block_name.begins_with("["):
			var end = block_name.find("]")
			if end != -1:
				category = block_name.substr(1, end - 1)
				display_name = block_name.substr(end + 1).strip_edges()

		if category == "":
			category = "Unsorted"

		#% Create category tab if it doesn't exist:
		if not categories.has(category):
			var flow := HFlowContainer.new()
			var tab_name = category.replace(" ", "_")
			flow.name = tab_name
			container.add_child(flow)
			#% Set tab title:
			var tab_idx = container.get_tab_count() - 1
			container.set_tab_title(tab_idx, category)
			categories[category] = flow

		#% Create button:
		var btn := Button.new()
		btn.text = display_name
		var block_lines = blocks[block_name]["Text"].duplicate(true)
		btn.pressed.connect(func():
			_insert_preset_lines(block_lines))
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				var display = category + ": " + display_name if category != "Unsorted" else display_name
				show_favorites_context_menu({"type": "preset", "conv_key": conv_key, "block_name": block_name, "display": display, "block_lines": block_lines}))
		categories[category].add_child(btn)


#* Insert preset lines at the current position:
func _insert_preset_lines(block_lines: Array) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.current_conversation == "" or globals.current_block == "":
		return

	var lines = _get_current_lines()
	var insert_at: int

	if globals.current_line == -1 or selected_lines.is_empty() or globals.current_line >= lines.size():
		insert_at = lines.size()
	else:
		insert_at = globals.current_line + 1

	for i in range(block_lines.size()):
		lines.insert(insert_at + i, block_lines[i].duplicate(true))

	globals.current_line = insert_at + block_lines.size() - 1

	#% Determine type of the current line:
	globals.current_line_type = lines[globals.current_line].keys()[0]

	#% Display the data for the line type:
	if globals.current_line != -1 and not sort_dialogue == true:
		_show_line_editor()

	update_line_list()
	save_undo_step()


#* Export user presets:
func export_user_presets() -> void:
	print(globals.current_user)
	if globals.current_user != "":
		var user_presets_path = "user://Users/" + globals.current_user + "/user_presets.txt"
		var file = FileAccess.open(user_presets_path, FileAccess.WRITE)
		if file:
			var ascii_hash := "\u0023"
			file.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
			file.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
			file.store_string(ascii_hash + " Type: User Presets\n")
			file.store_string(ascii_hash + " User: " + globals.current_user + "\n\n")
			file.store_string(_pretty_var(globals.user_presets))
			file.close()
		else:
			push_error("Failed to write user_presets.txt")


#* Export profile presets:
func export_profile_presets() -> void:
	if globals.current_user != "" and globals.current_profile != "":
		var profile_presets_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/profile_presets.txt"
		var file = FileAccess.open(profile_presets_path, FileAccess.WRITE)
		if file:
			var ascii_hash := "\u0023"
			file.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
			file.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
			file.store_string(ascii_hash + " Type: Profile Presets\n")
			file.store_string(ascii_hash + " User: " + globals.current_user + "\n")
			file.store_string(ascii_hash + " Profile: " + globals.current_profile + "\n\n")
			file.store_string(_pretty_var(globals.profile_presets))
			file.close()
		else:
			push_error("Failed to write profile_presets.txt")


#* Load all presets and update lines with new variants in one function call:
func load_presets():
	load_user_presets()
	load_profile_presets()
	_populate_all_spoken_lines()


#* Load user presets:
func load_user_presets() -> void:
	if globals.current_user != "":
		var user_presets_path = "user://Users/" + globals.current_user + "/user_presets.txt"
		if FileAccess.file_exists(user_presets_path):
			var file = FileAccess.open(user_presets_path, FileAccess.READ)
			if file:
				var raw = file.get_as_text()
				file.close()
				var lines = raw.split("\n")
				var cleaned = []
				for line in lines:
					if not line.strip_edges().begins_with("\u0023"):
						cleaned.append(line)
				raw = "\n".join(cleaned)
				var parsed = str_to_var(raw)
				if parsed is Dictionary:
					globals.user_presets = parsed
					populate_preset_buttons()

					#@ Import languages from user presets:
					var keys := []
					for conv in globals.user_presets.values():
						for block in conv.values():
							for line_entry in block.get("Text", []):
								var line_type = line_entry.keys()[0]
								if line_type == "Spoken Line":
									for entry in line_entry["Spoken Line"].get("Variants", []):
										keys.append(entry.keys()[0])
								elif line_type in ["§If", "§Elif", "§Else", "§For", "§While"]:
									var commands = line_entry[line_type].get("Commands", {})
									if commands.has("Spoken Line"):
										for entry in commands["Spoken Line"].get("Variants", []):
											keys.append(entry.keys()[0])
					_import_languages_from_keys(keys)

				else:
					push_error("Failed to read user_presets.txt")


#* Load profile presets:
func load_profile_presets() -> void:
	if globals.current_user != "" and globals.current_profile != "":
		var profile_presets_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/profile_presets.txt"
		if FileAccess.file_exists(profile_presets_path):
			var file = FileAccess.open(profile_presets_path, FileAccess.READ)
			if file:
				var raw = file.get_as_text()
				file.close()
				var lines = raw.split("\n")
				var cleaned = []
				for line in lines:
					if not line.strip_edges().begins_with("\u0023"):
						cleaned.append(line)
				raw = "\n".join(cleaned)
				var parsed = str_to_var(raw)
				if parsed is Dictionary:
					globals.profile_presets = parsed
					populate_preset_buttons()

					#@ Import languages from profile presets:
					var keys := []
					for conv in globals.profile_presets.values():
						for block in conv.values():
							for line_entry in block.get("Text", []):
								var line_type = line_entry.keys()[0]
								if line_type == "Spoken Line":
									for entry in line_entry["Spoken Line"].get("Variants", []):
										keys.append(entry.keys()[0])
								elif line_type in ["§If", "§Elif", "§Else", "§For", "§While"]:
									var commands = line_entry[line_type].get("Commands", {})
									if commands.has("Spoken Line"):
										for entry in commands["Spoken Line"].get("Variants", []):
											keys.append(entry.keys()[0])
					_import_languages_from_keys(keys)

				else:
					push_error("Failed to read profile_presets.txt")

#endregion


#?######################################################################################
#& TEST EXPORT:
#?#############
#region
#* Export all conversations to test_dialogue.txt file:
func _on_test_export_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	var path = globals.project_path.path_join(globals.custom_project_paths["Dialogues"]).path_join("test_dialogue.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		if globals.project_path == "":
			show_warning("[color=yellow]You must provide a path to your project in the Settings menu first.[/color]")
		else:
			show_warning("[color=yellow]The path to your project or to its 'Dialogues' folder is invalid. Please check the path in the Settings menu.[/color]")
		return

	#@ Create a deep duplicate so we don't modify globals.dialogue:
	var export_data = globals.dialogue.duplicate(true)

	#@ Iterate over conversations → blocks → lines:
	for conv_key in export_data.keys():
		var conv = export_data[conv_key]
		for block_key in conv.keys():
			var block = conv[block_key]
			var lines = block["Text"]
			for i in range(lines.size()):
				var entry = lines[i]
				var line_type = entry.keys()[0]
				if line_type == "Spoken Line":
					var spoken_line = entry["Spoken Line"]
					var variants = spoken_line.get("Variants", [])
					var cleaned_variants := []
					#% Keep only variants that contain non-empty text:
					for variant_dict in variants:
						for variant_name in variant_dict.keys():
							var text_val := str(variant_dict[variant_name].get("Text", "")).strip_edges()
							if text_val != "":
								cleaned_variants.append(variant_dict)
							break
					spoken_line["Variants"] = cleaned_variants
					entry["Spoken Line"] = spoken_line
					lines[i] = entry
				block["Text"] = lines

	#@ Wrap in Meta and Dialogue structure:
	var output := {
		"Meta": {
			"Exported By": "Candy Dialogue Creator",
			"Creator Version": globals.dc_version,
			"Dialogue Version": globals.dialogue_version,
		},
		"Dialogue": export_data,
	}

	#@ Write to file:
	var ascii_hash := "\u0023"
	file.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
	file.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
	file.store_string(ascii_hash + " Dialogue Version: " + str(globals.dialogue_version) + "\n\n")
	file.store_string(_pretty_var(output, 0))
	file.close()
	print("Exported dialogue to: ", path)
	show_warning("Dialogue exported to " + path)

#endregion


#?######################################################################################
#& SAVE/LOAD:
#?###########
#region
#* General save function (used by all save types):
func _save_dialogue_to_txt(path: String, save_type: String, save_mode: int = 0) -> void:
	#@ Unmark unsaved work:
	if save_type != "Auto Save":
		globals.unsaved_work = false
		top_text.text = "Candy Dialogue Creator " + globals.dc_version + "   -   " + globals.current_user + ": " + globals.current_profile

	var save_path = path

	#@ Incremental save - append timestamp:
	if save_mode == 1:
		var regex := RegEx.new()
		regex.compile("〔\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}〕$")
		var without_ext = path.trim_suffix(".txt")
		without_ext = regex.sub(without_ext, "", true)
		var stamp = Time.get_datetime_string_from_system().replace(":", "-")
		save_path = without_ext + "_〔" + stamp + "〕.txt"

	#@ Get file:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + save_path)
		return

	#@ Prepare save data:
	var save_data := {
		"Type": save_type,
		"User": globals.current_user,
		"Profile": globals.current_profile,
		"Exported By": "Candy Dialogue Creator",
		"Version": globals.dc_version,
		"Dialogue Version": globals.dialogue_version,
		"Dialogue": globals.dialogue,
	}

	#@ Save data to file:
	file.store_string(_pretty_var(save_data))
	file.close()
	if save_type == "Normal Save":
		globals.current_save = save_path
		save_dialogue.visible = false
		shield.visible = false
	print("Saved ", save_type, " to: ", save_path)


#* Save button pressed:
func _on_save_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	save(globals.default_save_mode)


#* Load button pressed:
func _on_load_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	var save_dir = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves"
	if DirAccess.dir_exists_absolute(save_dir):
		load_dialogue.current_path = save_dir + "/"
	globals.editor_state = "Load"
	shield.visible = true
	load_dialogue.visible = true


#* Prepare to save:
func save(save_mode) -> void:
	#@ Check that there is a current save:
	if globals.current_save == "":
		save_as(save_mode)
		return

	#@ Save:
	_save_dialogue_to_txt(globals.current_save, "Normal Save", save_mode)


#* Save As - Display save dialogue window:
func save_as(save_mode) -> void:
	globals.editor_state = "Save As"
	var save_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves/Manual_Saves"
	if DirAccess.dir_exists_absolute(save_path):
		save_dialogue.current_path = save_path + "/"
	shield.visible = true
	save_dialogue.visible = true
	save_dialogue.save_mode = save_mode


#* "Save" button right-clicked:
func _on_save_btn_gui_input(event: InputEvent) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		save_context_menu.hide()
		save_context_menu.popup()
		save_context_menu.position = Vector2i(get_viewport().get_mouse_position())


#* Item selected from the save context menu:
func _on_save_context_menu_pressed(id: int) -> void:
	match id:
		0: save(0)
		1: save_as(globals.default_save_mode)
		2: save(1)


#* Called when profile loaded, to setup and start the auto save timer:
func setup_autosave() -> void:
	var freq = globals.auto_save_freq.to_int()
	if freq < 1:
		freq = 15
	auto_save_timer.wait_time = freq
	auto_save_timer.timeout.connect(_on_autosave_timer_timeout)
	auto_save_timer.start()


#* Perform Auto Save:
func _on_autosave_timer_timeout() -> void:
	if globals.current_user == "" or globals.current_profile == "":
		return

	#% Safety: minimum 5 seconds between auto saves:
	var freq = globals.auto_save_freq.to_int()
	if freq < 5:
		freq = 5

	#% Update the timer countdown for next auto save, in case it changed:
	auto_save_timer.wait_time = freq

	#% Don't save if auto save disabled:
	var max_saves = globals.auto_saves_max.to_int()
	if max_saves == -1:
		return

	#% Select the folder to save to, and check that it exists:
	var save_dir = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves/Auto_Saves"
	if not DirAccess.dir_exists_absolute(save_dir):
		return

	#% Append timestamp to file name:
	var stamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = "Auto_Save_" + str(globals.auto_save_index) + "_" + stamp + ".txt"
	var save_path = save_dir + "/" + filename

	#% Delete previous autosave with the same index:
	var dir = DirAccess.open(save_dir)
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.begins_with("Auto_Save_" + str(globals.auto_save_index) + "_") and f.ends_with(".txt"):
				DirAccess.remove_absolute(save_dir + "/" + f)
			f = dir.get_next()
		dir.list_dir_end()

	#% Save:
	_save_dialogue_to_txt(save_path, "Auto Save")

	#% Increase index for next auto save:
	globals.auto_save_index += 1
	if max_saves > 0 and globals.auto_save_index > max_saves:
		globals.auto_save_index = 1


#* Perform quick save (called by user input):
func quick_save() -> void:
	if globals.current_user == "" or globals.current_profile == "":
		show_warning("[color=red]Quick save failed: user or profile not assigned.[/color]")
		return

	var max_saves = globals.quick_saves_max.to_int()
	if max_saves == -1:
		show_warning("[color=red]Quick saving disabled in profile settings.[/color]")
		return

	var save_dir = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves/Quick_Saves"
	if not DirAccess.dir_exists_absolute(save_dir):
		show_warning("[color=red]Quick save failed: error 2.[/color]")
		return

	var stamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = "Quick_Save_" + str(globals.quick_save_index) + "_" + stamp + ".txt"
	var save_path = save_dir + "/" + filename

	_save_dialogue_to_txt(save_path, "Quick Save")

	globals.quick_save_index += 1
	if max_saves > 0 and globals.quick_save_index > max_saves:
		globals.quick_save_index = 1

	show_warning("[color=yellow]Quick save successful.[/color]")


#* Perform quick load (called by user input):
func quick_load() -> void:
	if globals.current_user == "" or globals.current_profile == "":
		show_warning("[color=red]Quick load failed: user or profile not assigned.[/color]")
		return

	var save_dir = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves/Quick_Saves"
	if not DirAccess.dir_exists_absolute(save_dir):
		show_warning("[color=red]Quick load failed: error 7.[/color]")
		return

	#@ Find the quick save with the most recent timestamp:
	var dir = DirAccess.open(save_dir)
	if not dir:
		return

	var latest_file := ""
	var latest_stamp := ""
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.begins_with("Quick_Save_") and f.ends_with(".txt"):
			#% Extract the timestamp: "Quick_Save_INDEX_STAMP.txt" → "STAMP":
			var without_ext := f.trim_suffix(".txt")
			var first_underscore := without_ext.find("_")
			var second_underscore := without_ext.find("_", first_underscore + 1)
			var third_underscore := without_ext.find("_", second_underscore + 1)
			var stamp := without_ext.substr(third_underscore + 1)

			#% Compare timestamps:
			if stamp > latest_stamp:
				latest_stamp = stamp
				latest_file = f
		f = dir.get_next()
	dir.list_dir_end()

	if latest_file == "":
		show_warning("[color=red]No file to load.[/color]")
		return

	_load_dialogue_from_txt(save_dir + "/" + latest_file)
	globals.current_save = ""

	show_warning("[color=yellow]Quick load successful.[/color]")

#* Load a save file:
func _load_dialogue_from_txt(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: " + path)
		shield.visible = false
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path)
		shield.visible = false
		return

	var raw := file.get_as_text()
	var data = str_to_var(raw)
	if not data is Dictionary:
		data = JSON.parse_string(raw)
	file.close()

	if data == null or not data is Dictionary:
		push_error("Failed to parse file: " + path)
		shield.visible = false
		return

	var version := str(data.get("Dialogue Version", "unknown")).strip_edges()
	if version != globals.dialogue_version:
		show_warning("[color=yellow]The file you are trying to load uses the " + version + " format. Please use the Converter tool to convert it to 1.1 format.[/color]")
		shield.visible = false
		return

	globals.dialogue = data.get("Dialogue", {})

	#@ Import languages and variants from loaded dialogue:
	var keys := []
	for conv in globals.dialogue.values():
		for block in conv.values():
			for line_entry in block.get("Text", []):
				if line_entry.has("Spoken Line"):
					for entry in line_entry["Spoken Line"].get("Variants", []):
						keys.append(entry.keys()[0])
	_import_languages_from_keys(keys)

	#@ Populate all spoken lines with any missing combinations:
	_populate_all_spoken_lines()

	globals.current_save = ""
	if data.get("Type", "") == "Normal Save":
		globals.current_save = path
	load_dialogue.visible = false
	shield.visible = false

	update_conversation_selector(false)
	print("Loaded dialogue from: ", path)

#endregion


#?######################################################################################
#& PROFILE SAVING/LOADING:
#?########################
#region
#* Save profile settings to ProfileSettings.txt:
func save_profile() -> void:
	if globals.current_user == "" or globals.current_profile == "":
		push_error("No active user/profile selected.")
		return

	var config_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/ProfileSettings.txt"

	#@ Build data dictionary:
	var data = {}

	#% Save data:
	data["User Name"] = globals.current_user
	data["Profile Name"] = globals.current_profile
	data["Candy DC Version"] = globals.dc_version

	data["current_variant"] = globals.current_variant
	data["current_translation"] = globals.current_translation

	data["meta_visible"] = globals.meta_visible
	data["dev_comments_visible"] = globals.dev_comments_visible
	data["overrides_area_visible"] = globals.overrides_area_visible
	data["translate_area_visible"] = globals.translate_area_visible
	data["portrait_area_visible"] = globals.portrait_area_visible
	data["voice_area_visible"] = globals.voice_area_visible
	data["disposition_area_visible"] = globals.disposition_area_visible

	data["choice_general_prompt_visible"] = globals.choice_general_prompt_visible
	data["choice_general_mouse_visible"] = globals.choice_general_mouse_visible
	data["choice_general_setup_visible"] = globals.choice_general_setup_visible
	data["choice_general_scenes_visible"] = globals.choice_general_scenes_visible
	data["choice_general_tags_visible"] = globals.choice_general_tags_visible
	data["choice_general_custom_visible"] = globals.choice_general_custom_visible

	data["choice_category_prompt_visible"] = globals.choice_category_prompt_visible
	data["choice_category_mouse_visible"] = globals.choice_category_mouse_visible
	data["choice_category_setup_visible"] = globals.choice_category_setup_visible
	data["choice_category_scenes_visible"] = globals.choice_category_scenes_visible
	data["choice_category_tags_visible"] = globals.choice_category_tags_visible
	data["choice_category_custom_visible"] = globals.choice_category_custom_visible

	data["choice_item_tooltip_visible"] = globals.choice_item_tooltip_visible
	data["choice_item_setup_visible"] = globals.choice_item_setup_visible
	data["choice_item_scene_visible"] = globals.choice_item_scene_visible
	data["choice_item_tags_visible"] = globals.choice_item_tags_visible
	data["choice_item_custom_visible"] = globals.choice_item_custom_visible

	data["choice_timer_setup_visible"] = globals.choice_timer_setup_visible
	data["choice_timer_timeout_visible"] = globals.choice_timer_timeout_visible
	data["choice_timer_tags_visible"] = globals.choice_timer_tags_visible
	data["choice_timer_custom_visible"] = globals.choice_timer_custom_visible

	data["video_preview_width"] = globals.video_preview_width
	data["image_preview_width"] = globals.image_preview_width
	data["bg_preview_width"] = globals.bg_preview_width
	data["bg_sprite_fps"] = globals.bg_sprite_fps
	data["portrait_preview_width"] = globals.portrait_preview_width
	data["portrait_sprite_fps"] = globals.portrait_sprite_fps
	data["bust_preview_width"] = globals.bust_preview_width
	data["bust_sprite_fps"] = globals.bust_sprite_fps

	data["undo_steps_min"] = globals.undo_steps_min
	data["undo_steps_max"] = globals.undo_steps_max
	data["undo_memory_min"] = globals.undo_memory_min
	data["undo_memory_max"] = globals.undo_memory_max

	data["selected_ui_colors"] = globals.selected_ui_colors
	data["ui_colors"] = globals.ui_colors

	data["conversation_default_name"] = globals.conversation_default_name
	data["block_default_name"] = globals.block_default_name

	data["default_text_direction"] = globals.default_text_direction

	data["warning_display_time"] = globals.warning_display_time

	data["spoken_text_limit"] = globals.spoken_text_limit
	data["limit_margin"] = globals.limit_margin

	data["default_save_mode"] = globals.default_save_mode
	data["quick_saves_max"] = globals.quick_saves_max
	data["auto_save_freq"] = globals.auto_save_freq
	data["auto_saves_max"] = globals.auto_saves_max

	data["symbol_script_path"] = globals.symbol_script_path
	data["singleton_symbol"] = globals.singleton_symbol
	data["node_symbol"] = globals.node_symbol
	data["vardict_symbol"] = globals.vardict_symbol
	data["super_singleton_symbol"] = globals.super_singleton_symbol
	data["super_node_symbol"] = globals.super_node_symbol
	data["super_vardict_symbol"] = globals.super_vardict_symbol
	data["role_symbol"] = globals.role_symbol
	data["text_var_symbol_start"] = globals.text_var_symbol_start
	data["text_var_symbol_end"] = globals.text_var_symbol_end
	data["substitution_symbol"] = globals.substitution_symbol
	data["separator_symbol"] = globals.separator_symbol

	data["project_path"] = globals.project_path

	data["custom_project_paths"] = globals.custom_project_paths
	data["project_scripts"] = globals.project_scripts
	data["direct_data"] = globals.direct_data
	data["favorites"] = globals.favorites
	data["line_colors"] = globals.line_colors

	data["languages"] = globals.languages
	data["variants"] = globals.variants

	data["preview_bg_color"] = var_to_str(globals.preview_bg_color)
	data["preview_text_color"] = var_to_str(globals.preview_text_color)
	data["preview_portrait_color"] = var_to_str(globals.preview_portrait_color)


	#@ Write to file:
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write ProfileSettings.txt.")
		return
	file.store_string(_pretty_var(data, 0))
	file.close()
	print("Profile saved: ", globals.current_profile)


#* Load profile settings from ProfileSettings.txt:
func load_profile() -> void:
	if globals.current_user == "" or globals.current_profile == "":
		push_error("No active user/profile selected.")
		return

	var config_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/ProfileSettings.txt"

	if not FileAccess.file_exists(config_path):
		push_error("ProfileSettings.txt not found.")
		return

	#@ Read file:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open ProfileSettings.txt.")
		return
	var data = str_to_var(file.get_as_text())
	file.close()

	if not data is Dictionary:
		push_error("Failed to parse ProfileSettings.txt.")
		return

	#% Load data:
	globals.current_user = data.get("User Name", "")
	globals.current_profile = data.get("Profile Name", "")

	globals.current_variant = data.get("current_variant", "Default")
	globals.current_translation = data.get("current_translation", "Default")

	globals.meta_visible = data.get("meta_visible", true)
	globals.dev_comments_visible = data.get("dev_comments_visible", true)
	globals.overrides_area_visible = data.get("overrides_area_visible", true)
	globals.translate_area_visible = data.get("translate_area_visible", false)
	globals.portrait_area_visible = data.get("portrait_area_visible", true)
	globals.voice_area_visible = data.get("voice_area_visible", true)
	globals.disposition_area_visible = data.get("disposition_area_visible", true)

	globals.choice_general_prompt_visible = data.get("choice_general_prompt_visible", true)
	globals.choice_general_mouse_visible = data.get("choice_general_mouse_visible", true)
	globals.choice_general_setup_visible = data.get("choice_general_setup_visible", true)
	globals.choice_general_scenes_visible = data.get("choice_general_scenes_visible", true)
	globals.choice_general_tags_visible = data.get("choice_general_tags_visible", true)
	globals.choice_general_custom_visible = data.get("choice_general_custom_visible", true)

	globals.choice_category_prompt_visible = data.get("choice_category_prompt_visible", true)
	globals.choice_category_mouse_visible = data.get("choice_category_mouse_visible", true)
	globals.choice_category_setup_visible = data.get("choice_category_setup_visible", true)
	globals.choice_category_scenes_visible = data.get("choice_category_scenes_visible", true)
	globals.choice_category_tags_visible = data.get("choice_category_tags_visible", true)
	globals.choice_category_custom_visible = data.get("choice_category_custom_visible", true)

	globals.choice_item_tooltip_visible = data.get("choice_item_tooltip_visible", true)
	globals.choice_item_setup_visible = data.get("choice_item_setup_visible", true)
	globals.choice_item_scene_visible = data.get("choice_item_scene_visible", true)
	globals.choice_item_tags_visible = data.get("choice_item_tags_visible", true)
	globals.choice_item_custom_visible = data.get("choice_item_custom_visible", true)

	globals.choice_timer_setup_visible = data.get("choice_timer_setup_visible", true)
	globals.choice_timer_timeout_visible = data.get("choice_timer_timeout_visible", true)
	globals.choice_timer_tags_visible = data.get("choice_timer_tags_visible", true)
	globals.choice_timer_custom_visible = data.get("choice_timer_custom_visible", true)

	globals.video_preview_width = data.get("video_preview_width", true)
	globals.image_preview_width = data.get("image_preview_width", true)
	globals.bg_preview_width = data.get("bg_preview_width", true)
	globals.bg_sprite_fps = data.get("bg_sprite_fps", true)
	globals.portrait_preview_width = data.get("portrait_preview_width", true)
	globals.portrait_sprite_fps = data.get("portrait_sprite_fps", true)
	globals.bust_preview_width = data.get("bust_preview_width", true)
	globals.bust_sprite_fps = data.get("bust_sprite_fps", true)

	globals.undo_steps_min = data.get("undo_steps_min", 0)
	globals.undo_steps_max = data.get("undo_steps_max", 25)
	globals.undo_memory_min = data.get("undo_memory_min", 0)
	globals.undo_memory_max = data.get("undo_memory_max", 0)

	globals.selected_ui_colors = data.get("selected_ui_colors", "0")
	globals.ui_colors = data.get("ui_colors", globals.ui_colors)

	globals.conversation_default_name = data.get("conversation_default_name", "Conversation_1")
	globals.block_default_name = data.get("block_default_name", "Block_1")

	globals.default_text_direction = data.get("default_text_direction", "LtR")

	globals.warning_display_time = data.get("warning_display_time", "0.05")

	globals.spoken_text_limit = data.get("spoken_text_limit", "250")
	globals.limit_margin = data.get("limit_margin", "50")

	globals.default_save_mode = data.get("default_save_mode", 0)
	globals.quick_saves_max = data.get("quick_saves_max", "5")
	globals.auto_save_freq = data.get("auto_save_freq", "15")
	globals.auto_saves_max = data.get("auto_saves_max", "5")

	globals.symbol_script_path = data.get("symbol_script_path", "")
	globals.singleton_symbol = data.get("singleton_symbol", "£")
	globals.node_symbol = data.get("node_symbol", "$")
	globals.vardict_symbol = data.get("vardict_symbol", "€")
	globals.super_singleton_symbol = data.get("super_singleton_symbol", "££")
	globals.super_node_symbol = data.get("super_node_symbol", "$$")
	globals.super_vardict_symbol = data.get("super_vardict_symbol", "€€")
	globals.role_symbol = data.get("role_symbol", "°")
	globals.text_var_symbol_start = data.get("text_var_symbol_start", "{)")
	globals.text_var_symbol_end = data.get("text_var_symbol_end", "}")
	globals.substitution_symbol = data.get("substitution_symbol", "•")
	globals.separator_symbol = data.get("separator_symbol", "|")

	globals.project_path = data.get("project_path", "")

	globals.custom_project_paths = data.get("custom_project_paths", globals.custom_project_paths)
	globals.project_scripts = data.get("project_scripts", globals.project_scripts)
	globals.direct_data = data.get("direct_data", globals.direct_data)
	globals.favorites = data.get("favorites", [])
	globals.line_colors = data.get("line_colors", globals.line_colors)

	globals.languages = data.get("languages", globals.languages)
	globals.variants = data.get("variants", globals.variants)

	globals.preview_bg_color = str_to_var(data.get("preview_bg_color", var_to_str(Color(0, 0, 0, 1))))
	globals.preview_text_color = str_to_var(data.get("preview_text_color", var_to_str(Color(1, 1, 1, 1))))
	globals.preview_portrait_color = str_to_var(data.get("preview_portrait_color", var_to_str(Color(0, 0, 0, 1))))

	#% Restore preview colors:
	_on_preview_bg_color_color_changed(globals.preview_bg_color)
	_on_preview_text_color_color_changed(globals.preview_text_color)
	preview_bg_color_picker.color = globals.preview_bg_color
	preview_text_color_picker.color = globals.preview_text_color

	portrait_bg.color = globals.preview_portrait_color

	#% Load presets:
	load_presets()

	#% Load inserts:
	load_user_inserts()
	load_profile_inserts()

	#% Set auto and quick saves to save after the latest file:
	_load_save_index("Auto_Saves", "auto_save_index", globals.auto_saves_max.to_int())
	_load_save_index("Quick_Saves", "quick_save_index", globals.quick_saves_max.to_int())

	setup_autosave()

	top_text.text = "Candy Dialogue Creator " + globals.dc_version + "   -   " + globals.current_user + ": " + globals.current_profile

	print("Profile loaded: ", globals.current_user + "/" + globals.current_profile)
	print(globals.project_path)

	#% Populate line color list:
	settings_menu._populate_line_color_list()

	#% Load the data filters config:
	setup_data_filters()

	#% Scan project resources upon loading:
	scan_project_resources()

	#% Update symbol inserts buttons:
	update_variable_insert_buttons()

	save_undo_step()


#* Scan quick and auto save files to find the latest:
func _load_save_index(folder_name: String, index_var: String, max_saves: int) -> void:
	var save_dir = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Saves/" + folder_name
	if not DirAccess.dir_exists_absolute(save_dir):
		return

	var dir = DirAccess.open(save_dir)
	if dir == null:
		return

	#% Find the file with the most recent timestamp:
	var latest_index := 0
	var latest_stamp := ""
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".txt"):
			var without_ext := fname.trim_suffix(".txt")
			var parts := without_ext.split("_")
			if parts.size() >= 3:
				var index := parts[2].to_int()
				#% Timestamp starts after the third underscore:
				var first := without_ext.find("_")
				var second := without_ext.find("_", first + 1)
				var third := without_ext.find("_", second + 1)
				var stamp := without_ext.substr(third + 1)
				if stamp > latest_stamp:
					latest_stamp = stamp
					latest_index = index
		fname = dir.get_next()
	dir.list_dir_end()

	#% Set next index:
	var next = latest_index + 1
	if max_saves > 0 and next > max_saves:
		next = 1

	if index_var == "auto_save_index":
		globals.auto_save_index = next
	elif index_var == "quick_save_index":
		globals.quick_save_index = next


#* Setup data filters:
func setup_data_filters():
	if globals.translate_area_visible == false:
		translation_area.visible = false
		translation_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		translation_area.visible = true
		translation_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.portrait_area_visible == false:
		portrait_file.visible = false
		portrait_box.visible = false
		portrait_play.visible = false
		portrait_play_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		portrait_file.visible = true
		portrait_box.visible = true
		portrait_play.visible = true
		portrait_play_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.voice_area_visible == false:
		variant_voice_area.visible = false
		translation_voice_area.visible = false
		variant_voice_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		variant_voice_area.visible = true
		translation_voice_area.visible = true
		variant_voice_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.disposition_area_visible == false:
		disposition_field.visible = false
		disposition_field_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		disposition_field.visible = true
		disposition_field_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.overrides_area_visible == false:
		overrides_area.visible = false
		overrides_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		overrides_area.visible = true
		overrides_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


	if globals.choice_general_prompt_visible == false:
		choice_general_prompt.visible = false
		choice_general_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_prompt.visible = true
		choice_general_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_general_mouse_visible == false:
		choice_general_mouse.visible = false
		choice_general_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_mouse.visible = true
		choice_general_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_general_setup_visible == false:
		choice_general_setup.visible = false
		choice_general_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_setup.visible = true
		choice_general_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_general_scenes_visible == false:
		choice_general_self_scene.visible = false
		choice_general_category_scene.visible = false
		choice_general_item_scene.visible = false
		choice_general_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_self_scene.visible = true
		choice_general_category_scene.visible = true
		choice_general_item_scene.visible = true
		choice_general_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_general_tags_visible == false:
		choice_general_tags.visible = false
		choice_general_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_tags.visible = true
		choice_general_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_general_custom_visible == false:
		choice_general_custom.visible = false
		choice_general_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_general_custom.visible = true
		choice_general_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


	if globals.choice_category_prompt_visible == false:
		choice_category_prompt.visible = false
		choice_category_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_prompt.visible = true
		choice_category_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_category_mouse_visible == false:
		choice_category_mouse.visible = false
		choice_category_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_mouse.visible = true
		choice_category_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_category_setup_visible == false:
		choice_category_setup.visible = false
		choice_category_setup.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_setup.visible = true
		choice_category_setup.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_category_scenes_visible == false:
		choice_category_self_scene.visible = false
		choice_category_item_scene.visible = false
		choice_category_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_self_scene.visible = true
		choice_category_item_scene.visible = true
		choice_category_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_category_tags_visible == false:
		choice_category_tags.visible = false
		choice_category_tags.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_tags.visible = true
		choice_category_tags.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_category_custom_visible == false:
		choice_category_custom.visible = false
		choice_category_custom.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_category_custom.visible = true
		choice_category_custom.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


	if globals.choice_item_tooltip_visible == false:
		choice_item_tooltip.visible = false
		choice_item_tooltip_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_item_tooltip.visible = true
		choice_item_tooltip_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_item_setup_visible == false:
		choice_item_setup.visible = false
		choice_item_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_item_setup.visible = true
		choice_item_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_item_scene_visible == false:
		choice_item_self_scene.visible = false
		choice_item_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_item_self_scene.visible = true
		choice_item_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_item_tags_visible == false:
		choice_item_tags.visible = false
		choice_item_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_item_tags.visible = true
		choice_item_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_item_custom_visible == false:
		choice_item_custom.visible = false
		choice_item_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_item_custom.visible = true
		choice_item_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


	if globals.choice_timer_setup_visible == false:
		choice_timer_setup.visible = false
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_timer_setup.visible = true
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_timer_timeout_visible == false:
		choice_timer_timeout.visible = false
		choice_timer_timeout_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_timer_timeout.visible = true
		choice_timer_timeout_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_timer_tags_visible == false:
		choice_timer_tags.visible = false
		choice_timer_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_timer_tags.visible = true
		choice_timer_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

	if globals.choice_timer_custom_visible == false:
		choice_timer_custom.visible = false
		choice_timer_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		choice_timer_custom.visible = true
		choice_timer_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

#endregion


#?######################################################################################
#& VARIANT TREE:
#?##############
#region
#* Refresh variant tree:
func refresh_variant_tree() -> void:
	variant_tree.clear()
	variant_tree.columns = 2
	variant_tree.set_column_expand(0, true)
	variant_tree.set_column_expand(1, false)
	variant_tree.set_column_custom_minimum_width(1, 32)
	var root = variant_tree.create_item()
	variant_tree.hide_root = true
	variant_tree.hide_folding = true

	#% Find current line's variants
	var source = _get_line_source()
	var line_variants = {}
	if globals.current_line < 0 or globals.current_line_type == "":
		pass
	elif source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
		var lines = source[globals.current_conversation][globals.current_block]["Text"]
		if globals.current_line < lines.size():
			var line = lines[globals.current_line]
			var line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.get("Commands", {}).has("Spoken Line"):
				line_data = line_data["Commands"]["Spoken Line"]
			if line_data.has("Variants"):
				for entry in line_data["Variants"]:
					var key = entry.keys()[0]
					line_variants[key] = entry[key]

	var languages_sorted = globals.languages.keys()
	languages_sorted.erase("Default")
	languages_sorted.sort()
	languages_sorted.push_front("Default")

	for language in languages_sorted:
		var lang_item = variant_tree.create_item(root)
		lang_item.set_metadata(0, {"type": "language", "language": language})
		lang_item.set_text(0, language)
		lang_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Normal"])

		var variants_sorted = globals.languages[language]["Variants"].keys()
		variants_sorted.erase("")
		variants_sorted.sort()
		variants_sorted.push_front("")

		for variant in variants_sorted:
			var combined = language + variant
			var var_item = variant_tree.create_item(lang_item)
			var_item.set_metadata(0, {"type": "variant", "language": language, "variant": variant, "combined": combined})
			var_item.set_text(0, "    " + combined)

			if line_variants.has(combined):
				var text = line_variants[combined].get("Text", "")
				if text == "":
					var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Caution"])
				else:
					var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Normal"])
				var_item.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				var_item.set_text(1, line_variants[combined].get("Weight", "1"))
			else:
				var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Disabled"])

	_select_tree_item_by_combined(variant_tree, globals.current_variant)


#* Select a variant in the tree:
func _on_variant_tree_item_selected() -> void:
	_reset_voice(true, false)

	#% Clear last focus:
	globals.last_focused_field = null

	var item = variant_tree.get_selected()
	var meta = item.get_metadata(0)
	if meta["type"] != "variant":
		return
	globals.current_variant = meta["combined"]
	var source = _get_line_source()
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	var line = lines[globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type) and line_data.get("Commands", {}).has("Spoken Line"):
		line_data = line_data["Commands"]["Spoken Line"]
	if not line_data.has("Variants"):
		spoken_text_edit.text = ""
		spoken_text_preview.text = ""
		return
	for entry in line_data["Variants"]:
		if entry.keys()[0] == globals.current_variant:
			var text = entry[globals.current_variant].get("Text", "")
			spoken_text_edit.text = text
			spoken_text_preview.text = text
			var weight = entry[globals.current_variant].get("Weight", "")
			variant_weight.text_field.text = weight
			var direction = entry[globals.current_variant].get("Direction", "")
			variant_direction_field.text_field.text = direction
			var text_dir
			if direction.to_lower() == "rtl":
				text_dir = Control.TEXT_DIRECTION_RTL
			else:
				text_dir = Control.TEXT_DIRECTION_LTR
			spoken_text_preview.text_direction = text_dir
			refresh_counters()
			save_undo_step()
			return

	spoken_text_edit.text = ""
	spoken_text_preview.text = ""

	refresh_counters()
	if not _suppress_undo_save and not _updating_ui:
		save_undo_step()
	return


#* Refresh translation tree:
func refresh_translation_tree() -> void:
	translation_tree.clear()
	translation_tree.columns = 1
	translation_tree.set_column_expand(0, true)
	var root = translation_tree.create_item()
	translation_tree.hide_root = true
	translation_tree.hide_folding = true

	var source = _get_line_source()
	var line_variants = {}
	var lines
	var line
	var line_data
	if globals.current_line < 0 or globals.current_line_type == "":
		pass
	elif source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
		lines = source[globals.current_conversation][globals.current_block]["Text"]
		if globals.current_line < lines.size():
			line = lines[globals.current_line]
			line_data = line[globals.current_line_type]
			if _is_condition_command(globals.current_line_type) and line_data.get("Commands", {}).has("Spoken Line"):
				line_data = line_data["Commands"]["Spoken Line"]
			if line_data.has("Variants"):
				for entry in line_data["Variants"]:
					var key = entry.keys()[0]
					line_variants[key] = entry[key]

	var languages_sorted = globals.languages.keys()
	languages_sorted.erase("Default")
	languages_sorted.sort()
	languages_sorted.push_front("Default")

	for language in languages_sorted:
		var lang_item = translation_tree.create_item(root)
		lang_item.set_metadata(0, {"type": "language", "language": language})
		lang_item.set_text(0, language)
		lang_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Normal"])

		var variants_sorted = globals.languages[language]["Variants"].keys()
		variants_sorted.erase("")
		variants_sorted.sort()
		variants_sorted.push_front("")

		for variant in variants_sorted:
			var combined = language + variant
			var var_item = translation_tree.create_item(lang_item)
			var_item.set_metadata(0, {"type": "variant", "language": language, "variant": variant, "combined": combined})
			var_item.set_text(0, "    " + combined)

			if line_variants.has(combined):
				var text = line_variants[combined].get("Text", "")
				if text == "":
					var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Caution"])
				else:
					var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Normal"])
			else:
				var_item.set_custom_color(0, globals.ui_colors[globals.selected_ui_colors]["Disabled"])

	_select_tree_item_by_combined(translation_tree, globals.current_translation)

	if globals.current_line < 0 or globals.current_line_type == "":
		translation_preview_raw.text = ""
		translation_preview_final.text = ""
		return
	elif not source.has(globals.current_conversation) or not source[globals.current_conversation].has(globals.current_block):
		translation_preview_raw.text = ""
		translation_preview_final.text = ""
		return

	lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line >= lines.size():
		translation_preview_raw.text = ""
		translation_preview_final.text = ""
		return

	line = lines[globals.current_line]
	line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type) and line_data.get("Commands", {}).has("Spoken Line"):
		line_data = line_data["Commands"]["Spoken Line"]
	if not line_data.has("Variants"):
		translation_preview_raw.text = ""
		translation_preview_final.text = ""
		return
	for entry in line_data["Variants"]:
		if entry.keys()[0] == globals.current_translation:
			var text = entry[globals.current_translation].get("Text", "")
			translation_preview_raw.text = text
			translation_preview_final.text = text
			return
	translation_preview_raw.text = ""
	translation_preview_final.text = ""


#* Select a translation variant in the tree:
func _on_translation_tree_item_selected() -> void:
	_reset_voice(false, true)
	globals.last_focused_field = null
	var item = translation_tree.get_selected()
	var meta = item.get_metadata(0)
	if meta["type"] != "variant":
		return
	globals.current_translation = meta["combined"]

	var source = _get_line_source()
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	var line_data = lines[globals.current_line][globals.current_line_type]
	if _is_condition_command(globals.current_line_type) and line_data.get("Commands", {}).has("Spoken Line"):
		line_data = line_data["Commands"]["Spoken Line"]

	for entry in line_data.get("Variants", []):
		if entry.keys()[0] == globals.current_translation:
			var text = entry[globals.current_translation].get("Text", "")
			translation_preview_raw.text = text
			translation_preview_final.text = text
			var direction = entry[globals.current_translation].get("Direction", "")
			var text_dir
			if direction.to_lower() == "rtl":
				text_dir = Control.TEXT_DIRECTION_RTL
			else:
				text_dir = Control.TEXT_DIRECTION_LTR
			translation_preview_raw.text_direction = text_dir
			translation_preview_final.text_direction = text_dir
			refresh_counters()
			save_undo_step()
			return

	translation_preview_raw.text = ""
	translation_preview_final.text = ""
	refresh_counters()
	if not _suppress_undo_save and not _updating_ui:
		save_undo_step()
	return


#* Walk a tree and visually select the item whose combined key matches the target:
func _select_tree_item_by_combined(tree: Tree, target: String) -> void:
	var root = tree.get_root()
	if not root:
		return
	var lang_item = root.get_first_child()
	while lang_item:
		var var_item = lang_item.get_first_child()
		while var_item:
			var meta = var_item.get_metadata(0)
			if meta.get("combined", "") == target:
				var_item.select(0)
				tree.scroll_to_item(var_item, true)
				return
			var_item = var_item.get_next()
		lang_item = lang_item.get_next()

#endregion


#?######################################################################################
#& WINDOW HANDLING:
#?#################
#region
#* Minimize button pressed:
func _on_minimize_pressed():
	#% Clear last focus:
	globals.last_focused_field = null

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


#* Windowed button pressed:
func _on_windowed_pressed():
	#% Clear last focus:
	globals.last_focused_field = null

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


#* Open exit confirmation prompt:
func _on_exit_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.unsaved_work == true:
		prompt_menu.setup("Quit")
	else:
		get_tree().quit()

#* Show or hide side-panel:
func _on_side_panel_button_pressed() -> void:
	if sidebar.visible == true:
		sidebar.visible = false
		side_button.text = "🞀\n🞀\n🞀"
	elif sidebar.visible == false:
		sidebar.visible = true
		side_button.text = "🞂\n🞂\n🞂"

#endregion


#?######################################################################################
#& DATA FILTERS:
#?##############
#region
func _on_toggle_translation_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.translate_area_visible == true:
		globals.translate_area_visible = false
		translation_area.visible = false
		translation_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.translate_area_visible = true
		translation_area.visible = true
		translation_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_toggle_portrait_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.portrait_area_visible == true:
		globals.portrait_area_visible = false
		portrait_file.visible = false
		portrait_box.visible = false
		portrait_play.visible = false
		portrait_play_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.portrait_area_visible = true
		portrait_file.visible = true
		portrait_box.visible = true
		portrait_play.visible = true
		portrait_play_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_toggle_voice_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.voice_area_visible == true:
		globals.voice_area_visible = false
		variant_voice_area.visible = false
		translation_voice_area.visible = false
		variant_voice_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.voice_area_visible = true
		variant_voice_area.visible = true
		translation_voice_area.visible = true
		variant_voice_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_toggle_disposition_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.disposition_area_visible == true:
		globals.disposition_area_visible = false
		disposition_field.visible = false
		disposition_field_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.disposition_area_visible = true
		disposition_field.visible = true
		disposition_field_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_toggle_tags_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.overrides_area_visible == true:
		globals.overrides_area_visible = false
		overrides_area.visible = false
		overrides_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.overrides_area_visible = true
		overrides_area.visible = true
		overrides_area_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]



func _on_choice_general_prompt_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_prompt_visible == true:
		globals.choice_general_prompt_visible = false
		choice_general_prompt.visible = false
		choice_general_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_prompt_visible = true
		choice_general_prompt.visible = true
		choice_general_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_general_mouse_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_mouse_visible == true:
		globals.choice_general_mouse_visible = false
		choice_general_mouse.visible = false
		choice_general_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_mouse_visible = true
		choice_general_mouse.visible = true
		choice_general_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_general_setup_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_setup_visible == true:
		globals.choice_general_setup_visible = false
		choice_general_setup.visible = false
		choice_general_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_setup_visible = true
		choice_general_setup.visible = true
		choice_general_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_general_scenes_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_scenes_visible == true:
		globals.choice_general_scenes_visible = false
		choice_general_self_scene.visible = false
		choice_general_category_scene.visible = false
		choice_general_item_scene.visible = false
		choice_general_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_scenes_visible = true
		choice_general_self_scene.visible = true
		choice_general_category_scene.visible = true
		choice_general_item_scene.visible = true
		choice_general_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_general_tags_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_tags_visible == true:
		globals.choice_general_tags_visible = false
		choice_general_tags.visible = false
		choice_general_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_tags_visible = true
		choice_general_tags.visible = true
		choice_general_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_general_custom_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_general_custom_visible == true:
		globals.choice_general_custom_visible = false
		choice_general_custom.visible = false
		choice_general_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_general_custom_visible = true
		choice_general_custom.visible = true
		choice_general_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


func _on_choice_categories_prompt_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_prompt_visible == true:
		globals.choice_category_prompt_visible = false
		choice_category_prompt.visible = false
		choice_category_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_prompt_visible = true
		choice_category_prompt.visible = true
		choice_category_prompt_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_categories_mouse_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_mouse_visible == true:
		globals.choice_category_mouse_visible = false
		choice_category_mouse.visible = false
		choice_category_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_mouse_visible = true
		choice_category_mouse.visible = true
		choice_category_mouse_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_categories_setup_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_setup_visible == true:
		globals.choice_category_setup_visible = false
		choice_category_setup.visible = false
		choice_category_setup.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_setup_visible = true
		choice_category_setup.visible = true
		choice_category_setup.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_categories_scenes_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_scenes_visible == true:
		globals.choice_category_scenes_visible = false
		choice_category_self_scene.visible = false
		choice_category_item_scene.visible = false
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_scenes_visible = true
		choice_category_self_scene.visible = true
		choice_category_item_scene.visible = true
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_categories_tags_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_tags_visible == true:
		globals.choice_category_tags_visible = false
		choice_category_prompt.visible = false
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_tags_visible = true
		choice_category_prompt.visible = true
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_categories_custom_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_category_custom_visible == true:
		globals.choice_category_custom_visible = false
		choice_category_prompt.visible = false
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_category_custom_visible = true
		choice_category_prompt.visible = true
		choice_category_prompt.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


func _on_choice_item_tooltip_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_item_tooltip_visible == true:
		globals.choice_item_tooltip_visible = false
		choice_item_tooltip.visible = false
		choice_item_tooltip_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_item_tooltip_visible = true
		choice_item_tooltip.visible = true
		choice_item_tooltip_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_item_setup_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_item_setup_visible == true:
		globals.choice_item_setup_visible = false
		choice_item_setup.visible = false
		choice_item_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_item_setup_visible = true
		choice_item_setup.visible = true
		choice_item_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_item_scene_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_item_scene_visible == true:
		globals.choice_item_scene_visible = false
		choice_item_self_scene.visible = false
		choice_item_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_item_scene_visible = true
		choice_item_self_scene.visible = true
		choice_item_scenes_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_item_tags_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_item_tags_visible == true:
		globals.choice_item_tags_visible = false
		choice_item_tags.visible = false
		choice_item_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_item_tags_visible = true
		choice_item_tags.visible = true
		choice_item_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_item_custom_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_item_custom_visible == true:
		globals.choice_item_custom_visible = false
		choice_item_custom.visible = false
		choice_item_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_item_custom_visible = true
		choice_item_custom.visible = true
		choice_item_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


func _on_choice_timers_setup_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_timer_setup_visible == true:
		globals.choice_timer_setup_visible = false
		choice_timer_setup.visible = false
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_timer_setup_visible = true
		choice_timer_setup.visible = true
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_timers_timeout_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_timer_timeout_visible == true:
		globals.choice_timer_timeout_visible = false
		choice_timer_setup.visible = false
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_timer_timeout_visible = true
		choice_timer_timeout.visible = true
		choice_timer_timeout_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_timers_tags_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_timer_tags_visible == true:
		globals.choice_timer_tags_visible = false
		choice_timer_setup.visible = false
		choice_timer_setup_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_timer_tags_visible = true
		choice_timer_tags.visible = true
		choice_timer_tags_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]

func _on_choice_timers_custom_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if globals.choice_timer_custom_visible == true:
		globals.choice_timer_custom_visible = false
		choice_timer_custom.visible = false
		choice_timer_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Disabled"]
	else:
		globals.choice_timer_custom_visible = true
		choice_timer_custom.visible = true
		choice_timer_custom_filter.self_modulate = globals.ui_colors[globals.selected_ui_colors]["Normal"]


#endregion


#?######################################################################################
#& SPOKEN LINES:
#?##############
#region
#* Called when spoken text is typed:
func _on_spoken_line_speech_text_changed() -> void:
	if _applying_undo_step:
		return
	var caret_line = spoken_text_edit.get_caret_line()
	var caret_column = spoken_text_edit.get_caret_column()
	var source = _get_line_source()

	var line = source[globals.current_conversation][globals.current_block]["Text"][globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has("Spoken Line"):
		line_data = line_data["Commands"]["Spoken Line"]
	for entry in line_data["Variants"]:
		if entry.keys()[0] == globals.current_variant:
			entry[globals.current_variant]["Text"] = spoken_text_edit.text
			break

	#% Update preview:
	spoken_text_preview.text = spoken_text_edit.text

	var saved_field = globals.last_focused_field
	_suppress_undo_save = true
	refresh_variant_tree()
	refresh_translation_tree()
	_suppress_undo_save = false
	globals.last_focused_field = saved_field

	#% Reposition caret:
	spoken_text_edit.set_caret_line(caret_line)
	spoken_text_edit.set_caret_column(caret_column)

	refresh_counters()


#* Mark as last focused:
func _on_spoken_text_edit_focus_entered(source) -> void:
	if _applying_undo_step:
		return
	globals.original_data = spoken_text_edit.text
	globals.last_focused_field = source


#* Focus exited:
func _on_spoken_text_edit_focus_exited(source) -> void:
	if globals.last_focused_field == source and source.text != globals.original_data and not _applying_undo_step:
		globals.original_data = ""
		save_undo_step()
		update_line_list()


#* Refresh character/word/limit counters:
func refresh_counters() -> void:
	var variant_text = strip_bbcode(_get_variant_text(globals.current_variant))
	var translation_text = strip_bbcode(_get_variant_text(globals.current_translation))

	var v_chars = variant_text.length()
	var v_words = variant_text.split(" ", false).size() if variant_text != "" else 0
	var t_chars = translation_text.length()
	var t_words = translation_text.split(" ", false).size() if translation_text != "" else 0

	variant_characters.text = str(v_chars)
	variant_words.text = str(v_words)
	variant_limit.text = _limit_bbcode(v_chars)

	translation_characters.text = str(t_chars)
	translation_words.text = str(t_words)

	var char_diff = t_chars - v_chars
	var word_diff = t_words - v_words
	translation_character_difference.text = ("+" if char_diff >= 0 else "") + str(char_diff)
	translation_word_difference.text = ("+" if word_diff >= 0 else "") + str(word_diff)


#* Get the text for the variant/transaltion:
func _get_variant_text(combined: String) -> String:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return ""
	if not source[globals.current_conversation].has(globals.current_block):
		return ""
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return ""
	var line = lines[globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type) and line_data.has("Commands") and line_data["Commands"].has("Spoken Line"):
		line_data = line_data["Commands"]["Spoken Line"]
	if not line_data.has("Variants"):
		return ""
	for entry in line_data["Variants"]:
		if entry.keys()[0] == combined:
			return entry[combined].get("Text", "")
	return ""


#* Color the limit numbers:
func _limit_bbcode(char_count: int) -> String:
	var limit = int(globals.spoken_text_limit)
	var margin = int(globals.limit_margin)
	var diff = char_count - limit
	var diff_str = ("+" if diff >= 0 else "") + str(diff)
	if char_count > limit:
		return "[color=red]" + diff_str + "[/color]"
	elif char_count > limit - margin:
		return "[color=yellow]" + diff_str + "[/color]"
	else:
		return "[color=green]" + diff_str + "[/color]"


#* Display the speaker's portrait in the portrait box:
func refresh_portrait_display() -> void:
	_clear_portrait_display()
	if globals.current_line_type != "Spoken Line" and not _is_condition_command(globals.current_line_type):
		return
	var source = _get_line_source()
	if not source.has(globals.current_conversation) or \
	   not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type):
		if not line_data.has("Commands") or not line_data["Commands"].has("Spoken Line"):
			return
		line_data = line_data["Commands"]["Spoken Line"]
	var reference = line_data.get("Reference", "")
	var speaker_portrait_file = line_data.get("Portrait", "")
	if reference == "" or speaker_portrait_file == "":
		return
	if not globals.project_resources["*Portraits"].has(reference):
		return
	var char_folder = globals.project_resources["*Portraits"][reference]

	#@ Sprite_Frames animation:
	if char_folder.has("Sprite_Frames"):
		var sf_folder = char_folder["Sprite_Frames"]
		for sf_name in sf_folder.keys():
			var sf_path = sf_folder[sf_name]
			if sf_path is String and FileAccess.file_exists(sf_path):
				var tres_file = FileAccess.open(sf_path, FileAccess.READ)
				if tres_file:
					var content = tres_file.get_as_text()
					tres_file.close()
					var anim_regex = RegEx.new()
					anim_regex.compile('"name":\\s*&?"([^"]+)"')
					for result in anim_regex.search_all(content):
						if result.get_string(1) == speaker_portrait_file:
							var res = ResourceLoader.load(sf_path)
							if res:
								portrait_animated_sprite.sprite_frames = res
								portrait_animated_sprite.animation = speaker_portrait_file
								portrait_animated_sprite.playing = false
								portrait_animated_sprite.frame = 0
								portrait_animated_sprite.visible = true
							return

	#@ Animated folder:
	if char_folder.has("Animated") and char_folder["Animated"].has(speaker_portrait_file):
		var anim_folder = char_folder["Animated"][speaker_portrait_file]
		if anim_folder is Dictionary:
			var frames = []
			for fname in anim_folder.keys():
				var fpath = anim_folder[fname]
				if fpath is String and FileAccess.file_exists(fpath):
					var img = Image.new()
					if img.load(fpath) == OK:
						frames.append(ImageTexture.create_from_image(img))
			if not frames.is_empty():
				portrait_display.texture = frames[0]
				portrait_display.visible = true
		return

	#@ Direct file:
	if char_folder.has(speaker_portrait_file):
		var file_path = char_folder[speaker_portrait_file]
		if file_path is String and FileAccess.file_exists(file_path):
			var ext = speaker_portrait_file.get_extension().to_lower()

			#% Video:
			if ext == "ogv":
				var stream = VideoStreamTheora.new()
				stream.file = file_path
				portrait_video.stream = stream
				portrait_video.paused = true
				portrait_video.play()
				portrait_video.stream_position = 0.0
				portrait_video.visible = true
				return

			#% Sprite sheet:
			var img
			var sprite_regex = RegEx.new()
			sprite_regex.compile("_(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
			var sprite_match = sprite_regex.search(speaker_portrait_file)
			if sprite_match:
				img = Image.new()
				if img.load(file_path) == OK:
					var tex = ImageTexture.create_from_image(img)
					portrait_sprite.texture = tex
					var cols = sprite_match.get_string(1).to_int()
					var rows = sprite_match.get_string(2).to_int()
					var missing = sprite_match.get_string(3).to_int() if sprite_match.get_string(3) != "" else 0
					_portrait_sprite_total_frames = cols * rows - missing
					portrait_sprite.hframes = cols
					portrait_sprite.vframes = rows
					portrait_sprite.frame = 0
					var frame_width = float(portrait_sprite.texture.get_width()) / cols
					var frame_height = float(portrait_sprite.texture.get_height()) / rows
					var scale_x = 192.0 / frame_width
					var scale_y = 192.0 / frame_height
					var scale_factor = min(scale_x, scale_y)
					portrait_sprite.scale = Vector2(scale_factor, scale_factor)
					portrait_sprite.visible = true
				return

			#% Regular image:
			img = Image.new()
			if img.load(file_path) == OK:
				portrait_display.texture = ImageTexture.create_from_image(img)
				portrait_display.visible = true


#* Clear portrait display:
func _clear_portrait_display() -> void:
	portrait_display.texture = null
	portrait_video.stop()
	portrait_video.stream = null
	portrait_sprite.texture = null
	portrait_animated_sprite.sprite_frames = null


func _on_portrait_display_mouse_entered() -> void:
	if portrait_video.stream != null:
		portrait_video.paused = false
	elif portrait_animated_sprite.sprite_frames != null:
		portrait_animated_sprite.play()
	elif portrait_sprite.texture != null:
		_animate_portrait_sprite(_portrait_sprite_total_frames)


func _on_portrait_display_mouse_exited() -> void:
	portrait_video.paused = true
	portrait_video.stream_position = 0.0
	portrait_animated_sprite.stop()
	portrait_animated_sprite.frame = 0
	portrait_sprite.frame = 0
	globals.sprite_preview_cancelled = true


func _animate_portrait_sprite(total_frames: int) -> void:
	globals.sprite_preview_cancelled = false
	while not globals.sprite_preview_cancelled:
		for i in range(total_frames):
			if globals.sprite_preview_cancelled:
				return
			portrait_sprite.frame = i
			await get_tree().create_timer(1.0 / globals.portrait_sprite_fps).timeout


func _on_spoken_voice_play_button_pressed() -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation) or \
	   not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type):
		if not line_data.has("Commands") or not line_data["Commands"].has("Spoken Line"):
			return
		line_data = line_data["Commands"]["Spoken Line"]
	var reference = line_data.get("Reference", "")
	var voice_file = line_data.get("Voice", "")
	if reference == "" or voice_file == "":
		return

	#@ Pause translation if playing:
	if translation_voice_player.playing and not translation_voice_player.stream_paused:
		translation_voice_player.stream_paused = true

	#@ If already playing, toggle pause:
	if variant_voice_player.stream != null and variant_voice_player.playing:
		variant_voice_player.stream_paused = not variant_voice_player.stream_paused
		return

	#@ Find the file path:
	if not globals.project_resources["*Voice_Files"].has(reference):
		return
	var char_folder = globals.project_resources["*Voice_Files"][reference]
	if not char_folder.has(globals.current_conversation):
		return
	var conv_folder = char_folder[globals.current_conversation]
	if not conv_folder.has(globals.current_block):
		return
	var block_folder = conv_folder[globals.current_block]

	#@ Check variant subfolder if not Default:
	if globals.current_variant != "Default":
		if not block_folder.has(globals.current_variant):
			return
		block_folder = block_folder[globals.current_variant]
	if not block_folder.has(voice_file):
		return
	var file_path = block_folder[voice_file]

	#@ Load and play:
	var stream = _load_audio_stream(file_path)
	if stream == null:
		return
	variant_voice_player.stream = stream
	variant_voice_player.volume_db = linear_to_db(variant_volume_slider.value)
	variant_voice_player.play()


func _on_translation_voice_play_button_pressed() -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation) or \
	   not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_data = line[globals.current_line_type]
	if _is_condition_command(globals.current_line_type):
		if not line_data.has("Commands") or not line_data["Commands"].has("Spoken Line"):
			return
		line_data = line_data["Commands"]["Spoken Line"]
	var reference = line_data.get("Reference", "")
	var voice_file = line_data.get("Voice", "")
	if reference == "" or voice_file == "":
		return
	#@ Pause variant if playing:
	if variant_voice_player.playing and not variant_voice_player.stream_paused:
		variant_voice_player.stream_paused = true
	#@ If already playing, toggle pause:
	if translation_voice_player.stream != null and translation_voice_player.playing:
		translation_voice_player.stream_paused = not translation_voice_player.stream_paused
		return
	#@ Find the file path:
	if not globals.project_resources["*Voice_Files"].has(reference):
		return
	var char_folder = globals.project_resources["*Voice_Files"][reference]
	if not char_folder.has(globals.current_conversation):
		return
	var conv_folder = char_folder[globals.current_conversation]
	if not conv_folder.has(globals.current_block):
		return
	var block_folder = conv_folder[globals.current_block]
	#@ Check translation subfolder if not Default:
	if globals.current_translation != "Default":
		if not block_folder.has(globals.current_translation):
			return
		block_folder = block_folder[globals.current_translation]
	if not block_folder.has(voice_file):
		return
	var file_path = block_folder[voice_file]
	#@ Load and play:
	var stream = _load_audio_stream(file_path)
	if stream == null:
		return
	translation_voice_player.stream = stream
	translation_voice_player.volume_db = linear_to_db(translation_volume_slider.value)
	translation_voice_player.play()


func _on_variant_volume_slider_value_changed(value: float) -> void:
	variant_voice_player.volume_db = linear_to_db(value)


func _on_translation_volume_slider_value_changed(value: float) -> void:
	translation_voice_player.volume_db = linear_to_db(value)

func _on_variant_progress_slider_value_changed(value: float) -> void:
	if variant_voice_player.stream != null:
		var length = variant_voice_player.stream.get_length()
		variant_voice_player.seek(value * length)

func _on_translation_progress_slider_value_changed(value: float) -> void:
	if translation_voice_player.stream != null:
		var length = translation_voice_player.stream.get_length()
		translation_voice_player.seek(value * length)

#* Load audio file in audio player:
func _load_audio_stream(path: String) -> AudioStream:
	var ext = path.get_extension().to_lower()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var buffer = file.get_buffer(file.get_length())
	file.close()
	match ext:
		"mp3":
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			return stream
		"ogg":
			var stream = AudioStreamOggVorbis.load_from_buffer(buffer)
			return stream
		"wav":
			var stream = AudioStreamWAV.new()
			stream.data = buffer
			return stream
	return null

func _reset_voice(reset_variant: bool, reset_translation: bool) -> void:
	if reset_variant == true:
		variant_voice_player.stop()
		variant_voice_player.stream = null
		variant_translation_volume_slider.value = 0.0

	if reset_translation == true:
		translation_voice_player.stop()
		translation_voice_player.stream = null
		translation_progress_slider.value = 0.0


func _on_preview_bg_color_color_changed(color: Color) -> void:
	spoken_text_preview_bg.color = color
	translation_preview_raw_bg.color = color
	translation_preview_final_bg.color = color
	globals.preview_bg_color = color

func _on_preview_text_color_color_changed(color: Color) -> void:
	spoken_text_preview.add_theme_color_override("default_color", color)
	translation_preview_raw.add_theme_color_override("default_color", color)
	translation_preview_final.add_theme_color_override("default_color", color)
	globals.preview_text_color = color

func _on_portrait_bg_color_color_changed(color: Color) -> void:
	globals.preview_portrait_color = color

func _on_portrait_button_pressed() -> void:
	portrait_bg.get_popup().popup()


#endregion


#?######################################################################################
#& CHOICES:
#?#########
#region
func refresh_choice_tree() -> void:
	choice_tree.clear()
	choice_tree.columns = 1
	var root = choice_tree.create_item()
	choice_tree.hide_root = true
	choice_tree.hide_folding = false

	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	var data = {}
	if _is_condition_command(line_type):
		if not line[line_type].has("Commands") or not line[line_type]["Commands"].has("§Choice_List"):
			return
		data = line[line_type]["Commands"]["§Choice_List"]
	else:
		if not line.has("§Choice_List"):
			return
		data = line["§Choice_List"]

	#@ Timers:
	for timer_entry in data.get("Timers", []):
		var timer_name = timer_entry.keys()[0]
		var timer_item = choice_tree.create_item(root)
		timer_item.set_text(0, timer_name)
		timer_item.set_custom_color(0, Color.YELLOW)
		timer_item.set_metadata(0, {"type": "timer", "name": timer_name})

	#@ Categories and choices:
	for category_entry in data.get("Categories", []):
		var category_name = category_entry.keys()[0]
		var category_data = category_entry[category_name]
		var category_item = choice_tree.create_item(root)
		category_item.set_text(0, category_name)
		category_item.set_custom_color(0, Color.CORNFLOWER_BLUE)
		category_item.set_metadata(0, {"type": "category", "name": category_name})

		for choice_entry in category_data.get("Choices", []):
			var choice_name = choice_entry.keys()[0]
			var choice_item = choice_tree.create_item(category_item)
			choice_item.set_text(0, choice_name)
			choice_item.set_metadata(0, {"type": "choice", "name": choice_name, "category": category_name})


#* Category/Choice/Timer selected in the tree:
func _on_choice_tree_item_selected() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	var item = choice_tree.get_selected()
	if item == null:
		return
	globals.selected_choice_item = item
	_on_choice_item_changed()
	save_undo_step()


func _on_choice_item_changed() -> void:
	if globals.selected_choice_item == null:
		return
	var meta = globals.selected_choice_item.get_metadata(0)
	match meta["type"]:
		"timer":
			globals.current_choice_category = ""
			globals.current_choice_item = ""
			globals.current_choice_timer = meta["name"]
			_show_timer_data(meta["name"])
		"category":
			globals.current_choice_category = meta["name"]
			globals.current_choice_item = ""
			globals.current_choice_timer = ""
			_show_category_data(meta["name"])
		"choice":
			globals.current_choice_category = meta["category"]
			globals.current_choice_item = meta["name"]
			globals.current_choice_timer = ""
			_show_choice_data(meta["category"], meta["name"])


func _show_timer_data(_timer):
	choice_category_settings.visible = false
	choice_item_settings.visible = false
	choice_timer_settings.visible = true
	for data_field in line_data_fields["§Choice_List"]:
		line_data_fields["§Choice_List"][data_field].data_load()

func _show_category_data(_category):
	choice_category_settings.visible = true
	choice_item_settings.visible = false
	choice_timer_settings.visible = false
	for data_field in line_data_fields["§Choice_List"]:
		line_data_fields["§Choice_List"][data_field].data_load()

func _show_choice_data(category, _choice):
	choice_category_settings.visible = true
	choice_timer_settings.visible = false
	_show_category_data(category)
	choice_item_settings.visible = true

func _hide_all_choice_data():
	choice_category_settings.visible = false
	choice_item_settings.visible = false
	choice_timer_settings.visible = false


#* Right click item in choice tree:
func _on_choice_tree_item_mouse_button(_item: TreeItem, _column: int, button: int, pressed: bool) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	if button != MOUSE_BUTTON_RIGHT or not pressed:
		return
	choice_tree_context_menu.clear()
	choice_tree_context_menu.add_item("Rename", 0)
	choice_tree_context_menu.add_item("Delete", 1)
	choice_tree_context_menu.position = Vector2i(get_viewport().get_mouse_position())
	choice_tree_context_menu.popup()


#* Select from context menu:
func _on_choice_tree_context_menu_id_pressed(id: int) -> void:
	var item = choice_tree.get_selected()
	if item == null:
		return
	var meta = item.get_metadata(0)
	match id:
		0: #% Rename
			match meta["type"]:
				"timer":
					prompt_menu.setup("Rename Choice Timer")
				"category":
					prompt_menu.setup("Rename Choice Category")
				"choice":
					prompt_menu.setup("Rename Choice Item")
		1: #% Delete
			match meta["type"]:
				"timer":
					_delete_choice_timer(meta["name"])
				"category":
					_delete_choice_category(meta["name"])
				"choice":
					_delete_choice_item(meta["category"], meta["name"])


#* Rename category:
func _rename_choice_category(new_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for i in range(data["Categories"].size()):
		if data["Categories"][i].keys()[0] == globals.current_choice_category:
			var category_data = data["Categories"][i][globals.current_choice_category]
			data["Categories"][i].erase(globals.current_choice_category)
			data["Categories"][i][new_name] = category_data
			globals.current_choice_category = new_name
			break
	refresh_choice_tree()

#* Rename choice:
func _rename_choice_item(new_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for category_entry in data["Categories"]:
		if category_entry.keys()[0] == globals.current_choice_category:
			var choices = category_entry[globals.current_choice_category]["Choices"]
			for i in range(choices.size()):
				if choices[i].keys()[0] == globals.current_choice_item:
					var choice_data = choices[i][globals.current_choice_item]
					choices[i].erase(globals.current_choice_item)
					choices[i][new_name] = choice_data
					globals.current_choice_item = new_name
					break
			break
	refresh_choice_tree()

#* Rename timer:
func _rename_choice_timer(new_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for i in range(data["Timers"].size()):
		if data["Timers"][i].keys()[0] == globals.current_choice_timer:
			var timer_data = data["Timers"][i][globals.current_choice_timer]
			data["Timers"][i].erase(globals.current_choice_timer)
			data["Timers"][i][new_name] = timer_data
			globals.current_choice_timer = new_name
			break
	refresh_choice_tree()


#* Delete timer:
func _delete_choice_timer(timer_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for i in range(data["Timers"].size()):
		if data["Timers"][i].keys()[0] == timer_name:
			data["Timers"].remove_at(i)
			break
	if globals.current_choice_timer == timer_name:
		globals.current_choice_timer = ""
		_hide_all_choice_data()
	refresh_choice_tree()


#* Delete category:
func _delete_choice_category(category_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for i in range(data["Categories"].size()):
		if data["Categories"][i].keys()[0] == category_name:
			data["Categories"].remove_at(i)
			break
	if globals.current_choice_category == category_name:
		globals.current_choice_category = ""
		globals.current_choice_item = ""
		_hide_all_choice_data()
	refresh_choice_tree()


#* Delete choice:
func _delete_choice_item(category_name: String, choice_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for category_entry in data["Categories"]:
		if category_entry.keys()[0] == category_name:
			var choices = category_entry[category_name]["Choices"]
			for i in range(choices.size()):
				if choices[i].keys()[0] == choice_name:
					choices.remove_at(i)
					break
			break
	if globals.current_choice_category == category_name and globals.current_choice_item == choice_name:
		globals.current_choice_item = ""
		_show_category_data(category_name)
	refresh_choice_tree()


func _get_drag_data_fw(drag_position: Vector2, _from_node: Node) -> Variant:
	var item = choice_tree.get_item_at_position(drag_position)
	if item == null:
		return null
	var meta = item.get_metadata(0)
	if meta["type"] != "choice":
		return null
	return {"choice": meta["name"], "category": meta["category"]}


func _can_drop_data_fw(drop_position: Vector2, data: Variant, _from_node: Node) -> bool:
	if not data is Dictionary or not data.has("choice"):
		return false
	var target = choice_tree.get_item_at_position(drop_position)
	if target == null:
		return false
	var meta = target.get_metadata(0)
	return meta["type"] == "choice" or meta["type"] == "category"


func _drop_data_fw(drop_position: Vector2, data: Variant, _from_node: Node) -> void:
	var target = choice_tree.get_item_at_position(drop_position)
	if target == null:
		return
	var target_meta = target.get_metadata(0)
	var source_choice = data["choice"]
	var source_category = data["category"]
	var target_category = target_meta["name"] if target_meta["type"] == "category" else target_meta["category"]

	var line_data = _get_choice_list_data()
	if line_data.is_empty():
		return

	#@ Find and remove from source category:
	var choice_data = null
	for category_entry in line_data["Categories"]:
		if category_entry.keys()[0] == source_category:
			var choices = category_entry[source_category]["Choices"]
			for i in range(choices.size()):
				if choices[i].keys()[0] == source_choice:
					choice_data = choices[i]
					choices.remove_at(i)
					break
			break

	if choice_data == null:
		return

	#@ Resolve name conflict in target category:
	var final_name = source_choice
	for category_entry in line_data["Categories"]:
		if category_entry.keys()[0] == target_category:
			var existing_names = []
			for c in category_entry[target_category]["Choices"]:
				existing_names.append(c.keys()[0])
			if existing_names.has(final_name):
				var suffix = 1
				while existing_names.has(final_name + "_(" + str(suffix) + ")"):
					suffix += 1
				var old_data = choice_data[source_choice]
				choice_data.erase(source_choice)
				final_name = source_choice + "_(" + str(suffix) + ")"
				choice_data[final_name] = old_data

			#@ Insert at target position:
			var target_index = category_entry[target_category]["Choices"].size()
			if target_meta["type"] == "choice" and target_meta["category"] == target_category:
				for i in range(category_entry[target_category]["Choices"].size()):
					if category_entry[target_category]["Choices"][i].keys()[0] == target_meta["name"]:
						target_index = i
						break
			category_entry[target_category]["Choices"].insert(target_index, choice_data)
			break

	refresh_choice_tree()


func _get_choice_list_data() -> Dictionary:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return {}
	if not source[globals.current_conversation].has(globals.current_block):
		return {}
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return {}
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	if _is_condition_command(line_type):
		if not line[line_type].has("Commands") or not line[line_type]["Commands"].has("§Choice_List"):
			return {}
		return line[line_type]["Commands"]["§Choice_List"]
	if not line.has("§Choice_List"):
		return {}
	return line["§Choice_List"]




func _on_add_choice_category_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	prompt_menu.setup("New Choice Category")

func _on_add_choice_item_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	prompt_menu.setup("New Choice Item")

func _on_add_choice_timer_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	prompt_menu.setup("New Choice Timer")


func _add_choice_timer(timer_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	data["Timers"].append({
		timer_name: {
			"Display": "",
			"Tags": "",
			"Time": "0",
			"Auto": "Start",
			"Loop": "1",
			"Setup": {
				"Type": "Bridge",
				"Conversation": "",
				"Block": "",
				"Line": "",
			},
			"Timeout": {
				"Type": "Bridge",
				"Conversation": "",
				"Block": "",
				"Line": "",
			},
			"Timer Choices": "",
			"Custom": "",
		}
	})
	refresh_choice_tree()


func _add_choice_category(category_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	data["Categories"].append({
		category_name: {
			"Title": "",
			"Mouse": "Default",
			"Tags": "",
			"Prompt": "",
			"Category Scene": "",
			"Button Scene": "",
			"Setup": {
				"Type": "Bridge",
				"Conversation": "",
				"Block": "",
				"Line": "",
			},
			"Custom": "",
			"Choices": [],
		}
	})
	refresh_choice_tree()


func _add_choice_item(choice_name: String) -> void:
	var data = _get_choice_list_data()
	if data.is_empty():
		return
	for category_entry in data["Categories"]:
		if category_entry.keys()[0] == globals.current_choice_category:
			category_entry[globals.current_choice_category]["Choices"].append({
				choice_name: {
					"Button Scene": "",
					"Setup": {
						"Type": "Bridge",
						"Conversation": "",
						"Block": "",
						"Line": "",
					},
					"Label": "",
					"Tags": "",
					"Tooltip": "",
					"Enabled": "1",
					"Active": "1",
					"Invisible": "0",
					"Navigate": "",
					"Finish": {
						"Type": "Continue",
						"Conversation": "",
						"Block": "",
						"Line": "",
					},
					"Custom": "",
				}
			})
			break
	refresh_choice_tree()

#endregion


#?######################################################################################
#& OTHER COMMANDS:
#?################
#region
func _on_comment_color_color_changed(color: Color) -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation) or \
	   not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	line[line_type]["Color"] = var_to_str(color)
	update_line_list()

#endregion


#?######################################################################################
#& INSERTS:
#?#########
#region
#* Update the tools color labels when a color is chosen:
func _on_tools_color_picker_color_changed(color: Color) -> void:
	var hex = color.to_html(true)
	match globals.tools_color_mode:
		"BBCode":
			tools_hex_color.text = "[color=\u0023" + hex + "][/color]"
			tools_rgb_color.text = "[color=rgba(%d,%d,%d,%d)][/color]" % [
				int(color.r * 255), int(color.g * 255),
				int(color.b * 255), int(color.a * 255)]
		"Color()":
			tools_hex_color.text = "Color(\u0022\u0023" + hex + "\u0022)"
			tools_rgb_color.text = "Color(%s, %s, %s, %s)" % [
				str(snappedf(color.r, 0.001)), str(snappedf(color.g, 0.001)),
				str(snappedf(color.b, 0.001)), str(snappedf(color.a, 0.001))]
		"Code":
			tools_hex_color.text = "\u0023" + hex
			tools_rgb_color.text = "%d, %d, %d, %d" % [
				int(color.r * 255), int(color.g * 255),
				int(color.b * 255), int(color.a * 255)]


#* Change the color code display mode:
func _on_tools_color_mode_pressed() -> void:
	match globals.tools_color_mode:
		"BBCode":
			globals.tools_color_mode = "Color()"
			tools_color_mode.text = "Color()"
		"Color()":
			globals.tools_color_mode = "Code"
			tools_color_mode.text = "Code"
		"Code":
			globals.tools_color_mode = "BBCode"
			tools_color_mode.text = "BBCode"

	#% Refresh the labels:
	_on_tools_color_picker_color_changed(tools_color_picker.color)


#* Insert the hex tools color at the caret:
func _on_tools_color_hex_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var color = tools_color_picker.color
	var hex = color.to_html(true)
	var before := ""
	var after := ""
	match globals.tools_color_mode:
		"BBCode":
			before = "[color=\u0023" + hex + "]"
			after = "[/color]"
		"Color()":
			before = "Color(\"\u0023" + hex + "\")"
		"Code":
			before = "\u0023" + hex

	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + before + mid + after + txt.substr(to)
			e.set_caret_column(from + before.length())
		else:
			e.text = txt.substr(0, from) + before + after + txt.substr(from)
			e.set_caret_column(from + before.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(before + sel_text + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(before + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


#* Copy the hex tools color to the clipboard:
func _on_tools_color_hex_copy_pressed() -> void:
	DisplayServer.clipboard_set(tools_hex_color.text)


#* Insert the RGB tools color at the caret:
func _on_tools_color_rgb_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var color = tools_color_picker.color
	var before := ""
	var after := ""
	match globals.tools_color_mode:
		"BBCode":
			before = "[color=rgba(%d,%d,%d,%d)]" % [int(color.r * 255), int(color.g * 255), int(color.b * 255), int(color.a * 255)]
			after = "[/color]"
		"Color()":
			before = "Color(%s, %s, %s, %s)" % [str(snappedf(color.r, 0.001)), str(snappedf(color.g, 0.001)), str(snappedf(color.b, 0.001)), str(snappedf(color.a, 0.001))]
		"Code":
			before = "%d, %d, %d, %d" % [int(color.r * 255), int(color.g * 255), int(color.b * 255), int(color.a * 255)]

	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + before + mid + after + txt.substr(to)
			e.set_caret_column(from + before.length())
		else:
			e.text = txt.substr(0, from) + before + after + txt.substr(from)
			e.set_caret_column(from + before.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(before + sel_text + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(before + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


#* Copy the RGB tools color to the clipboard:
func _on_tools_color_rgb_copy_pressed() -> void:
	DisplayServer.clipboard_set(tools_rgb_color.text)


#* Insert •¦•:
func _on_substitution_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.substitution_symbol
	var sep = globals.separator_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			if " " in mid:
				mid = mid.replace(" ", sep)
				e.text = txt.substr(0, from) + sym + mid + sym + txt.substr(to)
			else:
				e.text = txt.substr(0, from) + sym + mid + sep + sym + txt.substr(to)
			e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			if " " in sel_text:
				sel_text = sel_text.replace(" ", sep)
				e.insert_text_at_caret(sym + sel_text + sym)
			else:
				e.insert_text_at_caret(sym + sel_text + sep + sym)
			e.set_caret_column(e.get_caret_column() - sym.length())
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_text_var_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var before = globals.text_var_symbol_start
	var after = globals.text_var_symbol_end
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + before + mid + after + txt.substr(to)
			e.set_caret_column(from + before.length())
		else:
			e.text = txt.substr(0, from) + before + after + txt.substr(from)
			e.set_caret_column(from + before.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(before + sel_text + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(before + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_role_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.role_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_singleton_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.singleton_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_node_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.node_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_var_dict_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.vardict_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_super_singleton_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.super_singleton_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_super_node_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.super_node_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_super_var_dict_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = globals.super_vardict_symbol
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()

func _on_res_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = "res://"
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_user_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = "user://"
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_v_res_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = "v_res://"
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


func _on_v_user_insert_pressed() -> void:
	if globals.last_focused_field == null:
		return
	
	_suppress_undo_save = true
	var sym = "v_user://"
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + sym + mid + txt.substr(to)
		else:
			e.text = txt.substr(0, from) + sym + txt.substr(from)
		e.set_caret_column(from + sym.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(sym + sel_text)
			e.set_caret_column(e.get_caret_column())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(sym)
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


#* Generic/Multipurpose BBCode insert function:
func bbcode_insert(tag: String) -> void:
	if globals.last_focused_field == null:
		return

	#@ Determine before/after strings based on tag:
	var before := ""
	var after := ""
	match tag:
		"bold":
			before = "[b]"
			after = "[/b]"
		"italic":
			before = "[i]"
			after = "[/i]"
		"underline":
			before = "[u]"
			after = "[/u]"
		"strikethrough":
			before = "[s]"
			after = "[/s]"

		"center":
			before = "[center]"
			after = "[/center]"
		"left":
			before = "[left]"
			after = "[/left]"
		"right":
			before = "[right]"
			after = "[/right]"
		"fill":
			before = "[fill]"
			after = "[/fill]"

		"wave":
			before = "[wave]"
			after = "[/wave]"
		"shake":
			before = "[shake]"
			after = "[/shake]"
		"tornado":
			before = "[tornado]"
			after = "[/tornado]"
		"fade":
			before = "[fade]"
			after = "[/fade]"
		"rainbow":
			before = "[rainbow]"
			after = "[/rainbow]"
		"pulse":
			before = "[pulse]"
			after = "[/pulse]"

		"char":
			before = "[char]"
		"break":
			before = "[br]"
		"h_line":
			before = "[hr]"

		"code":
			before = "[code]"
			after = "[/code]"
		"indent":
			before = "[indent]"
			after = "[/indent]"
		"paragraph":
			before = "[p]"
			after = "[/p]"

		"font":
			before = "[font=]"
			after = "[/font]"
		"font_size":
			before = "[font_size=]"
			after = "[/font_size]"
		"outline_size":
			before = "[outline_size=]"
			after = "[/outline_size]"

		"bg_color":
			before = "[bgcolor=]"
			after = "[/bgcolor]"
		"fg_color":
			before = "[fgcolor=]"
			after = "[/fgcolor]"
		"outline_color":
			before = "[outline_color=]"
			after = "[/outline_color]"

		"hint":
			before = "[hint=]"
			after = "[/hint]"
		"url":
			before = "[url=]"
			after = "[/url]"
		"image":
			before = "[img=]"
			after = "[/img]"

		"lb":
			before = "[lb]"
		"rb":
			before = "[rb]"
		"u_list":
			before = "[ul]"
			after = "[/ul]"
		"o_list":
			before = "[ol]"
			after = "[/ol]"
		"table":
			before = "[table=]"
			after = "[/table]"
		"cell":
			before = "[cell]"
			after = "[/cell]"
		_:
			return

	#@ Insert before/after around selection or at caret:
	_suppress_undo_save = true
	var target = globals.last_focused_field
	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + before + mid + after + txt.substr(to)
			e.set_caret_column(from + before.length())
		else:
			e.text = txt.substr(0, from) + before + after + txt.substr(from)
			e.set_caret_column(from + before.length())
		e.grab_focus()
	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(before + sel_text + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(before + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		e.end_complex_operation()
		e.grab_focus()
	_suppress_undo_save = false
	#% Manually sync to dialogue data:
	_on_spoken_line_speech_text_changed()
	save_undo_step()


#* Update the text of the symbol insert buttons to reflect actual symbols:
func update_variable_insert_buttons():
	role_insert_button.text = globals.role_symbol
	singleton_insert_button = globals.singleton_symbol
	node_insert_button.text = globals.node_symbol
	vardict_insert_button.text = globals.vardict_symbol
	super_singleton_insert_button.text = globals.super_singleton_symbol
	super_node_insert_button.text = globals.super_node_symbol
	super_vardict_insert_button.text = globals.super_vardict_symbol


#* Open menu to create new insert:
func _on_new_insert_pressed() -> void:
	#% Clear last focus:
	globals.last_focused_field = null

	insert_menu.visible = true
	insert_menu.setup("New", "", "")


func refresh_insert_lists() -> void:
	#@ Clear existing lists:
	for child in user_inserts_list.get_children():
		child.queue_free()
	for child in profile_inserts_list.get_children():
		child.queue_free()

	#@ Populate user inserts list:
	for category in globals.user_inserts:
		var folder = FoldableContainer.new()
		folder.title = category
		user_inserts_list.add_child(folder)
		var grid = GridContainer.new()
		grid.columns = 2
		folder.add_child(grid)
		for insert in globals.user_inserts[category]:
			var button = Button.new()
			button.text = insert
			button.pressed.connect(_on_insert_button_pressed.bind(insert, globals.user_inserts[category]))
			button.gui_input.connect(_on_insert_button_gui_input.bind(insert, category, globals.user_inserts))
			button.mouse_entered.connect(_store_selection)
			grid.add_child(button)

	#@ Populate profile inserts list:
	for category in globals.profile_inserts:
		var folder = FoldableContainer.new()
		folder.title = category
		profile_inserts_list.add_child(folder)
		var grid = GridContainer.new()
		grid.columns = 2
		folder.add_child(grid)
		for insert in globals.profile_inserts[category]:
			var button = Button.new()
			button.text = insert
			button.pressed.connect(_on_insert_button_pressed.bind(insert, globals.profile_inserts[category]))
			button.gui_input.connect(_on_insert_button_gui_input.bind(insert, category, globals.profile_inserts))
			button.mouse_entered.connect(_store_selection)
			grid.add_child(button)


#* Store references to the selected text in data fields:
func _store_selection() -> void:
	if globals.last_focused_field == null:
		return
	var target = globals.last_focused_field
	if target is LineEdit:
		globals.last_selection_from = target.get_selection_from_column() if target.has_selection() else target.get_caret_column()
		globals.last_selection_to = target.get_selection_to_column() if target.has_selection() else target.get_caret_column()
	elif target is TextEdit:
		globals.last_selection_from_line = target.get_selection_from_line() if target.has_selection() else target.get_caret_line()
		globals.last_selection_from_col = target.get_selection_from_column() if target.has_selection() else target.get_caret_column()
		globals.last_selection_to_line = target.get_selection_to_line() if target.has_selection() else target.get_caret_line()
		globals.last_selection_to_col = target.get_selection_to_column() if target.has_selection() else target.get_caret_column()


#* Right-click insert button:
func _on_insert_button_gui_input(event: InputEvent, insert: String, category: String, source: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		insert_context_menu.clear()
		insert_context_menu.add_item("Edit", 0)
		insert_context_menu.add_item("Delete", 1)
		insert_context_menu.position = Vector2i(get_viewport().get_mouse_position())
		insert_context_menu.set_meta("insert", insert)
		insert_context_menu.set_meta("category", category)
		insert_context_menu.set_meta("source", source)
		insert_context_menu.popup()


#* Select option from insert context menu:
func _on_insert_context_menu_id_pressed(id: int) -> void:
	var insert = insert_context_menu.get_meta("insert")
	var category = insert_context_menu.get_meta("category")
	var source = insert_context_menu.get_meta("source")
	match id:
		0: #% Edit
			insert_menu.setup("Edit", category, insert)
		1: #% Delete
			source[category].erase(insert)
			if source[category].is_empty():
				source.erase(category)
			export_user_inserts()
			export_profile_inserts()
			refresh_insert_lists()
			save_undo_step()


#* Insert text when insert button clicked:
func _on_insert_button_pressed(insert_name: String, source: Dictionary) -> void:
	if globals.last_focused_field == null:
		return
	var before = source[insert_name].get("Before", "")
	var after = source[insert_name].get("After", "")
	var target = globals.last_focused_field

	if target is LineEdit:
		var e: LineEdit = target
		var txt = e.text
		var from = globals.last_selection_from
		var to = globals.last_selection_to
		if from != to:
			var mid := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + before + mid + after + txt.substr(to)
			e.set_caret_column(from + before.length())
		else:
			e.text = txt.substr(0, from) + before + after + txt.substr(from)
			e.set_caret_column(from + before.length())
		e.grab_focus()

	elif target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		var from_line = globals.last_selection_from_line
		var from_col = globals.last_selection_from_col
		var to_line = globals.last_selection_to_line
		var to_col = globals.last_selection_to_col
		if from_line != to_line or from_col != to_col:
			e.select(from_line, from_col, to_line, to_col)
			var sel_text := e.get_selected_text()
			e.delete_selection()
			e.insert_text_at_caret(before + sel_text + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		else:
			e.set_caret_line(from_line)
			e.set_caret_column(from_col)
			e.insert_text_at_caret(before + after)
			e.set_caret_column(e.get_caret_column() - after.length())
		e.end_complex_operation()
		e.grab_focus()

	save_undo_step()


#* Export user inserts:
func export_user_inserts() -> void:
	if globals.current_user != "":
		var path = "user://Users/" + globals.current_user + "/user_inserts.txt"
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			var ascii_hash := "\u0023"
			file.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
			file.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
			file.store_string(ascii_hash + " Type: User Inserts\n")
			file.store_string(ascii_hash + " User: " + globals.current_user + "\n\n")
			file.store_string(_pretty_var(globals.user_inserts))
			file.close()
		else:
			push_error("Failed to write user_inserts.txt")


#* Export profile inserts:
func export_profile_inserts() -> void:
	if globals.current_user != "" and globals.current_profile != "":
		var path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/profile_inserts.txt"
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			var ascii_hash := "\u0023"
			file.store_string(ascii_hash + " Exported By: Candy Dialogue Creator\n")
			file.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
			file.store_string(ascii_hash + " Type: Profile Inserts\n")
			file.store_string(ascii_hash + " User: " + globals.current_user + "\n")
			file.store_string(ascii_hash + " Profile: " + globals.current_profile + "\n\n")
			file.store_string(_pretty_var(globals.profile_inserts))
			file.close()
		else:
			push_error("Failed to write profile_inserts.txt")


#* Load user inserts:
func load_user_inserts() -> void:
	if globals.current_user != "":
		var path = "user://Users/" + globals.current_user + "/user_inserts.txt"
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var raw = file.get_as_text()
				file.close()
				#% Strip comment lines:
				var lines = raw.split("\n")
				var cleaned = []
				for line in lines:
					if not line.strip_edges().begins_with("\u0023"):
						cleaned.append(line)
				raw = "\n".join(cleaned)
				var parsed = str_to_var(raw)
				if parsed is Dictionary:
					globals.user_inserts = parsed
					refresh_insert_lists()
			else:
				push_error("Failed to read user_inserts.txt")


#* Load profile inserts:
func load_profile_inserts() -> void:
	if globals.current_user != "" and globals.current_profile != "":
		var path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/profile_inserts.txt"
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var raw = file.get_as_text()
				file.close()
				#% Strip comment lines:
				var lines = raw.split("\n")
				var cleaned = []
				for line in lines:
					if not line.strip_edges().begins_with("\u0023"):
						cleaned.append(line)
				raw = "\n".join(cleaned)
				var parsed = str_to_var(raw)
				if parsed is Dictionary:
					globals.profile_inserts = parsed
					refresh_insert_lists()
			else:
				push_error("Failed to read profile_inserts.txt")

#endregion


#?######################################################################################
#& WARNING DISPLAY:
#?#################
#region
#* Show a warning or notification in the center of the screen:
func show_warning(text):
	warning_player.stop()
	warning_timer.stop()
	warning_panel.visible = true
	warning_message.text = text
	warning_timer.wait_time = text.length() * float(globals.warning_display_time)
	warning_timer.start()


#* Warning timer timeout:
func _on_warning_timer_timeout():
	warning_player.play("FadeOut")
	await warning_player.animation_finished
	warning_panel.visible = false
	warning_player.stop()
	warning_message.text = ""

#* Close warning prematurely if clicked:
func _on_warning_pressed() -> void:
	warning_player.stop()
	warning_timer.stop()
	warning_panel.visible = false
	warning_message.text = ""
#endregion


#?######################################################################################
#& GENERAL:
#?#########
#region
#* Find a line's source (globals.dialogue, globals.user_presets, globals.profile_presets):
func _get_line_source() -> Dictionary:
	if globals.current_conversation == "USER PRESETS":
		return globals.user_presets
	elif globals.current_conversation == "PROFILE PRESETS":
		return globals.profile_presets
	else:
		return globals.dialogue

#* Helper to remove BBCode tags:
func strip_bbcode(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[/?(" + "|".join(globals.BBCODE_TAGS_SIMPLE + globals.BBCODE_TAGS_EQUALS + globals.BBCODE_TAGS_SPACE) + ")[^\\]]*\\]")
	return regex.sub(text, "", true)

#* Edit DevComment text:
func _on_dev_comment_text_changed() -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	line[line_type]["DevComment"] = devcom_field.text

func _on_devcom_focus_entered(source) -> void:
	globals.original_data = devcom_field.text
	globals.last_focused_field = source


func _on_devcom_focus_exited(source) -> void:
	if globals.last_focused_field == source and source.text != globals.original_data:
		globals.original_data = ""
		save_undo_step()

#* Edit Meta text:
func _on_meta_text_changed() -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	line[line_type]["Meta"] = meta_field.text


func _on_meta_focus_entered(source) -> void:
	globals.original_data = meta_field.text
	globals.last_focused_field = source


func _on_meta_focus_exited(source) -> void:
	if globals.last_focused_field == source and source.text != globals.original_data:
		globals.original_data = ""
		save_undo_step()


#* Edit CustomData text:
func _on_custom_data_text_changed() -> void:
	var source = _get_line_source()
	if not source.has(globals.current_conversation):
		return
	if not source[globals.current_conversation].has(globals.current_block):
		return
	var lines = source[globals.current_conversation][globals.current_block]["Text"]
	if globals.current_line < 0 or globals.current_line >= lines.size():
		return
	var line = lines[globals.current_line]
	var line_type = line.keys()[0]
	line[line_type]["CustomData"] = custom_data_field.text


func _on_custom_data_focus_entered(source) -> void:
	globals.original_data = custom_data_field.text
	globals.last_focused_field = source


func _on_custom_data_focus_exited(source) -> void:
	if globals.last_focused_field == source and source.text != globals.original_data:
		globals.original_data = ""
		save_undo_step()


#* Check if the current command is a condition command:
func _is_condition_command(command: String) -> bool:
	return command in ["§If", "§Elif", "§Else", "§For", "§While"]


#* Pretty-prints a dialogue-structured Dictionary or Array to a GDScript-compatible string:
func _pretty_var(value, depth: int = 0) -> String:
	var indent := "    ".repeat(depth)       # four spaces
	var indent_inner := "    ".repeat(depth + 1)

	if value is Dictionary:
		if value.is_empty():
			return "{}"

		#% Check if this dictionary contains any nested containers (Dictionary or Array):
		#% If not, it's a leaf-level line — keep it compact on one line for readability.
		var has_nested := false
		for v in value.values():
			if v is Dictionary or v is Array:
				has_nested = true
				break

		if not has_nested:
			#% Compact single-line format for simple dictionaries:
			var pairs := []
			for k in value.keys():
				pairs.append('"%s": %s' % [k, _pretty_var(value[k], depth + 1)])
			return "{ " + ", ".join(pairs) + " }"

		#% Expanded multi-line format for dictionaries that contain nested data:
		var lines := []
		for k in value.keys():
			lines.append('%s"%s": %s' % [indent_inner, k, _pretty_var(value[k], depth + 1)])
		return "{\n" + ",\n".join(lines) + "\n" + indent + "}"

	elif value is Array:
		if value.is_empty():
			return "[]"

		#% Always expand arrays onto multiple lines — each element on its own line:
		#% This ensures each dialogue line in a Text array is readable as a distinct entry.
		var items := []
		for item in value:
			items.append(indent_inner + _pretty_var(item, depth + 1))
		return "[\n" + ",\n".join(items) + "\n" + indent + "]"

	elif value is String:
		#% Escape any existing backslashes and quotes inside the string itself:
		var escaped = value.replace("\\", "\\\\").replace('"', '\\"')
		return '"' + escaped + '"'

	elif value is bool:
		#% GDScript's str() handles bools fine but let's be explicit:
		return "true" if value else "false"

	elif value == null:
		return "null"

	elif value is Color:
		return var_to_str(value)

	else:
		return str(value)


#* Import languages and variants from a list of spoken line variant keys into the database:
func _import_languages_from_keys(keys: Array) -> void:
	for key in keys:
		var underscore = key.find("_")
		var language = key if underscore == -1 else key.substr(0, underscore)
		var variant = "" if underscore == -1 else key.substr(underscore)
		#% Add language if missing:
		if language != "" and not globals.languages.has(language):
			var variants_dict = {}
			for v in globals.variants:
				variants_dict[v] = {}
			globals.languages[language] = {
				"Default_Direction": "LtR",
				"Variants": variants_dict,
			}
		#% Add variant to globals.variants if missing:
		if variant != "" and not globals.variants.has(variant):
			globals.variants[variant] = {}
			for lang in globals.languages:
				globals.languages[lang]["Variants"][variant] = {}
		#% Add variant to this language if missing:
		if language != "" and not globals.languages[language]["Variants"].has(variant):
			globals.languages[language]["Variants"][variant] = {}


#* Populate a Spoken Line's Variants with all language+variant combinations:
func _populate_spoken_line_variants(line_data: Dictionary) -> void:
	if not line_data.has("Variants"):
		return

	#% Build a set of existing variant keys for fast lookup:
	var existing_keys := {}
	for entry in line_data["Variants"]:
		existing_keys[entry.keys()[0]] = true

	#% Iterate languages in the same order as the variant tree:
	var languages_sorted = globals.languages.keys()
	languages_sorted.erase("Default")
	languages_sorted.sort()
	languages_sorted.push_front("Default")

	for lang in languages_sorted:
		var variants_sorted = globals.languages[lang]["Variants"].keys()
		variants_sorted.erase("")
		variants_sorted.sort()
		variants_sorted.push_front("")

		for variant in variants_sorted:
			var combined = lang + variant
			#% Only add if not already present:
			if not existing_keys.has(combined):
				var direction = globals.languages[lang].get("Default_Direction", "LtR")
				line_data["Variants"].append({
					combined: {
						"Text": "",
						"Direction": direction,
						"Weight": "1"
					}
				})

#* Add missing language+variant combinations to all spoken lines in dialogue and presets:
func _populate_all_spoken_lines() -> void:
	for source in [globals.dialogue, globals.user_presets, globals.profile_presets]:
		for conv in source.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					for spoken in _get_spoken_lines_from_entry(line_entry):
						_populate_spoken_line_variants(spoken)


#* Get all Spoken Line data dictionaries from a line entry, including those nested in condition commands:
func _get_spoken_lines_from_entry(line_entry: Dictionary) -> Array:
	var result = []
	if line_entry.has("Spoken Line"):
		result.append(line_entry["Spoken Line"])
	for condition_type in ["§If", "§Elif", "§Else", "§For", "§While"]:
		if line_entry.has(condition_type):
			var commands = line_entry[condition_type].get("Commands", {})
			if commands.has("Spoken Line"):
				result.append(commands["Spoken Line"])
	return result

#endregion


#?######################################################################################
#& UNDO/REDO:
#?###########
#region
func save_undo_step() -> void:
	if _suppress_undo_save or _applying_undo_step:
		return

	#@ Mark unsaved work:
	globals.unsaved_work = true
	top_text.text = "*Candy Dialogue Creator " + globals.dc_version + "   -   " + globals.current_user + ": " + globals.current_profile

	#@ Discard future steps if we're not at the end:
	if globals.current_undo_step < globals.undo_stack.size() - 1:
		globals.undo_stack = globals.undo_stack.slice(0, globals.current_undo_step + 1)

	#@ Create step:
	var step = {
		"dialogue": globals.dialogue.duplicate(true),
		"user_presets": globals.user_presets.duplicate(true),
		"profile_presets": globals.profile_presets.duplicate(true),
		"user_inserts": globals.user_inserts.duplicate(true),
		"profile_inserts": globals.profile_inserts.duplicate(true),
		"languages": globals.languages.duplicate(true),
		"variants": globals.variants.duplicate(true),
		"favorites": globals.favorites.duplicate(true),
		"selected_lines": selected_lines.duplicate(),
		"current_conversation": globals.current_conversation,
		"current_block": globals.current_block,
		"current_line": globals.current_line,
		"current_line_type": globals.current_line_type,
		"current_translation": globals.current_translation,
		"current_variant": globals.current_variant,
		"current_save": globals.current_save,
		"current_choice_category": globals.current_choice_category,
		"current_choice_item": globals.current_choice_item,
		"current_choice_timer": globals.current_choice_timer,
		"selected_choice_item": globals.selected_choice_item

	}

	#@ Calculate memory usage of new step:
	var step_size = var_to_str(step).length()

	#@ Calculate total memory usage of stack:
	var total_memory = 0
	for s in globals.undo_stack:
		total_memory += var_to_str(s).length()

	#@ Enforce limits — remove oldest steps if needed:
	while globals.undo_stack.size() > 0:
		var over_max_steps = globals.undo_stack.size() >= globals.undo_steps_max and globals.undo_steps_max > 0
		var over_max_memory = (total_memory + step_size) > globals.undo_memory_max and globals.undo_memory_max > 0
		var above_min_steps = globals.undo_stack.size() >= globals.undo_steps_min
		var above_min_memory = total_memory >= globals.undo_memory_min

		if (over_max_steps or over_max_memory) and above_min_steps and above_min_memory:
			var removed = globals.undo_stack.pop_front()
			total_memory -= var_to_str(removed).length()
			globals.current_undo_step -= 1
		else:
			break

	#@ Add step:
	globals.undo_stack.append(step)
	globals.current_undo_step = globals.undo_stack.size() - 1

func undo() -> void:
	if globals.current_undo_step <= 0:
		return
	globals.current_undo_step -= 1
	_apply_undo_step(globals.undo_stack[globals.current_undo_step])


func redo() -> void:
	if globals.current_undo_step >= globals.undo_stack.size() - 1:
		return
	globals.current_undo_step += 1
	_apply_undo_step(globals.undo_stack[globals.current_undo_step])


#* Reload undo step:
func _apply_undo_step(step: Dictionary) -> void:
	#@ Make sure none of the undo process saves more undo steps:
	_applying_undo_step = true

	#@ Reload data:
	globals.dialogue = step["dialogue"].duplicate(true)
	globals.user_presets = step["user_presets"].duplicate(true)
	globals.profile_presets = step["profile_presets"].duplicate(true)
	globals.user_inserts = step["user_inserts"].duplicate(true)
	globals.profile_inserts = step["profile_inserts"].duplicate(true)
	globals.languages = step["languages"].duplicate(true)
	globals.variants = step["variants"].duplicate(true)
	globals.favorites = step["favorites"].duplicate(true)
	selected_lines = step["selected_lines"].duplicate()
	globals.current_conversation = step["current_conversation"]
	globals.current_block = step["current_block"]
	globals.current_line = step["current_line"]
	globals.current_line_type = step["current_line_type"]
	globals.current_translation = step["current_translation"]
	globals.current_variant = step["current_variant"]
	globals.current_save = step["current_save"]
	globals.current_choice_category = step["current_choice_category"]
	globals.current_choice_item = step["current_choice_item"]
	globals.current_choice_timer = step["current_choice_timer"]
	globals.selected_choice_item = step["selected_choice_item"]

	#@ Export inserts and presets for consistency:
	export_user_inserts()
	export_profile_inserts()
	export_user_presets()
	export_profile_presets()

	#@ Refresh UI:
	refresh_insert_lists()
	populate_preset_buttons()
	_rebuild_favorites()
	update_conversation_selector(true)
	update_line_list()

	#@ Clear data fields if no line selected after undo:
	if globals.current_line >= 0:
		var root = line_tree.get_root()
		if root:
			var item = root.get_first_child()
			while item != null:
				if item.get_metadata(0) == globals.current_line:
					_suppress_undo_save = true
					line_tree.deselect_all()
					item.select(0)
					_suppress_undo_save = false
					selected_lines = [globals.current_line]
					break
				item = item.get_next()
		if globals.current_line_type != "":
			_show_line_editor()
	else:
		hide_line_data(false)

	#@ Refresh variant/translation/choice trees based on line type:
	var has_spoken_line = globals.current_line_type == "Spoken Line"
	var has_choice_list = globals.current_line_type == "§Choice_List"
	if not has_spoken_line and _is_condition_command(globals.current_line_type):
		var source = _get_line_source()
		if source.has(globals.current_conversation) and source[globals.current_conversation].has(globals.current_block):
			var lines = source[globals.current_conversation][globals.current_block]["Text"]
			if globals.current_line >= 0 and globals.current_line < lines.size():
				var line_data = lines[globals.current_line][globals.current_line_type]
				has_spoken_line = line_data.get("Type", "") == "Spoken Line" and line_data.get("Commands", {}).has("Spoken Line")
				has_choice_list = line_data.get("Type", "") == "§Choice_List" and line_data.get("Commands", {}).has("§Choice_List")
	if has_spoken_line:
		refresh_variant_tree()
		refresh_translation_tree()
		refresh_counters()
	if has_choice_list:
		refresh_choice_tree()
		_reselect_choice_tree_item()
		_on_choice_item_changed()

	#@ Release the anti-undo step safety:
	_applying_undo_step = false


#* Helper to reselect the correct choice item in §Choice_List commands:
func _reselect_choice_tree_item() -> void:
	var root = choice_tree.get_root()
	if root == null:
		return
	var target = choice_tree.get_root()
	if target == null:
		return
	var child = target.get_first_child()
	while child != null:
		var meta = child.get_metadata(0)
		if meta["type"] == "timer" and meta["name"] == globals.current_choice_timer:
			child.select(0)
			globals.selected_choice_item = child
			return
		if meta["type"] == "category" and meta["name"] == globals.current_choice_category:
			if globals.current_choice_item == "":
				child.select(0)
				globals.selected_choice_item = child
				return
			var subchild = child.get_first_child()
			while subchild != null:
				var submeta = subchild.get_metadata(0)
				if submeta["type"] == "choice" and submeta["name"] == globals.current_choice_item:
					subchild.select(0)
					globals.selected_choice_item = subchild
					return
				subchild = subchild.get_next_sibling()
		child = child.get_next_sibling()


#endregion


#?######################################################################################
#& DIALOGUE CONVERSION:
#?#####################
#region
#* Convert dialogues from 1.0 to 1.1:
func convert_dialogue_1_0_to_1_1(files: Array) -> void:
	var log_path := "user://Users/" .path_join(globals.current_user).path_join(globals.current_profile).path_join("convert_dialogues_log.txt")
	var log_lines := []
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")

	log_lines.append("Candy Dialogue Creator — Conversion Log")
	log_lines.append("Target version: 1.1.0")
	log_lines.append("")
	log_lines.append("Selected files:")

	var valid_files := []
	var skipped_files := []

	#@ Check files:
	for path in files:
		if not path.ends_with(".txt"):
			log_lines.append("  - " + path + " (aborted: not a .txt file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — not all selected files are .txt files.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: not all selected files are .txt files. See convert_dialogues_log.txt for details.")
			return

		var f_check := FileAccess.open(path, FileAccess.READ)
		if not f_check:
			log_lines.append("  - " + path + " (aborted: could not open file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be opened.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be opened. See convert_dialogues_log.txt for details.")
			return

		var raw := f_check.get_as_text()
		f_check.close()

		#@ Try native Godot format first, then fall back to custom to_gdstring format:
		var parsed = str_to_var(raw)
		if not parsed is Dictionary:
			parsed = _parse_gdstring(raw)
			if parsed is Dictionary:
				parsed = parsed.duplicate(true)
		if not parsed is Dictionary:
			log_lines.append("  - " + path + " (aborted: could not parse file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be parsed.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be parsed. See convert_dialogues_log.txt for details.")
			return

		var version := str(parsed.get("Meta", {}).get("Dialogue Version", "unknown")).strip_edges()

		if version == "1.1.0":
			log_lines.append("  - " + path + " (version: " + version + ", already up to date — will be skipped)")
			skipped_files.append(path)
			continue

		if version != "1.0.0" and version != "1.0":
			log_lines.append("  - " + path + " (aborted: unexpected version " + version + ")")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file has an unexpected dialogue version.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file has an unexpected dialogue version '" + version + "'. See convert_dialogues_log.txt for details.")
			return

		log_lines.append("  - " + path + " (version: " + version + ")")
		valid_files.append({"path": path, "raw": raw, "parsed": parsed})

	if valid_files.is_empty():
		log_lines.append("")
		log_lines.append("No files to convert.")
		_write_log(log_path, log_lines)
		return

	#@ Create backup folder:
	var first_path: String = valid_files[0]["path"]
	var dialogue_folder := first_path.get_base_dir()
	var backup_folder := dialogue_folder.path_join("Conversion Backups").path_join(stamp)
	DirAccess.make_dir_recursive_absolute(backup_folder)

	log_lines.append("")
	log_lines.append("Backing up originals to: " + backup_folder)
	for entry in valid_files:
		var path: String = entry["path"]
		var raw: String = entry["raw"]
		var filename := path.get_file()
		var backup_path := backup_folder.path_join(filename)
		var f_bak := FileAccess.open(backup_path, FileAccess.WRITE)
		if not f_bak:
			log_lines.append("  - " + filename + " (failed: could not create backup)")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: could not create backup. See convert_dialogues_log.txt for details.")
			return
		f_bak.store_string(raw)
		f_bak.close()
		log_lines.append("  - " + filename + " (backed up)")

	log_lines.append("")
	log_lines.append("Conversion results:")

	var failed := false

	#@ Write to file:
	for entry in valid_files:
		var path: String = entry["path"]
		var parsed = entry["parsed"]

		if failed:
			log_lines.append("  - " + path + " (aborted)")
			continue

		var dialogue = parsed.get("Dialogue", {})
		dialogue.erase("CUSTOM_PRESETS")
		for conv in dialogue.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					_convert_line_1_0_to_1_1(line_entry)

		var ascii_hash := "\u0023"
		var f_write := FileAccess.open(path, FileAccess.WRITE)
		if not f_write:
			log_lines.append("  - " + path + " (failed: could not write output file)")
			failed = true
			continue

		parsed["Meta"]["Exported By"] = "Candy Dialogue Creator"
		parsed["Meta"]["Creator Version"] = globals.dc_version
		parsed["Meta"]["Dialogue Version"] = "1.1.0"
		f_write.store_string(ascii_hash + " Converted By: Candy Dialogue Creator\n")
		f_write.store_string(ascii_hash + " Creator Version: " + str(globals.dc_version) + "\n")
		f_write.store_string(ascii_hash + " Dialogue Version: 1.1.0\n\n")
		f_write.store_string(_pretty_var(parsed))
		f_write.close()
		log_lines.append("  - " + path + " (success)")

	#@ Log skipped files:
	if not skipped_files.is_empty():
		log_lines.append("")
		log_lines.append("Skipped files (already at version 1.1.0):")
		for sf in skipped_files:
			log_lines.append("  - " + sf)

	_write_log(log_path, log_lines)

	if failed:
		show_warning("Dialogue conversion aborted mid-batch. See convert_dialogues_log.txt for details.")
	else:
		show_warning("Dialogue conversion complete. See convert_dialogues_log.txt for details.")


#* Convert saves from 1.0 to 1.1:
func convert_saves_1_0_to_1_1(files: Array) -> void:
	var log_path := "user://Users/".path_join(globals.current_user).path_join(globals.current_profile).path_join("Saves/Converted/convert_saves_log.txt")
	var log_lines := []
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")

	log_lines.append("Candy Dialogue Creator — Save Conversion Log")
	log_lines.append("Target version: 1.1.0")
	log_lines.append("")
	log_lines.append("Selected files:")

	var valid_files := []
	var skipped_files := []

	for path in files:
		if not path.ends_with(".txt"):
			log_lines.append("  - " + path + " (aborted: not a .txt file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — not all selected files are .txt files.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: not all selected files are .txt files. See convert_saves_log.txt for details.")
			return

		var f_check := FileAccess.open(path, FileAccess.READ)
		if not f_check:
			log_lines.append("  - " + path + " (aborted: could not open file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be opened.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be opened. See convert_saves_log.txt for details.")
			return

		var raw := f_check.get_as_text()
		f_check.close()

		#@ Try native Godot format first, then fall back to custom to_gdstring format:
		var parsed = str_to_var(raw)
		if not parsed is Dictionary:
			parsed = _parse_gdstring(raw)
			parsed = parsed.duplicate(true)
		if not parsed is Dictionary:
			log_lines.append("  - " + path + " (aborted: could not parse file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be parsed.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be parsed. See convert_saves_log.txt for details.")
			return

		var version := str(parsed.get("Dialogue Version", "unknown")).strip_edges()

		if version == "1.1.0":
			log_lines.append("  - " + path + " (version: " + version + ", already up to date — will be skipped)")
			skipped_files.append(path)
			continue

		if version != "1.0.0" and version != "1.0":
			log_lines.append("  - " + path + " (aborted: unexpected version " + version + ")")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file has an unexpected version.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: unexpected version '" + version + "'. See convert_saves_log.txt for details.")
			return

		log_lines.append("  - " + path + " (version: " + version + ")")
		valid_files.append({"path": path, "raw": raw, "parsed": parsed})

	if valid_files.is_empty():
		log_lines.append("")
		log_lines.append("No files to convert.")
		_write_log(log_path, log_lines)
		return

	#@ Create output and backup folders:
	var output_folder := "user://Users/".path_join(globals.current_user).path_join(globals.current_profile).path_join("Saves/Converted/New").path_join(stamp)
	var backup_folder := "user://Users/".path_join(globals.current_user).path_join(globals.current_profile).path_join("Saves/Converted/Originals").path_join(stamp)
	DirAccess.make_dir_recursive_absolute(output_folder)
	DirAccess.make_dir_recursive_absolute(backup_folder)

	log_lines.append("")
	log_lines.append("Output folder: " + output_folder)
	log_lines.append("Backup folder: " + backup_folder)
	log_lines.append("")
	log_lines.append("Conversion results:")

	var failed := false

	for entry in valid_files:
		var path: String = entry["path"]
		var raw: String = entry["raw"]
		var parsed = entry["parsed"]
		var filename := path.get_file()

		if failed:
			log_lines.append("  - " + filename + " (aborted)")
			continue

		#@ Copy original to backup folder:
		var backup_path := backup_folder.path_join(filename)
		var f_bak := FileAccess.open(backup_path, FileAccess.WRITE)
		if not f_bak:
			log_lines.append("  - " + filename + " (failed: could not create backup)")
			failed = true
			continue
		f_bak.store_string(raw)
		f_bak.close()

		#@ Convert dialogue data inside save:
		var dialogue = parsed.get("Dialogue", {})
		dialogue.erase("CUSTOM_PRESETS")
		for conv in dialogue.values():
			for block in conv.values():
				for line_entry in block.get("Text", []):
					_convert_line_1_0_to_1_1(line_entry)

		#@ Update version and add User key:
		parsed["Dialogue Version"] = "1.1.0"
		parsed["User"] = globals.current_user
		if parsed.get("Type", "") == "ManualSave":
			parsed["Type"] = "Normal Save"
		if parsed.get("Type", "") == "AutoSave":
			parsed["Type"] = "Auto Save"
		if parsed.get("Type", "") == "QuickSave":
			parsed["Type"] = "Quick Save"

		#@ Write converted file to output folder:
		var output_path := output_folder.path_join(filename)
		var f_write := FileAccess.open(output_path, FileAccess.WRITE)
		if not f_write:
			log_lines.append("  - " + filename + " (failed: could not write output file)")
			failed = true
			continue
		print(typeof(parsed))
		f_write.store_string(_pretty_var(parsed))
		f_write.close()
		log_lines.append("  - " + filename + " (success → " + output_path + ")")

	if not skipped_files.is_empty():
		log_lines.append("")
		log_lines.append("Skipped files (already at version 1.1.0):")
		for sf in skipped_files:
			log_lines.append("  - " + sf)

	_write_log(log_path, log_lines)

	if failed:
		show_warning("Save conversion aborted mid-batch. See convert_saves_log.txt for details.")
	else:
		show_warning("Save conversion complete. See convert_saves_log.txt for details.")


#* Convert presets from a 1.0 profile config file to the 1.1 profile_presets.txt format:
#! NOTE: This function works by importing 1.0 presets directly to globals, and then exporting them to the profile_preset.txt files.
func convert_presets_1_0_to_1_1(files: Array) -> void:
	export_profile_presets()
	var log_path := "user://Users/".path_join(globals.current_user).path_join(globals.current_profile).path_join("convert_presets_log.txt")
	var log_lines := []
	log_lines.append("Candy Dialogue Creator — Preset Conversion Log")
	log_lines.append("Source format: 1.0 profile config")
	log_lines.append("Target format: 1.1 profile_presets.txt")
	log_lines.append("")
	log_lines.append("Selected files:")

	#@ Step 1 - Validate all files:
	var valid_files := []
	var flat_paths: Array[String] = []
	for inner in files:
		for p in inner:
			flat_paths.append(str(p))

	for path in flat_paths:

		if not path.ends_with(".txt") and not path.ends_with(".json"):
			log_lines.append("  - " + path + " (aborted: not a .txt or .json file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — not all selected files are .txt or .json files.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: not all selected files are .txt or .json files. See convert_presets_log.txt for details.")
			return

		var f_check := FileAccess.open(path, FileAccess.READ)
		if not f_check:
			log_lines.append("  - " + path + " (aborted: could not open file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be opened.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be opened. See convert_presets_log.txt for details.")
			return

		var raw := f_check.get_as_text()
		f_check.close()

		#% Try native GDScript parsing first, then JSON, then fall back to custom parser:
		var parsed = str_to_var(raw)
		if not parsed is Dictionary:
			parsed = JSON.parse_string(raw)
		if not parsed is Dictionary:
			parsed = _parse_gdstring(raw)
			if parsed is Dictionary:
				parsed = parsed.duplicate(true)
		if not parsed is Dictionary:
			log_lines.append("  - " + path + " (aborted: could not parse file)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file could not be parsed.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file could not be parsed. See convert_presets_log.txt for details.")
			return

		#% Check for 'custom_presets' to confirm selected file is 1.0 profile config:
		if not parsed.has("custom_presets"):
			log_lines.append("  - " + path + " (aborted: no custom_presets key found — may not be a 1.0 profile config)")
			log_lines.append("")
			log_lines.append("Conversion aborted — a file does not appear to be a 1.0 profile config.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: a file does not appear to be a 1.0 profile config. See convert_presets_log.txt for details.")
			return

		var presets = parsed.get("custom_presets", {})
		if presets.is_empty():
			log_lines.append("  - " + path + " (skipped: custom_presets is empty)")
			continue

		log_lines.append("  - " + path + " (" + str(presets.size()) + " preset(s) found)")
		valid_files.append({"path": path, "presets": presets})

	if valid_files.is_empty():
		log_lines.append("")
		log_lines.append("No presets to convert.")
		_write_log(log_path, log_lines)
		return

	#@ Step 2 - Back up the existing 1.1 preset file:
	var preset_file_path = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/profile_presets.txt"
	if FileAccess.file_exists(preset_file_path):
		var backup_folder = "user://Users/" + globals.current_user + "/" + globals.current_profile + "/Preset Backups"
		DirAccess.make_dir_recursive_absolute(backup_folder)
		var stamp := Time.get_datetime_string_from_system().replace(":", "-")
		var backup_path = backup_folder + "/profile_presets_〔" + stamp + "〕.txt"
		var f_src := FileAccess.open(preset_file_path, FileAccess.READ)
		if not f_src:
			log_lines.append("Aborted: could not read preset file for backup.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: could not read preset file for backup. See convert_presets_log.txt for details.")
			return
		var preset_raw := f_src.get_as_text()
		f_src.close()
		var f_bak := FileAccess.open(backup_path, FileAccess.WRITE)
		if not f_bak:
			log_lines.append("Aborted: could not write backup file.")
			_write_log(log_path, log_lines)
			show_warning("Conversion aborted: could not write backup file. See convert_presets_log.txt for details.")
			return
		f_bak.store_string(preset_raw)
		f_bak.close()
		log_lines.append("Backed up existing preset file to: " + backup_path)
		log_lines.append("")

	#@ Step 3 - Convert lines from 1.0 to 1.1 format:
	log_lines.append("")
	log_lines.append("Conversion results:")

	for entry in valid_files:
		var path: String = entry["path"]
		var presets: Dictionary = entry["presets"]

		for preset_name in presets.keys():
			var block: Dictionary = presets[preset_name]
			for line_entry in block.get("Text", []):
				_convert_line_1_0_to_1_1(line_entry)

		#@ Step 4 - Merge converted presets into globals.profile_presets:
		var added := 0
		var renamed_block := 0
		for preset_name in presets.keys():
			var final_name = preset_name
			var destination = globals.profile_presets["PROFILE PRESETS"]
			if destination.has(preset_name):
				final_name = preset_name + " (1.0)"
				renamed_block += 1
				log_lines.append("  - '" + preset_name + "' renamed to '" + final_name + "' (name collision)")
			else:
				added += 1
			destination[final_name] = presets[preset_name]

		log_lines.append("  - " + path + ": " + str(added) + " preset(s) added, " + str(renamed_block) + " renamed due to collisions")

	#@ Step 5 - Save the updated presets to disk:
	export_profile_presets()

	#% Reload presets immediately to update languages/variants:
	load_presets()

	#@ Step 6 - Update the Block and refresh the preset buttons:
	update_block_selector(true)
	populate_preset_buttons()

	_write_log(log_path, log_lines)
	show_warning("Preset conversion complete. See convert_presets_log.txt for details.")


#* Convert a single line entry from 1.0 to 1.1 format (in-place):
func _convert_line_1_0_to_1_1(line_entry: Dictionary) -> void:
	var line_type = line_entry.keys()[0]

	if line_type == "Spoken Line":
		var sl: Dictionary = line_entry["Spoken Line"]
		for variant_dict in sl.get("Variants", []):
			if variant_dict.has("DevCom"):
				sl["DevComment"] = variant_dict["DevCom"].get("Text", "")
				break
		var cleaned_variants := []
		for variant_dict in sl.get("Variants", []):
			var variant_name = variant_dict.keys()[0]
			if variant_name == "DevCom":
				continue
			variant_dict[variant_name].erase("Hide")
			variant_dict[variant_name].erase("Enabled")
			cleaned_variants.append(variant_dict)
		sl["Variants"] = cleaned_variants
		sl.erase("ShowVariants")
		for key in ["AI", "TTS"]:
			if sl.has(key) and typeof(sl[key]) in [TYPE_INT, TYPE_FLOAT]:
				sl[key] = str(int(sl[key]))
		if sl.has("BubbleExempt"):
			var val = sl["BubbleExempt"]
			sl.erase("BubbleExempt")
			match typeof(val):
				TYPE_BOOL:
					sl["ForceBubbles"] = "-1" if val else "0"
				TYPE_INT:
					sl["ForceBubbles"] = str(val)
				TYPE_FLOAT:
					sl["ForceBubbles"] = str(int(val))
		line_entry["Spoken Line"] = sl

	elif line_type in ["§If", "§Elif", "§Else", "§For", "§While"]:
		var d: Dictionary = line_entry[line_type]
		var result: String = str(d.get("Type", d.get("Result", ""))).to_lower()
		var transition: String = str(d.get("Transition", "Bridge")).to_lower()
		var commands := {}
		match result:
			"transition":
				match transition:
					"bridge":
						commands["§Bridge"] = {"Conversation": d.get("Conversation", ""), "Block": d.get("Block", ""), "Line": d.get("Line", "")}
					"jump":
						commands["§Jump"] = {"Conversation": d.get("Conversation", ""), "Block": d.get("Block", ""), "Line": d.get("Line", "")}
					"return":
						commands["§Return"] = {}
					"end":
						commands["§End"] = {}
			"set":
				commands["§Set"] = {"Variable": d.get("Variable", ""), "Operator": d.get("Operator", "="), "Expression": d.get("Expression", "")}
			"call":
				var await_val = d.get("Await", true)
				if typeof(await_val) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
					await_val = str(bool(await_val)).to_lower()
				commands["§Call"] = {"Function": d.get("Function", ""), "Arguments": d.get("Arguments", ""), "Variable": d.get("Variable", ""), "Await": await_val}
			"emit":
				commands["§Emit"] = {"Signal": d.get("Signal", ""), "Arguments": d.get("Arguments", "")}
			"await":
				commands["§Await"] = {"Signal": d.get("Signal", ""), "Variable": d.get("Variable", "")}
			"flag":
				commands["§Flag"] = {"Flag": d.get("Flag", ""), "Operator": d.get("Operator", "="), "Expression": d.get("Expression", "")}
			"name":
				commands["§Name"] = {"Reference": d.get("Reference", ""), "Name": d.get("Name", ""), "Table": d.get("Table", ""), "Actor_Key": d.get("Actor_Key", "")}
			"disposition":
				commands["§Disposition"] = {"Reference": d.get("Reference", ""), "Disposition": d.get("Disposition", "")}
			"role":
				commands["§Role"] = {"Role": d.get("Role", ""), "Reference": d.get("Reference", "")}
			_:
				push_warning("Unrecognised Result value '" + result + "' in line_entry: " + str(line_entry))

		var new_type = commands.keys()[0] if not commands.is_empty() else ""
		line_entry[line_type] = {"Condition": d.get("Condition", ""), "Type": new_type, "Commands": commands}

	elif line_type in ["§BG_Stop", "§VN_Bust_Stop"]:
		var d: Dictionary = line_entry[line_type]
		if d.has("Default") and typeof(d["Default"]) in [TYPE_INT, TYPE_FLOAT]:
			d["Default"] = str(int(d["Default"]))
		line_entry[line_type] = d

	elif line_type == "§Call":
		var d: Dictionary = line_entry["§Call"]
		if d.has("Await") and typeof(d["Await"]) in [TYPE_INT, TYPE_BOOL, TYPE_FLOAT]:
			d["Await"] = str(bool(d["Await"])).to_lower()
		line_entry["§Call"] = d

	elif line_type in ["§Video", "§V_Wait", "§V_Resume", "§V_Show", "§I_Wait", "§I_Resume", "§I_Show"]:
		var d: Dictionary = line_entry[line_type]
		for key in ["Box", "Portrait"]:
			if d.has(key) and typeof(d[key]) in [TYPE_INT, TYPE_FLOAT]:
				d[key] = str(int(d[key]))
		line_entry[line_type] = d

	elif line_type == "§V_Volume":
		var d: Dictionary = line_entry[line_type]
		for key in ["Volume", "Time"]:
			if d.has(key) and typeof(d[key]) in [TYPE_INT, TYPE_FLOAT]:
				d[key] = str(int(d[key]))
		line_entry[line_type] = d

	elif line_type in ["§V_Pause", "§I_Pause"]:
		var d: Dictionary = line_entry[line_type]
		for key in ["Lines", "All", "Box", "Portrait"]:
			if d.has(key) and typeof(d[key]) in [TYPE_INT, TYPE_FLOAT]:
				d[key] = str(int(d[key]))
		line_entry[line_type] = d

	elif line_type == "§Image":
		var d: Dictionary = line_entry["§Image"]
		for key in ["Animated", "Box", "Portrait"]:
			if d.has(key) and typeof(d[key]) in [TYPE_INT, TYPE_FLOAT]:
				d[key] = str(int(d[key]))
		line_entry["§Image"] = d

	elif line_type == "§A_Pause":
		var d: Dictionary = line_entry["§A_Pause"]
		if d.has("All") and typeof(d["All"]) in [TYPE_INT, TYPE_FLOAT]:
			d["All"] = str(int(d["All"]))
		line_entry["§A_Pause"] = d


#* Parse a file written with to_gdstring() or _dict_to_string() using the Expression evaluator:
func _parse_gdstring(raw: String) -> Variant:
	var text := raw
	text = text.replace("<null>", "null").replace("<Null>", "null")
	var regex_trailing := RegEx.new()
	regex_trailing.compile(",(\\s*[}\\]])")
	text = regex_trailing.sub(text, "$1", true)
	text = text.strip_edges()
	if text.ends_with(","):
		text = text.substr(0, text.length() - 1)
	var expr := Expression.new()
	if expr.parse(text) != OK:
		return null
	var result = expr.execute()
	if expr.has_execute_failed():
		return null
	return result


#* Helper to write the log file:
func _write_log(path: String, lines: Array) -> void:
	print(globals.current_user)
	var log_dir := "user://Users/".path_join(globals.current_user).path_join(globals.current_profile).path_join("Saves/Converted")
	DirAccess.make_dir_recursive_absolute(log_dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Could not write conversion log to: " + path)
		return
	f.store_string("\n".join(lines))
	f.close()


#endregion

#* Clear focus when command tab clicked:
func _on_commands_tab_clicked(_tab: int) -> void:
	#% Clear last focus:
	globals.last_focused_field = null

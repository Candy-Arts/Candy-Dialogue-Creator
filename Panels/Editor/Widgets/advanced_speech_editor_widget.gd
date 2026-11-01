#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAdvancedSpeechEditorWidget
extends CandySpeechEditorWidget

#^ Shortcut that opens and leaves the tag popup:
const EDIT_TAGS_ACTION := "edit_tags"

#^ Widget config keys and profile setting keys:
const CONFIG_MARKERS := "tag_markers"
const CONFIG_MARKER_COLOR := "tag_marker_color"
const SETTING_MARKERS := "tag_markers"
const SETTING_MARKER_CHARACTER := "tag_marker_character"
#^ { theme id = Color }:
const SETTING_MARKER_COLOR := "tag_marker_colors"
#^ A widget's tag_markers when it follows the setting:
const MARKERS_DEFAULT := "default"
const DEFAULT_MARKERS := "on"
#^ Stored mode → CandyBBCodeEdit mode:
const MARKER_MODES := {
	"off": CandyBBCodeEdit.TagMarkers.OFF,
	"on": CandyBBCodeEdit.TagMarkers.ON,
	"smart": CandyBBCodeEdit.TagMarkers.SMART,
}
const MODE_LABELS := {"off": "Off", "on": "On", "smart": "Smart"}  #/ translatable


#* Modes for a settings dropdown - [{ "label", "value" }]:
static func mode_options() -> Array:
	var options: Array = []
	for mode in MARKER_MODES:
		options.append({"label": CandyLocale.t(MODE_LABELS[mode]), "value": mode})
	return options


static func mode_label(mode: String) -> String:
	if not MODE_LABELS.has(mode):
		return mode
	return CandyLocale.t(MODE_LABELS[mode])


#* The profile's mode:
static func setting_mode() -> String:
	var mode := str(CandyProfiles.get_setting(SETTING_MARKERS, DEFAULT_MARKERS))
	if not MARKER_MODES.has(mode):
		return DEFAULT_MARKERS
	return mode


#* The profile's marker color for the current theme:
static func setting_color() -> Color:
	return theme_marker_color(CandyProfiles.get_setting(SETTING_MARKER_COLOR, {}), CandyTheme.current_theme_id())


#* A theme's marker color:
#? stored: { theme id: Color }.
static func theme_marker_color(stored: Variant, theme_id: String) -> Color:
	if stored is Dictionary and CandySpeechEditorSettings.has_color(stored.get(theme_id)):
		return CandySpeechEditorSettings.to_color(stored[theme_id], CandyBBCodeEdit.DEFAULT_MARKER_COLOR)			#/ User's
	var from_theme = CandyTheme.speech_colors().get("tag_marker")
	if from_theme is Color:
		return from_theme
	return CandyBBCodeEdit.DEFAULT_MARKER_COLOR


#* A widget's mode, its own or the setting's:
static func mode_of(p_config: Dictionary) -> String:
	var mode := str(p_config.get(CONFIG_MARKERS, MARKERS_DEFAULT))
	if not MARKER_MODES.has(mode):
		return setting_mode()
	return mode


#* A widget's marker color, its own or the setting's:
static func marker_color_of(p_config: Dictionary) -> Color:
	var own: Variant = p_config.get(CONFIG_MARKER_COLOR, "")
	if CandySpeechEditorSettings.has_color(own):
		return CandySpeechEditorSettings.to_color(own, CandyBBCodeEdit.DEFAULT_MARKER_COLOR)
	return setting_color()


func _make_edit() -> Control:
	var edit := CandyBBCodeEdit.new()
	edit.theme_type_variation = CandyThemeDefaults.ADVANCED_SPEECH_EDITOR
	edit.get_tag_popup().theme_type_variation = CandyThemeDefaults.TAG_POPUP
	edit.get_popup_edit().theme_type_variation = CandyThemeDefaults.TAG_POPUP_EDIT
	edit.hide_tags = true
	#? Its menu offers the settings (see _add_settings_menu_item()).
	edit.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
	#? Not focus_exited - going to the tag popup isn't the end of typing.
	edit.focus_left.connect(_finish_typing)
	edit.text_changed.connect(_on_text_typed)
	edit.gui_input.connect(_on_text_key)
	edit.get_popup_edit().gui_input.connect(_on_popup_key)
	return edit


#* Edit Tags - open the popup:
func _on_text_key(event: InputEvent) -> void:
	#? Heard before the text uses the key (it still does where there are no tags).
	if CandyShortcuts.speech_action(event) == EDIT_TAGS_ACTION and _bbcode_edit().edit_tags():
		_bbcode_edit().accept_event()


#* Edit Tags again - back to the text:
func _on_popup_key(event: InputEvent) -> void:
	if CandyShortcuts.speech_action(event) == EDIT_TAGS_ACTION:
		_bbcode_edit().get_popup_edit().accept_event()
		_bbcode_edit().leave_tags()


func _on_configured() -> void:
	super()
	_apply_tag_markers()
	CandyProfiles.settings_changed.connect(_on_setting_changed)


func _new_settings() -> CandySpeechEditorSettings:
	return CandyAdvancedSpeechEditorSettings.new()


#* Apply colors and markers:
func _apply_colors() -> void:
	super()
	_apply_tag_markers()			#/ Its contrast depends on the background


func _apply_tag_markers() -> void:
	if _edit == null:
		return
	var edit := _bbcode_edit()
	edit.tag_markers = MARKER_MODES[mode_of(config)]
	edit.marker_character = str(CandyProfiles.get_setting(SETTING_MARKER_CHARACTER, CandyBBCodeEdit.DEFAULT_MARKER_CHARACTER))
	edit.marker_color = marker_color_of(config)


func _on_setting_changed(key: String) -> void:
	#? The theme picks its own marker color.
	if key in [SETTING_MARKERS, SETTING_MARKER_CHARACTER, SETTING_MARKER_COLOR, CandyTheme.THEME_SETTING]:
		_apply_tag_markers()


func _bbcode_edit() -> CandyBBCodeEdit:
	return _edit as CandyBBCodeEdit


func _edit_text() -> String:
	return _bbcode_edit().text


func _set_edit_text(value: String) -> void:
	_bbcode_edit().text = value


func _set_edit_editable(on: bool) -> void:
	_bbcode_edit().editable = on


func _set_edit_placeholder(value: String) -> void:
	_bbcode_edit().placeholder_text = value


#* Typing in the tag popup is typing too:
func _is_typing() -> bool:
	return _bbcode_edit().has_focus_within()


func _edit_menu() -> PopupMenu:
	return _bbcode_edit().get_menu()

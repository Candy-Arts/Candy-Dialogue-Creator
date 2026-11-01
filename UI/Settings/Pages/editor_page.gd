#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyEditorSettingsPage
extends CandySettingsPage

var _marker_color: ColorPickerButton
var _color_menu: CandyOverrideMenu


func build() -> void:
	add_heading(CandyLocale.t("Layout"))
	add_number("layout_resize_step", CandyLocale.t("Resize step (Ctrl)"), 1, 512, 1,
		CandyLocale.t("Dragging a divider between two areas with Ctrl held moves it in steps of this many pixels."),
		CandyAreaSplit.DEFAULT_RESIZE_STEP)
	add_choice(CandyAreaDrag.COPY_KEY_SETTING, CandyLocale.t("Copy key (drag)"), CandyAreaDrag.key_options(),
		CandyLocale.t("In Edit Layout mode, dragging an area's button moves the area. Hold this key when dropping it to copy it instead, leaving the original where it is."),
		CandyAreaDrag.DEFAULT_COPY_KEY)
	add_choice(CandyAreaDrag.SWAP_KEY_SETTING, CandyLocale.t("Swap key (drag)"), CandyAreaDrag.key_options(),
		CandyLocale.t("In Edit Layout mode, hold this key when dropping an area onto another to swap the two.\nSome systems move the whole window when Alt is held while dragging: pick another key there."),
		CandyAreaDrag.DEFAULT_SWAP_KEY)
	add_separator()

	add_heading(CandyLocale.t("Previews"))
	add_number("portrait_preview_width", CandyLocale.t("Portrait width"), 16, 1024, 1,
		_preview_tooltip(CandyLocale.t("a portrait (Spoken Line)")), 128)
	add_number("bust_preview_width", CandyLocale.t("Bust width"), 16, 1024, 1,
		_preview_tooltip(CandyLocale.t("a bust (VN Play)")), 256)
	add_number("bg_preview_width", CandyLocale.t("Background width"), 16, 2048, 1,
		_preview_tooltip(CandyLocale.t("a background (BG Play)")), 256)
	add_number("image_preview_width", CandyLocale.t("Media image width"), 16, 2048, 1,
		_preview_tooltip(CandyLocale.t("an image of a Media Play")), 512)
	add_number("video_preview_width", CandyLocale.t("Media video width"), 16, 2048, 1,
		_preview_tooltip(CandyLocale.t("a video of a Media Play")), 512)
	add_separator()

	add_heading(CandyLocale.t("Sprite playback"))
	add_number("portrait_sprite_fps", CandyLocale.t("Portrait FPS"), 1, 120, 0.5,
		CandyLocale.t("Sprite sheets and frame folders of portraits play at this rate, in the Portrait Preview and the dropdown previews, and SpriteFrames animations saved with a speed of 0."), 30.0)
	add_number("bust_sprite_fps", CandyLocale.t("Bust FPS"), 1, 120, 0.5,
		CandyLocale.t("Sprite sheets and frame folders of busts play at this rate in the dropdown previews."), 30.0)
	add_number("bg_sprite_fps", CandyLocale.t("Background FPS"), 1, 120, 0.5,
		CandyLocale.t("Sprite sheets and frame folders of backgrounds and Media Play images play at this rate in the dropdown previews."), 30.0)
	add_separator()

	add_heading(CandyLocale.t("Advanced Speech Editor"))
	add_note(CandyLocale.t("A marker stands for a BBCode tag in the text, where the tags are hidden. Each Advanced Speech Editor can use these, or its own (its Options)."))
	add_choice(CandyAdvancedSpeechEditorWidget.SETTING_MARKERS, CandyLocale.t("Tag markers"),
		CandyAdvancedSpeechEditorWidget.mode_options(),
		CandyLocale.t("Off: no markers.\nOn: a marker for every tag.\nSmart: a marker for a tag and its closing tag with nothing between them, and for the tags at the start or end of a line, so the caret can go before or after them."),
		CandyAdvancedSpeechEditorWidget.DEFAULT_MARKERS)
	add_text(CandyAdvancedSpeechEditorWidget.SETTING_MARKER_CHARACTER, CandyLocale.t("Marker character"),
		CandyLocale.t("The character a marker shows (one)."), CandyBBCodeEdit.DEFAULT_MARKER_CHARACTER)
	_add_marker_color(CandyLocale.t("Marker color"),
		CandyLocale.t("For the current theme: each theme has its own. Made lighter or darker where it doesn't stand out enough from the text's background.\nRight-click to copy, paste or remove it. Ctrl+click to paste."))
	add_separator()

	add_heading(CandyLocale.t("Undo"))
	add_number("undo_steps_max", CandyLocale.t("Maximum steps"), 0, 999, 1,
		CandyLocale.t("0 means no limit on the number of undo steps."), 25)
	add_number("undo_memory_max", CandyLocale.t("Maximum memory (MB)"), 0, 4096, 1,
		CandyLocale.t("0 means no memory limit."), 0)


func refresh() -> void:
	super.refresh()
	_marker_color.color = CandyAdvancedSpeechEditorWidget.theme_marker_color(
		draft.get_dictionary(CandyAdvancedSpeechEditorWidget.SETTING_MARKER_COLOR), _theme_id())


#* Get the Theme page's theme, as the app resolves it:
func _theme_id() -> String:
	return CandyTheme.resolved_id(str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME)))			#/ A missing theme resolves to the default


#* Get the marker color's draft key: "tag_marker_colors/<theme id>":
func _marker_key() -> String:
	return "/".join([CandyAdvancedSpeechEditorWidget.SETTING_MARKER_COLOR, _theme_id()])


#* Add the per-theme marker color row:
func _add_marker_color(label_text: String, tooltip: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	_marker_color = ColorPickerButton.new()
	_marker_color.custom_minimum_size.x = 120
	_marker_color.tooltip_text = tooltip
	_marker_color.color_changed.connect(func(color: Color): draft.set_value(_marker_key(), color))
	_color_menu = CandyOverrideMenu.new()
	add_child(_color_menu)
	_color_menu.add_to_color(_marker_color,
		func(color: Color):
			draft.set_value(_marker_key(), color)
			refresh(),
		func():
			draft.erase_value(_marker_key())
			refresh(),
		func() -> bool: return draft.has_value(_marker_key()))
	row.add_child(_marker_color)
	add_custom(row)


#* Get a preview width's tooltip (what: CandyLocale.t("a portrait (Spoken Line)")):
func _preview_tooltip(what: String) -> String:
	return CandyLocale.t("The width of the preview played beside the pointer when %s is hovered in a dropdown. Its height follows the file's proportions.") % what

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAdvancedSpeechEditorSettings
extends CandySpeechEditorSettings

var _markers: OptionButton
var _default_color: CheckBox
var _marker_color: ColorPickerButton


func _init() -> void:
	#? Builds the Speech Editor's rows and _root (the parent's _init hasn't run yet).
	super()
	title = CandyLocale.t("Advanced Speech Editor")

	_root.add_child(HSeparator.new())

	var markers_row := HBoxContainer.new()
	_root.add_child(markers_row)
	var markers_label := Label.new()
	markers_label.text = CandyLocale.t("Tag markers")
	markers_label.custom_minimum_size.x = LABEL_WIDTH
	markers_label.tooltip_text = CandyLocale.t("Which hidden tags show as a marker in the text. Off: none. On: every tag. Smart: a tag and its closing tag with nothing between them, and the tags at the start or end of a line, so the caret can go before or after them.")
	markers_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	markers_row.add_child(markers_label)
	_markers = OptionButton.new()
	_markers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_markers.fit_to_longest_item = false
	markers_row.add_child(_markers)

	var color_row := HBoxContainer.new()
	_root.add_child(color_row)
	var color_label := Label.new()
	color_label.text = CandyLocale.t("Marker color")
	color_label.custom_minimum_size.x = LABEL_WIDTH
	color_label.tooltip_text = CandyLocale.t("Made lighter or darker where it doesn't stand out enough from the background.")
	color_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	color_row.add_child(color_label)
	_default_color = CheckBox.new()
	_default_color.text = CandyLocale.t("Default")
	_default_color.tooltip_text = CandyLocale.t("The marker color of Settings > UI > Editor.")
	_default_color.toggled.connect(_on_default_color_toggled)
	color_row.add_child(_default_color)
	_marker_color = ColorPickerButton.new()
	_marker_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_row.add_child(_marker_color)


#* Load the marker settings:
func _load_extra(config: Dictionary) -> void:
	#Ł Rebuilt on every open - Default names the setting's current mode:
	_markers.clear()
	var setting := CandyAdvancedSpeechEditorWidget.setting_mode()
	_markers.add_item(CandyLocale.t("Default (%s)") % CandyAdvancedSpeechEditorWidget.mode_label(setting))
	_markers.set_item_metadata(0, CandyAdvancedSpeechEditorWidget.MARKERS_DEFAULT)
	_markers.set_item_tooltip(0, CandyLocale.t("The tag markers of Settings > UI > Editor."))
	for option in CandyAdvancedSpeechEditorWidget.mode_options():
		_markers.add_item(str(option["label"]))
		_markers.set_item_metadata(_markers.item_count - 1, str(option["value"]))
	var own := str(config.get(CandyAdvancedSpeechEditorWidget.CONFIG_MARKERS, CandyAdvancedSpeechEditorWidget.MARKERS_DEFAULT))
	_markers.select(0)
	for i in _markers.item_count:
		if str(_markers.get_item_metadata(i)) == own:
			_markers.select(i)

	var own_color: Variant = config.get(CandyAdvancedSpeechEditorWidget.CONFIG_MARKER_COLOR, "")
	_default_color.set_pressed_no_signal(not has_color(own_color))
	_on_default_color_toggled(_default_color.button_pressed)
	if has_color(own_color):
		_marker_color.color = to_color(own_color, CandyBBCodeEdit.DEFAULT_MARKER_COLOR)


func _extra_config() -> Dictionary:
	var color_value := ""
	if not _default_color.button_pressed:
		color_value = var_to_str(_marker_color.color)
	var widget_mode := CandyAdvancedSpeechEditorWidget.MARKERS_DEFAULT
	if _markers.selected >= 0:
		widget_mode = str(_markers.get_item_metadata(_markers.selected))
	return {
		CandyAdvancedSpeechEditorWidget.CONFIG_MARKERS: widget_mode,
		CandyAdvancedSpeechEditorWidget.CONFIG_MARKER_COLOR: color_value,
	}


#* Default shows the setting's color:
func _on_default_color_toggled(on: bool) -> void:
	_marker_color.disabled = on
	if on:
		_marker_color.color = CandyAdvancedSpeechEditorWidget.setting_color()

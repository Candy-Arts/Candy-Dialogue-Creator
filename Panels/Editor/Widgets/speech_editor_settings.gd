#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeechEditorSettings
extends AcceptDialog

signal applied(config: Dictionary)

#^ Content column width:
#? Wrapping labels need an explicit width, or the dialog opens too tall.
const CONTENT_WIDTH := 428
const LABEL_WIDTH := 100
const DEFAULT_TEXT_COLOR := Color.BLACK
const DEFAULT_BACKGROUND_COLOR := Color.WHITE
const MAX_FONT_SIZE := 200
#^ The RichTextLabel fonts and sizes a picked font replaces (the monospace one is kept, for code):
const RICH_FONTS: Array[StringName] = [&"normal_font", &"bold_font", &"italics_font", &"bold_italics_font"]
const RICH_FONT_SIZES: Array[StringName] = [&"normal_font_size", &"bold_font_size", &"italics_font_size", &"bold_italics_font_size"]

#^ The content column, so subclasses can add rows to it:
var _root: VBoxContainer
var _reference: LineEdit
var _random: OptionButton
var _tts: CheckBox
var _show_variation: CheckBox
var _text_color: ColorPickerButton
var _background_color: ColorPickerButton
var _font: CandyFontPicker
var _font_size: SpinBox
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Speech Editor")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(460, 0)

	_root = VBoxContainer.new()
	_root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(_root)

	var reference_row := HBoxContainer.new()
	_root.add_child(reference_row)
	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	reference_label.custom_minimum_size.x = LABEL_WIDTH
	reference_label.tooltip_text = CandyLocale.t("Shows the variation picked in the Variation Selector with this reference.")
	reference_row.add_child(reference_label)
	_reference = LineEdit.new()
	_reference.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_row.add_child(_reference)

	_root.add_child(HSeparator.new())

	var random_row := HBoxContainer.new()
	_root.add_child(random_row)
	var random_label := Label.new()
	random_label.text = CandyLocale.t("Random tag")
	random_label.custom_minimum_size.x = LABEL_WIDTH
	random_label.tooltip_text = CandyLocale.t("Shows this random variation of the selected variation, e.g. Default_S=F_#2 when Default_S=F or Default_S=F_#1 is selected.")
	random_row.add_child(random_label)
	_random = OptionButton.new()
	_random.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_random.fit_to_longest_item = false
	random_row.add_child(_random)

	_tts = CheckBox.new()
	_tts.text = CandyLocale.t("Show the TTS variation")
	_tts.tooltip_text = CandyLocale.t("Shows the text passed to Text To Speech, e.g. Default_S=F_TTS. A selected TTS variation is shown as TTS either way.")
	_root.add_child(_tts)

	_show_variation = CheckBox.new()
	_show_variation.text = CandyLocale.t("Show the variation name")
	_show_variation.tooltip_text = CandyLocale.t("Shows the variation's name above the text. Off leaves more room for the text.")
	_root.add_child(_show_variation)

	_root.add_child(HSeparator.new())

	_text_color = _add_color_row(_root, CandyLocale.t("Text"), CandyLocale.t("The color of the text, as in the dialogue box."))
	_background_color = _add_color_row(_root, CandyLocale.t("Background"), CandyLocale.t("The color behind the text, as in the dialogue box."))

	var font_tooltip := CandyLocale.t("The font of the text, as in the dialogue box: a font file from the fonts folder. Theme font keeps the font of Settings > Text.")
	var font_row := _add_row(_root, CandyLocale.t("Font"), font_tooltip)
	_font = CandyFontPicker.new(CandyLocale.t("Theme font"))
	_font.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_font.set_tooltip(font_tooltip)
	font_row.add_child(_font)

	var size_tooltip := CandyLocale.t("The size of the text. 0 keeps the size of Settings > Text.")
	var size_row := _add_row(_root, CandyLocale.t("Text size"), size_tooltip)
	_font_size = SpinBox.new()
	_font_size.min_value = 0
	_font_size.max_value = MAX_FONT_SIZE
	_font_size.step = 1
	_font_size.tooltip_text = size_tooltip
	size_row.add_child(_font_size)

	_min_size = CandyMinSizeFields.new()
	_root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func _add_color_row(root: VBoxContainer, label_text: String, tooltip: String) -> ColorPickerButton:
	var row := _add_row(root, label_text, tooltip)
	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(picker)
	return picker


#* A row with its label, for a control to be added:
func _add_row(root: VBoxContainer, label_text: String, tooltip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	root.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	return row


func open(config: Dictionary) -> void:
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	_load_random(str(config.get("random_tag", "")))
	_tts.button_pressed = bool(config.get("tts", false))
	_show_variation.button_pressed = CandyVariantFile.to_bool(config.get("show_variation", true), true)
	_text_color.color = text_color_of(config, false)
	_background_color.color = background_color_of(config, false)
	_font.set_font(str(config.get("font", "")))
	_font_size.value = font_size_of(config)
	_load_extra(config)
	#? Below any rows a subclass added after this class's _init().
	_root.move_child(_min_size, -1)
	_min_size.load_config(config)

	#Ł The dialog is reused - drop the previous size:
	reset_size()
	popup_centered()


#* Fill the random tags (rebuilt on every open, since they're edited in the settings):
func _load_random(current: String) -> void:
	_random.clear()
	_random.add_item(CandyLocale.t("As selected"))
	_random.set_item_metadata(0, "")
	_random.set_item_tooltip(0, CandyLocale.t("Keeps the selected variation's own random tag, if it has one."))
	_random.select(0)

	var known := CandyVariationData.new(CandySettingsDraft.new()).random_tags()
	var tags := known.duplicate()
	#% A tag removed from the settings stays selectable, so opening the dialog changes nothing:
	if current != "" and not tags.has(current):
		tags.append(current)
	for tag in tags:
		var text := str(tag)
		var item_text := text
		if not known.has(text):
			item_text = CandyLocale.t("%s (no longer in the settings)") % text
		_random.add_item(item_text)
		var index := _random.item_count - 1
		_random.set_item_metadata(index, text)
		if text == current:
			_random.select(index)


func _selected_random() -> String:
	if _random.selected < 0:
		return ""
	return str(_random.get_item_metadata(_random.selected))


#* Emit the config (colors as var_to_str(), as 1.1 profiles hold them):
func _apply() -> void:
	var result := {
		"reference": _reference.text.strip_edges(),
		"random_tag": _selected_random(),
		"tts": _tts.button_pressed,
		"show_variation": _show_variation.button_pressed,
		"text_color": var_to_str(_text_color.color),
		"background_color": var_to_str(_background_color.color),
		"font": _font.get_font(),
		"font_size": int(_font_size.value),
	}
	result.merge(_extra_config(), true)
	_min_size.write_config(result)
	applied.emit(result)


#* Overridden by subclasses to show their own options:
func _load_extra(_config: Dictionary) -> void:
	pass


#* Overridden by subclasses to return their own options:
func _extra_config() -> Dictionary:
	return {}


#& Stored colors

#* A Speech Editor's or Viewer's text color:
static func text_color_of(config: Dictionary, follow_theme := true) -> Color:
	return _color_of(config, "text_color", "text", DEFAULT_TEXT_COLOR, follow_theme)			#/ The theme's when at the default and follow_theme


static func background_color_of(config: Dictionary, follow_theme := true) -> Color:
	return _color_of(config, "background_color", "background", DEFAULT_BACKGROUND_COLOR, follow_theme)


static func _color_of(config: Dictionary, key: String, theme_key: String, default_color: Color,
		follow_theme: bool) -> Color:
	var color := to_color(config.get(key, ""), default_color)
	if follow_theme and color.is_equal_approx(default_color):
		var from_theme = CandyTheme.speech_colors().get(theme_key)
		if from_theme is Color:
			return from_theme
	return color


static func has_color(value: Variant) -> bool:
	if value is Color:
		return true
	if value is String and value != "":
		return str_to_var(value) is Color
	return false


static func to_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String and value != "":
		var parsed = str_to_var(value)
		if parsed is Color:
			return parsed
	return fallback


#& Stored font

#* A Speech Editor's or Viewer's text size, 0 for the theme's:
static func font_size_of(config: Dictionary) -> int:
	var value = config.get("font_size", 0)
	if value is String and not value.is_valid_int():
		return 0
	return clampi(int(value), 0, MAX_FONT_SIZE)


#* Give control the font and text size of config, or the theme's:
#? rich: the control draws with RichTextLabel's fonts (a RichTextLabel, a CandyBBCodeEdit), else TextEdit's.
static func apply_font(control: Control, config: Dictionary, rich: bool) -> void:
	var font: Font = CandyTheme.picked_font(str(config.get("font", "")))
	var font_size := font_size_of(config)
	#¦ 1. Rich text: the normal font and its bold and italic versions:
	if rich:
		var fonts := {}
		if font != null:
			fonts = CandyThemeDefaults.rich_text_fonts(font)
		for item in RICH_FONTS:
			if fonts.has(item):
				control.add_theme_font_override(item, CandyTheme.with_fallbacks(fonts[item], true))
			else:
				control.remove_theme_font_override(item)
		for item in RICH_FONT_SIZES:
			if font_size > 0:
				control.add_theme_font_size_override(item, font_size)
			else:
				control.remove_theme_font_size_override(item)
	#¦ 2. Plain text:
	else:
		if font != null:
			control.add_theme_font_override(&"font", CandyTheme.with_fallbacks(font, true))
		else:
			control.remove_theme_font_override(&"font")
		if font_size > 0:
			control.add_theme_font_size_override(&"font_size", font_size)
		else:
			control.remove_theme_font_size_override(&"font_size")

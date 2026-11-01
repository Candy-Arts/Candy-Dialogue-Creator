#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeechViewerWidget
extends CandyAreaWidget

const VARIATIONS_FIELD := "Variations"
const TEXT_FIELD := "Text"
const MIN_HEIGHT := 32
const DEFAULT_BBCODE := true
#^ RichTextLabel styleboxes that draw its background ("focus" is drawn on top, kept):
const BACKGROUND_STYLES: PackedStringArray = ["normal"]

#^ Id of CandyLocale.t("Options") in the RichTextLabel's own menu, well above its own ids:
const MENU_WIDGET_SETTINGS := 1000

var _header: HBoxContainer
var _title: Label
var _view: RichTextLabel
var _settings: CandySpeechViewerSettings
var _line_path: Array = []


#* Needs the line's Variations:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD)


#* Shows the Group's variation; in Translate mode the source, unless "translation" is on:
func variation_group_config(p_config: Dictionary, refs: Dictionary, mode: String) -> Variant:
	var result := p_config.duplicate(true)
	result["reference"] = refs["variation"]
	if mode == CandyVariationEditorWidget.MODE_TRANSLATE and not bool(p_config.get("translation", false)):
		result["reference"] = refs["source"]
	result["random_tag"] = ""
	result["tts"] = false
	return result


func show_placeholder() -> void:
	if _view == null:
		return
	_line_path = []
	_view.text = CandyLocale.t(CandyVariationEditorWidget.PLACEHOLDER_TEXT)
	_title.text = CandyLocale.t(CandyVariationEditorWidget.PLACEHOLDER_VARIATION)
	_title.tooltip_text = ""


func _on_configured() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(root)

	var header := HBoxContainer.new()
	header.visible = CandyVariantFile.to_bool(config.get("show_variation", true), true)
	root.add_child(header)
	_header = header

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	header.add_child(_title)

	var settings_button := Button.new()
	settings_button.text = "..."
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.tooltip_text = CandyLocale.t("Reference, variation, colors and BBCode")
	settings_button.pressed.connect(_open_settings)
	header.add_child(settings_button)

	_view = RichTextLabel.new()
	_view.theme_type_variation = CandyThemeDefaults.SPEECH_VIEWER
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.custom_minimum_size.y = MIN_HEIGHT
	_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_view.scroll_active = true
	#? Read-only, but copying out of it is still useful.
	_view.selection_enabled = true
	_view.context_menu_enabled = true
	_view.bbcode_enabled = bool(config.get("bbcode", DEFAULT_BBCODE))
	root.add_child(_view)

	#? Added to the RichTextLabel's own menu, keeping its entries (copy...).
	_view.get_menu().id_pressed.connect(func(id: int):
		if id == MENU_WIDGET_SETTINGS:
			_open_settings())
	_add_settings_menu_item()

	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	_refresh()


func _notification(what: int) -> void:
	#? Also sent on entering the tree, the first moment the real theme can be read.
	if what == NOTIFICATION_THEME_CHANGED:
		_apply_colors()
		_apply_font()


#& Showing

func _refresh() -> void:
	if _view == null:
		return
	var variation := _current_variation()
	var variations = _variations()
	var index := _index_of(variations, variation)

	if not variations is Array:
		_title.text = CandyLocale.t("No variations")
		_title.tooltip_text = CandyLocale.t("This line type has no variations.")
	else:
		_title.text = variation
		_title.tooltip_text = ""
		if index < 0:
			_title.tooltip_text = CandyLocale.t("This line doesn't have this variation.")

	var shown := _stored_text(variations, index)
	#? Reassigning the same text would reset the scroll and selection.
	if _view.text != shown:
		_view.text = shown


#* The selected variation, as this widget is set to show it:
func _current_variation() -> String:
	var selected := CandyVariationSelection.DEFAULT_VARIATION
	var shared := selection()
	if shared != null:
		selected = shared.get_selected(reference())
	#? "Default_S=F_#1" with random tag "#2" and TTS on -> "Default_S=F_#2_TTS".
	return CandyVariations.resolve_variation(selected,
		str(config.get("random_tag", "")), bool(config.get("tts", false)))


#* The line's Variations array, or null:
func _variations() -> Variant:
	if not CandyDialogue.is_line_path(_line_path):
		return null
	return CandyDialogue.get_field(_line_path, [VARIATIONS_FIELD], null)


func _index_of(variations: Variant, variation: String) -> int:
	if not variations is Array:
		return -1
	for i in variations.size():
		var entry = variations[i]
		if entry is Dictionary and entry.size() > 0 and str(entry.keys()[0]) == variation:
			return i
	return -1


func _stored_text(variations: Variant, index: int) -> String:
	if index < 0:
		return ""
	var entry: Dictionary = variations[index]
	var value = entry[entry.keys()[0]]
	if value is Dictionary:
		return str(value.get(TEXT_FIELD, ""))
	return ""


#& Input

func _on_selection_changed(changed_reference: String, _variation_name: String) -> void:
	if changed_reference == reference():
		_refresh()


#* Add CandyLocale.t("Options") to the text's menu (the text fills the widget):
func _add_settings_menu_item() -> void:
	var menu := _view.get_menu()
	menu.add_separator()
	menu.add_item(CandyLocale.t("Options"), MENU_WIDGET_SETTINGS)


func has_settings() -> bool:
	return true


func open_settings() -> void:
	_open_settings()


func _open_settings() -> void:
	if _settings == null:
		_settings = CandySpeechViewerSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config)


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	#? Saving usually rebuilds this widget; not in every context.
	_header.visible = CandyVariantFile.to_bool(config.get("show_variation", true), true)
	_view.bbcode_enabled = bool(config.get("bbcode", DEFAULT_BBCODE))
	_apply_colors()
	_apply_font()
	_view.text = ""  #/ Re-parse the text in the new mode
	_refresh()


#& Colors

func _apply_colors() -> void:
	if _view == null:
		return

	#? Only the default - [color] tags in the text still win.
	_view.add_theme_color_override("default_color", CandySpeechEditorSettings.text_color_of(config))

	#? Read through this widget - the label may not have the theme yet when they enter the tree.
	var background := CandySpeechEditorSettings.background_color_of(config)
	for style_name in BACKGROUND_STYLES:
		_view.add_theme_stylebox_override(style_name, _colored_style(
			CandyThemeDefaults.variation_stylebox(self, style_name, CandyThemeDefaults.SPEECH_VIEWER), background))


#* The font and text size of the Options, or the theme's:
func _apply_font() -> void:
	if _view == null:
		return
	CandySpeechEditorSettings.apply_font(_view, config, true)


#* A copy of the theme's stylebox with a new background:
func _colored_style(base: StyleBox, background: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat
	if base is StyleBoxFlat:
		box = base.duplicate()
	else:
		box = StyleBoxFlat.new()
		#Ł Not flat - keep its margins:
		if base != null:
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				box.set_content_margin(side, base.get_margin(side))
	box.bg_color = background
	return box
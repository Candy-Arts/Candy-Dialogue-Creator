#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeechEditorWidget
extends CandyAreaWidget

const VARIATIONS_FIELD := "Variations"
const TEXT_FIELD := "Text"
const MIN_HEIGHT := 32
#^ Typing pause, in seconds, before the text is written:
const WRITE_DELAY := 0.4
#^ TextEdit styleboxes that draw its background ("focus" is an outline on top, kept):
const BACKGROUND_STYLES: PackedStringArray = ["normal", "read_only"]

#^ Id of CandyLocale.t("Options") in the TextEdit's own menu, well above its own ids:
const MENU_WIDGET_SETTINGS := 1000

var _header: HBoxContainer
var _title: Label
var _message: Label
var _edit: Control
var _settings: CandySpeechEditorSettings
var _line_path: Array = []
#^ The variation on screen, which edits are written to:
#? So a selection change can save the old variation before showing the new one.
var _shown_variation: String = ""
#^ The text as loaded or last written:
#? Only a difference counts as an edit, so a stale line path never writes untyped text.
var _loaded_text: String = ""
#^ Runs from the last keystroke to the write:
var _write_timer: Timer
#^ The undo step of the current typing (CandyDialogue.new_typing_id()), 0 before its first write:
var _typing_id := 0


#* Needs the line's Variations:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD)


#* Edits the Group's variation, or in TTS mode its TTS twin:
func variation_group_config(p_config: Dictionary, refs: Dictionary, mode: String) -> Variant:
	var result := p_config.duplicate(true)
	result["reference"] = refs["variation"]
	result["random_tag"] = ""
	result["tts"] = mode == CandyVariationEditorWidget.MODE_TTS
	return result


#* Read-only sample text:
func show_placeholder() -> void:
	if _edit == null:
		return
	_line_path = []
	_set_edit_editable(false)
	_set_edit_text(CandyLocale.t(CandyVariationEditorWidget.PLACEHOLDER_TEXT))
	_loaded_text = _edit_text()
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
	#? Clipped text has no minimum width - without this, the name gets none.
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	header.add_child(_title)

	_message = CandyChecks.new_message_label()
	header.add_child(_message)

	_edit = _make_edit()
	_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_edit.custom_minimum_size.y = MIN_HEIGHT
	root.add_child(_edit)

	#? Added to the text's own menu, keeping its entries (copy...).
	_edit_menu().id_pressed.connect(func(id: int):
		if id == MENU_WIDGET_SETTINGS:
			_open_settings())
	_add_settings_menu_item()

	_write_timer = Timer.new()
	_write_timer.one_shot = true
	_write_timer.wait_time = WRITE_DELAY
	_write_timer.timeout.connect(_commit)
	add_child(_write_timer)

	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)


func bind_line(line_path: Array) -> void:
	if line_path != _line_path:
		_finish_typing()  #/ Still aimed at the previous line
		_line_path = line_path.duplicate()
		_show_variation(true)
		return
	_show_variation(false)


#* The line whose text it edits ([] if none):
func edited_line_path() -> Array:
	return _line_path.duplicate()


#* The variation whose text it edits ("" if none yet):
func edited_variation() -> String:
	return _shown_variation


func _notification(what: int) -> void:
	#? Also sent on entering the tree, the first moment the real theme can be read.
	if what == NOTIFICATION_THEME_CHANGED:
		_apply_colors()
		_apply_font()


#& Showing

#* Show the current variation's text:
func _show_variation(force: bool) -> void:
	if _edit == null:
		return
	var variation := _current_variation()
	var variation_changed := variation != _shown_variation
	_shown_variation = variation

	var variations = _variations()
	var has_list: bool = variations is Array
	var index := _index_of(variations, variation)
	_set_edit_editable(has_list)
	_update_title(has_list, index)
	_show_checks(variations, index)

	#% While typing, leave the text alone so the caret and unsaved edit stay put:
	#? force: the line or variation changed, old text already saved.
	if not force and not variation_changed and _is_typing():
		return

	var stored := _stored_text(variations, index)
	_loaded_text = stored
	if _edit_text() != stored:
		_set_edit_text(stored)


#* Show the Text checks for the shown variation (none for one the line doesn't hold yet):
func _show_checks(variations: Variant, index: int) -> void:
	if index < 0:
		CandyChecks.show_messages(_message, [])
		return
	var line := CandyDialogue.line_at(_line_path)
	var line_type := CandyDialogue.line_type(line)
	var spec := {}
	for field in CandySchemas.field_specs(line_type, CandyDialogue.line_data(line)):
		if field is Dictionary and str(field.get("id", "")) == VARIATIONS_FIELD and field.get("fields") is Array:
			for sub in field["fields"]:
				if sub is Dictionary and str(sub.get("id", "")) == TEXT_FIELD:
					spec = sub
	var check_context := CandyCheckContext.new(_stored_text(variations, index), spec)
	check_context.line_type = line_type
	check_context.line_path = _line_path
	check_context.field_path = [VARIATIONS_FIELD, index, CandyDialogue.ENTRY_VALUE, TEXT_FIELD]
	CandyChecks.show_messages(_message, CandyChecks.messages(spec, check_context))


func _update_title(has_list: bool, index: int) -> void:
	if not has_list:
		_title.text = CandyLocale.t("No variations")
		_title.tooltip_text = CandyLocale.t("This line type has no variations.")
		_set_edit_placeholder(CandyLocale.t("This line has no variations."))
		return
	_title.text = _shown_variation
	_title.tooltip_text = ""
	if index < 0:
		_title.tooltip_text = CandyLocale.t("This line doesn't have this variation yet. Typing creates it.")
	_set_edit_placeholder(CandyLocale.t("Type to write the %s variation.") % _shown_variation)


#* The selected variation, as this widget is set to show it:
func _current_variation() -> String:
	var selected := CandyVariationSelection.DEFAULT_VARIATION
	var shared := selection()
	if shared != null:
		selected = shared.get_selected(reference())
	#? "Default_S=F_#1" with random tag "#2" and TTS on -> "Default_S=F_#2_TTS".
	return CandyVariations.resolve_variation(selected,
		str(config.get("random_tag", "")), bool(config.get("tts", false)))


#& Data

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


#* Write the text, if changed, into this typing's undo step:
func _commit() -> void:
	if _write_timer != null:
		_write_timer.stop()
	if _edit == null or not CandyDialogue.is_line_path(_line_path):
		return
	var new_text := _edit_text()
	if new_text == _loaded_text:
		return
	#? Set first - the write comes back through bind_line(), which must see it as saved.
	_loaded_text = new_text
	if _typing_id == 0:
		_typing_id = CandyDialogue.new_typing_id()
	CandyDialogue.begin_step("", _typing_id)
	_write(_line_path, _shown_variation, new_text)
	CandyDialogue.end_step()


#* Typing is over - write, and start a new undo step next time:
func _finish_typing() -> void:
	_commit()
	_typing_id = 0


#* The text changed - write once typing pauses (text set by the widget isn't typed):
func _on_text_typed() -> void:
	_publish_typed()
	if _write_timer != null and _is_typing():
		_write_timer.start()


#* Let the Counters count along with the typing:
func _publish_typed() -> void:
	var shared := selection()
	if shared != null:
		shared.publish_typed(_shown_variation, _edit_text())


func _write(line_path: Array, variation: String, new_text: String) -> void:
	var variations = CandyDialogue.get_field(line_path, [VARIATIONS_FIELD], null)
	if not variations is Array:
		return

	var index := _index_of(variations, variation)
	if index >= 0:
		CandyDialogue.set_field(line_path,
			[VARIATIONS_FIELD, index, CandyDialogue.ENTRY_VALUE, TEXT_FIELD], new_text)
		return

	#% Don't create an empty variation:
	if new_text == "":
		return
	var template := _entry_template(line_path, variation)
	template[TEXT_FIELD] = new_text
	CandyDialogue.add_entry(line_path, [VARIATIONS_FIELD], variation, template)


#* A new Variations entry from the schema, in the direction of the variation's language:
func _entry_template(line_path: Array, variation: String) -> Dictionary:
	var line := CandyDialogue.line_at(line_path)
	var specs := CandySchemas.field_specs(CandyDialogue.line_type(line), CandyDialogue.line_data(line))
	for spec in specs:
		if spec is Dictionary and str(spec.get("id", "")) == VARIATIONS_FIELD:
			var template := CandySchemas.entry_defaults(spec)
			CandyVariationData.new(CandySettingsDraft.new()).apply_language_direction(template, variation)
			return template
	return {}


#& Input

func _on_selection_changed(changed_reference: String, _variation_name: String) -> void:
	if changed_reference != reference():
		return
	#? The selector's rows don't take focus, so the edit isn't saved yet.
	_finish_typing()
	_show_variation(true)


#* Add CandyLocale.t("Options") to the text's menu (the text fills the widget):
func _add_settings_menu_item() -> void:
	var menu := _edit_menu()
	menu.add_separator()
	menu.add_item(CandyLocale.t("Options"), MENU_WIDGET_SETTINGS)


func has_settings() -> bool:
	return true


func open_settings() -> void:
	_open_settings()


func _open_settings() -> void:
	_commit()
	if _settings == null:
		_settings = _new_settings()
		if widget_id != "":
			_settings.title = CandyWidgets.get_title(widget_id)
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config)


#* The settings dialog; subclasses with options of their own give their own:
func _new_settings() -> CandySpeechEditorSettings:
	return CandySpeechEditorSettings.new()


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	#? Saving usually rebuilds this widget; not in every context.
	_header.visible = CandyVariantFile.to_bool(config.get("show_variation", true), true)
	_apply_colors()
	_apply_font()
	_show_variation(true)


#& Text control

#* The control the text is typed in, signals connected:
func _make_edit() -> Control:
	var edit := TextEdit.new()
	edit.theme_type_variation = CandyThemeDefaults.SPEECH_EDITOR
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.focus_exited.connect(_finish_typing)
	edit.text_changed.connect(_on_text_typed)
	return edit


func _edit_text() -> String:
	return (_edit as TextEdit).text


func _set_edit_text(value: String) -> void:
	(_edit as TextEdit).text = value


func _set_edit_editable(on: bool) -> void:
	(_edit as TextEdit).editable = on


func _set_edit_placeholder(value: String) -> void:
	(_edit as TextEdit).placeholder_text = value


#* Whether the user is typing (the text isn't reloaded under them):
func _is_typing() -> bool:
	return _edit.has_focus()


#* The control's own right-click menu, which gets CandyLocale.t("Options"):
func _edit_menu() -> PopupMenu:
	return (_edit as TextEdit).get_menu()


#& Colors

func _apply_colors() -> void:
	if _edit == null:
		return

	var text_color := CandySpeechEditorSettings.text_color_of(config)
	_edit.add_theme_color_override("font_color", text_color)
	_edit.add_theme_color_override("font_readonly_color", Color(text_color, text_color.a * 0.6))
	_edit.add_theme_color_override("caret_color", text_color)

	#? Read through this widget - the TextEdit may not have the theme yet when they enter the tree.
	var background := CandySpeechEditorSettings.background_color_of(config)
	for style_name in BACKGROUND_STYLES:
		_edit.add_theme_stylebox_override(style_name, _colored_style(
			CandyThemeDefaults.variation_stylebox(self, style_name, _edit.theme_type_variation), background))


#* The font and text size of the Options, or the theme's:
func _apply_font() -> void:
	if _edit == null:
		return
	#? A CandyBBCodeEdit (Advanced Speech Editor) draws with RichTextLabel's fonts.
	CandySpeechEditorSettings.apply_font(_edit, config, not (_edit is TextEdit))


#* A copy of the theme's stylebox with a new background:
func _colored_style(base: StyleBox, background: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat
	if base is StyleBoxFlat:
		box = base.duplicate()			#/ Keeps its margins, corners and border
	else:
		box = StyleBoxFlat.new()
		#Ł Keep its margins:
		if base != null:
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				box.set_content_margin(side, base.get_margin(side))
	box.bg_color = background
	return box
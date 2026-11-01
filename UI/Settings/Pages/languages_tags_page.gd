#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLanguagesTagsPage
extends CandySettingsPage

var _data: CandyVariationData

var _language_input: LineEdit
var _language_direction: OptionButton
var _custom_input: LineEdit
var _random_input: LineEdit
var _language_error: Label
var _custom_error: Label
var _random_error: Label
var _languages_box: CandyListRows
var _custom_box: CandyListRows
var _random_box: CandyListRows


func build() -> void:
	_data = CandyVariationData.new(draft)

	add_heading(CandyLocale.t("Languages"))
	add_note(CandyLocale.t("Hidden languages stay in the database but are left out of the editor, for translators who only work in some of them. \"%s\" is always present and comes first.") % CandyVariationData.DEFAULT_LANGUAGE)
	add_note(CandyLocale.t("A language's direction is the one its new variations start with. Changing it doesn't change the variations already written."))
	_language_direction = _direction_button(CandyVariationData.DEFAULT_DIRECTION)
	_language_input = _add_input(CandyLocale.t("Add language"), func(text: String): _add_language(text), _language_direction)
	_language_error = _add_error()
	_languages_box = _add_rows()

	add_separator()
	add_heading(CandyLocale.t("Custom tags"))
	add_note(CandyLocale.t("A tag may carry a value after \"=\": \"S=F\" and \"S=M\" are two values of \"S\", so no combination holds both. A tag without \"=\" is its own key."))
	add_note(CandyLocale.t("No spaces, no \"_\", no \"#\", and nothing a file name can't hold — language and tag names end up in translation file names."))
	_custom_input = _add_input(CandyLocale.t("Add tag"), func(text: String): _add_custom_tag(text))
	_custom_error = _add_error()
	_custom_box = _add_rows()

	add_separator()
	add_heading(CandyLocale.t("Random tags"))
	add_note(CandyLocale.t("Alternative texts for the same variation, picked at random by Candy DE. Numbers are yours to choose and don't have to run in sequence."))
	_random_input = _add_input(CandyLocale.t("Add random tag"), func(text: String): _add_random_tag(text))
	_random_error = _add_error()
	_random_box = _add_rows()

	_rebuild()


func refresh() -> void:
	super.refresh()
	_rebuild()


#& Editing

func _add_language(text: String) -> void:
	var direction := _selected_direction(_language_direction)
	var problem := _data.add_language(text.strip_edges(), direction)
	_show_error(_language_error, problem)
	if problem == "":
		_language_input.text = ""
		_rebuild()


func _add_custom_tag(text: String) -> void:
	var problem := _data.add_custom_tag(text.strip_edges())
	_show_error(_custom_error, problem)
	if problem == "":
		_custom_input.text = ""
		_rebuild()


func _add_random_tag(text: String) -> void:
	var problem := _data.add_random_tag(text.strip_edges())
	_show_error(_random_error, problem)
	if problem == "":
		_rebuild()
		#Ł Offer the next free number:
		_random_input.text = _data.next_random()


#& Display

func _rebuild() -> void:
	if _languages_box == null:
		return
	_build_languages()
	_build_tags(_custom_box, _tags_by_key(_data.custom_tags()), func(tag: String): _data.remove_custom_tag(tag))
	_build_tags(_random_box, [_data.random_tags()], func(tag: String): _data.remove_random_tag(tag))
	if _random_input != null and _random_input.text == "":
		_random_input.text = _data.next_random()


func _build_languages() -> void:
	_clear(_languages_box)
	for entry in _data.languages():
		var language := str(entry.get("name", ""))
		var is_hidden := bool(entry.get("hidden", false))
		var row := HBoxContainer.new()
		#? As tall as the buttons, so Default's row (fewer buttons) matches.
		row.custom_minimum_size.y = _button_height()
		_languages_box.add_child(row)

		var label := Label.new()
		label.text = language
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_hidden:
			label.theme_type_variation = CandyThemeDefaults.NOTE
		row.add_child(label)

		var direction_button := _direction_button(_data.language_direction(language))
		direction_button.item_selected.connect(func(_index: int):
			_data.set_language_direction(language, _selected_direction(direction_button)))
		row.add_child(direction_button)

		#% Default can't be hidden or deleted:
		if language == CandyVariationData.DEFAULT_LANGUAGE:
			continue

		var hide_button := Button.new()
		if is_hidden:
			hide_button.text = CandyLocale.t("Show")
		else:
			hide_button.text = CandyLocale.t("Hide")
		hide_button.focus_mode = Control.FOCUS_NONE
		hide_button.pressed.connect(func():
			_data.toggle_language_hidden(language)
			_rebuild())
		row.add_child(hide_button)

		row.add_child(_delete_button(language, func():
			_data.remove_language(language)
			_rebuild()))


#* Build tag rows of small boxes with delete buttons, wrapping:
func _build_tags(box: VBoxContainer, rows: Array, on_delete: Callable) -> void:
	_clear(box)
	var any := false
	for tags in rows:
		if tags.is_empty():
			continue
		any = true
		var flow := HFlowContainer.new()
		box.add_child(flow)
		for tag in tags:
			var text := str(tag)
			flow.add_child(_tag_box(text, func():
				on_delete.call(text)
				_rebuild()))

	if not any:
		var empty := Label.new()
		empty.text = CandyLocale.t("None yet.")
		empty.theme_type_variation = CandyThemeDefaults.NOTE
		box.add_child(empty)


func _tag_box(text: String, on_delete: Callable) -> PanelContainer:
	var tag_box := PanelContainer.new()
	tag_box.theme_type_variation = CandyThemeDefaults.TAG_BOX
	var row := HBoxContainer.new()
	row.theme_type_variation = CandyThemeDefaults.FLUSH_HBOX
	tag_box.add_child(row)

	var label := Label.new()
	label.text = text
	row.add_child(label)
	var delete_button := _delete_button(text, on_delete)
	delete_button.flat = true
	row.add_child(delete_button)
	return tag_box


#* Group custom tags into a row per key ("S=F", "S=M" share one):
#! Expects sorted tags.
func _tags_by_key(tags: Array) -> Array:
	var rows: Array = []
	var last_key := ""
	for tag in tags:
		#? A tag without "=" is its own key.
		var key := str(tag).get_slice("=", 0)
		if rows.is_empty() or key != last_key:
			rows.append([])
			last_key = key
		rows[-1].append(tag)
	return rows


#* Make a text direction dropdown showing direction:
func _direction_button(direction: String) -> OptionButton:
	var button := OptionButton.new()
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = CandyLocale.t("The direction new variations in this language start with.")
	for item in CandyVariationData.DIRECTIONS:
		button.add_item(CandyLocale.t(str(item["label"])))
		button.set_item_metadata(button.item_count - 1, str(item["value"]))
		if str(item["value"]) == direction:
			button.select(button.item_count - 1)
	return button


func _selected_direction(button: OptionButton) -> String:
	if button.selected < 0:
		return CandyVariationData.DEFAULT_DIRECTION
	return str(button.get_item_metadata(button.selected))


func _delete_button(item: String, on_delete: Callable) -> CandyIconButton:
	var button := CandyIconButton.new(&"remove", CandyThemeDefaults.ICONS, "×", CandyLocale.t("Delete %s") % item)
	button.pressed.connect(on_delete)
	return button


#* Get the height of a one-line button:
func _button_height() -> float:
	var font_height := get_theme_font("font", "Button").get_height(get_theme_font_size("font_size", "Button"))
	return font_height + get_theme_stylebox("normal", "Button").get_minimum_size().y


func _clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


#& Building blocks

#* Add a text field and its button (extra, if any, between them):
func _add_input(button_text: String, on_submit: Callable, extra: Control = null) -> LineEdit:
	var row := HBoxContainer.new()
	add_custom(row)

	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(text: String): on_submit.call(text))
	row.add_child(edit)
	if extra != null:
		row.add_child(extra)

	var button := Button.new()
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): on_submit.call(edit.text))
	row.add_child(button)
	return edit


func _add_rows() -> CandyListRows:
	var rows := CandyListRows.new()
	add_list_box(rows)
	return rows


#* Add an error label (hidden while there's no error):
func _add_error() -> Label:
	var label := Label.new()
	label.theme_type_variation = CandyThemeDefaults.ERROR
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.visible = false
	add_custom(label)
	return label


func _show_error(label: Label, message: String) -> void:
	if label == null:
		return
	label.text = message
	label.visible = message != ""

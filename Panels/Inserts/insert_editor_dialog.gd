#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyInsertEditor
extends ConfirmationDialog

const CONTENT_WIDTH := 440
const LABEL_WIDTH := 130
#^ Starting colors of an unchecked color's picker:
const FALLBACK_TEXT_COLOR := Color(0.875, 0.875, 0.875)
const FALLBACK_BACKGROUND_COLOR := Color(0.2, 0.2, 0.24)
const FALLBACK_TEXT_OUTLINE_COLOR := Color(0.0, 0.0, 0.0)
const FALLBACK_BUTTON_OUTLINE_COLOR := Color(0.6, 0.6, 0.65)

var _editing_id := ""

var _type: OptionButton
var _category: LineEdit
var _category_button: Button
var _category_popup: PopupMenu
var _label_edit: LineEdit
var _left: LineEdit
var _middle: LineEdit
var _right: LineEdit
var _text_custom: CheckBox
var _text_color: ColorPickerButton
var _background_custom: CheckBox
var _background_color: ColorPickerButton
var _text_outline_custom: CheckBox
var _text_outline_color: ColorPickerButton
var _button_outline_custom: CheckBox
var _button_outline_color: ColorPickerButton
var _preview: Button
var _error: Label


func _init() -> void:
	title = CandyLocale.t("Create Insert")
	min_size = Vector2i(CONTENT_WIDTH + 30, 0)
	dialog_hide_on_ok = false  #/ Closes once the insert saves

	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(root)

	_type = OptionButton.new()
	_type.add_item(CandyLocale.t("User"))
	_type.set_item_metadata(0, CandyInserts.TYPE_USER)
	_type.set_item_tooltip(0, CandyLocale.t("Saved in user_inserts.txt: available in every profile of this user."))
	_type.add_item(CandyLocale.t("Profile"))
	_type.set_item_metadata(1, CandyInserts.TYPE_PROFILE)
	_type.set_item_tooltip(1, CandyLocale.t("Saved in profile_inserts.txt: only available in this profile."))
	_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_type.item_selected.connect(func(_index: int): _set_error(""))
	_add_row(root, CandyLocale.t("Type"), _type)

	var category_box := HBoxContainer.new()
	category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category = LineEdit.new()
	_category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category.tooltip_text = CandyLocale.t("The category this insert is listed under in the panels' Available list.")
	_category.text_changed.connect(func(_text: String): _set_error(""))
	category_box.add_child(_category)
	_category_button = Button.new()
	_category_button.focus_mode = Control.FOCUS_NONE
	_category_button.tooltip_text = CandyLocale.t("Pick an existing category")
	_category_button.pressed.connect(_open_category_popup)
	category_box.add_child(_category_button)
	_category_popup = PopupMenu.new()
	_category_popup.index_pressed.connect(func(index: int):
		_category.text = _category_popup.get_item_text(index)
		_set_error(""))
	add_child(_category_popup)
	_add_row(root, CandyLocale.t("Category"), category_box)

	_label_edit = _add_text_row(root, CandyLocale.t("Label"), CandyLocale.t("The text on the insert button."))

	root.add_child(HSeparator.new())
	#? Each may hold the color token, like the native color tags.
	_left = _add_text_row(root, CandyLocale.t("Left"),
		CandyLocale.t("Typed before the selected text. %s becomes the color of the Color Selector with the Inserts panel's reference.") % CandyInserts.COLOR_TOKEN)
	_middle = _add_text_row(root, CandyLocale.t("Middle"),
		CandyLocale.t("Replaces each space inside the selected text. Unused without a selection. %s becomes the color of the Color Selector with the Inserts panel's reference.") % CandyInserts.COLOR_TOKEN)
	_right = _add_text_row(root, CandyLocale.t("Right"),
		CandyLocale.t("Typed after the selected text. %s becomes the color of the Color Selector with the Inserts panel's reference.") % CandyInserts.COLOR_TOKEN)

	root.add_child(HSeparator.new())
	var text_row := _add_color_row(root, CandyLocale.t("Text"))
	_text_custom = text_row[0]
	_text_color = text_row[1]
	var background_row := _add_color_row(root, CandyLocale.t("Background"))
	_background_custom = background_row[0]
	_background_color = background_row[1]
	var text_outline_row := _add_color_row(root, CandyLocale.t("Text Outline"))
	_text_outline_custom = text_outline_row[0]
	_text_outline_color = text_outline_row[1]
	_text_outline_custom.tooltip_text = CandyLocale.t("Outlines the letters of the button text.")
	var button_outline_row := _add_color_row(root, CandyLocale.t("Button Outline"))
	_button_outline_custom = button_outline_row[0]
	_button_outline_color = button_outline_row[1]
	_button_outline_custom.tooltip_text = CandyLocale.t("Draws a border around the button.")

	var note := Label.new()
	note.text = CandyLocale.t("An unchecked color follows the theme.")
	note.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(note)

	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(preview_row)
	_preview = Button.new()
	_preview.focus_mode = Control.FOCUS_NONE
	_preview.custom_minimum_size.x = 140
	_preview.tooltip_text = CandyLocale.t("Preview")
	preview_row.add_child(_preview)

	_error = Label.new()
	_error.theme_type_variation = CandyThemeDefaults.ERROR
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.custom_minimum_size.x = CONTENT_WIDTH
	_error.text = " "
	root.add_child(_error)

	register_text_enter(_label_edit)
	confirmed.connect(_on_confirmed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _category_button != null:
		_update_category_icon()


func _update_category_icon() -> void:
	#? Theme's dropdown arrow, so the button stays narrow.
	if _category_button.has_theme_icon("arrow", "OptionButton"):
		_category_button.icon = _category_button.get_theme_icon("arrow", "OptionButton")
		_category_button.text = ""
	else:
		_category_button.text = "v"


#* Open for a new insert:
func open_create() -> void:
	_editing_id = ""
	title = CandyLocale.t("Create Insert")
	ok_button_text = CandyLocale.t("Create")
	_type.select(0)
	_category.text = ""
	_label_edit.text = ""
	_left.text = ""
	_middle.text = ""
	_right.text = ""
	_load_color("", _text_custom, _text_color, FALLBACK_TEXT_COLOR)
	_load_color("", _background_custom, _background_color, FALLBACK_BACKGROUND_COLOR)
	_load_color("", _text_outline_custom, _text_outline_color, FALLBACK_TEXT_OUTLINE_COLOR)
	_load_color("", _button_outline_custom, _button_outline_color, FALLBACK_BUTTON_OUTLINE_COLOR)
	_show()


#* Open for an existing insert:
func open_edit(id: String) -> void:
	var insert := CandyInserts.get_insert(id)
	if insert.is_empty() or CandyInserts.is_native(id):
		return
	_editing_id = id
	title = CandyLocale.t("Edit Insert")
	ok_button_text = CandyLocale.t("Save")
	if insert["type"] == CandyInserts.TYPE_PROFILE:
		_type.select(1)
	else:
		_type.select(0)
	_category.text = str(insert["category"])
	_label_edit.text = str(insert["label"])
	_left.text = str(insert["left"])
	_middle.text = str(insert["middle"])
	_right.text = str(insert["right"])
	_load_color(insert["text_color"], _text_custom, _text_color, FALLBACK_TEXT_COLOR)
	_load_color(insert["background_color"], _background_custom, _background_color,
		FALLBACK_BACKGROUND_COLOR)
	_load_color(insert["text_outline_color"], _text_outline_custom, _text_outline_color,
		FALLBACK_TEXT_OUTLINE_COLOR)
	_load_color(insert["button_outline_color"], _button_outline_custom, _button_outline_color,
		FALLBACK_BUTTON_OUTLINE_COLOR)
	_show()


func _show() -> void:
	_update_category_icon()
	_set_error("")
	_update_preview()
	#Ł Reused dialog - drop the previous size:
	reset_size()
	popup_centered()
	_label_edit.grab_focus()


#& Rows

func _add_row(root: VBoxContainer, label_text: String, field: Control) -> void:
	var row := HBoxContainer.new()
	root.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)


func _add_text_row(root: VBoxContainer, label_text: String, tooltip: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.tooltip_text = tooltip
	edit.text_changed.connect(func(_text: String):
		_set_error("")
		_update_preview())
	_add_row(root, label_text, edit)
	return edit


#* Add a color row - returns [CheckBox, ColorPickerButton], the picker usable while checked:
func _add_color_row(root: VBoxContainer, label_text: String) -> Array:
	var row := HBoxContainer.new()
	root.add_child(row)

	var custom := CheckBox.new()
	custom.text = label_text
	custom.custom_minimum_size.x = LABEL_WIDTH
	custom.tooltip_text = CandyLocale.t("Use a custom color instead of the theme's.")
	row.add_child(custom)

	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.disabled = true
	picker.color_changed.connect(func(_color: Color): _update_preview())
	row.add_child(picker)

	custom.toggled.connect(func(pressed: bool):
		picker.disabled = not pressed
		_update_preview())
	return [custom, picker]


func _load_color(value: Variant, custom: CheckBox, picker: ColorPickerButton, fallback: Color) -> void:
	var is_custom := CandySpeechEditorSettings.has_color(value)
	custom.set_pressed_no_signal(is_custom)
	picker.disabled = not is_custom
	picker.color = CandySpeechEditorSettings.to_color(value, fallback)


#* A color row's value ("" follows the theme):
func _color_value(custom: CheckBox, picker: ColorPickerButton) -> String:
	if custom.button_pressed:
		return var_to_str(picker.color)
	return ""


#& Category picker

func _open_category_popup() -> void:
	_category_popup.clear()
	var names := CandyInserts.categories()
	if names.is_empty():
		_category_popup.add_item(CandyLocale.t("No categories yet"))
		_category_popup.set_item_disabled(0, true)
	for category in names:
		_category_popup.add_item(str(category))
	var anchor := Rect2i(Vector2i(_category_button.get_screen_position()), Vector2i(_category_button.size))
	CandyPopups.popup_at(_category_popup, anchor, _category_button)


#& Saving

func _current_data() -> Dictionary:
	return {
		"id": _editing_id,
		"type": str(_type.get_item_metadata(_type.selected)),
		"category": _category.text.strip_edges(),
		"label": _label_edit.text.strip_edges(),
		#? Not stripped - spaces around a symbol can be intended.
		"left": _left.text,
		"middle": _middle.text,
		"right": _right.text,
		"text_color": _color_value(_text_custom, _text_color),
		"background_color": _color_value(_background_custom, _background_color),
		"text_outline_color": _color_value(_text_outline_custom, _text_outline_color),
		"button_outline_color": _color_value(_button_outline_custom, _button_outline_color),
	}


func _update_preview() -> void:
	var data := _current_data()
	var preview_text := str(data["label"])
	if preview_text == "":
		preview_text = CandyLocale.t("Label")
	_preview.text = preview_text
	CandyInsertsPanel.style_button(_preview, data)


func _on_confirmed() -> void:
	var data := _current_data()
	if data["left"] == "" and data["middle"] == "" and data["right"] == "":
		_set_error(CandyLocale.t("Enter at least one of Left, Middle or Right."))
		return
	var problem := CandyInserts.save_insert(data)
	if problem != "":
		_set_error(problem)
		return
	hide()


func _set_error(message: String) -> void:
	if message == "":
		_error.text = " "
	else:
		_error.text = message
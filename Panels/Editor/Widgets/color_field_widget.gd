#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyColorFieldWidget
extends CandyLineEditWidget

const PICKER_WIDTH := 28

var _picker: ColorPickerButton
#^ The text when the picker opened, to know whether picking changed it:
var _text_before_picking := ""


func _init() -> void:
	super()
	_picker = ColorPickerButton.new()
	_picker.custom_minimum_size.x = PICKER_WIDTH
	_picker.edit_alpha = true
	_picker.focus_mode = Control.FOCUS_NONE
	_picker.tooltip_text = CandyLocale.t("Pick a color")
	_picker.pressed.connect(func(): _text_before_picking = _edit.text)
	_picker.color_changed.connect(func(color: Color): _edit.text = var_to_str(color))
	_picker.popup_closed.connect(func():
		if _edit.text != _text_before_picking:
			commit(_edit.text))
	add_child(_picker)
	move_child(_picker, 0)  #/ Left of the text; a dropdown button goes further left
	_edit.text_changed.connect(func(_text: String): _show_color())


func _update_editable() -> void:
	super()
	_picker.disabled = not is_editable()


func set_value(value: Variant) -> void:
	super(value)
	_show_color()


func set_value_forced(value: Variant) -> void:
	super(value)
	_show_color()


#* Show the text's color on the button, when it is one:
func _show_color() -> void:
	var parsed = str_to_var(_edit.text.strip_edges())
	if parsed is Color:
		_picker.color = parsed
	elif Color.html_is_valid(_edit.text.strip_edges()):
		_picker.color = Color.html(_edit.text.strip_edges())

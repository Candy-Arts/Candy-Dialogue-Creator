#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorPreviewRow
extends CandyNavigatorRow

func _init() -> void:
	super._init()
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


#* Show text with every state's colors:
#? states: { state: { text, outline, bg, border, frame } }. text_indent: -1 for the default.
func show_colors(text: String, states: Dictionary, font_size: int, text_indent: int = -1, foldable: bool = false) -> void:
	var font := get_theme_font(&"font", &"Label")
	var preview_row := {
		"text": text,
		"depth": 0,
		"foldable": foldable,
		"folded": false,
		"font_size": font_size,
		"states": states,
	}
	if text_indent >= 0:
		preview_row["text_indent"] = text_indent
	var frame := float(CandyNavigatorRow.frame_width(preview_row))
	custom_minimum_size.y = CandyNavigatorRow.row_height(font, font_size) + frame * 2.0
	update_row(preview_row, font)


#* The row's rect, inset by the frame width:
func _row_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size).grow(-float(CandyNavigatorRow.frame_width(row)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			set_state("pressed")
		else:
			set_state(_resting_state())
		accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if state != "pressed":
				set_state("hover")
		NOTIFICATION_MOUSE_EXIT:
			set_state("normal")


func _resting_state() -> String:
	if get_global_rect().has_point(get_global_mouse_position()):
		return "hover"
	return "normal"

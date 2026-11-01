#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldsPopup
extends PopupPanel

const WIDTH := 440

var _fields: CandyAreaWidget
var _line_path: Array = []


#* The square button that opens it, with the fields icon:
static func make_button(tooltip: String) -> CandyIconButton:
	return CandyIconButton.new(&"fields", CandyThemeDefaults.ICONS, "...", tooltip)


#* Hold a Fields widget listing these fields (ids, as a Fields widget's "fields"):
#? context: the owning widget's - its line type, and the Editor it's in.
func setup(field_ids: Array, context: Dictionary) -> void:
	var shared := context.duplicate()
	shared.erase("field_selection")			#/ Always its own fields, whatever a Field Tree has picked
	_fields = CandyWidgets.instantiate_area("fields")
	_fields.custom_minimum_size.x = WIDTH
	add_child(_fields)
	#? No scroll of its own: the pop-up is as tall as the fields.
	_fields.configure("fields", {"fields": field_ids.duplicate(), "scroll": false}, shared)
	#Ł Commit what's being typed before it closes:
	popup_hide.connect(func(): gui_release_focus())


#* Follow the owning widget's line:
func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	if visible:
		_fields.bind_line(_line_path)


#* Open beside a button, centered on the screen up and down:
func open_beside(button: Control) -> void:
	_fields.bind_line(_line_path)
	reset_size()
	CandyPopups.popup_centered_vertically(self,
		Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size)), button)

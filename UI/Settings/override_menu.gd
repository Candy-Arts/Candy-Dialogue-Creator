#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyOverrideMenu
extends PopupMenu

enum Id { COPY, PASTE, REMOVE }

const REMOVE_LABEL := "Remove Override"		#/ translatable
const REMOVE_TOOLTIP := "Go back to the value it starts from."		#/ translatable
#^ Remove Override's id in a text field's menu, past LineEdit's own:
const NUMBER_REMOVE_ID := 1000

var _target: Dictionary = {}    #/ Open on: { picker, set_color, remove, is_set }


func _init() -> void:
	add_item(CandyLocale.t("Copy"), Id.COPY)
	add_item(CandyLocale.t("Paste"), Id.PASTE)
	add_item(CandyLocale.t(REMOVE_LABEL), Id.REMOVE)
	set_item_tooltip(get_item_index(Id.REMOVE), CandyLocale.t(REMOVE_TOOLTIP))
	id_pressed.connect(_on_id_pressed)


#* Add the menu to a color picker:
#? Right-click opens it, Ctrl+click pastes.
func add_to_color(picker: ColorPickerButton, set_color: Callable, remove: Callable, is_set: Callable) -> void:
	var target := {"picker": picker, "set_color": set_color, "remove": remove, "is_set": is_set}
	picker.gui_input.connect(func(event: InputEvent): _on_color_input(event, target))


#* Add Remove Override to a SpinBox's text field menu:
static func add_to_number(spin: SpinBox, remove: Callable, is_set: Callable) -> void:
	var menu := spin.get_line_edit().get_menu()
	menu.add_separator()
	menu.add_item(CandyLocale.t(REMOVE_LABEL), NUMBER_REMOVE_ID)
	menu.set_item_tooltip(menu.get_item_index(NUMBER_REMOVE_ID), CandyLocale.t(REMOVE_TOOLTIP))
	menu.about_to_popup.connect(func():
		menu.set_item_disabled(menu.get_item_index(NUMBER_REMOVE_ID), not is_set.call()))
	menu.id_pressed.connect(func(id: int):
		if id == NUMBER_REMOVE_ID:
			remove.call())


#* Get the clipboard's color, or null:
static func clipboard_color() -> Variant:
	var text := DisplayServer.clipboard_get().strip_edges()
	if Color.html_is_valid(text):	#/ "#ff8000" or "ff8000cc"
		return Color.html(text)
	#% Only parse what looks like a Color, "Color(1, 0.5, 0, 1)" (other text prints parse errors):
	if text.begins_with("Color(") and text.ends_with(")"):
		var parsed = str_to_var(text)
		if parsed is Color:
			return parsed
	return null


func _on_color_input(event: InputEvent, target: Dictionary) -> void:
	var click := event as InputEventMouseButton
	if click == null:
		return
	var picker: ColorPickerButton = target["picker"]
	if click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
		_target = target
		set_item_disabled(get_item_index(Id.PASTE), not clipboard_color() is Color)
		set_item_disabled(get_item_index(Id.REMOVE), not target["is_set"].call())
		CandyPopups.popup_at_point(self,
			Vector2i(picker.get_screen_position() + picker.get_local_mouse_position()), picker)
		picker.accept_event()	#/ The picker never sees the click
	elif click.button_index == MOUSE_BUTTON_LEFT and click.is_command_or_control_pressed():
		if click.pressed:
			_paste(target)
		picker.accept_event()	#/ The picker never sees the click


func _on_id_pressed(id: int) -> void:
	if _target.is_empty():
		return
	match id:
		Id.COPY:
			var shown: Color = _target["picker"].color
			DisplayServer.clipboard_set("#" + shown.to_html(true))
		Id.PASTE:
			_paste(_target)
		Id.REMOVE:
			_target["remove"].call()


func _paste(target: Dictionary) -> void:
	var color = clipboard_color()
	if color is Color:
		target["set_color"].call(color)

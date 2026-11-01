#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyWindowButtons
extends HBoxContainer

#^ The user confirmed closing:
signal close_pressed

#^ Confirmation text and button, set by the owner before X is pressed:
var close_question := CandyLocale.t("Quit Candy Dialogue Creator?")
var close_action := CandyLocale.t("Quit")

var _buttons: Array[Button] = []
var _close_confirm: ConfirmationDialog


func _ready() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_add_button("_", _on_minimize_pressed)
	_add_button("❐", _on_maximize_pressed)
	_add_button("X", _on_close_pressed)
	_square_buttons()


func _add_button(label_text: String, handler: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(handler)
	add_child(button)
	_buttons.append(button)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		#? Deferred - the buttons get the new theme after this does.
		_square_buttons.call_deferred()


func _square_buttons() -> void:
	for button in _buttons:
		button.custom_minimum_size.x = 0
		button.custom_minimum_size.x = button.get_combined_minimum_size().y


func _on_minimize_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED


func _on_maximize_pressed() -> void:
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_MAXIMIZED
	else:
		win.mode = Window.MODE_FULLSCREEN


func _on_close_pressed() -> void:
	if _close_confirm == null:
		_close_confirm = ConfirmationDialog.new()
		_close_confirm.confirmed.connect(close_pressed.emit)
		add_child(_close_confirm)
	_close_confirm.title = close_action
	_close_confirm.dialog_text = close_question
	_close_confirm.ok_button_text = close_action
	_close_confirm.reset_size()
	_close_confirm.popup_centered()

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNamePrompt
extends ConfirmationDialog

const DEFAULT_EMPTY_MESSAGE := "The name can't be empty."      #/ translatable

var _edit: LineEdit
var _error: Label
var _validator: Callable
var _on_submit: Callable
var _empty_message := DEFAULT_EMPTY_MESSAGE


func _init() -> void:
	title = CandyLocale.t("Name")
	min_size = Vector2i(380, 0)
	dialog_hide_on_ok = false  #/ Closed once the name validates

	var box := VBoxContainer.new()
	add_child(box)

	_edit = LineEdit.new()
	_edit.custom_minimum_size.x = 340
	_edit.text_changed.connect(func(_text: String): _set_error(""))
	box.add_child(_edit)

	_error = Label.new()
	_error.theme_type_variation = CandyThemeDefaults.ERROR
	_error.text = " "
	box.add_child(_error)

	register_text_enter(_edit)
	confirmed.connect(_on_confirmed)


#* Open the prompt:
#? validator returns "" for a usable name, else the message. on_submit runs with a valid name.
#? empty_message: shown for an empty entry.
func prompt(p_title: String, initial: String, validator: Callable, on_submit: Callable,
		empty_message: String = DEFAULT_EMPTY_MESSAGE) -> void:
	title = p_title
	_empty_message = empty_message
	#% The default message:
	if empty_message == DEFAULT_EMPTY_MESSAGE:
		_empty_message = CandyLocale.t(DEFAULT_EMPTY_MESSAGE)
	_validator = validator
	_on_submit = on_submit
	_edit.text = initial
	_set_error("")
	popup_centered()
	_edit.grab_focus()
	_edit.select_all()


func _on_confirmed() -> void:
	var entered_name := _edit.text.strip_edges()
	if entered_name == "":
		_set_error(_empty_message)
		return
	if _validator.is_valid():
		var problem := str(_validator.call(entered_name))
		if problem != "":
			_set_error(problem)
			return
	hide()
	if _on_submit.is_valid():
		_on_submit.call(entered_name)


func _set_error(message: String) -> void:
	if message != "":
		_error.text = message
	else:
		_error.text = " "
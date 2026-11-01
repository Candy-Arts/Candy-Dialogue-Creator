#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLineEditWidget
extends CandyFieldWidget

var _edit: LineEdit


func _init() -> void:
	_edit = LineEdit.new()
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.text_submitted.connect(func(text: String): commit(text))
	_edit.focus_exited.connect(func(): commit(_edit.text))
	add_child(_edit)


func _on_bound() -> void:
	_update_editable()
	add_lock_menu_item(_edit)
	_edit.placeholder_text = str(spec.get("note", spec.get("placeholder", "")))
	_edit.tooltip_text = CandyFieldHelpButton.with_symbols(CandyLocale.t(str(spec.get("tooltip", ""))))


#* Apply editable and the locked look:
func _update_editable() -> void:
	_edit.editable = is_editable()
	if locked:
		_edit.theme_type_variation = CandyThemeDefaults.LOCKED_LINE_EDIT
	else:
		_edit.theme_type_variation = &""


func set_value(value: Variant) -> void:
	var new_text := str(value)
	if _edit.text == new_text:
		return
	#% Don't move the caret mid-edit:
	if _edit.has_focus():
		return
	_edit.text = new_text


func set_value_forced(value: Variant) -> void:
	_edit.text = str(value)


func get_value() -> Variant:
	return _edit.text


#* Focus the field with its text selected:
func start_editing() -> void:
	_edit.grab_focus()
	_edit.select_all()
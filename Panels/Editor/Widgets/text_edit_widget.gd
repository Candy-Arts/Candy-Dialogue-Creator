#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTextEditWidget
extends CandyFieldWidget

const DEFAULT_HEIGHT := 72
const FIT_HEIGHT := "fit"

var _edit: TextEdit


func _init() -> void:
	_edit = TextEdit.new()
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.custom_minimum_size.y = DEFAULT_HEIGHT
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.focus_exited.connect(func(): commit(_edit.text))
	add_child(_edit)


func _on_bound() -> void:
	_update_editable()
	add_lock_menu_item(_edit)
	_edit.tooltip_text = CandyFieldHelpButton.with_symbols(CandyLocale.t(str(spec.get("tooltip", ""))))
	if str(spec.get("height", "")) == FIT_HEIGHT:
		_edit.custom_minimum_size.y = 0
		_edit.scroll_fit_content_height = true
	elif spec.has("height"):
		_edit.custom_minimum_size.y = int(spec["height"])


#* Apply editable and the locked look:
func _update_editable() -> void:
	_edit.editable = is_editable()
	if locked:
		_edit.theme_type_variation = CandyThemeDefaults.LOCKED_TEXT_EDIT
	else:
		_edit.theme_type_variation = &""


func set_value(value: Variant) -> void:
	var new_text := str(value)
	if _edit.text == new_text or _edit.has_focus():
		return
	_edit.text = new_text


func set_value_forced(value: Variant) -> void:
	_edit.text = str(value)


func get_value() -> Variant:
	return _edit.text
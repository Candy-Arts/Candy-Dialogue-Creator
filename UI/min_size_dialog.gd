#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMinSizeDialog
extends ConfirmationDialog

var _fields: CandyMinSizeFields
var _on_submit: Callable


func _init() -> void:
	title = CandyLocale.t("Settings")

	_fields = CandyMinSizeFields.new()
	add_child(_fields)
	for line_edit in _fields.line_edits():
		register_text_enter(line_edit)

	confirmed.connect(_on_confirmed)


#* Open the dialog (current, and what on_submit receives: CandyMinSizeFields.limits_of()):
func open(p_title: String, current: Dictionary, on_submit: Callable) -> void:
	title = p_title
	_on_submit = on_submit
	_fields.set_limits(current)
	reset_size()
	popup_centered()
	_fields.line_edits()[0].grab_focus()


func _on_confirmed() -> void:
	if _on_submit.is_valid():
		_on_submit.call(_fields.get_limits())


#* Open the settings of a window Area's panel with none of its own:
static func open_for_area(host: Node, window_id: String, area_id: int) -> void:
	var area := CandyLayout.find_area(window_id, area_id)
	if area == null:
		return
	var dialog := CandyMinSizeDialog.new()
	host.add_child(dialog)
	#? Saving rebuilds the window's view.
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	dialog.open(CandyLocale.t("%s Options") % CandyPanels.get_title(area.panel_id),
		CandyMinSizeFields.limits_of(area.config),
		func(typed: Dictionary): CandyLayout.set_area_size_limits(window_id, area_id, typed))

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyReferenceDialog
extends ConfirmationDialog

var _reference_label: Label
var _reference_edit: LineEdit
var _fields: CandyMinSizeFields
var _on_submit: Callable


func _init() -> void:
	title = CandyLocale.t("Options")

	var box := VBoxContainer.new()
	add_child(box)

	var reference_row := HBoxContainer.new()
	box.add_child(reference_row)
	_reference_label = Label.new()
	_reference_label.text = CandyLocale.t("Reference")
	_reference_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	reference_row.add_child(_reference_label)
	_reference_edit = LineEdit.new()
	_reference_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reference_edit.custom_minimum_size.x = CandyMinSizeFields.FIELD_WIDTH
	_reference_edit.select_all_on_focus = true
	reference_row.add_child(_reference_edit)
	register_text_enter(_reference_edit)

	_fields = CandyMinSizeFields.new()
	box.add_child(_fields)
	for line_edit in _fields.line_edits():
		register_text_enter(line_edit)

	confirmed.connect(_on_confirmed)


#* Open the dialog:
#? on_submit(reference: String, limits: Dictionary) - limits: CandyMinSizeFields.limits_of().
func open(p_title: String, tooltip: String, reference: String, show_min_size: bool,
		area_limits: Dictionary, on_submit: Callable) -> void:
	title = p_title
	_on_submit = on_submit
	_reference_edit.text = reference
	_reference_edit.tooltip_text = tooltip
	_reference_label.tooltip_text = tooltip
	_fields.visible = show_min_size
	_fields.set_limits(area_limits)
	reset_size()
	popup_centered()
	_reference_edit.grab_focus()


func _on_confirmed() -> void:
	if _on_submit.is_valid():
		_on_submit.call(CandyDialogue.clean_reference(_reference_edit.text), _fields.get_limits())


#* Open a panel's settings, as its child, freed once closed:
static func open_for_panel(panel: CandyPanel, tooltip: String, reference: String,
		on_reference: Callable) -> void:
	var dialog := CandyReferenceDialog.new()
	panel.add_child(dialog)
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	var panel_title := CandyLocale.t("Options")
	if panel.fills_area:
		var area := CandyLayout.find_area(panel.window_id, panel.area_id)
		if area != null:
			panel_title = CandyLocale.t("%s Options") % CandyPanels.get_title(area.panel_id)
	dialog.open(panel_title, tooltip, reference, panel.fills_area, panel.area_size_limits(),
		func(typed: String, area_limits: Dictionary):
			on_reference.call(typed)
			#? Last - new size limits rebuild the window's view.
			panel.set_area_size_limits(area_limits))

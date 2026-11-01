#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFilterBar
extends HBoxContainer

signal filters_applied

var layouts: CandyLineLayoutSet
var line_type: String = ""
var tab_index: int = 0

var _editor_dialog: CandyFilterEditorDialog
#^ Reorders the filters by dragging:
var _reorder: CandyRowReorder
#^ Each filter button's index in the tab's definitions:
var _definition_indices: Array[int] = []


func _ready() -> void:
	_editor_dialog = CandyFilterEditorDialog.new()
	add_child(_editor_dialog)
	_reorder = CandyRowReorder.new(self, _on_filter_moved)
	layouts.filters_changed.connect(_on_filters_changed)


func bind(p_line_type: String, p_tab_index: int) -> void:
	line_type = p_line_type
	tab_index = p_tab_index
	_rebuild()


func _on_filters_changed(changed_type: String) -> void:
	if changed_type == line_type:
		_rebuild()
		filters_applied.emit()


func _rebuild() -> void:
	for child in get_children():
		if child == _editor_dialog:
			continue
		remove_child(child)
		child.queue_free()
	_reorder.clear()
	_definition_indices.clear()

	var labels: Dictionary = CandyFilters.widget_labels(layouts, line_type, tab_index)
	var definitions := CandyFilters.definitions(layouts, line_type, tab_index)
	for definition_index in definitions.size():
		var definition = definitions[definition_index]
		if not definition is Dictionary:
			continue
		var id := str(definition.get("id", ""))
		if id == "":
			continue
		var button := Button.new()
		button.text = str(definition.get("label", id))
		button.toggle_mode = true
		button.theme_type_variation = CandyThemeDefaults.FILTER_BUTTON
		button.focus_mode = Control.FOCUS_NONE
		button.button_pressed = CandyFilters.is_enabled(layouts, line_type, tab_index, id)
		var shown: Array = []
		for target in _targets(definition):
			shown.append(CandyFilters.target_label(str(target), labels))
		button.tooltip_text = CandyLocale.t("Show or hide: %s\nDrag to move the filter.") % ", ".join(PackedStringArray(shown))
		button.toggled.connect(func(pressed: bool):
			CandyFilters.set_enabled(layouts, line_type, tab_index, id, pressed))
		add_child(button)
		_reorder.add_item(button)
		_definition_indices.append(definition_index)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)

	var edit_button := Button.new()
	edit_button.text = CandyLocale.t("Filters...")
	edit_button.focus_mode = Control.FOCUS_NONE
	edit_button.tooltip_text = CandyLocale.t("Create and edit the filters of this tab")
	edit_button.pressed.connect(func(): _editor_dialog.open(layouts, line_type, tab_index))
	add_child(edit_button)


#* A filter button dragged to another place (to counts the buttons without it):
func _on_filter_moved(from: int, to: int) -> void:
	var definitions := CandyFilters.definitions(layouts, line_type, tab_index).duplicate(true)
	var moved = definitions[_definition_indices[from]]
	definitions.remove_at(_definition_indices[from])
	#Ł Before the button now at `to`, or after the last button:
	var others := _definition_indices.duplicate()
	others.remove_at(from)
	var at := definitions.size()
	if to < others.size():
		at = others[to]
		if at > _definition_indices[from]:
			at -= 1
	definitions.insert(at, moved)
	CandyFilters.set_definitions(layouts, line_type, tab_index, definitions)


func _targets(definition: Dictionary) -> Array:
	var targets = definition.get("targets", [])
	if targets is Array:
		return targets
	return []

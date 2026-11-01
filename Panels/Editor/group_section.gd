#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyGroupSection
extends VBoxContainer


var fields: CandyFieldForm


func setup(spec: Dictionary, base_path: Array, context: Dictionary, schema_path: Array = []) -> void:
	theme_type_variation = CandyThemeDefaults.COMPACT_VBOX

	var header := HBoxContainer.new()
	add_child(header)

	header.add_child(CandyFieldHelpButton.new(spec))

	var label := Label.new()
	label.text = str(spec.get("id", ""))
	if spec.has("label"):
		label.text = CandyLocale.t(str(spec["label"]))
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	header.add_child(label)

	var indent := MarginContainer.new()
	indent.theme_type_variation = CandyThemeDefaults.INDENT
	add_child(indent)

	fields = CandyFieldForm.new()
	indent.add_child(fields)
	fields.build(_sub_fields(spec), base_path, context, schema_path)


func bind_line(line_path: Array) -> void:
	fields.bind_line(line_path)


func set_entry_types(types: Array) -> void:
	fields.set_entry_types(types)


func _sub_fields(spec: Dictionary) -> Array:
	var sub = spec.get("fields", [])
	if sub is Array:
		return sub
	return []
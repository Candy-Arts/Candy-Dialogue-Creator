#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCheckContext
extends RefCounted

#^ The field's value, as text:
var value: String = ""
#^ The list or map (list and map checks), or the entry's data (entry checks):
var data: Variant = null
#^ Entry checks - the list or map the entry is in:
var container: Variant = null
var checks_value := true
var spec: Dictionary = {}
var line_type := ""
var line_path: Array = []
#^ Where the value is in the line's data, e.g. ["Players", "Music", "Loops"]:
var field_path: Array = []
#^ Types of the map entry the field is in (a media player's "audio"...):
var entry_types: Array = []
#^ The forms' shared context (see CandyFieldForm), for dropdowns:
var form_context: Dictionary = {}

#^ Callable(id: String) -> Variant - reads a field beside this one:
var _sibling_reader: Callable
#^ Callable(rule: Dictionary) -> bool:
var _rule_tester: Callable


func _init(p_value: String = "", p_spec: Dictionary = {}) -> void:
	value = p_value
	spec = p_spec


func set_readers(sibling_reader: Callable, rule_tester: Callable) -> void:
	_sibling_reader = sibling_reader
	_rule_tester = rule_tester


#& Reading the line

#* Get a sibling field's value, as stripped text:
#? "../Id" reads a field one level up (see CandyFieldForm).
func sibling(id: String) -> String:
	var found = sibling_data(id)
	if found == null or found is Dictionary or found is Array:
		return ""
	return str(found).strip_edges()


#* Get a sibling field's value as stored (groups and lists whole):
func sibling_data(id: String) -> Variant:
	if _sibling_reader.is_valid():
		return _sibling_reader.call(id)
	if field_path.is_empty():
		return null
	return CandyDialogue.get_field(line_path, field_path.slice(0, field_path.size() - 1) + [id], null)


#* Test a visible_when style rule (false without a form):
func rule(test: Dictionary) -> bool:
	if _rule_tester.is_valid():
		return bool(_rule_tester.call(test))
	return false


#* Get the line's data, { "Reference": ..., "Variations": [...] }:
func line_data() -> Dictionary:
	return CandyDialogue.line_data(CandyDialogue.line_at(line_path))


#* Check whether a sibling's value is only known at runtime:
func is_unknown(text: String) -> bool:
	return text.strip_edges() == CandyChecks.NOT_SET_VALUE or CandyChecks.is_expression(text)


#& Dropdowns

#* Get the context this field's dropdown opens with (see CandyFieldWidget):
func dropdown_context() -> Dictionary:
	var result := form_context.duplicate()
	result["line_path"] = line_path
	result["field_path"] = field_path
	result["spec"] = spec
	result["line_type"] = line_type
	return result


#* List the values this field's dropdown offers, submenus included:
#? config: another dropdown config.
#! [] lists nothing, which checks read as "not known".
func dropdown_values(config: Variant = null) -> Array:
	if config == null:
		config = spec.get("dropdown", {})
	if not config is Dictionary or config.is_empty():
		return []
	var menu_context := dropdown_context()
	return CandyChecks.item_values(CandyDropdowns.get_items(config, menu_context), menu_context)


#* Get the entry whose folder the dropdown lists (a speaker, a layer...):
func entry_name() -> String:
	var config = spec.get("dropdown", {})
	if not config is Dictionary:
		config = {}
	return CandyDropdowns.entry_name(config, dropdown_context())


#* Get the map or named list entry the field is in ("Music" in ["Players", "Music", "Loops"]), or "":
func entry_key() -> String:
	if field_path.size() < 2:
		return ""
	var step = field_path[field_path.size() - 2]
	if str(step) == CandyDialogue.ENTRY_VALUE and field_path.size() >= 3:
		return str(CandyDialogue.get_field(line_path, field_path.slice(0, field_path.size() - 2) + [CandyDialogue.ENTRY_NAME], ""))
	return str(step)

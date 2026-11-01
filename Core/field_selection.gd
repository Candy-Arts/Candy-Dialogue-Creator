#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldSelection
extends RefCounted

signal changed(field_reference: String, line_type: String, tree_path: Array)

var _selected: Dictionary = {}    #/ "reference|line type" -> tree path, or null for nothing


#* Get the selected tree path ([] when nothing is selected, see has_selection()):
func get_selected(field_reference: String, line_type: String) -> Array:
	var tree_path = _selected.get(_key(field_reference, line_type), [])
	if tree_path is Array:
		return tree_path.duplicate()
	return []


#* Check whether something is selected (see clear()):
func has_selection(field_reference: String, line_type: String) -> bool:
	return _selected.get(_key(field_reference, line_type), []) is Array


func select(field_reference: String, line_type: String, tree_path: Array) -> void:
	var key := _key(field_reference, line_type)
	var current = _selected.get(key, [])
	if current is Array and current == tree_path:
		return
	_selected[key] = tree_path.duplicate()
	changed.emit(_clean(field_reference), line_type, tree_path.duplicate())


#* Select nothing, silently:
#? Only called before widgets are bound to a new line, which shows it.
func clear(field_reference: String, line_type: String) -> void:
	_selected[_key(field_reference, line_type)] = null


func _key(field_reference: String, line_type: String) -> String:
	return "%s|%s" % [_clean(field_reference), line_type]


func _clean(field_reference: String) -> String:
	var text := field_reference.strip_edges()
	if text == "":
		return CandyVariationSelection.DEFAULT_REFERENCE
	return text


#& Paths

#* Get where a tree path points in the line's data, or null if the line lacks it:
#? Built like the forms' paths.
static func data_path(line_path: Array, specs: Array, tree_path: Array) -> Variant:
	var path: Array = []
	var level := specs
	var step := 0
	while step < tree_path.size():
		var spec := spec_in(level, str(tree_path[step]))
		if spec.is_empty():
			return null
		var id := str(spec["id"])
		step += 1
		match str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)):
			"group":
				path.append(id)
			"list":
				var list_path := path + [id]
				if step == tree_path.size():
					return list_path			#/ Where its entries are stored (CandyFieldTreeWidget's add buttons)
				var index := int(tree_path[step])
				step += 1
				var array = CandyDialogue.get_field(line_path, list_path, null)
				if not array is Array or index < 0 or index >= array.size():
					return null
				path = list_path + [index]
				#% Named list - ["Choices", 2, "Finish"] -> ["Choices", 2, "@entry", "Finish"]:
				if CandySchemas.is_named_list(spec):
					path.append(CandyDialogue.ENTRY_VALUE)
			"map":
				var map_path := path.duplicate()
				#% Root map - only the key (["Players", 1] -> ["Video"]):
				if not CandySchemas.is_root_map(spec):
					map_path.append(id)
				if step == tree_path.size():
					return map_path			#/ Where its entries are stored
				var index := int(tree_path[step])
				step += 1
				var keys := CandyDialogue.map_keys(line_path, map_path)
				if index < 0 or index >= keys.size():
					return null
				path = map_path + [keys[index]]
				#? An entry's fields can depend on the entry (a map of commands).
				level = CandySchemas.map_entry_fields(spec, str(keys[index]),
					CandyDialogue.get_field(line_path, path, {}))
				continue
			_:
				return null  #/ A plain field has nothing inside
		level = sub_fields(spec)
	return path


static func spec_in(specs: Array, id: String) -> Dictionary:
	for spec in specs:
		if spec is Dictionary and str(spec.get("id", "")) == id:
			return spec
	return {}


static func sub_fields(spec: Dictionary) -> Array:
	var fields = spec.get("fields", [])
	if fields is Array:
		return fields
	return []

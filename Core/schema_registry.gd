#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

const BUILTIN_DIR := "res://Line_Schemas"
const MODS_DIR := "user://Mods"
const SCHEMA_SUBDIR := "Line_Schemas"
const META_FILE := "res://Defaults/line_meta.txt"

var _schemas: Dictionary = {}    #/ Line type -> schema
var _type_providers: Dictionary = {}    #/ Provider id -> Callable(entry_key: String) -> Array
var _value_providers: Dictionary = {}   #/ Provider id -> Callable(read: Callable) -> String
#^ Defaults/line_meta.txt - { "line" = [specs], "entry" = [specs] }:
var _meta: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_schemas.clear()
	_meta = CandyVariantFile.read(META_FILE)
	_load_dir(BUILTIN_DIR)
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			_load_dir(MODS_DIR.path_join(mod).path_join(SCHEMA_SUBDIR))


func _load_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in DirAccess.get_files_at(path):
		if not file_name.ends_with(".txt"):
			continue
		var data := CandyVariantFile.read(path.path_join(file_name))
		var type := str(data.get("type", ""))
		if type == "" or not data.get("fields") is Array:
			push_warning("CandySchemas: %s has no \"type\" or \"fields\"" % file_name)
			continue
		if not root_map_spec_of(data["fields"]).is_empty() and data["fields"].size() > 1:
			push_warning("CandySchemas: %s has a root map beside other fields; they would share its keys" % file_name)
		_add_meta(data)
		_schemas[type] = data


func has_schema(type: String) -> bool:
	return _schemas.has(type)


func register_schema(schema: Dictionary) -> void:
	var type := str(schema.get("type", ""))
	if type != "":
		_add_meta(schema)
		_schemas[type] = schema


#& Meta fields

#* Add the Meta fields to a schema (see the header):
func _add_meta(schema: Dictionary) -> void:
	var fields = schema.get("fields")
	if not fields is Array:
		return
	if root_map_spec_of(fields).is_empty():
		_append_meta(fields, "line")
	_add_entry_meta(fields)


func _add_entry_meta(specs: Array) -> void:
	for spec in specs:
		if not spec is Dictionary:
			continue
		match str(spec.get("widget", "line_edit")):
			"group":
				_add_entry_meta(_sub_fields(spec))
			"list", "map":
				if is_command_map(spec) or is_value_map(spec) or is_command_list(spec):
					continue
				var fields = spec.get("fields")
				if not fields is Array:
					fields = []
					spec["fields"] = fields
				if root_map_spec_of(fields).is_empty():
					_append_meta(fields, "entry")
				_add_entry_meta(fields)


#* Append line_meta.txt's "line" or "entry" fields that fields lacks:
func _append_meta(fields: Array, kind: String) -> void:
	var specs = _meta.get(kind)
	if not specs is Array:
		return
	var ids := {}
	for spec in fields:
		if spec is Dictionary:
			ids[str(spec.get("id", ""))] = true
	for spec in specs:
		if spec is Dictionary and not ids.has(str(spec.get("id", ""))):
			fields.append(spec.duplicate(true))


#* Where a spec's value sits below its level: [id], or [stored_in, id]:
func data_path(spec: Dictionary) -> Array:
	var store := str(spec.get("stored_in", ""))
	if store == "":
		return [str(spec.get("id", ""))]
	return [store, str(spec.get("id", ""))]


#* Get a line type's schema:
func get_schema(type: String, data: Dictionary = {}) -> Dictionary:
	if _schemas.has(type):
		return _schemas[type]
	return _generate_schema(type, data)			#/ No file: generated from data


func field_specs(type: String, data: Dictionary = {}) -> Array:
	var fields = get_schema(type, data).get("fields", [])
	if fields is Array:
		return fields
	return []


func get_title(type: String) -> String:
	return str(get_schema(type).get("title", type))


#* Every line type with a schema file, by category then title:
func line_types() -> Array:
	var result: Array = _schemas.keys()
	result.sort_custom(func(a, b):
		var category_a := get_category(a)
		var category_b := get_category(b)
		if category_a != category_b:
			return category_a.naturalnocasecmp_to(category_b) < 0
		return get_title(a).naturalnocasecmp_to(get_title(b)) < 0)
	return result


func get_category(type: String) -> String:
	if not _schemas.has(type):
		return ""
	return str(_schemas[type].get("category", ""))


#* Get a category heading's tooltip, or "":
func get_category_tooltip(category: String) -> String:
	for type in line_types():
		if get_category(type) != category:
			continue
		var tooltip := str(_schemas[type].get("category_tooltip", ""))
		if tooltip != "":
			return tooltip
	return ""


#* Get the schema's default layout, or {}:
#! The loaded schema's own dictionary: copy before changing.
func get_layout(type: String) -> Dictionary:
	if not _schemas.has(type):
		return {}
	var layout = _schemas[type].get("layout", {})
	if layout is Dictionary:
		return layout
	return {}


#* Get the schema's { "Text": Color, "BG": Color }, or {}:
func get_colors(type: String) -> Dictionary:
	if not _schemas.has(type):
		return {}
	var colors = _schemas[type].get("colors", {})
	if colors is Dictionary:
		return colors
	return {}


#* Get the schema's "navigator_text_field", or "":
func get_navigator_text_field(type: String) -> String:
	if not _schemas.has(type):
		return ""
	return str(_schemas[type].get("navigator_text_field", ""))


#* Fill the schema's "summary" from data, or "":
func summary(type: String, data: Dictionary) -> String:
	if not _schemas.has(type):
		return ""
	var template := str(_schemas[type].get("summary", ""))
	if template == "":
		return ""
	var regex := RegEx.create_from_string("\\{([^{}]+)\\}")
	var text := template
	for found in regex.search_all(template):
		var parts := found.get_string(1).split("|", true, 1)
		var value = data.get(parts[0], "")
		if value is Dictionary:
			#% A map lists its entries - "Music, Video":
			var keys: PackedStringArray = []
			for key in value:
				if str(key) != CandyDialogue.META_KEY:
					keys.append(str(key))
			value = ", ".join(keys)
		elif value == null or value is Array:
			value = ""
		if str(value) == "" and parts.size() > 1:
			value = parts[1]
		text = text.replace(found.get_string(), str(value))
	#Ł Collapse spaces left by empty values:
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text.strip_edges()


#* Whether the schema has a "short":
func has_short(type: String) -> bool:
	return _schemas.has(type) and _schemas[type].has("short")


#* Fill the schema's "short": its first template whose placeholders all have a value, or "":
func short_text(type: String, data: Dictionary) -> String:
	if not _schemas.has(type):
		return ""
	var templates = _schemas[type].get("short", [])
	if templates is String:
		templates = [templates]
	if not templates is Array:
		return ""
	var regex := RegEx.create_from_string("\\{([^{}]+)\\}")
	for template in templates:
		var text := str(template)
		var complete := true
		for found in regex.search_all(text):
			var parts := found.get_string(1).split("|", true, 1)
			var value := _short_value(data, parts[0].split("/"))
			if value == "" and parts.size() > 1:
				value = parts[1]
			if value == "":
				complete = false
				break
			text = text.replace(found.get_string(), value)
		if complete:
			return text.strip_edges()
	return ""


#* Get a "short" placeholder's value, going into each map / list entry, or "":
func _short_value(value, steps: PackedStringArray) -> String:
	if steps.is_empty():
		if value is Dictionary:
			return ", ".join(_entry_names(value))
		if value is Array:
			var names: PackedStringArray = []
			for entry in value:
				if entry is Dictionary:
					names.append_array(_entry_names(entry))
			return ", ".join(names)
		if value == null:
			return ""
		var text := str(value).strip_edges()
		if text == "null":
			return ""
		return text
	if not value is Dictionary:
		return ""
	var rest := steps.slice(1)
	var inner = value.get(steps[0])
	if rest.is_empty() or (not inner is Dictionary and not inner is Array):
		return _short_value(inner, rest)
	#¦ 1. A map names its entries - "Music: theme; Video: intro":
	if inner is Dictionary:
		var entries: PackedStringArray = []
		var any_value := false
		for key in inner:
			if _is_meta_key(key):
				continue
			var entry_value := _short_value(inner[key], rest)
			if entry_value != "":
				entries.append("%s: %s" % [key, entry_value])
				any_value = true
			else:
				entries.append(str(key))
		if not any_value:
			return ", ".join(entries)
		return "; ".join(entries)
	#¦ 2. A list's entries are {name: content}; only values show:
	var values: PackedStringArray = []
	for entry in inner:
		if not entry is Dictionary:
			continue
		for key in entry:
			var entry_value := _short_value(entry[key], rest)
			if entry_value != "":
				values.append(entry_value)
	return ", ".join(values)


#* A dictionary's keys, less META_KEY and Meta:
func _entry_names(source: Dictionary) -> PackedStringArray:
	var names: PackedStringArray = []
	for key in source:
		if not _is_meta_key(key):
			names.append(str(key))
	return names


func _is_meta_key(key) -> bool:
	return str(key) == CandyDialogue.META_KEY or str(key) == CandyDialogue.META_DATA_KEY


#& Defaults database

#* Every key the specs define, with its default:
#? line_type: for defaults that depend on the command (field_default()).
func defaults_for_fields(specs: Array, line_type: String = "") -> Dictionary:
	var result := {}
	for spec in specs:
		if not (spec is Dictionary and spec.has("id")):
			continue
		var id := str(spec["id"])
		var target := result
		var store := str(spec.get("stored_in", ""))
		if store != "":
			if not result.get(store) is Dictionary:
				result[store] = {}
			target = result[store]
		match str(spec.get("widget", "line_edit")):
			"group":
				target[id] = defaults_for_fields(_sub_fields(spec), line_type)
			"list":
				target[id] = []
			"map":
				if is_value_map(spec):
					target[id] = value_map_defaults(spec)
				#? A root map starts empty (its entries are the data).
				elif not is_root_map(spec):
					target[id] = {}
			_:
				target[id] = field_default(spec, line_type)
	return result


#* Get a field's default: its "default", or what "default_from" names:
func field_default(spec: Dictionary, line_type: String) -> String:
	match str(spec.get("default_from", "")):
		"navigator_text_color":
			if line_type != "":
				var states := CandyNavigatorColors.for_command(line_type, CandyNavigatorColors.user_colors(), null)
				return var_to_str(states["normal"]["text"])
	return str(spec.get("default", ""))


func default_data(type: String) -> Dictionary:
	return defaults_for_fields(field_specs(type), type)


func default_line(type: String) -> Dictionary:
	return {type: default_data(type)}


#* Get one new entry of a list / map:
func entry_defaults(spec: Dictionary, entry_key: String = "") -> Dictionary:
	if is_command_map(spec):			#/ entry_key is the command
		return default_data(entry_key)
	return defaults_for_fields(_sub_fields(spec))


#* Whether a map's entries are commands:
func is_command_map(spec: Dictionary) -> bool:
	return str(spec.get("widget", "")) == "map" and str(spec.get("entries", "")) == "commands"


#* Whether a list's entries are lines of commands:
func is_command_list(spec: Dictionary) -> bool:
	return str(spec.get("widget", "")) == "list" and str(spec.get("entries", "")) == "commands"


#* Whether a map's entries are single values:
func is_value_map(spec: Dictionary) -> bool:
	return str(spec.get("widget", "")) == "map" and str(spec.get("entries", "")) == "values"


#* Get the spec of one entry of a map of values, named after its key:
func value_spec(map_spec: Dictionary, key: String) -> Dictionary:
	var result := {}
	var stored = map_spec.get("value", {})
	if stored is Dictionary:
		result = stored.duplicate(true)
	result["id"] = key
	result["label"] = key
	return result


#* A new map of values - its "start_entries", numbered from 1:
func value_map_defaults(spec: Dictionary) -> Dictionary:
	var result := {}
	var prefix := str(spec.get("entry_prefix", "Entry"))
	var default_value := field_default(value_spec(spec, ""), "")
	for number in int(spec.get("start_entries", 0)):
		result["%s_%d" % [prefix, number + 1]] = default_value
	return result


#* Get one map entry's fields:
func map_entry_fields(map_spec: Dictionary, entry_key: String, entry_value: Variant = {}) -> Array:
	if is_command_map(map_spec):
		var data = entry_value
		if not data is Dictionary:
			data = {}
		return field_specs(entry_key, data)
	return _sub_fields(map_spec)


#* False for fields Fields widgets leave out:
func in_forms(spec: Dictionary) -> bool:
	return bool(spec.get("in_forms", true))


func is_named_list(spec: Dictionary) -> bool:
	return str(spec.get("entry", "")) == "named"


func is_root_map(spec: Dictionary) -> bool:
	if str(spec.get("widget", "")) != "map":
		return false
	return CandyVariantFile.to_bool(spec.get("root", false), false)


#* Get a line type's root map spec, or {}:
func root_map_spec(type: String, data: Dictionary = {}) -> Dictionary:
	return root_map_spec_of(field_specs(type, data))


func root_map_spec_of(specs: Array) -> Dictionary:
	for spec in specs:
		if spec is Dictionary and is_root_map(spec):
			return spec
	return {}


#& Entry types

#* Register an entry type provider:
#? provider: Callable(entry_key: String) -> Array of type names, [] when unknown.
func register_type_provider(id: String, provider: Callable) -> void:
	_type_providers[id] = provider


#* Get one map entry's types from the map's "entry_type" provider, or []:
func entry_types(map_spec: Dictionary, entry_key: String) -> Array:
	var id := str(map_spec.get("entry_type", ""))
	if id == "":
		return []
	if not _type_providers.has(id):
		push_warning("CandySchemas: unknown entry type provider '%s'" % id)
		return []
	var types = _type_providers[id].call(entry_key)
	if types is Array:
		return types
	return []


#& Value providers

#* Register a value provider, for visible_when "provider" rules:
#? provider: Callable(read: Callable) -> String; read: Callable(field_id) -> Variant, on the rule's level.
#? Return "null" when the value can't be known while editing.
func register_value_provider(id: String, provider: Callable) -> void:
	_value_providers[id] = provider


#* Get a provider's value, or "null" without that provider:
func provided_value(id: String, read: Callable) -> String:
	if not _value_providers.has(id):
		push_warning("CandySchemas: unknown value provider '%s'" % id)
		return "null"
	return str(_value_providers[id].call(read))


#* Whether a field shows for an entry of these types:
func suits_types(spec: Dictionary, types: Array) -> bool:
	var wanted = spec.get("types", [])
	if not wanted is Array or wanted.is_empty() or types.is_empty():
		return true			#/ No "types", or an unknown entry type ([])
	for type in types:
		if wanted.has(type):
			return true
	return false


func _sub_fields(spec: Dictionary) -> Array:
	var fields = spec.get("fields", [])
	if fields is Array:
		return fields
	return []


#* Every field of a line type, flattened, for pickers:
func field_index(type: String, data: Dictionary = {}) -> Array:
	return spec_index(field_specs(type, data))			#/ Each: id, label, depth (indent only), in_forms (false inside a hidden field too), key (schema path, "Players/Loops"), parent (holds fields)


#* field_index() for some specs only (a widget's, CandyAreaWidget.filter_fields()):
func spec_index(specs: Array) -> Array:
	var result: Array = []
	_collect_fields(specs, [], true, result)
	return result


func _collect_fields(specs: Array, parent_ids: Array, parent_in_forms: bool, result: Array) -> void:
	for spec in specs:
		if not (spec is Dictionary and spec.has("id")):
			continue
		var id := str(spec["id"])
		var shown := parent_in_forms and in_forms(spec)
		var ids := parent_ids + [id]
		var is_parent := str(spec.get("widget", "line_edit")) in ["group", "list", "map"]
		result.append({"id": id, "label": str(spec.get("label", id)), "depth": parent_ids.size(),
			"in_forms": shown, "key": "/".join(PackedStringArray(ids)), "parent": is_parent})
		if is_parent:
			_collect_fields(_sub_fields(spec), ids, shown, result)


#& Normalization

#* Add every key the schema defines, in schema order:
func normalize_line(line: Dictionary) -> Dictionary:
	var type := ""
	for key in line:
		type = str(key)
		break
	if type == "":
		return line
	var data = line[type]
	if not data is Dictionary:
		data = {}
	#? A generated schema mirrors the data.
	line[type] = normalize_data(data, field_specs(type, data))			#/ Unknown keys are kept (a newer version may have written them)
	return line


func normalize_data(data: Dictionary, specs: Array) -> Dictionary:
	var result := {}
	var stores := {}    #/ "stored_in" key -> the data's dictionary of it
	for spec in specs:
		if not (spec is Dictionary and spec.has("id")):
			continue
		var id := str(spec["id"])
		var store := str(spec.get("stored_in", ""))
		if store != "":
			if not stores.has(store):
				var stored = data.get(store, {})
				if not stored is Dictionary:
					stored = {}
				stores[store] = stored
				result[store] = {}
			result[store][id] = _normalize_value(stores[store], spec)
			continue
		match str(spec.get("widget", "line_edit")):
			"group":
				var group = data.get(id, {})
				if not group is Dictionary:
					group = {}
				result[id] = normalize_data(group, _sub_fields(spec))
			"list":
				var array = data.get(id, [])
				var normalized: Array = []
				if array is Array:
					for entry in array:
						if is_command_list(spec):
							#% Each entry is a line of its own command:
							if entry is Dictionary:
								normalized.append(normalize_line(entry))
							else:
								normalized.append(entry)
						else:
							normalized.append(_normalize_entry(entry, spec))
				result[id] = normalized
			"map":
				if is_value_map(spec):
					result[id] = _normalize_value(data, spec)
				elif is_root_map(spec):
					for key in data:
						if str(key) != CandyDialogue.META_KEY:
							result[key] = _normalize_map_value(data[key], spec, str(key))
				else:
					var map = data.get(id, {})
					var normalized_map := {}
					if map is Dictionary:
						for key in map:
							normalized_map[key] = _normalize_map_value(map[key], spec, str(key))
					result[id] = normalized_map
			_:
				result[id] = _normalize_value(data, spec)

	for key in data:
		if not result.has(key):
			result[key] = data[key]
	#Ł Keep unknown keys inside "stored_in" dictionaries:
	for store in stores:
		for key in stores[store]:
			if not result[store].has(key):
				result[store][key] = stores[store][key]
	return result


#* Get a plain field's or map of values' value from source (its level's data or "stored_in" dictionary):
func _normalize_value(source: Dictionary, spec: Dictionary) -> Variant:
	var id := str(spec["id"])
	if is_value_map(spec):
		#% Only fill in a missing map - its values are the user's:
		if not source.has(id):
			return value_map_defaults(spec)
		if source[id] is Dictionary:
			return source[id]
		return {}
	return source.get(id, spec.get("default", ""))


#* Normalize a map entry as a dictionary of its fields:
func _normalize_map_value(value: Variant, spec: Dictionary, key: String) -> Dictionary:
	var entry: Dictionary = {}
	if value is Dictionary:
		entry = value
	return normalize_data(entry, map_entry_fields(spec, key, entry))


func _normalize_entry(entry: Variant, spec: Dictionary) -> Variant:
	var fields := _sub_fields(spec)
	if is_named_list(spec):
		if entry is Dictionary and entry.size() > 0:
			var entry_name := str(entry.keys()[0])
			var value = entry[entry_name]
			if not value is Dictionary:
				value = {}
			return {entry_name: normalize_data(value, fields)}
		return {str(spec.get("entry_prefix", "Entry")) + "_1": normalize_data({}, fields)}
	if entry is Dictionary:
		return normalize_data(entry, fields)
	return normalize_data({}, fields)


#* Build a schema from a line - scalars become text fields, the rest read-only notes:
func _generate_schema(type: String, data: Dictionary) -> Dictionary:
	var fields: Array = []
	for key in data:
		if str(key) == CandyDialogue.META_KEY:
			continue  #/ Editor-side data
		var value = data[key]
		if value is Dictionary or value is Array:
			fields.append({
				"id": str(key),
				"label": str(key),
				"widget": "line_edit",
				"read_only": true,
				"note": CandyLocale.t("nested data — needs a schema"),
			})
		else:
			fields.append({"id": str(key), "label": str(key), "widget": "line_edit"})
	return {"type": type, "title": type, "fields": fields, "generated": true}
#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariantFile


static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.strip_edges() == "":
		return {}
	var data = str_to_var(text)
	if data is Dictionary:
		return data
	#? 1.1's create_profile() wrote "{}" before the first save.
	data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}


static func write(path: String, data: Variant) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CandyVariantFile: can't write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(stringify(data))
	return true


static func stringify(value: Variant, depth: int = 0) -> String:
	var indent := "    ".repeat(depth)
	var indent_inner := "    ".repeat(depth + 1)

	if value is Dictionary:
		if value.is_empty():
			return "{}"

		#% No nested container - one line:
		var has_nested := false
		for v in value.values():
			if v is Dictionary or v is Array:
				has_nested = true
				break

		if not has_nested:
			var pairs := []
			for k in value.keys():
				pairs.append("%s: %s" % [stringify(k, depth + 1), stringify(value[k], depth + 1)])
			return "{ " + ", ".join(pairs) + " }"

		var lines := []
		for k in value.keys():
			lines.append("%s%s: %s" % [indent_inner, stringify(k, depth + 1), stringify(value[k], depth + 1)])
		return "{\n" + ",\n".join(lines) + "\n" + indent + "}"

	elif value is Array:
		if value.is_empty():
			return "[]"
		var items := []
		for item in value:
			items.append(indent_inner + stringify(item, depth + 1))
		return "[\n" + ",\n".join(items) + "\n" + indent + "]"

	elif value is String or value is StringName:
		return _quote(str(value))

	elif value is bool:
		if value:
			return "true"
		return "false"

	elif value == null:
		return "null"

	elif value is Color:
		return var_to_str(value)

	elif value is int or value is float:
		return str(value)

	#% Other types (Vector2, PackedStringArray...):
	return var_to_str(value)


#* Quote a string, escaping control characters (keeps it on one line):
static func _quote(text: String) -> String:
	var escaped := text.replace("\\", "\\\\")
	escaped = escaped.replace("\"", "\\\"")
	escaped = escaped.replace("\n", "\\n")
	escaped = escaped.replace("\r", "\\r")
	escaped = escaped.replace("\t", "\\t")
	return "\"" + escaped + "\""


#* A bool from any stored value (bools, numbers, "true" / "1"..., null):
static func to_bool(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String or value is StringName:
		var text := str(value).strip_edges().to_lower()
		if text == "true" or text == "1" or text == "yes" or text == "on":
			return true
		if text == "false" or text == "0" or text == "no" or text == "off" or text == "":
			return false
	return fallback
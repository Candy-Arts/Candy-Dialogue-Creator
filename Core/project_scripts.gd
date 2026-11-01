#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyProjectScripts

#* The values of variable_name in the script at script_path (absolute):
static func read_variable(script_path: String, variable_name: String) -> PackedStringArray:
	if script_path == "" or variable_name == "":
		return PackedStringArray()
	if not FileAccess.file_exists(script_path):
		return PackedStringArray()
	var text := FileAccess.get_file_as_string(script_path)
	return parse_values(extract_expression(text, variable_name))


#* Read a dictionary of dictionaries' keys, two levels deep:
static func read_nested_keys(script_path: String, variable_name: String) -> Dictionary:
	var result := {}
	if script_path == "" or variable_name == "" or not FileAccess.file_exists(script_path):
		return result
	var text := extract_expression(FileAccess.get_file_as_string(script_path), variable_name).strip_edges()
	if not text.begins_with("{") or not text.ends_with("}"):
		return result
	for item in split_top_level(text.substr(1, text.length() - 2)):
		var key := _key_of(item)
		if key == "":
			continue
		var value := _value_of(item)
		if value.begins_with("{"):
			result[key] = parse_values(value)
		else:
			result[key] = PackedStringArray()			#/ Not a dictionary
	return result			#/ { "*": ["Alice"], "Default*": ["Alice", "_June"] } (the Lexicon, text events)


#* One String variable's value ("" if unreadable):
static func read_string(script_path: String, variable_name: String) -> String:
	var values := read_variable(script_path, variable_name)
	if values.is_empty():
		return ""
	return values[0]


#* The literal assigned to a variable, as written:
static func extract_expression(text: String, variable_name: String) -> String:
	if not _is_identifier(variable_name):
		return ""
	#? var, const, @export, static, typed.
	var pattern := "(?m)^[ \\t]*(?:@export[^\\n]*?[ \\t]+)?(?:static[ \\t]+)?(?:var|const)[ \\t]+" \
		+ variable_name + "\\b[ \\t]*(?::[^=\\n]*?)?=[ \\t]*"
	var regex := RegEx.create_from_string(pattern)
	if regex == null:
		return ""
	var found := regex.search(text)
	if found == null:
		return ""

	#Ł Read until the brackets balance (or the line ends), skipping comments:
	#? Comments are left out, so their quotes and brackets can't unbalance it.
	var segments := PackedStringArray()
	var start := found.get_end()
	var index := start
	var depth := 0
	var in_string := false
	var quote := ""
	while index < text.length():
		var character := text[index]
		if in_string:
			if character == "\\":
				index += 2
				continue
			if character == quote:
				in_string = false
		elif character == "\"" or character == "'":
			in_string = true
			quote = character
		elif character == "[" or character == "{" or character == "(":
			depth += 1
		elif character == "]" or character == "}" or character == ")":
			depth -= 1
			if depth <= 0:
				index += 1
				break
		elif character == "#":
			segments.append(text.substr(start, index - start))
			if depth == 0:
				start = index
				break
			#Ł Skip to the line break:
			index = text.find("\n", index)
			if index == -1:
				index = text.length()
			start = index
			continue
		elif character == "\n" and depth == 0:
			break
		index += 1
	segments.append(text.substr(start, index - start))
	return "".join(segments).strip_edges()


#* Turn a literal into a list of values:
static func parse_values(expression: String) -> PackedStringArray:
	var result := PackedStringArray()
	var text := expression.strip_edges()
	if text == "":
		return result

	if text.begins_with("{"):
		#¦ 1. Dictionary - top-level keys only:
		for item in split_top_level(text.substr(1, text.length() - 2)):
			var key := _key_of(item)
			if key != "":
				result.append(key)
		return result

	if text.begins_with("["):
		for item in split_top_level(text.substr(1, text.length() - 2)):
			var value := strip_quotes(item)
			if value != "":
				result.append(value)
		return result

	#¦ 2. Plain string - one value:
	var single := strip_quotes(text)
	if single != "":
		result.append(single)
	return result


#* Split on commas outside brackets and quotes:
static func split_top_level(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	var depth := 0
	var in_string := false
	var quote := ""
	var start := 0
	var index := 0
	while index < text.length():
		var character := text[index]
		if in_string:
			if character == "\\":
				index += 2
				continue
			if character == quote:
				in_string = false
		elif character == "\"" or character == "'":
			in_string = true
			quote = character
		elif character == "[" or character == "{" or character == "(":
			depth += 1
		elif character == "]" or character == "}" or character == ")":
			depth -= 1
		elif character == "," and depth == 0:
			result.append(text.substr(start, index - start))
			start = index + 1
		index += 1
	result.append(text.substr(start))

	var cleaned := PackedStringArray()
	for item in result:
		var trimmed := item.strip_edges()
		if trimmed != "":
			cleaned.append(trimmed)
	return cleaned


static func strip_quotes(text: String) -> String:
	var trimmed := text.strip_edges()
	if trimmed.length() >= 2:
		var first := trimmed[0]
		if (first == "\"" or first == "'") and trimmed[trimmed.length() - 1] == first:
			return trimmed.substr(1, trimmed.length() - 2).replace("\\" + first, first)
	return trimmed


#& Comma-separated lists (how these settings are stored)

static func split_list(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for item in text.split(",", false):
		var trimmed := item.strip_edges()
		if trimmed != "":
			result.append(trimmed)
	return result


static func join_list(values: PackedStringArray) -> String:
	return ", ".join(values)


#* Loaded minus excluded, plus added (no duplicates, in order):
static func combine(loaded: PackedStringArray, excluded: PackedStringArray,
		added: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	var seen := {}
	for value in loaded:
		if excluded.has(value) or seen.has(value):
			continue
		seen[value] = true
		result.append(value)
	for value in added:
		if seen.has(value):
			continue
		seen[value] = true
		result.append(value)
	return result


#* The usable values of one project_scripts entry:
static func entry_values(entry: Dictionary) -> PackedStringArray:
	return combine(
		split_list(str(entry.get("Loaded", ""))),
		split_list(str(entry.get("Exclude", ""))),
		split_list(str(entry.get("Add", ""))))


#* A dictionary item's value ("" if none):
static func _value_of(item: String) -> String:
	var key_end := _key_end(item)
	if key_end < 0:
		return ""
	return item.substr(key_end + 1).strip_edges()


static func _key_of(item: String) -> String:
	var key_end := _key_end(item)
	if key_end < 0:
		return ""
	return strip_quotes(item.substr(0, key_end))


#* Where a dictionary item's key ends (its ":"), or -1:
static func _key_end(item: String) -> int:
	var depth := 0
	var in_string := false
	var quote := ""
	var index := 0
	while index < item.length():
		var character := item[index]
		if in_string:
			if character == "\\":
				index += 2
				continue
			if character == quote:
				in_string = false
		elif character == "\"" or character == "'":
			in_string = true
			quote = character
		elif character == "[" or character == "{" or character == "(":
			depth += 1
		elif character == "]" or character == "}" or character == ")":
			depth -= 1
		elif character == ":" and depth == 0:
			return index
		index += 1
	return -1


static func _is_identifier(text: String) -> bool:
	if text == "":
		return false
	var regex := RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*$")
	return regex != null and regex.search(text) != null
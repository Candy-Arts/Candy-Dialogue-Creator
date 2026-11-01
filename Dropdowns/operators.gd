#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted

const CURRENT := "Works on the current value when Expression is empty."	#/ translatable

#^ Top-level operators, before the groups:
const BASIC := {
	"=": "Sets the value to Expression.",	#/ translatable
	"+=": "Adds numbers; joins two texts or two Arrays.",	#/ translatable
	"-=": "Subtracts.",	#/ translatable
	"*=": "Multiplies.",	#/ translatable
}

#^ [group label, { operator: tooltip }], a submenu each:
const GROUPS := [
	["Arithmetic", {	#/ translatable
		"/=": "Divides, as a decimal number. Dividing by 0 leaves the value unchanged.",	#/ translatable
		"//=": "Divides, rounded down to a whole number.",	#/ translatable
		"%=": "The remainder of the division.",	#/ translatable
		"^=": "Raises to the power of Expression.",	#/ translatable
	}],
	["Strings", {	#/ translatable
		"strip_edges": ["Removes spaces and line breaks at both ends.", CURRENT],	#/ translatable
		"to_upper": ["Makes every letter upper case.", CURRENT],	#/ translatable
		"to_lower": ["Makes every letter lower case.", CURRENT],	#/ translatable
		"replace": "Replaces text. Expression: [from, to].",	#/ translatable
		"substr": "Keeps part of the text. Expression: [start, length].",	#/ translatable
		"split": "Splits the text into a PackedStringArray. Expression: the separator.",	#/ translatable
		"split_to_array": "Splits the text into an Array. Expression: the separator.",	#/ translatable
		"join": "Joins an Array into one text. Expression: the separator.",	#/ translatable
		"path_join": "Adds a part to a file path. Expression: the part.",	#/ translatable
	}],
	["Arrays", {	#/ translatable
		"append": "Adds Expression at the end.",	#/ translatable
		"append_first": "Adds Expression at the start.",	#/ translatable
		"insert": "Adds an item at a position. Expression: [index, item].",	#/ translatable
		"erase": "Removes the first item equal to Expression.",	#/ translatable
		"remove_at": "Removes the item at a position. Expression: the index.",	#/ translatable
		"slice": "Keeps part of the Array. Expression: [start, end].",	#/ translatable
		"clear": ["Empties an Array or Dictionary.", CURRENT],	#/ translatable
		"reverse": ["Reverses the order.", CURRENT],	#/ translatable
		"sort": ["Sorts the items.", CURRENT],	#/ translatable
		"shuffle": ["Puts the items in random order.", CURRENT],	#/ translatable
		"unique": ["Removes repeated items.", CURRENT],	#/ translatable
		"rand_pick": ["Picks one item at random.", CURRENT],	#/ translatable
	}],
	["Dictionaries", {	#/ translatable
		"merge": "Adds Expression's keys, overwriting the ones that exist. Expression: a Dictionary.",	#/ translatable
		"get": "The value of one key. Expression: key, or [key, default].",	#/ translatable
		"set_key": "Sets one key. Expression: [key, value].",	#/ translatable
		"duplicate": "A copy of Expression, an Array or Dictionary.",	#/ translatable
		"deep_duplicate": "A copy of Expression, an Array or Dictionary, copying what it holds too.",	#/ translatable
	}],
	["Types", {	#/ translatable
		"typeof": ["The type, as a number.", CURRENT],	#/ translatable
		"type_string": ["The type's name.", CURRENT],	#/ translatable
		"is_array": ["Whether it is an Array.", CURRENT],	#/ translatable
		"is_dict": ["Whether it is a Dictionary.", CURRENT],	#/ translatable
		"is_object": ["Whether it is an Object.", CURRENT],	#/ translatable
		"is_nan": ["Whether it is not a number (NaN).", CURRENT],	#/ translatable
		"is_inf": ["Whether it is infinite.", CURRENT],	#/ translatable
		"to_int": ["Converts to a whole number.", CURRENT],	#/ translatable
		"to_float": ["Converts to a decimal number.", CURRENT],	#/ translatable
		"to_string": ["Converts to text.", CURRENT],	#/ translatable
		"to_bool": ["Converts to true or false.", CURRENT],	#/ translatable
		"toggle_bool": ["Turns true into false, and false into true.", CURRENT],	#/ translatable
		"var_to_str": ["Converts to Godot's text format.", CURRENT],	#/ translatable
		"str_to_var": ["Reads Godot's text format.", CURRENT],	#/ translatable
		"json_to_str": ["Converts to JSON text.", CURRENT],	#/ translatable
		"str_to_json": ["Reads JSON text.", CURRENT],	#/ translatable
		"var_to_bytes": ["Converts to bytes.", CURRENT],	#/ translatable
		"bytes_to_var": ["Reads bytes.", CURRENT],	#/ translatable
	}],
	["Math", {	#/ translatable
		"abs": ["Removes the minus sign.", CURRENT],	#/ translatable
		"floor": ["Rounds down.", CURRENT],	#/ translatable
		"ceil": ["Rounds up.", CURRENT],	#/ translatable
		"round": ["Rounds to the nearest whole number.", CURRENT],	#/ translatable
		"sqrt": ["Square root.", CURRENT],	#/ translatable
		"sign": ["-1, 0 or 1, by the value's sign.", CURRENT],	#/ translatable
		"sin": ["Sine, in radians.", CURRENT],	#/ translatable
		"cos": ["Cosine, in radians.", CURRENT],	#/ translatable
		"tan": ["Tangent, in radians.", CURRENT],	#/ translatable
		"asin": ["Arcsine, in radians.", CURRENT],	#/ translatable
		"acos": ["Arccosine, in radians.", CURRENT],	#/ translatable
		"atan": ["Arctangent, in radians.", CURRENT],	#/ translatable
		"deg_to_rad": ["Degrees to radians.", CURRENT],	#/ translatable
		"rad_to_deg": ["Radians to degrees.", CURRENT],	#/ translatable
		"log": ["Natural logarithm.", CURRENT],	#/ translatable
		"log10": ["Base-10 logarithm.", CURRENT],	#/ translatable
		"log_base": "Logarithm. Expression: the base.",	#/ translatable
		"clamp": "Keeps the value between two limits. Expression: [min, max].",	#/ translatable
		"min": "The smaller value. Expression: a number, or an Array.",	#/ translatable
		"max": "The larger value. Expression: a number, or an Array.",	#/ translatable
		"lerp": "Moves toward a value. Expression: [to, weight].",	#/ translatable
		"wrap": "Wraps the value around between two limits. Expression: [min, max].",	#/ translatable
	}],
	["Random", {	#/ translatable
		"randi": "A random whole number.",	#/ translatable
		"randf": "A random decimal number from 0 to 1.",	#/ translatable
		"randi_range": ["A random whole number between two limits. Expression: [min, max].", CURRENT],	#/ translatable
		"randf_range": ["A random decimal number between two limits. Expression: [min, max].", CURRENT],	#/ translatable
	}],
	["Nodes", {	#/ translatable
		"get_node": "The node at a path. Expression: the node path, from the engine.",	#/ translatable
		"get_node_or_null": "The node at a path, or null when there is none. Expression: the node path, from the engine.",	#/ translatable
	}],
	["Candy", {	#/ translatable
		"candy_to_dict": "Reads Candy's text format into a Dictionary.",	#/ translatable
		"candy_to_array": "Reads Candy's text format into an Array.",	#/ translatable
		"candy_to_string": "Writes a Dictionary or Array in Candy's text format.",	#/ translatable
	}],
]


func get_items(_config: Dictionary, _context: Dictionary) -> Array:
	var items := _to_items(BASIC)
	for group in GROUPS:
		items.append({"label": CandyLocale.t(group[0]), "items": _to_items(group[1])})
	return items


#* Items of operator -> tooltip pairs (a tooltip of [text, CURRENT] works on the current value):
func _to_items(operators: Dictionary) -> Array:
	var items: Array = []
	for operator in operators:
		var tooltip := ""
		var text = operators[operator]
		if text is Array:
			tooltip = "%s %s" % [CandyLocale.t(text[0]), CandyLocale.t(text[1])]
		else:
			tooltip = CandyLocale.t(text)
		items.append({"label": operator, "value": operator, "tooltip": tooltip})
	return items

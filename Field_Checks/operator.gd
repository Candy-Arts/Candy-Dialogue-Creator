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

#^ CandyValues.calculate_value()'s operators - keep in sync with Candy DE:
const OPERATORS := [
	"=", "+=", "-=", "*=", "×=", "/=", "÷=", "//=", "%=", "^=", "**=", "pow",
	"strip_edges", "to_upper", "to_lower", "replace", "substr", "split", "split_to_array", "join", "path_join",
	"append", "append_first", "insert", "erase", "remove_at", "slice", "clear", "reverse", "sort", "shuffle",
	"unique", "rand_pick",
	"merge", "get", "set_key", "duplicate", "deep_duplicate",
	"typeof", "type_string", "is_array", "is_dict", "is_object", "is_nan", "is_inf", "to_int", "to_float",
	"to_string", "to_bool", "toggle_bool", "var_to_str", "str_to_var", "json_to_str", "str_to_json",
	"var_to_bytes", "bytes_to_var",
	"abs", "floor", "ceil", "round", "sqrt", "root", "sign", "sin", "cos", "tan", "asin", "acos", "atan",
	"deg_to_rad", "rad_to_deg", "log", "log10", "log_base", "clamp", "min", "max", "lerp", "wrap",
	"randi", "rand_i", "randf", "rand_f", "randi_range", "rand_i_range", "randf_range", "rand_f_range",
	"get_node", "get_node_or_null",
	"candy_to_dict", "candy_to_array", "candy_to_string",
]


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "" or OPERATORS.has(value):
		return []
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not an operator."))]

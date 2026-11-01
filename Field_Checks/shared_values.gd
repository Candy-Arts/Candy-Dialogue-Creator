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


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var other = context.sibling_data(str(config.get("other", "")))
	if not context.data is Dictionary or not other is Dictionary:
		return []
	var theirs := _values(other)
	var shared: PackedStringArray = []
	for value in _values(context.data):
		if theirs.has(value) and not shared.has(value):
			shared.append(value)
	if shared.is_empty():
		return []
	var text := CandyChecks.fill(CandyLocale.t(str(config.get("text", ""))), context, {"shared": ", ".join(shared)})
	return [CandyChecks.message(str(config.get("severity", CandyChecks.WARNING)), text)]


#* The map's values that are known here:
func _values(map: Dictionary) -> Array:
	var result: Array = []
	for value in map.values():
		var text := str(value).strip_edges()
		if text == "" or text == CandyChecks.NOT_SET_VALUE or CandyChecks.is_expression(text):
			continue
		result.append(text)
	return result

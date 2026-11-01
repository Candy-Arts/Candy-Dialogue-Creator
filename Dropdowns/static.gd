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


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var items = config.get("items", [])
	if items is Array:
		return _shown(items)
	return []


#* Copy of the schema's items with their labels and tooltips translated (the schema keeps its own):
func _shown(items: Array) -> Array:
	var result: Array = []
	for item in items:
		if not item is Dictionary:
			result.append(item)
			continue
		var copy: Dictionary = item.duplicate()
		if copy.has("label"):
			copy["label"] = CandyLocale.t(str(copy["label"]))
		if copy.has("tooltip"):
			copy["tooltip"] = CandyLocale.t(str(copy["tooltip"]))
		if copy.get("items") is Array:
			copy["items"] = _shown(copy["items"])
		result.append(copy)
	return result

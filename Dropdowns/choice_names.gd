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

func get_items(config: Dictionary, context: Dictionary) -> Array:
	var items: Array = []
	var line_path = context.get("line_path", [])
	if not line_path is Array:
		return items
	var with_choices := str(config.get("list", "categories")) == "choices"
	for category in _entries(CandyDialogue.line_data(CandyDialogue.line_at(line_path)).get("Categories", [])):
		var category_name := str(category[0])
		if not with_choices:
			items.append({"label": category_name, "value": category_name})
			continue
		var choices: Array = []
		for choice in _entries(category[1].get("Choices", [])):
			choices.append({"label": str(choice[0]), "value": "%s, %s" % [category_name, choice[0]]})
		if not choices.is_empty():
			items.append({"label": category_name, "items": choices})
	return items


#* [name, data] of each entry of a named list ([{ "<name>" = { ... } }, ...]):
func _entries(list: Variant) -> Array:
	var entries: Array = []
	if not list is Array:
		return entries
	for wrapper in list:
		if wrapper is Dictionary and wrapper.size() > 0:
			var entry_name = wrapper.keys()[0]
			var data = wrapper[entry_name]
			if not data is Dictionary:
				data = {}
			entries.append([entry_name, data])
	return entries

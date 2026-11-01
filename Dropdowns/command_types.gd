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

#^ Submenu of the commands with no category:
const NO_CATEGORY := "Other"	#/ translatable


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var skipped_categories = config.get("exclude_categories", [])
	var skipped = config.get("exclude", [])
	if not skipped_categories is Array:
		skipped_categories = []
	if not skipped is Array:
		skipped = []

	var categories: Dictionary = {}
	for type in CandySchemas.line_types():
		var category := CandySchemas.get_category(type)
		if category == "":
			category = NO_CATEGORY
		if skipped_categories.has(category) or skipped.has(type):
			continue
		if not categories.has(category):
			categories[category] = []
		categories[category].append({"label": CandyLocale.command_title(CandySchemas.get_title(type)), "value": type, "tooltip": type})

	var names: Array = categories.keys()
	names.sort_custom(func(a: String, b: String) -> bool:
		if (a == NO_CATEGORY) != (b == NO_CATEGORY):
			return b == NO_CATEGORY
		return a.naturalnocasecmp_to(b) < 0)
	var items: Array = []
	for category in names:
		items.append({"label": CandyLocale.t(category), "items": categories[category]})
	return items

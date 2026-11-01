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
	var modes: Array = CandyResources.dialogue_modes()
	if modes.is_empty():
		modes = CandyResources.BUILT_IN_DIALOGUE_MODES.duplicate()

	var excluded: Array = []
	var exclude = config.get("exclude", [])
	if exclude is Array:
		for mode in exclude:
			excluded.append(str(mode).to_lower())

	var items: Array = []
	for mode in modes:
		if not str(mode).to_lower() in excluded:
			items.append({"label": str(mode), "value": str(mode)})

	items.append_array(CandyDropdowns.get_items({"items": config.get("items", [])}, {}))
	return items

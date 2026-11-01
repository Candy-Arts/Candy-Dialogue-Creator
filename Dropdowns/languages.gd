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
	var data := CandyVariationData.new(CandySettingsDraft.new())
	var items: Array = []
	for language in data.language_names():
		items.append({"label": str(language), "value": str(language)})

	items.append_array(CandyDropdowns.get_items({"items": config.get("items", [])}, {}))
	return items

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

const PATHS_KIND := "CS_Paths"


func get_items(_config: Dictionary, _context: Dictionary) -> Array:
	var items: Array = []
	for path_key in CandyDropdowns.project_data(PATHS_KIND):
		var prefix := path_key + "/"
		var children: Array = [{"label": prefix, "value": prefix, "tooltip": CandyLocale.t("Type the node's name after it.")}]
		var actors := CandyDropdowns.actor_items(prefix)
		if not actors.is_empty():
			children.append({"separator": true})
			children.append_array(actors)
		items.append({"label": path_key, "items": children})
	return items

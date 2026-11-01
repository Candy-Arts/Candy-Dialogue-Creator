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
	var allowed = config.get("types", [])
	var items: Array = []
	for type in CandyResources.MEDIA_TYPE_LABELS:
		if allowed is Array and not allowed.is_empty() and not allowed.has(type):
			continue
		var players: Array = []
		for player in CandyResources.media_players(type):
			players.append({"label": player, "value": player})
		if not players.is_empty():
			items.append({"label": CandyLocale.t(CandyResources.MEDIA_TYPE_LABELS[type]), "items": players})
	return items

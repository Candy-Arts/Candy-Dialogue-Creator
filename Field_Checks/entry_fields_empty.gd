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
	if not context.data is Dictionary:
		return []
	var fields = config.get("fields", [])
	if not fields is Array:
		return []
	for field in fields:
		if str(context.data.get(str(field), "")).strip_edges() != "":
			return []
	return [CandyChecks.message(str(config.get("severity", CandyChecks.WARNING)), CandyLocale.t(str(config.get("text", ""))))]

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
	var count := 0
	if context.data is Array:
		count = context.data.size()
	elif context.data is Dictionary:
		for key in context.data:
			if str(key) != CandyDialogue.META_KEY:
				count += 1
	var outside := false
	if config.has("min") and count < int(config["min"]):
		outside = true
	if config.has("max") and count > int(config["max"]):
		outside = true
	if not outside:
		return []
	return [CandyChecks.message(str(config.get("severity", CandyChecks.WARNING)), CandyLocale.t(str(config.get("text", ""))))]

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
	var value := context.value.strip_edges()
	if value == "" or value.to_lower() == CandyChecks.NOT_SET_VALUE:
		return []
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a whole number."))]
	if value.to_int() < 0:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Can't be negative."))]
	var duration := 0
	var duration_field := str(config.get("duration_field", ""))
	if duration_field != "":
		duration = CandyChecks.duration_state(context.sibling(duration_field))
	if value.to_int() == 0 and duration == 0:
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Stops at once, like an empty Loops field."))]
	return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Counted from the start of the playback."))]

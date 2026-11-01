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
	var value := context.value.strip_edges().to_lower()
	if value in ["1", "0", "true", "false"]:
		return []
	var reset := bool(config.get("reset", false))
	if reset and value == "reset":
		return []
	if reset:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not '1' or '0', or 'Reset'."))]
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not '1' or '0'."))]

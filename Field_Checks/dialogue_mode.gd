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
	if bool(config.get("reset", false)) and value.to_lower() == "reset":
		return []
	var modes: Array = CandyResources.dialogue_modes()
	if modes.is_empty():
		return []
	for mode in modes:
		if str(mode).to_lower() == value.to_lower():
			return []
	return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No %s dialogue mode in the project's Dialogue_Modes folder.") % value)]

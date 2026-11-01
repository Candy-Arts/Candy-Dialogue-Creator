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

#^ CandyPauseLoop.RESUME_MODES:
const MODES := ["Return", "Continue", "Finish_Return", "Finish_Continue"]


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	#% "null" is Return on a _Pause:
	if value == CandyChecks.NOT_SET_VALUE:
		return []
	if value == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a resume mode."))]
	for mode in MODES:
		if value.to_lower() == str(mode).to_lower():
			return []
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a resume mode."))]

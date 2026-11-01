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


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value
	var result: Array = []
	var start := value.rfind("[")
	if start != -1 and value.find("]", start) == -1:
		result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Tag not closed with ].")))
	if value.contains("[/"):
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Candy DE adds the closing tags itself: write only the opening ones.")))
	return result

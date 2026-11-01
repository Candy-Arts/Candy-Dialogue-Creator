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
	var value := context.value.strip_edges()
	if value == "":
		return []
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Value is not a whole number."))]
	if value.to_int() == 0:
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Stays paused until a Resume command, like '-1'."))]
	return []

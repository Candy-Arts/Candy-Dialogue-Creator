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
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Needs a node."))]
	var role_symbol := CandyChecks.symbol("role")
	if role_symbol != "" and value.begins_with(role_symbol):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("A role needs a container before it."))]
	return []

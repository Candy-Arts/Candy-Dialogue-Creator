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
	if value.begins_with("["):
		return [CandyChecks.message(CandyChecks.WARNING,
			CandyLocale.t("Passed as one text argument, \"%s\". For a list of arguments, start with {expression}.") % value)]
	if CandyChecks.is_number(value):
		return [CandyChecks.message(CandyChecks.NOTICE,
			CandyLocale.t("Passed as the text \"{value}\". Write {expression}{value} for the number.").format({"value": value}))]
	if value.to_lower() == "true" or value.to_lower() == "false":
		return [CandyChecks.message(CandyChecks.NOTICE,
			CandyLocale.t("Passed as the text \"{value}\". Write {expression}{value} for the boolean.").format({"value": value}))]
	return []

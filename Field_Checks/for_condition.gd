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

const EXPRESSIONS := true


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Required."))]
	var found := RegEx.create_from_string("^(\\S+)\\s+in\\s+(.+)$").search(value)
	if found == null:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Write it as: name in {expression}iterable."))]
	if not CandyChecks.is_expression(found.get_string(2)):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("The iterable must start with {expression}."))]
	return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Each item is in {expression}for_['%s'].") % found.get_string(1))]

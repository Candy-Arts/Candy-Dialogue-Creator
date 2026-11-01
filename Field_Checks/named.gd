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
#^ The message for each "kind" of name:
const PATH_TEXTS := {
	"signal": "With {expression}, the expression gives the signal's path. To name it directly, leave {expression} out.",	#/ translatable
	"method": "With {expression}, the expression gives the method's path. To name it directly, leave {expression} out.",	#/ translatable
}


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Required."))]
	if CandyChecks.is_expression(value):
		var kind := str(config.get("kind", "signal"))
		if PATH_TEXTS.has(kind):
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t(PATH_TEXTS[kind]))]
		return [CandyChecks.message(CandyChecks.WARNING,
			CandyLocale.t("With {expression}, the expression gives the %s's path. To name it directly, leave {expression} out.") % kind)]
	return []

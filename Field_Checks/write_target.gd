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
	if CandyChecks.is_expression(context.value):
		return [CandyChecks.message(CandyChecks.WARNING,
			CandyLocale.t("With {expression}, the expression gives the variable's path. To write to the variable itself, leave {expression} out."))]
	return []

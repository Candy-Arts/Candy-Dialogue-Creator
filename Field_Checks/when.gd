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
	var rule = config.get("rule", {})
	if not rule is Dictionary or not context.rule(rule):
		return []
	var defaults = config.get("defaults", {})
	if not defaults is Dictionary:
		defaults = {}
	return [CandyChecks.message(str(config.get("severity", CandyChecks.NOTICE)),
		CandyChecks.fill(CandyLocale.t(str(config.get("text", ""))), context, {}, defaults))]

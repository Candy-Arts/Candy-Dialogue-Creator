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
	var value := context.value.strip_edges().to_lower()
	var values = config.get("values", [])
	if values is Array:
		for item in values:
			if str(item).to_lower() == value:
				return []
	if bool(config.get("reset", false)) and value == "reset":
		return []
	if config.has("others"):
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t(str(config["others"])))]
	var label := str(context.spec.get("id", ""))
	if context.spec.has("label"):
		label = CandyLocale.t(str(context.spec["label"]))
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a %s value.") % label)]

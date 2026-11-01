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
	var value := context.value.strip_edges()
	if value == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("An entry needs a name."))]
	match str(config.get("kind", "")):
		"player":
			var players := context.dropdown_values(context.spec.get("entry_dropdown", {}))
			if not players.is_empty() and not CandyChecks.has_text(players, value):
				return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No media player %s in the project.") % value)]
		"layer":
			var layers := context.dropdown_values(context.spec.get("entry_dropdown", {}))
			if not layers.is_empty() and not CandyChecks.has_text(layers, value):
				return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No layer %s in the background scene.") % value)]
		"target":
			var role_symbol := CandyChecks.symbol("role")
			if role_symbol != "" and value.begins_with(role_symbol):
				return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("A role needs a container before it."))]
	return []

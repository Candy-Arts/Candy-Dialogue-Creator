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
	var role_symbol := CandyChecks.symbol("role")
	if role_symbol != "" and value == role_symbol:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("A role needs a name."))]
	var role := CandyChecks.role_name(value)
	if role != "":
		var roles := CandyChecks.project_data("Roles")
		if not roles.is_empty() and not CandyChecks.has_text(roles, role) and not CandyChecks.has_text(roles, value):
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No role %s in the project's roles.") % role)]
		return []
	var actors := CandyChecks.project_data("Actors")
	if not actors.is_empty() and not CandyChecks.has_text(actors, value):
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No actor %s in the project's actors.") % value)]
	return []

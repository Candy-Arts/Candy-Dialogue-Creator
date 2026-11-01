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
	var own := context.entry_key()
	if value == own:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("An actor can't swap with itself."))]
	if context.field_path.size() >= 3:
		var actors = CandyDialogue.get_field(context.line_path, context.field_path.slice(0, context.field_path.size() - 2), {})
		if actors is Dictionary and actors.get(value) is Dictionary \
				and str(actors[value].get("With", "")).strip_edges() == own:
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("This pair is listed twice: the second swap undoes the first."))]
	return []

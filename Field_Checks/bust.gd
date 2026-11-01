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
	var result: Array = []
	var own := context.entry_key()
	if context.field_path.size() >= 3:
		var actors = CandyDialogue.get_field(context.line_path, context.field_path.slice(0, context.field_path.size() - 2), {})
		if actors is Dictionary:
			for actor in actors:
				if str(actor) == own or not actors[actor] is Dictionary:
					continue
				if str(actors[actor].get("Bust", "")).strip_edges() == value:
					result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("%s is on this bust too.") % str(actor)))
					break
	var busts := context.dropdown_values()
	if not busts.is_empty() and not CandyChecks.has_text(busts, value):
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No bust %s in the bust scene.") % value))
	return result

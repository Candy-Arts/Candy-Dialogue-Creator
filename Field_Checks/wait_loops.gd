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
		return []
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a whole number."))]
	var wait := value.to_int()
	if wait < 0:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Negative: the dialogue doesn't wait for any loop."))]
	var loop_field := str(config.get("loop_field", ""))
	var duration_field := str(config.get("duration_field", ""))
	if duration_field != "" and CandyChecks.duration_state(context.sibling(duration_field)) != 0:
		return []
	if loop_field != "":
		var loop := context.sibling(loop_field)
		if CandyChecks.is_whole(loop) and loop.to_int() >= 1 and wait > loop.to_int():
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.tn("The media only plays %d time.", "The media only plays %d times.", loop.to_int()) % loop.to_int())]
	return []

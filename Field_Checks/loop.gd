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
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Plays once, like '1'."))]
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a whole number."))]
	var loops := value.to_int()
	var duration := 0
	var duration_field := str(config.get("duration_field", ""))
	if duration_field != "":
		duration = CandyChecks.duration_state(context.sibling(duration_field))
	if loops == 0:
		if duration == 1:
			return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Plays for its Duration only."))]
		if duration == 0:
			return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Holds on the first frame."))]
		return []
	if loops < 0 and duration == 1:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Loops forever: the Duration is ignored."))]
	if loops < -1:
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Loops forever, like '-1'."))]
	return []

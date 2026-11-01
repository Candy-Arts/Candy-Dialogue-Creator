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

#^ The notice for each "decider":
const SAME_AS_EMPTY := {
	"player": "Same as empty: the player decides.",	#/ translatable
	"scene": "Same as empty: the scene decides.",	#/ translatable
}


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "" or value == "1" or value == "-1":
		return []
	if value == "0":
		var decider := str(config.get("decider", "player"))
		if SAME_AS_EMPTY.has(decider):
			return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t(SAME_AS_EMPTY[decider]))]
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Same as empty: the %s decides.") % decider)]
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not '1', '0', '-1' or empty."))]

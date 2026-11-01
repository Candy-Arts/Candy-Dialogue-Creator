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
	if context.value.strip_edges() != "":
		return []
	var none := CandyLocale.t("Nothing")
	if config.has("none"):
		none = CandyLocale.t(str(config["none"]))
	return [CandyChecks.message(CandyChecks.NOTICE,
		CandyLocale.t("%s on this line, over the actor's and the engine's. For no override, write null.") % none)]

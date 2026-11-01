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

const EXPRESSIONS := true


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	if context.value.strip_edges() != "":
		return []
	var text := CandyLocale.t("Required.")
	if config.has("text"):
		text = CandyLocale.t(str(config["text"]))
	return [CandyChecks.message(CandyChecks.ERROR, text)]

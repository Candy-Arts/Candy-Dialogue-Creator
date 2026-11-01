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

const FORBIDDEN := ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var found: PackedStringArray = []
	for character in FORBIDDEN:
		if context.value.contains(character):
			found.append(character)
	if found.is_empty():
		return []
	return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("%s become _.") % " ".join(found))]

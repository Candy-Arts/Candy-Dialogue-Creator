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
const CHAIN_TYPES := ["If", "Elif"]


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	if context.line_path.size() != 3:
		return []
	var index := int(context.line_path[2])
	var lines := CandyDialogue.lines(str(context.line_path[0]), str(context.line_path[1]))
	if index > 0 and index - 1 < lines.size() and lines[index - 1] is Dictionary \
			and CHAIN_TYPES.has(CandyDialogue.line_type(lines[index - 1])):
		return []
	return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No If before it: it never runs."))]

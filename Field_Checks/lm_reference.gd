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
	if CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.WARNING,
			CandyLocale.t("A Line of %s is read as a line number: no transition can reach this LM by its Reference.") % value)]
	if context.line_path.size() != 3:
		return []
	var lines := CandyDialogue.lines(str(context.line_path[0]), str(context.line_path[1]))
	for i in lines.size():
		if i == int(context.line_path[2]) or not lines[i] is Dictionary or CandyDialogue.line_type(lines[i]) != "LM":
			continue
		if str(CandyDialogue.line_data(lines[i]).get("Reference", "")).strip_edges() == value:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Another LM of this block has this Reference."))]
	return []

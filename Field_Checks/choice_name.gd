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

const FORBIDDEN := [".", ":", "@", "/", "%", "\""]
#^ The message for each "kind" of entry:
const SAME_NAME := {
	"category": "Another category has this name.",	#/ translatable
	"choice": "Another choice has this name.",	#/ translatable
	"timer": "Another timer has this name.",	#/ translatable
	"entry": "Another entry has this name.",	#/ translatable
}


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Needs a name."))]
	for character in FORBIDDEN:
		if value.contains(character):
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Can't contain . : @ / % or \"."))]
	var count := 0
	if context.container is Array:
		for wrapper in context.container:
			if wrapper is Dictionary and wrapper.size() > 0 and str(wrapper.keys()[0]).strip_edges() == value:
				count += 1
	if count > 1:
		var kind := str(config.get("kind", "entry"))
		if SAME_NAME.has(kind):
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t(SAME_NAME[kind]))]
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Another %s has this name.") % kind)]
	return []

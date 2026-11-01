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

#^ The warning for each level the tags are "used" on:
const UNUSED_TAG := {
	"menu": "No menu in this dialogue has the tag %s.",	#/ translatable
	"category": "No category in this dialogue has the tag %s.",	#/ translatable
	"choice": "No choice in this dialogue has the tag %s.",	#/ translatable
	"timer": "No timer in this dialogue has the tag %s.",	#/ translatable
}


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	var result: Array = []
	if CandyChecks.has_empty_item(value):
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Value contains an empty tag: remove the extra comma.")))
	var level := str(config.get("used", ""))
	if level == "":
		return result
	var known := context.dropdown_values()
	for tag in CandyChecks.split_list(value):
		if not CandyChecks.has_text(known, tag, true):
			if UNUSED_TAG.has(level):
				result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t(UNUSED_TAG[level]) % tag))
			else:
				result.append(CandyChecks.message(CandyChecks.WARNING,
					CandyLocale.t("No {level} in this dialogue has the tag {tag}.").format({"level": level, "tag": tag})))
			break
	return result

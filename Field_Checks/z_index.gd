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

const Z_LIMIT := 4096


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "" or value.to_lower() == "reset":
		return []
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a z index."))]
	if value.begins_with("+") or value.begins_with("-"):
		return []
	var z := value.to_int()
	if absi(z) > Z_LIMIT:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Kept within -4096 and 4096."))]
	var counted_from := CandyLocale.t("the player")
	if config.has("reference"):
		counted_from = CandyLocale.t(str(config["reference"]))
	return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Exactly z index {z}. To count from {reference}, write +{z} or -{z}.").format(
		{"z": z, "reference": counted_from}))]

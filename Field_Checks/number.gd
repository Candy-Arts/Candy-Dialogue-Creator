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
	if value == "" and bool(config.get("allow_empty", true)):
		return []
	var others = config.get("values", [])
	if others is Array:
		for item in others:
			if str(item).to_lower() == value.to_lower():
				return []
	var prefix := str(config.get("trim_prefix", ""))
	if prefix != "":
		value = value.trim_prefix(prefix).strip_edges()
	var whole := bool(config.get("whole", false))
	var fits := CandyChecks.is_number(value)
	if whole:
		fits = CandyChecks.is_whole(value)
	if fits and config.has("min") and CandyChecks.to_number(value) < float(config["min"]):
		fits = false
	if fits:
		return []
	var text := CandyLocale.t("Not a number.")
	if whole:
		text = CandyLocale.t("Not a whole number.")
	if config.has("text"):
		text = CandyLocale.t(str(config["text"]))
	return [CandyChecks.message(CandyChecks.ERROR, text)]

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
	if value == "":
		if bool(config.get("allow_empty", true)):
			return []
	var prefix := str(config.get("trim_prefix", ""))
	if prefix != "":
		value = value.trim_prefix(prefix)
	var case_sensitive := bool(config.get("case_sensitive", false))
	var values = config.get("values", [])
	if not values is Array:
		values = []
	for item in values:
		var wanted := str(item)
		if value == wanted or (not case_sensitive and value.to_lower() == wanted.to_lower()):
			return []
	if case_sensitive and (bool(config.get("case_text", false)) or bool(config.get("only_case", false))):
		for item in values:
			if value.to_lower() == str(item).to_lower():
				return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Case-sensitive: write %s.") % str(item))]
	if bool(config.get("only_case", false)):
		return []
	var text := CandyLocale.t("Not a valid value.")
	if config.has("text"):
		text = CandyLocale.t(str(config["text"]))
	return [CandyChecks.message(CandyChecks.ERROR, text)]

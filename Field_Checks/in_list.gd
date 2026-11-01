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
		return []
	if bool(config.get("skip_paths", false)) and value.contains("/"):
		return []
	var known := context.dropdown_values(context.spec.get(str(config.get("dropdown", "dropdown")), {}))
	if known.is_empty():
		return []
	var items: Array = [value]
	if bool(config.get("each", false)):
		items = Array(CandyChecks.split_list(value))
	var ignore_case := bool(config.get("ignore_case", false))
	for item in items:
		var wanted := str(item)
		if bool(config.get("role", false)) and CandyChecks.role_name(wanted) != "":
			wanted = CandyChecks.role_name(wanted)
		if not CandyChecks.has_text(known, wanted, ignore_case):
			var text := CandyLocale.t("‹name› isn't known.")
			if config.has("text"):
				text = CandyLocale.t(str(config["text"]))
			return [CandyChecks.message(CandyChecks.WARNING, CandyChecks.fill(text, context, {"name": wanted}))]
	return []

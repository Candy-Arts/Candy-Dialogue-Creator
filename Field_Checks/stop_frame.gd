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
	var clears := bool(config.get("clear", true))
	var lowered := value.to_lower()
	if lowered == "clear" or lowered == "x":
		if not clears:
			var remove := CandyLocale.t("a Remove command")
			if config.has("remove"):
				remove = str(config["remove"])	#/ A command name
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Clear isn't available here: use %s.") % remove)]
		if lowered == "x":
			return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Same as Clear."))]
		return []
	if CandyChecks.is_whole(value) and value.to_int() >= -1:
		return []
	if clears:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Value must be a frame or 'Clear'."))]
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Value must be a frame."))]

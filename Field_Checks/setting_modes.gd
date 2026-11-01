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
	if value == str(context.spec.get("default", "")).strip_edges():
		return []
	var mode := context.sibling(str(config.get("mode_field", "Dialogue_Mode")))
	if mode == "" or context.is_unknown(mode):
		return []
	var built_in := false
	for item in CandyResources.BUILT_IN_DIALOGUE_MODES:
		if str(item).to_lower() == mode.to_lower():
			built_in = true
	if not built_in:
		return []
	var modes = config.get("modes", [])
	if not modes is Array:
		return []
	for item in modes:
		if str(item).to_lower() == mode.to_lower():
			return []
	var label := str(context.spec.get("id", ""))
	if context.spec.has("label"):
		label = CandyLocale.t(str(context.spec["label"]))
	var modes_text := ", ".join(PackedStringArray(modes))
	if config.has("modes_text"):
		modes_text = CandyLocale.t(str(config["modes_text"]))
	return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("{field} only applies in {modes}: ignored in {mode}.").format(
		{"field": label, "modes": modes_text, "mode": mode}))]

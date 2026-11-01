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
	if not CandyChecks.is_whole(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a whole number."))]
	if value.to_int() <= 0:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Counts as 1."))]
	if value.to_int() == 1:
		return []
	var variation := _variation_name(context)
	if variation == "":
		return []
	var shape := CandyVariations.split_variation(variation)
	var pool := 0
	var variations = context.line_data().get("Variations", [])
	if variations is Array:
		for entry in variations:
			if not entry is Dictionary or entry.is_empty():
				continue
			var other := CandyVariations.split_variation(str(entry.keys()[0]))
			if other["base"] == shape["base"] and other["tts"] == shape["tts"]:
				pool += 1
	if pool < 2:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("This variation has no #N alternatives: Weight has no effect."))]
	return []


#* The variation checked:
func _variation_name(context: CandyCheckContext) -> String:
	#% The one the Variation Properties widget shows:
	var shown = context.form_context.get("variation_name")
	if shown is Callable and shown.is_valid():
		return str(shown.call())
	return context.entry_key()		#/ The Variations entry the field is in

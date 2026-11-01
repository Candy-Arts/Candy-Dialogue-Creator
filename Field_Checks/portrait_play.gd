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


#* Play Portrait: a whole number from -3, or -3/<value used when the line has no voice>:
#? As in Candy DE's CandyPortrait.loops_of() and voice_fallback_of().
func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return []
	var parts := value.split("/")
	if parts.size() > 2:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Only one '/' is allowed: -3/<value without a voice>."))]

	var loops := parts[0].strip_edges()
	if not CandyChecks.is_whole(loops) or loops.to_int() < -3:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a Play Portrait value."))]
	if parts.size() == 1:
		return []

	#% -3/<fallback>:
	if loops.to_int() != -3:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Only -3 takes a value after '/'."))]
	var fallback := parts[1].strip_edges()
	if not CandyChecks.is_whole(fallback) or fallback.to_int() < -2:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("The value after '/' must be a number of loops, 0, -1 or -2."))]
	return []

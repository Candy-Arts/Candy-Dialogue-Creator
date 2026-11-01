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
	var loop := bool(config.get("loop", false))
	if loop and value.to_lower() in ["inf", "!", "0"]:
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Forever. (On Choice_List, 0 counts down once.)"))]
	var operator := ""
	var number := value
	if value.substr(0, 1) in ["+", "-", "*", "/"]:
		operator = value.substr(0, 1)
		number = value.substr(1).strip_edges()
	if not CandyChecks.is_number(number):
		if loop:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a loop count."))]
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a time."))]
	if operator == "/" and is_zero_approx(CandyChecks.to_number(number)):
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Can't divide by 0."))]
	if operator == "-":
		if loop:
			return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("%s fewer, not forever.") % number)]
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("%s s shorter, not a negative time.") % number)]
	return []

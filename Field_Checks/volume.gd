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
	var number := value
	var relative := value.begins_with("+=") or value.begins_with("-=")
	if relative:
		number = value.substr(2).strip_edges()
	if not CandyChecks.is_number(number):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a volume."))]
	if not relative and CandyChecks.to_number(number) < 0.0:
		var amount := number.trim_prefix("-")
		return [CandyChecks.message(CandyChecks.NOTICE,
			CandyLocale.t("Sets the volume to {volume} dB. To lower it by {amount} dB, write -={amount}.").format({"volume": number, "amount": amount}))]
	return []

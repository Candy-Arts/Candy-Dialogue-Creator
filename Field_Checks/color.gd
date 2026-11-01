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
	if value == "" or _is_color(value):
		return []
	return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a color."))]


func _is_color(value: String) -> bool:
	if value.begins_with("#"):
		return Color.html_is_valid(value)
	if value.begins_with("(") and value.ends_with(")"):
		var numbers := value.substr(1, value.length() - 2).split(",")
		if numbers.size() < 3 or numbers.size() > 4:
			return false
		for number in numbers:
			if not CandyChecks.is_number(number):
				return false
		return true
	#% Color name - an unknown one returns the fallback, so the two differ:
	return Color.from_string(value, Color(0, 0, 0, 0)) == Color.from_string(value, Color(1, 1, 1, 1))

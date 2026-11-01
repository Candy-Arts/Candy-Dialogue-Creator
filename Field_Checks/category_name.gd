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
	var names: Array = []
	var categories = context.line_data().get("Categories", [])
	if categories is Array:
		for wrapper in categories:
			if wrapper is Dictionary and wrapper.size() > 0:
				names.append(str(wrapper.keys()[0]))
	if not names.has(value):
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("No category %s in this menu.") % value)]
	if bool(config.get("own", false)) and _own_category(context) == value:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Already on this category."))]
	return []


#* The category the field's choice is in:
func _own_category(context: CandyCheckContext) -> String:
	var at := context.field_path.find("Categories")
	if at == -1 or at + 1 >= context.field_path.size():
		return ""
	return str(CandyDialogue.get_field(context.line_path,
		context.field_path.slice(0, at + 2) + [CandyDialogue.ENTRY_NAME], ""))

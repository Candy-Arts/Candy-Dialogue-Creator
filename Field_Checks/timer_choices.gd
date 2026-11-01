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

const TARGET_KEYS := ["Conversation", "Block", "Line"]


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		var timeout = context.sibling_data(str(config.get("timeout_field", "Timeout")))
		if timeout is Dictionary:
			for key in TARGET_KEYS:
				if str(timeout.get(key, "")).strip_edges() != "":
					return []
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("The timer times out without doing anything."))]

	var parts := value.trim_prefix("[").trim_suffix("]").split(",")
	if parts.size() != 2 or parts[0].strip_edges() == "" or parts[1].strip_edges() == "":
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Write it as: Category, Choice."))]
	var category_name := parts[0].strip_edges().trim_prefix("\"").trim_suffix("\"")
	var choice_name := parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	var category = _entry(context.line_data().get("Categories", []), category_name)
	if category == null:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("No category %s in this menu.") % category_name)]
	var choice = _entry(category.get("Choices", []), choice_name)
	if choice == null:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("No choice %s in this menu.") % choice_name)]
	if str(choice.get("Enabled", "1")).strip_edges() == "0":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Skipped while the choice is disabled."))]
	return []


#* The data of a named list's entry, or null:
func _entry(list: Variant, entry_name: String) -> Variant:
	if not list is Array:
		return null
	for wrapper in list:
		if wrapper is Dictionary and wrapper.size() > 0 and str(wrapper.keys()[0]) == entry_name:
			var data = wrapper[wrapper.keys()[0]]
			if data is Dictionary:
				return data
			return {}
	return null

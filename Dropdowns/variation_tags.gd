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


func get_items(_config: Dictionary, _context: Dictionary) -> Array:
	var data := CandyVariationData.new(CandySettingsDraft.new())
	return items_for(data.custom_tags())


#* Items for a list of custom tags ("S=F", "Shout"...):
func items_for(custom_tags: Array) -> Array:
	var groups := CandyVariations.group_tags(custom_tags)
	var items: Array = []
	for key in groups:
		var values: PackedStringArray = []
		for tag in groups[key]:
			var text := str(tag)
			if text != key:
				values.append(text.substr(text.find("=") + 1))
		var label := str(key)
		if not values.is_empty():
			label = "%s: %s" % [key, ", ".join(values)]
		items.append({"label": label, "value": str(key)})
	return items

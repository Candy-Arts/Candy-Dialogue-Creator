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


func get_items(config: Dictionary, context: Dictionary) -> Array:
	var items: Array = []
	var file_name := CandyDropdowns.sibling_value(config, context, "file_field")
	var path := CandyDropdowns.sprite_frames_path(file_name, CandyDropdowns.entry_name(config, context),
		str(config.get("folder", "Backgrounds")))
	if path == "":
		return items
	for animation in CandyDropdowns.sprite_frames_animations(path):
		items.append(CandyDropdowns.with_preview({"label": animation, "value": animation},
			str(config.get("preview", "")), path, str(animation)))
	return items

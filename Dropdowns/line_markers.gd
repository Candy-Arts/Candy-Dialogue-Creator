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
	var items: Array = [{"label": CandyLocale.t("First Line"), "value": "0"}]
	var conversation := CandyDropdowns.target_conversation(config, context)
	var block := CandyDropdowns.sibling_value(config, context, "block_field")
	var line_path = context.get("line_path", [])
	if block == "" and line_path is Array and line_path.size() > 1:
		block = str(line_path[1])
	if conversation == "" or block == "":
		return items
	var markers: Array = []
	for line in CandyDialogue.lines(conversation, block):
		if line is Dictionary and CandyDialogue.line_type(line) == "LM":
			var marker := str(CandyDialogue.line_data(line).get("Reference", ""))
			if marker != "":
				markers.append({"label": marker, "value": marker})
	if not markers.is_empty():
		items.append({"separator": true})
		items.append_array(markers)
	return items

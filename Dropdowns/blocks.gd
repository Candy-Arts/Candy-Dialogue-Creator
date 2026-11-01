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
	if str(config.get("scope", "current")) == "all":
		for conversation in CandyDialogue.conversation_names():
			var children: Array = []
			for block in CandyDialogue.block_names(conversation):
				children.append({"label": str(block), "value": str(block)})
			items.append({"label": str(conversation), "items": children})
		return items

	var conversation := CandyDropdowns.target_conversation(config, context)
	if conversation == "":
		return items
	for block in CandyDialogue.block_names(conversation):
		items.append({"label": str(block), "value": str(block)})
	return items

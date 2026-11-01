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

const TEMPLATE_FILE := "Candy_Default.tscn"


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var scenes = CandyResources.project_resources.get(str(config.get("nodes", "BG_Layer_Nodes")), {})
	if not scenes is Dictionary:
		return []

	var every_node: Array = []
	var scene_items: Array = []
	for scene_name in scenes:
		var nodes = scenes[scene_name]
		if str(scene_name) == CandyResources.ALL_KEY or str(scene_name) == TEMPLATE_FILE or not nodes is Array:
			continue
		var node_items: Array = []
		for node in nodes:
			node_items.append({"label": str(node), "value": str(node)})
			if not every_node.has(str(node)):
				every_node.append(str(node))
		if not node_items.is_empty():
			scene_items.append({"label": str(scene_name).get_basename(), "items": node_items})

	if every_node.is_empty():
		return []
	#Ł Natural order - "10" after "9":
	every_node.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	var all_items: Array = []
	for node in every_node:
		all_items.append({"label": node, "value": node})
	var items: Array = [{"label": CandyLocale.t("All"), "items": all_items}]
	items.append_array(scene_items)
	return items

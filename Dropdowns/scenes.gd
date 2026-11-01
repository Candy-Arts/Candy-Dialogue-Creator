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

const EXTENSION := "tscn"
const TEMPLATE_FILE := "Candy_Default.tscn"


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var items: Array = []
	var empty_label := str(config.get("empty_label", ""))
	if empty_label != "":
		items.append({"label": CandyLocale.t(empty_label), "value": ""})
	var folder = CandyResources.project_resources.get(str(config.get("folder", "")), {})
	if folder is Dictionary:
		var scenes := _folder_items(folder, "")
		if not items.is_empty() and not scenes.is_empty():
			items.append({"separator": true})
		items.append_array(scenes)
	return items


#* List a folder's scenes, subfolders first as submenus (empty ones left out):
func _folder_items(folder: Dictionary, prefix: String) -> Array:
	var items: Array = []
	var scenes: Array = []
	for entry_name in folder:
		var entry = folder[entry_name]
		if entry is Dictionary:
			var children := _folder_items(entry, prefix + str(entry_name) + "/")
			if not children.is_empty():
				items.append({"label": str(entry_name), "items": children})
		elif str(entry_name).get_extension() == EXTENSION and str(entry_name) != TEMPLATE_FILE:
			var value := prefix + str(entry_name)
			scenes.append({"label": str(entry_name), "value": value})
	items.append_array(scenes)
	return items

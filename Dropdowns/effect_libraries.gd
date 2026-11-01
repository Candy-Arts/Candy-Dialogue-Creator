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

const LIBRARIES_FOLDER := "Animation_Libraries"
const EXTENSIONS := ["tres", "res"]


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var folder = CandyResources.project_resources.get(str(config.get("folder", "Effects")), {})
	if not folder is Dictionary or not folder.get(LIBRARIES_FOLDER) is Dictionary:
		return []
	return _folder_items(folder[LIBRARIES_FOLDER], "")


#* List a folder's libraries, subfolders first as submenus (empty ones left out):
func _folder_items(folder: Dictionary, prefix: String) -> Array:
	var items: Array = []
	var files: Array = []
	for entry_name in folder:
		var entry_text := str(entry_name)
		if folder[entry_name] is Dictionary:
			var children := _folder_items(folder[entry_name], prefix + entry_text + "/")
			if not children.is_empty():
				items.append({"label": entry_text, "items": children})
		elif EXTENSIONS.has(entry_text.get_extension().to_lower()):
			files.append({"label": entry_text, "value": prefix + entry_text})
	items.append_array(files)
	return items

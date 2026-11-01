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
	var folders = CandyResources.project_resources.get(str(config.get("folder", "*Portraits")), {})
	if not folders is Dictionary:
		return []
	var preview_size := str(config.get("preview", ""))
	var entry := CandyDropdowns.entry_name(config, context)
	if folders.get(entry) is Dictionary:
		return _files(folders[entry], preview_size)

	var items: Array = []
	for other in folders:
		if folders[other] is Dictionary:
			var files := _files(folders[other], preview_size)
			if not files.is_empty():
				items.append({"label": str(other), "items": files})
	return items


#* SpriteFrames files in a folder's Sprite_Frames:
func _files(folder: Dictionary, preview_size: String) -> Array:
	var items: Array = []
	var frames_folder = folder.get(CandyDropdowns.SPRITE_FRAMES_FOLDER)
	if not frames_folder is Dictionary:
		return items
	for file_name in frames_folder:
		if not frames_folder[file_name] is Dictionary and CandyMediaTypes.kind_of(str(file_name)) == CandyMediaTypes.SPRITE_FRAMES:
			items.append(CandyDropdowns.with_preview({"label": str(file_name), "value": str(file_name)},
				preview_size, str(frames_folder[file_name])))
	return items

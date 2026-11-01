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
	var line_path = context.get("line_path", [])
	if not line_path is Array:
		return []
	var actor := CandyResources.voice_actor(CandyDropdowns.sibling_value(config, context, "actor_field"))

	var preview_size := str(config.get("preview", ""))
	var lists: Array = []    #/ [path, items], empty folders left out
	for found in CandyResources.voice_folders(line_path, actor):
		var files := _files(found[1], preview_size)
		if not files.is_empty():
			lists.append([found[0], files])
	if lists.size() == 1:
		return lists[0][1]
	var items: Array = []
	for list in lists:
		items.append({"label": "/".join(list[0]), "items": list[1]})
	return items


#* Folder's own audio files, not its subfolders':
func _files(folder: Dictionary, preview_size: String) -> Array:
	var items: Array = []
	for entry_name in folder:
		if not folder[entry_name] is Dictionary and CandyMediaTypes.kind_of(str(entry_name)) == CandyMediaTypes.AUDIO:
			items.append(CandyDropdowns.with_preview({"label": str(entry_name), "value": str(entry_name)},
				preview_size, str(folder[entry_name])))
	return items

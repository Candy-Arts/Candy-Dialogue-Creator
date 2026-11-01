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

const ANIMATED_FOLDER := "Animated"


func get_items(config: Dictionary, context: Dictionary) -> Array:
	var player := _player_name(context)
	var types := CandyResources.media_player_types(player)
	if types.size() == 1:
		return _files(config, types[0], player)
	if types.size() > 1:
		#% Folder in several media folders - a submenu each:
		var shared: Array = []
		for type in CandyResources.MEDIA_TYPE_LABELS:
			if types.has(type):
				_add_submenu(shared, CandyLocale.t(CandyResources.MEDIA_TYPE_LABELS[type]), _files(config, type, player))
		return shared

	var items: Array = []
	for type in CandyResources.MEDIA_TYPE_LABELS:
		var players: Array = []
		for other in CandyResources.media_players(type):
			_add_submenu(players, other, _files(config, type, other))
		_add_submenu(items, CandyLocale.t(CandyResources.MEDIA_TYPE_LABELS[type]), players)
	return items


#* Map entry the field is in (the player):
func _player_name(context: Dictionary) -> String:
	var field_path = context.get("field_path", [])
	if not field_path is Array or field_path.size() < 2:
		return ""
	return str(field_path[field_path.size() - 2])


func _files(config: Dictionary, type: String, player: String) -> Array:
	var preview_size := ""
	var sizes = config.get("preview", {})
	if sizes is Dictionary:
		preview_size = str(sizes.get(type, ""))
	return _folder_items(CandyResources.media_player_folder(type, player), "", type, preview_size)


#* List a folder's items, subfolders first as submenus:
func _folder_items(folder: Dictionary, prefix: String, type: String, preview_size: String) -> Array:
	var items: Array = []
	var files: Array = []
	for entry_name in folder:
		var entry = folder[entry_name]
		var entry_text := str(entry_name)
		if not entry is Dictionary:
			if CandyMediaTypes.extensions_of(type).has(entry_text.get_extension().to_lower()):
				files.append(CandyDropdowns.with_preview({"label": entry_text, "value": prefix + entry_text},
					preview_size, str(entry)))
			continue

		if type == "image" and prefix == "" and entry_text == ANIMATED_FOLDER:
			var animations: Array = []
			for animation in entry:
				if entry[animation] is Dictionary:
					animations.append(CandyDropdowns.with_preview({"label": str(animation), "value": str(animation),
						"tooltip": CandyLocale.t("Frame animation.")}, preview_size, CandyMediaTypes.folder_path(entry[animation])))
			_add_submenu(items, CandyLocale.t("Animations"), animations)
		elif type == "image" and _holds_files(entry, type):
			files.append(CandyDropdowns.with_preview({"label": entry_text + "/", "value": prefix + entry_text,
				"tooltip": CandyLocale.t("Frame animation.")}, preview_size, CandyMediaTypes.folder_path(entry)))
		else:
			_add_submenu(items, entry_text, _folder_items(entry, prefix + entry_text + "/", type, preview_size))
	items.append_array(files)
	return items


func _holds_files(folder: Dictionary, type: String) -> bool:
	for entry_name in folder:
		if not folder[entry_name] is Dictionary and CandyMediaTypes.extensions_of(type).has(str(entry_name).get_extension().to_lower()):
			return true
	return false


#* Add a submenu, unless empty:
func _add_submenu(items: Array, label: String, children: Array) -> void:
	if not children.is_empty():
		items.append({"label": label, "items": children})

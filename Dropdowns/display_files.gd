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
const SKIPPED_FOLDERS := ["Button_Textures", "Animation_Libraries"]
#^ What Candy DE shows on TextureRect, Sprite and VideoStreamPlayer nodes:
const FILE_KINDS := [CandyMediaTypes.IMAGE, CandyMediaTypes.SPRITE, CandyMediaTypes.VIDEO]


func get_items(config: Dictionary, context: Dictionary) -> Array:
	var folders = CandyResources.project_resources.get(str(config.get("folder", "Backgrounds")), {})
	if not folders is Dictionary:
		return []
	var preview_size := str(config.get("preview", ""))
	var entry := CandyDropdowns.entry_name(config, context)
	if folders.get(entry) is Dictionary and not SKIPPED_FOLDERS.has(entry):
		return _folder_items(folders[entry], "", preview_size)

	var items: Array = []
	for other in folders:
		if folders[other] is Dictionary and not SKIPPED_FOLDERS.has(str(other)):
			_add_submenu(items, str(other), _folder_items(folders[other], "", preview_size))
	return items


#* List a folder's items, subfolders first as submenus:
func _folder_items(folder: Dictionary, prefix: String, preview_size: String) -> Array:
	var items: Array = []
	var files: Array = []
	for entry_name in folder:
		var entry = folder[entry_name]
		var entry_text := str(entry_name)
		if not entry is Dictionary:
			if FILE_KINDS.has(CandyMediaTypes.kind_of(entry_text)):
				files.append(CandyDropdowns.with_preview({"label": entry_text, "value": prefix + entry_text},
					preview_size, str(entry)))
			continue
		if prefix == "" and SKIPPED_FOLDERS.has(entry_text):
			continue

		if prefix == "" and entry_text == ANIMATED_FOLDER:
			var animations: Array = []
			for animation in entry:
				if entry[animation] is Dictionary:
					animations.append(CandyDropdowns.with_preview({"label": str(animation), "value": str(animation),
						"tooltip": CandyLocale.t("Frame animation.")}, preview_size, CandyMediaTypes.folder_path(entry[animation])))
			_add_submenu(items, CandyLocale.t("Animations"), animations)
		elif prefix == "" and entry_text == CandyDropdowns.SPRITE_FRAMES_FOLDER:
			var frames: Array = []
			for frames_file in entry:
				if not entry[frames_file] is Dictionary and CandyMediaTypes.kind_of(str(frames_file)) == CandyMediaTypes.SPRITE_FRAMES:
					frames.append(CandyDropdowns.with_preview({"label": str(frames_file), "value": str(frames_file),
						"tooltip": CandyLocale.t("SpriteFrames, for AnimatedSprite nodes.")}, preview_size, str(entry[frames_file])))
			_add_submenu(items, CandyLocale.t("Sprite Frames"), frames)
		elif CandyMediaTypes.holds_images(entry):
			files.append(CandyDropdowns.with_preview({"label": entry_text + "/", "value": prefix + entry_text,
				"tooltip": CandyLocale.t("Frame animation.")}, preview_size, CandyMediaTypes.folder_path(entry)))
		else:
			_add_submenu(items, entry_text, _folder_items(entry, prefix + entry_text + "/", preview_size))
	items.append_array(files)
	return items


#* Add a submenu, unless empty:
func _add_submenu(items: Array, label: String, children: Array) -> void:
	if not children.is_empty():	#/ An empty one would show as an item writing ""
		items.append({"label": label, "items": children})

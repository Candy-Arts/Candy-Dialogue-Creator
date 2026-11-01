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
const KINDS := [
	CandyMediaTypes.IMAGE,
	CandyMediaTypes.SPRITE,
	CandyMediaTypes.ANIMATED_IMAGES,
	CandyMediaTypes.SPRITE_FRAMES,
	CandyMediaTypes.VIDEO,
]
#^ Kinds a single file can be (the others are folders):
const FILE_KINDS := [CandyMediaTypes.IMAGE, CandyMediaTypes.SPRITE, CandyMediaTypes.VIDEO]


func get_items(config: Dictionary, context: Dictionary) -> Array:
	var folders = CandyResources.project_resources.get(str(config.get("folder", "*Portraits")), {})
	if not folders is Dictionary:
		return []
	var settings := {"frames_field": str(config.get("sprite_frames_field", "")),
		"preview": str(config.get("preview", ""))}
	var entry := CandyDropdowns.entry_name(config, context)
	if folders.get(entry) is Dictionary:
		return _actor_items(folders[entry], settings)

	var items: Array = []
	for actor in folders:
		if folders[actor] is Dictionary:
			_add_submenu(items, str(actor), _actor_items(folders[actor], settings))
	return items


#* One actor's folder, a submenu per kind:
#? settings: "frames_field" (the config's sprite_frames_field) and "preview".
func _actor_items(folder: Dictionary, settings: Dictionary) -> Array:
	var kinds := {}
	for kind in KINDS:
		kinds[kind] = []
	_collect(folder, "", kinds, settings)
	var items: Array = []
	for kind in KINDS:
		_add_submenu(items, CandyLocale.t(CandyMediaTypes.LABELS[kind]), kinds[kind])
	return items


#* Sort a folder's items, sub-folders included, into kinds:
func _collect(folder: Dictionary, prefix: String, kinds: Dictionary, settings: Dictionary) -> void:
	var preview_size := str(settings["preview"])
	for entry_name in folder:
		var entry = folder[entry_name]
		var entry_text := str(entry_name)
		if not entry is Dictionary:
			var kind := CandyMediaTypes.kind_of(entry_text)
			if FILE_KINDS.has(kind):
				kinds[kind].append(CandyDropdowns.with_preview({"label": prefix + entry_text,
					"value": prefix + entry_text}, preview_size, str(entry)))
			continue

		if prefix == "" and SKIPPED_FOLDERS.has(entry_text):
			continue
		if prefix == "" and entry_text == ANIMATED_FOLDER:
			for animation in entry:
				if entry[animation] is Dictionary:
					kinds[CandyMediaTypes.ANIMATED_IMAGES].append(CandyDropdowns.with_preview({"label": str(animation),
						"value": str(animation), "tooltip": CandyLocale.t("Frame animation, in %s/.") % ANIMATED_FOLDER},
						preview_size, CandyMediaTypes.folder_path(entry[animation])))
		elif prefix == "" and entry_text == CandyDropdowns.SPRITE_FRAMES_FOLDER:
			kinds[CandyMediaTypes.SPRITE_FRAMES] = _sprite_frames_items(entry, settings)
		elif CandyMediaTypes.holds_images(entry):
			kinds[CandyMediaTypes.ANIMATED_IMAGES].append(CandyDropdowns.with_preview({"label": prefix + entry_text + "/",
				"value": prefix + entry_text, "tooltip": CandyLocale.t("Frame animation.")}, preview_size, CandyMediaTypes.folder_path(entry)))
		else:
			_collect(entry, prefix + entry_text + "/", kinds, settings)


#* A submenu of animations per SpriteFrames file of Sprite_Frames:
func _sprite_frames_items(frames_folder: Dictionary, settings: Dictionary) -> Array:
	var frames_field := str(settings["frames_field"])
	var items: Array = []
	for file_name in frames_folder:
		var path = frames_folder[file_name]
		if path is Dictionary or CandyMediaTypes.kind_of(str(file_name)) != CandyMediaTypes.SPRITE_FRAMES:
			continue
		var animations: Array = []
		for animation in CandyDropdowns.sprite_frames_animations(str(path)):
			var item := {"label": str(animation), "value": str(animation),
				"tooltip": CandyLocale.t("Animation of %s, for AnimatedSprite portraits.") % file_name}
			#Ł Also write its file in the frames field:
			if frames_field != "":
				item["siblings"] = {frames_field: str(file_name)}
				item["tooltip"] = CandyLocale.t("Animation of %s, for AnimatedSprite portraits. Also sets the Sprite Frames File.") % file_name
			animations.append(CandyDropdowns.with_preview(item, str(settings["preview"]), str(path), str(animation)))
		_add_submenu(items, str(file_name), animations)
	return items


#* Add a submenu, unless empty:
func _add_submenu(items: Array, label: String, children: Array) -> void:
	if not children.is_empty():	#/ An empty one would show as an item writing ""
		items.append({"label": label, "items": children})

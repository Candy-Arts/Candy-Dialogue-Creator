#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLayoutLibrary

const WINDOWS := "Windows"
const AREAS := "Areas"
const LINE_AREAS := "Line Areas"
const PANELS := "Panels"
const WIDGETS := "Widgets"
const NAVIGATOR_COLORS := "Navigator Colors"
#^ Kinds with no type id folder:
const UNTYPED_KINDS := [WINDOWS, AREAS, LINE_AREAS, NAVIGATOR_COLORS]
const LEVEL_PROJECT := "project"
const LEVEL_USER := "user"
const EXTENSION := "txt"
const QUICK_SETTING := "quick_layouts"


#* The folder of a kind's (and type's) layouts at a level ("" with no profile):
static func folder(kind: String, type_id: String, level: String) -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	var untyped := UNTYPED_KINDS.has(kind)
	if type_id == "" and not untyped:
		return ""
	var base := CandyProfiles.current_profile_dir()
	if level == LEVEL_USER:
		base = CandyProfiles.user_dir(CandyProfiles.current_user)
	var path := base.path_join(CandyProfiles.LAYOUTS_DIR).path_join(kind)
	if not untyped:
		path = path.path_join(type_id)
	return path


static func path_of(kind: String, type_id: String, level: String, layout_name: String) -> String:
	var dir := folder(kind, type_id, level)
	if dir == "":
		return ""
	return dir.path_join("%s.%s" % [layout_name.strip_edges(), EXTENSION])


#* List the layouts - [{ "name", "level", "path" }], project's then user's:
static func list(kind: String, type_id: String) -> Array:
	var result: Array = []
	for level in [LEVEL_PROJECT, LEVEL_USER]:
		var dir := folder(kind, type_id, level)
		if dir == "" or not DirAccess.dir_exists_absolute(dir):
			continue
		var names: Array = []
		for file_name in DirAccess.get_files_at(dir):
			if file_name.get_extension() == EXTENSION:
				names.append(file_name.get_basename())
		names.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
		for layout_name in names:
			result.append({"name": layout_name, "level": level,
				"path": dir.path_join("%s.%s" % [layout_name, EXTENSION])})
	return result


static func exists(kind: String, type_id: String, level: String, layout_name: String) -> bool:
	var path := path_of(kind, type_id, level, layout_name)
	return path != "" and FileAccess.file_exists(path)


#* Save a layout (replaces one of the same name):
static func save(kind: String, type_id: String, level: String, layout_name: String, data: Dictionary) -> bool:
	var path := path_of(kind, type_id, level, layout_name)
	if path == "":
		return false
	return CandyVariantFile.write(path, data)


#* Delete a layout's file:
static func delete(kind: String, type_id: String, level: String, layout_name: String) -> bool:
	var path := path_of(kind, type_id, level, layout_name)
	if path == "" or not FileAccess.file_exists(path):
		return false
	if DirAccess.remove_absolute(path) != OK:
		return false
	#% A window layout also leaves the quick layouts, so a later one of the same name isn't listed by surprise:
	if kind == WINDOWS:
		var chosen = CandyProfiles.get_setting(QUICK_SETTING, [])
		if chosen is Array:
			var kept: Array = []
			for entry in chosen:
				if not is_quick([entry], {"name": layout_name, "level": level}):
					kept.append(entry)
			if kept.size() != chosen.size():
				CandyProfiles.set_setting(QUICK_SETTING, kept)
	return true


static func read(path: String) -> Dictionary:
	return CandyVariantFile.read(path)


#& Area layouts

#* An Area layout of area:
#? Panel states are as of the last capture (see CandyLayout.area_layout()).
static func area_layout(area: CandyAreaData) -> Dictionary:
	return {"root": area.to_dict().duplicate(true)}


#* The Area a layout holds, as a new tree (null if not one):
static func area_from_layout(layout: Variant) -> CandyAreaData:
	if not layout is Dictionary or not layout.get("root") is Dictionary:
		return null
	var area := CandyAreaData.from_dict(layout["root"].duplicate(true))
	if area != null:
		area.clear_uids()	#/ So a copy is never mistaken for its original
	return area


#& Quick layouts

#* The quick layouts that still exist, as list() gives them:
static func quick_layouts() -> Array:
	var chosen = CandyProfiles.get_setting(QUICK_SETTING, [])
	var result: Array = []
	for layout in list(WINDOWS, ""):
		if is_quick(chosen, layout):
			result.append(layout)
	return result


#* Whether a layout is in chosen (a "quick_layouts" value):
static func is_quick(chosen: Variant, layout: Dictionary) -> bool:
	if not chosen is Array:
		return false
	for entry in chosen:
		if entry is Dictionary and str(entry.get("name", "")) == str(layout["name"]) \
				and str(entry.get("level", "")) == str(layout["level"]):
			return true
	return false

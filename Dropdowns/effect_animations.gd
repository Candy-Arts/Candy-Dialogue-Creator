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


func get_items(config: Dictionary, context: Dictionary) -> Array:
	var items: Array = []
	var library := CandyDropdowns.sibling_value(config, context, "library_field")
	var path := _library_path(library, str(config.get("folder", "Effects")))
	if path == "" or path.get_extension().to_lower() != "tres" or not FileAccess.file_exists(path):
		return items
	for animation in _animation_names(FileAccess.get_file_as_string(path)):
		items.append({"label": animation, "value": animation})
	return items


#* Library's file system path, or "" when it can't be known here:
func _library_path(library: String, folder_key: String) -> String:
	if library == "":
		return ""
	var expression := CandyDropdowns.symbol("expression")
	if expression != "" and library.begins_with(expression):
		return ""
	if CandyResources.is_project_path(library):
		return CandyResources.to_file_path(library)
	var folder := CandyResources.resource_folder(folder_key)
	if folder == "":
		return ""
	return folder.path_join(LIBRARIES_FOLDER).path_join(library)


#* Read the animation names, the keys of the library's _data:
#/   [resource]
#/   _data = {
#/   &"Flash": SubResource("Animation_x1"),
#/   &"RESET": SubResource("Animation_x2")
#/   }
func _animation_names(text: String) -> Array:
	var names: Array = []
	var resource_start := text.find("\n[resource]")
	if resource_start == -1:
		return names
	var data_start := text.find("_data = {", resource_start)
	if data_start == -1:
		return names
	var data_end := text.find("\n}", data_start)
	if data_end == -1:
		data_end = text.length()
	#? Only keys are followed by ":", SubResource ids by ")".
	var key := RegEx.create_from_string("&?\"((?:[^\"\\\\]|\\\\.)*)\"\\s*:")
	for found in key.search_all(text.substr(data_start, data_end - data_start)):
		names.append(found.get_string(1).c_unescape())
	return names

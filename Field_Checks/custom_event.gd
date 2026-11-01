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

const EVENTS_FOLDER := "Candy_DE/Scripts/Custom_Events"


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	var root := CandyResources.project_root()
	if value == "" or root == "":
		return []
	var folder := root.path_join(EVENTS_FOLDER)
	if not DirAccess.dir_exists_absolute(folder):
		return []
	if _has_script(folder, value.to_lower()):
		return []
	return [CandyChecks.message(CandyChecks.WARNING,
		CandyLocale.t("No script %s in Custom_Events: Candy DE reports it and carries on.") % value)]


func _has_script(folder: String, wanted: String) -> bool:
	for file_name in DirAccess.get_files_at(folder):
		if file_name.get_extension() == "gd" and file_name.get_basename().to_lower() == wanted:
			return true
	for sub in DirAccess.get_directories_at(folder):
		if _has_script(folder.path_join(sub), wanted):
			return true
	return false

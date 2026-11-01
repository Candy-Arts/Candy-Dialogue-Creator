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

const TABLES_FOLDER := "Candy_DE/Scripts/User_Data/Localization_Tables"


func get_items(_config: Dictionary, _context: Dictionary) -> Array:
	var root := CandyResources.project_root()
	if root == "":
		return []
	var items: Array = []
	_add_tables(root.path_join(TABLES_FOLDER), items)
	return items


#* Add the table of each script in folder, then its sub-folders':
func _add_tables(folder: String, items: Array) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	var files := Array(DirAccess.get_files_at(folder))
	files.sort()
	for file in files:
		if str(file).get_extension() != "gd":
			continue
		var table := _table_name(folder.path_join(str(file)))
		if table != "":
			items.append({"label": table, "value": table})
	var folders := Array(DirAccess.get_directories_at(folder))
	folders.sort()
	for sub in folders:
		_add_tables(folder.path_join(str(sub)), items)


#* Variable a table script declares at its top level, or "":
func _table_name(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	var regex := RegEx.create_from_string("(?m)^var\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var found := regex.search(text)
	if found == null:
		return ""
	return found.get_string(1)

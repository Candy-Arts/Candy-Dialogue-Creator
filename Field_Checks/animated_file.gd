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


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	var animated := context.sibling(str(config.get("animated_field", "Animated")))
	if value == "" or not animated in ["0", "1"]:
		return []
	var folder := CandyResources.media_player_folder("image", context.entry_key())
	if folder.is_empty():
		return []
	var is_folder := folder.get(value) is Dictionary
	if folder.get(ANIMATED_FOLDER) is Dictionary and folder[ANIMATED_FOLDER].get(value) is Dictionary:
		is_folder = true
	var is_file := false
	for entry_name in folder:
		if not folder[entry_name] is Dictionary and (str(entry_name) == value or str(entry_name).get_basename() == value):
			is_file = true
	if animated == "1" and is_file and not is_folder:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Animated says folder, but File is a single image."))]
	if animated == "0" and is_folder and not is_file:
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Animated says single image, but File is a folder."))]
	return []

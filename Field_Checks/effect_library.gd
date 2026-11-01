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


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var folder_config := config.duplicate()
	folder_config["folder"] = str(config.get("folder", "Animation_Libraries"))
	return CandyChecks.file_messages(context, {
		"missing": CandyLocale.t("No library ‹name› in ‹folder›."),
		"missing_path": CandyLocale.t("This library doesn't exist."),
	}, CandyChecks.file_folder(folder_config, context))

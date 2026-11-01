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
	var folder := ""
	if config.has("folder_field"):
		folder = context.sibling(str(config["folder_field"]))
		if folder == "" or context.is_unknown(folder):
			folder = CandyLocale.t("its folder")
			if config.has("folder_label"):
				folder = CandyLocale.t(str(config["folder_label"]))
	else:
		folder = CandyChecks.file_folder(config, context)
	var texts := {}
	for key in ["missing", "missing_path", "empty", "no_default"]:
		if config.has(key):
			texts[key] = CandyLocale.t(str(config[key]))
	return CandyChecks.file_messages(context, texts, folder)

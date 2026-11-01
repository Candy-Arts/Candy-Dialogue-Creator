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
	return CandyChecks.file_messages(context, {
		"missing": CandyLocale.t("File not found in ‹folder›: 'Default' will play."),
		"missing_path": CandyLocale.t("This file doesn't exist."),
		"empty": CandyLocale.t("No file specified: 'Default' will play."),
		"no_default": CandyLocale.t("No Default file in ‹folder›."),
	}, CandyChecks.file_folder(config, context))

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

#^ Format -> tooltip, in menu order:
const FORMATS := {
	"json": "JSON text, readable by other tools.",	#/ translatable
	"txt": "Text, one \"name = value\" line per variable.",	#/ translatable
	"csv": "Spreadsheet rows, one \"name, value\" row per variable.",	#/ translatable
	"cfg": "Godot ConfigFile.",	#/ translatable
	"ini": "Godot ConfigFile, with an .ini extension.",	#/ translatable
	"bin": "Binary. Compact, but not readable as text.",	#/ translatable
	"b64": "The binary data as Base64 text.",	#/ translatable
	"tres": "Godot text Resource.",	#/ translatable
	"res": "Godot binary Resource.",	#/ translatable
	"dialogue": "A Candy dialogue, in a .txt file. Export: Data must be exactly one dictionary. Import: Dictionary is required.",	#/ translatable
}


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var items: Array = []
	if bool(config.get("from_extension", false)):
		items.append({"label": CandyLocale.t("From File's extension"), "value": "",
			"tooltip": CandyLocale.t("Takes the format from File: Save.json reads JSON.")})
		items.append({"separator": true})
	for format in FORMATS:
		items.append({"label": format, "value": format, "tooltip": CandyLocale.t(FORMATS[format])})
	return items

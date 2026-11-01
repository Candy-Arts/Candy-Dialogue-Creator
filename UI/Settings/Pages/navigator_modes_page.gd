#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorModesPage
extends CandySettingsPage

const OPEN_KEY := "navigator_line_modes_open"
const OPTIONS := [
	{"label": "Full",		#/ translatable
		"value": "full"},
	{"label": "Short",		#/ translatable
		"value": "short"},
	{"label": "Meta",		#/ translatable
		"value": "meta"},
]


func build() -> void:
	add_note(CandyLocale.t("What each command shows in the Dialogue Navigator's Custom mode. Full: the command and a summary of its data. Short: only what the line does (a Spoken_Line's text, a condition's Description, the media a command plays...). Meta: the command and its Meta Reference."))
	var options: Array = []
	for option in OPTIONS:
		options.append({"label": CandyLocale.t(str(option["label"])), "value": option["value"]})
	var categories := CandyNavigatorColors.categories()
	for category in categories:
		begin_section(CandyLocale.t(str(category)), "/".join([OPEN_KEY, str(category)]), true)
		for type in categories[category]:
			add_choice("/".join([CandyDialogue.LINE_MODES_SETTING, str(type)]),
				CandyLocale.command_title(CandySchemas.get_title(str(type))), options, str(type), "full")
		end_section()

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyListRowBreaks

const PREFIX := "row:"
#^ How a row break is listed in the settings dialogs:
const LABEL := "· · · New Row · · ·"      #/ translatable
const TOOLTIP := "Starts a new row: the buttons after it begin on the next row."      #/ translatable


static func is_row_break(entry: Variant) -> bool:
	return entry is String and str(entry).begins_with(PREFIX)


#* New row break id not in taken:
static func new_id(taken: Array) -> String:
	var number := 1
	while taken.has(PREFIX + str(number)):
		number += 1
	return PREFIX + str(number)

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyShortcutButton
extends Button

#^ The CandyShortcuts action it does, "" for none:
var action_id := ""


func _get_tooltip(_at_position: Vector2) -> String:
	return CandyShortcuts.with_keys(tooltip_text, action_id)

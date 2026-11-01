#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyListSeparators

const PREFIX := "separator:"
#^ How a separator is listed in the settings dialogs:
const LABEL := "──── Separator ────"      #/ translatable
const TOOLTIP := "A horizontal line between the entries above and below it."      #/ translatable


static func is_separator(entry: Variant) -> bool:
	return entry is String and str(entry).begins_with(PREFIX)


#* New separator id not in taken:
static func new_id(taken: Array) -> String:
	var number := 1
	while taken.has(PREFIX + str(number)):
		number += 1
	return PREFIX + str(number)


#* Show or hide a drawn list's nodes:
#? items, in order: [{ "node": Control, "separator": bool, "shown": bool }] ("shown" for non-separators).
static func update_visibility(items: Array) -> void:
	var waiting: Control = null    #/ Separator shown if a shown entry follows
	var any_shown := false
	for item in items:
		var node: Control = item["node"]
		if bool(item["separator"]):
			node.visible = false
			#% "hidden" (filtered, CandyFilters) - never shows, and leaves the next one free to:
			if bool(item.get("hidden", false)):
				continue
			#% Shows once, with shown entries before and after it:
			if any_shown and waiting == null:
				waiting = node
			continue
		var shown := bool(item.get("shown", true))
		node.visible = shown
		if shown:
			if waiting != null:
				waiting.visible = true
				waiting = null
			any_shown = true

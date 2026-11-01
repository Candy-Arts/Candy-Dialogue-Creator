#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldHelpButton
extends Button

const VALUES_TITLE := "Values:"	#/ translatable
const BULLET := "• "

var spec: Dictionary = {}


func _init(p_spec: Dictionary = {}) -> void:
	spec = p_spec
	text = "?"
	theme_type_variation = CandyThemeDefaults.HELP_BUTTON
	focus_mode = Control.FOCUS_NONE
	#? Own size, so it stays small and round.
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_HELP


func _get_tooltip(_at_position: Vector2) -> String:
	return help_text(spec)


#* The help text of a field spec:
static func help_text(field_spec: Dictionary) -> String:
	var id := str(field_spec.get("id", ""))
	var label := str(field_spec.get("label", id))
	var title := label
	if field_spec.has("label"):
		title = CandyLocale.t(label)
	if id != "" and id != label:
		title += " (%s)" % id
	var parts: PackedStringArray = [title]

	var summary := with_symbols(CandyLocale.t(str(field_spec.get("tooltip", ""))))
	if summary != "":
		parts.append(summary)

	var values = field_spec.get("values", [])
	if values is Array and not values.is_empty():
		var lines: PackedStringArray = [CandyLocale.t(VALUES_TITLE)]
		for value in values:
			lines.append(BULLET + with_symbols(CandyLocale.t(str(value))))
		parts.append("")
		parts.append("\n".join(lines))
	return "\n".join(parts)


#* Replace each {<symbol key>} with the project's symbol:
static func with_symbols(source: String) -> String:
	if not "{" in source:
		return source
	var symbols = CandyProfiles.get_setting(CandySymbolsPage.SYMBOLS_KEY, {})
	if not symbols is Dictionary:
		return source
	var result := source
	for key in symbols:
		result = result.replace("{%s}" % str(key), str(symbols[key]))
	return result

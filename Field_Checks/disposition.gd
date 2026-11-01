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

const PREFIX_CHARACTERS := "+-=!"
#^ What each condition checks, for the notice (none for unlisted forms):
const READINGS := {
	"": "Plays when the speaker has at least one of {names}.",	#/ translatable
	"+": "Plays when the speaker has all of {names}.",	#/ translatable
	"-": "Plays when the speaker has no dispositions other than {names}.",	#/ translatable
	"=": "Plays when the speaker has exactly {names}.",	#/ translatable
	"!": "Plays when the speaker has none of {names}.",	#/ translatable
	"(n)": "Plays when the speaker has exactly {count} of {names}.",	#/ translatable
	"+(n)": "Plays when the speaker has {count} or more of {names}.",	#/ translatable
	"-(n)": "Plays when the speaker has fewer than {count} of {names}.",	#/ translatable
}


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return []
	var result: Array = []
	var list := value
	var prefix := ""
	var count := ""
	if bool(config.get("condition", false)):
		var found := RegEx.create_from_string("^([+\\-=!]*)\\s*(\\(([^)]*)\\))?(.*)$").search(value)
		prefix = found.get_string(1)
		list = found.get_string(4).strip_edges()
		if found.get_string(2) != "":
			count = found.get_string(3).strip_edges()
			if not CandyChecks.is_whole(count):
				result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("(n) needs a whole number.")))
		if list != "" and not _starts_a_name(list):
			result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Unknown prefix.")))
		if context.sibling(str(config.get("speaker_field", "Reference"))) == "":
			result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("There's no speaker to check it against.")))

	if CandyChecks.has_empty_item(list):
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("An empty disposition: remove the extra comma.")))
	var known := CandyChecks.project_data("Dispositions")
	var names := CandyChecks.split_list(list)
	if not known.is_empty():
		for disposition in names:
			if not CandyChecks.has_text(known, disposition):
				result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No disposition %s in the project's data.") % disposition))
				break

	if bool(config.get("condition", false)) and not names.is_empty() and result.is_empty():
		var form := prefix
		if count != "":
			form += "(n)"
		if READINGS.has(form):
			var reading := CandyLocale.t(str(READINGS[form]))
			if count != "":
				reading = reading.replace("{count}", str(count.to_int()))
			result.append(CandyChecks.message(CandyChecks.NOTICE, reading.replace("{names}", ", ".join(names))))
	return result


#* Whether text starts like a disposition name, not a condition:
func _starts_a_name(text: String) -> bool:
	var first := text.substr(0, 1)
	if PREFIX_CHARACTERS.contains(first) or first == "(":
		return false
	return RegEx.create_from_string("^[\\p{L}\\p{N}_]").search(text) != null

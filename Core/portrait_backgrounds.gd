#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitBackgrounds

const SETTING := "portrait_backgrounds"
const ACTORS := "actors"
const ROLES := "roles"


#* Get a speaker's own background:
#? speaker_reference: a Spoken_Line's Speaker.
static func for_speaker(speaker_reference: String) -> Dictionary:
	var result := {"color": null, "texture": ""}
	var speaker := speaker_reference.strip_edges()
	if speaker == "":
		return result
	var kind := ACTORS
	#? Actor, or role with its symbol.
	var role_symbol := CandyDropdowns.symbol("role")
	if role_symbol != "" and speaker.begins_with(role_symbol):
		kind = ROLES
		speaker = speaker.substr(role_symbol.length())
	var all = CandyProfiles.get_setting(SETTING, {})
	if not all is Dictionary or not all.get(kind) is Dictionary:
		return result
	var entry = all[kind].get(speaker)
	if not entry is Dictionary:
		return result
	var color = entry.get("color", "")
	if color is String and str(color) != "":
		color = str_to_var(str(color))
	if color is Color:
		result["color"] = color
	result["texture"] = str(entry.get("texture", "")).strip_edges()
	return result			#/ { "color": Color or null, "texture": path or "" }

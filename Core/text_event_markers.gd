#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTextEventMarkers

const EVENTS_FIELD := "Text_Events"
const ENTRY_EVENTS_KEY := "Events"
const START_SYMBOL := "text_event_start"
const END_SYMBOL := "text_event_end"


#* Get the text event symbols, [start, end] ("" if not set):
static func symbols() -> PackedStringArray:
	var stored = CandyProfiles.get_setting("symbols", {})
	if not stored is Dictionary:
		stored = {}
	return PackedStringArray([str(stored.get(START_SYMBOL, "")), str(stored.get(END_SYMBOL, ""))])


#* Get an event's marker, "‡boom‡" ("" if the symbols aren't set):
static func marker(event_name: String) -> String:
	var pair := symbols()
	if pair[0] == "" or pair[1] == "":
		return ""
	return pair[0] + event_name + pair[1]


#* Strip the markers, as a player reads the text (for counting characters and words):
static func strip(text: String) -> String:
	var pair := symbols()
	var start_tag := pair[0]
	var end_tag := pair[1]
	if start_tag == "" or end_tag == "" or not text.contains(start_tag):
		return text

	var result := ""
	var i := 0
	while i < text.length():
		#¦ 1. Doubled start symbol:
		if text.substr(i, start_tag.length() * 2) == start_tag + start_tag:
			result += start_tag
			i += start_tag.length() * 2
			continue
		#¦ 2. Doubled end symbol:
		if end_tag != start_tag and text.substr(i, end_tag.length() * 2) == end_tag + end_tag:
			result += end_tag
			i += end_tag.length() * 2
			continue
		#¦ 3. Marker:
		if text.substr(i, start_tag.length()) == start_tag:
			var end_at := text.find(end_tag, i + start_tag.length())
			if end_at != -1:
				i = end_at + end_tag.length()
				continue
		result += text[i]
		i += 1
	return result


#* List a line's own Text_Events names, for CandyResources.names_matching():
static func line_events(table: Variant) -> Dictionary:
	var result := {}
	if not table is Dictionary:
		return result
	for pattern in table:
		var entry = table[pattern]
		if not entry is Dictionary:
			continue
		var events = entry.get(ENTRY_EVENTS_KEY, {})
		if not events is Dictionary:
			continue
		var names: Array = []
		for event_name in events:
			if events[event_name] is Dictionary:
				names.append(str(event_name))
		result[str(pattern)] = names
	return result			#/ { pattern: [names] }

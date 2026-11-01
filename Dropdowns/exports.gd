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


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var key := str(config.get("key", "File"))
	var exports: Array = []
	for conversation in CandyDialogue.conversation_names():
		for block in CandyDialogue.block_names(conversation):
			for line in CandyDialogue.lines(conversation, block):
				_collect(line, exports)

	var items: Array = []
	var seen := {}
	for export in exports:
		var value := _value_of(export, key)
		if value == "" or seen.has(value):
			continue
		seen[value] = true
		var item := {"label": value, "value": value}
		if key == "File":
			var hints := PackedStringArray()
			var folder := _plain(export.get("Path", ""))
			if folder != "":
				hints.append(CandyLocale.t("Written to %s: set Path to it too.") % folder)
			if value.get_extension() == "":
				hints.append(CandyLocale.t("Its format is only known in game: set Format too."))
			if not hints.is_empty():
				item["tooltip"] = " ".join(hints)
		items.append(item)
	return items


#* Collect every Export, nested Commands included:
func _collect(commands: Dictionary, exports: Array) -> void:
	for command in commands:
		var data = commands[command]
		if not data is Dictionary:
			continue
		if str(command) == "Export":
			exports.append(data)
		if data.get("Commands") is Dictionary:
			_collect(data["Commands"], exports)


func _value_of(export: Dictionary, key: String) -> String:
	if key != "File":
		return _plain(export.get(key, ""))
	var file_name := _plain(export.get("File", ""))
	if file_name == "":
		return ""
	var format := _plain(export.get("Format", "json")).to_lower().trim_prefix(".")
	if format == "":
		return file_name
	return file_name + "." + format


#* Value as a string, or "" when empty, "null" or an expression:
func _plain(value: Variant) -> String:
	var text := str(value).strip_edges()
	if text == "null":
		return ""
	var expression := CandyDropdowns.symbol("expression")
	if expression != "" and text.begins_with(expression):
		return ""
	return text

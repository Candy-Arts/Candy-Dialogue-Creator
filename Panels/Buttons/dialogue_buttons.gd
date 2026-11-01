#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueButtons

const SCHEMA_PREFIX := "line:"
const LINE_TOOLTIP := "Click: add after the selection\nCtrl+Click: add before the selection"	#/ translatable

const DEFINITIONS := [
	{
		"id": "conversation",
		"label": "Conversation",	#/ translatable
		"tooltip": "Add a new conversation",	#/ translatable
		"action": "conversation",
	},
	{
		"id": "block",
		"label": "Block",	#/ translatable
		"tooltip": "Add a new block to the selected conversation",	#/ translatable
		"action": "block",
	},
]


static func ids() -> Array:
	var result: Array = []
	for definition in DEFINITIONS:
		result.append(definition["id"])
	result.append_array(schema_ids())
	return result


#* Schema line type buttons, by category then title:
static func schema_ids() -> Array:
	var covered := {}
	for definition in DEFINITIONS:
		if definition.has("line_type"):
			covered[str(definition["line_type"])] = true
	var result: Array = []
	for type in CandySchemas.line_types():
		if not covered.has(type):
			result.append(SCHEMA_PREFIX + str(type))
	return result


static func get_definition(id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if definition["id"] == id:
			return definition
	if id.begins_with(SCHEMA_PREFIX):
		var type := id.substr(SCHEMA_PREFIX.length())
		if CandySchemas.has_schema(type):
			return {
				"id": id,
				"label": CandySchemas.get_title(type),
				"tooltip": LINE_TOOLTIP,
				"line_type": type,
				"category": CandySchemas.get_category(type),
			}
	return {}


static func get_label(id: String) -> String:
	var definition := get_definition(id)
	return str(definition.get("label", id))


#* A button's label as shown: translated, a command's as the command names setting says:
static func shown_label(id: String) -> String:
	var definition := get_definition(id)
	if definition.has("line_type"):
		return CandyLocale.command_title(str(definition.get("label", id)))
	return CandyLocale.t(str(definition.get("label", id)))

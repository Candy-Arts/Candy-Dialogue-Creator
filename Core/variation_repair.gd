#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationRepair
extends RefCounted

#^ Returned when a file is refused for its variations:
#? The report already says why: callers don't show it as an error.
const REFUSED := "Some variation names in this file must be fixed by hand before it can be loaded. The report lists them."	#/ translatable

var entries: Array = []
var _renames: Array = []   #/ [ [variations array, index, fixed name] ]
var _names: Array = []     #/ Every variation name, fixed
#^ Lowercased -> spelling, the database's first (see repair_name()):
var _known_languages: Dictionary = {}
var _known_tags: Dictionary = {}


#* Check the variation names of conversations:
#? conversations: { conversation: { block: { "Text": [ lines ] } } }
static func check(conversations: Dictionary) -> CandyVariationRepair:
	var repair := CandyVariationRepair.new()
	repair._learn_database()
	for conversation in conversations:
		var blocks = conversations[conversation]
		if not blocks is Dictionary:
			continue
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary or not block_data.get(CandyDialogue.TEXT_KEY) is Array:
				continue
			var text_lines: Array = block_data[CandyDialogue.TEXT_KEY]
			for i in text_lines.size():
				repair._walk(text_lines[i], CandyLocale.t("{conversation} > {block} > line {index}").format(
					{"conversation": conversation, "block": block, "index": i}), true)
	return repair


#* Whether some names can't be fixed (the file mustn't load):
func has_problems() -> bool:
	for entry in entries:
		if not entry["problems"].is_empty():
			return true
	return false


func has_fixes() -> bool:
	for entry in entries:
		if not entry["fixes"].is_empty():
			return true
	return false


#* Rename the variations, and add what they use to the database:
#! Only when has_problems() is false.
func apply() -> void:
	for rename in _renames:
		var list: Array = rename[0]
		var index: int = rename[1]
		var entry: Dictionary = list[index]
		list[index] = {rename[2]: entry.values()[0]}
	if not CandyProfiles.is_profile_open():
		return
	var draft := CandySettingsDraft.new()
	var refused := CandyVariationData.new(draft).add_from_names(_names)
	draft.apply()
	for problem in refused:
		push_warning("CandyVariationRepair: the database refused a repaired name. %s" % problem)


func _learn_database() -> void:
	if not CandyProfiles.is_profile_open():
		return
	var data := CandyVariationData.new(CandySettingsDraft.new())
	for language in data.language_names():
		if not _known_languages.has(language.to_lower()):
			_known_languages[language.to_lower()] = language
	for tag in data.custom_tags():
		if not _known_tags.has(str(tag).to_lower()):
			_known_tags[str(tag).to_lower()] = tag


#* Walk value for Spoken_Lines:
func _walk(value: Variant, where: String, top: bool) -> void:
	if value is Dictionary:
		for key in value:
			var child = value[key]
			var child_where := where
			#? Top - value is the line itself (its type isn't a step of where).
			if not top:
				child_where = "%s > %s" % [where, key]
			if str(key) == "Spoken_Line" and child is Dictionary and child.get("Variations") is Array:
				_check_variations(child["Variations"], child_where)
			_walk(child, child_where, false)
	elif value is Array:
		for item in value:
			_walk(item, where, false)


#* Check one line's variations ([ { "Default": {...} }, ... ]):
func _check_variations(list: Array, where: String) -> void:
	var taken := {}  #/ Fixed name -> the name in the file
	for i in list.size():
		var item = list[i]
		if not item is Dictionary or item.size() != 1:
			continue
		var old_name := str(item.keys()[0])
		var result := CandyVariations.repair_name(old_name, _known_languages, _known_tags)
		var fixed: String = result["name"]
		var problems: Array = result["problems"]
		if problems.is_empty():
			if not taken.has(fixed):
				taken[fixed] = old_name
			elif taken[fixed] == old_name:
				problems.append(CandyLocale.t("Another variation of this line has the same name."))
			else:
				problems.append(CandyLocale.t("Once fixed, it would have the same name as another variation of this line, \"{other}\": \"{fixed}\".").format(
					{"other": taken[fixed], "fixed": fixed}))

		if not result["fixes"].is_empty() or not problems.is_empty():
			entries.append({
				"where": where,
				"variation": old_name,
				"fixed": fixed,
				"fixes": result["fixes"],
				"problems": problems,
			})
		if problems.is_empty():
			_names.append(fixed)
			if fixed != old_name:
				_renames.append([list, i, fixed])

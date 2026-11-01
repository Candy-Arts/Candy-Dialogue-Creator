#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationData
extends RefCounted

const DATA_KEY := "variation_data"
const DEFAULT_LANGUAGE := "Default"
#^ The Variations entry field a language's direction goes into:
const DIRECTION_FIELD := "Direction"
const DEFAULT_DIRECTION := "LtR"
#^ Spoken_Line's Direction values:
const DIRECTIONS := [
	{"value": "LtR",
		"label": "Left to right"},	#/ translatable
	{"value": "RtL",
		"label": "Right to left"},	#/ translatable
]

var draft: CandySettingsDraft


func _init(p_draft: CandySettingsDraft) -> void:
	draft = p_draft


#& Reading

#* Languages, Default first, then alphabetical:
func languages() -> Array:
	var value = draft.get_value(DATA_KEY + "/languages", null)
	var list: Array = []
	if value is Array and not value.is_empty():
		list = value.duplicate(true)
	else:
		list = [{"name": DEFAULT_LANGUAGE, "hidden": false, "direction": DEFAULT_DIRECTION}]
	list.sort_custom(_compare_languages)
	return list


func language_names() -> Array:
	var result: Array = []
	for entry in languages():
		result.append(str(entry.get("name", "")))
	return result


#* Custom tags, alphabetical:
func custom_tags() -> Array:
	var value = draft.get_value(DATA_KEY + "/custom_tags", null)
	var list: Array = []
	if value is Array:
		list = value.duplicate()
	list.sort_custom(_compare_text)
	return list


#* Random tags, numerical (#2 before #10):
func random_tags() -> Array:
	var value = draft.get_value(DATA_KEY + "/random_tags", null)
	if value is Array:
		return CandyVariations.sort_randoms(value)
	return []


func disabled() -> Array:
	var value = draft.get_value(DATA_KEY + "/disabled", null)
	if value is Array:
		return value.duplicate()
	return []


#& Editing
#? The add_ functions return "" on success, or why the value was refused.

#* Add a language:
func add_language(language: String, direction: String = DEFAULT_DIRECTION) -> String:
	var problem := CandyVariations.validate_language(language)
	if problem != "":
		return problem
	if language_names().has(language):
		return CandyLocale.t("\"%s\" is already in the list.") % language

	var list := languages()
	list.append({"name": language, "hidden": false, "direction": direction})
	_store("languages", list)
	return ""


func remove_language(language: String) -> void:
	if language == DEFAULT_LANGUAGE:
		return
	var list := languages()
	for i in list.size():
		if str(list[i].get("name", "")) == language:
			list.remove_at(i)
			break
	_store("languages", list)


func toggle_language_hidden(language: String) -> void:
	if language == DEFAULT_LANGUAGE:
		return
	var list := languages()
	for entry in list:
		if str(entry.get("name", "")) == language:
			entry["hidden"] = not bool(entry.get("hidden", false))
			break
	_store("languages", list)


func is_language_hidden(language: String) -> bool:
	for entry in languages():
		if str(entry.get("name", "")) == language:
			return bool(entry.get("hidden", false))
	return false


#* The Direction new variations in language start with:
func language_direction(language: String) -> String:
	for entry in languages():
		if str(entry.get("name", "")) == language:
			return str(entry.get("direction", DEFAULT_DIRECTION))
	return DEFAULT_DIRECTION


func set_language_direction(language: String, direction: String) -> void:
	var list := languages()
	for entry in list:
		if str(entry.get("name", "")) == language:
			entry["direction"] = direction
			break
	_store("languages", list)


#* Give a new Variations entry its language's direction:
func apply_language_direction(entry: Dictionary, variation_name: String) -> void:
	if not entry.has(DIRECTION_FIELD):
		return
	var language: String = CandyVariations.name_parts(variation_name)["language"]
	entry[DIRECTION_FIELD] = language_direction(language)


func add_custom_tag(tag: String) -> String:
	var problem := CandyVariations.validate_custom_tag(tag)
	if problem != "":
		return problem
	var list := custom_tags()
	if list.has(tag):
		return CandyLocale.t("\"%s\" is already in the list.") % tag
	list.append(tag)
	list.sort_custom(_compare_text)
	_store("custom_tags", list)
	return ""


func add_random_tag(tag: String) -> String:
	var problem := CandyVariations.validate_random_tag(tag)
	if problem != "":
		return problem
	var list := random_tags()
	if list.has(tag):
		return CandyLocale.t("\"%s\" is already in the list.") % tag
	list.append(tag)
	_store("random_tags", CandyVariations.sort_randoms(list))
	return ""


func remove_custom_tag(tag: String) -> void:
	var list := custom_tags()
	list.erase(tag)
	_store("custom_tags", list)


func remove_random_tag(tag: String) -> void:
	var list := random_tags()
	list.erase(tag)
	_store("random_tags", list)


func toggle_disabled(id: String) -> void:
	var list := disabled()
	if list.has(id):
		list.erase(id)
	else:
		list.append(id)
	_store("disabled", list)


#* Add the languages and tags variation_names use that the database lacks:
func add_from_names(variation_names: Array) -> Array:
	var problems: Array = []
	#Ł Check each piece once:
	var checked_languages := {}
	var checked_tags := {}
	for variation_name in variation_names:
		var parts := CandyVariations.name_parts(str(variation_name))
		var language: String = parts["language"]
		if not checked_languages.has(language):
			checked_languages[language] = true
			if not language_names().has(language):
				_note_problem(problems, CandyLocale.t("Language"), language, add_language(language))
		for tag in parts["custom"]:
			if not checked_tags.has(tag):
				checked_tags[tag] = true
				if not custom_tags().has(tag):
					_note_problem(problems, CandyLocale.t("Tag"), tag, add_custom_tag(tag))
		for tag in parts["randoms"]:
			if not checked_tags.has(tag):
				checked_tags[tag] = true
				if not random_tags().has(tag):
					_note_problem(problems, CandyLocale.t("Random tag"), tag, add_random_tag(tag))
	return problems			#/ A message per refused one


func _note_problem(problems: Array, kind: String, text: String, problem: String) -> void:
	if problem != "":
		problems.append(CandyLocale.t("{kind} \"{name}\": {problem}").format({"kind": kind, "name": text, "problem": problem}))


func next_random() -> String:
	return CandyVariations.next_random(random_tags())


func _store(field: String, value: Variant) -> void:
	draft.set_value(DATA_KEY + "/" + field, value)


#* Sort languages, Default first (the fallback language):
static func _compare_languages(a: Dictionary, b: Dictionary) -> bool:
	var name_a := str(a.get("name", ""))
	var name_b := str(b.get("name", ""))
	if name_a == DEFAULT_LANGUAGE:
		return name_b != DEFAULT_LANGUAGE
	if name_b == DEFAULT_LANGUAGE:
		return false
	return name_a.naturalnocasecmp_to(name_b) < 0


static func _compare_text(a: String, b: String) -> bool:
	return a.naturalnocasecmp_to(b) < 0

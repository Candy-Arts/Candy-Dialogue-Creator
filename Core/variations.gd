#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariations

const SEPARATOR := "_"
const RANDOM_PREFIX := "#"
#^ Always the last part of a name:
const TTS_TAG := "TTS"
#^ Caps the combinations:
const MAX_TAG_KEYS := 12
const MAX_LENGTH := 64

#^ Characters no file name may contain on any OS:
#? Names end up in translation file names.
const RESERVED_CHARACTERS := "/\\:*?\"<>|"
const WINDOWS_RESERVED := [
	"CON", "PRN", "AUX", "NUL",
	"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
	"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
]


#& Validation

#* Validate a language name ("" if usable, else why not):
static func validate_language(text: String) -> String:
	return _validate_token(text, false)


#* Validate a custom tag (at most one "=", both sides filled):
static func validate_custom_tag(text: String) -> String:
	var problem := _validate_token(text, true)
	if problem != "":
		return problem
	var parts := text.split("=", true)
	if parts.size() > 2:
		return CandyLocale.t("A tag can hold only one \"=\".")
	if parts.size() == 2 and (parts[0] == "" or parts[1] == ""):
		return CandyLocale.t("Write a tag as key=value, with both parts filled in.")
	#% "Default_TTS" is always the TTS twin:
	if text.to_upper() == TTS_TAG:
		return CandyLocale.t("\"%s\" is reserved: every variation already has a TTS version.") % TTS_TAG
	return ""


#* Validate a random tag ("#" + any number, "#0", "#01"):
static func validate_random_tag(text: String) -> String:
	if text == "":
		return CandyLocale.t("Can't be empty.")
	var regex := RegEx.create_from_string("^#[0-9]+$")
	if regex == null or regex.search(text) == null:
		return CandyLocale.t("A random tag is \"#\" followed by a number, like #1 or #12.")
	if text.length() > MAX_LENGTH:
		return CandyLocale.t("Too long.")
	return ""


static func _validate_token(text: String, allow_equals: bool) -> String:
	if text == "":
		return CandyLocale.t("Can't be empty.")
	if text.length() > MAX_LENGTH:
		return CandyLocale.t("Too long.")
	if text != text.strip_edges():
		return CandyLocale.t("Can't start or end with a space.")
	if text.contains(SEPARATOR):
		return CandyLocale.t("Can't contain \"_\": it separates the parts of a variation name.")
	if text.contains(RANDOM_PREFIX):
		return CandyLocale.t("Can't contain \"#\": that marks a random tag.")
	if not allow_equals and text.contains("="):
		return CandyLocale.t("Can't contain \"=\".")

	for i in text.length():
		var character := text[i]
		if character == " " or character == "\t":
			return CandyLocale.t("Can't contain spaces.")
		if character.unicode_at(0) < 32:
			return CandyLocale.t("Can't contain control characters.")
		if RESERVED_CHARACTERS.contains(character):
			return CandyLocale.t("Can't contain any of  %s") % RESERVED_CHARACTERS

	if text.ends_with("."):
		return CandyLocale.t("Can't end with a dot.")
	if WINDOWS_RESERVED.has(text.to_upper()):
		return CandyLocale.t("\"%s\" is a reserved file name on Windows.") % text
	return ""


#* Sort random tags numerically (#2 before #10):
static func sort_randoms(tags: Array) -> Array:
	var sorted_tags := tags.duplicate()
	sorted_tags.sort_custom(_compare_randoms)
	return sorted_tags


static func _compare_randoms(a: String, b: String) -> bool:
	return random_number(a) < random_number(b)


static func random_number(tag: String) -> int:
	if not tag.begins_with(RANDOM_PREFIX):
		return 0
	return tag.substr(1).to_int()


#* A tag's key ("S=F" -> "S", "Shout" -> "Shout"):
static func tag_key(tag: String) -> String:
	var index := tag.find("=")
	if index < 0:
		return tag
	return tag.substr(0, index)


#* Group tag values by key, keys sorted:
static func group_tags(tags: Array) -> Dictionary:
	var keys: Array = []
	var groups := {}
	for tag in tags:
		var text := str(tag).strip_edges()
		if text == "":
			continue
		var key := tag_key(text)
		if not groups.has(key):
			groups[key] = []
			keys.append(key)
		if not groups[key].has(text):
			groups[key].append(text)

	keys.sort()
	var ordered := {}
	for key in keys:
		var values: Array = groups[key]
		values.sort()
		ordered[key] = values
	return ordered


#* Every custom tag combination (one value per key, at least one tag):
static func combinations(tags: Array) -> Array:
	var groups := group_tags(tags)
	var keys := groups.keys()
	if keys.is_empty():
		return []
	if keys.size() > MAX_TAG_KEYS:
		push_warning("CandyVariations: %d tag keys is too many to combine; using the first %d."
			% [keys.size(), MAX_TAG_KEYS])
		keys = keys.slice(0, MAX_TAG_KEYS)

	var result: Array = []
	#@ Step 1 - Each bit picks a key, then its values multiply out:
	var total := 1 << keys.size()
	for mask in range(1, total):
		var chosen: Array = []
		for i in keys.size():
			if mask & (1 << i):
				chosen.append(keys[i])
		for combination in _product(groups, chosen):
			combination.sort()
			result.append(SEPARATOR.join(combination))

	#@ Step 2 - Sort by tag count, then alphabetically:
	result.sort_custom(_compare_names)
	return result


#* Every combination with each random tag, plus the bare random tags:
static func with_randoms(combinations_list: Array, random_tags: Array) -> Array:
	var result: Array = []
	for random in random_tags:
		var text := str(random).strip_edges()
		if text != "":
			result.append(text)
	for combination in combinations_list:
		for random in random_tags:
			var text := str(random).strip_edges()
			if text != "":
				result.append(str(combination) + SEPARATOR + text)
	return result


#* The tag part of every variation, in display order:
static func ordered_tag_variations(custom_tags: Array, random_tags: Array, disabled: Array) -> Array:
	var result: Array = []
	for combination in combinations(custom_tags):
		#% A disabled combination takes its randoms with it:
		if disabled.has(combination):
			continue
		result.append(combination)
		#Ł Its randoms:
		for random in random_tags:
			var text := str(random).strip_edges()
			if text == "":
				continue
			var variation_name = combination + SEPARATOR + text
			if not disabled.has(variation_name):
				result.append(variation_name)
	#Ł Then the bare randoms:
	for random in random_tags:
		var bare := str(random).strip_edges()
		if bare != "" and not disabled.has(bare):
			result.append(bare)
	return result


#* One language's full variation names, the bare language first:
static func language_variations(language: String, tag_variations: Array, disabled: Array) -> Array:
	var result: Array = []
	if not disabled.has(language):
		result.append(language)
	for tags in tag_variations:
		var variation_name := language + SEPARATOR + str(tags)
		if not disabled.has(variation_name):
			result.append(variation_name)
	return result


#* The random variations of base ("French_S=F" -> "French_S=F_#1"...), less the disabled:
static func random_variations(base: String, random_tags: Array, disabled: Array) -> Array:
	var result: Array = []
	var parts := base.split(SEPARATOR)
	var language := parts[0]
	parts.remove_at(0)
	var tags := SEPARATOR.join(parts)
	#% None when base, its language or its tags are disabled:
	if disabled.has(base) or disabled.has(language) or (tags != "" and disabled.has(tags)):
		return result
	for random in random_tags:
		var tag := str(random).strip_edges()
		if tag == "":
			continue
		var tag_part := tag
		if tags != "":
			tag_part = tags + SEPARATOR + tag
		var variation_name := base + SEPARATOR + tag
		#% Disabled by tags or full name:
		if disabled.has(tag_part) or disabled.has(variation_name):
			continue
		result.append(variation_name)
	return result


#* The next unused random tag:
static func next_random(random_tags: Array) -> String:
	var number := 1
	while random_tags.has(RANDOM_PREFIX + str(number)):
		number += 1
	return RANDOM_PREFIX + str(number)


static func is_random(tag: String) -> bool:
	return tag.begins_with(RANDOM_PREFIX)


static func _product(groups: Dictionary, keys: Array) -> Array:
	var result: Array = [[]]
	for key in keys:
		var expanded: Array = []
		for partial in result:
			for value in groups[key]:
				var copy: Array = partial.duplicate()
				copy.append(value)
				expanded.append(copy)
		result = expanded
	return result


#* Sort - fewer tags first, then alphabetical:
static func _compare_names(a: String, b: String) -> bool:
	var count_a := a.count(SEPARATOR)
	var count_b := b.count(SEPARATOR)
	if count_a != count_b:
		return count_a < count_b
	return a < b


#& TTS and random parts of a name

static func is_tts(variation_name: String) -> bool:
	return variation_name.ends_with(SEPARATOR + TTS_TAG)


#* The TTS twin ("Default_S=F" -> "Default_S=F_TTS"):
static func tts_of(variation_name: String) -> String:
	if is_tts(variation_name):
		return variation_name
	return variation_name + SEPARATOR + TTS_TAG


#* Split a name into base, random tag and TTS:
static func split_variation(variation_name: String) -> Dictionary:
	var parts := variation_name.split(SEPARATOR)
	var tts := false
	var random := ""
	#? parts[0] is the language, never a tag.
	if parts.size() > 1 and parts[parts.size() - 1] == TTS_TAG:
		tts = true
		parts.remove_at(parts.size() - 1)
	if parts.size() > 1 and is_random(parts[parts.size() - 1]):
		random = parts[parts.size() - 1]
		parts.remove_at(parts.size() - 1)
	return {"base": SEPARATOR.join(parts), "random": random, "tts": tts}		#/ "English_S=F_#2_TTS" -> "English_S=F", "#2", true


#* A name's parts, in any order (the first is the language):
static func name_parts(variation_name: String) -> Dictionary:
	var parts := variation_name.split(SEPARATOR)
	var custom: Array = []
	var randoms: Array = []
	var tts := 0
	for i in range(1, parts.size()):
		var part := parts[i]
		if part == TTS_TAG:
			tts += 1
		elif is_random(part):
			randoms.append(part)
		else:
			custom.append(part)
	#? Same order as combinations().
	custom.sort()
	return {"language": parts[0], "custom": custom, "randoms": randoms, "tts": tts}		#/ "tts": a count


static func compose_variation(base: String, random: String, tts: bool) -> String:
	var result := base
	if random != "":
		result += SEPARATOR + random
	if tts:
		result += SEPARATOR + TTS_TAG
	return result


#& Repairing names

#* Repair a variation name read from a file:
#? known_languages / known_tags: lowercased -> spelling; new spellings are added.
#! The name is only usable when "problems" is empty.
static func repair_name(variation_name: String, known_languages: Dictionary, known_tags: Dictionary) -> Dictionary:
	var fixes: Array = []
	var problems: Array = []

	var parts: Array = []
	for part in variation_name.split(SEPARATOR):
		var text := _trim_spaces(part)
		if text == "":
			_add_fix(fixes, CandyLocale.t("An empty part: a doubled \"_\", or one at the start or end."), CandyLocale.t("Removed."))
			continue
		if text != part:
			_add_fix(fixes, CandyLocale.t("Spaces at the start or end of \"%s\".") % part, CandyLocale.t("Removed."))
		parts.append(text)
	if parts.is_empty():
		problems.append(CandyLocale.t("The name is empty."))
		return {"name": variation_name, "fixes": fixes, "problems": problems}

	#? File order, to tell whether the order needs fixing.
	var kept: Array = []
	var language := ""
	var first: String = parts[0]
	if first.to_upper() == TTS_TAG or is_random(first):
		problems.append(CandyLocale.t("The name must start with its language, but \"%s\" is a tag.") % first)
	elif first.contains("=") or first.contains(":"):
		problems.append(CandyLocale.t("The name must start with its language, but \"%s\" holds \"=\" or \":\", which only tags can.") % first)
	else:
		parts.remove_at(0)
		language = _repair_part(first, false, known_languages, fixes)
		var language_problem := validate_language(language)
		if language_problem != "":
			problems.append(CandyLocale.t("Language \"{name}\": {problem}").format({"name": language, "problem": language_problem}))
		kept.append(language)

	var custom: Array = []
	var randoms: Array = []
	var tts := false
	for part in parts:
		var text: String = part
		if text.to_upper() == TTS_TAG:
			if text != TTS_TAG:
				_add_fix(fixes, CandyLocale.t("\"%s\": the TTS tag in other capitals.") % text, CandyLocale.t("Written \"%s\".") % TTS_TAG)
			if tts:
				_add_fix(fixes, CandyLocale.t("\"%s\" appears more than once.") % TTS_TAG, CandyLocale.t("Kept once."))
				continue
			tts = true
			kept.append(TTS_TAG)
		elif is_random(text):
			var random_problem := validate_random_tag(text)
			if random_problem != "":
				problems.append(CandyLocale.t("Random tag \"{name}\": {problem}").format({"name": text, "problem": random_problem}))
			if randoms.has(text):
				_add_fix(fixes, CandyLocale.t("\"%s\" appears more than once.") % text, CandyLocale.t("Kept once."))
				continue
			randoms.append(text)
			kept.append(text)
		else:
			var tag := _repair_part(text, true, known_tags, fixes)
			var tag_problem := validate_custom_tag(tag)
			if tag_problem != "":
				problems.append(CandyLocale.t("Tag \"{name}\": {problem}").format({"name": tag, "problem": tag_problem}))
			if custom.has(tag):
				_add_fix(fixes, CandyLocale.t("\"%s\" appears more than once.") % tag, CandyLocale.t("Kept once."))
				continue
			custom.append(tag)
			kept.append(tag)

	if randoms.size() > 1:
		problems.append(CandyLocale.t("More than one random tag: %s. A variation has one at most.") % ", ".join(PackedStringArray(randoms)))
	var values := group_tags(custom)
	for key in values:
		var key_values: Array = values[key]
		if key_values.size() > 1:
			problems.append(CandyLocale.t("More than one value of the tag \"{tag}\": {values}. A variation has one value of each tag at most.").format(
				{"tag": key, "values": ", ".join(PackedStringArray(key_values))}))

	#? Same order as combinations().
	custom.sort()
	var base_parts: Array = [language]
	base_parts.append_array(custom)
	var random := ""
	if randoms.size() == 1:
		random = randoms[0]
	var fixed := compose_variation(SEPARATOR.join(base_parts), random, tts)
	if language != "" and randoms.size() <= 1 and fixed != SEPARATOR.join(kept):
		_add_fix(fixes, CandyLocale.t("The parts are out of order."),
			CandyLocale.t("Put in order: language, custom tags alphabetically, random tag, %s.") % TTS_TAG)
	return {"name": fixed, "fixes": fixes, "problems": problems}		#/ fixes: [{ "problem", "fix" }]


#* Fix a language or custom tag, and match its known spelling:
static func _repair_part(text: String, is_tag: bool, known: Dictionary, fixes: Array) -> String:
	var result := text
	if is_tag and result.contains(":"):
		var replaced := result.replace(":", "=")
		_add_fix(fixes, CandyLocale.t("\":\" in the tag \"%s\".") % result, CandyLocale.t("Replaced with \"=\": \"%s\".") % replaced)
		result = replaced
	#Ł Also trim spaces the dots hid:
	var undotted := _trim_spaces(result.rstrip("."))
	if undotted != result and undotted != "":
		_add_fix(fixes, CandyLocale.t("Dots at the end of \"%s\".") % result, CandyLocale.t("Removed: \"%s\".") % undotted)
		result = undotted
	if is_tag:
		var tight := RegEx.create_from_string("[ \\t]*=[ \\t]*").sub(result, "=", true)
		if tight != result:
			_add_fix(fixes, CandyLocale.t("Spaces around \"=\" in \"%s\".") % result, CandyLocale.t("Removed: \"%s\".") % tight)
			result = tight
	var dashed := RegEx.create_from_string("[ \\t]+").sub(result, "-", true)
	if dashed != result:
		_add_fix(fixes, CandyLocale.t("Spaces in \"%s\".") % result, CandyLocale.t("Replaced with \"-\": \"%s\".") % dashed)
		result = dashed

	#Ł Match the known spelling, or add it (the first one used is kept):
	var lowered := result.to_lower()
	if not known.has(lowered):
		known[lowered] = result
	elif str(known[lowered]) != result:
		_add_fix(fixes, CandyLocale.t("\"{name}\" differs only in capitals from \"{known}\", already in use.").format({"name": result, "known": known[lowered]}),
			CandyLocale.t("Written \"%s\".") % known[lowered])
		result = str(known[lowered])
	return result


#* Trim spaces and tabs only (the rest is left for the checks):
static func _trim_spaces(text: String) -> String:
	return text.lstrip(" \t").rstrip(" \t")


static func _add_fix(fixes: Array, problem: String, fix: String) -> void:
	for entry in fixes:
		if entry["problem"] == problem:
			return
	fixes.append({"problem": problem, "fix": fix})


#* The variation a widget shows for the selected one ("Default_S=F_#1", "#2", true -> "Default_S=F_#2_TTS"):
static func resolve_variation(selected: String, random_tag: String, tts: bool) -> String:
	var parts := split_variation(selected)
	var random: String = parts["random"]
	#? "" keeps the selection's own random tag.
	if random_tag != "":
		random = random_tag
	return compose_variation(parts["base"], random, tts or bool(parts["tts"]))		#/ A TTS selection stays TTS
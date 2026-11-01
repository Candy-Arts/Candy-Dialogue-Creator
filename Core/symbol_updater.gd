#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySymbolUpdater
extends RefCounted

#& Rewrites a 1.2 dialogue from the Candy DE symbols it was written with to others.
#! Candy Wizard's Scripts/Symbol_Updater.gd is a copy: change both together.
#? Symbols are keyed by their Candy_Properties.gd variable names, as in an export's Meta.
#? Each symbol is rewritten only where Candy DE reads it, following its own parsing:
#? - Every value: a leading expression symbol (doubled: escaped), a leading role symbol.
#? - Expressions: the variable dictionary and role symbols, outside quoted text.
#? - Entry names: a role, at the start or after the last "/" (CS targets).
#? - Spoken text: text variables, word substitutions (and their separator), text events and
#?   lexicon escapes, with their doubled symbols (literal ones).
#? Quoted text in expressions and Comment lines are never changed.

const LEVEL_CHECK := CandyDialogueConverter.LEVEL_CHECK
const LEVEL_NOTE := CandyDialogueConverter.LEVEL_NOTE

#^ Where a file keeps its symbols (an export's under "Meta"):
const SYMBOLS_KEY := "Symbols"

const EXPRESSION := "candy_ref_symbol"
const VARDICT := "vardict_symbol"
const ROLE := "role_symbol"
const SEPARATOR := "separator_symbol"
#^ CandyRef_Shortcuts.gd's tables, kept under their names beside the other symbols:
const SHORTCUTS := "SHORTCUT_SYMBOLS"
const LOOKUPS := "LOOKUP_SYMBOLS"
const KIND_SHORTCUT := "shortcut"
const KIND_LOOKUP := "lookup"
#^ CandyRef's node symbol, fixed:
const NODE_SYMBOL := "$"
#^ Symbol pairs of spoken text, in the order Candy DE reads them - [start, end]:
const TEXT_VAR := ["text_var_start_symbol", "text_var_end_symbol"]
const SUBSTITUTION := ["substitution_start_symbol", "substitution_end_symbol"]
const TEXT_EVENT := ["text_event_start_symbol", "text_event_end_symbol"]
const LEXICON := ["lexicon_escape_start_symbol", "lexicon_escape_end_symbol"]
const PAIRS := [TEXT_VAR, SUBSTITUTION, TEXT_EVENT, LEXICON]

const SPOKEN_LINE := "Spoken_Line"
const COMMENT_LINE := "Comment"
const VARIATIONS_KEY := "Variations"
const SPEECH_KEY := "Text"

const STATUS_UPDATE := "update"
const STATUS_MATCH := "match"
const STATUS_NOT_CURRENT := "not current"
const STATUS_UNREADABLE := "unreadable"

const BACKUP_KIND_FOLDER := "Symbols"
const LOG_FILE := "Symbol Update Log.txt"

var notes: Array = []
#^ Values the update changed:
var changed_values := 0

var _old: Dictionary = {}
var _new: Dictionary = {}
#^ Every symbol an expression can hold, { what it reads: symbol } (reference_symbols()):
var _old_refs: Dictionary = {}
var _new_refs: Dictionary = {}
#^ [old symbol, new symbol, what it reads], longest old symbol first:
var _sigils: Array = []
var _where: PackedStringArray = []
#^ "<where>\n<text>" of each note, so a value is noted once per problem:
var _noted: Dictionary = {}


func _init(old_symbols: Dictionary, new_symbols: Dictionary) -> void:
	_old = old_symbols.duplicate()
	_new = new_symbols.duplicate()
	_old_refs = reference_symbols(_old)
	_new_refs = reference_symbols(_new)
	for identity in _old_refs:
		#? One the new symbols lack keeps its old symbol (and is reported where it's used).
		_sigils.append([str(_old_refs[identity]), str(_new_refs.get(identity, _old_refs[identity])), identity])
	_sigils.sort_custom(func(a, b): return str(a[0]).length() > str(b[0]).length())


#& Symbols

#* Candy_Properties.gd variable of every symbol, in Settings > Project > Symbols order:
static func variables() -> Array:
	var result: Array = []
	for symbol in CandySymbolsPage.SYMBOLS:
		result.append(str(symbol[2]))
	return result


#* A symbol's label ("Role"):
static func label(variable: String) -> String:
	for symbol in CandySymbolsPage.SYMBOLS:
		if str(symbol[2]) == variable:
			return CandyLocale.t(str(symbol[0]))
	return variable


#* The open profile's symbols:
static func profile_symbols() -> Dictionary:
	return CandyDialogueExport.export_symbols()


#* What makes the profile's symbols unusable ("" if nothing):
#? Its CandyRef symbols are checked as listed too: two with the same symbol would make one.
static func profile_problems() -> String:
	var seen := {}
	for entry in CandyDialogueExport.candy_ref_entries():
		var symbol := str(entry.get("symbol", ""))
		if symbol == "":
			return CandyLocale.t("The %s has no symbol.") % entry_label(entry).to_lower()
		if seen.has(symbol):
			return CandyLocale.t("The {first} and the {second} have the same symbol ({symbol}).").format(
				{"first": seen[symbol], "second": entry_label(entry).to_lower(), "symbol": symbol})
		seen[symbol] = entry_label(entry).to_lower()
	return symbol_problems(profile_symbols())


#* Candy DE's own symbols:
static func default_symbols() -> Dictionary:
	var result := {}
	var defaults = CandyProfileDefaults.create("", "", CandyProfiles.VERSION).get(CandySymbolsPage.SYMBOLS_KEY, {})
	if not defaults is Dictionary:
		defaults = {}
	for symbol in CandySymbolsPage.SYMBOLS:
		result[str(symbol[2])] = str(defaults.get(str(symbol[1]), ""))
	result[SHORTCUTS] = {}
	result[LOOKUPS] = {}
	return result


#& CandyRef symbols
#? CandyRef_Shortcuts.gd's SHORTCUT_SYMBOLS ({symbol: target}) and LOOKUP_SYMBOLS
#? ({symbol: {"keys", "entries"}}), kept under those names beside the other symbols.
#? A symbol is known by what it reads (its target), so a changed one is found again.

#* The profile's list ([{ "kind", "symbol", "target" | "keys" + "entries" }]) as the two tables:
static func tables_of(entries: Array) -> Dictionary:
	var shortcuts := {}
	var lookups := {}
	for entry in entries:
		if not entry is Dictionary or str(entry.get("symbol", "")) == "":
			continue
		if str(entry.get("kind", "")) == KIND_LOOKUP:
			lookups[str(entry["symbol"])] = {"keys": str(entry.get("keys", "")), "entries": str(entry.get("entries", ""))}
		else:
			shortcuts[str(entry["symbol"])] = str(entry.get("target", ""))
	return {SHORTCUTS: shortcuts, LOOKUPS: lookups}


#* The two tables as the profile's list:
static func entries_of(tables: Dictionary) -> Array:
	var result: Array = []
	var shortcuts = tables.get(SHORTCUTS, {})
	if shortcuts is Dictionary:
		for symbol in shortcuts:
			result.append({"kind": KIND_SHORTCUT, "symbol": str(symbol), "target": str(shortcuts[symbol])})
	var lookups = tables.get(LOOKUPS, {})
	if lookups is Dictionary:
		for symbol in lookups:
			var lookup = lookups[symbol]
			if lookup is Dictionary:
				result.append({"kind": KIND_LOOKUP, "symbol": str(symbol),
					"keys": str(lookup.get("keys", "")), "entries": str(lookup.get("entries", ""))})
	return result


#* An entry of the profile's list, for the user ("Shortcut to globals.inventory"):
static func entry_label(entry: Dictionary) -> String:
	if str(entry.get("kind", "")) == KIND_LOOKUP:
		return CandyLocale.t("Lookup in {keys}, then {entries}").format({"keys": str(entry.get("keys", "")), "entries": str(entry.get("entries", ""))})
	return CandyLocale.t("Shortcut to %s") % str(entry.get("target", ""))


#* Every symbol an expression can hold, { what it reads: symbol }:
#? The variable dictionary and role symbols, then the CandyRef ones.
static func reference_symbols(symbols: Dictionary) -> Dictionary:
	var result := {}
	for variable in [VARDICT, ROLE]:
		if str(symbols.get(variable, "")) != "":
			result[variable] = str(symbols[variable])
	for entry in entries_of(symbols):
		result[identity_of(entry)] = str(entry["symbol"])
	return result


#* A reference symbol's label, by what it reads:
static func reference_label(identity: String) -> String:
	if identity == VARDICT or identity == ROLE:
		return label(identity)
	if identity.begins_with(KIND_LOOKUP + ":"):
		var parts := identity.substr(KIND_LOOKUP.length() + 1).split("|")
		return entry_label({"kind": KIND_LOOKUP, "keys": parts[0], "entries": parts[parts.size() - 1]})
	return entry_label({"kind": KIND_SHORTCUT, "target": identity.substr(KIND_SHORTCUT.length() + 1)})


#* What an entry of the profile's list reads ("shortcut:globals.inventory"), which a changed symbol keeps:
static func identity_of(entry: Dictionary) -> String:
	if str(entry.get("kind", "")) == KIND_LOOKUP:
		return "%s:%s|%s" % [KIND_LOOKUP, str(entry.get("keys", "")), str(entry.get("entries", ""))]
	return "%s:%s" % [KIND_SHORTCUT, str(entry.get("target", ""))]


#* Read CandyRef_Shortcuts.gd's two tables (absolute path):
#? Returns { SHORTCUTS, LOOKUPS, "problem" } ("" if both were read).
static func read_candy_ref_script(script_path: String) -> Dictionary:
	var result := {SHORTCUTS: {}, LOOKUPS: {}, "problem": ""}
	if not FileAccess.file_exists(script_path):
		result["problem"] = CandyLocale.t("No file at %s") % script_path
		return result
	var text := FileAccess.get_file_as_string(script_path)
	var unread: Array = []
	for table in [SHORTCUTS, LOOKUPS]:
		var literal := CandyProjectScripts.extract_expression(text, table)
		#% No such table - Candy DE reads it as empty:
		if literal == "":
			continue
		var value = str_to_var(literal)
		#% Single quotes and the like - read as an expression (literals only, nothing runs on an object):
		if not value is Dictionary:
			var expression := Expression.new()
			if expression.parse(literal) == OK:
				value = expression.execute([], null, false)
		if value is Dictionary:
			result[table] = value
		else:
			unread.append(table)
	if unread.size() == 1:
		result["problem"] = CandyLocale.t("Couldn't read %s.") % unread[0]
	elif unread.size() > 1:
		result["problem"] = CandyLocale.t("Couldn't read {first} or {second}.").format({"first": unread[0], "second": unread[1]})
	return result


#& The project's symbols

#* The symbols of the project's scripts, read as Settings > Project > Symbols reads them:
#? Returns { "symbols": the profile's, with what the scripts hold in place of theirs,
#? "read": whether a script was read }. A missing or unreadable script leaves the profile's.
static func project_symbols() -> Dictionary:
	var symbols := profile_symbols()
	var read := false
	var root := str(CandyProfiles.get_setting(CandySymbolsPage.ROOT_KEY, "")).strip_edges()
	var properties := _project_file(str(CandyProfiles.get_setting(CandySymbolsPage.SCRIPT_KEY, "")), root)
	if properties != "" and FileAccess.file_exists(properties):
		for symbol in CandySymbolsPage.SYMBOLS:
			var value := CandyProjectScripts.read_string(properties, str(symbol[2]))
			if value != "":
				symbols[str(symbol[2])] = value
				read = true
	var candy_ref := _project_file(str(CandyProfiles.get_setting(CandySymbolsPage.CANDY_REF_SCRIPT_KEY, "")), root)
	if candy_ref != "" and FileAccess.file_exists(candy_ref):
		var tables := read_candy_ref_script(candy_ref)
		if str(tables["problem"]) == "":
			symbols[SHORTCUTS] = tables[SHORTCUTS]
			symbols[LOOKUPS] = tables[LOOKUPS]
			read = true
	return {"symbols": symbols, "read": read}


#* A script setting's absolute path ("" if it can't be known):
static func _project_file(value: String, root: String) -> String:
	var path := value.strip_edges()
	if path == "" or path.is_absolute_path():
		return path
	if root == "":
		return ""
	return root.path_join(path)


#* Make symbols the profile's (Settings > Project > Symbols):
static func set_profile_symbols(symbols: Dictionary) -> void:
	var stored = CandyProfiles.get_setting(CandySymbolsPage.SYMBOLS_KEY, {})
	if stored is Dictionary:
		stored = stored.duplicate()
	else:
		stored = {}
	for symbol in CandySymbolsPage.SYMBOLS:
		stored[str(symbol[1])] = str(symbols.get(str(symbol[2]), ""))
	CandyProfiles.set_setting(CandySymbolsPage.SYMBOLS_KEY, stored, false)
	CandyProfiles.set_setting(CandySymbolsPage.CANDY_REF_KEY, entries_of(symbols))


#& Comparing

#* Whether two sets of symbols are the same:
static func same_symbols(a: Dictionary, b: Dictionary) -> bool:
	for variable in variables():
		if str(a.get(variable, "")) != str(b.get(variable, "")):
			return false
	var a_refs := reference_symbols(a)
	var b_refs := reference_symbols(b)
	if a_refs.size() != b_refs.size():
		return false
	for identity in a_refs:
		if str(b_refs.get(identity, "")) != str(a_refs[identity]):
			return false
	return true


#* What makes a set of symbols unusable ("" if nothing):
#? Spoken text's pairs must differ from each other (a pair's start and end may be the same).
#? Expression symbols ($, the CandyRef ones) must differ from each other and from the expression symbol.
static func symbol_problems(symbols: Dictionary) -> String:
	for variable in variables():
		if str(symbols.get(variable, "")) == "":
			return CandyLocale.t("The %s symbol is empty.") % label(variable)
	var owners := {}
	for group in [[EXPRESSION], [VARDICT], [ROLE], [SEPARATOR]] + PAIRS:
		var seen: Array = []
		for variable in group:
			var symbol := str(symbols.get(variable, ""))
			if symbol in seen:
				continue
			seen.append(symbol)
			if owners.has(symbol):
				return CandyLocale.t("The {first} and {second} symbols are the same ({symbol}).").format(
					{"first": label(owners[symbol]), "second": label(variable), "symbol": symbol})
			owners[symbol] = variable

	var taken := {str(symbols.get(EXPRESSION, "")): label(EXPRESSION), NODE_SYMBOL: CandyLocale.t("node symbol")}
	var references := reference_symbols(symbols)
	for identity in references:
		var symbol := str(references[identity])
		var what := reference_label(identity).to_lower()
		if taken.has(symbol):
			return CandyLocale.t("The {first} and the {second} use the same symbol ({symbol}).").format(
				{"first": taken[symbol], "second": what, "symbol": symbol})
		taken[symbol] = what
	return ""


#* The changed symbols, one per line ("Role: ° → @"):
static func describe_changes(old_symbols: Dictionary, new_symbols: Dictionary) -> String:
	var lines := PackedStringArray()
	for variable in variables():
		var old_symbol := str(old_symbols.get(variable, ""))
		var new_symbol := str(new_symbols.get(variable, ""))
		if old_symbol != new_symbol:
			lines.append("%s: %s → %s" % [label(variable), old_symbol, new_symbol])
	var old_refs := reference_symbols(old_symbols)
	var new_refs := reference_symbols(new_symbols)
	for identity in old_refs:
		if identity == VARDICT or identity == ROLE:
			continue
		if not new_refs.has(identity):
			lines.append(CandyLocale.t("{symbol}: {old} → none").format({"symbol": reference_label(identity), "old": old_refs[identity]}))
		elif str(new_refs[identity]) != str(old_refs[identity]):
			lines.append("%s: %s → %s" % [reference_label(identity), old_refs[identity], new_refs[identity]])
	for identity in new_refs:
		if not old_refs.has(identity):
			lines.append(CandyLocale.t("{symbol}: none → {new}").format({"symbol": reference_label(identity), "new": new_refs[identity]}))
	return "\n".join(lines)


#* Symbols a file says it was written with ({} if it doesn't say):
#? data: the parsed file. Missing symbols are filled in from fallback.
static func stored_symbols(data: Dictionary, fallback: Dictionary = {}) -> Dictionary:
	var stored = data.get(SYMBOLS_KEY)
	var meta = data.get("Meta")
	if meta is Dictionary and meta.get(SYMBOLS_KEY) is Dictionary:
		stored = meta[SYMBOLS_KEY]
	if not stored is Dictionary:
		return {}
	var result := {}
	for variable in variables():
		var value = stored.get(variable)
		if value is String:
			result[variable] = value
		else:
			result[variable] = str(fallback.get(variable, ""))
	for table in [SHORTCUTS, LOOKUPS]:
		var value = stored.get(table)
		if not value is Dictionary:
			value = fallback.get(table, {})
		if value is Dictionary:
			result[table] = value.duplicate(true)
		else:
			result[table] = {}
	return result


#& Dialogue

#* Update conversations into a copy:
#? conversations: { conversation: { block: { "Text": [ lines ] } } }.
func update_conversations(conversations: Dictionary) -> Dictionary:
	var result := {}
	for conversation in conversations:
		var blocks = conversations[conversation]
		if not blocks is Dictionary:
			result[conversation] = _copy(blocks)
			continue
		var new_blocks := {}
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary or not block_data.get(CandyDialogue.TEXT_KEY) is Array:
				new_blocks[block] = _copy(block_data)
				continue
			var new_block: Dictionary = block_data.duplicate(true)
			var lines: Array = block_data[CandyDialogue.TEXT_KEY]
			var new_lines: Array = []
			for i in lines.size():
				_where = PackedStringArray([CandyLocale.t("{conversation} > {block} > line {index}").format(
					{"conversation": conversation, "block": block, "index": i})])
				new_lines.append(_line(lines[i]))
			new_block[CandyDialogue.TEXT_KEY] = new_lines
			new_blocks[block] = new_block
		result[conversation] = new_blocks
	_where = PackedStringArray()
	return result


#* Update one line into a copy:
func update_line(line: Variant) -> Variant:
	_where = PackedStringArray([CandyLocale.t("Clipboard")])
	var result = _line(line)
	_where = PackedStringArray()
	return result


func add_note(text: String, level: String = LEVEL_CHECK) -> void:
	var where := " > ".join(_where)
	var key := where + "\n" + text
	if _noted.has(key):
		return
	_noted[key] = true
	notes.append({"where": where, "text": text, "level": level})


func _line(line: Variant) -> Variant:
	#% Comments are for writers: Candy DE never reads them:
	if line is Dictionary and line.has(COMMENT_LINE):
		return _copy(line)
	return _walk(line, "")


func _walk(value: Variant, parent_key: String) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			var child = value[key]
			#% Candy DC's own data:
			if str(key) == CandyDialogue.META_KEY:
				result[key] = _copy(child)
				continue
			_where.append(str(key))
			var new_key: Variant = key
			if key is String:
				new_key = _entry_name(key)
				if new_key != key and value.has(new_key):
					add_note(CandyLocale.t("Renaming this entry for the new role symbol (%s) would give it the name of another entry: it kept its name.") % new_key)
					new_key = key
				_counted(key, new_key)
			var new_child: Variant = null
			if parent_key == SPOKEN_LINE and str(key) == VARIATIONS_KEY and child is Array:
				new_child = _variations(child)
			else:
				new_child = _walk(child, str(key))
			_where.remove_at(_where.size() - 1)
			result[new_key] = new_child
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_walk(item, ""))
		return result
	if value is String:
		return _counted(value, _value(value))
	return value


#* A Spoken_Line's variations ([ { "Default": { "Text": ... } }, ... ]):
func _variations(list: Array) -> Array:
	var result: Array = []
	for item in list:
		if not item is Dictionary or item.size() != 1 or not item.values()[0] is Dictionary:
			result.append(_walk(item, ""))
			continue
		var variation_name: Variant = item.keys()[0]
		var content: Dictionary = item[variation_name]
		_where.append(str(variation_name))
		var new_content := {}
		for key in content:
			var child = content[key]
			if str(key) == SPEECH_KEY and child is String:
				_where.append(str(key))
				new_content[key] = _counted(child, _speech(child))
				_where.remove_at(_where.size() - 1)
			elif str(key) == CandyDialogue.META_KEY:
				new_content[key] = _copy(child)
			else:
				_where.append(str(key))
				new_content[key] = _walk(child, str(key))
				_where.remove_at(_where.size() - 1)
		_where.remove_at(_where.size() - 1)
		result.append({variation_name: new_content})
	return result


func _counted(before: String, after: String) -> String:
	if before != after:
		changed_values += 1
	return after


func _copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


#& Symbols

func _o(variable: String) -> String:
	return str(_old.get(variable, ""))


func _n(variable: String) -> String:
	return str(_new.get(variable, ""))


func _changed(variable: String) -> bool:
	return _o(variable) != _n(variable)


#* A value - an expression, a role, or text:
func _value(text: String) -> String:
	var expression := _o(EXPRESSION)
	if expression != "" and text.begins_with(expression):
		var body := text.substr(expression.length())
		#% "¢¢…" is the text "¢…":
		if body.begins_with(expression):
			return _escape_expression(body, false)
		return _n(EXPRESSION) + _expression(body)

	var result := text
	var role := _o(ROLE)
	if role != "" and text.begins_with(role):
		result = _n(ROLE) + text.substr(role.length())
	elif _changed(ROLE) and text.begins_with(_n(ROLE)):
		add_note(CandyLocale.t("Starts with the new role symbol (%s), so Candy DE will read it as a role.") % _n(ROLE))
	return _escape_expression(result, true)


#* Text starting with the new expression symbol gets it doubled, so it stays text:
func _escape_expression(text: String, note: bool) -> String:
	var expression := _n(EXPRESSION)
	if expression == "" or not text.begins_with(expression):
		return text
	if note:
		add_note(CandyLocale.t("Starts with the new expression symbol (%s): it was doubled, so Candy DE still reads it as text, not an expression.") % expression, LEVEL_NOTE)
	return expression + text


#* An expression's body (no expression symbol) - its symbols, outside quoted text:
func _expression(body: String) -> String:
	var result := ""
	var i := 0
	var n := body.length()
	while i < n:
		var c := body[i]
		#¦ 1. Quoted text ("…", '…', &"…", ^"…"), kept as written:
		var quote_at := -1
		if c == "\"" or c == "'":
			quote_at = i
		elif (c == "&" or c == "^") and i + 1 < n and (body[i + 1] == "\"" or body[i + 1] == "'"):
			quote_at = i + 1
		if quote_at != -1:
			var end := _quote_end(body, quote_at)
			var quoted := body.substr(i, end - i)
			_check_quoted(quoted)
			result += quoted
			i = end
			continue

		#¦ 2. A symbol:
		var matched := false
		for sigil in _sigils:
			var old_symbol: String = sigil[0]
			if body.substr(i, old_symbol.length()) == old_symbol:
				if not _new_refs.has(sigil[2]):
					add_note(CandyLocale.t("Uses {symbol} ({reads}), which the profile doesn't have anymore: it was left as it is.").format(
						{"symbol": old_symbol, "reads": reference_label(sigil[2]).to_lower()}))
				result += str(sigil[1])
				i += old_symbol.length()
				matched = true
				break
		if matched:
			continue

		#¦ 3. Anything else:
		result += c
		i += 1
	return result


#* Index after the quote closing the one at start:
func _quote_end(text: String, start: int) -> int:
	var quote := text[start]
	var i := start + 1
	while i < text.length():
		var c := text[i]
		if c == "\\":
			i += 2
			continue
		if c == quote:
			return i + 1
		i += 1
	return text.length()


func _check_quoted(quoted: String) -> void:
	for variable in variables():
		if _changed(variable) and _o(variable) != "" and quoted.contains(_o(variable)):
			add_note(CandyLocale.t("Quoted text in an expression holds the old {name} symbol ({symbol}). Quoted text is never updated: check whether it should be.").format(
				{"name": label(variable).to_lower(), "symbol": _o(variable)}))
			return
	for sigil in _sigils:
		if sigil[0] != sigil[1] and quoted.contains(str(sigil[0])):
			add_note(CandyLocale.t("Quoted text in an expression holds the old symbol {symbol} ({reads}). Quoted text is never updated: check whether it should be.").format(
				{"symbol": sigil[0], "reads": reference_label(sigil[2]).to_lower()}))
			return


#* An entry name - a role, at the start or after the last "/":
func _entry_name(key: String) -> String:
	var role := _o(ROLE)
	if role == "" or not _changed(ROLE):
		return key
	var slash := key.rfind("/")
	var head := key.substr(0, slash + 1)
	var tail := key.substr(slash + 1)
	if tail.begins_with(role):
		return head + _n(ROLE) + tail.substr(role.length())
	return key


#* A text variable's content, or a part of a word substitution, as Candy DE reads them:
func _inline(part: String) -> String:
	var core := part.strip_edges()
	if core == "":
		return part
	var lead := part.length() - part.strip_edges(true, false).length()
	var trail := part.length() - part.strip_edges(false, true).length()
	return part.substr(0, lead) + _inline_core(core) + part.substr(part.length() - trail)


func _inline_core(core: String) -> String:
	#¦ 1. Expression:
	var expression := _o(EXPRESSION)
	if expression != "" and core.begins_with(expression):
		return _value(core)

	#¦ 2. Role, variable or CandyRef symbol (°npc1, €gold): an expression without the expression symbol:
	for sigil in _sigils:
		if core.begins_with(str(sigil[0])):
			return _expression(core)

	#¦ 3. Text, or an actor with a key path (Alice.Age):
	var result := core
	var split := _path_start(core)
	if split != -1:
		result = core.substr(0, split) + _expression(core.substr(split))
	for identity in _new_refs:
		var symbol := str(_new_refs[identity])
		if symbol != str(_old_refs.get(identity, "")) and result.begins_with(symbol):
			add_note(CandyLocale.t("A text variable or word substitution starts with the new symbol {symbol} ({reads}), so Candy DE will read it as a reference.").format(
				{"symbol": symbol, "reads": reference_label(identity).to_lower()}))
	return _escape_expression(result, true)


#* Index where a key path starts ("." or "["), or -1:
func _path_start(text: String) -> int:
	var bracket := text.find("[")
	var dot := text.find(".")
	if bracket == -1:
		return dot
	if dot == -1:
		return bracket
	return mini(bracket, dot)


#& Spoken text

#* A spoken text - evaluated first if it's an expression, then read as written text:
func _speech(text: String) -> String:
	var expression := _o(EXPRESSION)
	if expression != "" and text.begins_with(expression):
		var body := text.substr(expression.length())
		if not body.begins_with(expression):
			return _n(EXPRESSION) + _expression(body)
		#% "¢¢…" is the text "¢…":
		return _escape_expression(_speech_text(body), false)
	return _escape_expression(_speech_text(text), true)


#* Written text, read in Candy DE's order:
#? Units: a String is one character of text, an Array ([text]) a finished piece, which the
#? next steps skip but tokens can hold.
func _speech_text(text: String) -> String:
	var units: Array = []
	for i in text.length():
		units.append(text[i])
	units = _pair_tokens(units, TEXT_VAR, true)
	units = _pair_tokens(units, SUBSTITUTION, false)
	units = _pair_tokens(units, TEXT_EVENT, false)
	units = _lexicon_escapes(units)

	var result := ""
	var run := ""
	for unit in units:
		if unit is String:
			run += unit
			continue
		result += _escape_text(run) + str(unit[0])
		run = ""
	return result + _escape_text(run)


#* Text variables, word substitutions or text events - their tokens and doubled symbols:
#? expression_tokens: a token ends at the first end symbol outside quotes and brackets.
func _pair_tokens(units: Array, pair: Array, expression_tokens: bool) -> Array:
	var start_symbol := _o(pair[0])
	var end_symbol := _o(pair[1])
	if start_symbol == "" or end_symbol == "":
		return units
	var changed := _changed(pair[0]) or _changed(pair[1])
	var result: Array = []
	var i := 0
	while i < units.size():
		#¦ 1. Doubled start symbol, a literal one:
		if _match(units, i, start_symbol + start_symbol):
			_add_literal(result, start_symbol, changed)
			i += start_symbol.length() * 2
			continue

		#¦ 2. Doubled end symbol, a literal one:
		if end_symbol != start_symbol and _match(units, i, end_symbol + end_symbol):
			_add_literal(result, end_symbol, changed)
			i += end_symbol.length() * 2
			continue

		#¦ 3. A token:
		if _match(units, i, start_symbol):
			var inner_start := i + start_symbol.length()
			var end_at := _token_end(units, inner_start, end_symbol, expression_tokens)
			if end_at != -1:
				var inner := units.slice(inner_start, end_at)
				result.append([_n(pair[0]) + _token_content(pair, inner) + _n(pair[1])])
				i = end_at + end_symbol.length()
				continue

		result.append(units[i])
		i += 1
	return result


#* A doubled symbol's literal one - text if its symbols change (doubled again if needed), else as written:
func _add_literal(result: Array, symbol: String, changed: bool) -> void:
	if not changed:
		result.append([symbol + symbol])
		return
	for i in symbol.length():
		result.append(symbol[i])


func _match(units: Array, at: int, symbol: String) -> bool:
	if at + symbol.length() > units.size():
		return false
	for i in symbol.length():
		var unit = units[at + i]
		if not unit is String or unit != symbol[i]:
			return false
	return true


#* Index of the end symbol closing a token, or -1:
func _token_end(units: Array, from: int, end_symbol: String, expression_tokens: bool) -> int:
	var depth := 0
	var quote := ""
	var i := from
	while i < units.size():
		var unit = units[i]
		if not unit is String:
			i += 1
			continue
		if expression_tokens:
			if quote != "":
				if unit == "\\":
					i += 2
					continue
				if unit == quote:
					quote = ""
				i += 1
				continue
			if depth == 0 and _match(units, i, end_symbol):
				return i
			if unit == "\"" or unit == "'":
				quote = unit
			elif unit == "(" or unit == "[" or unit == "{":
				depth += 1
			elif (unit == ")" or unit == "]" or unit == "}") and depth > 0:
				depth -= 1
			i += 1
			continue
		if _match(units, i, end_symbol):
			return i
		i += 1
	return -1


#* A token's content:
func _token_content(pair: Array, inner: Array) -> String:
	if pair == TEXT_VAR:
		return _inline(_joined(inner))
	if pair == SUBSTITUTION:
		return _substitution(inner)
	return _joined(inner)


#* A word substitution's parts (word¦actor¦category), each read like a text variable:
func _substitution(inner: Array) -> String:
	var separator := _o(SEPARATOR)
	var parts: Array = [[]]
	var i := 0
	while i < inner.size():
		if separator != "" and _match(inner, i, separator):
			parts.append([])
			i += separator.length()
			continue
		parts.back().append(inner[i])
		i += 1
	var texts := PackedStringArray()
	for part in parts:
		var text := _joined(part)
		if _is_text(part):
			text = _inline(text)
		if _changed(SEPARATOR) and text.contains(_n(SEPARATOR)):
			add_note(CandyLocale.t("A word substitution holds the new separator symbol (%s), so Candy DE will split it there.") % _n(SEPARATOR))
		texts.append(text)
	return _n(SEPARATOR).join(texts)


func _joined(units: Array) -> String:
	var result := ""
	for unit in units:
		if unit is String:
			result += unit
		else:
			result += str(unit[0])
	return result


func _is_text(units: Array) -> bool:
	for unit in units:
		if not unit is String:
			return false
	return true


#* Lexicon escapes - each symbol opens or closes one, doubled ones are literal:
func _lexicon_escapes(units: Array) -> Array:
	var start_symbol := _o(LEXICON[0])
	var end_symbol := _o(LEXICON[1])
	if start_symbol == "" or end_symbol == "":
		return units
	var changed := _changed(LEXICON[0]) or _changed(LEXICON[1])
	var result: Array = []
	var inside := false
	var i := 0
	while i < units.size():
		if _match(units, i, start_symbol + start_symbol):
			_add_literal(result, start_symbol, changed)
			i += start_symbol.length() * 2
			continue
		if end_symbol != start_symbol and _match(units, i, end_symbol + end_symbol):
			_add_literal(result, end_symbol, changed)
			i += end_symbol.length() * 2
			continue
		#? The end first: identical symbols take turns.
		if inside and _match(units, i, end_symbol):
			result.append([_n(LEXICON[1])])
			inside = false
			i += end_symbol.length()
			continue
		if not inside and _match(units, i, start_symbol):
			result.append([_n(LEXICON[0])])
			inside = true
			i += start_symbol.length()
			continue
		result.append(units[i])
		i += 1
	return result


#* Text - doubles the new symbols of the pairs that changed, so they're displayed:
func _escape_text(text: String) -> String:
	if text == "":
		return text
	for pair in PAIRS:
		if not (_changed(pair[0]) or _changed(pair[1])):
			continue
		var start_symbol := _n(pair[0])
		var end_symbol := _n(pair[1])
		if start_symbol != "":
			text = text.replace(start_symbol, start_symbol + start_symbol)
		if end_symbol != "" and end_symbol != start_symbol:
			text = text.replace(end_symbol, end_symbol + end_symbol)
	return text


#& Files

#* Inspect a file for an update to new_symbols:
#? fallback: the symbols of files that don't store theirs. Adds "symbols" and "stored" to
#? CandyFileConverter.inspect()'s info, and its own "status".
static func inspect(path: String, fallback: Dictionary, new_symbols: Dictionary) -> Dictionary:
	var info := CandyFileConverter.inspect(path)
	info["symbols"] = {}
	info["stored"] = false
	if str(info["kind"]) == "":
		info["status"] = STATUS_UNREADABLE
		return info
	if not str(info["version"]).begins_with("1.2"):
		info["status"] = STATUS_NOT_CURRENT
		info["problem"] = CandyLocale.t("Not in the 1.2 format: convert it with Edit > Dialogue Converter... first.")
		return info
	var stored := stored_symbols(info["data"], fallback)
	info["stored"] = not stored.is_empty()
	if stored.is_empty():
		stored = fallback.duplicate()
	info["symbols"] = stored
	if same_symbols(stored, new_symbols):
		info["status"] = STATUS_MATCH
		info["problem"] = CandyLocale.t("Its symbols already match the profile's.")
	else:
		info["status"] = STATUS_UPDATE
		info["problem"] = ""
	return info


#* Describe a file for a file list, e.g. "Save, symbols stored":
static func describe(info: Dictionary) -> String:
	var kind := str(info.get("kind", ""))
	if kind == "":
		return CandyLocale.t("Not readable")
	if str(info.get("status", "")) == STATUS_NOT_CURRENT:
		return CandyLocale.t("%s, not 1.2") % CandyFileConverter.kind_label(kind)
	if info.get("stored", false):
		return CandyLocale.t("%s, symbols stored") % CandyFileConverter.kind_label(kind)
	return CandyLocale.t("%s, no symbols stored") % CandyFileConverter.kind_label(kind)


#* Update each file in place, after backing it up:
static func update_files(paths: Array, fallback: Dictionary, new_symbols: Dictionary) -> Array:
	var stamp := CandyFileConverter.make_stamp()
	var results: Array = []
	var backup_folders: Array = []
	for path in paths:
		var result := update_file(str(path), fallback, new_symbols, stamp)
		results.append(result)
		var backup := str(result.get("backup", ""))
		if backup != "" and not (backup.get_base_dir() in backup_folders):
			backup_folders.append(backup.get_base_dir())
	var log_text := "\n".join(report_lines(results)) + "\n"
	for folder in backup_folders:
		CandyFileConverter.write_file(str(folder).path_join(LOG_FILE), log_text)
	return results


#* Update one file in place, after backing it up:
#? Result as CandyFileConverter's, with "changed" (values changed).
static func update_file(path: String, fallback: Dictionary, new_symbols: Dictionary, stamp: String = "") -> Dictionary:
	if stamp == "":
		stamp = CandyFileConverter.make_stamp()
	var info := inspect(path, fallback, new_symbols)
	var result := {"path": path, "kind": info["kind"], "version": info["version"],
		"outcome": CandyFileConverter.OUTCOME_SKIPPED, "message": str(info["problem"]), "backup": "",
		"notes": [], "changed": 0}
	match str(info["status"]):
		STATUS_MATCH:
			return result
		STATUS_NOT_CURRENT, STATUS_UNREADABLE:
			result["outcome"] = CandyFileConverter.OUTCOME_FAILED
			return result

	var old_symbols: Dictionary = info["symbols"]
	var symbols_problem := symbol_problems(new_symbols)
	if symbols_problem != "":
		result["outcome"] = CandyFileConverter.OUTCOME_FAILED
		result["message"] = CandyLocale.t("The profile's symbols can't be used: %s Fix them on Settings > Project > Symbols.") % symbols_problem
		return result
	symbols_problem = symbol_problems(old_symbols)
	if symbols_problem != "":
		result["outcome"] = CandyFileConverter.OUTCOME_FAILED
		result["message"] = CandyLocale.t("The symbols it was written with can't be read: %s") % symbols_problem
		return result

	var data: Dictionary = info["data"]
	var presets_key := ""
	var conversations: Dictionary = {}
	if str(info["kind"]) == CandyFileConverter.KIND_PRESETS:
		presets_key = CandyFileConverter.preset_key(data)
		conversations = {presets_key: data[presets_key]}
	else:
		conversations = data["Dialogue"]

	var updater := CandySymbolUpdater.new(old_symbols, new_symbols)
	var updated := updater.update_conversations(conversations)
	var updater_notes: Array = updater.notes
	if not info["stored"]:
		updater_notes.push_front({"where": CandyLocale.t("The whole file"), "level": LEVEL_NOTE,
			"text": CandyLocale.t("It didn't store its symbols: it was read with the ones given in the Symbol Updater.")})

	var text := ""
	match str(info["kind"]):
		CandyFileConverter.KIND_PRESETS:
			text = CandyFileConverter.presets_text(info["header"], {presets_key: updated[presets_key], SYMBOLS_KEY: new_symbols})
		CandyFileConverter.KIND_SAVE:
			var save: Dictionary = data.duplicate()
			save["Dialogue"] = updated
			save[SYMBOLS_KEY] = new_symbols
			text = CandyVariantFile.stringify(save) + "\n"
		_:
			text = CandyDialogueExport.export_text(updated, new_symbols)

	var backup := CandyFileConverter.backup_path(path, stamp, BACKUP_KIND_FOLDER)
	var problem := CandyFileConverter.write_file(backup, str(info["raw"]))
	if problem != "":
		result["outcome"] = CandyFileConverter.OUTCOME_FAILED
		result["message"] = CandyLocale.t("Couldn't back the file up, so it wasn't updated. %s") % problem
		return result
	result["backup"] = backup
	problem = CandyFileConverter.write_file(path, text)
	if problem != "":
		result["outcome"] = CandyFileConverter.OUTCOME_FAILED
		result["message"] = CandyLocale.t("Couldn't write the updated file. The original is unchanged. %s") % problem
		return result
	result["outcome"] = CandyFileConverter.OUTCOME_CONVERTED
	result["message"] = ""
	result["notes"] = updater_notes
	result["changed"] = updater.changed_values
	return result


#& Report

static func report_title() -> String:
	return CandyLocale.t("Symbol Updater Report")


static func report_intro() -> String:
	return CandyLocale.t("Updated files replace the originals. Each original is backed up in a {folder} folder beside it, with this report as {log}.").format(
		{"folder": "Conversion Backups/%s" % BACKUP_KIND_FOLDER, "log": LOG_FILE})


static func summary_words() -> Dictionary:
	return {
		CandyFileConverter.OUTCOME_CONVERTED: CandyLocale.t("Updated"),
		CandyFileConverter.OUTCOME_SKIPPED: CandyLocale.t("Skipped"),
		CandyFileConverter.OUTCOME_FAILED: CandyLocale.t("Not updated"),
	}


#* Write the whole run as plain text:
static func report_lines(results: Array) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append(CandyLocale.t("Candy Dialogue Creator %s: Symbol Updater") % CandyProfiles.VERSION)
	lines.append(Time.get_datetime_string_from_system(false, true))
	for result in results:
		lines.append("")
		lines.append(str(result["path"]))
		lines.append("    %s" % outcome_text(result))
		if str(result.get("backup", "")) != "":
			lines.append("    " + CandyLocale.t("Backup: %s") % result["backup"])
		for group in CandyFileConverter.grouped_notes(result):
			var mark := CandyLocale.t("Check: %s")
			if str(group["level"]) == LEVEL_NOTE:
				mark = CandyLocale.t("Note: %s")
			lines.append("    " + mark % group["text"])
			for where in group["wheres"]:
				lines.append("        %s" % where)
	return lines


static func outcome_text(result: Dictionary) -> String:
	match str(result["outcome"]):
		CandyFileConverter.OUTCOME_CONVERTED:
			var changed := int(result.get("changed", 0))
			return CandyLocale.tn("Updated ({kind}): {count} value changed.", "Updated ({kind}): {count} values changed.", changed).format(
				{"kind": CandyLocale.t(str(result["kind"])).to_lower(), "count": changed})
		CandyFileConverter.OUTCOME_SKIPPED:
			return CandyLocale.t("Skipped: %s") % result["message"]
	return CandyLocale.t("Not updated: %s") % result["message"]

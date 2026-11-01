#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueConverter
extends RefCounted

const LEVEL_CHECK := "check"
const LEVEL_NOTE := "note"

#^ ui_elements_paths keys Hide moves (V_Show and I_Show skip the barks):
const UI_ELEMENTS := ["dialogue_box_path", "subtitles_path", "chat_path", "barks_path"]
const SHOW_ELEMENTS := ["dialogue_box_path", "subtitles_path", "chat_path"]

#^ 1.1.3 dialogue box portrait nodes, for PortraitPlay:
const PORTRAIT_SPRITE := "sprite"
const PORTRAIT_FOLDER := "folder"
const PORTRAIT_VIDEO := "video"
const PORTRAIT_NODES := [PORTRAIT_SPRITE, PORTRAIT_FOLDER, PORTRAIT_VIDEO]

const TTS_MODES := ["Off", "Simple", "Advanced"]

#^ 1.1 media command -> [1.2 command, default player, kind]:
const MEDIA_COMMANDS := {
	"audio": ["Media_Play", "Sound", "audio"],
	"video": ["Media_Play", "Video", "video"],
	"image": ["Media_Play", "Image", "image"],
	"a_wait": ["Media_Wait", "Sound", "audio"],
	"v_wait": ["Media_Wait", "Video", "video"],
	"i_wait": ["Media_Wait", "Image", "image"],
	"a_pause": ["Media_Pause", "Sound", "audio"],
	"v_pause": ["Media_Pause", "Video", "video"],
	"i_pause": ["Media_Pause", "Image", "image"],
	"a_resume": ["Media_Resume", "Sound", "audio"],
	"v_resume": ["Media_Resume", "Video", "video"],
	"i_resume": ["Media_Resume", "Image", "image"],
	"a_stop": ["Media_Stop", "Sound", "audio"],
	"v_stop": ["Media_Stop", "Video", "video"],
	"i_stop": ["Media_Stop", "Image", "image"],
	"a_volume": ["Media_Volume", "Sound", "audio"],
	"v_volume": ["Media_Volume", "Video", "video"],
	"a_skip": ["Media_Skip", "Sound", "audio"],
	"v_skip": ["Media_Skip", "Video", "video"],
}

#^ Commands that only change name:
const RENAMED := {
	"bg": "BG_Play",
	"bg_effect": "BG_Effect_Play",
	"vn_bust": "VN_Play",
	"vn_bust_wait": "VN_Wait",
	"vn_bust_stop": "VN_Stop",
	"vn_effect": "VN_Effect_Play",
	"cs_anim": "CS_Anim_Play",
	"cs_sprite": "CS_Sprite_Play",
	"effect": "Effect_Play",
	"clear": "UI_Clear",
}

#^ Key a 1.2 command keeps its entries under, by name prefix:
#? Used to merge commands in a condition's Commands.
const ENTRY_KEYS := [
	["Media_", "Players"], ["Effect_", "Players"], ["BG_", "Layers"], ["VN_", "Actors"],
	["CS_Position", "Markers"], ["CS_Look", "Markers"], ["CS_", "Targets"], ["UI_Z", "Nodes"],
]

#^ Flow commands - in 1.1.3 only a line's last command decided where it went:
const FLOW_COMMANDS := ["return", "end", "jump"]

#^ Spoken Line keys converted here; others are carried over:
const SPOKEN_KEYS := ["Reference", "Disposition", "Portrait", "PortraitPlay", "Voice",
	"ForcePortrait", "ForceBubbles", "TTS", "AI", "Variants"]

var notes: Array = []

var _old: Dictionary = {}
var _new: Dictionary = {}
var _project: Dictionary = {}

#^ Where the converted line is, for notes (conversation > block > line > nested commands):
var _where: PackedStringArray = []
var _conversation := ""
var _block := ""
#^ "<conversation>\n<block>" of every block a choice timer's Timeout runs:
var _timeout_blocks: Dictionary = {}
#^ Last BG / VN Loops of each layer / actor in this block, for waits that waited for its end:
var _bg_loops: Dictionary = {}
var _vn_loops: Dictionary = {}


static func default_project() -> Dictionary:
	return {
		"tts": "Simple",
		"ui_elements": UI_ELEMENTS.duplicate(),
		"portrait_node": PORTRAIT_SPRITE,
		"bg_layers": "",
	}


static func default_old_symbols() -> Dictionary:
	return {
		"singleton_symbol": "£",
		"node_symbol": "$",
		"vardict_symbol": "€",
		"super_singleton_symbol": "££",
		"super_node_symbol": "$$",
		"super_vardict_symbol": "€€",
		"role_symbol": "°",
		"text_var_symbol_start": "{)",
		"text_var_symbol_end": "}",
		"substitution_symbol": "•",
		"separator_symbol": "¦",
		"file_var_symbol": "¬",
	}


static func default_new_symbols() -> Dictionary:
	return {
		"expression": "¢",
		"text_var_start": "¤",
		"text_var_end": "¤",
		"substitution_start": "•",
		"substitution_end": "•",
		"text_event_start": "‡",
		"text_event_end": "‡",
		"lexicon_escape_start": "¬",
		"lexicon_escape_end": "¬",
	}


func _init(old_symbols: Dictionary = {}, new_symbols: Dictionary = {}, project: Dictionary = {}) -> void:
	_old = default_old_symbols()
	for key in old_symbols:
		_old[key] = str(old_symbols[key])
	_new = default_new_symbols()
	for key in new_symbols:
		_new[key] = str(new_symbols[key])
	_project = default_project()
	for key in project:
		_project[key] = project[key]


#* Add a note for the user about the current line:
#? LEVEL_CHECK: may not behave as in 1.1.3, needs a look. LEVEL_NOTE: same behavior, written differently.
func add_note(text: String, level: String = LEVEL_CHECK) -> void:
	notes.append({"where": " > ".join(_where), "text": text, "level": level})


#& Dialogue

#* Convert conversations into a copy:
#? conversations: { conversation: { block: { "Text": [ lines ] } } }.
#? check_targets: report missing Jump, Bridge and choice targets (off for presets).
func convert_conversations(conversations: Dictionary, check_targets: bool = true) -> Dictionary:
	_find_timeout_blocks(conversations)
	var result := {}
	#? conversation -> block -> [ new index of each 1.1 line ]:
	var index_maps := {}
	for conversation in conversations:
		var blocks = conversations[conversation]
		if not blocks is Dictionary:
			result[conversation] = blocks
			continue
		var converted_blocks := {}
		index_maps[conversation] = {}
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary:
				converted_blocks[block] = block_data
				continue
			var new_block: Dictionary = block_data.duplicate(true)
			var lines = block_data.get(CandyDialogue.TEXT_KEY, [])
			if lines is Array:
				var index_map: Array = []
				new_block[CandyDialogue.TEXT_KEY] = _convert_block(str(conversation), str(block), lines, index_map)
				if index_map.size() != new_block[CandyDialogue.TEXT_KEY].size():
					index_maps[conversation][block] = index_map
			converted_blocks[block] = new_block
		result[conversation] = converted_blocks

	_fix_targets(result, index_maps, check_targets)
	_where = PackedStringArray()
	return result


func _convert_block(conversation: String, block: String, lines: Array, index_map: Array) -> Array:
	_conversation = conversation
	_block = block
	_bg_loops.clear()
	_vn_loops.clear()
	var result: Array = []
	for i in lines.size():
		index_map.append(result.size())
		_where = PackedStringArray([CandyLocale.t("{conversation} > {block} > line {line}").format({"conversation": conversation, "block": block, "line": i})])
		var line = lines[i]
		if not line is Dictionary:
			result.append(line)
			continue
		var converted := _convert_line(line)
		if converted.size() > 1:
			add_note(CandyLocale.t("This line held %d commands, which Candy DE 1.1.3 ran one after the other. Each is now a line of its own, and the line numbers of Jump, Bridge and choice targets in this block were updated.") % converted.size(), LEVEL_NOTE)
		for new_line in converted:
			result.append(CandySchemas.normalize_line(new_line))
	return result


#* Split a 1.1 line into one line per command:
func _convert_line(line: Dictionary) -> Array:
	var keys: Array = line.keys()
	var result: Array = []
	for i in keys.size():
		var key := str(keys[i])
		var id := _command_id(key)
		if id in FLOW_COMMANDS and i < keys.size() - 1:
			add_note(CandyLocale.t("%s isn't the last command of its 1.1 line, so Candy DE 1.1.3 ignored it: the last command decided what came next. In 1.2 it does what it says.") % _display_name(key))
		for pair in _convert_command(key, line[key]):
			result.append({pair[0]: pair[1]})
	return result


#* Convert a condition's Commands, merging those that become the same 1.2 command:
func _convert_body(body: Dictionary) -> Dictionary:
	var result := {}
	for key in body:
		if _command_id(str(key)) == "return":			#/ Ended only this body in 1.1.3: it and what follows are dropped
			break
		for pair in _convert_command(str(key), body[key]):
			_add_to_body(result, str(pair[0]), pair[1])
	return result


func _add_to_body(body: Dictionary, command: String, data: Variant) -> void:
	if not body.has(command):
		body[command] = data
		return
	var entries_key := _entries_key(command)
	if entries_key == "" or not data is Dictionary or not body[command] is Dictionary:
		add_note(CandyLocale.t("Two commands here become %s, and a condition can only hold it once. Only the last one was kept.") % command)
		body[command] = data
		return
	var entries = body[command].get(entries_key)
	var added = data.get(entries_key)
	if not entries is Dictionary or not added is Dictionary:
		body[command] = data
		return
	for entry in added:
		if entries.has(entry) and command != "UI_Z":
			add_note(CandyLocale.t("Two commands here act on {entry}, which a single {command} can't do: only the last one was kept. Move one of them to a line of its own.").format({"entry": entry, "command": command}))
		entries[entry] = added[entry]
	if command == "Media_Play" or command == "Effect_Play" or command == "Media_Volume":
		add_note(CandyLocale.t("Several commands here became one %s. Candy DE 1.1.3 ran them one after the other; 1.2 starts them together, then waits. If an earlier one waited, move it to a line of its own.") % command, LEVEL_NOTE)


func _entries_key(command: String) -> String:
	if command == "BG_Scene" or command == "VN_Scene":
		return ""
	for pair in ENTRY_KEYS:
		if command.begins_with(str(pair[0])):
			return str(pair[1])
	return ""


#* A 1.1 command key as 1.1.3 matched it (no §, lowercase, no "-"):
func _command_id(key: String) -> String:
	if key == "Spoken Line":
		return "spoken line"
	if not key.begins_with("§"):
		return ""			#/ Not a command
	return key.substr(1).to_lower().replace("-", "")


func _display_name(key: String) -> String:
	return key.trim_prefix("§")


#* Convert one command into [[1.2 command, data], ...]:
func _convert_command(key: String, value: Variant) -> Array:
	var id := _command_id(key)
	if id == "":
		add_note(CandyLocale.t("The key \"%s\" isn't a command, so Candy DE 1.1.3 ignored it. It was left out (the backup still has it).") % key)
		return []			#/ A key 1.1.3 ignored
	var data: Dictionary = {}
	if value is Dictionary:
		data = value.duplicate(true)

	_where.append(_display_name(key))
	var result: Array = []
	if id == "spoken line":
		result = [["Spoken_Line", _spoken_line(data)]]
	elif MEDIA_COMMANDS.has(id):
		result = _media(id, data)
	else:
		result = _convert_other(id, key, data)
	_where.remove_at(_where.size() - 1)
	return result


func _convert_other(id: String, key: String, data: Dictionary) -> Array:
	match id:
		"set":
			return [["Set", _set_command(data)]]
		"flag":
			return [["Flag", _flag(data)]]
		"call":
			return [["Call", _call(data)]]
		"emit":
			return [["Emit", _emit(data)]]
		"await":
			return [["Await", _await(data)]]
		"name":
			return [["Name", _name_command(data)]]
		"role":
			return [["Role", _role(data)]]
		"disposition":
			return [["Disposition", _disposition_command(data)]]
		"export":
			return [["Export", _export(data)]]
		"import":
			return [["Import", _import(data)]]
		"custom":
			return [["Custom", _custom(data)]]
		"comment":
			return [["Comment", data]]
		"if", "elif", "while":
			return [[_capitalized(id), _condition(data, false)]]
		"else":
			return [["Else", _condition(data, false)]]
		"for":
			return [["For", _condition(data, true)]]
		"jump", "bridge":
			return [[_capitalized(id), _r_keys(data, ["Conversation", "Block", "Line"])]]
		"return":
			#? Only top-level Returns reach here (_convert_body() drops the others).
			data["Levels"] = "-1"
			return [["Return", data]]
		"end":
			return [["End", data]]
		"lm":
			return [["LM", data]]
		"input":
			return [["Input", _input(data)]]
		"mouse":
			return [["Mouse", _r_keys(_underscore_keys(data, ["Mouse Mode"]), ["Mouse_Mode"])]]
		"player_advance":
			return [["Player_Advance", data]]
		"choice_list":
			return [["Choice_List", _choice_list(data)]]
		"choice_status":
			return [["Choice_Status", _choice_status(data)]]
		"timer_status":
			return [["Timer_Status", _timer_status(data)]]
		"wait":
			return [["Wait", _wait(data)]]
		"clear":
			return [["UI_Clear", _clear(data)]]
		"hide", "v_show", "i_show":
			return [["UI_Z", _ui_z(id, data)]]
		"effect", "effect_wait", "effect_stop":
			return _effect(id, data)
	if id.begins_with("bg"):
		var converted := _bg(id, data)
		if not converted.is_empty():
			return converted
	if id.begins_with("vn"):
		var converted := _vn(id, data)
		if not converted.is_empty():
			return converted
	if id.begins_with("cs"):
		var converted := _cs(id, data)
		if not converted.is_empty():
			return converted

	var command := key.substr(1).replace(" ", "_")
	add_note(CandyLocale.t("Candy DE 1.1.3 had no {old} command, so this line did nothing. It was kept as {new}.").format({"old": _display_name(key), "new": command}))
	return [[command, data]]


func _capitalized(id: String) -> String:
	return id.substr(0, 1).to_upper() + id.substr(1)


#& Values
#? How 1.1.3 read a key (Upgrade_Map_1.1.3.md, 2.1): R resolved (trimmed, a reference when
#? it starts with a symbol), S super-only, E expression, T target.

#* Value as text (1.2 lines hold only strings):
func _text(value: Variant) -> String:
	if value == null:
		return ""
	if value is String or value is StringName:
		return str(value)
	if value is bool:
		if value:
			return "1"
		return "0"
	if value is float and is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)


#* Value as 1.1.3's int() read it:
func _int(value: Variant) -> int:
	var text := _text(value).strip_edges()
	if text.is_valid_int():
		return text.to_int()
	if text.is_valid_float():
		return int(text.to_float())
	return 0


func _sym(key: String) -> String:
	return str(_old.get(key, ""))


func _starts(text: String, symbol: String) -> bool:
	return symbol != "" and text.begins_with(symbol)


#* R - add the expression symbol to a reference, escape text starting with it:
func _r(value: Variant) -> String:
	var text := _text(value).strip_edges()
	var body = _ref_body(text)
	if body != null:
		return _expr() + str(body)
	return _escape_expression(text)


func _r_keys(data: Dictionary, keys: Array) -> Dictionary:
	for key in keys:
		if data.has(key):
			data[key] = _r(data[key])
	return data


#* Rename 1.1.3 keys with spaces ("Menu Scene" -> "Menu_Scene"):
func _underscore_keys(data: Dictionary, keys: Array) -> Dictionary:
	for key in keys:
		if data.has(key):
			data[str(key).replace(" ", "_")] = data[key]
			data.erase(key)
	return data


#* Actor key (a bare role stays as is):
func _actor(value: Variant) -> String:
	var text := _text(value).strip_edges()
	if _starts(text, _sym("role_symbol")):
		return text
	return _r(text)


#* S - convert only super references, keep anything else as written:
func _super_only(value: Variant) -> String:
	if not (value is String or value is StringName):
		return _text(value)
	var text := str(value)
	var body = _super_body(text.strip_edges())
	if body != null:
		return _expr() + str(body)
	return _escape_expression(text)


#* T - a variable to write to, without the expression symbol:
func _target(value: Variant) -> String:
	var text := _text(value).strip_edges()
	var body = _super_body(text)
	if body != null:
		return _expr() + str(body)			#/ A super reference names it indirectly: stays an expression
	body = _ref_body(text)
	if body != null:
		return str(body)
	return text


func _expr() -> String:
	return str(_new.get("expression", "¢"))


#* Double a leading expression symbol, so 1.1 text stays text:
func _escape_expression(text: String) -> String:
	if _starts(text, _expr()):
		return _expr() + text
	return text


#* A super reference's expression (no expression symbol), or null:
func _super_body(text: String) -> Variant:
	var body = null
	if _starts(text, _sym("super_vardict_symbol")):
		body = _sym("vardict_symbol") + text.substr(_sym("super_vardict_symbol").length())
	elif _starts(text, _sym("super_singleton_symbol")):
		body = _singleton_body(text.substr(_sym("super_singleton_symbol").length()))
	elif _starts(text, _sym("super_node_symbol")):
		body = _node_body(text.substr(_sym("super_node_symbol").length()))
	elif text.begins_with("sv_res://") or text.begins_with("sv_user://"):
		var scheme := "res://"
		if text.begins_with("sv_user://"):
			scheme = "user://"
		var rest := text.substr(3 + scheme.length())
		var rest_body = _ref_body(rest)
		if rest_body != null:
			body = "file_var('%s' + %s)" % [scheme, rest_body]
		else:
			body = "file_var('%s%s')" % [scheme, rest]
	if body != null:
		add_note(CandyLocale.t("\"{text}\" read a reference stored in a variable. In 1.2 a stored reference is only read if it starts with {expression}: convert the value stored there too (\"{expression}€score\", not \"€score\").").format({"text": text, "expression": _expr()}))
	return body


#* A 1.1 reference's expression (no expression symbol), or null if not one:
func _ref_body(text: String) -> Variant:
	var body = _super_body(text)
	if body != null:
		return body
	if text.begins_with("v_res://") or text.begins_with("v_user://"):
		return _file_var_body(text.substr(2))
	if _starts(text, _sym("vardict_symbol")) or _starts(text, _sym("role_symbol")):
		return text
	if _starts(text, _sym("singleton_symbol")):
		return _singleton_body(text.substr(_sym("singleton_symbol").length()))
	if _starts(text, _sym("node_symbol")):
		return _node_body(text.substr(_sym("node_symbol").length()))
	return null


#* £name (an autoload) -> bare name; with a node path, a node under /root/:
func _singleton_body(rest: String) -> String:
	var head := rest
	for separator in [".", "["]:
		var at := head.find(separator)
		if at >= 0:
			head = head.substr(0, at)
	if head.contains("/"):
		return "$/root/" + rest
	return rest


#* 1.1.3 node paths started at /root/; 1.2's $ starts at the engine:
func _node_body(rest: String) -> String:
	if rest.begins_with("/"):
		return "$" + rest
	return "$/root/" + rest


#* "res://data/stats.json¬player.hp" -> "file_var('res://data/stats.json').player.hp":
func _file_var_body(path_and_steps: String) -> String:
	var path := path_and_steps
	var steps := ""
	var separator := _sym("file_var_symbol")
	if separator != "" and path_and_steps.contains(separator):
		var at := path_and_steps.find(separator)
		path = path_and_steps.substr(0, at)
		steps = path_and_steps.substr(at + separator.length())
	var body := "file_var('%s')" % path
	if steps == "":
		return body
	if steps.begins_with("["):
		return body + steps
	return body + "." + steps


#* E - convert an expression:
func _expression(value: Variant, allow_super: bool = true) -> String:
	var text := _text(value).strip_edges()
	if text == "":
		return ""
	if allow_super:			#/ Super-only first (S then E)
		var body = _super_body(text)
		if body != null:
			return _expr() + str(body)
	if _is_quoted(text):
		return _escape_expression(text.substr(1, text.length() - 2))			#/ Quoted text loses its quotes
	if text.is_valid_float() or text == "true" or text == "false":
		return _expr() + text
	return _expr() + _rewrite_refs(text)			#/ Inner references lose their symbols


#* Whether the whole text is one quoted string:
func _is_quoted(text: String) -> bool:
	if text.length() < 2:
		return false
	var quote := text.substr(0, 1)
	if quote != "'" and quote != "\"":
		return false
	return text.ends_with(quote) and not text.substr(1, text.length() - 2).contains(quote)


#* Rewrite every 1.1 reference in an expression, leaving quoted strings alone:
func _rewrite_refs(text: String) -> String:
	var result := ""
	var i := 0
	var quote := ""
	while i < text.length():
		var c := text.substr(i, 1)
		if quote != "":
			result += c
			if c == "\\" and i + 1 < text.length():
				result += text.substr(i + 1, 1)
				i += 2
				continue
			if c == quote:
				quote = ""
			i += 1
			continue
		if c == "'" or c == "\"":
			quote = c
			result += c
			i += 1
			continue
		if i > 0 and _is_name_char(text.substr(i - 1, 1)):
			result += c
			i += 1
			continue

		var rest := text.substr(i)
		var symbol := ""
		for key in ["super_vardict_symbol", "super_singleton_symbol", "super_node_symbol", "singleton_symbol", "node_symbol"]:
			if _starts(rest, _sym(key)):
				symbol = _sym(key)
				break
		if rest.begins_with("v_res://") or rest.begins_with("v_user://"):
			var length := _file_token_length(rest)
			result += _file_var_body(rest.substr(2, length - 2))
			i += length
			continue
		if symbol == "":
			result += c
			i += 1
			continue
		var token_length := _token_length(rest, symbol.length())
		var token := rest.substr(0, token_length)
		var body = _ref_body(token)
		if body == null:
			result += token
		else:
			result += str(body)
		i += token_length
	return result


func _is_name_char(c: String) -> bool:
	return c == "_" or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


#* Length of a reference from its symbol (names, "/" and "." steps, [...] steps):
func _token_length(text: String, start: int) -> int:
	var i := start
	var depth := 0
	while i < text.length():
		var c := text.substr(i, 1)
		if depth > 0:
			if c == "[":
				depth += 1
			elif c == "]":
				depth -= 1
			i += 1
			continue
		if c == "[":
			depth += 1
		elif not (_is_name_char(c) or c == "/" or c == "."):
			break
		i += 1
	return i


#* Length of "v_user://save.json¬gold" in an expression (path, then steps):
func _file_token_length(text: String) -> int:
	var separator := _sym("file_var_symbol")
	var i := 0
	while i < text.length():
		var c := text.substr(i, 1)
		if separator != "" and text.substr(i).begins_with(separator):
			return _token_length(text, i + separator.length())
		if c == " " or c in ["(", ")", "+", "*", ",", "=", "<", ">", "!", "&", "|"]:
			break
		i += 1
	return i


#& Spoken Line

func _spoken_line(data: Dictionary) -> Dictionary:
	var result := {}
	result["Reference"] = _actor(data.get("Reference", ""))
	result["Disposition"] = _disposition(_text(data.get("Disposition", "")))
	result["Portrait"] = _r(data.get("Portrait", ""))
	result["Portrait_Play"] = _portrait_play(data)
	result["Voice"] = _voice(data.get("Voice", ""))
	result["Variations"] = _variations(data.get("Variants", []))
	result["Portrait_Mode"] = _three_way(data.get("ForcePortrait", "0"), "All", "Off")
	result["Dialogue_Mode"] = _dialogue_mode(data.get("ForceBubbles", "0"))
	result["TTS"] = _tts(data.get("TTS", "0"))
	result["LLM"] = _three_way(data.get("AI", "0"), "1", "0")
	for key in data:
		if not (str(key) in SPOKEN_KEYS) and not result.has(key):
			result[key] = data[key]
	return result


#* -1 / 0 / 1 override - 1 -> on_value, -1 -> off_value, else "null":
func _three_way(value: Variant, on_value: String, off_value: String) -> String:
	var number := _int(value)
	if number == 1:
		return on_value
	if number == -1:
		return off_value
	return "null"


#* ForceBubbles -> Dialogue_Mode:
func _dialogue_mode(value: Variant) -> String:
	var number := _int(value)
	if number == 1:
		return "Bubbles"
	if number == -1:
		add_note(CandyLocale.t("ForceBubbles was -1 (never bubbles), which 1.2 doesn't have: Dialogue_Mode is left unset (\"null\"), so the line uses its engine's mode, speech bubbles included. To keep it out of bubbles, set its Dialogue_Mode (Box, say)."))
	return "null"


#* TTS - "1" meant on, in the engine's own mode:
func _tts(value: Variant) -> String:
	var number := _int(value)
	if number == -1:
		return "Off"
	if number == 1:
		var mode := str(_project.get("tts", "Simple"))
		add_note(CandyLocale.t("TTS was on (1). 1.2 needs the TTS mode itself: %s, your engine's, was written. Check it if your engines use different modes.") % mode, LEVEL_NOTE)
		return mode
	return "null"


#* PortraitPlay (play or not, by portrait node) -> Portrait_Play (loop count):
func _portrait_play(data: Dictionary) -> String:
	var value := "1"
	if data.has("PortraitPlay"):
		value = _text(data["PortraitPlay"]).strip_edges()
	match str(_project.get("portrait_node", PORTRAIT_SPRITE)):
		PORTRAIT_FOLDER:
			return "-2"
		PORTRAIT_VIDEO:
			if value == "0":
				return "0"
			return "1"
	if value == "1":
		return "-2"
	return "0"


func _voice(value: Variant) -> String:
	var text := _r(value)
	if text.begins_with("res://") or text.begins_with("user://"):
		add_note(CandyLocale.t("Voice is a full path. 1.2 adds the variation's folder to it for every variation but Default (res://X/French/hello.ogg). Set voice_fallback_language to 'Default' in Candy_Properties.gd to fall back on the file given."))
	return text


#* Convert a Disposition:
func _disposition(text: String) -> String:
	if text.strip_edges() == "":
		return text
	var parts: Array = []  #/ [is reference, text]
	var literal := ""
	var i := 0
	var has_reference := false
	while i < text.length():
		var rest := text.substr(i)
		var symbol := ""
		for key in ["vardict_symbol", "singleton_symbol", "node_symbol"]:			#/ 1.1.3 read references anywhere (not roles)
			if _starts(rest, _sym(key)):
				symbol = _sym(key)
				break
		if symbol == "":
			literal += text.substr(i, 1)
			i += 1
			continue
		var end := rest.find(",")
		if end < 0:
			end = rest.length()
		if literal != "":
			parts.append([false, literal])
			literal = ""
		var token := rest.substr(0, end).strip_edges()
		var body = _ref_body(token)
		if body == null:
			body = token
		parts.append([true, str(body)])
		has_reference = true
		i += end
	if literal != "":
		parts.append([false, literal])

	if not has_reference:
		if not text.contains(",") and text.contains("."):			#/ 1.1.3 split a list with no comma on "."
			return text.replace(".", ",")
		return _escape_expression(text)
	var pieces: PackedStringArray = []
	for part in parts:
		if part[0]:
			pieces.append(str(part[1]))
		else:
			pieces.append(_quoted(str(part[1])))
	return _expr() + " + ".join(pieces)


func _quoted(text: String) -> String:
	if not text.contains("'"):
		return "'%s'" % text
	return "\"%s\"" % text.replace("\"", "\\\"")


func _variations(value: Variant) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for entry in value:
		if not entry is Dictionary:
			continue
		var converted := {}
		for variation in entry:
			var content = entry[variation]
			if not content is Dictionary:
				converted[variation] = content
				continue
			var data: Dictionary = content.duplicate(true)
			if data.has("Text"):
				#? 1.2 evaluates a spoken text starting with the expression symbol - doubled, it stays text:
				data["Text"] = _escape_expression(_speech(_text(data["Text"])))
			if data.has("Weight"):
				data["Weight"] = _text(data["Weight"])
			if str(variation).contains("_#") and str(data.get("Text", "")) == "":
				add_note(CandyLocale.t("Variation %s is empty. In 1.1.3 picking it skipped the line; 1.2 never picks an empty variation.") % variation)
			converted[variation] = data
		result.append(converted)
	return result


#* Convert spoken text:
func _speech(text: String) -> String:
	var start := _sym("text_var_symbol_start")
	var end := _sym("text_var_symbol_end")
	if start == "" or end == "":
		return _speech_literal(text)
	var result := ""
	var position := 0
	while true:
		var start_at := text.find(start, position)
		if start_at < 0:
			break
		var end_at := text.find(end, start_at + start.length())
		if end_at < 0:
			break
		result += _speech_literal(text.substr(position, start_at - position))
		var content := text.substr(start_at + start.length(), end_at - start_at - start.length())
		result += str(_new["text_var_start"]) + _text_variable(content) + str(_new["text_var_end"])			#/ 1.2 symbols
		position = end_at + end.length()
	return result + _speech_literal(text.substr(position))


func _text_variable(content: String) -> String:
	if _starts(content, _sym("vardict_symbol")) or _starts(content, _sym("role_symbol")):
		return content
	var body = _ref_body(content)
	if body != null:
		return _expr() + str(body)
	return content


#* Convert text outside text variables (substitutions, doubled symbols):
func _speech_literal(text: String) -> String:
	var symbol := _sym("substitution_symbol")
	var separator := _sym("separator_symbol")
	if symbol == "" or separator == "":
		return _double_symbols(text)
	var result := ""
	var position := 0
	while true:
		var start_at := text.find(symbol, position)
		if start_at < 0:
			break
		var end_at := text.find(symbol, start_at + symbol.length())
		if end_at < 0:
			break
		var token := text.substr(start_at + symbol.length(), end_at - start_at - symbol.length())
		if token.split(separator, false).size() < 2:			#/ 1.1.3 only read a pair holding a separator as a token
			result += _double_symbols(text.substr(position, end_at + symbol.length() - position))
		else:
			result += _double_symbols(text.substr(position, start_at - position))
			result += str(_new["substitution_start"]) + _substitution(token, separator) + str(_new["substitution_end"])
		position = end_at + symbol.length()
	return result + _double_symbols(text.substr(position))


func _substitution(token: String, separator: String) -> String:
	var parts := token.split(separator)
	for i in parts.size():
		var part := parts[i]
		var trimmed := part.strip_edges()
		if i == 2 and trimmed.is_valid_int():
			add_note(CandyLocale.t("The word substitution \"%s\" picks its category by number. In 1.1.3 the number counted the word group's case rule too; if the group has one, lower the number by 1.") % token)
		if i > 1 or _starts(trimmed, _sym("vardict_symbol")) or _starts(trimmed, _sym("role_symbol")):
			continue
		var body = _ref_body(trimmed)
		if body != null:
			parts[i] = _expr() + str(body)
	return separator.join(parts)


#* Double every 1.2 text variable, substitution and text event symbol, so it displays:
func _double_symbols(text: String) -> String:
	var symbols: Array = []
	for key in ["text_var_start", "text_var_end", "substitution_start", "substitution_end",
			"text_event_start", "text_event_end", "lexicon_escape_start", "lexicon_escape_end"]:
		var symbol := str(_new.get(key, ""))
		if symbol != "" and not (symbol in symbols):
			symbols.append(symbol)
	if symbols.is_empty():
		return text
	var result := ""
	var i := 0
	while i < text.length():
		var matched := ""
		for symbol in symbols:
			if text.substr(i).begins_with(symbol) and symbol.length() > matched.length():
				matched = symbol
		if matched == "":
			result += text.substr(i, 1)
			i += 1
		else:
			result += matched + matched
			i += matched.length()
	return result


#& Control

func _set_command(data: Dictionary) -> Dictionary:
	if data.has("Variable"):
		data["Variable"] = _target(data["Variable"])
	_r_keys(data, ["Operator"])
	if data.has("Expression"):
		data["Expression"] = _expression(data["Expression"])
	return data


func _flag(data: Dictionary) -> Dictionary:
	_r_keys(data, ["Flag", "Operator"])
	if data.has("Expression"):
		data["Expression"] = _expression(data["Expression"])
	return data


func _call(data: Dictionary) -> Dictionary:
	if data.has("Function"):
		data["Function"] = _target(data["Function"])
	if data.has("Arguments"):
		data["Arguments"] = _arguments(data["Arguments"])
	if data.has("Variable"):
		data["Variable"] = _target(data["Variable"])
	_r_keys(data, ["Await"])
	return data


func _emit(data: Dictionary) -> Dictionary:
	if data.has("Signal"):
		data["Signal"] = _target(data["Signal"])
	if data.has("Arguments"):
		data["Arguments"] = _arguments(data["Arguments"])
	return data


#* Await - a plain path was a node relative to the engine, needing $ in 1.2:
func _await(data: Dictionary) -> Dictionary:
	if data.has("Signal"):
		var text := _text(data["Signal"]).strip_edges()
		var target := _target(text)
		if target == text and text.contains("/"):
			target = "$" + text
		data["Signal"] = target
	if data.has("Variable"):
		data["Variable"] = _target(data["Variable"])
	return data


#* Arguments - 1.1.3 evaluated "[" + arguments + "]", so a comma list was several:
func _arguments(value: Variant) -> Variant:
	if value is Array:
		return value
	var text := _text(value).strip_edges()
	if text == "":
		return ""
	var body = _super_body(text)
	if body != null:
		return _expr() + str(body)
	return _expr() + "[" + _rewrite_refs(text) + "]"


func _name_command(data: Dictionary) -> Dictionary:
	if data.has("Reference"):
		data["Reference"] = _actor(data["Reference"])
	_r_keys(data, ["Name", "Actor_Key"])
	if data.has("Table"):
		var table := _text(data["Table"]).strip_edges()
		var actor_key := str(data.get("Actor_Key", "DisplayName"))
		if table != "" and not table.ends_with("display_names"):
			add_note(CandyLocale.t("Name translated its value through the table %s, which 1.2 no longer does. Translate it with a translate() expression instead.") % table)
		elif table != "" and actor_key != "" and actor_key != "DisplayName" and actor_key != "ShortName":
			add_note(CandyLocale.t("Name translated its value through display_names before writing it to %s. 1.2 only translates DisplayName and ShortName, when they're displayed.") % actor_key)
		data.erase("Table")
	return data


func _role(data: Dictionary) -> Dictionary:
	if data.has("Role"):
		data["Role"] = _actor(data["Role"])
	if data.has("Reference"):
		data["Reference"] = _actor(data["Reference"])
	return data


func _disposition_command(data: Dictionary) -> Dictionary:
	if data.has("Reference"):
		data["Reference"] = _actor(data["Reference"])
	_r_keys(data, ["Disposition"])
	return data


func _export(data: Dictionary) -> Dictionary:
	_r_keys(data, ["Format", "File", "Path", "Method"])
	if data.has("Data"):
		var entries: PackedStringArray = []
		for entry in _text(data["Data"]).split(",", false):
			if entry.strip_edges() != "":
				entries.append(_target(entry))
		data["Data"] = ", ".join(entries)
	return data


func _import(data: Dictionary) -> Dictionary:
	_r_keys(data, ["Format", "File", "Path"])
	if data.has("Dictionary"):
		data["Dictionary"] = _target(data["Dictionary"])
	return data


func _custom(data: Dictionary) -> Dictionary:
	_r_keys(data, ["Command"])
	if data.has("Data"):
		data["Data"] = _super_only(data["Data"])
	return data


func _condition(data: Dictionary, is_for: bool) -> Dictionary:
	if data.has("Condition"):
		if is_for:
			data["Condition"] = _for_condition(_text(data["Condition"]))
		else:
			data["Condition"] = _expression(data["Condition"], false)
	#Ł Type names the command the body runs:
	if data.get("Commands") is Dictionary:
		data["Commands"] = _convert_body(data["Commands"])
		if not data["Commands"].is_empty():
			data["Type"] = str(data["Commands"].keys()[0])
	if data.has("Type") and str(data["Type"]).begins_with("§"):
		data["Type"] = str(data["Type"]).substr(1).replace(" ", "_")
	return data


#* For - "i in range(3)" -> "i in ¢range(3)":
func _for_condition(text: String) -> String:
	var at := text.find(" in ")
	if at < 0:
		return _expression(text, false)
	var iterable := text.substr(at + 4).strip_edges()
	return text.substr(0, at).strip_edges() + " in " + _expr() + _rewrite_refs(iterable)


func _input(data: Dictionary) -> Dictionary:
	_r_keys(data, ["File"])
	if data.has("Variable"):
		data["Variable"] = _target(data["Variable"])
	for key in ["Mode", "Instructions", "Placeholder", "Text"]:
		if data.has(key):
			data[key] = _super_only(data[key])
	var custom := {}
	var any := false
	for n in range(1, 6):
		var key := "Custom%d" % n
		custom["Custom_%d" % n] = _super_only(data.get(key, ""))
		if str(custom["Custom_%d" % n]) != "":
			any = true
		data.erase(key)
	if any:
		_set_custom_data(data, custom)
	return data


#* Put Custom values in the level's Meta:
func _set_custom_data(data: Dictionary, custom: Dictionary) -> void:
	var meta = data.get("Meta")
	if not meta is Dictionary:
		meta = {}
	meta["Custom_Data"] = custom
	data["Meta"] = meta


func _wait(data: Dictionary) -> Dictionary:
	if data.has("Time"):
		data["Wait_Time"] = _r(data["Time"])
		data.erase("Time")
	return data


#* Clear -> UI_Clear (D1 - Backgrounds and Busts never worked in 1.1.3):
func _clear(data: Dictionary) -> Dictionary:
	_r_keys(data, ["Box", "Bubbles", "Subtitles", "Portraits", "Backgrounds", "Busts"])
	var cleared: Array = []
	for key in ["Backgrounds", "Busts"]:
		if str(data.get(key, "1")) == "1":
			cleared.append(key)
		data[key] = "0"
	if not cleared.is_empty():
		if cleared.size() == 2:
			add_note(CandyLocale.t("{first} and {second} never worked in Candy DE 1.1.3, so the line left them on screen. It was set to \"0\" to keep that: set it to \"1\" to clear them.").format({"first": cleared[0], "second": cleared[1]}), LEVEL_NOTE)
		else:
			add_note(CandyLocale.t("%s never worked in Candy DE 1.1.3, so the line left them on screen. It was set to \"0\" to keep that: set it to \"1\" to clear them.") % cleared[0], LEVEL_NOTE)
	return data


#& Choices

func _choice_list(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Menu Scene", "Category Scene", "Button Scene"])
	_r_keys(data, ["Menu_Scene", "Category_Scene", "Button_Scene", "Title", "Prompt", "Tags", "Main", "Mouse"])
	if data.get("Setup") is Dictionary:
		data["Setup"] = _transition(data["Setup"], false)
	_custom_to_meta(data)
	data.erase("Reference")
	data["Timers"] = _named_list(data.get("Timers", []), _timer)
	data["Categories"] = _named_list(data.get("Categories", []), _category)
	return data


#* Convert [{ name = data }, ...] with convert_entry:
func _named_list(value: Variant, convert_entry: Callable) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for entry in value:
		if not entry is Dictionary:
			continue
		var converted := {}
		for entry_name in entry:
			var entry_data = entry[entry_name]
			if entry_data is Dictionary:
				_where.append(str(entry_name))
				converted[entry_name] = convert_entry.call(entry_data.duplicate(true))
				_where.remove_at(_where.size() - 1)
			else:
				converted[entry_name] = entry_data
		result.append(converted)
	return result


func _custom_to_meta(data: Dictionary) -> void:
	if not data.has("Custom"):
		return
	var custom := _super_only(data["Custom"])
	data.erase("Custom")
	if custom != "":
		_set_custom_data(data, {"Custom_1": custom})


func _timer(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Timer Choices"])
	_r_keys(data, ["Time", "Auto", "Loop", "Tags", "Timer_Choices"])
	var loop := _text(data.get("Loop", "1"))
	if loop.is_valid_int() and loop.to_int() < -1:
		add_note(CandyLocale.t("Loops %s fired once in Candy DE 1.1.3; 1.2 reports it and fires once. Write 1.") % loop)
	_rename_loops(data)
	for key in ["Setup", "Timeout"]:
		if data.get(key) is Dictionary:
			data[key] = _transition(data[key], false)
	_custom_to_meta(data)
	return data


func _category(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Category Scene", "Button Scene"])
	_r_keys(data, ["Category_Scene", "Button_Scene", "Title", "Prompt", "Tags", "Mouse"])
	if data.get("Setup") is Dictionary:
		data["Setup"] = _transition(data["Setup"], false)
	_custom_to_meta(data)
	data["Choices"] = _named_list(data.get("Choices", []), _choice)
	return data


func _choice(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Button Scene"])
	_r_keys(data, ["Label", "Tooltip", "Button_Scene", "Tags", "Enabled", "Active", "Invisible", "Navigate"])
	if data.get("Setup") is Dictionary:
		data["Setup"] = _transition(data["Setup"], false)
		if str(data.get("Enabled", "1")) != "1" and _has_target(data["Setup"]):
			add_note(CandyLocale.t("This choice starts disabled and has a Setup. Candy DE 1.1.3 ran its Setup with the menu's; 1.2 runs it when Choice_Status enables the choice."))
	if data.get("Finish") is Dictionary:
		data["Finish"] = _transition(data["Finish"], true)
	_custom_to_meta(data)
	return data


func _has_target(transition: Dictionary) -> bool:
	for key in ["Conversation", "Block", "Line"]:
		if str(transition.get(key, "")).strip_edges() != "":
			return true
	return false


#* Convert a Setup, Timeout or Finish:
func _transition(data: Dictionary, finish: bool) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	_r_keys(result, ["Type", "Conversation", "Block", "Line", "Levels"])
	if not finish:
		return result
	var type := str(result.get("Type", "")).to_lower()
	if (type == "return" or type == "end" or type == "close") and not _has_target(result):
		add_note(CandyLocale.t("This choice's Finish is {type} with no target, which did nothing in Candy DE 1.1.3: the menu stayed open. {effect}").format({"type": result.get("Type", ""), "effect": _finish_effect(type)}))
	if type == "return":			#/ A Finish's Return only ended the choice's line in 1.1.3, as 1.2's Close does
		result["Type"] = "Close"
		for key in ["Conversation", "Block", "Line"]:
			result[key] = ""
	return result


func _finish_effect(type: String) -> String:
	match type:
		"end":
			return CandyLocale.t("In 1.2 it ends the dialogue.")
		"close":
			return CandyLocale.t("In 1.2 it closes the menu.")
	return CandyLocale.t("In 1.2 it closes the menu and carries on after it.")


func _choice_status(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Menu Mode", "Menu Tags", "Category Mode", "Category Tags", "Choice Mode", "Choice Tags"])
	_r_keys(data, ["Menu_Mode", "Menu_Tags", "Category_Mode", "Category_Tags", "Choice_Mode", "Choice_Tags",
		"Enable", "Activate", "Show", "Label", "Tooltip"])
	_check_modes(data, ["Menu_Mode", "Category_Mode", "Choice_Mode"])
	return data


func _check_modes(data: Dictionary, keys: Array) -> void:
	for key in keys:
		var mode := str(data.get(key, "Last")).capitalize()
		if not (mode in ["Last", "Tags", "All"]) and not mode.begins_with(_expr()):
			add_note(CandyLocale.t("{key} \"{value}\" isn't a mode. Candy DE 1.1.3 then changed everything (or, for Menu_Mode, nothing); 1.2 changes nothing.").format({"key": key, "value": data.get(key, "")}))


func _timer_status(data: Dictionary) -> Dictionary:
	_underscore_keys(data, ["Menu Mode", "Menu Tags", "Timer Mode", "Timer Tags", "Timer Node"])
	_r_keys(data, ["Menu_Mode", "Menu_Tags", "Timer_Mode", "Timer_Tags", "Time", "Timer_Node", "Loop", "Status"])
	data.erase("Show")
	_check_modes(data, ["Menu_Mode", "Timer_Mode"])
	var loop := str(data.get("Loop", "")).strip_edges()
	var status := str(data.get("Status", "")).strip_edges()
	var in_timeout := _timeout_blocks.has(_conversation + "\n" + _block)

	if loop.begins_with("+") or loop.begins_with("-") or loop.begins_with("*") or loop.begins_with("/"):
		add_note(CandyLocale.t("A relative Loops (%s) stopped at -1 (forever) in Candy DE 1.1.3; in 1.2 it stops at 0 (no loops left), and leaves a timer looping forever as it is.") % loop)
	elif loop.is_valid_int() and loop.to_int() > 0 and in_timeout:
		if str(data.get("Timer_Mode", "Last")).capitalize() == "Last":
			#? 1.1.3 counted the ending timeout after this ran.
			if loop.to_int() == 1:
				data["Loop"] = ""
				data["Status"] = "Stop"
			else:
				data["Loop"] = str(loop.to_int() - 1)
			add_note(CandyLocale.t("This block is a timer's Timeout. Candy DE 1.1.3 counted the timeout after it, so Loops {loops} gave one firing fewer: {result} was written to keep that.").format({"loops": loop, "result": _loop_result(data)}), LEVEL_NOTE)
		else:
			add_note(CandyLocale.t("This block is a timer's Timeout. If this Loops (%s) is that timer's, Candy DE 1.1.3 gave it one firing fewer: lower it by 1.") % loop)
	if status == "Start/Resume" and loop == "":
		add_note(CandyLocale.t("A timer that had fired all its loops ran once more when restarted in Candy DE 1.1.3; in 1.2 it doesn't start. Add \"Loops\": \"+1\" to keep that."))
	_rename_loops(data)
	return data


func _loop_result(data: Dictionary) -> String:
	if str(data.get("Status", "")) == "Stop" and str(data.get("Loop", "")) == "":
		return "Status Stop"
	return "Loops %s" % data.get("Loop", "")


#* Find the blocks a choice timer's Timeout runs, in the 1.1 data:
func _find_timeout_blocks(conversations: Dictionary) -> void:
	_timeout_blocks.clear()
	for conversation in conversations:
		var blocks = conversations[conversation]
		if not blocks is Dictionary:
			continue
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary or not block_data.get(CandyDialogue.TEXT_KEY) is Array:
				continue
			for line in block_data[CandyDialogue.TEXT_KEY]:
				_find_timeouts(line, str(conversation), str(block))


func _find_timeouts(value: Variant, conversation: String, block: String) -> void:
	if value is Dictionary:
		for key in value:
			if _command_id(str(key)) == "choice_list" and value[key] is Dictionary:
				var timers = value[key].get("Timers", [])
				if timers is Array:
					for entry in timers:
						if not entry is Dictionary:
							continue
						for timer in entry.values():
							if timer is Dictionary and timer.get("Timeout") is Dictionary:
								var timeout: Dictionary = timer["Timeout"]
								var target_conversation := str(timeout.get("Conversation", "")).strip_edges()
								var target_block := str(timeout.get("Block", "")).strip_edges()
								if target_conversation == "":
									target_conversation = conversation
								if target_block == "":
									target_block = block
								if str(timeout.get("Conversation", "")) + str(timeout.get("Block", "")) + str(timeout.get("Line", "")) != "":
									_timeout_blocks[target_conversation + "\n" + target_block] = true
			_find_timeouts(value[key], conversation, block)
	elif value is Array:
		for item in value:
			_find_timeouts(item, conversation, block)


#& UI_Z

#* Hide / V_Show / I_Show -> UI_Z:
func _ui_z(id: String, data: Dictionary) -> Dictionary:
	var nodes := {}
	var box := 1
	if id != "hide":
		box = -1
	if data.has("Box"):
		box = _int(data["Box"])
	var portrait := box
	if data.has("Portrait"):
		portrait = _int(data["Portrait"])
	if portrait != box:
		add_note(CandyLocale.t("Box and Portrait differ. The portrait is part of the dialogue box in 1.2, so they move together, as Box says."))

	var elements: Array = UI_ELEMENTS
	if id != "hide":
		elements = SHOW_ELEMENTS
	var settings := {}
	if id == "hide" and box == 1:			#/ Hide reset the z-order
		settings = {"Z_Index": "Reset", "Relative_To": ""}
	elif id != "hide" and box == 1:			#/ V_Show / I_Show raised it above a player
		var player := _r(data.get("Node", ""))
		if player == "":
			player = "Video"
			if id == "i_show":
				player = "Image"
		settings = {"Z_Index": "+1", "Relative_To": player}
	elif id != "hide" and box == -1:
		settings = {"Z_Index": "Reset", "Relative_To": ""}
	if not settings.is_empty():
		for element in elements:
			if element in _project.get("ui_elements", UI_ELEMENTS):
				nodes[element] = settings.duplicate()
	return {"Nodes": nodes}


#& Media

func _media(id: String, data: Dictionary) -> Array:
	var info: Array = MEDIA_COMMANDS[id]
	var command := str(info[0])
	var kind := str(info[2])
	var player := _r(data.get("Node", ""))
	if player == "":
		player = str(info[1])
	if player == "Voice" or player == "PEffect":
		add_note(CandyLocale.t("%s was a media player of Candy DE 1.1.3 that 1.2 no longer has, so this line has no player to act on.") % player)
	data.erase("Node")

	var has_box := kind != "audio" and command != "Media_Stop" and command != "Media_Volume" and command != "Media_Skip"
	if has_box:
		var box := -1
		if data.has("Box"):
			box = _int(data["Box"])
		if data.has("Portrait") and _int(data["Portrait"]) != box:
			add_note(CandyLocale.t("Box and Portrait differ. The portrait is part of the dialogue box in 1.2, so they move together, as Box says."))
		data["Box"] = _box(box)
	data.erase("Portrait")

	match command:
		"Media_Play":
			_r_keys(data, ["File"])
			if kind == "image":
				_image(data)
			_media_loop(data)
			_rename_loops(data)
			_rename_waits(data)
		"Media_Wait":
			_rename_waits(data)
		"Media_Pause":
			_r_keys(data, ["Lines", "All"])
		"Media_Volume":
			_r_keys(data, ["Time"])
			if data.has("Volume"):
				data["Volume"] = _volume(data["Volume"])
		"Media_Skip":
			if data.has("Time"):
				data["Time"] = _skip_time(data["Time"])
	return [[command, {"Players": {player: data}}]]


#* 1.1.3 Box (1 raise above the player, -1 reset, else leave) -> 1.2 value:
func _box(box: int) -> String:
	if box == 1:
		return "+1"
	if box == -1:
		return "Reset"
	return ""


#* Media Loop - 1.1.3 replayed forever on 0 or "", once on a negative:
func _media_loop(data: Dictionary) -> void:
	if not data.has("Loop"):
		return
	var text := _r(data["Loop"])
	if text == "" or text == "0":
		data["Loop"] = "-1"
	elif text.is_valid_int() and text.to_int() < 0:
		data["Loop"] = "1"
	else:
		data["Loop"] = text


#* Loop -> Loops (1.2's name):
func _rename_loops(data: Dictionary) -> void:
	if data.has("Loop"):
		data["Loops"] = data["Loop"]
		data.erase("Loop")


func _rename_waits(data: Dictionary) -> void:
	if data.has("Wait"):
		data["Wait_Loops"] = _r(data["Wait"])
		data.erase("Wait")
	if data.has("Time"):
		data["Wait_Time"] = _r(data["Time"])
		data.erase("Time")


#* Image - Duration was an animation's FPS, or a still image's loop length:
func _image(data: Dictionary) -> void:
	if not data.has("Animated"):
		data["Animated"] = "0"
	var animated := _int(data["Animated"]) == 1
	data["Animated"] = _r(data["Animated"])
	var duration := _int(data.get("Duration", "0"))
	data["Duration"] = ""
	if animated:
		if duration > 0:
			data["FPS"] = str(duration)
		return
	var loop := _text(data.get("Loop", "1")).strip_edges()
	add_note(CandyLocale.t("A still image on an Image player never showed in Candy DE 1.1.3 (its file path was built wrongly). In 1.2 it does."))
	if loop == "" or loop == "0":
		return  #/ Forever: Loop -1, no Duration
	if duration <= 0:
		add_note(CandyLocale.t("A still image with no Duration stayed up for as long as the player's last image did in Candy DE 1.1.3. In 1.2 it stays until it's stopped: give it a Duration."))
		return
	var count := 1
	if loop.is_valid_int() and loop.to_int() > 1:
		count = loop.to_int()
	data["Duration"] = str(duration * count)			#/ A still image was removed when its loops ended
	data["Loop"] = "1"


#* Volume - a signed value was relative in 1.1.3:
func _volume(value: Variant) -> String:
	var text := _r(value)
	if text.begins_with("+=") or text.begins_with("-="):
		add_note(CandyLocale.t("Volume %s was read as no change by Candy DE 1.1.3. In 1.2 it changes the volume.") % text)
		return text
	if (text.begins_with("+") or text.begins_with("-")) and text.substr(1).strip_edges().is_valid_float():
		return text.substr(0, 1) + "=" + text.substr(1).strip_edges()
	return text


#* Skip Time - V_Skip's relative frames "+f=N" -> "f+N"; a number was a position:
func _skip_time(value: Variant) -> String:
	if not (value is String or value is StringName):
		return _text(value)
	var text := _r(value)
	var lower := text.to_lower()
	if lower.begins_with("+f=") or lower.begins_with("-f="):
		return "f" + text.substr(0, 1) + text.substr(3)
	return text


#& Effects

func _effect(id: String, data: Dictionary) -> Array:
	var player := _r(data.get("Node", ""))
	if player == "":
		player = "Effect"
	if player == "PEffect":
		add_note(CandyLocale.t("PEffect was the portrait's effect player in Candy DE 1.1.3. It's part of the dialogue box in 1.2, and no longer a media player: this line has no player to act on."))
	data.erase("Node")
	match id:
		"effect":
			_r_keys(data, ["Animation"])
			if not data.has("Library"):
				data["Library"] = ""
			if data.has("Loop"):
				#? "" played once, as in 1.2.
				var loop := _r(data["Loop"])
				if loop == "0":
					loop = "-1"
				elif loop.is_valid_int() and loop.to_int() < 0:
					loop = "1"
				data["Loop"] = loop
			_rename_loops(data)
			_rename_waits(data)
			return [["Effect_Play", {"Players": {player: data}}]]
		"effect_wait":
			_rename_waits(data)
			return [["Effect_Wait", {"Players": {player: data}}]]
	_stop_on_current_frame(data)
	return [["Effect_Stop", {"Players": {player: data}}]]


#* Stop on the current frame (D3; 1.2's default plays RESET):
func _stop_on_current_frame(data: Dictionary) -> void:
	data["Stop_Frame"] = "0"
	add_note(CandyLocale.t("The effect stops on its current frame, as in Candy DE 1.1.3. New in 1.2: Stop_Frame \"Clear\" plays the effect's RESET animation, if it has one, then stops."), LEVEL_NOTE)


#& Backgrounds

#* List of names, from a comma separated String or an Array:
func _names(value: Variant, actors: bool = false) -> Array:
	var raw: Array = []
	if value is Array:
		raw = value
	else:
		raw = Array(_text(value).split(","))
	var result: Array = []
	for entry in raw:
		var entry_name := _text(entry).strip_edges()
		if entry_name == "":
			continue
		if actors:
			result.append(_actor(entry_name))
		else:
			result.append(_r(entry_name))
	return result


#* Layers (an empty one meant every layer):
func _layers(data: Dictionary) -> Array:
	var layers := _names(data.get("Layers", ""))
	if not layers.is_empty():
		return layers
	layers = _names(str(_project.get("bg_layers", "")))
	if layers.is_empty():
		add_note(CandyLocale.t("Layers was empty, which meant every layer in Candy DE 1.1.3. 1.2 needs each layer named: give your background scene's layers in the Dialogue Converter, or add them here."))
	return layers


#* One entry per name, each a copy of settings:
func _entries(names: Array, settings: Dictionary) -> Dictionary:
	var result := {}
	for entry_name in names:
		result[entry_name] = settings.duplicate(true)
	return result


func _bg(id: String, data: Dictionary) -> Array:
	match id:
		"bg_scene":
			return [["BG_Scene", _r_keys(data, ["Scene"])]]
		"bg":
			#? One layer, as written (1.1.3 never split it).
			var layer := _r(data.get("Layers", ""))
			data.erase("Layers")
			if layer == "":
				add_note(CandyLocale.t("BG with no layer did nothing in Candy DE 1.1.3."))
				return [["BG_Play", {"Layers": {}}]]
			if layer.contains(","):
				add_note(CandyLocale.t("BG took a single layer in Candy DE 1.1.3, so \"%s\" was looked up as one layer and failed. Now it's one layer of that name: split it into several if they were meant.") % layer)
			_r_keys(data, ["File", "Animation"])
			_hold_loop(data)
			_rename_loops(data)
			_rename_waits(data)
			_frame_wait_note(data)
			_bg_loops[layer] = str(data.get("Loops", "1"))
			return [["BG_Play", {"Layers": {layer: data}}]]
		"bg_stop", "bg_remove", "bg_mirror", "bg_wait":
			var layers := _layers(data)
			data.erase("Layers")
			var command := "BG_Remove"
			match id:
				"bg_stop":
					command = "BG_Stop"
					_stop_frame(data)
				"bg_mirror":
					command = "BG_Mirror"
					_r_keys(data, ["Axis"])
				"bg_wait":
					command = "BG_Wait"
			if id != "bg_wait":
				return [[command, {"Layers": _entries(layers, data)}]]
			var entries := {}
			for layer in layers:
				var entry: Dictionary = data.duplicate(true)
				_wait_until_done(entry, _bg_loops.get(layer, ""), "layer")
				entries[layer] = entry
			return [[command, {"Layers": entries}]]
		"bg_effect", "bg_effect_wait", "bg_effect_stop":
			return [[_effect_command(id), {"Layers": _effects(id, data, _layers(data))}]]
	return []


func _effect_command(id: String) -> String:
	var suffix := "Stop"
	if id.ends_with("wait"):
		suffix = "Wait"
	elif id.ends_with("effect"):
		suffix = "Play"
	if id.begins_with("bg"):
		return "BG_Effect_" + suffix
	return "VN_Effect_" + suffix


#* BG / VN effects -> target = { "Effects" = { effect = settings } }:
func _effects(id: String, data: Dictionary, targets: Array) -> Dictionary:
	var effects := _names(data.get("Effects", ""))
	var play := id.ends_with("effect")
	var settings: Dictionary = data.duplicate(true)
	for key in ["Layers", "Actors", "Effects"]:
		settings.erase(key)
	_r_keys(settings, ["Library"])

	if play:
		var loop := _r(settings.get("Loop", "0"))
		if loop == "" or loop == "0" or (loop.is_valid_int() and loop.to_int() < 0):
			loop = "-1"
		settings["Loop"] = loop
		_rename_loops(settings)
		if id.begins_with("bg") and not settings.has("Time"):
			settings["Time"] = "1"  #/ 1.1.3 default: 1 second wait
	if play or id.ends_with("wait"):
		_rename_waits(settings)
	else:
		_stop_on_current_frame(settings)

	if effects.is_empty():
		if play:
			add_note(CandyLocale.t("Effects was empty, so Candy DE 1.1.3 played every animation of the library. 1.2 needs each effect named: add them."))
		else:
			add_note(CandyLocale.t("Effects was empty, which meant every effect playing in Candy DE 1.1.3. 1.2 needs each effect named: add them."))
	if id.ends_with("wait") and _int(settings.get("Wait_Loops", "0")) == -1:
		add_note(CandyLocale.t("Wait -1 waited until the effect's loops were done in Candy DE 1.1.3. 1.2 has no such value: write the number of loops to wait for."))
		settings["Wait_Loops"] = "0"

	var result := {}
	var first := true
	for target in targets:
		var target_effects := {}
		for effect in effects:
			var entry: Dictionary = settings.duplicate(true)
			if play and not first:			#/ 1.1.3 only waited on the first target's first effect
				entry["Wait_Loops"] = "0"
				entry["Wait_Time"] = ""
			first = false
			target_effects[effect] = entry
		result[target] = {"Effects": target_effects}
	return result


#* Explicit "" Loop -> "0", a hold, as BG, VN_Bust, CS_Anim and CS_Sprite read it:
func _hold_loop(data: Dictionary) -> void:
	if data.has("Loop"):
		var loop := _r(data["Loop"])
		if loop == "":
			loop = "0"
		data["Loop"] = loop


func _frame_wait_note(data: Dictionary) -> void:
	if str(data.get("Wait_Time", "")).to_lower().begins_with("f="):
		add_note(CandyLocale.t("f= counted at 30 frames per second in Candy DE 1.1.3. 1.2 counts the media's own frames."))


#* Stop commands - Default -> Stop_Frame:
func _stop_frame(data: Dictionary) -> void:
	var frame := "0"
	if data.has("Default"):
		frame = _r(data["Default"])
		data.erase("Default")
	data["Stop_Frame"] = frame
	if frame != "0" and frame != "":
		add_note(CandyLocale.t("Stop frame {frame}: Candy DE 1.1.3 went back to the first frame on an animation folder, and sought to {frame} / 30 seconds on a video. 1.2 goes to that frame, counted from 1. Check it if the layer or bust is either.").format({"frame": frame}))


#* Convert a wait:
func _wait_until_done(entry: Dictionary, loop: String, what: String) -> void:
	var wait := _text(entry.get("Wait", "")).strip_edges()
	var time := _text(entry.get("Time", "")).strip_edges()
	_rename_waits(entry)
	#Ł Waited until the playback's loops were done (BG: Wait -1, VN: no wait):
	var until_done := false
	if what == "layer":
		until_done = wait == "-1"
	else:
		until_done = _int(wait) <= 0 and time == ""
	if not until_done:
		return
	if loop.is_valid_int() and loop.to_int() > 0:
		entry["Wait_Loops"] = loop
		if what == "layer":
			add_note(CandyLocale.t("This wait lasted until the layer's playback was done in Candy DE 1.1.3: Wait_Loops %s, its Loops, keeps that.") % loop, LEVEL_NOTE)
		else:
			add_note(CandyLocale.t("This wait lasted until the bust's playback was done in Candy DE 1.1.3: Wait_Loops %s, its Loops, keeps that.") % loop, LEVEL_NOTE)
		return
	entry["Wait_Loops"] = "0"
	if what == "layer":
		add_note(CandyLocale.t("This wait lasted until the layer's playback was done in Candy DE 1.1.3, which 1.2 can't say. Write the number of loops to wait for."))
	else:
		add_note(CandyLocale.t("This wait lasted until the bust's playback was done in Candy DE 1.1.3, which 1.2 can't say. Write the number of loops to wait for."))


#& Visual novel

func _actors(data: Dictionary) -> Array:
	var actors := _names(data.get("Actors", ""), true)
	if actors.is_empty():
		add_note(CandyLocale.t("Actors was empty, which meant every actor on a bust in Candy DE 1.1.3. 1.2 needs each actor named: add them."))
	return actors


func _vn(id: String, data: Dictionary) -> Array:
	match id:
		"vn_scene":
			return [["VN_Scene", _r_keys(data, ["Scene"])]]
		"vn_bust", "vn_move":
			var actor := _actor(data.get("Reference", ""))
			data.erase("Reference")
			_r_keys(data, ["Bust", "File", "Animation"])
			if id == "vn_move":
				return [["VN_Move", {"Actors": {actor: data}}]]
			_hold_loop(data)
			_rename_loops(data)
			_rename_waits(data)
			if _int(data.get("Wait_Loops", "0")) > 0 or str(data.get("Wait_Time", "")).strip_edges() != "":
				add_note(CandyLocale.t("1.2 counts this wait from the start of playback, which may begin before the Join effect: the line may move on sooner than in Candy DE 1.1.3."))
			_frame_wait_note(data)
			_vn_loops[actor] = str(data.get("Loops", "1"))
			return [["VN_Play", {"Actors": {actor: data}}]]
		"vn_mirror":
			var mirrored := _names(data.get("Actors", ""), true)
			data.erase("Actors")
			_r_keys(data, ["Axis"])
			return [["VN_Mirror", {"Actors": _entries(mirrored, data)}]]
		"vn_remove":
			var actors := _actors(data)
			data.erase("Actors")
			var entries := {}
			for i in actors.size():
				var entry: Dictionary = data.duplicate(true)
				entry["JML_Order"] = str(i)
				entries[actors[i]] = entry
			return [["VN_Remove", {"Actors": entries}]]
		"vn_bust_stop":
			var actors := _actors(data)
			data.erase("Actors")
			_stop_frame(data)
			return [["VN_Stop", {"Actors": _entries(actors, data)}]]
		"vn_bust_wait":
			var actors := _actors(data)
			data.erase("Actors")
			var entries := {}
			for actor in actors:
				var entry: Dictionary = data.duplicate(true)
				_wait_until_done(entry, _vn_loops.get(actor, ""), "bust")
				entries[actor] = entry
			return [["VN_Wait", {"Actors": entries}]]
		"vn_effect", "vn_effect_wait", "vn_effect_stop":
			return [[_effect_command(id), {"Actors": _effects(id, data, _actors(data))}]]
	return []


#& Cutscenes

#* "<Path 1>/<target>" for each of Targets:
func _cs_targets(data: Dictionary, single: bool = false) -> Array:
	var container := _r(data.get("Path 1", ""))
	var names: Array = []
	if single:
		var target := _r(data.get("Targets", ""))
		if target != "":
			names = [target]
	else:
		names = _names(data.get("Targets", ""), true)
	var result: Array = []
	for target in names:
		if container == "" or str(target).begins_with(_expr()):
			result.append(str(target))
		else:
			result.append(container + "/" + str(target))
	return result


func _cs(id: String, data: Dictionary) -> Array:
	var targets := _cs_targets(data, id == "cs_cam")
	var node := _r(data.get("Path 2", ""))
	for key in ["Path 1", "Path 2", "Targets"]:
		data.erase(key)

	match id:
		"cs_loc":
			return [["CS_Position", {"Markers": _cs_markers(id, data, targets, node)}]]
		"cs_look":
			return [["CS_Look", {"Markers": _cs_markers(id, data, targets, node)}]]
		"cs_scene":
			return [["CS_Scene", {"Targets": _cs_scene(data, targets)}]]
		"cs_cam":
			return [["CS_Cam", {"Targets": _entries(targets, {})}]]
		"cs_light":
			return [["CS_Light", {"Targets": _entries(targets, _r_keys(data, ["Color", "Energy", "Operator"]))}]]
		"cs_visible":
			return [["CS_Visible", {"Targets": _entries(targets, _r_keys(data, ["Visibility"]))}]]
		"cs_toggle":
			return [["CS_Toggle", {"Targets": _entries(targets, _r_keys(data, ["Method", "Properties", "Value"]))}]]
		"cs_move":
			add_note(CandyLocale.t("CS_Move runs a script of yours for each target in 1.2: write your 1.1 movement code as a script in Candy DE's Scripts/Move_Events folder, and name it in each target's Movement. The line's 1.1 keys were kept on each target."))
			if node != "":
				data["Path 2"] = node
			return [["CS_Move", {"Targets": _entries(targets, data)}]]
		"cs_anim", "cs_sprite", "cs_anim_wait", "cs_sprite_wait", "cs_anim_stop", "cs_sprite_stop":
			pass
		_:
			return []

	var is_anim := id.begins_with("cs_anim")
	data["Node"] = node
	if is_anim:
		for target in targets:
			if _starts(str(target).get_file(), _sym("role_symbol")):
				add_note(CandyLocale.t("Candy DE 1.1.3 didn't read roles on CS_Anim commands: %s was looked up as a node of that name. In 1.2 it's the actor in the role.") % target)
	var command := "CS_Anim"
	if not is_anim:
		command = "CS_Sprite"
	if id.ends_with("_stop"):
		_stop_frame(data)
		return [[command + "_Stop", {"Targets": _entries(targets, data)}]]
	if id.ends_with("_wait"):
		if _int(data.get("Wait", "0")) > 0 and _text(data.get("Time", "")).strip_edges() != "":
			add_note(CandyLocale.t("Candy DE 1.1.3 waited for Wait loops, then Time more. 1.2 waits until Wait_Loops x length + Wait_Time from the start: check the timing."))
		_rename_waits(data)
		return [[command + "_Wait", {"Targets": _entries(targets, data)}]]
	_r_keys(data, ["File", "Animation"])
	_hold_loop(data)
	_rename_loops(data)
	_rename_waits(data)
	_frame_wait_note(data)
	return [[command + "_Play", {"Targets": _entries(targets, data)}]]


#* CS_Loc / CS_Look -> markers first:
func _cs_markers(id: String, data: Dictionary, targets: Array, container: String) -> Dictionary:
	var markers: Array = []
	for marker in _names(data.get("Markers", "")):
		if container == "" or str(marker).begins_with(_expr()):
			markers.append(str(marker))
		else:
			markers.append(container + "/" + str(marker))
	data.erase("Markers")
	var settings: Dictionary = {}
	if id == "cs_loc":
		settings = _r_keys(data, ["Rotate"])
	else:
		settings = _r_keys(data, ["Axis"])

	var result := {}
	if markers.is_empty():
		add_note(CandyLocale.t("No markers: the line did nothing in Candy DE 1.1.3."))
		return result
	var dropped: Array = []
	for i in targets.size():
		var marker := ""
		if i < markers.size():			#/ 1.1.3 paired targets and markers by position
			marker = str(markers[i])
		elif id == "cs_look" and markers.size() == 1:			#/ CS_Look aimed every target at one marker
			marker = str(markers[0])
		else:
			dropped.append(targets[i])
			continue
		if not result.has(marker):
			result[marker] = {"Nodes": {}}
		result[marker]["Nodes"][targets[i]] = settings.duplicate(true)
	if not dropped.is_empty():
		add_note(CandyLocale.t("More targets than markers: Candy DE 1.1.3 left out %s, and so does the converted line.") % ", ".join(PackedStringArray(dropped)))
	return result


#* CS_Scene - each target gets every scene, named from Name by position:
func _cs_scene(data: Dictionary, targets: Array) -> Dictionary:
	var scenes := _names(data.get("Scene", ""))
	var instance_names: Array = []
	for entry in _text(data.get("Name", "")).split(","):
		instance_names.append(_r(entry))
	var instances := {}
	for i in scenes.size():
		var instance_name := ""
		if i < instance_names.size():
			instance_name = str(instance_names[i])
		if instances.has(instance_name):
			var named := str(scenes[i]).get_file().get_basename()
			add_note(CandyLocale.t("Several scenes had no name, which 1.2 can't hold: {scene} was named {name}.").format({"scene": scenes[i], "name": named}))
			instance_name = named
		instances[instance_name] = {"Scene": scenes[i]}
	var result := {}
	for target in targets:
		result[target] = {"Instances": instances.duplicate(true)}
	return result


#& Targets

#* Renumber Line targets into split blocks, and report missing ones:
func _fix_targets(conversations: Dictionary, index_maps: Dictionary, check: bool) -> void:
	for conversation in conversations:
		var blocks = conversations[conversation]
		if not blocks is Dictionary:
			continue
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary or not block_data.get(CandyDialogue.TEXT_KEY) is Array:
				continue
			var lines: Array = block_data[CandyDialogue.TEXT_KEY]
			for i in lines.size():
				_where = PackedStringArray([CandyLocale.t("{conversation} > {block} > line {line} (in 1.2)").format({"conversation": conversation, "block": block, "line": i})])
				_walk_targets(lines[i], str(conversation), str(block), conversations, index_maps, check)			#/ Missing targets: 1.1.3 skipped them, 1.2 ends the dialogue


func _walk_targets(value: Variant, conversation: String, block: String, conversations: Dictionary,
		index_maps: Dictionary, check: bool) -> void:
	if value is Dictionary:
		var transition: bool = value.has("Conversation") and value.has("Block") and value.has("Line")
		if transition:
			_fix_target(value, conversation, block, conversations, index_maps, check)
		for key in value:
			if transition and str(key) in ["Conversation", "Block", "Line"]:
				continue
			_walk_targets(value[key], conversation, block, conversations, index_maps, check)
	elif value is Array:
		for item in value:
			_walk_targets(item, conversation, block, conversations, index_maps, check)


func _fix_target(target: Dictionary, conversation: String, block: String, conversations: Dictionary,
		index_maps: Dictionary, check: bool) -> void:
	var target_conversation := str(target["Conversation"]).strip_edges()
	var target_block := str(target["Block"]).strip_edges()
	var line := str(target["Line"]).strip_edges()
	if target_conversation + target_block + line == "":
		return
	if target_conversation.begins_with(_expr()) or target_block.begins_with(_expr()):
		return
	if target_conversation == "":
		target_conversation = conversation
	if target_block == "":
		target_block = block

	if line.is_valid_int() and index_maps.has(target_conversation) and index_maps[target_conversation].has(target_block):
		var index_map: Array = index_maps[target_conversation][target_block]
		var old_line := line.to_int()
		if old_line >= 0 and old_line < index_map.size():
			target["Line"] = str(index_map[old_line])
		elif old_line >= index_map.size() and not index_map.is_empty():
			var added: int = conversations[target_conversation][target_block][CandyDialogue.TEXT_KEY].size() - index_map.size()
			target["Line"] = str(old_line + added)

	if not check:
		return
	var blocks = conversations.get(target_conversation)
	if not blocks is Dictionary or not blocks.has(target_block):
		add_note(CandyLocale.t("The target {conversation} > {block} isn't in this file. Candy DE 1.1.3 skipped a target that didn't exist; 1.2 ends the dialogue. Check it exists in the dialogue this runs in.").format({"conversation": target_conversation, "block": target_block}))
		return
	if line == "" or line.is_valid_int() or line.begins_with(_expr()):
		return
	var lines = blocks[target_block].get(CandyDialogue.TEXT_KEY, [])
	if lines is Array:
		for entry in lines:
			if entry is Dictionary and entry.get("LM") is Dictionary and str(entry["LM"].get("Reference", "")) == line:
				return
	add_note(CandyLocale.t("No LM line named {line} in {conversation} > {block}. Candy DE 1.1.3 went to the block's first line; 1.2 ends the dialogue.").format({"line": line, "conversation": target_conversation, "block": target_block}))

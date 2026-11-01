#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

const USER_FILE := "user_presets.txt"
const PROFILE_FILE := "profile_presets.txt"
const ID_PREFIX := "preset|"
const USER_CODE := "U"
const PROFILE_CODE := "P"

var _paths: Dictionary = {}       #/ conversation -> file path, set when the profile opens
var _user_name := ""
var _profile_name := ""
var _saved: Dictionary = {}       #/ conversation -> file text as last read or written
#^ Files never written - unreadable, or with variation names to fix by hand:
var _unreadable: Dictionary = {}  #/ conversation -> true
#^ Files whose variation names were fixed on load, written at the next save:
var _repaired: Dictionary = {}    #/ conversation -> true
#^ Files written with other symbols than the profile's, left out until updated:
var _mismatched: Dictionary = {}  #/ conversation -> true
var _category_regex := RegEx.new()
#^ A save waits for the end of the frame (see _on_history_changed()):
var _save_queued := false


func _ready() -> void:
	_category_regex.compile("^\\s*\\[([^\\]]*)\\]\\s*(.*)$")
	CandyProfiles.profile_opened.connect(_on_profile_opened)
	CandyProfiles.profile_closed.connect(_on_profile_closed)
	CandyDialogue.history_changed.connect(_on_history_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


func _exit_tree() -> void:
	save()  #/ Quitting from the landing screen skips the close request


#& Loading and saving

func _on_profile_opened(user: String, profile: String) -> void:
	_user_name = user
	_profile_name = profile
	_paths = {
		CandyDialogue.USER_PRESETS: CandyProfiles.user_dir(user).path_join(USER_FILE),
		CandyDialogue.PROFILE_PRESETS: CandyProfiles.current_profile_dir().path_join(PROFILE_FILE),
	}
	_saved.clear()
	_unreadable.clear()
	_repaired.clear()
	_mismatched.clear()
	CandyDialogue.set_presets(_read_checked(CandyDialogue.USER_PRESETS), _read_checked(CandyDialogue.PROFILE_PRESETS))
	if not _mismatched.is_empty():
		_ask_symbol_update.call_deferred()
	#Ł What the files would hold now, so untouched presets (1.1 files too) aren't rewritten:
	for conversation in CandyDialogue.PRESET_CONVERSATIONS:
		if _repaired.has(conversation):
			_saved[conversation] = ""
		else:
			_saved[conversation] = _file_text(conversation)


#* Get the open profile's two preset files:
func file_paths() -> Array:
	return _paths.values()


#* Read the preset files again, after something rewrote them (the Dialogue Converter):
#? Clears the undo history, as opening the profile does.
func reload() -> void:
	if _paths.is_empty():
		return
	_on_profile_opened(_user_name, _profile_name)


func _on_profile_closed() -> void:
	save()  #/ The paths were kept for this
	_paths.clear()
	CandyDialogue.clear_presets()


#* Queue a save at an undo point:
func _on_history_changed() -> void:
	#% A cleared history (presets just loaded, or closing) saves nothing:
	if _save_queued or not (CandyDialogue.can_undo() or CandyDialogue.can_redo()):
		return
	_save_queued = true
	_save_queued_presets.call_deferred()	#/ The edit is recorded before it's made


func _save_queued_presets() -> void:
	_save_queued = false
	save()


#* Write each preset file whose presets changed since read or written:
func save() -> void:
	if _paths.is_empty():
		return
	for conversation in CandyDialogue.PRESET_CONVERSATIONS:
		if _unreadable.has(conversation):
			continue
		var text := _file_text(conversation)
		if text == str(_saved.get(conversation, "")):
			continue
		var path := str(_paths[conversation])
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("CandyPresets: can't write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
			continue
		file.store_string(text)
		file.close()
		_saved[conversation] = text


func _file_text(conversation: String) -> String:
	var header: PackedStringArray = [
		"# Exported By: Candy Dialogue Creator",
		"# Creator Version: %s" % CandyProfiles.VERSION,
	]
	if conversation == CandyDialogue.USER_PRESETS:
		header.append("# Type: User Presets")
		header.append("# User: %s" % _user_name)
	else:
		header.append("# Type: Profile Presets")
		header.append("# User: %s" % _user_name)
		header.append("# Profile: %s" % _profile_name)
	var data := {conversation: CandyDialogue.preset_blocks(conversation), CandySymbolUpdater.SYMBOLS_KEY: CandyDialogue.symbols}
	return "\n".join(header) + "\n\n" + CandyVariantFile.stringify(data) + "\n"


#* Ask to update the preset files written with other symbols, then read them again:
func _ask_symbol_update() -> void:
	var paths: Array = []
	for conversation in _mismatched:
		paths.append(_paths[conversation])
	if paths.is_empty():
		return
	CandySymbolPrompt.ensure_files(self, paths, CandyLocale.t("loading these presets"), reload,
		CandyLocale.t("Cancel leaves these presets out until the profile is opened again. Their files aren't changed."))


#* Read a preset file, checking and reporting its variation names:
func _read_checked(conversation: String) -> Dictionary:
	var blocks := _read(conversation)
	if _mismatched.has(conversation):
		return {}
	var repair := CandyVariationRepair.check({conversation: blocks})
	CandyVariationReportDialog.open_report(repair, str(_paths.get(conversation, "")), true)
	#% Unfixable names leave the file's presets out:
	if repair.has_problems():
		_unreadable[conversation] = true
		return {}
	repair.apply()
	if repair.has_fixes():
		_repaired[conversation] = true
	return blocks


#* Read a preset file's blocks, { block: { "Text": [...] } }:
func _read(conversation: String) -> Dictionary:
	var path := str(_paths.get(conversation, ""))
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var data = _parse(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		_unreadable[conversation] = true
		push_warning("CandyPresets: can't read %s. It won't be overwritten." % path)
		return {}
	#% Other symbols - left out (and never overwritten) until updated:
	var file_symbols := CandySymbolUpdater.stored_symbols(data)
	if not file_symbols.is_empty() and not CandySymbolUpdater.same_symbols(file_symbols, CandySymbolUpdater.profile_symbols()):
		_unreadable[conversation] = true
		_mismatched[conversation] = true
		return {}

	#Ł The conversation's own key, or else the file's first conversation:
	var source = data.get(conversation)
	if not source is Dictionary:
		source = null
		for key in data:
			if data[key] is Dictionary:
				source = data[key]
				break
	if source == null:
		return {}

	var blocks := {}
	for block in source:
		var block_data = source[block]
		if not block_data is Dictionary:
			continue
		if not block_data.get(CandyDialogue.TEXT_KEY) is Array:
			block_data[CandyDialogue.TEXT_KEY] = []
		blocks[str(block)] = block_data
	return blocks


#* Parse a preset file, skipping its "#" header lines (neither parser accepts them):
func _parse(text: String) -> Variant:
	var body: PackedStringArray = []
	for line in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			body.append(line)
	var joined := "\n".join(body).strip_edges()
	if joined == "":
		return {}
	var data = str_to_var(joined)
	if data is Dictionary:
		return data
	data = JSON.parse_string(joined)
	if data is Dictionary:
		return data
	return null


#& Presets as buttons

func is_preset_id(id: String) -> bool:
	return id.begins_with(ID_PREFIX)


func make_id(conversation: String, block: String) -> String:
	var code := USER_CODE
	if conversation == CandyDialogue.PROFILE_PRESETS:
		code = PROFILE_CODE
	return ID_PREFIX + code + "|" + block


#* Get an id's [conversation, block] ([] if not a preset id):
func id_path(id: String) -> Array:
	if not is_preset_id(id):
		return []
	var parts := id.substr(ID_PREFIX.length()).split("|", true, 1)
	if parts.size() != 2:
		return []
	if parts[0] == USER_CODE:
		return [CandyDialogue.USER_PRESETS, parts[1]]
	if parts[0] == PROFILE_CODE:
		return [CandyDialogue.PROFILE_PRESETS, parts[1]]
	return []


func exists(id: String) -> bool:
	var path := id_path(id)
	return not path.is_empty() and CandyDialogue.has_block(path[0], path[1])


#* List every preset id - user presets first, each in Navigator order:
func all_ids() -> Array:
	var result: Array = []
	for conversation in CandyDialogue.PRESET_CONVERSATIONS:
		for block in CandyDialogue.block_names(conversation):
			result.append(make_id(conversation, str(block)))
	return result


#* Split a block name into [category, name]:
#? "[Greetings] Wave" -> ["Greetings", "Wave"].
func split_name(block: String) -> Array:
	var found := _category_regex.search(block)
	if found == null:
		return ["", block]		#/ No brackets, no category
	var category := found.get_string(1).strip_edges()
	var preset_name := found.get_string(2).strip_edges()
	if preset_name == "":
		preset_name = block
	return [category, preset_name]


func category_of(id: String) -> String:
	var path := id_path(id)
	if path.is_empty():
		return ""
	return str(split_name(str(path[1]))[0])


#* Get the button text (the block name without its category):
func button_label(id: String) -> String:
	var path := id_path(id)
	if path.is_empty():
		return id
	return str(split_name(str(path[1]))[1])


#* Get the settings lists' text:
func list_label(id: String) -> String:
	var path := id_path(id)
	if path.is_empty():
		return id
	var parts := split_name(str(path[1]))
	var other := CandyDialogue.PROFILE_PRESETS
	if path[0] == CandyDialogue.PROFILE_PRESETS:
		other = CandyDialogue.USER_PRESETS
	#% (U) / (P) in front when a user and a profile preset share it:
	for block in CandyDialogue.block_names(other):
		var other_parts := split_name(str(block))
		if other_parts[0] == parts[0] and other_parts[1] == parts[1]:
			if path[0] == CandyDialogue.USER_PRESETS:
				return "(U) " + str(parts[1])
			return "(P) " + str(parts[1])
	return str(parts[1])


func tooltip(id: String) -> String:
	var path := id_path(id)
	if path.is_empty():
		return ""
	var source := CandyLocale.t("User preset")
	if path[0] == CandyDialogue.PROFILE_PRESETS:
		source = CandyLocale.t("Profile preset")
	return CandyLocale.t("{source}: {preset}\nClick: insert after the selection\nCtrl+Click: insert before the selection").format(
		{"source": source, "preset": path[1]})


#* Get the id after CandyDialogue.blocks_renamed:
func renamed_id(id: String, renames: Array) -> String:
	var path := id_path(id)
	if path.is_empty():
		return id
	for rename in renames:
		var old_path: Array = rename[0]
		var new_path: Array = rename[1]
		if str(old_path[0]) == path[0] and str(old_path[1]) == path[1]:
			if not CandyDialogue.is_preset_conversation(str(new_path[0])):
				return ""		#/ Moved out of the preset conversations
			return make_id(str(new_path[0]), str(new_path[1]))
	return id

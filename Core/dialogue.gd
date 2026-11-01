#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueModel
extends Node

signal dialogue_changed
#^ The selection of a view changed:
signal selection_changed(reference: String)
signal clipboard_changed
#^ The active line of a view changed:
signal active_changed(reference: String)
#^ Another view became the current one:
signal current_reference_changed(reference: String)
#^ One line's data changed, structure unchanged (repaint one row):
signal line_changed(path: Array)
#^ Blocks renamed or moved - [[old_path, new_path], ...], paths being [conversation, block]:
signal blocks_renamed(renames: Array)
#^ A step was recorded, undone or redone, or the history cleared:
signal history_changed

enum Kind { CONVERSATION, BLOCK, LINE }
#^ Navigator line display (describe_line()). CUSTOM picks one per line type:
enum DisplayMode { FULL, SHORT, META, CUSTOM }

#^ Custom mode's profile setting: { line type: "full" | "short" | "meta" }. Unlisted types show Full:
const LINE_MODES_SETTING := "navigator_line_modes"
#^ The Custom mode's values, as stored:
const LINE_MODES := {"full": DisplayMode.FULL, "short": DisplayMode.SHORT, "meta": DisplayMode.META}
#^ A line's Meta Reference: data["Meta"]["Meta_Reference"] (see Defaults/line_meta.txt):
const META_DATA_KEY := "Meta"
const META_REFERENCE_KEY := "Meta_Reference"

const TEXT_KEY := "Text"
#^ Also the top-level keys of user_presets.txt and profile_presets.txt:
const USER_PRESETS := "USER PRESETS"
const PROFILE_PRESETS := "PROFILE PRESETS"
const PRESET_CONVERSATIONS := [USER_PRESETS, PROFILE_PRESETS]
#^ Key inside a line for editor-side data (filters); Candy DE ignores it:
const META_KEY := "CandyDC"
#^ Path steps into a named entry {"Hub_1" = {...}} - "@name" is its key, "@entry" its value:
#? Names never appear in paths, so they survive renames:
#?   ["Categories", 0, "@entry", "Choices", 2, "@entry", "Label"]
const ENTRY_NAME := "@name"
const ENTRY_VALUE := "@entry"
#^ Reference of a Navigator or Editor given none:
const DEFAULT_REFERENCE := "1"

var dialogue: Dictionary = {}
#^ The Candy DE symbols the dialogue, presets and clipboard are written with (CandySymbolUpdater's keys):
#? The profile's when it opens. They differ only once the profile's change: then every file
#? operation asks to update them first (CandySymbolPrompt), so files only ever meet these.
var symbols: Dictionary = {}
#^ { USER_PRESETS = { block = {...} }, PROFILE_PRESETS = { block = {...} } }:
var presets: Dictionary = {USER_PRESETS: {}, PROFILE_PRESETS: {}}
var clipboard: Array = []
var clipboard_kind: int = Kind.LINE
#^ The view `selection` and `active_path` belong to:
var current_reference: String = DEFAULT_REFERENCE
#^ Current view's paths, possibly of mixed kinds:
#? Operations act on the most granular kind: lines, then blocks, then conversations.
var selection: Array:
	get:
		return _view(current_reference)["selection"]
	set(value):
		_view(current_reference)["selection"] = value
#^ Current view's active line, the one its Editors edit (the last clicked):
var active_path: Array:
	get:
		return _view(current_reference)["active"]
	set(value):
		_view(current_reference)["active"] = value
#^ { reference = { "selection" = Array, "active" = Array } }:
var _views: Dictionary = {}
#^ Views start with the first block selected (from a profile opening until the dialogue is replaced):
var _start_on_first_block := false
var _history := CandyDialogueHistory.new(self)
#^ Last id new_typing_id() gave:
var _last_typing_id := 0


func _ready() -> void:
	_history.changed.connect(func(): history_changed.emit())
	#! Needs CandySchemas loaded first (project.godot): set_dialogue() normalizes lines.
	if dialogue.is_empty():
		set_dialogue(_default_dialogue())
	CandyProfiles.profile_closed.connect(_on_profile_closed)
	CandyProfiles.profile_opened.connect(_on_profile_opened)


func _on_profile_opened(_user: String, _profile: String) -> void:
	symbols = CandySymbolUpdater.profile_symbols()
	_select_first_block_in_views()


#* Reset dialogue and clipboard when the profile closes:
func _on_profile_closed() -> void:
	set_dialogue(_default_dialogue())
	clipboard.clear()
	clipboard_kind = Kind.LINE
	clipboard_changed.emit()


#& Reading

#* Load a dialogue from a file:
func load_dialogue(data: Dictionary) -> CandyVariationRepair:
	var repair := CandyVariationRepair.check(data)
	#% Load only if every broken variation name can be fixed:
	if not repair.has_problems():
		repair.apply()
		set_dialogue(data)
	return repair			#/ For the loader to report


#* Replace the dialogue:
#? data must use the symbols (files are updated to them before they're read).
func set_dialogue(data: Dictionary) -> void:
	_history.clear()
	_start_on_first_block = false
	dialogue = data
	normalize_all()
	for reference in _views:
		_views[reference]["selection"] = []
		_views[reference]["active"] = []
	dialogue_changed.emit()
	for reference in _views.keys():
		selection_changed.emit(reference)


#* Replace the dialogue with an import merged into it (CandyDialogueMerge):
#? Lines must already be complete: not normalized here.
func merge_dialogue(data: Dictionary) -> void:
	_history.clear()
	var anchors := _anchor_views()
	dialogue = data
	_follow_views(anchors)
	_finish_edit(anchors)


#& Symbols

#* Whether the dialogue, presets and clipboard use the profile's symbols:
func symbols_match() -> bool:
	return CandySymbolUpdater.same_symbols(symbols, CandySymbolUpdater.profile_symbols())


#* Rewrite the dialogue, presets and clipboard with the profile's symbols:
#? Clears the undo history: undoing past it would bring the old symbols back.
#? Returns the updater, for its notes.
func update_symbols() -> CandySymbolUpdater:
	var profile := CandySymbolUpdater.profile_symbols()
	var updater := CandySymbolUpdater.new(symbols, profile)
	_history.clear()
	dialogue = updater.update_conversations(dialogue)
	for conversation in PRESET_CONVERSATIONS:
		if presets.get(conversation) is Dictionary:
			presets[conversation] = updater.update_conversations({conversation: presets[conversation]})[conversation]
	for entry in clipboard:
		match clipboard_kind:
			Kind.LINE:
				entry[1] = updater.update_line(entry[1])
			Kind.BLOCK:
				entry[1] = updater.update_conversations({"": {entry[0]: entry[1]}})[""][entry[0]]
			Kind.CONVERSATION:
				entry[1] = updater.update_conversations({entry[0]: entry[1]})[entry[0]]
	symbols = profile
	#? Every path still leads to the same line, but each line is a new Dictionary: views read theirs again.
	dialogue_changed.emit()
	for reference in _views.keys():
		selection_changed.emit(reference)
		active_changed.emit(reference)
	return updater


#* Replace the dialogue with the default one, keeping presets:
#? File > New Dialogue goes through CandySaves.new_dialogue() instead.
func new_dialogue() -> void:
	set_dialogue(_default_dialogue())


#* Real conversations only (see preset_conversation_names()):
func conversation_names() -> Array:
	return dialogue.keys()


func preset_conversation_names() -> Array:
	return PRESET_CONVERSATIONS.duplicate()


func is_preset_conversation(conversation: String) -> bool:
	return PRESET_CONVERSATIONS.has(conversation)


func block_names(conversation: String) -> Array:
	var conv = _conv(conversation)
	if conv is Dictionary:
		return conv.keys()
	return []


func get_block(conversation: String, block: String) -> Dictionary:
	var conv = _conv(conversation)
	if conv is Dictionary and conv.get(block) is Dictionary:
		return conv[block]
	return {}


#* A block's lines, live (edit in place):
func lines(conversation: String, block: String) -> Array:
	var data := get_block(conversation, block)
	if not data.has(TEXT_KEY) or not data[TEXT_KEY] is Array:
		return []
	return data[TEXT_KEY]


#* The line at a line path:
#? Nested command: [conversation, block, index, "Commands", "Media_Play"].
func line_at(path: Array) -> Dictionary:
	if path.size() < 3:
		return {}
	var array := lines(path[0], path[1])
	var index := int(path[2])
	if index < 0 or index >= array.size():
		return {}
	if path.size() == 3:
		return array[index]
	var data = line_data(array[index])
	#Ł Nested command's steps (array indices for text event lines):
	for step in path.slice(3):
		if data is Dictionary and data.has(step):
			data = data[step]
		elif data is Array and step is int and step >= 0 and step < data.size():
			data = data[step]
		else:
			return {}
	#? { type = live data }, so nested commands edit like lines.
	if data is Dictionary:
		return {str(path[path.size() - 1]): data}
	return {}


#* Whether path is a line path, top-level or nested:
func is_line_path(path: Array) -> bool:
	return path.size() >= 3


#* The top-level line a line path is in:
func root_line_path(path: Array) -> Array:
	return path.slice(0, 3)


#* Emit line_changed, for the root line too when nested:
func _emit_line_changed(line_path: Array) -> void:
	line_changed.emit(line_path)
	if line_path.size() > 3:
		line_changed.emit(root_line_path(line_path))


#* A line's type, its one key ("Comment", "Spoken_Line"):
func line_type(line: Dictionary) -> String:
	for key in line:
		return str(key)
	return ""


func line_data(line: Dictionary) -> Dictionary:
	var type := line_type(line)
	if line.get(type) is Dictionary:
		return line[type]
	return {}


func path_kind(path: Array) -> int:
	match path.size():
		1: return Kind.CONVERSATION
		2: return Kind.BLOCK
		_: return Kind.LINE


func exists(path: Array) -> bool:
	match path.size():
		1: return has_conversation(path[0])
		2: return has_block(path[0], path[1])
		3: return int(path[2]) < lines(path[0], path[1]).size()
	if path.size() > 3:
		return not line_at(path).is_empty()
	return false


#& Views

#* A typed reference as views are keyed - trimmed, DEFAULT_REFERENCE if empty:
func clean_reference(reference: String) -> String:
	var text := reference.strip_edges()
	if text == "":
		return DEFAULT_REFERENCE
	return text


#* Make a view the current one:
func use_reference(reference: String) -> void:
	var key := clean_reference(reference)
	if key == current_reference:
		return
	current_reference = key
	current_reference_changed.emit(key)


#* A view's selection (read-only: select through the current view):
func selection_of(reference: String) -> Array:
	return _view(reference)["selection"]


#* A view's active line, [] for none:
func active_path_of(reference: String) -> Array:
	return _view(reference)["active"]


func _view(reference: String) -> Dictionary:
	var key := clean_reference(reference)
	if not _views.has(key):
		var start_selection: Array = []
		if _start_on_first_block:
			start_selection = _first_block_selection()
		_views[key] = {"selection": start_selection, "active": []}
	return _views[key]


#* Select the first block in every view with nothing selected, and in the views made from now on:
func _select_first_block_in_views() -> void:
	_start_on_first_block = true
	for reference in _views.keys():
		if _views[reference]["selection"].is_empty():
			_views[reference]["selection"] = _first_block_selection()
			selection_changed.emit(reference)


#* The first block of the dialogue, as a selection ([] if it has none):
func _first_block_selection() -> Array:
	for conversation in conversation_names():
		var blocks := block_names(conversation)
		if not blocks.is_empty():
			return [[str(conversation), str(blocks[0])]]
	return []


#* Anchor every view's paths to their items, before an edit:
func _anchor_views() -> Dictionary:
	var anchors := {}
	for reference in _views:
		var view: Dictionary = _views[reference]
		var items: Array = []
		for path in view["selection"]:
			items.append([path.duplicate(), _item_at(path)])
		var active: Array = view["active"]
		var root := root_line_path(active)
		var root_line = null
		if is_line_path(root):
			root_line = _item_at(root)
		anchors[reference] = {"selection": items, "active": active.duplicate(), "active_line": root_line}
	return anchors			#/ For _follow_views() and _finish_edit()


#* Point every view's paths at where their anchored items are now:
func _follow_views(anchors: Dictionary) -> void:
	#Ł Find moved items in one pass, by identity:
	var missing: Array = []
	for reference in anchors:
		var anchor: Dictionary = anchors[reference]
		for entry in anchor["selection"]:
			if entry[1] != null and not _is_at(entry[1], entry[0]):
				missing.append(entry[1])
		var line = anchor["active_line"]
		if line != null and not _is_at(line, root_line_path(anchor["active"])):
			missing.append(line)
	var found := _find_items(missing)

	for reference in anchors:
		var anchor: Dictionary = anchors[reference]
		var view := _view(reference)
		var kept: Array = []
		for entry in anchor["selection"]:
			var path := _followed_path(entry[1], entry[0], missing, found)
			#% Conversation or block not found keeps its path if it still exists (undo restores copies):
			if path.is_empty() and path_kind(entry[0]) != Kind.LINE and exists(entry[0]):
				path = entry[0]
			if not path.is_empty() and not _has_path(kept, path):
				kept.append(path)
		view["selection"] = kept
		var active: Array = anchor["active"]
		var root_line = anchor["active_line"]
		if root_line == null:
			continue
		var root := _followed_path(root_line, root_line_path(active), missing, found)
		if not root.is_empty():
			root.append_array(active.slice(3))
		view["active"] = root


#* Where item is now, [] if nowhere:
func _followed_path(item: Variant, path: Array, missing: Array, found: Array) -> Array:
	if item == null:
		return []
	if _is_at(item, path):
		return path.duplicate()
	for i in missing.size():
		if is_same(missing[i], item):
			return found[i].duplicate()
	return []


#* The live item a selection path leads to (blocks dict, block data or line), or null:
func _item_at(path: Array) -> Variant:
	if path.is_empty() or path.size() > 3 or not exists(path):
		return null
	match path.size():
		1:
			return _conv(str(path[0]))
		2:
			return _conv(str(path[0]))[path[1]]
	return lines(path[0], path[1])[int(path[2])]


func _is_at(item: Variant, path: Array) -> bool:
	var current = _item_at(path)
	return current != null and is_same(current, item)


#* Find items in one walk through dialogue and presets:
func _find_items(items: Array) -> Array:
	var found: Array = []
	for i in items.size():
		found.append([])
	if items.is_empty():
		return found
	for conversation in _all_conversation_names():
		_match_item(items, found, _conv(conversation), [conversation])
		for block in block_names(conversation):
			_match_item(items, found, _conv(conversation)[block], [conversation, block])
			var array := lines(conversation, block)
			for i in array.size():
				_match_item(items, found, array[i], [conversation, block, i])
	return found			#/ One path per item, [] if not found


func _match_item(items: Array, found: Array, item: Variant, path: Array) -> void:
	for i in items.size():
		if found[i].is_empty() and is_same(items[i], item):
			found[i] = path.duplicate()


#* End an anchored edit - rebuild views, then emit view changes:
func _finish_edit(anchors: Dictionary) -> void:
	dialogue_changed.emit()
	_emit_view_changes(anchors)


#* Emit selection_changed / active_changed for views changed since anchors:
func _emit_view_changes(anchors: Dictionary) -> void:
	for reference in _views.keys():
		var view: Dictionary = _views[reference]
		var old_selection: Array = []
		var old_active: Array = []
		if anchors.has(reference):
			for entry in anchors[reference]["selection"]:
				old_selection.append(entry[0])
			old_active = anchors[reference]["active"]
		if not _same_paths(old_selection, view["selection"]):
			selection_changed.emit(reference)
		if not _same_path(old_active, view["active"]):
			active_changed.emit(reference)


#& Selection

#* Set the current view's selection:
func set_selection(paths: Array) -> void:
	#Ł Not an undo step - keep the last step's selection first:
	_history.seal()
	selection = paths.duplicate()
	selection_changed.emit(current_reference)


func is_selected(path: Array, reference: String) -> bool:
	return _has_path(selection_of(reference), path)


func toggle_selected(path: Array) -> void:
	_history.seal()
	for i in selection.size():
		if _same_path(selection[i], path):
			selection.remove_at(i)
			selection_changed.emit(current_reference)
			return
	selection.append(path.duplicate())
	selection_changed.emit(current_reference)


#* The most granular kind selected:
func selected_kind() -> int:
	var kind := -1
	for path in selection:
		var k := path_kind(path)
		if kind == -1 or k > kind:
			kind = k
	if kind != -1:
		return kind
	return Kind.LINE


func selected_paths_of_kind(kind: int) -> Array:
	var result: Array = []
	for path in selection:
		if path_kind(path) == kind and exists(path):
			result.append(path)
	return _sorted_paths(result)


#& Clipboard

func copy_selection() -> void:
	var kind := selected_kind()
	var paths := selected_paths_of_kind(kind)
	if paths.is_empty():
		return
	var copied: Array = []
	for path in paths:
		match kind:
			Kind.LINE:
				copied.append(["", line_at(path).duplicate(true)])
			Kind.BLOCK:
				copied.append([path[1], get_block(path[0], path[1]).duplicate(true)])
			Kind.CONVERSATION:
				if not is_preset_conversation(path[0]):
					copied.append([path[0], dialogue[path[0]].duplicate(true)])
	if copied.is_empty():
		return  #/ Only presets selected
	clipboard_kind = kind
	clipboard = copied
	clipboard_changed.emit()


func cut_selection() -> void:
	copy_selection()
	_delete_selection(CandyLocale.t("Cut %s"))


func delete_selection() -> void:
	_delete_selection(CandyLocale.t("Delete %s"))


#* Delete the selection:
func _delete_selection(label: String) -> void:
	var kind := selected_kind()
	var paths := selected_paths_of_kind(kind)
	if kind == Kind.CONVERSATION:
		paths = _without_presets(paths)
	if paths.is_empty():
		return
	_record_structure(label % _describe_paths(paths))
	var anchors := _anchor_views()
	match kind:
		Kind.LINE:
			_remove_lines(paths)
		Kind.BLOCK:
			for path in paths:
				_conv(path[0]).erase(path[1])
		Kind.CONVERSATION:
			for path in paths:
				if not is_preset_conversation(path[0]):
					dialogue.erase(path[0])
	_follow_views(anchors)
	selection = []
	_finish_edit(anchors)


func duplicate_selection() -> void:
	var kind := selected_kind()
	var paths := selected_paths_of_kind(kind)
	if kind == Kind.CONVERSATION:
		paths = _without_presets(paths)
	if paths.is_empty():
		return
	_record_structure(CandyLocale.t("Duplicate %s") % _describe_paths(paths))
	var anchors := _anchor_views()

	match kind:
		Kind.LINE:
			#Ł Copies go after each block's last selected line:
			var by_block := {}
			for path in paths:
				var key := "%s/%s" % [path[0], path[1]]
				if not by_block.has(key):
					by_block[key] = {"conversation": path[0], "block": path[1], "indices": []}
				by_block[key]["indices"].append(int(path[2]))
			for key in by_block:
				var group: Dictionary = by_block[key]
				var indices: Array = group["indices"]
				indices.sort()
				var array := lines(group["conversation"], group["block"])
				var at := int(indices[indices.size() - 1]) + 1
				for i in indices.size():
					array.insert(at + i, array[int(indices[i])].duplicate(true))
		Kind.BLOCK:
			for path in paths:
				var conversation: String = path[0]
				var taken := block_names(conversation)
				var new_name := unique_name(taken, path[1])
				var index := taken.find(path[1])
				_set_conv(conversation, _insert_keys(_conv(conversation),
					[[new_name, get_block(conversation, path[1]).duplicate(true)]], index + 1))
		Kind.CONVERSATION:
			for path in paths:
				if is_preset_conversation(path[0]):
					continue
				var taken := conversation_names()
				var new_name := unique_name(taken, path[0])
				var index := taken.find(path[0])
				dialogue = _insert_keys(dialogue, [[new_name, dialogue[path[0]].duplicate(true)]], index + 1)

	_follow_views(anchors)
	_finish_edit(anchors)


func can_paste() -> bool:
	if clipboard.is_empty() or selection.is_empty():
		return false
	var target := selected_kind()
	match clipboard_kind:
		Kind.LINE:
			return target == Kind.LINE or target == Kind.BLOCK
		Kind.BLOCK:
			return target == Kind.BLOCK or target == Kind.CONVERSATION
		Kind.CONVERSATION:
			#% Real conversations only:
			if target != Kind.CONVERSATION:
				return false
			for path in selected_paths_of_kind(target):
				if not is_preset_conversation(path[0]):
					return true
	return false


#* Paste after each selected item:
func paste() -> void:
	if not can_paste():
		return
	var target := selected_kind()
	var paths := selected_paths_of_kind(target)
	_record_structure(CandyLocale.t("Paste %s") % _describe_count(clipboard.size(), clipboard_kind))
	var anchors := _anchor_views()

	match clipboard_kind:
		Kind.LINE:
			#¦ 1. Under each selected line, or atop each selected block:
			if target == Kind.LINE:
				#? Descending, so insertions don't shift later targets.
				for i in range(paths.size() - 1, -1, -1):
					var path: Array = paths[i]
					_insert_lines(path[0], path[1], int(path[2]) + 1)
			else:
				for path in paths:
					_insert_lines(path[0], path[1], 0)
		Kind.BLOCK:
			#¦ 2. Under each selected block, or atop each selected conversation:
			if target == Kind.BLOCK:
				for path in paths:
					var index := block_names(path[0]).find(path[1])
					_insert_blocks(path[0], index + 1)
			else:
				for path in paths:
					_insert_blocks(path[0], 0)
		Kind.CONVERSATION:
			for path in paths:
				if is_preset_conversation(path[0]):
					continue
				var index := conversation_names().find(path[0])
				_insert_conversations(index + 1)

	_follow_views(anchors)
	_finish_edit(anchors)


func _insert_lines(conversation: String, block: String, index: int) -> void:
	var array := lines(conversation, block)
	index = clampi(index, 0, array.size())
	for i in clipboard.size():
		array.insert(index + i, clipboard[i][1].duplicate(true))


func _insert_blocks(conversation: String, index: int) -> void:
	var taken := block_names(conversation)
	var entries: Array = []
	for entry in clipboard:
		var new_name := unique_name(taken, str(entry[0]))
		taken.append(new_name)
		entries.append([new_name, entry[1].duplicate(true)])
	_set_conv(conversation, _insert_keys(_conv(conversation), entries, index))


func _insert_conversations(index: int) -> void:
	var taken := conversation_names()
	var entries: Array = []
	for entry in clipboard:
		var new_name := unique_name(taken, str(entry[0]))
		taken.append(new_name)
		entries.append([new_name, entry[1].duplicate(true)])
	dialogue = _insert_keys(dialogue, entries, index)


#& Moving (drag and drop)

func move_lines(paths: Array, dest_conversation: String, dest_block: String, dest_index: int) -> void:
	var sorted_paths := _sorted_paths(paths)
	if sorted_paths.is_empty():
		return

	_record_structure(CandyLocale.t("Move %s") % _describe_paths(sorted_paths))
	var anchors := _anchor_views()
	var moving: Array = []
	for path in sorted_paths:
		moving.append(line_at(path))

	#Ł Lines removed above the target shift it up:
	var before := 0
	for path in sorted_paths:
		if path[0] == dest_conversation and path[1] == dest_block and int(path[2]) < dest_index:
			before += 1

	_remove_lines(sorted_paths)

	var array := lines(dest_conversation, dest_block)
	var at := clampi(dest_index - before, 0, array.size())
	for i in moving.size():
		array.insert(at + i, moving[i])

	_follow_views(anchors)
	var moved: Array = []
	for i in moving.size():
		moved.append([dest_conversation, dest_block, at + i])
	selection = moved
	_finish_edit(anchors)


func move_blocks(paths: Array, dest_conversation: String, dest_index: int) -> void:
	var sorted_paths := _sorted_paths(paths)
	if sorted_paths.is_empty():
		return

	_record_structure(CandyLocale.t("Move %s") % _describe_paths(sorted_paths))
	var anchors := _anchor_views()
	var moving: Array = []
	for path in sorted_paths:
		moving.append([path[1], get_block(path[0], path[1])])

	var before := 0
	var dest_keys := block_names(dest_conversation)
	for path in sorted_paths:
		if path[0] == dest_conversation:
			var index := dest_keys.find(path[1])
			if index >= 0 and index < dest_index:
				before += 1

	for path in sorted_paths:
		_conv(path[0]).erase(path[1])

	#Ł Keep names unique in the destination:
	var taken := block_names(dest_conversation)
	var entries: Array = []
	var renames: Array = []
	for i in moving.size():
		var entry: Array = moving[i]
		var new_name := unique_name(taken, str(entry[0]))
		taken.append(new_name)
		entries.append([new_name, entry[1]])
		var old_path := [str(sorted_paths[i][0]), str(entry[0])]
		var new_path := [dest_conversation, new_name]
		if not _same_path(old_path, new_path):
			renames.append([old_path, new_path])

	_set_conv(dest_conversation, _insert_keys(_conv(dest_conversation), entries, dest_index - before))

	_follow_views(anchors)
	var moved: Array = []
	for entry in entries:
		moved.append([dest_conversation, entry[0]])
	selection = moved
	if not renames.is_empty():
		_history.note_renames(renames)
		blocks_renamed.emit(renames)
	_finish_edit(anchors)


func move_conversations(paths: Array, dest_index: int) -> void:
	var real_paths: Array = []
	for path in paths:
		if not is_preset_conversation(path[0]):
			real_paths.append(path)
	var sorted_paths := _sorted_paths(real_paths)
	if sorted_paths.is_empty():
		return

	_record_structure(CandyLocale.t("Move %s") % _describe_paths(sorted_paths))
	var anchors := _anchor_views()
	var moving: Array = []
	var before := 0
	var keys := conversation_names()
	for path in sorted_paths:
		moving.append([path[0], dialogue[path[0]]])
		if keys.find(path[0]) < dest_index:
			before += 1

	for path in sorted_paths:
		dialogue.erase(path[0])

	dialogue = _insert_keys(dialogue, moving, dest_index - before)

	_follow_views(anchors)
	var moved: Array = []
	for entry in moving:
		moved.append([entry[0]])
	selection = moved
	_finish_edit(anchors)


#& Creating

#* Whether a conversation exists (presets included, so their names stay reserved):
func has_conversation(conversation_name: String) -> bool:
	return dialogue.has(conversation_name) or is_preset_conversation(conversation_name)


func has_block(conversation: String, block_name: String) -> bool:
	var conv = _conv(conversation)
	return conv is Dictionary and conv.has(block_name)


#* The conversation the selection is in, "" if none:
func current_conversation() -> String:
	for path in selection:
		if path.size() > 0:
			return path[0]
	return ""


#* A new line of type, with its schema's defaults:
func create_line(type: String) -> Dictionary:
	if CandySchemas.has_schema(type):
		return CandySchemas.default_line(type)
	return CandyLineTemplates.create(type)


#* Add a conversation with one empty block (block_default_name setting):
func add_conversation(conversation_name: String) -> bool:
	if conversation_name == "" or has_conversation(conversation_name):
		return false
	var block_name := str(CandyProfiles.get_setting("block_default_name", "Block_1"))
	_record_structure(CandyLocale.t("Add conversation %s") % conversation_name)
	var anchors := _anchor_views()
	dialogue[conversation_name] = {block_name: {TEXT_KEY: []}}
	selection = [[conversation_name]]
	_finish_edit(anchors)
	return true


func add_block(conversation: String, block_name: String) -> bool:
	if not has_conversation(conversation) or block_name == "" or has_block(conversation, block_name):
		return false
	_record_structure(CandyLocale.t("Add block %s") % _place([conversation, block_name]))
	var anchors := _anchor_views()
	var blocks: Dictionary = _conv(conversation)
	blocks[block_name] = {TEXT_KEY: []}
	selection = [[conversation, block_name]]
	_finish_edit(anchors)
	return true


#* Insert a new line of type at each selected item, and select them:
func add_lines(type: String, before: bool) -> int:
	return _insert_at_selection([create_line(type)], before, CandyLocale.t("Add %s") % type)			#/ How many lines were added


#* Insert a copy of a preset's lines wherever add_lines() would:
func insert_preset(conversation: String, block: String, before: bool) -> int:
	if not is_preset_conversation(conversation) or not has_block(conversation, block):
		return 0
	var source := lines(conversation, block)
	if source.is_empty():
		return 0
	#Ł Copy first - the selection may be inside this preset:
	return _insert_at_selection(source.duplicate(true), before, CandyLocale.t("Insert preset %s") % block)			#/ How many copies were made


#* Insert copies of new_lines at each selected item (see add_lines()):
func _insert_at_selection(new_lines: Array, before: bool, label: String) -> int:
	var kind := selected_kind()
	var paths := selected_paths_of_kind(kind)
	if paths.is_empty() or new_lines.is_empty():
		return 0

	#@ Step 1 - Targets, [conversation, block, index] in document order:
	var targets: Array = []
	for path in paths:
		match kind:
			Kind.LINE:
				var index := int(path[2]) + 1
				if before:
					index = int(path[2])
				targets.append([path[0], path[1], index])
			Kind.BLOCK:
				var index := lines(path[0], path[1]).size()
				if before:
					index = 0
				targets.append([path[0], path[1], index])
			Kind.CONVERSATION:
				#Ł End of its last block, or top of its first:
				var blocks := block_names(path[0])
				if blocks.is_empty():
					continue
				var block: String = blocks[blocks.size() - 1]
				if before:
					block = blocks[0]
				var index := lines(path[0], block).size()
				if before:
					index = 0
				targets.append([path[0], block, index])
	if targets.is_empty():
		return 0

	if targets.size() == 1:
		label = CandyLocale.t("{action} ({place})").format({"action": label, "place": _place([targets[0][0], targets[0][1]])})
	else:
		label = CandyLocale.tn("{action} ({count} place)", "{action} ({count} places)", targets.size()).format({"action": label, "count": targets.size()})
	_record_structure(label)
	var anchors := _anchor_views()
	#@ Step 2 - Insert, descending so insertions don't shift later targets:
	var count := new_lines.size()
	for i in range(targets.size() - 1, -1, -1):
		var target: Array = targets[i]
		var array := lines(target[0], target[1])
		var at := clampi(int(target[2]), 0, array.size())
		for j in count:
			array.insert(at + j, new_lines[j].duplicate(true))

	_follow_views(anchors)
	#@ Step 3 - Select each copy's last line, shifted by the copies above it:
	var added: Array = []
	for target in targets:
		var shift := 0
		for other in targets:
			if other != target and other[0] == target[0] and other[1] == target[1] \
					and int(other[2]) < int(target[2]):
				shift += count
		added.append([target[0], target[1], int(target[2]) + shift + count - 1])
	selection = added
	#Ł Show the last new line in the Editor:
	active_path = added[added.size() - 1].duplicate()
	_finish_edit(anchors)
	return targets.size()


#& Active line and field editing

#* Set the current view's active line:
func set_active_path(path: Array) -> void:
	if _same_path(active_path, path):
		return
	_history.seal()
	active_path = path.duplicate()
	active_changed.emit(current_reference)


func active_line() -> Dictionary:
	return line_at(active_path)


#* A value in a line's data:
#? field_path, e.g. ["Finish", "Type"], ["Categories", 0, "@entry", "Label"].
func get_field(line_path: Array, field_path: Array, default_value: Variant = "") -> Variant:
	if field_path.is_empty():
		return line_data(line_at(line_path))
	var container = _resolve_container(line_data(line_at(line_path)), field_path)
	if container == null:
		return default_value
	var key = field_path[field_path.size() - 1]
	return _read_step(container, key, default_value)


func set_field(line_path: Array, field_path: Array, value: Variant) -> bool:
	if field_path.is_empty() or not exists(line_path):
		return false
	var container = _resolve_container(line_data(line_at(line_path)), field_path)
	if container == null:
		return false
	var key = field_path[field_path.size() - 1]

	#% "@name" renames the named entry:
	if str(key) == ENTRY_NAME:
		var list_name := _field_name(line_path, field_path.slice(0, field_path.size() - 2))
		return _rename_entry(container, str(value), line_path, _line_label(CandyLocale.t("Rename %s entry") % list_name, line_path))

	var label := _line_label(CandyLocale.t("Edit %s") % _field_name(line_path, field_path), line_path)
	if container is Dictionary:
		if container.get(key) == value:
			return false
		_record_line(line_path, label)
		container[key] = value
	elif container is Array and key is int and key >= 0 and key < container.size():
		if container[key] == value:
			return false
		_record_line(line_path, label)
		container[key] = value
	else:
		return false

	_emit_line_changed(line_path)
	return true



#* The Dictionary or Array holding field_path's value, or null:
func _resolve_container(data: Variant, field_path: Array) -> Variant:
	var current = data
	for i in field_path.size() - 1:
		current = _read_step(current, field_path[i], null)
		if current == null:
			return null
	if current is Dictionary or current is Array:
		return current
	return null


#* One field path step - a key, an index, "@name" or "@entry":
func _read_step(container: Variant, step: Variant, default_value: Variant) -> Variant:
	if str(step) == ENTRY_VALUE:
		if container is Dictionary and container.size() > 0:
			return container[container.keys()[0]]
		return default_value
	if str(step) == ENTRY_NAME:
		if container is Dictionary and container.size() > 0:
			return str(container.keys()[0])
		return default_value
	if container is Dictionary:
		return container.get(step, default_value)
	if container is Array and step is int and step >= 0 and step < container.size():
		return container[step]
	return default_value


#& Per-line editor data

#* Read a line's editor data (under META_KEY):
func get_line_meta(line_path: Array, key: String, default_value: Variant = null) -> Variant:
	#% Nested command - kept in its line's, so it never reaches the export:
	if line_path.size() > 3:
		return get_line_meta(root_line_path(line_path), _nested_meta_key(line_path, key), default_value)
	var meta = line_data(line_at(line_path)).get(META_KEY, {})
	if meta is Dictionary:
		return meta.get(key, default_value)
	return default_value


func set_line_meta(line_path: Array, key: String, value: Variant) -> void:
	if line_path.size() > 3:
		set_line_meta(root_line_path(line_path), _nested_meta_key(line_path, key), value)
		_emit_line_changed(line_path)
		return
	var data := line_data(line_at(line_path))
	if data.is_empty():
		return
	var meta = data.get(META_KEY, {})
	if not meta is Dictionary:
		meta = {}
	meta[key] = value
	data[META_KEY] = meta
	_emit_line_changed(line_path)


func erase_line_meta(line_path: Array, key: String) -> void:
	if line_path.size() > 3:
		erase_line_meta(root_line_path(line_path), _nested_meta_key(line_path, key))
		return
	var data := line_data(line_at(line_path))
	var meta = data.get(META_KEY, {})
	if not meta is Dictionary or not meta.has(key):
		return
	meta.erase(key)
	if meta.is_empty():
		data.erase(META_KEY)
	_emit_line_changed(line_path)


#& Repeatable entries

#* Names of a list's named entries (each unique in its list):
func entry_names(line_path: Array, list_path: Array) -> Array:
	var array = get_field(line_path, list_path, [])
	var names: Array = []
	if array is Array:
		for entry in array:
			if entry is Dictionary and entry.size() > 0:
				names.append(str(entry.keys()[0]))
	return names


#* Append an entry, returning its index or -1:
func add_entry(line_path: Array, list_path: Array, entry_name: String = "", template: Variant = null) -> int:
	var array = get_field(line_path, list_path, null)
	if not array is Array:
		return -1
	var value = {}
	if template is Dictionary or template is Array:
		value = template.duplicate(true)
	_record_line(line_path, _line_label(CandyLocale.t("Add %s entry") % _field_name(line_path, list_path), line_path))
	#% Named entry:
	if entry_name != "":
		array.append({unique_name(entry_names(line_path, list_path), entry_name): value})
	else:
		array.append(value)
	_emit_line_changed(line_path)
	return array.size() - 1


func remove_entry(line_path: Array, list_path: Array, index: int) -> bool:
	var array = get_field(line_path, list_path, null)
	if not array is Array or index < 0 or index >= array.size():
		return false
	_record_line(line_path, _line_label(CandyLocale.t("Remove %s entry") % _field_name(line_path, list_path), line_path))
	array.remove_at(index)
	_emit_line_changed(line_path)
	return true


func move_entry(line_path: Array, list_path: Array, index: int, to_index: int) -> bool:
	var array = get_field(line_path, list_path, null)
	if not array is Array:
		return false
	if index < 0 or index >= array.size() or to_index < 0 or to_index >= array.size() or index == to_index:
		return false
	_record_line(line_path, _line_label(CandyLocale.t("Move %s entry") % _field_name(line_path, list_path), line_path))
	var entry = array[index]
	array.remove_at(index)
	array.insert(to_index, entry)
	_emit_line_changed(line_path)
	return true


#* Rename a named entry, refusing duplicates in its list:
func set_entry_name(line_path: Array, list_path: Array, index: int, new_name: String) -> bool:
	new_name = new_name.strip_edges()
	var array = get_field(line_path, list_path, null)
	if new_name == "" or not array is Array or index < 0 or index >= array.size():
		return false
	var entry = array[index]
	if not entry is Dictionary or entry.is_empty():
		return false
	var old_name := str(entry.keys()[0])
	if old_name == new_name:
		return false
	var names := entry_names(line_path, list_path)
	names.remove_at(index)
	if names.has(new_name):
		return false
	var label := _line_label(CandyLocale.t("Rename %s entry") % _field_name(line_path, list_path), line_path)
	return _rename_entry(entry, new_name, line_path, label)


#* Rename a named entry's key:
func _rename_entry(entry: Variant, new_name: String, line_path: Array, label: String) -> bool:
	if not entry is Dictionary or entry.is_empty():
		return false
	var old_name := str(entry.keys()[0])
	if old_name == new_name or new_name == "":
		return false
	_record_line(line_path, label)
	var value = entry[old_name]
	entry.clear()
	entry[new_name] = value
	_emit_line_changed(line_path)
	return true


#& Map entries

#? A map is a dictionary keyed by user-named entries (e.g. Media_Play's Players). map_path
#? leads to it in the line's data ([] = the data itself). Key order is Candy DE's run order.
#? META_KEY is never an entry and stays last.

func map_keys(line_path: Array, map_path: Array) -> Array:
	var map = _map_at(line_path, map_path)
	var keys: Array = []
	if map is Dictionary:
		for key in map:
			if str(key) != META_KEY:
				keys.append(str(key))
	return keys


#* Append an entry named after base_name (made unique), returning its key or "":
func add_map_entry(line_path: Array, map_path: Array, base_name: String, template: Variant = null) -> String:
	var map = _map_at(line_path, map_path)
	if not map is Dictionary:
		return ""
	var taken := map_keys(line_path, map_path)
	taken.append(META_KEY)
	var key := unique_name(taken, base_name)
	var value := {}
	if template is Dictionary:
		value = template.duplicate(true)
	_record_line(line_path, _line_label(CandyLocale.t("Add %s entry") % _field_name(line_path, map_path), line_path))
	var entries := _map_entries(map)
	entries.append([key, value])
	_refill_map(map, entries)
	_emit_line_changed(line_path)
	return key


func remove_map_entry(line_path: Array, map_path: Array, key: String) -> bool:
	var map = _map_at(line_path, map_path)
	if not map is Dictionary or key == META_KEY or not map.has(key):
		return false
	_record_line(line_path, _line_label(CandyLocale.t("Remove {field} entry {entry}").format({"field": _field_name(line_path, map_path), "entry": key}), line_path))
	map.erase(key)
	_emit_line_changed(line_path)
	return true


func move_map_entry(line_path: Array, map_path: Array, key: String, to_index: int) -> bool:
	var map = _map_at(line_path, map_path)
	if not map is Dictionary:
		return false
	var entries := _map_entries(map)
	var index := -1
	for i in entries.size():
		if entries[i][0] == key:
			index = i
	if index < 0 or to_index < 0 or to_index >= entries.size() or index == to_index:
		return false
	_record_line(line_path, _line_label(CandyLocale.t("Move {field} entry {entry}").format({"field": _field_name(line_path, map_path), "entry": key}), line_path))
	var entry = entries[index]
	entries.remove_at(index)
	entries.insert(to_index, entry)
	_refill_map(map, entries)
	_emit_line_changed(line_path)
	return true


#* Rename an entry in place, refusing empty, taken or META_KEY names:
func rename_map_entry(line_path: Array, map_path: Array, key: String, new_key: String) -> bool:
	new_key = new_key.strip_edges()
	var map = _map_at(line_path, map_path)
	if not map is Dictionary or not map.has(key):
		return false
	if new_key == "" or new_key == key or new_key == META_KEY or map.has(new_key):
		return false
	var map_name := _field_name(line_path, map_path)
	_record_line(line_path, _line_label(CandyLocale.t("Rename {field} entry {entry} to {name}").format({"field": map_name, "entry": key, "name": new_key}), line_path))
	var entries := _map_entries(map)
	for entry in entries:
		if entry[0] == key:
			entry[0] = new_key
	_refill_map(map, entries)
	_emit_line_changed(line_path)
	return true


func _map_at(line_path: Array, map_path: Array) -> Variant:
	if not exists(line_path):
		return null
	var map = get_field(line_path, map_path, null)
	if map is Dictionary:
		return map
	return null


#* A map's entries as [[key, value], ...], in order, without META_KEY:
func _map_entries(map: Dictionary) -> Array:
	var entries: Array = []
	for key in map:
		if str(key) != META_KEY:
			entries.append([str(key), map[key]])
	return entries


#* Refill the map in place with entries, META_KEY kept last:
func _refill_map(map: Dictionary, entries: Array) -> void:
	var meta = map.get(META_KEY)
	var holds_meta := map.has(META_KEY)
	#? In place - a root map is the line's data, held elsewhere.
	map.clear()
	for entry in entries:
		map[entry[0]] = entry[1]
	if holds_meta:
		map[META_KEY] = meta


#& Normalization

#* Fill in every schema key of every line:
func normalize_all() -> void:
	#? So widgets and visible_when test values, never presence.
	for conversation in _all_conversation_names():
		for block in block_names(conversation):
			var array := lines(conversation, block)
			for i in array.size():
				array[i] = CandySchemas.normalize_line(array[i])


#& Renaming

func rename_conversation(old_name: String, new_name: String) -> bool:
	if new_name == "" or old_name == new_name or not has_conversation(old_name):
		return false
	if is_preset_conversation(old_name):
		return false
	if has_conversation(new_name):
		return false
	_record_structure(CandyLocale.t("Rename conversation {old} to {new}").format({"old": old_name, "new": new_name}))
	var anchors := _anchor_views()
	dialogue = _rename_key(dialogue, old_name, new_name)
	_follow_views(anchors)
	selection = [[new_name]]
	_finish_edit(anchors)
	return true


func rename_block(conversation: String, old_name: String, new_name: String) -> bool:
	if new_name == "" or old_name == new_name or not has_block(conversation, old_name):
		return false
	if has_block(conversation, new_name):
		return false
	_record_structure(CandyLocale.t("Rename block {old} to {new}").format({"old": _place([conversation, old_name]), "new": new_name}))
	var anchors := _anchor_views()
	_set_conv(conversation, _rename_key(_conv(conversation), old_name, new_name))
	_follow_views(anchors)
	selection = [[conversation, new_name]]
	var renames := [[[conversation, old_name], [conversation, new_name]]]
	_history.note_renames(renames)
	blocks_renamed.emit(renames)
	_finish_edit(anchors)
	return true


#* Rename a key in place (dictionary order is display order):
func _rename_key(source: Dictionary, old_key: String, new_key: String) -> Dictionary:
	var result := {}
	for key in source:
		if str(key) == old_key:
			result[new_key] = source[key]
		else:
			result[key] = source[key]
	return result


#& Display

#* A line's Navigator text, "{index} | {type}: ...":
func describe_line(line: Dictionary, index: int, mode: int) -> String:
	var type := line_type(line)
	var data := line_data(line)

	#% Custom - the type's own mode (LINE_MODES_SETTING):
	if mode == DisplayMode.CUSTOM:
		mode = custom_mode(type)

	#¦ 1. Meta - the Meta Reference, "3 | Set: score_bonus":
	if mode == DisplayMode.META:
		var reference := meta_reference(data)
		if reference != "":
			return "%d | %s: %s" % [index, type, reference]
		return "%d | %s:" % [index, type]

	#¦ 2. Spoken_Line and Comment show no type:
	match type:
		"Spoken_Line":
			return ("%d | %s" % [index, _spoken_line_text(data, mode == DisplayMode.FULL)]).strip_edges()
		"Comment":
			return ("%d | %s" % [index, str(data.get("Comment", ""))]).strip_edges()

	#¦ 3. Short - the schema's "short", else Full:
	if mode == DisplayMode.SHORT and CandySchemas.has_short(type):
		var short := CandySchemas.short_text(type, data)
		if short != "":
			return "%d | %s: %s" % [index, type, short]
		return "%d | %s:" % [index, type]

	#¦ 4. Full, root map - list its entries:
	if not CandySchemas.root_map_spec(type, data).is_empty():
		var keys: PackedStringArray = []
		for key in data:
			if str(key) != META_KEY:
				keys.append(str(key))
		if not keys.is_empty():
			return "%d | %s: %s" % [index, type, ", ".join(keys)]

	#¦ 5. Full - schema's summary, "3 | Set: gold += 5":
	var summary := CandySchemas.summary(type, data)
	if summary != "":
		return "%d | %s: %s" % [index, type, summary]

	return "%d | %s:" % [index, type]


#* A Spoken_Line's text after its index:
#? full: "[Disposition] Speaker (Portrait): |Voice| Text", else "Speaker: Text".
func _spoken_line_text(data: Dictionary, full: bool) -> String:
	var parts: PackedStringArray = []
	if full:
		var disposition := _shown_value(data, "Disposition")
		if disposition != "":
			parts.append("[%s]" % disposition)
	var speaker := _shown_value(data, "Reference")
	if speaker != "":
		parts.append(speaker)
	if full:
		var portrait := _shown_value(data, "Portrait")
		if portrait != "":
			parts.append("(%s)" % portrait)
	var head := " ".join(parts)
	var tail: PackedStringArray = []
	if full:
		var voice := _shown_value(data, "Voice")
		if voice != "":
			tail.append("|%s|" % voice)
	var text := spoken_text(data)
	#% Short leaves out text event markers:
	if not full:
		text = CandyTextEventMarkers.strip(text)
	if text != "":
		tail.append(text)
	if head != "" and not tail.is_empty():
		return "%s: %s" % [head, " ".join(tail)]
	if head != "":
		return head
	return " ".join(tail)


#* A field's value as a row shows it, "" for "null":
func _shown_value(data: Dictionary, key: String) -> String:
	var value := str(data.get(key, "")).strip_edges()
	if value == "null":
		return ""
	return value


#* The display mode the Custom mode uses for a type:
func custom_mode(type: String) -> int:
	var modes = CandyProfiles.get_setting(LINE_MODES_SETTING, {})
	if not modes is Dictionary:
		return DisplayMode.FULL
	return int(LINE_MODES.get(str(modes.get(type, "full")), DisplayMode.FULL))


#* A line's Meta Reference, "" if none:
func meta_reference(data: Dictionary) -> String:
	var meta = data.get(META_DATA_KEY, {})
	if not meta is Dictionary:
		return ""
	return str(meta.get(META_REFERENCE_KEY, ""))


#* A Spoken_Line's text, of the first variation or the one named:
func spoken_text(data: Dictionary, variation: String = "") -> String:
	var variations = data.get("Variations", [])
	if not variations is Array:
		return ""
	for entry in variations:
		if not entry is Dictionary:
			continue
		for key in entry:
			if variation != "" and str(key) != variation:
				continue
			var value = entry[key]
			if value is Dictionary:
				return str(value.get("Text", ""))
	return ""


#& Names

#* A free name from base - "Block_1" -> "Block_1_(1)" -> "Block_1_(2)":
func unique_name(taken: Array, base: String) -> String:
	if not taken.has(base):
		return base
	var root := base
	var regex := RegEx.create_from_string("^(.*)_\\((\\d+)\\)$")
	#Ł Replace an existing suffix, not stack it:
	var found := regex.search(base)
	if found != null:
		root = found.get_string(1)
	var counter := 1
	while true:
		var candidate := "%s_(%d)" % [root, counter]
		if not taken.has(candidate):
			return candidate
		counter += 1
	return base


#* Next "<prefix>_<n>" name - highest number + 1:
func numbered_name(taken: Array, prefix: String) -> String:
	var highest := 0
	var start := prefix + "_"
	for key in taken:
		var number := str(key).trim_prefix(start)
		if str(key).begins_with(start) and number.is_valid_int() and not number.begins_with("-"):
			highest = maxi(highest, int(number))
	return "%s_%d" % [prefix, highest + 1]


#* Renumber a map's "<prefix>_<n>" entries from 1, in order, leaving no gap:
func renumbered(map: Dictionary, prefix: String) -> Dictionary:
	var start := prefix + "_"
	var numbered: Array = []
	var others: Array = []
	for key in map:
		var number := str(key).trim_prefix(start)
		if str(key).begins_with(start) and number.is_valid_int() and not number.begins_with("-"):
			numbered.append([int(number), key])
		else:
			others.append(key)
	numbered.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var result := {}
	#@ Step 1 - "Custom_<n>" must stay at index n - 1 (Candy DE passes Custom_Data as an array):
	for i in numbered.size():
		result["%s_%d" % [prefix, i + 1]] = map[numbered[i][1]]
	#@ Step 2 - Other keys follow, unchanged:
	for key in others:
		result[key] = map[key]
	return result


#& Presets

#* Replace both preset conversations (e.g. on profile open):
func set_presets(user_blocks: Dictionary, profile_blocks: Dictionary) -> void:
	#? History steps may hold the old presets.
	_history.clear()
	var anchors := _anchor_views()
	presets = {USER_PRESETS: user_blocks, PROFILE_PRESETS: profile_blocks}
	for conversation in PRESET_CONVERSATIONS:
		for block in block_names(conversation):
			var array := lines(conversation, block)
			for i in array.size():
				array[i] = CandySchemas.normalize_line(array[i])
	_forget_preset_paths()
	_finish_edit(anchors)


func clear_presets() -> void:
	set_presets({}, {})


#* A preset conversation's live blocks, { block: { "Text": [...] } }:
func preset_blocks(conversation: String) -> Dictionary:
	if not is_preset_conversation(conversation):
		return {}
	return presets[conversation]


#* Drop preset paths from every view (they may be stale):
func _forget_preset_paths() -> void:
	for reference in _views:
		var view: Dictionary = _views[reference]
		var kept: Array = []
		for path in view["selection"]:
			if not is_preset_conversation(str(path[0])):
				kept.append(path)
		view["selection"] = kept
		var active: Array = view["active"]
		if not active.is_empty() and is_preset_conversation(str(active[0])):
			view["active"] = []


#& Undo and redo

func can_undo() -> bool:
	return _history.can_undo()


func can_redo() -> bool:
	return _history.can_redo()


#* Labels of the steps undo() would undo, next first:
func undo_labels() -> Array:
	return _history.undo_labels()


#* Labels of the steps redo() would redo, next first:
func redo_labels() -> Array:
	return _history.redo_labels()


#* Undo the last steps:
func undo(steps: int = 1) -> void:
	_travel(steps, true)


#* Redo the last undone steps:
func redo(steps: int = 1) -> void:
	_travel(steps, false)


#* Start a step - every edit until the matching end_step() is one undo step:
#? label "" uses the first edit's. Steps nest. Consecutive steps with the same typing_id
#? (new_typing_id()) merge.
func begin_step(label: String = "", typing_id: int = 0) -> void:
	_history.begin_step(label, typing_id)


#* A new typing id, one per stretch of typing in a text field:
func new_typing_id() -> int:
	_last_typing_id += 1
	return _last_typing_id


func end_step() -> void:
	_history.end_step()


#* A view's active line and selection, as an undo step keeps them:
func selection_state(reference: String) -> Dictionary:
	var view := _view(reference)
	return {"reference": clean_reference(reference), "active": view["active"].duplicate(),
		"selection": view["selection"].duplicate(true)}


#* Undo or redo steps, then update the views:
func _travel(steps: int, undoing: bool) -> void:
	var anchors := _anchor_views()
	var state: Dictionary = {}
	for i in steps:
		var step: Dictionary
		if undoing:
			step = _history.undo()
			if not step.is_empty():
				state = step["before"]
		else:
			step = _history.redo()
			if not step.is_empty():
				state = step["after"]
		if step.is_empty():
			break
		var renames: Array = step["renames"]
		if not renames.is_empty():
			blocks_renamed.emit(_travelled_renames(renames, undoing))
	if state.is_empty():
		return

	#Ł Other views stay on their items:
	_follow_views(anchors)
	#Ł The last step's view gets back its active line and selection from that side of the step:
	_restore_selection_state(state)
	_finish_edit(anchors)


#* Restore a view's selection_state(), skipping what no longer exists:
func _restore_selection_state(state: Dictionary) -> void:
	var view := _view(str(state.get("reference", DEFAULT_REFERENCE)))
	var kept: Array = []
	var paths = state.get("selection", [])
	if paths is Array:
		for path in paths:
			if path is Array and exists(path):
				kept.append(path.duplicate())
	view["selection"] = kept
	view["active"] = []
	var active = state.get("active", [])
	if active is Array and is_line_path(active) and exists(active):
		view["active"] = active.duplicate()


#* A step's renames as they happen again (reversed when undoing):
func _travelled_renames(renames: Array, undoing: bool) -> Array:
	if not undoing:
		return renames.duplicate(true)
	var result: Array = []
	for i in range(renames.size() - 1, -1, -1):
		result.append([renames[i][1].duplicate(), renames[i][0].duplicate()])
	return result


#* Record the top-level line before an edit in it, for the view editing it:
func _record_line(line_path: Array, label: String) -> void:
	var line := line_at(root_line_path(line_path))
	if not line.is_empty():
		_history.record_line(line, label, _reference_editing(line))


#* Record the structure before an edit of it, for the current view:
func _record_structure(label: String) -> void:
	_history.record_structure(label, current_reference)


#* The view editing a top-level line - the current one, unless only another has it active:
func _reference_editing(line: Dictionary) -> String:
	if _is_active_line(current_reference, line):
		return current_reference
	for reference in _views:
		if _is_active_line(reference, line):
			return reference
	return current_reference


func _is_active_line(reference: String, line: Dictionary) -> bool:
	var root := root_line_path(active_path_of(reference))
	return is_line_path(root) and _is_at(line, root)


#& Step labels

#* A path as the Editor's breadcrumb names it: "Conversation_1 › Block_1 › line 3":
func _place(path: Array) -> String:
	var parts := PackedStringArray()
	for i in mini(path.size(), 3):
		if i == 2:
			parts.append(CandyLocale.t("line %d") % int(path[2]))
		else:
			parts.append(str(path[i]))
	return " › ".join(parts)


#* An undo label for a line - "Edit Variations/Text (Conversation_1 › Block_1 › line 3)":
func _line_label(action: String, line_path: Array) -> String:
	return CandyLocale.t("{action} ({place})").format({"action": action, "place": _place(root_line_path(line_path))})


#* A field's schema path ("Categories/Choices/Label"), after any nested command's steps:
func _field_name(line_path: Array, field_path: Array) -> String:
	var steps := PackedStringArray()
	for step in line_path.slice(3) + field_path:
		if step is int or str(step) == ENTRY_VALUE or str(step) == ENTRY_NAME:
			continue
		steps.append(str(step))
	if steps.is_empty():
		return line_type(line_at(line_path))			#/ No field: the line's type
	return "/".join(steps)


#* Name paths of one kind ("block Conversation_1 › Block_1"), or count them ("3 lines"):
func _describe_paths(paths: Array) -> String:
	if paths.size() != 1:
		return _describe_count(paths.size(), path_kind(paths[0]))
	var path: Array = paths[0]
	match path_kind(path):
		Kind.CONVERSATION:
			return CandyLocale.t("conversation %s") % path[0]
		Kind.BLOCK:
			return CandyLocale.t("block %s") % _place(path)
	return CandyLocale.t("{command} ({place})").format({"command": line_type(line_at(path)), "place": _place(path)})


#* "1 line", "3 blocks":
func _describe_count(count: int, kind: int) -> String:
	match kind:
		Kind.CONVERSATION:
			return CandyLocale.tn("%d conversation", "%d conversations", count) % count
		Kind.BLOCK:
			return CandyLocale.tn("%d block", "%d blocks", count) % count
	return CandyLocale.tn("%d line", "%d lines", count) % count


#& Internals

#* A conversation's live blocks dictionary, real or preset, or null:
func _conv(conversation: String) -> Variant:
	if is_preset_conversation(conversation):
		return presets[conversation]
	return dialogue.get(conversation)


#* Replace a conversation's blocks dictionary:
func _set_conv(conversation: String, blocks: Dictionary) -> void:
	if is_preset_conversation(conversation):
		presets[conversation] = blocks
	else:
		dialogue[conversation] = blocks


func _all_conversation_names() -> Array:
	return conversation_names() + PRESET_CONVERSATIONS


#* Paths without preset conversations:
func _without_presets(paths: Array) -> Array:
	var result: Array = []
	for path in paths:
		if not is_preset_conversation(str(path[0])):
			result.append(path)
	return result



func _same_path(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if str(a[i]) != str(b[i]):
			return false
	return true


#* Whether two path lists match, in order:
func _same_paths(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not _same_path(a[i], b[i]):
			return false
	return true


func _has_path(paths: Array, path: Array) -> bool:
	for p in paths:
		if _same_path(p, path):
			return true
	return false


#* Sort paths in document order:
func _sorted_paths(paths: Array) -> Array:
	var conversations := _all_conversation_names()
	var result := paths.duplicate()
	result.sort_custom(func(a: Array, b: Array) -> bool:
		var ca := conversations.find(a[0])
		var cb := conversations.find(b[0])
		if ca != cb:
			return ca < cb
		if a.size() > 1 and b.size() > 1 and str(a[1]) != str(b[1]):
			var blocks := block_names(a[0])
			return blocks.find(a[1]) < blocks.find(b[1])
		if a.size() > 2 and b.size() > 2:
			return int(a[2]) < int(b[2])
		return a.size() < b.size())
	return result


func _remove_lines(paths: Array) -> void:
	#? Descending, so indices stay valid.
	var sorted_paths := _sorted_paths(paths)
	for i in range(sorted_paths.size() - 1, -1, -1):
		var path: Array = sorted_paths[i]
		var array := lines(path[0], path[1])
		var index := int(path[2])
		if index >= 0 and index < array.size():
			array.remove_at(index)


#* Insert entries at index (rebuilds, since dictionaries keep insertion order):
func _insert_keys(source: Dictionary, entries: Array, index: int) -> Dictionary:
	var keys := source.keys()
	index = clampi(index, 0, keys.size())
	var result := {}
	for i in keys.size() + 1:
		if i == index:
			for entry in entries:
				result[entry[0]] = entry[1]
		if i < keys.size():
			result[keys[i]] = source[keys[i]]
	return result


#* The starting dialogue - one conversation with one empty block, named from settings:
func _default_dialogue() -> Dictionary:
	var conversation_name := str(CandyProfiles.get_setting("conversation_new_name", "Conversation_1"))
	var block_name := str(CandyProfiles.get_setting("block_default_name", "Block_1"))
	return {conversation_name: {block_name: {TEXT_KEY: []}}}


#* A nested command's key in its line's editor data - "filters@Commands/Media_Play":
func _nested_meta_key(line_path: Array, key: String) -> String:
	var steps := PackedStringArray()
	for step in line_path.slice(3):
		steps.append(str(step))
	return "%s@%s" % [key, "/".join(steps)]

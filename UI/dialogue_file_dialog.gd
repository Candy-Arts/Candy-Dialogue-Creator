#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueFileDialog
extends AcceptDialog

enum Action { EXPORT, IMPORT }

const EXPORT_PATH_SETTING := "dialogue_export_path"
const IMPORT_PATH_SETTING := "dialogue_import_path"
const EXPORT_MODE_SETTING := "dialogue_export_mode"
const IMPORT_MODE_SETTING := "dialogue_import_mode"
const EXPORT_UNIT_SETTING := "dialogue_export_unit"
const IMPORT_UNIT_SETTING := "dialogue_import_unit"
const DEFAULT_EXPORT_FILE := "dialogue.txt"
#^ Seconds after the last key in the path before re-reading the file:
const RELOAD_DELAY := 0.4
const TEXT_WIDTH := 760
const SIDE_WIDTH := 190
const RESULT_COLUMN_WIDTH := 190

var action: Action = Action.EXPORT

var _path_edit: LineEdit
var _mode_button: OptionButton
var _unit_button: OptionButton
var _mode_note: Label
var _tree: Tree
var _error: Label
var _confirm: ConfirmationDialog
var _reload_timer: Timer
#^ Resolved path awaiting confirmation:
var _pending_path: String = ""

#^ The file's dialogue as last read ({} if none), and why it couldn't be read ("" if fine or missing):
var _file_dialogue: Dictionary = {}
var _file_problem: String = ""
#^ Unticked rows, by _key() (a conversation's key counts only when it has no blocks):
var _unchecked: Dictionary = {}


func _init(p_action: Action = Action.EXPORT) -> void:
	action = p_action
	min_size = Vector2i(820, 600)
	dialog_hide_on_ok = false  #/ Closed once the action worked
	if action == Action.EXPORT:
		title = CandyLocale.t("Export Dialogue")
		ok_button_text = CandyLocale.t("Export")
	else:
		title = CandyLocale.t("Import Dialogue")
		ok_button_text = CandyLocale.t("Import")
	add_cancel_button(CandyLocale.t("Cancel"))

	var box := VBoxContainer.new()
	box.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	add_child(box)

	var note := Label.new()
	if action == Action.EXPORT:
		note.text = CandyLocale.t("Export the checked conversations and blocks to a file Candy Dialogue Engine reads. The mode says how they go into a file that exists.")
	else:
		note.text = CandyLocale.t("Import the checked conversations and blocks of a dialogue file. The mode says how they go into the dialogue currently loaded.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#? A wrapping label needs a width, or the window becomes a sliver-wide tall label.
	note.custom_minimum_size.x = TEXT_WIDTH
	note.theme_type_variation = CandyThemeDefaults.NOTE
	box.add_child(note)

	box.add_child(_build_path_row())
	box.add_child(HSeparator.new())

	var options := HBoxContainer.new()
	options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(options)
	options.add_child(_build_side())
	options.add_child(VSeparator.new())
	options.add_child(_build_tree())

	_error = Label.new()
	_error.text = " "
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.custom_minimum_size.x = TEXT_WIDTH
	_error.theme_type_variation = CandyThemeDefaults.ERROR
	box.add_child(_error)

	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(_on_confirmed)
	add_child(_confirm)

	_reload_timer = Timer.new()
	_reload_timer.one_shot = true
	_reload_timer.wait_time = RELOAD_DELAY
	_reload_timer.timeout.connect(_reload)
	add_child(_reload_timer)

	register_text_enter(_path_edit)
	confirmed.connect(_on_action_pressed)


func _build_path_row() -> HBoxContainer:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = CandyLocale.t("File")
	row.add_child(label)

	_path_edit = LineEdit.new()
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_edit.placeholder_text = CandyLocale.t("Path and file name (.txt)")
	_path_edit.tooltip_text = CandyLocale.t("A file name alone goes in the Dialogues folder set in Settings > Project > Paths.")
	_path_edit.text_changed.connect(func(_text: String):
		_set_error("")
		_reload_timer.start())
	row.add_child(_path_edit)

	var browse := Button.new()
	browse.text = "..."
	browse.tooltip_text = CandyLocale.t("Browse for a file")
	browse.focus_mode = Control.FOCUS_NONE
	browse.pressed.connect(_browse)
	row.add_child(browse)

	var reveal := Button.new()
	reveal.text = "↗"
	reveal.tooltip_text = CandyLocale.t("Show the folder in the file manager")
	reveal.focus_mode = Control.FOCUS_NONE
	reveal.pressed.connect(_reveal)
	row.add_child(reveal)
	return row


func _build_side() -> VBoxContainer:
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = SIDE_WIDTH

	var label := Label.new()
	label.text = CandyLocale.t("Mode")
	side.add_child(label)

	_mode_button = OptionButton.new()
	for i in CandyDialogueMerge.MODE_LABELS.size():
		_mode_button.add_item(CandyLocale.t(CandyDialogueMerge.MODE_LABELS[i]), i)
	_mode_button.tooltip_text = _by_target(
		CandyLocale.t("Overwrite: the file becomes what's checked.\nAdd: only what the file doesn't have.\nUpdate: only what the file has.\nAdd & Update: everything checked."),
		CandyLocale.t("Overwrite: the dialogue becomes what's checked.\nAdd: only what the dialogue doesn't have.\nUpdate: only what the dialogue has.\nAdd & Update: everything checked."))
	_mode_button.item_selected.connect(func(_index: int): _on_mode_changed())
	side.add_child(_mode_button)

	_unit_button = OptionButton.new()
	for i in CandyDialogueMerge.UNIT_LABELS.size():
		_unit_button.add_item(CandyLocale.t(CandyDialogueMerge.UNIT_LABELS[i]), i)
	_unit_button.tooltip_text = CandyLocale.t("Conversations: a conversation goes in whole, with only its checked blocks.\nBlocks: only the checked blocks go in, and everything else stays.")
	_unit_button.item_selected.connect(func(_index: int): _on_mode_changed())
	side.add_child(_unit_button)

	_mode_note = Label.new()
	_mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_note.custom_minimum_size.x = SIDE_WIDTH
	_mode_note.theme_type_variation = CandyThemeDefaults.NOTE
	side.add_child(_mode_note)

	side.add_child(HSeparator.new())
	side.add_child(_make_button(CandyLocale.t("Mark All"), CandyLocale.t("Tick every conversation and block"), _mark_all.bind(true)))
	side.add_child(_make_button(CandyLocale.t("Unmark All"), CandyLocale.t("Untick every conversation and block"), _mark_all.bind(false)))
	side.add_child(HSeparator.new())
	side.add_child(_make_button(CandyLocale.t("Mark Selected"), CandyLocale.t("Tick the rows selected in the list (Ctrl and Shift select several). A conversation comes with all its blocks."), _mark_selected.bind(true)))
	side.add_child(_make_button(CandyLocale.t("Unmark Selected"), CandyLocale.t("Untick the rows selected in the list (Ctrl and Shift select several). A conversation comes with all its blocks."), _mark_selected.bind(false)))
	return side


func _build_tree() -> Tree:
	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.select_mode = Tree.SELECT_MULTI
	_tree.columns = 2
	_tree.column_titles_visible = true
	_tree.set_column_title(0, CandyLocale.t("Conversations and blocks"))
	_tree.set_column_title(1, CandyLocale.t("Result"))
	_tree.set_column_expand(1, false)
	_tree.set_column_custom_minimum_width(1, RESULT_COLUMN_WIDTH)
	_tree.item_edited.connect(_on_item_edited)
	return _tree


func _make_button(text: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


#* Open the dialog:
func open() -> void:
	#Ł Commit typing first, so the tree and file have it (and an import doesn't replace the line under it):
	CandyLayout.commit_typing()
	_set_error("")
	_unchecked.clear()
	_path_edit.text = _initial_path()
	_mode_button.select(_stored_index(_mode_setting(), CandyDialogueMerge.MODE_IDS))
	_unit_button.select(_stored_index(_unit_setting(), CandyDialogueMerge.UNIT_IDS))
	_update_mode_controls()
	_load_file()
	_rebuild_tree()
	popup_centered()
	_path_edit.grab_focus()
	_path_edit.caret_column = _path_edit.text.length()


func _initial_path() -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	var stored := str(CandyProfiles.get_setting(_path_setting(), "")).strip_edges()
	if stored != "":
		return stored
	var folder := CandyDialogueExport.dialogues_folder()
	if folder == "":
		return ""
	if action == Action.EXPORT:
		return folder.path_join(DEFAULT_EXPORT_FILE)
	return folder.path_join("")


func _stored_index(key: String, ids: Array) -> int:
	if not CandyProfiles.is_profile_open():
		return 0
	return maxi(ids.find(str(CandyProfiles.get_setting(key, ids[0]))), 0)


func _path_setting() -> String:
	if action == Action.EXPORT:
		return EXPORT_PATH_SETTING
	return IMPORT_PATH_SETTING


func _mode_setting() -> String:
	if action == Action.EXPORT:
		return EXPORT_MODE_SETTING
	return IMPORT_MODE_SETTING


func _unit_setting() -> String:
	if action == Action.EXPORT:
		return EXPORT_UNIT_SETTING
	return IMPORT_UNIT_SETTING


func _resolved() -> String:
	return CandyDialogueExport.resolve_path(_path_edit.text, action == Action.EXPORT)


#* The text that names what the merge writes into - the file (Export) or the dialogue (Import):
func _by_target(file_text: String, dialogue_text: String) -> String:
	if action == Action.EXPORT:
		return file_text
	return dialogue_text


#& Source and target

func _source() -> Dictionary:
	if action == Action.EXPORT:
		return CandyDialogue.dialogue
	return _file_dialogue


func _target() -> Dictionary:
	if action == Action.EXPORT:
		return _file_dialogue
	return CandyDialogue.dialogue


#* Read the file again (a missing file is empty for Export):
func _load_file() -> void:
	_file_dialogue = {}
	_file_problem = ""
	if not CandyProfiles.is_profile_open():
		_file_problem = CandyLocale.t("Open a project profile first.")
		return
	var path := _resolved()
	if path == "" or DirAccess.dir_exists_absolute(path):
		if action == Action.IMPORT:
			_file_problem = CandyLocale.t("Choose a file to import.")
		return
	if action == Action.EXPORT and not FileAccess.file_exists(path):
		return
	var result := {}
	_file_problem = CandyDialogueExport.read_dialogue(path, result)
	if _file_problem == "":
		_file_dialogue = result["dialogue"]
	elif action == Action.EXPORT:
		_file_problem = CandyLocale.t("Only Overwrite can export to this file: %s") % _file_problem


func _reload() -> void:
	_load_file()
	_rebuild_tree()


func _mode() -> int:
	return _mode_button.get_selected_id()


func _unit() -> int:
	return _unit_button.get_selected_id()


func _plan() -> Dictionary:
	return CandyDialogueMerge.run(_target(), _source(), _selection(), _mode(), _unit(), false)


#& Checks

#* A row's key in _unchecked:
func _key(path: Array) -> String:
	return "\n".join(PackedStringArray(path))


#* What's ticked, as CandyDialogueMerge takes it:
func _selection() -> Dictionary:
	var result := {}
	var source := _source()
	for conversation in source:
		var blocks = source[conversation]
		if not blocks is Dictionary:
			continue
		var checked: Array = []
		for block in blocks:
			if not _unchecked.has(_key([conversation, block])):
				checked.append(block)
		#% A conversation with ticked blocks, or with no blocks and ticked itself:
		if not checked.is_empty():
			result[conversation] = checked
		elif blocks.is_empty() and not _unchecked.has(_key([conversation])):
			result[conversation] = checked
	return result


#* Tick or untick a row (a conversation's blocks with it):
func _set_checked(path: Array, checked: bool) -> void:
	var keys: Array = [_key(path)]
	if path.size() == 1:
		var blocks = _source().get(path[0])
		if blocks is Dictionary:
			for block in blocks:
				keys.append(_key([path[0], block]))
	for key in keys:
		if checked:
			_unchecked.erase(key)
		else:
			_unchecked[key] = true


func _on_item_edited() -> void:
	var item := _tree.get_edited()
	if item == null or _tree.get_edited_column() != 0:
		return
	_set_checked(item.get_metadata(0), item.is_checked(0))
	_refresh_rows()


func _mark_all(checked: bool) -> void:
	for conversation in _source():
		_set_checked([conversation], checked)
	_refresh_rows()


func _mark_selected(checked: bool) -> void:
	var item := _tree.get_next_selected(null)
	while item != null:
		if item.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
			_set_checked(item.get_metadata(0), checked)
		item = _tree.get_next_selected(item)
	_refresh_rows()


#& Mode

func _on_mode_changed() -> void:
	_update_mode_controls()
	_refresh_rows()


func _update_mode_controls() -> void:
	_unit_button.disabled = _mode() == CandyDialogueMerge.Mode.OVERWRITE
	_mode_note.text = _mode_description()


func _mode_description() -> String:
	if _mode() == CandyDialogueMerge.Mode.OVERWRITE:
		return _by_target(CandyLocale.t("The file becomes the checked conversations and blocks. Everything else in it is removed."),
			CandyLocale.t("The dialogue becomes the checked conversations and blocks. Everything else in it is removed."))
	if _unit() == CandyDialogueMerge.Unit.CONVERSATIONS:
		match _mode():
			CandyDialogueMerge.Mode.ADD:
				return _by_target(CandyLocale.t("Adds the checked conversations the file doesn't have. Those it has stay as they are."),
					CandyLocale.t("Adds the checked conversations the dialogue doesn't have. Those it has stay as they are."))
			CandyDialogueMerge.Mode.UPDATE:
				return _by_target(CandyLocale.t("Replaces the conversations the file has with the checked ones, which keep only their checked blocks. Adds nothing."),
					CandyLocale.t("Replaces the conversations the dialogue has with the checked ones, which keep only their checked blocks. Adds nothing."))
		return _by_target(CandyLocale.t("Writes every checked conversation, with only its checked blocks. A conversation the file has is replaced whole."),
			CandyLocale.t("Writes every checked conversation, with only its checked blocks. A conversation the dialogue has is replaced whole."))
	match _mode():
		CandyDialogueMerge.Mode.ADD:
			return _by_target(CandyLocale.t("Adds the checked blocks the file doesn't have, and their conversations if needed. Blocks it has stay as they are."),
				CandyLocale.t("Adds the checked blocks the dialogue doesn't have, and their conversations if needed. Blocks it has stay as they are."))
		CandyDialogueMerge.Mode.UPDATE:
			return _by_target(CandyLocale.t("Replaces the checked blocks the file has. Adds nothing, and everything else stays."),
				CandyLocale.t("Replaces the checked blocks the dialogue has. Adds nothing, and everything else stays."))
	return _by_target(CandyLocale.t("Adds the checked blocks the file doesn't have, and replaces those it has. Everything else stays."),
		CandyLocale.t("Adds the checked blocks the dialogue doesn't have, and replaces those it has. Everything else stays."))


#& Tree

#* Rebuild the rows (only when the source or target changes):
#? Checks and modes only refresh state (_refresh_rows()), so folds and scrolling stay.
func _rebuild_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()
	for row in _plan()["rows"]:
		var conversation_item := _add_row(root, row, [row["name"]])
		for block_row in row["blocks"]:
			_add_row(conversation_item, block_row, [row["name"], block_row["name"]])
	_refresh_rows()


func _add_row(parent: TreeItem, row: Dictionary, path: Array) -> TreeItem:
	var item := _tree.create_item(parent)
	#? The cell mode first: setting it clears the cell's text.
	if row["in_source"]:
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
	item.set_text(0, str(row["name"]))
	item.set_metadata(0, path)
	if not row["in_source"]:
		item.set_custom_color(0, _tree.get_theme_color(&"font_color", CandyThemeDefaults.NOTE))
		item.set_tooltip_text(0, _by_target(CandyLocale.t("Only in the file"), CandyLocale.t("Only in the dialogue")))
	return item


#* Refresh every row's checkbox and Result, and the error line:
func _refresh_rows() -> void:
	var rows: Array = _plan()["rows"]
	var root := _tree.get_root()
	if root == null:
		return
	var conversation_items := root.get_children()
	for i in mini(rows.size(), conversation_items.size()):
		var conversation_item: TreeItem = conversation_items[i]
		var block_items := conversation_item.get_children()
		var ticked := 0
		var tickable := 0
		for j in mini(rows[i]["blocks"].size(), block_items.size()):
			var block_item: TreeItem = block_items[j]
			_show_status(block_item, rows[i]["blocks"][j]["status"])
			if block_item.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
				var checked := not _unchecked.has(_key(block_item.get_metadata(0)))
				block_item.set_checked(0, checked)
				tickable += 1
				if checked:
					ticked += 1
		_show_status(conversation_item, rows[i]["status"])
		if conversation_item.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
			if tickable == 0:
				conversation_item.set_checked(0, not _unchecked.has(_key(conversation_item.get_metadata(0))))
			elif ticked == tickable:
				conversation_item.set_checked(0, true)
			elif ticked == 0:
				conversation_item.set_checked(0, false)
			else:
				conversation_item.set_indeterminate(0, true)
	_show_file_problem()


func _show_status(item: TreeItem, status: int) -> void:
	var variation := CandyThemeDefaults.NOTE
	var text := ""
	var tooltip := ""
	match status:
		CandyDialogueMerge.Status.NEW:
			variation = CandyThemeDefaults.HIGHLIGHT
			text = CandyLocale.t("New")
			tooltip = _by_target(CandyLocale.t("Added: the file doesn't have it yet."), CandyLocale.t("Added: the dialogue doesn't have it yet."))
		CandyDialogueMerge.Status.REPLACED:
			variation = CandyThemeDefaults.WARNING
			text = CandyLocale.t("Replaces")
			tooltip = _by_target(CandyLocale.t("Replaces the file's."), CandyLocale.t("Replaces the dialogue's."))
		CandyDialogueMerge.Status.UPDATED:
			variation = CandyThemeDefaults.HIGHLIGHT
			text = CandyLocale.t("Updated")
			tooltip = CandyLocale.t("Some of its blocks change.")
		CandyDialogueMerge.Status.UNCHANGED:
			text = CandyLocale.t("Unchanged")
			tooltip = CandyLocale.t("None of its blocks change.")
		CandyDialogueMerge.Status.REMOVED:
			variation = CandyThemeDefaults.WARNING
			text = CandyLocale.t("Removed")
			tooltip = _by_target(CandyLocale.t("The file's is removed."), CandyLocale.t("The dialogue's is removed."))
		CandyDialogueMerge.Status.SKIPPED_EXISTS:
			text = CandyLocale.t("Skipped: already there")
			tooltip = _by_target(CandyLocale.t("The file has it already: this mode only adds what's missing."),
				CandyLocale.t("The dialogue has it already: this mode only adds what's missing."))
		CandyDialogueMerge.Status.SKIPPED_MISSING:
			text = CandyLocale.t("Skipped: not there")
			tooltip = _by_target(CandyLocale.t("The file doesn't have it: this mode only replaces what's there."),
				CandyLocale.t("The dialogue doesn't have it: this mode only replaces what's there."))
		CandyDialogueMerge.Status.NOT_INCLUDED:
			text = CandyLocale.t("Not included")
			tooltip = CandyLocale.t("Unticked")
		CandyDialogueMerge.Status.KEPT:
			text = CandyLocale.t("Kept")
			tooltip = _by_target(CandyLocale.t("Only in the file, left as it is."), CandyLocale.t("Only in the dialogue, left as it is."))
	item.set_text(1, text)
	item.set_tooltip_text(1, tooltip)
	item.set_custom_color(1, _tree.get_theme_color(&"font_color", variation))


func _show_file_problem() -> void:
	if _file_problem == "":
		_set_error("")
	elif action == Action.EXPORT and _mode() == CandyDialogueMerge.Mode.OVERWRITE:
		_set_error("")
	else:
		_set_error(_file_problem)


#* Summary for the confirmation ("2 conversations new, 5 blocks replaced"):
func _summary(rows: Array) -> String:
	var counts := CandyDialogueMerge.count(rows)
	var parts := PackedStringArray()
	for status in [CandyDialogueMerge.Status.NEW, CandyDialogueMerge.Status.REPLACED, CandyDialogueMerge.Status.REMOVED]:
		var conversations := int(counts["conversations"].get(status, 0))
		var blocks := int(counts["blocks"].get(status, 0))
		var conversations_text := ""
		var blocks_text := ""
		match status:
			CandyDialogueMerge.Status.NEW:
				conversations_text = CandyLocale.tn("%d conversation new", "%d conversations new", conversations)
				blocks_text = CandyLocale.tn("%d block new", "%d blocks new", blocks)
			CandyDialogueMerge.Status.REPLACED:
				conversations_text = CandyLocale.tn("%d conversation replaced", "%d conversations replaced", conversations)
				blocks_text = CandyLocale.tn("%d block replaced", "%d blocks replaced", blocks)
			CandyDialogueMerge.Status.REMOVED:
				conversations_text = CandyLocale.tn("%d conversation removed", "%d conversations removed", conversations)
				blocks_text = CandyLocale.tn("%d block removed", "%d blocks removed", blocks)
		if conversations > 0:
			parts.append(conversations_text % conversations)
		if blocks > 0:
			parts.append(blocks_text % blocks)
	if parts.is_empty():
		return CandyLocale.t("Nothing changes.")
	return CandyLocale.t("%s.") % CandyLocale.t(", ").join(parts)


#& Export / Import

func _on_action_pressed() -> void:
	if not CandyProfiles.is_profile_open():
		_set_error(CandyLocale.t("Open a project profile first."))
		return
	var path := _resolved()
	if path == "":
		_set_error(CandyLocale.t("Enter a path and file name."))
		return
	if path.get_extension().to_lower() != "txt":
		_set_error(CandyLocale.t("The file must be a .txt file."))
		return

	#? The file may have changed since it was read.
	_load_file()
	_rebuild_tree()
	var overwrite := _mode() == CandyDialogueMerge.Mode.OVERWRITE
	if _file_problem != "" and (action == Action.IMPORT or not overwrite):
		_set_error(_file_problem)
		return
	var selection := _selection()
	if selection.is_empty():
		_set_error(CandyLocale.t("Nothing is checked."))
		return

	var mode_text := CandyLocale.t(CandyDialogueMerge.MODE_LABELS[_mode()])
	if not overwrite:
		mode_text += " (%s)" % CandyLocale.t(CandyDialogueMerge.UNIT_LABELS[_unit()])
	var summary := _summary(_plan()["rows"])
	if action == Action.EXPORT:
		_confirm.title = CandyLocale.t("Export Dialogue")
		_confirm.ok_button_text = CandyLocale.t("Export")
		_confirm.dialog_text = CandyLocale.t("Export to:\n{path}\n\nMode: {mode}\n{summary}").format({"path": path, "mode": mode_text, "summary": summary})
		if overwrite and FileAccess.file_exists(path):
			_confirm.dialog_text += "\n\n" + CandyLocale.t("The file is replaced.")
	else:
		#? Checked before the prompt, so a bad file never asks.
		var problem := CandyDialogueExport.check_import(path, selection)
		if problem != "":
			_set_error(problem)
			return
		_confirm.title = CandyLocale.t("Import Dialogue")
		_confirm.ok_button_text = CandyLocale.t("Import")
		_confirm.dialog_text = CandyLocale.t("Import from:\n{path}\n\nMode: {mode}\n{summary}").format({"path": path, "mode": mode_text, "summary": summary})
		if overwrite:
			_confirm.dialog_text += "\n\n" + CandyLocale.t("The dialogue currently loaded is replaced: changes that weren't saved will be lost.")

	_pending_path = path
	_confirm.popup_centered()


func _on_confirmed() -> void:
	var path := _pending_path
	_pending_path = ""
	if path == "":
		return
	CandyLayout.commit_typing()
	#Ł The open dialogue and the file meet: both must use the profile's symbols.
	#? Except a file Export overwrites, which isn't read.
	var doing := CandyLocale.t("importing")
	if action == Action.EXPORT:
		doing = CandyLocale.t("exporting")
	CandySymbolPrompt.ensure_dialogue(self, doing, func():
		if action == Action.EXPORT and _mode() == CandyDialogueMerge.Mode.OVERWRITE:
			_run(path)
		else:
			CandySymbolPrompt.ensure_files(self, [path], doing, _run.bind(path)))


#* Export or import, once the symbols match:
func _run(path: String) -> void:
	var problem := ""
	if action == Action.EXPORT:
		problem = CandyDialogueExport.export_merged(path, _selection(), _mode(), _unit())
	else:
		problem = CandyDialogueExport.import_merged(path, _selection(), _mode(), _unit())
	if problem != "":
		_set_error(problem)
		return
	CandyProfiles.set_setting(_path_setting(), _path_edit.text.strip_edges())
	CandyProfiles.set_setting(_mode_setting(), CandyDialogueMerge.MODE_IDS[_mode()])
	CandyProfiles.set_setting(_unit_setting(), CandyDialogueMerge.UNIT_IDS[_unit()])
	hide()


#& Path buttons

func _browse() -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.txt ; %s" % CandyLocale.t("Dialogue files")])
	if action == Action.EXPORT:
		dialog.title = CandyLocale.t("Export Dialogue To")
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	else:
		dialog.title = CandyLocale.t("Import Dialogue From")
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

	var path := _resolved()
	var start_dir := ""
	if path != "":
		if DirAccess.dir_exists_absolute(path):
			start_dir = path
		elif DirAccess.dir_exists_absolute(path.get_base_dir()):
			start_dir = path.get_base_dir()
			if path.get_extension() != "":
				dialog.current_file = path.get_file()
	if start_dir == "":
		var folder := CandyDialogueExport.dialogues_folder()
		if folder != "" and DirAccess.dir_exists_absolute(folder):
			start_dir = folder
	if start_dir != "":
		dialog.current_dir = start_dir

	dialog.file_selected.connect(func(selected: String):
		dialog.queue_free()
		if action == Action.EXPORT and selected.get_extension() == "":
			selected += ".txt"
		_path_edit.text = selected
		_set_error("")
		_reload_timer.stop()
		_reload())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _reveal() -> void:
	var path := _resolved()
	if path == "":
		path = CandyDialogueExport.dialogues_folder()
	if path == "":
		_set_error(CandyLocale.t("No folder to show: enter a path, or set the project root in Settings > Project > Paths."))
		return
	if FileAccess.file_exists(path):
		OS.shell_show_in_file_manager(path, false)
		return
	var folder := path
	if not DirAccess.dir_exists_absolute(folder):
		folder = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(folder):
		_set_error(CandyLocale.t("The folder doesn't exist yet:\n%s") % folder)
		return
	OS.shell_show_in_file_manager(folder, true)


func _set_error(message: String) -> void:
	if message == "":
		_error.text = " "
	else:
		_error.text = message

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySymbolUpdaterDialog
extends AcceptDialog

#& Edit > Symbol Updater...: rewrites 1.2 files from the symbols they were written with to the profile's.

#^ Symbols of files that don't store theirs, { Candy_Properties.gd variable: symbol }:
const FALLBACK_SETTING := "symbol_updater_symbols"
#^ Under it, the CandyRef symbols, { what it reads: symbol }:
const CANDY_REF_FALLBACK := "candy_ref"
const CANDY_REF_LABEL_WIDTH := 150
const TEXT_WIDTH := 820
const FILES_WIDTH := 430
const OPTIONS_WIDTH := 420

var _files: Tree
var _error: Label
var _confirm: ConfirmationDialog
#^ Variable -> LineEdit (files that don't store their symbols):
var _fallback_edits: Dictionary = {}
#^ Variable -> Label (the profile's):
var _profile_labels: Dictionary = {}
var _grid: GridContainer
#^ The profile's CandyRef symbols - [entry, LineEdit], and every control of their rows:
var _candy_ref_edits: Array = []
var _candy_ref_controls: Array = []
#^ Folder Add Files... opens in (last one used):
var _last_folder := ""


func _init() -> void:
	title = CandyLocale.t("Symbol Updater")
	ok_button_text = CandyLocale.t("Update")
	dialog_hide_on_ok = false
	min_size = Vector2i(880, 640)
	add_cancel_button(CandyLocale.t("Close"))

	var box := VBoxContainer.new()
	box.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	add_child(box)

	var note := _note(CandyLocale.t("Rewrites 1.2 dialogues, saves and presets with the profile's symbols. Each file is backed up beside it first, in Conversion Backups/%s.") % CandySymbolUpdater.BACKUP_KIND_FOLDER)
	note.custom_minimum_size.x = TEXT_WIDTH
	box.add_child(note)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	columns.add_child(_build_files())
	columns.add_child(VSeparator.new())
	columns.add_child(_build_options())

	_error = Label.new()
	_error.text = " "
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.custom_minimum_size.x = TEXT_WIDTH
	_error.theme_type_variation = CandyThemeDefaults.ERROR
	box.add_child(_error)

	_confirm = ConfirmationDialog.new()
	_confirm.ok_button_text = CandyLocale.t("Update")
	#? The open dialogue first, so reloaded presets meet the same symbols:
	_confirm.confirmed.connect(func(): CandySymbolPrompt.ensure_dialogue(self, CandyLocale.t("updating files"), _update))
	add_child(_confirm)

	confirmed.connect(_on_update_pressed)


#& Building

func _build_files() -> VBoxContainer:
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = FILES_WIDTH
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_heading(side, CandyLocale.t("Files"))
	_files = Tree.new()
	_files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_files.hide_root = true
	_files.select_mode = Tree.SELECT_MULTI
	_files.columns = 2
	_files.column_titles_visible = true
	_files.set_column_title(0, CandyLocale.t("File"))
	_files.set_column_title(1, CandyLocale.t("Found"))
	_files.set_column_expand(1, false)
	_files.set_column_custom_minimum_width(1, 200)
	_files.create_item()
	side.add_child(_files)

	var buttons := HBoxContainer.new()
	side.add_child(buttons)
	buttons.add_child(_button(CandyLocale.t("Add Files..."), CandyLocale.t("Pick dialogue files, saves or preset files to update."), _browse))
	buttons.add_child(_button(CandyLocale.t("Remove"), CandyLocale.t("Take the selected files out of the list. Nothing is deleted."), _remove_selected))
	return side


func _build_options() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = OPTIONS_WIDTH
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side)

	_heading(side, CandyLocale.t("Symbols"))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.theme_type_variation = CandyThemeDefaults.ROOMY_GRID
	side.add_child(grid)
	_grid = grid
	#Ł Column titles - [text, tooltip]:
	var titles := [
		[CandyLocale.t("Symbol"), ""],
		[CandyLocale.t("Written with"), CandyLocale.t("The symbols of files that don't store theirs.")],
		[CandyLocale.t("Becomes"), CandyLocale.t("The profile's symbols, from Settings > Project > Symbols.")],
	]
	for column in titles:
		var title_label := Label.new()
		title_label.text = column[0]
		title_label.tooltip_text = column[1]
		title_label.mouse_filter = Control.MOUSE_FILTER_PASS
		title_label.theme_type_variation = CandyThemeDefaults.NOTE
		grid.add_child(title_label)
	for variable in CandySymbolUpdater.variables():
		var symbol_label := Label.new()
		symbol_label.text = CandySymbolUpdater.label(variable)
		symbol_label.tooltip_text = "var %s" % variable
		symbol_label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(symbol_label)
		var edit := LineEdit.new()
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.tooltip_text = CandyLocale.t("For files that don't store their symbols.")
		grid.add_child(edit)
		_fallback_edits[variable] = edit
		var profile_label := Label.new()
		profile_label.tooltip_text = CandyLocale.t("The profile's, from Settings > Project > Symbols.")
		profile_label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(profile_label)
		_profile_labels[variable] = profile_label
	#? The CandyRef symbols' rows follow, made when the window opens (_build_candy_ref_rows()).
	return scroll


func _heading(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	parent.add_child(label)


func _note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = CandyThemeDefaults.NOTE
	return label


func _button(text: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


#& Opening

#? The profile's symbols may be updated from the project first (asked under the parent: this window isn't shown yet).
func open() -> void:
	CandySymbolPrompt.offer_project_symbols(get_parent(), func():
		_set_error("")
		_load_options()
		for item in _files.get_root().get_children():
			_describe(item)
		popup_centered())


func _load_options() -> void:
	var profile := CandySymbolUpdater.profile_symbols()
	for variable in _profile_labels:
		_profile_labels[variable].text = str(profile.get(variable, ""))

	var fallback := CandySymbolUpdater.default_symbols()
	var stored = CandyProfiles.get_setting(FALLBACK_SETTING, {})
	if not stored is Dictionary:
		stored = {}
	for variable in CandySymbolUpdater.variables():
		if str(stored.get(variable, "")) != "":
			fallback[variable] = str(stored[variable])
	for variable in _fallback_edits:
		_fallback_edits[variable].text = str(fallback.get(variable, ""))
	var stored_candy_ref = stored.get(CANDY_REF_FALLBACK, {})
	if not stored_candy_ref is Dictionary:
		stored_candy_ref = {}
	_build_candy_ref_rows(stored_candy_ref)


#* A row per CandyRef symbol of the profile - written with (the profile's, unless changed), becomes:
func _build_candy_ref_rows(stored: Dictionary) -> void:
	for control in _candy_ref_controls:
		control.queue_free()
	_candy_ref_controls.clear()
	_candy_ref_edits.clear()
	for entry in CandyDialogueExport.candy_ref_entries():
		if not entry is Dictionary:
			continue
		var symbol_label := Label.new()
		symbol_label.text = CandySymbolUpdater.entry_label(entry)
		symbol_label.tooltip_text = symbol_label.text
		symbol_label.mouse_filter = Control.MOUSE_FILTER_PASS
		symbol_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		symbol_label.custom_minimum_size.x = CANDY_REF_LABEL_WIDTH
		var edit := LineEdit.new()
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.tooltip_text = CandyLocale.t("For files that don't store their symbols.")
		var written := str(stored.get(CandySymbolUpdater.identity_of(entry), ""))
		if written == "":
			written = str(entry.get("symbol", ""))
		edit.text = written
		var profile_label := Label.new()
		profile_label.text = str(entry.get("symbol", ""))
		profile_label.tooltip_text = CandyLocale.t("The profile's, from Settings > Project > Symbols.")
		profile_label.mouse_filter = Control.MOUSE_FILTER_PASS
		for control in [symbol_label, edit, profile_label]:
			_grid.add_child(control)
			_candy_ref_controls.append(control)
		_candy_ref_edits.append([entry, edit])


func _fallback() -> Dictionary:
	var result := {}
	for variable in _fallback_edits:
		result[variable] = _fallback_edits[variable].text.strip_edges()
	var entries: Array = []
	for pair in _candy_ref_edits:
		var entry: Dictionary = pair[0].duplicate()
		entry["symbol"] = pair[1].text.strip_edges()
		entries.append(entry)
	result.merge(CandySymbolUpdater.tables_of(entries))
	return result


#* What the window keeps in the profile - the symbols, and the CandyRef ones by what they read:
func _fallback_setting() -> Dictionary:
	var result := {}
	for variable in _fallback_edits:
		result[variable] = _fallback_edits[variable].text.strip_edges()
	var candy_ref := {}
	for pair in _candy_ref_edits:
		candy_ref[CandySymbolUpdater.identity_of(pair[0])] = pair[1].text.strip_edges()
	result[CANDY_REF_FALLBACK] = candy_ref
	return result


#& Files

func _browse() -> void:
	var dialog := FileDialog.new()
	dialog.title = CandyLocale.t("Files to Update")
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.txt ; %s" % CandyLocale.t("Dialogues, saves and presets")])
	var folder := _last_folder
	if folder == "":
		folder = CandyDialogueExport.dialogues_folder()
	if folder == "":
		folder = ProjectSettings.globalize_path(CandyProfiles.current_profile_dir())
	dialog.current_dir = folder
	dialog.files_selected.connect(func(paths: PackedStringArray):
		dialog.queue_free()
		_add_files(paths))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _add_files(paths: PackedStringArray) -> void:
	_set_error("")
	var listed := _listed_paths()
	for path in paths:
		_last_folder = path.get_base_dir()
		if path in listed:
			continue
		var item := _files.create_item(_files.get_root())
		item.set_metadata(0, path)
		listed.append(path)
		_describe(item)


#* Show what a file is now (read again after an update):
func _describe(item: TreeItem) -> void:
	var path := str(item.get_metadata(0))
	var info := CandySymbolUpdater.inspect(path, _fallback(), CandySymbolUpdater.profile_symbols())
	item.set_text(0, path.get_file())
	item.set_tooltip_text(0, path)
	var found := CandySymbolUpdater.describe(info)
	match str(info["status"]):
		CandySymbolUpdater.STATUS_MATCH:
			found += " (%s)" % CandyLocale.t("matching")
		CandySymbolUpdater.STATUS_UNREADABLE, CandySymbolUpdater.STATUS_NOT_CURRENT:
			found += " (%s)" % CandyLocale.t("can't update")
	item.set_text(1, found)
	var tooltip := str(info["problem"])
	if str(info["status"]) == CandySymbolUpdater.STATUS_UPDATE:
		tooltip = CandySymbolUpdater.describe_changes(info["symbols"], CandySymbolUpdater.profile_symbols())
	item.set_tooltip_text(1, tooltip)


func _remove_selected() -> void:
	var selected: Array = []
	var item := _files.get_next_selected(null)
	while item != null:
		selected.append(item)
		item = _files.get_next_selected(item)
	for entry in selected:
		entry.free()


func _listed_paths() -> Array:
	var result: Array = []
	for item in _files.get_root().get_children():
		result.append(str(item.get_metadata(0)))
	return result


#& Updating

func _on_update_pressed() -> void:
	var paths := _listed_paths()
	if paths.is_empty():
		_set_error(CandyLocale.t("Add the files to update first."))
		return
	var problem := CandySymbolUpdater.profile_problems()
	if problem != "":
		_set_error(CandyLocale.t("The profile's symbols can't be used: %s Fix them on Settings > Project > Symbols.") % problem)
		return
	_set_error("")
	CandyProfiles.set_setting(FALLBACK_SETTING, _fallback_setting())
	_confirm.title = CandyLocale.t("Update")
	_confirm.dialog_text = CandyLocale.tn("Update the symbols of %d file to the profile's?\nEach is backed up first, then replaced by its updated version.",
		"Update the symbols of %d files to the profile's?\nEach is backed up first, then replaced by its updated version.", paths.size()) % paths.size()
	_confirm.popup_centered()


func _update() -> void:
	var results := CandySymbolUpdater.update_files(_listed_paths(), _fallback(), CandySymbolUpdater.profile_symbols())
	_reload_presets(results)
	for item in _files.get_root().get_children():
		_describe(item)
	CandyConverterReportDialog.open_report(results, CandySymbolUpdater)


#* Read the open profile's presets again if they were updated:
func _reload_presets(results: Array) -> void:
	var preset_files: Array = []
	for path in CandyPresets.file_paths():
		preset_files.append(_comparable(str(path)))
	for result in results:
		if str(result["outcome"]) == CandyFileConverter.OUTCOME_CONVERTED and _comparable(str(result["path"])) in preset_files:
			CandyPresets.reload()
			return


func _comparable(path: String) -> String:
	var result := ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path()
	if OS.get_name() == "Windows" or OS.get_name() == "macOS":
		result = result.to_lower()
	return result


func _set_error(message: String) -> void:
	if message == "":
		_error.text = " "
	else:
		_error.text = message

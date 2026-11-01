#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyConverterDialog
extends AcceptDialog

const PROJECT_SETTING := "converter_project"
const SYMBOLS_SETTING := "symbols"
#^ 1.2 symbols the conversion writes - [label, key under "symbols"]:
const NEW_SYMBOLS := [
	["Expression",      #/ translatable
		"expression"],
	["Text variable start",      #/ translatable
		"text_var_start"],
	["Text variable end",      #/ translatable
		"text_var_end"],
	["Substitution start",      #/ translatable
		"substitution_start"],
	["Substitution end",      #/ translatable
		"substitution_end"],
]
const UI_ELEMENT_LABELS := {
	"dialogue_box_path": "Dialogue box",      #/ translatable
	"subtitles_path": "Subtitles",      #/ translatable
	"chat_path": "Chat",      #/ translatable
	"barks_path": "Barks",      #/ translatable
}
const PORTRAIT_LABELS := {
	CandyDialogueConverter.PORTRAIT_SPRITE: "Sprite, AnimatedSprite, or not sure",      #/ translatable
	CandyDialogueConverter.PORTRAIT_FOLDER: "TextureRect or NinePatchRect (animation folders)",      #/ translatable
	CandyDialogueConverter.PORTRAIT_VIDEO: "VideoStreamPlayer",      #/ translatable
}
const TEXT_WIDTH := 820
const FILES_WIDTH := 430
const OPTIONS_WIDTH := 420
const SETTING_LABEL_WIDTH := 150
const SETTING_GRID_META := &"candy_setting_grid"

var _files: Tree
var _error: Label
var _confirm: ConfirmationDialog
#^ Setting key -> LineEdit:
var _old_symbol_edits: Dictionary = {}
#^ "symbols" key -> LineEdit:
var _new_symbol_edits: Dictionary = {}
var _tts: OptionButton
var _portrait: OptionButton
var _layers: LineEdit
#^ ui_elements_paths key -> CheckBox:
var _elements: Dictionary = {}
#^ Folder Add Files... opens in (last one used):
var _last_folder := ""


func _init() -> void:
	title = CandyLocale.t("Dialogue Converter")
	ok_button_text = CandyLocale.t("Convert")
	dialog_hide_on_ok = false
	min_size = Vector2i(880, 640)
	add_cancel_button(CandyLocale.t("Close"))

	var box := VBoxContainer.new()
	box.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	add_child(box)

	var note := _note(CandyLocale.t("Converts dialogues, saves and presets made with Candy Dialogue Creator 1.1 (for Candy DE 1.1.3) to the 1.2 format. Each file is backed up beside it first, in Conversion Backups/1.1 to 1.2, then replaced by its converted version."))
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
	_confirm.ok_button_text = CandyLocale.t("Convert")
	_confirm.confirmed.connect(_convert)
	add_child(_confirm)

	confirmed.connect(_on_convert_pressed)


#& Building

func _build_files() -> VBoxContainer:
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = FILES_WIDTH
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = CandyLocale.t("Files")
	title_label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	side.add_child(title_label)

	_files = Tree.new()
	_files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_files.hide_root = true
	_files.select_mode = Tree.SELECT_MULTI
	_files.columns = 2
	_files.column_titles_visible = true
	_files.set_column_title(0, CandyLocale.t("File"))
	_files.set_column_title(1, CandyLocale.t("Found"))
	_files.set_column_expand(1, false)
	_files.set_column_custom_minimum_width(1, 170)
	_files.create_item()
	side.add_child(_files)

	var buttons := HBoxContainer.new()
	side.add_child(buttons)
	buttons.add_child(_button(CandyLocale.t("Add Files..."), CandyLocale.t("Pick dialogue files, saves or preset files to convert."), _browse))
	buttons.add_child(_button(CandyLocale.t("Remove"), CandyLocale.t("Take the selected files out of the list. Nothing is deleted."), _remove_selected))
	return side


func _build_options() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = OPTIONS_WIDTH
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side)

	_heading(side, CandyLocale.t("Your 1.1 project"))
	side.add_child(_note(CandyLocale.t("A few things about your 1.1 project change how its files convert, and they aren't in the files themselves. Enter what your project used: they're kept in this profile for next time.")))

	_heading(side, CandyLocale.t("1.1 symbols"))
	side.add_child(_note(CandyLocale.t("The symbols your dialogues were written with, from your 1.1.3 project's Candy_Properties.gd. The converter uses them to find the references, text variables and word substitutions in your lines, and rewrite them for 1.2.")))
	var old_grid := _grid(side)
	for symbol in CandySymbolsPage.LEGACY_SYMBOLS:
		_old_symbol_edits[str(symbol[1])] = _line_edit(old_grid, CandyLocale.t(str(symbol[0])), "var %s" % symbol[1])

	_heading(side, CandyLocale.t("1.2 symbols"))
	side.add_child(_note(CandyLocale.t("What they become: the symbols of your 1.2 project (also on Settings > Project > Symbols). 1.2 only reads a value as an expression when it starts with the Expression symbol.")))
	var new_grid := _grid(side)
	for symbol in NEW_SYMBOLS:
		_new_symbol_edits[str(symbol[1])] = _line_edit(new_grid, CandyLocale.t(str(symbol[0])), "")

	_heading(side, CandyLocale.t("1.1 engine"))
	side.add_child(_note(CandyLocale.t("Some 1.1 values did different things depending on your engine's settings and scenes, which the converter can't read. Each setting below is only used for the lines it names: if your files have none, leave it as it is.")))

	_tts = _option(_setting_grid(side), CandyLocale.t("Text To Speech"), CandyDialogueConverter.TTS_MODES, "var text_to_speech")
	side.add_child(_note(CandyLocale.t("For lines with TTS on (\"1\"). In 1.1 they were read in your engine's TTS mode. In 1.2 each line names its own mode, so this one is written into them.")))

	_portrait = _option(_setting_grid(side), CandyLocale.t("Portrait node"),
		PORTRAIT_LABELS.values().map(func(label: Variant) -> String: return CandyLocale.t(str(label))),
		CandyLocale.t("The portrait_node of your dialogue box or portrait scene."))
	side.add_child(_note(CandyLocale.t("For every spoken line. In 1.1, PortraitPlay played a portrait differently depending on this node (looping until replaced, showing its first frame, or playing once). 1.2 counts loops instead, so the converter needs it to keep each portrait playing the same way.")))

	var elements_grid := _setting_grid(side)
	var elements_label := _setting_label(elements_grid, CandyLocale.t("Dialogue UI"), CandyLocale.t("Keys of your engine's ui_elements_paths."))
	elements_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var elements_box := VBoxContainer.new()
	elements_grid.add_child(elements_box)
	for element in CandyDialogueConverter.UI_ELEMENTS:
		var check := CheckBox.new()
		check.text = CandyLocale.t(str(UI_ELEMENT_LABELS[element]))
		check.tooltip_text = element
		elements_box.add_child(check)
		_elements[element] = check
	side.add_child(_note(CandyLocale.t("For Hide, V_Show and I_Show, which become UI_Z. 1.1 moved every dialogue UI element, skipping those your engine didn't have. 1.2 names each one, and reports any it can't find: tick only the ones your engine has.")))

	_layers = _line_edit(_setting_grid(side), CandyLocale.t("Background layers"), CandyLocale.t("The children of your background scene's bg_container."))
	side.add_child(_note(CandyLocale.t("For BG commands with no Layers, which meant every layer in 1.1. 1.2 needs each layer named: list your background scene's layers, separated by commas. Left empty, those lines get no layers, and are listed in the report.")))
	_layers.placeholder_text = CandyLocale.t("Sky, Ground...")
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


func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.theme_type_variation = CandyThemeDefaults.ROOMY_GRID
	parent.add_child(grid)
	return grid


#* Make a grid for one engine setting (its note goes below it):
func _setting_grid(parent: Control) -> GridContainer:
	var grid := _grid(parent)
	grid.set_meta(SETTING_GRID_META, true)
	return grid


func _setting_label(grid: GridContainer, label_text: String, tooltip: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	#% Engine setting grids line up:
	if grid.has_meta(SETTING_GRID_META):
		label.custom_minimum_size.x = SETTING_LABEL_WIDTH
	grid.add_child(label)
	return label


func _line_edit(grid: GridContainer, label_text: String, tooltip: String) -> LineEdit:
	_setting_label(grid, label_text, tooltip)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.tooltip_text = tooltip
	grid.add_child(edit)
	return edit


func _option(grid: GridContainer, label_text: String, items: Array, tooltip: String) -> OptionButton:
	_setting_label(grid, label_text, tooltip)
	var button := OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = tooltip
	for item in items:
		button.add_item(str(item))
	grid.add_child(button)
	return button


func _button(text: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


#& Opening

func open() -> void:
	_set_error("")
	_load_options()
	popup_centered()


func _load_options() -> void:
	var old_defaults := CandyDialogueConverter.default_old_symbols()
	for key in _old_symbol_edits:
		var value := str(CandyProfiles.get_setting(key, "")).strip_edges()
		if value == "":
			value = str(old_defaults.get(key, ""))
		_old_symbol_edits[key].text = value

	var symbols = CandyProfiles.get_setting(SYMBOLS_SETTING, {})
	if not symbols is Dictionary:
		symbols = {}
	var new_defaults := CandyDialogueConverter.default_new_symbols()
	for key in _new_symbol_edits:
		var value := str(symbols.get(key, "")).strip_edges()
		if value == "":
			value = str(new_defaults.get(key, ""))
		_new_symbol_edits[key].text = value

	var project := CandyDialogueConverter.default_project()
	var stored = CandyProfiles.get_setting(PROJECT_SETTING, {})
	if stored is Dictionary:
		for key in stored:
			project[key] = stored[key]
	_select(_tts, CandyDialogueConverter.TTS_MODES, str(project["tts"]))
	_select(_portrait, PORTRAIT_LABELS.keys(), str(project["portrait_node"]))
	var elements = project["ui_elements"]
	for element in _elements:
		_elements[element].button_pressed = elements is Array and element in elements
	_layers.text = str(project["bg_layers"])


func _select(button: OptionButton, values: Array, value: String) -> void:
	button.select(maxi(values.find(value), 0))


#& Files

func _browse() -> void:
	var dialog := FileDialog.new()
	dialog.title = CandyLocale.t("Files to Convert")
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


#* Show what a file is now (read again after a conversion):
func _describe(item: TreeItem) -> void:
	var path := str(item.get_metadata(0))
	var info := CandyFileConverter.inspect(path)
	item.set_text(0, path.get_file())
	item.set_tooltip_text(0, path)
	var found := CandyFileConverter.describe(info)
	if str(info["status"]) != CandyFileConverter.STATUS_CONVERT:
		found += " (%s)" % _status_word(str(info["status"]))
	item.set_text(1, found)
	item.set_tooltip_text(1, str(info["problem"]))


func _status_word(status: String) -> String:
	match status:
		CandyFileConverter.STATUS_CURRENT:
			return CandyLocale.t("already 1.2")
		CandyFileConverter.STATUS_OLD:
			return "1.0"
	return CandyLocale.t("can't convert")


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


#& Converting

func _on_convert_pressed() -> void:
	var paths := _listed_paths()
	if paths.is_empty():
		_set_error(CandyLocale.t("Add the files to convert first."))
		return
	_set_error("")
	_store_options()
	_confirm.title = CandyLocale.t("Convert")
	_confirm.dialog_text = CandyLocale.tn("Convert %d file to the 1.2 format?\nEach is backed up first, then replaced by its converted version.",
		"Convert %d files to the 1.2 format?\nEach is backed up first, then replaced by its converted version.", paths.size()) % paths.size()
	_confirm.popup_centered()


func _convert() -> void:
	var paths := _listed_paths()
	var results := CandyFileConverter.convert_files(paths, _old_symbols(), _new_symbols(), _project())
	_reload_presets(results)
	for item in _files.get_root().get_children():
		_describe(item)
	CandyConverterReportDialog.open_report(results)


#* Reload the open profile's presets if they were converted:
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


func _store_options() -> void:
	for key in _old_symbol_edits:
		CandyProfiles.set_setting(key, _old_symbol_edits[key].text.strip_edges(), false)
	var symbols = CandyProfiles.get_setting(SYMBOLS_SETTING, {})
	if symbols is Dictionary:
		symbols = symbols.duplicate()
	else:
		symbols = {}
	for key in _new_symbol_edits:
		symbols[key] = _new_symbol_edits[key].text.strip_edges()
	CandyProfiles.set_setting(SYMBOLS_SETTING, symbols, false)
	CandyProfiles.set_setting(PROJECT_SETTING, _project())


func _old_symbols() -> Dictionary:
	var result := {}
	for key in _old_symbol_edits:
		result[key] = _old_symbol_edits[key].text.strip_edges()
	return result


func _new_symbols() -> Dictionary:
	var result := {}
	for key in _new_symbol_edits:
		result[key] = _new_symbol_edits[key].text.strip_edges()
	return result


func _project() -> Dictionary:
	var elements: Array = []
	for element in _elements:
		if _elements[element].button_pressed:
			elements.append(element)
	return {
		"tts": CandyDialogueConverter.TTS_MODES[_tts.selected],
		"portrait_node": PORTRAIT_LABELS.keys()[_portrait.selected],
		"ui_elements": elements,
		"bg_layers": _layers.text.strip_edges(),
	}


func _set_error(message: String) -> void:
	if message == "":
		_error.text = " "
	else:
		_error.text = message

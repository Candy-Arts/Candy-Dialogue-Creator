#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTopBarPanel
extends CandyPanel

enum FileItem { NEW, OPEN, SAVE, SAVE_AS, SAVE_INCREMENTAL, SWITCH_PROFILE, QUIT, EXPORT, IMPORT }

const TEST_TEXT := "Test"	#/ translatable
const TEST_DONE_TEXT := "Test ✓"	#/ translatable
#^ While the Godot editor is asked to start the test:
const TEST_WAITING_TEXT := "Test…"	#/ translatable
const TEST_FEEDBACK_SECONDS := 1.5
const REFRESH_TEXT := "Refresh"	#/ translatable
const REFRESH_DONE_TEXT := "Refresh ✓"	#/ translatable
enum EditItem { SETTINGS, CONVERTER, SYMBOL_UPDATER }
enum LayoutItem { EDIT_LAYOUT, NEW_WINDOW, SAVE_LAYOUT, RESET_LAYOUT }
enum HelpItem { DOCUMENTATION }
#^ Window menu - first quick layout id, after the LayoutItem ids:
const QUICK_LAYOUT_FIRST_ID := 100
#^ Menu items -> shortcut action, whose keys show beside them (CandyShortcuts.show_keys_in()):
const FILE_SHORTCUTS := {
	FileItem.NEW: "new_dialogue", FileItem.OPEN: "load", FileItem.SAVE: "save", FileItem.SAVE_AS: "save_as",
	FileItem.SAVE_INCREMENTAL: "save_incremental", FileItem.EXPORT: "export", FileItem.IMPORT: "import",
}
const EDIT_SHORTCUTS := {EditItem.SETTINGS: "settings"}
const LAYOUT_SHORTCUTS := {
	LayoutItem.EDIT_LAYOUT: "edit_layout", LayoutItem.NEW_WINDOW: "new_window", LayoutItem.RESET_LAYOUT: "reset_layout",
}

var _row: HBoxContainer
var _bar: MenuBar
var _test_button: Button
var _test_timer: Timer
#^ Left of Test - where it starts:
var _test_start_button: Button
var _test_start_popup: CandyTestStartPopup
#^ Right of Test - rescans the project's folders:
var _refresh_button: Button
var _refresh_timer: Timer
var _window_menu: PopupMenu
var _quick_layout_paths: Array = []    #/ item id - QUICK_LAYOUT_FIRST_ID -> file path
var _settings_dialog: CandySettingsDialog
var _converter_dialog: CandyConverterDialog
var _symbol_updater_dialog: CandySymbolUpdaterDialog
var _export_dialog: CandyDialogueFileDialog
var _import_dialog: CandyDialogueFileDialog
#^ Window > Save Layout... / Load Layout:
var _layout_menu: CandyLayoutMenu
var _undo_button: Button
var _redo_button: Button
#^ Undo or Redo's steps, on a right-click (item id = how many steps it travels):
var _history_menu: PopupMenu
var _history_menu_undoes := true


func _ready() -> void:
	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_row)

	_bar = MenuBar.new()
	_bar.flat = true
	_bar.theme_type_variation = CandyThemeDefaults.FLAT_MENU_BAR
	#? Keep the menu in the window on macOS too.
	_bar.prefer_global_menu = false
	_row.add_child(_bar)

	var file_menu := PopupMenu.new()
	file_menu.name = "File"
	file_menu.add_item(CandyLocale.t("New Dialogue"), FileItem.NEW)
	file_menu.add_item(CandyLocale.t("Load Dialogue..."), FileItem.OPEN)
	file_menu.add_separator()
	file_menu.add_item(CandyLocale.t("Save"), FileItem.SAVE)
	file_menu.add_item(CandyLocale.t("Save As..."), FileItem.SAVE_AS)
	file_menu.add_item(CandyLocale.t("Save Incremental"), FileItem.SAVE_INCREMENTAL)
	file_menu.add_separator()
	file_menu.add_item(CandyLocale.t("Export Dialogue..."), FileItem.EXPORT)
	file_menu.add_item(CandyLocale.t("Import Dialogue..."), FileItem.IMPORT)
	file_menu.add_separator()
	file_menu.add_item(CandyLocale.t("Switch Profile..."), FileItem.SWITCH_PROFILE)
	file_menu.add_item(CandyLocale.t("Quit"), FileItem.QUIT)
	file_menu.id_pressed.connect(_on_file_menu)
	file_menu.about_to_popup.connect(CandyShortcuts.show_keys_in.bind(file_menu, FILE_SHORTCUTS))
	_bar.add_child(file_menu)
	_bar.set_menu_title(_bar.get_menu_count() - 1, CandyLocale.t("File"))

	var edit_menu := PopupMenu.new()
	edit_menu.name = "Edit"
	edit_menu.add_item(CandyLocale.t("Settings..."), EditItem.SETTINGS)
	edit_menu.add_separator()
	edit_menu.add_item(CandyLocale.t("Dialogue Converter..."), EditItem.CONVERTER)
	edit_menu.set_item_tooltip(edit_menu.get_item_index(EditItem.CONVERTER),
		CandyLocale.t("Convert dialogues, saves and presets made with Candy Dialogue Creator 1.1 to the 1.2 format."))
	edit_menu.add_item(CandyLocale.t("Symbol Updater..."), EditItem.SYMBOL_UPDATER)
	edit_menu.set_item_tooltip(edit_menu.get_item_index(EditItem.SYMBOL_UPDATER),
		CandyLocale.t("Rewrite 1.2 dialogues, saves and presets written with other symbols to the profile's."))
	edit_menu.id_pressed.connect(_on_edit_menu)
	edit_menu.about_to_popup.connect(CandyShortcuts.show_keys_in.bind(edit_menu, EDIT_SHORTCUTS))
	_bar.add_child(edit_menu)
	_bar.set_menu_title(_bar.get_menu_count() - 1, CandyLocale.t("Edit"))

	_layout_menu = CandyLayoutMenu.new()
	add_child(_layout_menu)
	_layout_menu.setup(CandyLayoutLibrary.WINDOWS, "", CandyLayout.layout_data, _load_window_layout)
	_window_menu = PopupMenu.new()
	_window_menu.name = "Window"
	#? Refilled on each opening, for new settings and files.
	_window_menu.about_to_popup.connect(_fill_window_menu)
	_window_menu.id_pressed.connect(_on_window_menu)
	_bar.add_child(_window_menu)
	_bar.set_menu_title(_bar.get_menu_count() - 1, CandyLocale.t("Window"))
	_bar.set_menu_tooltip(_bar.get_menu_count() - 1,
		CandyLocale.t("Edit Layout, new windows, saving and loading window layouts, and your quick layouts (chosen in Settings > UI > Layouts)."))
	_fill_window_menu()

	var help_menu := PopupMenu.new()
	help_menu.name = "Help"
	help_menu.add_item(CandyLocale.t("Documentation"), HelpItem.DOCUMENTATION)
	help_menu.set_item_tooltip(help_menu.get_item_index(HelpItem.DOCUMENTATION),
		CandyLocale.t("The documentation of Candy Dialogue Engine and Candy Dialogue Creator, in a window of its own."))
	help_menu.id_pressed.connect(_on_help_menu)
	_bar.add_child(help_menu)
	_bar.set_menu_title(_bar.get_menu_count() - 1, CandyLocale.t("Help"))

	_undo_button = _history_button(CandyLocale.t("Undo"), true)
	_redo_button = _history_button(CandyLocale.t("Redo"), false)
	_history_menu = PopupMenu.new()
	_history_menu.id_pressed.connect(func(id: int): _travel(id, _history_menu_undoes))
	add_child(_history_menu)
	CandyDialogue.history_changed.connect(_update_history_buttons)
	_update_history_buttons()

	#Ł Push the next buttons to the right:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(spacer)

	_test_start_button = CandyIconButton.new(&"arrow", &"OptionButton", "v", CandyLocale.t("Where Test starts the dialogue in the Godot editor."))
	_test_start_button.flat = true
	_test_start_button.pressed.connect(_open_test_start)
	_row.add_child(_test_start_button)
	_test_start_popup = CandyTestStartPopup.new()
	add_child(_test_start_popup)

	_test_button = CandyShortcutButton.new()
	_test_button.action_id = "test"
	_test_button.text = CandyLocale.t(TEST_TEXT)
	_test_button.focus_mode = Control.FOCUS_NONE
	_test_button.mouse_entered.connect(_update_test_tooltip)
	_test_button.pressed.connect(_on_test_pressed)
	_row.add_child(_test_button)
	_update_test_tooltip()

	_test_timer = Timer.new()
	_test_timer.one_shot = true
	_test_timer.wait_time = TEST_FEEDBACK_SECONDS
	_test_timer.timeout.connect(func(): _test_button.text = CandyLocale.t(TEST_TEXT))
	add_child(_test_timer)
	CandyTestRun.notifier().state_changed.connect(_on_test_state)

	_refresh_button = CandyShortcutButton.new()
	_refresh_button.action_id = "refresh"
	_refresh_button.text = CandyLocale.t(REFRESH_TEXT)
	_refresh_button.focus_mode = Control.FOCUS_NONE
	_refresh_button.tooltip_text = CandyLocale.t("Rescan the Godot project's folders (portraits, voice files, scenes, dialogue modes...),\nfor files added since the profile opened. Set the project root in Settings first.")
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_row.add_child(_refresh_button)

	_refresh_timer = Timer.new()
	_refresh_timer.one_shot = true
	_refresh_timer.wait_time = TEST_FEEDBACK_SECONDS
	_refresh_timer.timeout.connect(func(): _refresh_button.text = CandyLocale.t(REFRESH_TEXT))
	add_child(_refresh_timer)

	_row.add_child(VSeparator.new())

	var window_buttons := CandyWindowButtons.new()
	if window_id != CandyLayout.MAIN_WINDOW_ID:
		window_buttons.close_question = CandyLocale.t("Close this window?")
		window_buttons.close_action = CandyLocale.t("Close")
	window_buttons.close_pressed.connect(_on_close_pressed)
	_row.add_child(window_buttons)

	_row.minimum_size_changed.connect(_update_height)
	_update_height()

	CandyShortcuts.triggered.connect(_on_shortcut)
	CandyResources.resources_scanned.connect(_show_refreshed)


#* Run the File / Edit shortcuts that open a dialog, in the key's window:
func _on_shortcut(action_id: String, window: Window) -> void:
	if window != get_window():
		return
	match action_id:
		"new_dialogue":
			_on_file_menu(FileItem.NEW)
		"export":
			_on_file_menu(FileItem.EXPORT)
		"import":
			_on_file_menu(FileItem.IMPORT)
		"settings":
			_on_edit_menu(EditItem.SETTINGS)


func _update_height() -> void:
	#? The top bar's Area uses this as its fixed height.
	custom_minimum_size.y = maxf(28.0, _row.get_combined_minimum_size().y)


#& Undo and Redo

func _history_button(text: String, undoing: bool) -> Button:
	var button := CandyShortcutButton.new()
	if undoing:
		button.action_id = "undo"
	else:
		button.action_id = "redo"
	button.text = text
	button.flat = true
	button.theme_type_variation = CandyThemeDefaults.FLAT_BUTTON
	button.focus_mode = Control.FOCUS_NONE
	#? Its right-click lists the steps.
	button.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
	button.pressed.connect(_travel.bind(1, undoing))
	button.gui_input.connect(_on_history_button_input.bind(button, undoing))
	_row.add_child(button)
	return button


func _update_history_buttons() -> void:
	var undo_labels := CandyDialogue.undo_labels()
	_undo_button.disabled = undo_labels.is_empty()
	if undo_labels.is_empty():
		_undo_button.tooltip_text = CandyLocale.t("Nothing to undo.")
	else:
		_undo_button.tooltip_text = CandyLocale.t("Undo: %s\nRight-click for every step that can be undone.") % undo_labels[0]

	var redo_labels := CandyDialogue.redo_labels()
	_redo_button.disabled = redo_labels.is_empty()
	if redo_labels.is_empty():
		_redo_button.tooltip_text = CandyLocale.t("Nothing to redo.")
	else:
		_redo_button.tooltip_text = CandyLocale.t("Redo: %s\nRight-click for every step that can be redone.") % redo_labels[0]


#* Undo or redo steps:
func _travel(steps: int, undoing: bool) -> void:
	if steps <= 0:
		return
	CandyLayout.release_focus()	#/ Commits typed text first, as a step of its own
	if undoing:
		CandyDialogue.undo(steps)
	else:
		CandyDialogue.redo(steps)


func _on_history_button_input(event: InputEvent, button: Button, undoing: bool) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT:
		return
	button.accept_event()
	_open_history_menu(button, undoing)


func _open_history_menu(button: Button, undoing: bool) -> void:
	#Ł Commit typing first, so it's listed:
	CandyLayout.release_focus()
	var labels: Array
	var nothing := CandyLocale.t("Nothing to undo")
	var one_step := CandyLocale.t("Undo this step.")
	if undoing:
		labels = CandyDialogue.undo_labels()
	else:
		labels = CandyDialogue.redo_labels()
		nothing = CandyLocale.t("Nothing to redo")
		one_step = CandyLocale.t("Redo this step.")
	_history_menu_undoes = undoing
	_history_menu.clear()
	if labels.is_empty():
		_history_menu.add_item(nothing, 0)
		_history_menu.set_item_disabled(0, true)
	for i in labels.size():
		_history_menu.add_item(str(labels[i]), i + 1)
		if i == 0:
			_history_menu.set_item_tooltip(i, one_step)
		elif undoing:
			_history_menu.set_item_tooltip(i, CandyLocale.tn("Undo this step and the %d above it.", "Undo this step and the %d above it.", i) % i)
		else:
			_history_menu.set_item_tooltip(i, CandyLocale.tn("Redo this step and the %d above it.", "Redo this step and the %d above it.", i) % i)
	_history_menu.reset_size()
	var anchor := Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size))
	CandyPopups.popup_at(_history_menu, anchor, button)


#& Test

#* Test the dialogue:
func _on_test_pressed() -> void:
	var export_only := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)	#/ Ctrl+Click (Cmd+Click on macOS)
	CandyTestRun.run(CandyTestRun.saved_start(), export_only)


#* Show the test's progress on the button:
func _on_test_state(state: int) -> void:
	_test_timer.stop()
	match state:
		CandyTestRun.State.WAITING:
			_test_button.text = CandyLocale.t(TEST_WAITING_TEXT)
		CandyTestRun.State.STARTED, CandyTestRun.State.EXPORTED:
			_test_button.text = CandyLocale.t(TEST_DONE_TEXT)
			_test_timer.start()
		_:
			_test_button.text = CandyLocale.t(TEST_TEXT)


func _open_test_start() -> void:
	var anchor := Rect2i(Vector2i(_test_start_button.get_screen_position()), Vector2i(_test_start_button.size))
	_test_start_popup.open(anchor, _test_start_button)


#& Refresh

#* Rescan the project's folders:
func _on_refresh_pressed() -> void:
	CandyResources.scan()


#* Show a rescan on the button, whoever started it:
func _show_refreshed() -> void:
	_refresh_button.text = CandyLocale.t(REFRESH_DONE_TEXT)
	_refresh_timer.start()


#* Update Test's tooltip: where the file goes and where the test starts:
func _update_test_tooltip() -> void:
	var path := CandyDialogueExport.test_path()
	var text := CandyLocale.t("Export the dialogue to %s in the Dialogues folder (set the project root in Settings first)") % CandyDialogueExport.TEST_FILE
	if path != "":
		text = CandyLocale.t("Export the dialogue to:\n%s\n") % path
	text += "\n" + CandyLocale.t("Then test it in the Godot editor (with Candy Wizard), from:\n%s\n\nThe menu beside it sets the scene and the start.") % CandyTestRun.describe_start(CandyTestRun.saved_start())
	var export_keys := CandyShortcuts.keys_text("test_export")
	if export_keys != "":
		text += " " + CandyLocale.t("Ctrl+Click: export only (%s).") % export_keys
	else:
		text += " " + CandyLocale.t("Ctrl+Click: export only.")
	#? CandyShortcutButton adds the Test shortcut's keys.
	_test_button.tooltip_text = text


func _on_file_menu(id: int) -> void:
	match id:
		FileItem.NEW:
			CandyConfirmPrompt.ask(self, CandyLocale.t("New Dialogue"),
				CandyLocale.t("Close this dialogue and start a new one?\nAnything not saved will be lost."),
				CandyLocale.t("New Dialogue"), CandySaves.new_dialogue)
		FileItem.OPEN:
			CandySaves.open_load_dialog()
		FileItem.SAVE:
			CandySaves.save()
		FileItem.SAVE_AS:
			CandySaves.save_as()
		FileItem.SAVE_INCREMENTAL:
			CandySaves.save_incremental()
		FileItem.EXPORT:
			if _export_dialog == null:
				_export_dialog = CandyDialogueFileDialog.new(CandyDialogueFileDialog.Action.EXPORT)
				add_child(_export_dialog)
			_export_dialog.open()
		FileItem.IMPORT:
			if _import_dialog == null:
				_import_dialog = CandyDialogueFileDialog.new(CandyDialogueFileDialog.Action.IMPORT)
				add_child(_import_dialog)
			_import_dialog.open()
		FileItem.SWITCH_PROFILE:
			#Ł Save the layout in the closing profile, back to the landing screen:
			CandyLayout.save_layout()
			CandyProfiles.close_profile()
		FileItem.QUIT:
			_quit()


func _on_close_pressed() -> void:
	if window_id == CandyLayout.MAIN_WINDOW_ID:
		_quit()
	else:
		CandyLayout.close_window(window_id)


#* Quit (File > Quit, main window's Close):
func _quit() -> void:
	CandyLayout.save_layout()
	CandyProfiles.close_profile()
	get_tree().quit()


func _on_edit_menu(id: int) -> void:
	if id == EditItem.CONVERTER:
		if _converter_dialog == null:
			_converter_dialog = CandyConverterDialog.new()
			add_child(_converter_dialog)
		_converter_dialog.open()
		return
	if id == EditItem.SYMBOL_UPDATER:
		if _symbol_updater_dialog == null:
			_symbol_updater_dialog = CandySymbolUpdaterDialog.new()
			add_child(_symbol_updater_dialog)
		_symbol_updater_dialog.open()
		return
	if id != EditItem.SETTINGS:
		return
	#? Created on first use (costly).
	if _settings_dialog == null:
		_settings_dialog = CandySettingsDialog.new()
		add_child(_settings_dialog)
	_settings_dialog.open()


func _on_help_menu(id: int) -> void:
	if id == HelpItem.DOCUMENTATION:
		CandyDocsWindow.show_documentation(self)


#& Window menu

func _fill_window_menu() -> void:
	var popup := _window_menu
	popup.clear()
	_quick_layout_paths.clear()
	popup.add_check_item(CandyLocale.t("Edit Layout"), LayoutItem.EDIT_LAYOUT)
	popup.set_item_checked(0, CandyLayout.is_editing())
	popup.set_item_tooltip(0, CandyLocale.t("Show each area's panel name and + menu, to change, split, move or close areas."))
	popup.add_separator()
	popup.add_item(CandyLocale.t("New Window"), LayoutItem.NEW_WINDOW)
	popup.add_separator()
	_layout_menu.add_items(popup, LayoutItem.SAVE_LAYOUT)
	popup.add_item(CandyLocale.t("Reset Layout"), LayoutItem.RESET_LAYOUT)
	_add_quick_layouts(popup)
	CandyShortcuts.show_keys_in(popup, LAYOUT_SHORTCUTS)


#* List the quick layouts under a heading:
func _add_quick_layouts(popup: PopupMenu) -> void:
	var layouts := CandyLayoutLibrary.quick_layouts()
	if layouts.is_empty():
		popup.add_separator(CandyLocale.t("Quick Layouts"))
		popup.add_item(CandyLocale.t("None yet (Settings > UI > Layouts)"))
		popup.set_item_disabled(popup.item_count - 1, true)
		return

	#Ł One heading per level when both are listed, to tell same names apart:
	var both_levels := false
	for layout in layouts:
		if layout["level"] != layouts[0]["level"]:
			both_levels = true
	if not both_levels:
		popup.add_separator(CandyLocale.t("Quick Layouts"))
	var current_level := ""
	for layout in layouts:
		if both_levels and layout["level"] != current_level:
			current_level = layout["level"]
			if current_level == CandyLayoutLibrary.LEVEL_USER:
				popup.add_separator(CandyLocale.t("Quick Layouts: User"))
			else:
				popup.add_separator(CandyLocale.t("Quick Layouts: Project"))
		popup.add_item(str(layout["name"]), QUICK_LAYOUT_FIRST_ID + _quick_layout_paths.size())
		_quick_layout_paths.append(layout["path"])


func _on_window_menu(id: int) -> void:
	if _layout_menu.handle_id(id):
		return
	match id:
		LayoutItem.EDIT_LAYOUT:
			CandyLayout.set_editing(not CandyLayout.is_editing())
			return
		LayoutItem.NEW_WINDOW:
			CandyLayout.open_window()
			return
		LayoutItem.RESET_LAYOUT:
			CandyLayout.reset_layout()
			return
	var index := id - QUICK_LAYOUT_FIRST_ID
	if index < 0 or index >= _quick_layout_paths.size():
		return
	_load_window_layout(CandyLayoutLibrary.read(str(_quick_layout_paths[index])).duplicate(true))


#* Load a window layout - replaces every window, and becomes the profile's:
func _load_window_layout(layout: Dictionary) -> void:
	if CandyLayout.apply_layout_data(layout):
		CandyLayout.save_layout()
	else:
		push_warning("Top bar: that window layout can't be used.")

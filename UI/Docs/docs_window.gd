#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsWindow
extends Window

const SETTING := "documentation"
const DEFAULT_SIZE := Vector2i(1200, 800)
const MIN_SIZE := Vector2i(720, 420)
#^ Seconds between a change and the setting being written:
const SAVE_DELAY := 1.0

enum DocsItem { DOWNLOAD, REFRESH, FOLDER, AUTO_CHECK }
#^ View menu - one id per look of CandyDocsLook.LOOKS from 0, then these:
enum ViewItem { ZOOM_IN = 100, ZOOM_OUT, ZOOM_RESET }

static var _window: CandyDocsWindow = null

var _content: VBoxContainer
var _docs_menu: PopupMenu
var _view_menu: PopupMenu
var _view: CandyDocsView
var _save_timer: Timer
#^ Placed once; then stays where the user leaves it:
var _placed := false


#* Open the Documentation window, or bring it to the front:
static func show_documentation(from: Node) -> void:
	if not is_instance_valid(_window):
		_window = CandyDocsWindow.new()
		CandyLocale.claim(_window)
		from.get_tree().root.add_child(_window)
	_window.open()


func _init() -> void:
	title = CandyLocale.t("Documentation")
	min_size = MIN_SIZE
	size = DEFAULT_SIZE
	#? Shown by open(), once placed.
	visible = false

	CandyThemeDefaults.add_background(self)
	_content = VBoxContainer.new()
	add_child(_content)

	var bar_frame := PanelContainer.new()
	bar_frame.theme_type_variation = CandyThemeDefaults.PANEL_FRAME
	_content.add_child(bar_frame)
	var bar := MenuBar.new()
	bar.flat = true
	bar.theme_type_variation = CandyThemeDefaults.FLAT_MENU_BAR
	#? Keep the menus in the window on macOS.
	bar.prefer_global_menu = false
	bar_frame.add_child(bar)
	_docs_menu = PopupMenu.new()
	_docs_menu.name = "Documentation"
	_docs_menu.about_to_popup.connect(_fill_docs_menu)
	_docs_menu.id_pressed.connect(_on_docs_menu)
	bar.add_child(_docs_menu)
	bar.set_menu_title(0, CandyLocale.t("Documentation"))
	_view_menu = PopupMenu.new()
	_view_menu.name = "View"
	_view_menu.about_to_popup.connect(_fill_view_menu)
	_view_menu.id_pressed.connect(_on_view_menu)
	bar.add_child(_view_menu)
	bar.set_menu_title(1, CandyLocale.t("View"))

	var view_frame := PanelContainer.new()
	view_frame.theme_type_variation = CandyThemeDefaults.PANEL_FRAME
	view_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(view_frame)
	_view = CandyDocsView.new()
	_view.state_changed.connect(_save_soon)
	view_frame.add_child(_view)

	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(_save)
	add_child(_save_timer)

	close_requested.connect(close)


func _enter_tree() -> void:
	#? Before the view is ready, so it's built with the theme.
	theme = CandyTheme.theme


func _ready() -> void:
	_fill_docs_menu()
	_fill_view_menu()
	_apply_spacing()
	CandyProfiles.profile_closing.connect(_save)
	CandyProfiles.profile_closed.connect(hide)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			if _content != null and is_inside_tree():
				_apply_spacing()
		NOTIFICATION_EXIT_TREE:
			#% App quitting with the window open:
			if visible:
				_save()


#* Use the layout windows' margin and gap (CandyAreaHost, CandyAreaSplit):
func _apply_spacing() -> void:
	var margin := get_theme_constant(&"margin", CandyThemeDefaults.AREA_HOST)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, margin)
	var gap := get_theme_constant(&"gap", CandyThemeDefaults.AREA_SPLIT)
	if has_theme_constant(&"locked_gap", CandyThemeDefaults.AREA_SPLIT):
		gap = get_theme_constant(&"locked_gap", CandyThemeDefaults.AREA_SPLIT)
	_content.add_theme_constant_override(&"separation", gap)


#& Opening and closing

#* Show the window as the profile last had it, or bring it to the front:
func open() -> void:
	if visible:
		if mode == Window.MODE_MINIMIZED:
			mode = Window.MODE_WINDOWED
		grab_focus()
		return
	var saved: Dictionary = {}
	if CandyProfiles.get_setting(SETTING) is Dictionary:
		saved = CandyProfiles.get_setting(SETTING)
	var view_state: Dictionary = {}
	if saved.get("view") is Dictionary:
		view_state = saved["view"]
	_view.set_state(view_state)
	_place(saved.get("rect"))
	show()
	CandyDocs.look_if_due()


#* Save and hide the window:
func close() -> void:
	_save()
	hide()


#* Place the window where the profile had it, or centered on the main window's screen:
func _place(rect: Variant) -> void:
	#! Never let Godot center it (WINDOW_INITIAL_POSITION_CENTER_...): its position
	#! stays (0, 0) until moved, and the menus pop up in the screen's corner.
	initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	if rect is Array and rect.size() == 4:
		var saved := Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))
		if saved.has_area() and _is_on_a_screen(saved):
			position = saved.position
			size = saved.size.max(MIN_SIZE)
			_placed = true
			return
	if not _placed:
		var screen := DisplayServer.window_get_current_screen(DisplayServer.MAIN_WINDOW_ID)
		var area := DisplayServer.screen_get_usable_rect(screen)
		size = DEFAULT_SIZE.min(area.size).max(MIN_SIZE)
		@warning_ignore("integer_division")
		position = area.position + (area.size - size) / 2
		_placed = true


func _is_on_a_screen(rect: Rect2i) -> bool:
	for screen in DisplayServer.get_screen_count():
		var screen_rect := Rect2i(DisplayServer.screen_get_position(screen), DisplayServer.screen_get_size(screen))
		if screen_rect.intersects(rect):
			return true
	return false


#& The profile's setting

func _save_soon() -> void:
	_save_timer.start()


#* Save the window's rect and view state, if changed:
func _save() -> void:
	_save_timer.stop()
	if not CandyProfiles.is_profile_open() or not _placed:
		return
	var data := {"rect": [position.x, position.y, size.x, size.y], "view": _view.get_state()}
	var saved: Variant = CandyProfiles.get_setting(SETTING)
	if saved is Dictionary and saved == data:
		return
	CandyProfiles.set_setting(SETTING, data.duplicate(true))


#& Menus

func _fill_docs_menu() -> void:
	_docs_menu.clear()
	if CandyDocs.has_downloads():
		_docs_menu.add_item(CandyLocale.t("Update Documentation"), DocsItem.DOWNLOAD)
		_docs_menu.set_item_tooltip(0, CandyLocale.t("Check GitHub for newer documentation of Candy Dialogue Engine and Candy Dialogue Creator, and download what changed."))
	else:
		_docs_menu.add_item(CandyLocale.t("Download Documentation"), DocsItem.DOWNLOAD)
		_docs_menu.set_item_tooltip(0, CandyLocale.t("Download the documentation of Candy Dialogue Engine and Candy Dialogue Creator from Candy Arts' official GitHub repository."))
	_docs_menu.set_item_disabled(0, CandyDocs.is_busy())
	_docs_menu.add_item(CandyLocale.t("Refresh"), DocsItem.REFRESH)
	_docs_menu.set_item_tooltip(1, CandyLocale.t("Read the documentation folder again, after adding or changing a database in it."))
	_docs_menu.add_item(CandyLocale.t("Open Documentation Folder"), DocsItem.FOLDER)
	_docs_menu.set_item_tooltip(2, CandyLocale.t("Where the documentation is kept. A database folder dropped here shows in the window after Refresh."))
	_docs_menu.add_separator()
	_docs_menu.add_check_item(CandyLocale.t("Look for Updates Once a Day"), DocsItem.AUTO_CHECK)
	var index := _docs_menu.get_item_index(DocsItem.AUTO_CHECK)
	_docs_menu.set_item_checked(index, CandyDocs.auto_check())
	_docs_menu.set_item_tooltip(index, CandyLocale.t("Ask GitHub, at most once a day, whether the downloaded documentation has changed.\nNothing is downloaded until you ask."))


func _on_docs_menu(id: int) -> void:
	match id:
		DocsItem.DOWNLOAD:
			CandyDocs.download()
		DocsItem.REFRESH:
			CandyDocs.rescan()
		DocsItem.FOLDER:
			OS.shell_open(CandyDocs.databases_folder())
		DocsItem.AUTO_CHECK:
			CandyDocs.set_auto_check(not CandyDocs.auto_check())


func _fill_view_menu() -> void:
	_view_menu.clear()
	for index in CandyDocsLook.LOOKS.size():
		var look := str(CandyDocsLook.LOOKS[index])
		_view_menu.add_radio_check_item(CandyLocale.t(str(CandyDocsLook.LOOK_LABELS[look])), index)
		_view_menu.set_item_checked(index, _view.look() == look)
		_view_menu.set_item_tooltip(index, CandyLocale.t(str(CandyDocsLook.LOOK_TOOLTIPS[look])))
	_view_menu.add_separator()
	_view_menu.add_item(CandyLocale.t("Increase Text Size"), ViewItem.ZOOM_IN)
	_view_menu.add_item(CandyLocale.t("Decrease Text Size"), ViewItem.ZOOM_OUT)
	_view_menu.add_item(CandyLocale.t("Reset Text Size"), ViewItem.ZOOM_RESET)
	_view_menu.set_item_tooltip(_view_menu.get_item_index(ViewItem.ZOOM_RESET), CandyLocale.t("Back to the size of Candy DC's own text."))


func _on_view_menu(id: int) -> void:
	match id:
		ViewItem.ZOOM_IN:
			_view.step_text_size(1)
		ViewItem.ZOOM_OUT:
			_view.step_text_size(-1)
		ViewItem.ZOOM_RESET:
			_view.reset_text_size()
		_:
			if id >= 0 and id < CandyDocsLook.LOOKS.size():
				_view.set_look(str(CandyDocsLook.LOOKS[id]))

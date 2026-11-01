#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaLeaf
extends VBoxContainer

enum MenuId { SPLIT_LEFT, SPLIT_RIGHT, SPLIT_UP, SPLIT_DOWN, PANEL_SETTINGS, OPEN_IN_WINDOW, CLOSE,
	SAVE_LAYOUT, SAVE_AREA_LAYOUT,
	#^ The context menu's Save Layout:
	CONTEXT_SAVE_LAYOUT = 50,
	#^ First id of the panel's own actions:
	PANEL_ACTION_FIRST = 100 }

var window_id: String
var data: CandyAreaData
var panel: Control = null

var _header: HBoxContainer
var _type_button: Button
var _type_popup: PopupMenu
var _title_label: Label
#^ The + at the start of the header:
var area_button: CandyAreaButton
var _menu_popup: PopupMenu
#^ Right-click menu outside Edit Layout mode:
var _context_popup: PopupMenu
var _content: PanelContainer
var _selector_ids: PackedStringArray = []
var _panel_actions: PackedStringArray = []
#^ Save / Load Panel Layout (CandyLayoutLibrary), one per menu:
var _layout_menu: CandyLayoutMenu
var _context_layout_menu: CandyLayoutMenu
#^ Save / Load Area Layout:
var _area_layout_menu: CandyLayoutMenu


func setup(p_window_id: String, p_data: CandyAreaData, p_panel: Control) -> void:
	window_id = p_window_id
	data = p_data
	theme_type_variation = CandyThemeDefaults.FLUSH_VBOX
	#? Set before the header - the + menu depends on the panel's settings.
	panel = p_panel

	custom_minimum_size = Vector2(CandyMinSizeFields.of_config(data.config))
	if data.show_header:
		custom_minimum_size = custom_minimum_size.max(Vector2(60, 40))
		_build_header()
		_header.visible = CandyLayout.is_editing()
		CandyLayout.editing_changed.connect(_on_editing_changed)
		_build_context_menu()

	_content = PanelContainer.new()
	_content.theme_type_variation = CandyThemeDefaults.PANEL_FRAME
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.clip_contents = true
	add_child(_content)

	_content.add_child(panel)


#* Detach the panel, for the host to reuse:
func take_panel() -> Control:
	var p := panel
	if p != null and p.get_parent() == _content:
		_content.remove_child(p)
	panel = null
	return p


func _build_header() -> void:
	_header = HBoxContainer.new()
	_header.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	_header.gui_input.connect(_on_header_gui_input)
	add_child(_header)

	_panel_actions = _get_panel_actions()
	area_button = CandyAreaButton.new()
	area_button.setup(data, func(anchor: Rect2i) -> PopupMenu:
			CandyPopups.popup_at(_menu_popup, anchor, self)
			return _menu_popup)
	_header.add_child(area_button)

	#Ł Plain Button with our own popup (MenuButton overrides its popup's placement):
	_type_button = Button.new()
	_type_button.flat = true
	_type_button.focus_mode = Control.FOCUS_NONE
	_type_button.tooltip_text = CandyLocale.t("Change panel type")
	_type_button.disabled = not data.can_change_panel
	_selector_ids = CandyPanels.get_selectable_ids()
	if not _selector_ids.has(data.panel_id):
		_selector_ids.insert(0, data.panel_id)
	_type_popup = PopupMenu.new()
	for i in _selector_ids.size():
		_type_popup.add_radio_check_item(CandyPanels.get_title(_selector_ids[i]), i)
		_type_popup.set_item_checked(i, _selector_ids[i] == data.panel_id)
	_type_popup.id_pressed.connect(_on_type_selected)
	add_child(_type_popup)
	_type_button.pressed.connect(func(): _open(_type_popup, _type_button))
	_header.add_child(_type_button)

	_title_label = Label.new()
	_title_label.text = CandyPanels.get_title(data.panel_id)
	_title_label.clip_text = true
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_title_label)

	var popup := PopupMenu.new()
	_menu_popup = popup
	add_child(popup)
	popup.add_item(CandyLocale.t("Split Left"), MenuId.SPLIT_LEFT)
	popup.add_item(CandyLocale.t("Split Right"), MenuId.SPLIT_RIGHT)
	popup.add_item(CandyLocale.t("Split Up"), MenuId.SPLIT_UP)
	popup.add_item(CandyLocale.t("Split Down"), MenuId.SPLIT_DOWN)
	popup.add_separator()
	popup.add_item(CandyLocale.t("Options"), MenuId.PANEL_SETTINGS)
	for i in _panel_actions.size():
		popup.add_item(_panel_actions[i], MenuId.PANEL_ACTION_FIRST + i)
	popup.add_separator()
	if panel is CandyPanel:
		_layout_menu = CandyLayoutMenu.new()
		_layout_menu.save_label = CandyLocale.t("Save Panel Layout...")
		_layout_menu.load_label = CandyLocale.t("Load Panel Layout")
		add_child(_layout_menu)
		_layout_menu.setup(CandyLayoutLibrary.PANELS, data.panel_id, _capture_layout, _apply_layout)
		_layout_menu.add_items(popup, MenuId.SAVE_LAYOUT)
	_area_layout_menu = CandyLayoutMenu.new()
	_area_layout_menu.save_label = CandyLocale.t("Save Area Layout...")
	_area_layout_menu.load_label = CandyLocale.t("Load Area Layout")
	add_child(_area_layout_menu)
	_area_layout_menu.setup(CandyLayoutLibrary.AREAS, "",
		func() -> Dictionary: return CandyLayout.area_layout(window_id, data.id),
		func(layout: Dictionary): CandyLayout.replace_area(window_id, data.id, layout))
	_area_layout_menu.add_items(popup, MenuId.SAVE_AREA_LAYOUT)
	popup.add_separator()
	popup.add_item(CandyLocale.t("Open in New Window"), MenuId.OPEN_IN_WINDOW)
	popup.add_separator()
	popup.add_item(CandyLocale.t("Close Area"), MenuId.CLOSE)
	popup.id_pressed.connect(_on_menu_id_pressed)
	popup.about_to_popup.connect(_refresh_menu)

	_update_selector_icon()


#* Build the panel's part of the Area menu (settings, actions, layouts):
func _build_context_menu() -> void:
	_context_popup = PopupMenu.new()
	add_child(_context_popup)
	_context_popup.add_item(CandyLocale.t("Options"), MenuId.PANEL_SETTINGS)
	for i in _panel_actions.size():
		_context_popup.add_item(_panel_actions[i], MenuId.PANEL_ACTION_FIRST + i)
	if panel is CandyPanel:
		_context_popup.add_separator()
		_context_layout_menu = CandyLayoutMenu.new()
		_context_layout_menu.save_label = CandyLocale.t("Save Panel Layout...")
		_context_layout_menu.load_label = CandyLocale.t("Load Panel Layout")
		add_child(_context_layout_menu)
		_context_layout_menu.setup(CandyLayoutLibrary.PANELS, data.panel_id, _capture_layout, _apply_layout)
		_context_layout_menu.add_items(_context_popup, MenuId.CONTEXT_SAVE_LAYOUT)
	_context_popup.id_pressed.connect(func(id: int):
		if _context_layout_menu != null and _context_layout_menu.handle_id(id):
			return
		_on_menu_id_pressed(id))


func _on_editing_changed(editing: bool) -> void:
	_header.visible = editing


func _input(event: InputEvent) -> void:
	if _content == null or _context_popup == null:
		return
	if not CandyPopups.is_context_click(event, _content):
		return
	var point := Vector2i(_content.get_screen_position() + _content.get_local_mouse_position())
	if CandyLayout.is_editing():
		CandyPopups.popup_at_point(_menu_popup, point, self)
	else:
		CandyPopups.popup_at_point(_context_popup, point, self)
	get_viewport().set_input_as_handled()


func _capture_layout() -> Dictionary:
	if panel is CandyPanel:
		return (panel as CandyPanel).get_state()
	return {}


func _apply_layout(layout: Dictionary) -> void:
	if panel is CandyPanel:
		(panel as CandyPanel).set_state(layout)


func _get_panel_actions() -> PackedStringArray:
	if panel is CandyPanel:
		return (panel as CandyPanel).get_area_actions()
	return PackedStringArray()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _type_button != null:
		_update_selector_icon()


func _update_selector_icon() -> void:
	#? Theme's dropdown arrow keeps the button narrow.
	if has_theme_icon("arrow", "OptionButton"):
		_type_button.icon = get_theme_icon("arrow", "OptionButton")
		_type_button.text = ""
	else:
		_type_button.text = "v"


#* Open a popup under a button (above it near the window's bottom):
func _open(popup: PopupMenu, button: Button) -> void:
	var anchor := Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size))
	CandyPopups.popup_at(popup, anchor, self)


func _refresh_menu() -> void:
	var popup := _menu_popup
	for id in [MenuId.SPLIT_LEFT, MenuId.SPLIT_RIGHT, MenuId.SPLIT_UP, MenuId.SPLIT_DOWN]:
		popup.set_item_disabled(popup.get_item_index(id), not data.can_split)
	popup.set_item_disabled(popup.get_item_index(MenuId.OPEN_IN_WINDOW),
		not CandyPanels.is_selectable(data.panel_id))
	popup.set_item_disabled(popup.get_item_index(MenuId.CLOSE),
		not CandyLayout.can_close_area(window_id, data.id))


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		CandyPopups.popup_at_point(_menu_popup,
			Vector2i(_header.get_screen_position() + event.position), self)
		_header.accept_event()


func _on_type_selected(id: int) -> void:
	CandyLayout.set_area_panel(window_id, data.id, _selector_ids[id])


func _on_menu_id_pressed(id: int) -> void:
	if _layout_menu != null and _layout_menu.handle_id(id):
		return
	if _area_layout_menu != null and _area_layout_menu.handle_id(id):
		return
	match id:
		MenuId.SPLIT_LEFT:
			CandyLayout.split_area(window_id, data.id, CandyAreaData.Layout.LEFT_RIGHT, true)
		MenuId.SPLIT_RIGHT:
			CandyLayout.split_area(window_id, data.id, CandyAreaData.Layout.LEFT_RIGHT, false)
		MenuId.SPLIT_UP:
			CandyLayout.split_area(window_id, data.id, CandyAreaData.Layout.TOP_BOTTOM, true)
		MenuId.SPLIT_DOWN:
			CandyLayout.split_area(window_id, data.id, CandyAreaData.Layout.TOP_BOTTOM, false)
		MenuId.PANEL_SETTINGS:
			if panel is CandyPanel:
				(panel as CandyPanel).open_panel_settings()
			else:
				CandyMinSizeDialog.open_for_area(self, window_id, data.id)
		MenuId.OPEN_IN_WINDOW:
			CandyLayout.open_window(data.panel_id)
		MenuId.CLOSE:
			CandyLayout.close_area(window_id, data.id)
		_:
			var index := id - MenuId.PANEL_ACTION_FIRST
			if index >= 0 and index < _panel_actions.size() and panel is CandyPanel:
				(panel as CandyPanel).run_area_action(_panel_actions[index])
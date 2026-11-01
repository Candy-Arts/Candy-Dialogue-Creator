#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLineAreaLeaf
extends VBoxContainer

signal edit_requested(action: String, area: CandyAreaData, argument: Variant)

enum MenuId { HEADING, SPLIT_LEFT, SPLIT_RIGHT, SPLIT_UP, SPLIT_DOWN, WIDGET_SETTINGS, CONFIGURE, SCROLL,
	CLOSE, SAVE_LAYOUT, SAVE_AREA_LAYOUT }

var area: CandyAreaData
var widget: CandyAreaWidget
#^ The + that opens the area's menu, Edit Layout mode only:
#? Not in the leaf: its frame shows it over the widget's corner (CandyAreaFrame.around_leaf()),
#? so Edit Layout mode doesn't move the widget.
var area_button: CandyAreaButton

var _line_type := ""
var _widget_ids: PackedStringArray = []
#^ Save / Load the widget's layout (CandyLayoutLibrary):
var _layout_menu: CandyLayoutMenu
#^ Save / Load Area Layout - this area with its widget and settings:
var _area_layout_menu: CandyLayoutMenu
var _content: PanelContainer
#^ The + menu in Edit Layout mode; the right-click menu otherwise:
var _menu_popup: PopupMenu
var _context_popup: PopupMenu


func setup(p_area: CandyAreaData, line_type: String, editing: bool, context: Dictionary = {}) -> void:
	area = p_area
	_line_type = line_type
	theme_type_variation = CandyThemeDefaults.FLUSH_VBOX
	custom_minimum_size = Vector2(CandyMinSizeFields.of_config(area.config))

	var content := PanelContainer.new()
	content.theme_type_variation = CandyThemeDefaults.WIDGET_FRAME
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.clip_contents = true
	add_child(content)
	_content = content

	widget = _instantiate_widget()
	widget.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(widget)

	#Ł Menu after the widget - it depends on it:
	if editing:
		_build_edit_menu()
	else:
		_context_popup = PopupMenu.new()
		_add_widget_items(_context_popup)
		_context_popup.id_pressed.connect(_on_menu_id_pressed)
		add_child(_context_popup)
	var widget_context := context.duplicate()
	widget_context["line_type"] = line_type
	widget.configure(area.panel_id, area.config, widget_context)
	widget.config_changed.connect(func(new_config: Dictionary):
		edit_requested.emit("config", area, new_config))
	widget.config_stored.connect(func(new_config: Dictionary):
		edit_requested.emit("store", area, new_config))


#* Its Save / Load Area Layout menu, null outside Edit Layout mode:
func area_layout_menu() -> CandyLayoutMenu:
	return _area_layout_menu


func bind_line(line_path: Array) -> void:
	widget.bind_line(line_path)


func apply_hidden_fields(hidden_fields: Dictionary) -> void:
	widget.apply_hidden_fields(hidden_fields)


func apply_hidden_parts(hidden_parts: Dictionary) -> void:
	widget.apply_hidden_parts(hidden_parts)


func _input(event: InputEvent) -> void:
	if _content == null or not CandyPopups.is_context_click(event, _content):
		return
	var popup := _context_popup
	if popup == null:
		popup = _menu_popup
	CandyPopups.popup_at_point(popup,
		Vector2i(_content.get_screen_position() + _content.get_local_mouse_position()), self)
	get_viewport().set_input_as_handled()


func _instantiate_widget() -> CandyAreaWidget:
	var node := CandyWidgets.instantiate_area(area.panel_id)
	return node


#* Build the + button and the Edit Layout menu:
func _build_edit_menu() -> void:
	var title := CandyWidgets.get_title(area.panel_id)
	area_button = CandyAreaButton.new()
	area_button.setup(area, func(anchor: Rect2i) -> PopupMenu:
			CandyPopups.popup_at(_menu_popup, anchor, self)
			return _menu_popup)
	area_button.tooltip_text = "%s: %s" % [CandyLocale.t(CandyAreaButton.TOOLTIP), title]

	var popup := PopupMenu.new()
	_menu_popup = popup
	add_child(popup)
	popup.add_separator(title, MenuId.HEADING)

	#Ł The widget picker:
	var picker := PopupMenu.new()
	_widget_ids = CandyWidgets.ids_of_kind("area")
	if not _widget_ids.has(area.panel_id):
		_widget_ids.insert(0, area.panel_id)
	for i in _widget_ids.size():
		picker.add_radio_check_item(CandyWidgets.get_title(_widget_ids[i]), i)
		picker.set_item_checked(i, _widget_ids[i] == area.panel_id)
	picker.id_pressed.connect(func(index: int):
		if _widget_ids[index] != area.panel_id:
			edit_requested.emit("widget", area, _widget_ids[index]))
	popup.add_submenu_node_item(CandyLocale.t("Widget"), picker)
	popup.add_separator()

	popup.add_item(CandyLocale.t("Split Left"), MenuId.SPLIT_LEFT)
	popup.add_item(CandyLocale.t("Split Right"), MenuId.SPLIT_RIGHT)
	popup.add_item(CandyLocale.t("Split Up"), MenuId.SPLIT_UP)
	popup.add_item(CandyLocale.t("Split Down"), MenuId.SPLIT_DOWN)
	popup.add_separator()
	_add_widget_items(popup)
	popup.add_separator()
	_layout_menu = CandyLayoutMenu.new()
	_layout_menu.save_label = CandyLocale.t("Save Widget Layout...")
	_layout_menu.load_label = CandyLocale.t("Load Widget Layout")
	add_child(_layout_menu)
	_layout_menu.setup(CandyLayoutLibrary.WIDGETS, area.panel_id,
		func() -> Dictionary: return area.config.duplicate(true),
		func(layout: Dictionary): edit_requested.emit("config", area, layout))
	_layout_menu.add_items(popup, MenuId.SAVE_LAYOUT)
	_area_layout_menu = CandyLayoutMenu.new()
	_area_layout_menu.save_label = CandyLocale.t("Save Area Layout...")
	_area_layout_menu.load_label = CandyLocale.t("Load Area Layout")
	add_child(_area_layout_menu)
	_area_layout_menu.setup(CandyLayoutLibrary.LINE_AREAS, "",
		func() -> Dictionary: return CandyLayoutLibrary.area_layout(area),
		func(layout: Dictionary): edit_requested.emit("replace", area, layout),
		func(layout: Dictionary) -> bool: return CandyLineLayouts.area_fits(layout, _line_type))
	_area_layout_menu.add_items(popup, MenuId.SAVE_AREA_LAYOUT)
	popup.add_separator()
	popup.add_item(CandyLocale.t("Close Area"), MenuId.CLOSE)
	popup.about_to_popup.connect(func():
		popup.set_item_disabled(popup.get_item_index(MenuId.CLOSE),
			area.get_parent_area() == null))
	popup.id_pressed.connect(_on_menu_id_pressed)


#* Add the widget's own items (Options, Fields..., Scroll) to a menu:
func _add_widget_items(popup: PopupMenu) -> void:
	popup.add_item(CandyLocale.t("Options"), MenuId.WIDGET_SETTINGS)
	if widget is CandyFieldsAreaWidget:
		popup.add_item(CandyLocale.t("Fields..."), MenuId.CONFIGURE)
		popup.set_item_tooltip(popup.get_item_index(MenuId.CONFIGURE),
			CandyLocale.t("Which fields this area shows, in what order, and over how many columns."))
	popup.add_check_item(CandyLocale.t("Scroll"), MenuId.SCROLL)
	popup.set_item_tooltip(popup.get_item_index(MenuId.SCROLL),
		CandyLocale.t("Scroll inside this area. Off, the area grows to fit, and the whole tab scrolls."))
	popup.about_to_popup.connect(func():
		popup.set_item_checked(popup.get_item_index(MenuId.SCROLL),
			bool(area.config.get("scroll", true))))


func _on_menu_id_pressed(id: int) -> void:
	if _layout_menu != null and _layout_menu.handle_id(id):
		return
	if _area_layout_menu != null and _area_layout_menu.handle_id(id):
		return
	match id:
		MenuId.SPLIT_LEFT:
			edit_requested.emit("split", area, [CandyAreaData.Layout.LEFT_RIGHT, true])
		MenuId.SPLIT_RIGHT:
			edit_requested.emit("split", area, [CandyAreaData.Layout.LEFT_RIGHT, false])
		MenuId.SPLIT_UP:
			edit_requested.emit("split", area, [CandyAreaData.Layout.TOP_BOTTOM, true])
		MenuId.SPLIT_DOWN:
			edit_requested.emit("split", area, [CandyAreaData.Layout.TOP_BOTTOM, false])
		MenuId.WIDGET_SETTINGS:
			if widget != null and widget.has_settings():
				widget.open_settings()
			else:
				edit_requested.emit("min_size", area, null)
		MenuId.CONFIGURE:
			edit_requested.emit("configure", area, widget)
		MenuId.SCROLL:
			edit_requested.emit("scroll", area, not bool(area.config.get("scroll", true)))
		MenuId.CLOSE:
			edit_requested.emit("close", area, null)
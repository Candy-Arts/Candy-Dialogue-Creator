#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLineLayoutHost
extends VBoxContainer

#^ The shown tab was built - picked, or moved by a tab edit:
signal tab_selected(tab_index: int)
#^ A tab's right-click menu asks for the Editor panel's Options:
signal options_requested

#^ The bottom dragger's place while the tab has no height of its own - past the bottom, held there:
const BOTTOM_FILL := 1000000.0
#^ Seconds after the bottom widgets last resized before the tab's ratios are stored:
const RATIO_STORE_DELAY := 0.4

#^ The Editor's line layouts, drawn and edited here:
var layouts: CandyLineLayoutSet
var line_type: String = ""
var line_path: Array = []
var tab_index: int = 0
var editing: bool = false

#^ The tabs, in a box the owner places (see take_tabs()):
var _tabs_box: VBoxContainer
var _tab_bar: HBoxContainer
#^ Reorders the tabs by dragging:
var _tab_reorder: CandyRowReorder
#^ A tab's right-click menu, and the tab it was opened on:
var _tab_menu: PopupMenu
var _menu_tab := -1
var _area_root: ScrollContainer
#^ Inside _area_root - keeps the tree off the scrollbar while there is one:
var _scroll_gap: MarginContainer
var _leaves: Array = []
var _view: Control
#^ Stores the tab's ratios once they stop changing (see _store_timer()):
var _ratio_store: Timer
var _ratio_store_type := ""
#^ The line the widgets were last bound to (see CandyAreaWidget.line_changing()):
var _bound_path: Array = []
#^ Shared by this host's widgets: the variation each reference shows:
var selection := CandyVariationSelection.new()
#^ Shared - the parent field each Field Tree reference shows:
var field_selection := CandyFieldSelection.new()
#^ Shared - the Voice Preview driving the Portrait Previews:
var portrait_sync := CandyPortraitSync.new()
#^ Applies the areas' edits to the shown tab's tree:
var _edits: CandyLineAreaEdits
#^ Dragging areas within the shown tab, in Edit Layout mode:
var _drag: CandyAreaDrag
var _name_prompt: CandyNamePrompt


func _ready() -> void:
	_tabs_box = VBoxContainer.new()
	add_child(_tabs_box)

	_tab_bar = HBoxContainer.new()
	_tabs_box.add_child(_tab_bar)
	_tab_reorder = CandyRowReorder.new(_tab_bar, _on_tab_moved)
	_build_tab_menu()

	#? Widgets with scrolling off report their full height; this scrolls the tree then.
	_area_root = ScrollContainer.new()
	_area_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#? The Editor doesn't grow wider: content wider than it scrolls instead of being cut.
	_area_root.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_area_root)

	_scroll_gap = MarginContainer.new()
	_scroll_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area_root.add_child(_scroll_gap)
	var bar := _area_root.get_v_scroll_bar()
	bar.visibility_changed.connect(func(): _show_scroll_gap(bar.visible))
	_show_scroll_gap(bar.visible)

	_edits = CandyLineAreaEdits.new()
	add_child(_edits)
	_edits.setup(func(root: CandyAreaData): layouts.set_root(line_type, tab_index, root),
		func(): layouts.save(line_type),
		func(): layouts.store(line_type))
	_drag = CandyAreaDrag.new(
		func(area: CandyAreaData) -> String: return CandyWidgets.get_title(area.panel_id),
		_edits.can_drop,
		func(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> void:
			_on_edit_requested("drop", target, [source, zone, mode]))

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	layouts.changed.connect(_on_layouts_changed)


func show_line(p_line_type: String, p_line_path: Array, p_tab_index: int) -> void:
	var type_changed := p_line_type != line_type
	line_type = p_line_type
	line_path = p_line_path.duplicate()
	tab_index = clampi(p_tab_index, 0, maxi(0, layouts.tab_count(line_type) - 1))
	if type_changed or _view == null:
		rebuild()
	else:
		bind_line()


#* Put bar right above the areas (the Editor's filter bar):
func add_bar(bar: Control) -> void:
	add_child(bar)
	move_child(bar, _area_root.get_index())


#* Take the tabs out, for the owner to place (still filled here):
func take_tabs() -> Control:
	remove_child(_tabs_box)
	return _tabs_box


func set_editing(value: bool) -> void:
	if editing == value:
		return
	editing = value
	rebuild()


func select_tab(index: int) -> void:
	if index == tab_index:
		return
	tab_index = index
	rebuild()


#& Building

func rebuild() -> void:
	if line_type == "":
		return
	_build_tabs()

	if _view != null:
		_scroll_gap.remove_child(_view)
		_view.queue_free()
	_leaves.clear()

	var root := layouts.get_root(line_type, tab_index)
	if root == null:
		return
	var root_view := _build_area(root)
	var reach := CandyBottomReach.new()
	reach.setup(root_view)
	#? Its ratios changed - kept once the dragging or resizing pauses.
	var line_type_now := line_type
	reach.ratios_changed.connect(func(): _store_timer(line_type_now).start())
	#? A leaf root may have its own minimum - the larger wins.
	reach.custom_minimum_size.y = layouts.tab_min_height(line_type, tab_index)
	_view = _with_bottom_dragger(reach)
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_gap.add_child(_view)
	bind_line()
	tab_selected.emit(tab_index)


#* The tab's widgets over an empty area, with a divider between them that sets how far down they reach:
#? A split of its own, outside the tab's tree: the tab keeps its height (CandyLineLayoutSet.tab_height()).
func _with_bottom_dragger(widgets: CandyBottomReach) -> CandyAreaSplit:
	var data := CandyAreaData.new()
	data.layout = CandyAreaData.Layout.TOP_BOTTOM
	data.size_mode = CandyAreaData.SizeMode.FIXED_FIRST
	var height: int = layouts.tab_height(line_type, tab_index)
	data.fixed_size = BOTTOM_FILL
	if height > 0:
		data.fixed_size = height
	var below := Control.new()
	below.mouse_filter = Control.MOUSE_FILTER_PASS
	var split := CandyAreaSplit.new()
	split.show_grip = true			#/ Nothing below it to show where it is
	split.double_click_size = BOTTOM_FILL			#/ Back to the bottom
	split.setup(data, widgets, below)
	var line_type_now := line_type
	var tab_now := tab_index
	var store_height := func():
		var stored := 0
		if data.fixed_size < BOTTOM_FILL:
			stored = roundi(data.fixed_size)
		layouts.set_tab_height(line_type_now, tab_now, stored)
	split.ratio_changed.connect(store_height)
	#Ł Widgets at the bottom hidden or shown - the dragger follows the widgets' bottom:
	widgets.move_dragger = func(to: float, down: bool) -> void:
		#% Back at the bottom of the page - reaching it again, as it follows the Editor's size:
		if down and to >= split.room_along() - 0.5:
			data.fixed_size = BOTTOM_FILL
		else:
			data.fixed_size = maxf(to, 0.0)
		split.queue_sort()
		store_height.call()
	return split


#* The timer that stores the tab's ratios once the bottom dragger, or the Editor's size, stops changing:
func _store_timer(type: String) -> Timer:
	if _ratio_store == null:
		_ratio_store = Timer.new()
		_ratio_store.one_shot = true
		_ratio_store.wait_time = RATIO_STORE_DELAY
		_ratio_store.timeout.connect(func(): layouts.store(_ratio_store_type))
		add_child(_ratio_store)
	_ratio_store_type = type
	return _ratio_store


func _build_area(area: CandyAreaData) -> Control:
	if area.is_leaf():
		var leaf := CandyLineAreaLeaf.new()
		leaf.setup(area, line_type, editing,
			{"selection": selection, "field_selection": field_selection, "portrait_sync": portrait_sync,
				"line_layouts": layouts})
		leaf.edit_requested.connect(_on_edit_requested)
		_leaves.append(leaf)
		if editing:
			return CandyAreaCap.around(CandyAreaFrame.around_leaf(leaf, leaf.area_button, &"editor", _drag), area.config)
		return CandyAreaCap.around(leaf, area.config)

	var split := CandyAreaSplit.new()
	split.setup(area, _build_area(area.first), _build_area(area.second))
	#? Dragging a divider is a layout edit - save it.
	split.ratio_changed.connect(func(): layouts.save(line_type))
	#% The split's menu only exists in Edit Layout mode:
	if editing:
		split.enable_menu(CandyWidgets.get_title, Callable())
		split.enable_layouts(CandyLayoutLibrary.LINE_AREAS,
			func(split_area: CandyAreaData) -> Dictionary: return CandyLayoutLibrary.area_layout(split_area),
			func(layout: Dictionary) -> bool: return CandyLineLayouts.area_fits(layout, line_type))
		split.edit_requested.connect(_on_edit_requested)
		return CandyAreaFrame.around_split(split, &"editor")
	return split


func _show_scroll_gap(shown: bool) -> void:
	if shown:
		_scroll_gap.theme_type_variation = CandyThemeDefaults.SCROLL_GAP
	else:
		_scroll_gap.theme_type_variation = &""


func bind_line() -> void:
	if not CandyDialogue.is_line_path(line_path):
		return
	var hidden_targets := CandyFilters.hidden_targets(layouts, line_type, tab_index)
	for leaf in _leaves:
		#Ł Hide filtered widgets, in Edit Layout mode too (the split gives their space to the other side):
		leaf.visible = not CandyFilters.is_area_hidden(hidden_targets, leaf.area)
	if line_path != _bound_path:
		#% New line - every shown widget hears it before any binds it:
		_bound_path = line_path.duplicate()
		for leaf in _leaves:
			if leaf.visible:
				leaf.widget.line_changing(line_path)
	for leaf in _leaves:
		if not leaf.visible:
			continue
		leaf.apply_hidden_fields(CandyFilters.fields_hidden_in(hidden_targets, leaf.area))
		leaf.apply_hidden_parts(CandyFilters.parts_hidden_in(hidden_targets, leaf.area))
		leaf.bind_line(line_path)


func _build_tabs() -> void:
	for child in _tab_bar.get_children():
		_tab_bar.remove_child(child)
		child.queue_free()
	_tab_reorder.clear()

	#? In a group, clicking the shown tab doesn't untoggle it.
	var group := ButtonGroup.new()
	var tabs := layouts.tabs(line_type)
	for i in tabs.size():
		var button := Button.new()
		button.text = str(tabs[i]["name"])
		button.theme_type_variation = CandyThemeDefaults.EDITOR_TAB
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == tab_index
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = CandyLocale.t("Drag to move the tab. Right-click for its options.")
		button.pressed.connect(select_tab.bind(i))
		button.gui_input.connect(_on_tab_gui_input.bind(i, button))
		button.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
		_tab_bar.add_child(button)
		_tab_reorder.add_item(button)

	var add_tab := Button.new()
	add_tab.text = "+"
	add_tab.theme_type_variation = CandyThemeDefaults.EDITOR_TAB_ADD
	add_tab.focus_mode = Control.FOCUS_NONE
	add_tab.tooltip_text = CandyLocale.t("Add a tab")
	add_tab.pressed.connect(_on_add_tab)
	_tab_bar.add_child(add_tab)


#& Tab menu

enum TabMenuId { RENAME, MIN_HEIGHT, REMOVE, ADD, RESET, OPTIONS }

func _build_tab_menu() -> void:
	_tab_menu = PopupMenu.new()
	_tab_menu.add_item(CandyLocale.t("Rename Tab..."), TabMenuId.RENAME)
	_tab_menu.add_item(CandyLocale.t("Minimum Height..."), TabMenuId.MIN_HEIGHT)
	_tab_menu.set_item_tooltip(_tab_menu.get_item_index(TabMenuId.MIN_HEIGHT),
		CandyLocale.t("Below this height, the tab's areas stop shrinking and the tab scrolls."))
	_tab_menu.add_item(CandyLocale.t("Remove Tab"), TabMenuId.REMOVE)
	_tab_menu.add_separator()
	_tab_menu.add_item(CandyLocale.t("Add Tab..."), TabMenuId.ADD)
	_tab_menu.add_item(CandyLocale.t("Reset Layout"), TabMenuId.RESET)
	_tab_menu.set_item_tooltip(_tab_menu.get_item_index(TabMenuId.RESET),
		CandyLocale.t("Every tab of this line type goes back to its default layout."))
	_tab_menu.add_separator()
	_tab_menu.add_item(CandyLocale.t("Options"), TabMenuId.OPTIONS)
	_tab_menu.id_pressed.connect(_on_tab_menu_id_pressed)
	add_child(_tab_menu)


func _on_tab_gui_input(event: InputEvent, index: int, button: Button) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_RIGHT:
		return
	_menu_tab = index
	_tab_menu.set_item_disabled(_tab_menu.get_item_index(TabMenuId.REMOVE), layouts.tab_count(line_type) <= 1)
	_tab_menu.set_item_disabled(_tab_menu.get_item_index(TabMenuId.OPTIONS), not options_requested.has_connections())
	CandyPopups.popup_at_point(_tab_menu, Vector2i(button.get_screen_position() + mouse.position), self)
	button.accept_event()


func _on_tab_menu_id_pressed(id: int) -> void:
	match id:
		TabMenuId.RENAME:
			_on_rename_tab(_menu_tab)
		TabMenuId.MIN_HEIGHT:
			_on_tab_min_height(_menu_tab)
		TabMenuId.REMOVE:
			_on_remove_tab(_menu_tab)
		TabMenuId.ADD:
			_on_add_tab()
		TabMenuId.RESET:
			_on_reset()
		TabMenuId.OPTIONS:
			options_requested.emit()


#& Edits

func _on_edit_requested(action: String, area: CandyAreaData, argument: Variant) -> void:
	_edits.line_type = line_type
	_edits.apply(action, area, argument)


#? Tab edits rebuild the view (layouts changed) before the new tab index is
#? known, so they rebuild again once it is.

func _on_add_tab() -> void:
	_prompt_name(CandyLocale.t("New Tab"), "Tab", func(tab_name: String):
		tab_index = layouts.add_tab(line_type, tab_name)
		rebuild())


func _on_rename_tab(index: int) -> void:
	var tabs := layouts.tabs(line_type)
	if index < 0 or index >= tabs.size():
		return
	var line_type_now := line_type
	_prompt_name(CandyLocale.t("Rename Tab"), str(tabs[index]["name"]), func(tab_name: String):
		layouts.rename_tab(line_type_now, index, tab_name))


func _on_remove_tab(index: int) -> void:
	if not layouts.remove_tab(line_type, index):
		return
	#Ł The shown tab stays shown, or its left neighbour takes the place of a removed one:
	if index < tab_index or (index == tab_index and tab_index > 0):
		tab_index -= 1
	rebuild()


#* A tab dragged to another place; the shown tab stays shown:
func _on_tab_moved(from: int, to: int) -> void:
	var shown := tab_index
	if not layouts.move_tab(line_type, from, to):
		return
	if shown == from:
		tab_index = to
	elif from < shown and to >= shown:
		tab_index = shown - 1
	elif from > shown and to <= shown:
		tab_index = shown + 1
	rebuild()


func _on_tab_min_height(index: int) -> void:
	var line_type_now := line_type
	_prompt_height(CandyLocale.t("Tab Minimum Height"), layouts.tab_min_height(line_type, index), func(height: int):
		layouts.set_tab_min_height(line_type_now, index, height))


func _on_reset() -> void:
	layouts.reset(line_type)
	tab_index = 0
	rebuild()


func _prompt_name(title: String, initial: String, on_submit: Callable) -> void:
	_name_prompt.prompt(title, initial, func(_value: String) -> String: return "", on_submit)


#* Ask for a height in pixels (0 for none), passed on as an int:
func _prompt_height(title: String, initial: int, on_submit: Callable) -> void:
	var hint := CandyLocale.t("Type a height in pixels, or 0 for none.")
	_name_prompt.prompt(CandyLocale.t("%s (pixels, 0 for none)") % title, str(initial),
		func(value: String) -> String:
			if not value.is_valid_int() or int(value) < 0:
				return hint
			return "",
		func(value: String): on_submit.call(int(value)),
		hint)


#* Rebuild when this line type's layouts change ("" = the whole set was replaced):
func _on_layouts_changed(changed_type: String) -> void:
	if changed_type == line_type or changed_type == "":
		tab_index = clampi(tab_index, 0, maxi(0, layouts.tab_count(line_type) - 1))
		rebuild()
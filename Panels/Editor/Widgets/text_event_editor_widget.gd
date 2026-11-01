#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTextEventEditorWidget
extends CandyAreaWidget

const EVENTS_FIELD := "Text_Events"
const EVENTS_KEY := "Events"
const LINES_KEY := "Lines"
const NEW_PATTERN := "*"
const NEW_EVENT := "Event_1"
#^ The category listed first in the + Command menu:
const TEXT_EVENT_CATEGORY := "Text Events"
const DEFAULT_TREE_HEIGHT := 200
#^ The tree's least height: a few rows:
const MIN_TREE_HEIGHT := 60
#^ The embedded editor's least height:
#? It fills the room under the tree (its forms scroll), so a tall tree can't squeeze it away.
const MIN_EDITOR_HEIGHT := 240
const EMPTY_TEXT := "Select a command in the list above."  #/ translatable
const HINT_TEXT := "Add a variation pattern (* for every variation), then events in it, then the commands each event runs. A marker in the text runs its event: ‹start›name‹end›."  #/ translatable

var _tree: Tree
var _add_event_button: Button
var _add_command_button: MenuButton
var _up_button: Button
var _down_button: Button
var _remove_button: Button
var _hint: Label
var _form_holder: VBoxContainer
var _event_form: CandyFieldForm
#^ The base path the event form was built for ([] for none):
var _form_base: Array = []
var _editor: CandyDialogueEditorPanel
var _line_path: Array = []
#^ The selected row - [pattern], [pattern, event] or [pattern, event, command index]; [] for none:
var _selected: Array = []
#^ A row to start renaming once the tree is rebuilt, after adding it:
var _rename_next: Array = []
#^ Set while the tree selects a row in code (see _rebuild_tree()):
var _rebuilding := false
var _settings: CandyTextEventEditorSettings
#^ The bar under the tree that sets its height:
var _grabber: Control
#^ While dragging the grabber - the pointer's height and the tree's at press:
var _drag_from := -1.0
var _drag_height := 0.0


#* Needs the line's Text_Events:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, EVENTS_FIELD)


func _on_configured() -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	box.add_child(_build_toolbar())

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.custom_minimum_size.y = tree_height_of(config)
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.select_mode = Tree.SELECT_ROW
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	#? Commands drag to other places (see Dragging).
	_tree.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	_tree.item_edited.connect(_on_item_edited)
	box.add_child(_tree)

	box.add_child(_build_grabber())

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(details)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.theme_type_variation = CandyThemeDefaults.NOTE
	details.add_child(_hint)

	_form_holder = VBoxContainer.new()
	_form_holder.visible = false
	details.add_child(_form_holder)

	_editor = CandyDialogueEditorPanel.new()
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.custom_minimum_size.y = MIN_EDITOR_HEIGHT
	_editor.visible = false
	#? Fixed before entering the tree, as in the Command Editor (else it would nest itself).
	_editor.show_fixed([], CandyLocale.t(EMPTY_TEXT))
	var layouts := line_layouts()
	if layouts != null:
		_editor.use_layouts(layouts)
	details.add_child(_editor)

	if scrolls():
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(scroll)
		var gap := MarginContainer.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(gap)
		gap.add_child(box)
		var bar := scroll.get_v_scroll_bar()
		bar.visibility_changed.connect(func(): _show_gap(gap, bar.visible))
		_show_gap(gap, bar.visible)
	else:
		#? Without its own scroll, the widget is as tall as everything in it - its area grows.
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(box)
		var fit := func(): custom_minimum_size.y = box.get_combined_minimum_size().y
		box.minimum_size_changed.connect(fit)
		fit.call_deferred()


func _build_toolbar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_child(_tool_button(CandyLocale.t("+ Variation"), CandyLocale.t("Add a variation pattern: * for every variation, Default* for those starting with Default, or a variation's exact name."), _on_add_pattern))
	_add_event_button = _tool_button(CandyLocale.t("+ Event"), CandyLocale.t("Add an event to the selected variation pattern."), _on_add_event)
	bar.add_child(_add_event_button)

	_add_command_button = MenuButton.new()
	_add_command_button.text = CandyLocale.t("+ Command")
	_add_command_button.tooltip_text = CandyLocale.t("Add a command to the selected event, after the selected command.")
	_add_command_button.flat = false
	_add_command_button.focus_mode = Control.FOCUS_NONE
	_add_command_button.about_to_popup.connect(_fill_command_menu)
	bar.add_child(_add_command_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	_up_button = _icon_button(&"move_up", "^", CandyLocale.t("Move up"), func(): _move_selected(-1))
	bar.add_child(_up_button)
	_down_button = _icon_button(&"move_down", "v", CandyLocale.t("Move down"), func(): _move_selected(1))
	bar.add_child(_down_button)
	_remove_button = _icon_button(&"remove", "×", CandyLocale.t("Remove"), _remove_selected)
	bar.add_child(_remove_button)
	return bar


func _tool_button(text: String, tooltip: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


#* A CandyIcons icon button, with fallback_text for a theme that has none:
func _icon_button(icon_name: StringName, fallback_text: String, tooltip: String, handler: Callable) -> Button:
	var button := CandyIconButton.new(icon_name, CandyThemeDefaults.ICONS, fallback_text, tooltip)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


func _show_gap(gap: MarginContainer, shown: bool) -> void:
	if shown:
		gap.theme_type_variation = CandyThemeDefaults.SCROLL_GAP
	else:
		gap.theme_type_variation = &""


#& Settings

#* The tree's height in a config, never under MIN_TREE_HEIGHT:
static func tree_height_of(widget_config: Dictionary) -> int:
	return maxi(MIN_TREE_HEIGHT, int(widget_config.get("tree_height", DEFAULT_TREE_HEIGHT)))


func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings == null:
		_settings = CandyTextEventEditorSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config)


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	#? Saving usually rebuilds this widget; not in every context.
	_tree.custom_minimum_size.y = tree_height_of(config)


#& Grabber
#? A bar under the tree, drawn like a VSplitContainer's grabber, setting the tree's height.
#? Not a split: it would share out its room (squeezing the tree), and can't grow while scrolling.

func _build_grabber() -> Control:
	_grabber = Control.new()
	_grabber.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grabber.mouse_default_cursor_shape = Control.CURSOR_VSPLIT
	_grabber.tooltip_text = CandyLocale.t("Drag to change the height of the list.")
	_grabber.draw.connect(_draw_grabber)
	_grabber.gui_input.connect(_on_grabber_input)
	_grabber.theme_changed.connect(_size_grabber)
	_size_grabber()
	return _grabber


#* As tall as a VSplitContainer's grabber and separation:
func _size_grabber() -> void:
	var height := float(_grabber.get_theme_constant(&"separation", &"VSplitContainer"))
	var icon := _grabber_icon()
	if icon != null:
		height = maxf(height, icon.get_height())
	_grabber.custom_minimum_size.y = maxf(height, 6.0)
	_grabber.queue_redraw()


func _grabber_icon() -> Texture2D:
	for item in [[&"v_grabber", &"SplitContainer"], [&"grabber", &"VSplitContainer"]]:
		if _grabber.has_theme_icon(item[0], item[1]):
			return _grabber.get_theme_icon(item[0], item[1])
	return null


func _draw_grabber() -> void:
	var icon := _grabber_icon()
	if icon != null:
		_grabber.draw_texture(icon, (_grabber.size - icon.get_size()) / 2.0)


#* Dragging resizes the tree at once; letting go stores it:
func _on_grabber_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_from = event.global_position.y
			_drag_height = _tree.custom_minimum_size.y
		elif _drag_from >= 0.0:
			_drag_from = -1.0
			_store_tree_height()
		_grabber.accept_event()
	elif event is InputEventMouseMotion and _drag_from >= 0.0:
		var height: float = _drag_height + event.global_position.y - _drag_from
		_tree.custom_minimum_size.y = tree_height_of({"tree_height": int(round(height))})
		_grabber.accept_event()


#* Store the tree's height in the config, without rebuilding (the widget already shows it):
func _store_tree_height() -> void:
	var height := tree_height_of({"tree_height": int(round(_tree.custom_minimum_size.y))})
	if height == tree_height_of(config):
		return
	var new_config := config.duplicate(true)
	new_config["tree_height"] = height
	store_config(new_config)


#& Binding

func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	_rebuild_tree()
	_show_detail()


#* Rebuild the tree from the line, keeping the selected row when it's still there:
func _rebuild_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var selected_item: TreeItem = null
	var rename_item: TreeItem = null

	for pattern in _patterns():
		var pattern_item := _add_row(root, str(pattern), [pattern], CandyLocale.t("Variation pattern. Double-click to rename."))
		if [pattern] == _selected:
			selected_item = pattern_item
		if [pattern] == _rename_next:
			rename_item = pattern_item
		for event_name in _events(pattern):
			var event_item := _add_row(pattern_item, str(event_name), [pattern, event_name],
				CandyLocale.t("Event %s. Double-click to rename.") % CandyTextEventMarkers.marker(str(event_name)))
			if [pattern, event_name] == _selected:
				selected_item = event_item
			if [pattern, event_name] == _rename_next:
				rename_item = event_item
			var commands := _commands(pattern, event_name)
			for index in commands.size():
				var line = commands[index]
				#? Numbered from 1, as in the Navigator - "1 | Set: …".
				var text := "%d | ?" % (index + 1)
				if line is Dictionary:
					text = CandyDialogue.describe_line(line, index + 1, CandyDialogue.DisplayMode.SHORT)
				var command_item := _add_row(event_item, text, [pattern, event_name, index], "")
				if [pattern, event_name, index] == _selected:
					selected_item = command_item

	if selected_item == null:
		_selected = []
	else:
		#? Selecting in code emits item_selected - bind_line() shows the details itself.
		_rebuilding = true
		selected_item.select(0)
		_rebuilding = false
		_tree.scroll_to_item(selected_item)
	_rename_next = []
	if rename_item != null:
		_start_rename(rename_item)
	_update_buttons()


func _add_row(parent: TreeItem, text: String, row: Array, tooltip: String) -> TreeItem:
	var item := _tree.create_item(parent)
	item.set_text(0, text)
	item.set_metadata(0, row)
	if tooltip != "":
		item.set_tooltip_text(0, tooltip)
	return item


func _update_buttons() -> void:
	_add_event_button.disabled = _selected.is_empty()
	_add_command_button.disabled = _selected.size() < 2
	_up_button.disabled = _selected.is_empty() or _sibling_index() <= 0
	_down_button.disabled = _selected.is_empty() or _sibling_index() >= _sibling_count() - 1
	_remove_button.disabled = _selected.is_empty()
	var pair := CandyTextEventMarkers.symbols()
	_hint.text = CandyLocale.t(HINT_TEXT).replace("‹start›", pair[0]).replace("‹end›", pair[1])
	_hint.visible = _patterns().is_empty()


#& Selection and details

func _on_item_selected() -> void:
	var item := _tree.get_selected()
	if item == null or _rebuilding:
		return
	_selected = (item.get_metadata(0) as Array).duplicate()
	_update_buttons()
	_show_detail()


#* Show the event's fields for an event, the embedded editor for a command:
func _show_detail() -> void:
	if _selected.size() == 3:
		_form_holder.visible = false
		_editor.visible = true
		var line = _commands(_selected[0], _selected[1])[int(_selected[2])]
		var type := ""
		if line is Dictionary:
			type = CandyDialogue.line_type(line)
		_editor.show_fixed(_event_path(_selected[0], _selected[1]) + [LINES_KEY, int(_selected[2]), type], CandyLocale.t(EMPTY_TEXT))
		return

	_editor.visible = false
	if _selected.size() == 2:
		#? A form's base is a field path inside the line, not a line path.
		var base := _event_field(_selected[0], _selected[1])
		if base != _form_base or _event_form == null:
			_build_event_form(base)
		_form_holder.visible = true
		_event_form.bind_line(_line_path)
		return
	_form_holder.visible = false


func _build_event_form(base: Array) -> void:
	if _event_form != null:
		_event_form.queue_free()
	_event_form = CandyFieldForm.new()
	_form_holder.add_child(_event_form)
	var line := CandyDialogue.line_at(_line_path)
	var line_type := CandyDialogue.line_type(line)
	_event_form.build(_event_specs(line_type), base, {"line_type": line_type},
		[EVENTS_FIELD, EVENTS_KEY])
	_form_base = base.duplicate()


#& Renaming

func _on_item_activated() -> void:
	var item := _tree.get_selected()
	if item != null and (item.get_metadata(0) as Array).size() < 3:
		_start_rename(item)


func _start_rename(item: TreeItem) -> void:
	item.set_editable(0, true)
	item.select(0)
	_tree.edit_selected(true)


#* Rename a frame later (it rebuilds the tree, which can't be cleared in its own signal):
func _on_item_edited() -> void:
	var item := _tree.get_edited()
	if item == null:
		return
	item.set_editable(0, false)
	var row: Array = (item.get_metadata(0) as Array).duplicate()
	var new_name := item.get_text(0).strip_edges()
	_rename.call_deferred(row, new_name)


func _rename(row: Array, new_name: String) -> void:
	if not CandyDialogue.is_line_path(_line_path):
		return
	var name_changed := false
	if row.size() == 1:
		name_changed = CandyDialogue.rename_map_entry(_line_path, [EVENTS_FIELD], str(row[0]), new_name)
		if name_changed:
			_selected = [new_name]
	elif row.size() == 2:
		name_changed = CandyDialogue.rename_map_entry(_line_path, [EVENTS_FIELD, row[0], EVENTS_KEY], str(row[1]), new_name)
		if name_changed:
			_selected = [row[0], new_name]
	#% Refused (empty, or already used) - the stored name comes back:
	if not name_changed:
		_rebuild_tree()


#& Adding

func _on_add_pattern() -> void:
	if not CandyDialogue.is_line_path(_line_path):
		return
	var key := CandyDialogue.add_map_entry(_line_path, [EVENTS_FIELD], NEW_PATTERN,
		CandySchemas.entry_defaults(_events_spec(_current_type())))
	if key != "":
		_select_after_edit([key], true)


func _on_add_event() -> void:
	if _selected.is_empty():
		return
	var pattern = _selected[0]
	var key := CandyDialogue.add_map_entry(_line_path, [EVENTS_FIELD, pattern, EVENTS_KEY], NEW_EVENT,
		CandySchemas.entry_defaults(_event_spec(_current_type())))
	if key != "":
		_select_after_edit([pattern, key], true)


#* Fill the + Command menu - command types by category, Text Events first:
func _fill_command_menu() -> void:
	var menu := _add_command_button.get_popup()
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu.clear()

	var by_category := {}
	var categories: Array = []
	for type in CandySchemas.line_types():
		var category := CandySchemas.get_category(str(type))
		if not by_category.has(category):
			by_category[category] = []
			categories.append(category)
		by_category[category].append(str(type))
	if categories.has(TEXT_EVENT_CATEGORY):
		categories.erase(TEXT_EVENT_CATEGORY)
		categories.insert(0, TEXT_EVENT_CATEGORY)

	for category in categories:
		var submenu := PopupMenu.new()
		for type in by_category[category]:
			submenu.add_item(CandyLocale.command_title(CandySchemas.get_title(type)))
			submenu.set_item_metadata(submenu.item_count - 1, type)
		submenu.index_pressed.connect(func(index: int): _add_command(str(submenu.get_item_metadata(index))))
		var title := CandyLocale.t(str(category))
		if title == "":
			title = CandyLocale.t("Other")
		menu.add_submenu_node_item(title, submenu)


#* Append a command to the selected event, then move it after the selected command:
func _add_command(type: String) -> void:
	if _selected.size() < 2:
		return
	var pattern = _selected[0]
	var event_name = _selected[1]
	var list_path := _lines_field(pattern, event_name)
	CandyDialogue.begin_step(CandyLocale.t("Add {command} to text event {event}").format({"command": CandyLocale.command_title(CandySchemas.get_title(type)), "event": event_name}))
	var index := CandyDialogue.add_entry(_line_path, list_path, "", CandySchemas.default_line(type))
	if index >= 0 and _selected.size() == 3 and int(_selected[2]) + 1 < index:
		if CandyDialogue.move_entry(_line_path, list_path, index, int(_selected[2]) + 1):
			index = int(_selected[2]) + 1
	CandyDialogue.end_step()
	if index >= 0:
		_select_after_edit([pattern, event_name, index], false)


#* Select a row once the edit that added it has rebuilt the tree:
func _select_after_edit(row: Array, rename: bool) -> void:
	_selected = row
	if rename:
		_rename_next = row
	if CandyDialogue.is_line_path(_line_path):
		bind_line(_line_path)


#& Moving and removing

func _move_selected(offset: int) -> void:
	var index := _sibling_index()
	if index < 0:
		return
	var to_index := index + offset
	if _selected.size() == 3:
		var list_path := _lines_field(_selected[0], _selected[1])
		var row := [_selected[0], _selected[1], to_index]
		if CandyDialogue.move_entry(_line_path, list_path, index, to_index):
			_select_after_edit(row, false)
	elif _selected.size() == 2:
		var row := _selected.duplicate()
		if CandyDialogue.move_map_entry(_line_path, [EVENTS_FIELD, _selected[0], EVENTS_KEY], str(_selected[1]), to_index):
			_select_after_edit(row, false)
	elif _selected.size() == 1:
		var row := _selected.duplicate()
		if CandyDialogue.move_map_entry(_line_path, [EVENTS_FIELD], str(_selected[0]), to_index):
			_select_after_edit(row, false)


func _remove_selected() -> void:
	if _selected.is_empty():
		return
	var row := _selected.duplicate()
	var target_line := _line_path.duplicate()
	if row.size() == 3:
		var list_path := _lines_field(row[0], row[1])
		var line = _commands(row[0], row[1])[int(row[2])]
		var title := "?"
		if line is Dictionary:
			title = CandyLocale.command_title(CandySchemas.get_title(CandyDialogue.line_type(line)))
		CandyConfirmPrompt.ask_remove(self, CandyLocale.t("command"), "%d. %s" % [int(row[2]) + 1, title], func():
			CandyDialogue.remove_entry(target_line, list_path, int(row[2])))
	elif row.size() == 2:
		CandyConfirmPrompt.ask_remove(self, CandyLocale.t("event"), str(row[1]), func():
			CandyDialogue.remove_map_entry(target_line, [EVENTS_FIELD, row[0], EVENTS_KEY], str(row[1])))
	else:
		CandyConfirmPrompt.ask_remove(self, CandyLocale.t("variation pattern"), str(row[0]), func():
			CandyDialogue.remove_map_entry(target_line, [EVENTS_FIELD], str(row[0])))


#& Dragging

#^ The drag data's key holding a dragged command's row:
const DRAG_KEY := "candy_text_event_command"


#* Drag data for a command (only commands drag) - its row, and this widget's id:
func _get_drag_data(at_position: Vector2) -> Variant:
	var item := _tree.get_item_at_position(at_position)
	if item == null:
		return null
	var row: Array = item.get_metadata(0)
	if row.size() != 3:
		return null
	#? The Tree clears its drop flags when a drag ends - set them for each drag.
	_tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	var preview := Label.new()
	preview.text = item.get_text(0)
	_tree.set_drag_preview(preview)
	return {DRAG_KEY: row.duplicate(), "widget": get_instance_id()}			#/ The id keeps another Text Event Editor's tree from taking it


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return _dragged_row(data).size() == 3 and not _drop_target(at_position).is_empty()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source := _dragged_row(data)
	var target := _drop_target(at_position)
	if source.size() != 3 or target.is_empty():
		return
	move_command(source, target["pattern"], target["event"], int(target["index"]))


#* The row a drag carries, or [] when it isn't a command of this widget:
func _dragged_row(data: Variant) -> Array:
	if not data is Dictionary or not data.has(DRAG_KEY) or data.get("widget") != get_instance_id():
		return []
	return data[DRAG_KEY]


#* Where a command dropped at at_position goes - { "pattern", "event", "index" }, {} for nowhere:
#? index: its place in the event's list once there.
func _drop_target(at_position: Vector2) -> Dictionary:
	var item := _tree.get_item_at_position(at_position)
	if item == null:
		return {}
	var row: Array = item.get_metadata(0)
	var section := _tree.get_drop_section_at_position(at_position)
	#¦ 1. Before a command when above it, after it when on or below it:
	if row.size() == 3:
		var index := int(row[2])
		if section >= 0:
			index += 1
		return {"pattern": row[0], "event": row[1], "index": index}
	#¦ 2. On an event - the end of its list:
	if row.size() == 2:
		return {"pattern": row[0], "event": row[1], "index": _commands(row[0], row[1]).size()}
	return {}			#/ Patterns take nothing


#* Move row's command ([pattern, event, index]) into target_event's list at to_index, one undo step:
#? to_index counts the list as it is now (the command's own place included).
func move_command(row: Array, target_pattern: Variant, target_event: Variant, to_index: int) -> bool:
	if row.size() != 3 or not CandyDialogue.is_line_path(_line_path):
		return false
	var from_index := int(row[2])
	var source_list := _lines_field(row[0], row[1])
	var target_list := _lines_field(target_pattern, target_event)

	#¦ 1. Same event, a move within its list:
	if source_list == target_list:
		#? Its own place is taken out first - dropped after itself, it stays.
		if to_index > from_index:
			to_index -= 1
		if to_index == from_index:
			return false
		if not CandyDialogue.move_entry(_line_path, source_list, from_index, to_index):
			return false
		_select_after_edit([target_pattern, target_event, to_index], false)
		return true			#/ Moved

	#¦ 2. Another event - out of the first list, into the second, as one step:
	var commands := _commands(row[0], row[1])
	if from_index < 0 or from_index >= commands.size():
		return false
	var line = commands[from_index]
	if not line is Dictionary:
		return false
	var moved: Dictionary = line.duplicate(true)
	CandyDialogue.begin_step(CandyLocale.t("Move {command} to text event {event}").format({"command": CandyLocale.command_title(CandySchemas.get_title(CandyDialogue.line_type(moved))), "event": str(target_event)}))
	CandyDialogue.remove_entry(_line_path, source_list, from_index)
	var index := CandyDialogue.add_entry(_line_path, target_list, "", moved)
	if index >= 0 and to_index < index:
		if CandyDialogue.move_entry(_line_path, target_list, index, to_index):
			index = to_index
	CandyDialogue.end_step()
	if index < 0:
		return false
	_select_after_edit([target_pattern, target_event, index], false)
	return true			#/ Moved


#* The selected row's place among its siblings, or -1:
func _sibling_index() -> int:
	match _selected.size():
		1:
			return _patterns().find(_selected[0])
		2:
			return _events(_selected[0]).find(_selected[1])
		3:
			return int(_selected[2])
	return -1


func _sibling_count() -> int:
	match _selected.size():
		1:
			return _patterns().size()
		2:
			return _events(_selected[0]).size()
		3:
			return _commands(_selected[0], _selected[1]).size()
	return 0


#& Data

#* The line's variation patterns, in order:
func _patterns() -> Array:
	if not CandyDialogue.is_line_path(_line_path):
		return []
	return CandyDialogue.map_keys(_line_path, [EVENTS_FIELD])


func _events(pattern: Variant) -> Array:
	if not CandyDialogue.is_line_path(_line_path):
		return []
	return CandyDialogue.map_keys(_line_path, [EVENTS_FIELD, pattern, EVENTS_KEY])


#* An event's commands: its Lines, live ([] when none):
func _commands(pattern: Variant, event_name: Variant) -> Array:
	if not CandyDialogue.is_line_path(_line_path):
		return []
	var lines = CandyDialogue.get_field(_line_path, [EVENTS_FIELD, pattern, EVENTS_KEY, event_name, LINES_KEY], [])
	if lines is Array:
		return lines
	return []


#* The line path to an event, inside the bound line:
func _event_path(pattern: Variant, event_name: Variant) -> Array:
	return _line_path + [EVENTS_FIELD, pattern, EVENTS_KEY, event_name]


#* Where an event is in the line's data (its fields' form base):
func _event_field(pattern: Variant, event_name: Variant) -> Array:
	return [EVENTS_FIELD, pattern, EVENTS_KEY, event_name]


#* Where an event's list of commands is in the line's data:
func _lines_field(pattern: Variant, event_name: Variant) -> Array:
	return _event_field(pattern, event_name) + [LINES_KEY]


func _current_type() -> String:
	return CandyDialogue.line_type(CandyDialogue.line_at(_line_path))


#* The line's Text_Events spec: { "fields": [the Events spec] }:
func _events_spec(line_type: String) -> Dictionary:
	for spec in CandySchemas.field_specs(line_type):
		if spec is Dictionary and str(spec.get("id", "")) == EVENTS_FIELD:
			return spec
	return {}


#* The spec of one pattern's Events map:
func _event_spec(line_type: String) -> Dictionary:
	var fields = _events_spec(line_type).get("fields", [])
	if fields is Array:
		for spec in fields:
			if spec is Dictionary and str(spec.get("id", "")) == EVENTS_KEY:
				return spec
	return {}


#* An event's own fields, as forms draw them (Lines left out):
func _event_specs(line_type: String) -> Array:
	var result: Array = []
	var fields = _event_spec(line_type).get("fields", [])
	if fields is Array:
		for spec in fields:
			if spec is Dictionary and spec.has("id") and CandySchemas.in_forms(spec):
				result.append(spec)
	return result

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueButtonsPanel
extends CandyPanel

const DEFAULT_BUTTONS := ["conversation", "block", "line:Spoken_Line", "line:Comment"]
const DEFAULT_COLUMNS := 2
#^ The Area action that opens the Buttons dialog:
const ACTION_BUTTONS := "Buttons"	#/ translatable

var _buttons: Array = DEFAULT_BUTTONS.duplicate()
var _layout: String = CandyButtonLayoutOptions.LAYOUT_COLUMNS
var _columns: int = DEFAULT_COLUMNS
var _min_width: int = CandyButtonLayoutOptions.DEFAULT_MIN_WIDTH
var _alignment: String = CandyButtonLayoutOptions.ALIGN_LEFT
var _scroll: bool = true
var _fill_height: bool = false

var _scroll_container: ScrollContainer
var _margin: MarginContainer
var _box: Container
var _settings_dialog: AcceptDialog
var _buttons_dialog: AcceptDialog
var _available_tree: Tree
#^ Folded Available categories, kept across refreshes:
var _available_folds: Dictionary = {}
var _shown_list: ItemList
var _layout_options: CandyButtonLayoutOptions
var _min_size_fields: CandyMinSizeFields
var _name_prompt: CandyNamePrompt
var _pending_state: Dictionary = {}


func _ready() -> void:
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)
	#? Without scrolling, the buttons' size is the panel's minimum size.
	_scroll_container.minimum_size_changed.connect(update_minimum_size)

	_margin = MarginContainer.new()
	_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin.theme_type_variation = CandyThemeDefaults.PANEL_MARGIN
	_scroll_container.add_child(_margin)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	_build_settings_dialog()
	_build_buttons_dialog()

	CandyDialogue.dialogue_changed.connect(_on_dialogue_changed)
	CandyDialogue.blocks_renamed.connect(_on_blocks_renamed)

	if not _pending_state.is_empty():
		_apply_state(_pending_state)
	_rebuild_buttons()


#& Buttons

func _rebuild_buttons() -> void:
	if _margin == null:
		return
	CandyButtonLayoutOptions.apply_scroll(_scroll_container, _scroll)
	update_minimum_size()
	#@ Step 1 - The container type depends on the layout - rebuild it:
	if _box != null:
		_margin.remove_child(_box)
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin.add_child(_box)

	#@ Step 2 - Each row break starts a new grid, unless the current one is empty:
	var grid := _add_grid()
	for id in _buttons:
		if CandyListRowBreaks.is_row_break(str(id)):
			if grid.get_child_count() > 0:
				grid = _add_grid()
			continue
		var button := CandyShortcutButton.new()
		if CandyPresets.is_preset_id(str(id)):
			if not CandyPresets.exists(str(id)):
				button.free()
				continue  #/ Deleted, or another profile's preset
			button.text = CandyPresets.button_label(str(id))
			button.tooltip_text = CandyPresets.tooltip(str(id))
			button.action_id = CandyShortcuts.PRESET_PREFIX + str(id)
		else:
			var definition := CandyDialogueButtons.get_definition(str(id))
			if definition.is_empty():
				button.free()
				continue  #/ An id from an older panel state
			button.text = CandyDialogueButtons.shown_label(str(id))
			button.tooltip_text = CandyLocale.t(str(definition.get("tooltip", "")))
			if definition.has("line_type"):
				button.action_id = CandyShortcuts.LINE_PREFIX + str(definition["line_type"])
		button.focus_mode = Control.FOCUS_NONE
		CandyButtonLayoutOptions.fit_button(button, _layout, _min_width)
		button.pressed.connect(_on_button_pressed.bind(str(id)))
		grid.add_child(button)
	if grid.get_child_count() == 0 and _box.get_child_count() > 1:
		grid.free()  #/ A row break after the last button

	#@ Step 3 - Fill the height, in the Columns layout:
	CandyButtonLayoutOptions.apply_fill([_margin, _box], _box.get_children(),
		_fill_height and _layout == CandyButtonLayoutOptions.LAYOUT_COLUMNS)


#* Add a grid of buttons at the end of the panel:
func _add_grid() -> Container:
	var grid := CandyButtonLayoutOptions.make_container(_layout, _columns, _alignment)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_child(grid)
	return grid


func _on_button_pressed(id: String) -> void:
	var before := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	if CandyPresets.is_preset_id(id):
		var path = CandyPresets.id_path(id)
		if not path.is_empty():
			CandyDialogue.insert_preset(path[0], path[1], before)
		return

	var definition := CandyDialogueButtons.get_definition(id)
	if definition.is_empty():
		return

	if definition.has("line_type"):
		CandyDialogue.add_lines(str(definition["line_type"]), before)
		return

	match str(definition.get("action", "")):
		"conversation":
			_prompt_new_conversation()
		"block":
			_prompt_new_block()


func _prompt_new_conversation() -> void:
	var base := str(CandyProfiles.get_setting("conversation_new_name", "Conversation_1"))
	var suggestion := CandyDialogue.unique_name(CandyDialogue.conversation_names(), base)
	_name_prompt.prompt(CandyLocale.t("New Conversation"), suggestion,
		func(new_name: String) -> String:
			if CandyDialogue.has_conversation(new_name):
				return CandyLocale.t("A conversation called \"%s\" already exists.") % new_name
			return "",
		func(new_name: String) -> void:
			CandyDialogue.add_conversation(new_name))


func _prompt_new_block() -> void:
	var conversation := CandyDialogue.current_conversation()
	if conversation == "":
		return  #/ No conversation selected
	var base := str(CandyProfiles.get_setting("block_new_name", "Block_"))
	var suggestion := CandyDialogue.unique_name(CandyDialogue.block_names(conversation), base)
	_name_prompt.prompt(CandyLocale.t("New Block in \"%s\"") % conversation, suggestion,
		func(new_name: String) -> String:
			if CandyDialogue.has_block(conversation, new_name):
				return CandyLocale.t("A block called \"%s\" already exists in this conversation.") % new_name
			return "",
		func(new_name: String) -> void:
			CandyDialogue.add_block(conversation, new_name))


#& Settings menu

#* Build Options - layout, alignment, scrolling and the Area's minimum size:
func _build_settings_dialog() -> void:
	_settings_dialog = AcceptDialog.new()
	_settings_dialog.title = CandyLocale.t("Options")
	add_child(_settings_dialog)

	var root := VBoxContainer.new()
	_settings_dialog.add_child(root)

	_layout_options = CandyButtonLayoutOptions.new()
	_layout_options.offer_fill()
	_layout_options.changed.connect(func():
		_layout = _layout_options.layout
		_columns = _layout_options.columns
		_min_width = _layout_options.min_width
		_alignment = _layout_options.button_alignment
		_scroll = _layout_options.scroll
		_fill_height = _layout_options.fill_height
		_rebuild_buttons())
	root.add_child(_layout_options)

	_min_size_fields = CandyMinSizeFields.new()
	root.add_child(_min_size_fields)
	_settings_dialog.visibility_changed.connect(func():
		if not _settings_dialog.visible:
			set_area_size_limits(_min_size_fields.get_limits()))


#* Build Buttons - which buttons the panel shows, and their order:
func _build_buttons_dialog() -> void:
	_buttons_dialog = AcceptDialog.new()
	_buttons_dialog.title = CandyLocale.t("Buttons")
	_buttons_dialog.min_size = Vector2i(560, 380)
	add_child(_buttons_dialog)

	var lists := HBoxContainer.new()
	_buttons_dialog.add_child(lists)

	lists.add_child(_build_list_column(CandyLocale.t("Displayed"), false))

	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	lists.add_child(middle)
	middle.add_child(_build_tool_button(CandyLocale.t("← Add"), _on_add_pressed))
	middle.add_child(_build_tool_button(CandyLocale.t("Remove →"), _on_remove_pressed))

	lists.add_child(_build_list_column(CandyLocale.t("Available"), true))


func _build_list_column(title: String, available: bool) -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = title
	column.add_child(label)

	if available:
		#? A tree, for the preset categories.
		_available_tree = Tree.new()
		_available_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_available_tree.hide_root = true
		_available_tree.allow_reselect = true
		#? Ctrl / Shift multi-select, for one Add.
		_available_tree.select_mode = Tree.SELECT_MULTI
		_available_tree.item_activated.connect(_on_add_pressed)
		column.add_child(_available_tree)
	else:
		_shown_list = ItemList.new()
		_shown_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_shown_list.allow_reselect = true
		_shown_list.item_activated.connect(func(_index: int): _on_remove_pressed())
		CandyListSelection.enable_reorder(_shown_list, func(indices: Array, slot: int):
			var moved := CandyListSelection.move_to(_buttons, indices, slot)
			_apply_settings_change()
			CandyListSelection.select_indices(_shown_list, moved))
		column.add_child(_shown_list)
		var add_row := _build_tool_button(CandyLocale.t("Add Row"), _on_add_row_pressed)
		add_row.tooltip_text = CandyLocale.t("Starts a new row of buttons after the selected button, or at the end.")
		add_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		column.add_child(add_row)
	return column


func _build_tool_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


#* Options, from the Area's menus or a tab's right-click menu:
func has_settings() -> bool:
	return true


func open_settings() -> void:
	_layout_options.set_values(_layout, _columns, _min_width, _alignment, _scroll, _fill_height)
	_min_size_fields.visible = fills_area
	_min_size_fields.set_limits(area_size_limits())
	_settings_dialog.popup_centered()


func get_area_actions() -> PackedStringArray:
	return PackedStringArray([CandyLocale.t(ACTION_BUTTONS)])


func run_area_action(action: String) -> void:
	if action == CandyLocale.t(ACTION_BUTTONS):
		_open_buttons_dialog()


func _open_buttons_dialog() -> void:
	#Ł Drop deleted presets, which would sit in Displayed with no button:
	var kept: Array = []
	for id in _buttons:
		if not CandyPresets.is_preset_id(str(id)) or CandyPresets.exists(str(id)):
			kept.append(id)
	if kept.size() != _buttons.size():
		_buttons = kept
		_rebuild_buttons()
	_refresh_settings_lists()
	_buttons_dialog.popup_centered()


#* Fill both lists:
func _refresh_settings_lists() -> void:
	CandyTreeFolds.remember(_available_tree, _available_folds)
	_available_tree.clear()
	var root := _available_tree.create_item()
	var schema_ids := CandyDialogueButtons.schema_ids()
	#@ Step 1 - Available - regular buttons:
	for id in CandyDialogueButtons.ids():
		if not _buttons.has(id) and not schema_ids.has(id):
			_add_button_item(root, str(id))

	#@ Step 2 - Schema commands, by category:
	var commands: TreeItem = null
	var command_categories := {}  #/ Category -> TreeItem
	for id in schema_ids:
		if _buttons.has(id):
			continue
		if commands == null:
			commands = _add_heading(root, CandyLocale.t("Commands"))
		var parent := commands
		var category := str(CandyDialogueButtons.get_definition(str(id)).get("category", ""))
		if category != "":
			if not command_categories.has(category):
				command_categories[category] = _add_heading(commands, CandyLocale.t(category))
				command_categories[category].collapsed = true
				command_categories[category].set_tooltip_text(0, CandyLocale.t(CandySchemas.get_category_tooltip(category)))
			parent = command_categories[category]
		_add_button_item(parent, str(id))

	#@ Step 3 - Presets by category, then presets with no category:
	var categories := {}  #/ Category -> TreeItem
	var uncategorized: Array = []
	for id in CandyPresets.all_ids():
		if _buttons.has(id):
			continue
		var category = CandyPresets.category_of(str(id))
		if category == "":
			uncategorized.append(id)
			continue
		if not categories.has(category):
			categories[category] = _add_heading(root, category)
		_add_preset_item(categories[category], str(id))
	for id in uncategorized:
		_add_preset_item(root, str(id))
	CandyTreeFolds.restore(_available_tree, _available_folds)

	_shown_list.clear()
	for id in _buttons:
		var index := -1
		if CandyPresets.is_preset_id(str(id)):
			index = _shown_list.add_item(CandyPresets.list_label(str(id)))
			_shown_list.set_item_tooltip(index, CandyPresets.tooltip(str(id)))
		elif CandyListRowBreaks.is_row_break(str(id)):
			index = _shown_list.add_item(CandyLocale.t(CandyListRowBreaks.LABEL))
			_shown_list.set_item_tooltip(index, CandyLocale.t(CandyListRowBreaks.TOOLTIP))
		else:
			index = _shown_list.add_item(CandyDialogueButtons.shown_label(str(id)))
		_shown_list.set_item_metadata(index, id)


func _add_heading(parent: TreeItem, text: String) -> TreeItem:
	var header := _available_tree.create_item(parent)
	header.set_text(0, text)
	header.set_selectable(0, false)
	header.set_metadata(0, "")
	return header


func _add_button_item(parent: TreeItem, id: String) -> void:
	var item := _available_tree.create_item(parent)
	item.set_text(0, CandyDialogueButtons.shown_label(id))
	item.set_tooltip_text(0, CandyLocale.t(str(CandyDialogueButtons.get_definition(id).get("tooltip", ""))))
	item.set_metadata(0, id)


func _add_preset_item(parent: TreeItem, id: String) -> void:
	var item := _available_tree.create_item(parent)
	item.set_text(0, CandyPresets.list_label(id))
	item.set_tooltip_text(0, CandyPresets.tooltip(id))
	item.set_metadata(0, id)


#* Add every selected Available button, in list order:
func _on_add_pressed() -> void:
	var added := false
	for item in CandyListSelection.selected_tree_items(_available_tree):
		var id := str(item.get_metadata(0))
		if id == "" or _buttons.has(id):
			continue  #/ A category heading
		_buttons.append(id)
		added = true
	if added:
		_apply_settings_change()


#* Add a row break after the last selected button, or at the end:
func _on_add_row_pressed() -> void:
	var at := _buttons.size()
	var selected := CandyListSelection.selected_indices(_shown_list)
	if not selected.is_empty():
		at = int(selected[-1]) + 1
	#? Unique in the panel - Displayed tells entries apart by id.
	_buttons.insert(at, CandyListRowBreaks.new_id(_buttons))
	_apply_settings_change()
	CandyListSelection.select_indices(_shown_list, [at])


#* Remove the selected buttons (row breaks just go):
func _on_remove_pressed() -> void:
	var indices := CandyListSelection.selected_indices(_shown_list)
	if indices.is_empty():
		return
	indices.reverse()
	for index in indices:
		_buttons.remove_at(index)
	_apply_settings_change()


func _apply_settings_change() -> void:
	_refresh_settings_lists()
	_rebuild_buttons()


#& Presets

#* Presets may have been added, renamed or deleted:
func _on_dialogue_changed() -> void:
	if _margin == null:
		return
	var shows_presets := false
	for id in _buttons:
		if CandyPresets.is_preset_id(str(id)):
			shows_presets = true
			break
	if shows_presets:
		_rebuild_buttons()
	if _buttons_dialog.visible:
		_refresh_settings_lists()


func _on_blocks_renamed(renames: Array) -> void:
	var updated: Array = []
	for id in _buttons:
		var new_id = CandyPresets.renamed_id(str(id), renames)
		if new_id != "" and not updated.has(new_id):
			updated.append(new_id)
	_buttons = updated
	#? dialogue_changed follows and rebuilds.


#* With scrolling off, keep the panel at least as big as its buttons:
func _get_minimum_size() -> Vector2:
	if _scroll or _scroll_container == null:
		return Vector2.ZERO
	return _scroll_container.get_combined_minimum_size()


#& Panel state

func get_state() -> Dictionary:
	if _margin == null:
		return _pending_state
	return {
		"buttons": _buttons.duplicate(),
		"layout": _layout,
		"columns": _columns,
		"min_button_width": _min_width,
		"alignment": _alignment,
		"scroll": _scroll,
		"fill_height": _fill_height,
	}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _margin != null:
		_apply_state(state)
		_rebuild_buttons()


func _apply_state(state: Dictionary) -> void:
	var buttons = state.get("buttons", [])
	_buttons = []
	if buttons is Array:
		for id in buttons:
			#? Missing presets are skipped when built, and dropped when the settings open.
			if CandyPresets.is_preset_id(str(id)) or CandyListRowBreaks.is_row_break(str(id)) \
					or not CandyDialogueButtons.get_definition(str(id)).is_empty():
				_buttons.append(str(id))
	_layout = CandyButtonLayoutOptions.read_layout(state)
	_columns = clampi(int(state.get("columns", DEFAULT_COLUMNS)), 1, CandyButtonLayoutOptions.MAX_COLUMNS)
	_min_width = CandyButtonLayoutOptions.read_min_width(state)
	_alignment = CandyButtonLayoutOptions.read_alignment(state)
	_scroll = CandyButtonLayoutOptions.read_scroll(state)
	_fill_height = CandyButtonLayoutOptions.read_fill_height(state)
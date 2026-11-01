#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyInsertsPanel
extends CandyPanel

const DEFAULT_COLUMNS := 3
#^ Area actions - the settings' Buttons page, and a new insert:
const ACTION_BUTTONS := "Buttons"	#/ translatable
const ACTION_CREATE_INSERT := "Create Insert..."	#/ translatable
#^ Text outline thickness, with a custom text outline color:
const TEXT_OUTLINE_SIZE := 4
#^ Border width, with a custom button outline color:
const BORDER_WIDTH := 2
#^ When the theme's button style isn't a StyleBoxFlat to start from:
const FALLBACK_BUTTON_COLOR := Color(0.2, 0.2, 0.24)
const BUTTON_STATES := ["normal", "hover", "pressed", "hover_pressed"]
const FONT_COLOR_KEYS := ["font_color", "font_hover_color", "font_pressed_color",
	"font_hover_pressed_color", "font_focus_color"]

enum ContextId { EDIT, DELETE, PANEL_SETTINGS, BUTTONS }

#^ [{ "name" = String, "folded" = bool, "inserts" = [id, ...] }, ...]:
#? "inserts" holds the separators' and row breaks' ids too.
var _categories: Array = []
var _layout: String = CandyButtonLayoutOptions.LAYOUT_COLUMNS
var _columns: int = DEFAULT_COLUMNS
var _min_width: int = CandyButtonLayoutOptions.DEFAULT_MIN_WIDTH
var _alignment: String = CandyButtonLayoutOptions.ALIGN_LEFT
var _scroll: bool = true
var _reference: String = CandyInserts.DEFAULT_REFERENCE
var _pending_state: Dictionary = {}

var _scroll_container: ScrollContainer
var _list: VBoxContainer
var _context_menu: PopupMenu
var _context_id: String = ""
var _editor: CandyInsertEditor
var _settings: CandyInsertsPanelSettings
var _delete_confirm: ConfirmationDialog
#^ The Text Events and Lexicon drop-downs among the buttons:
var _speech_menus := CandySpeechInsertMenus.new()


func _ready() -> void:
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)
	#? Without scrolling, the buttons' size is the panel's minimum size.
	_scroll_container.minimum_size_changed.connect(update_minimum_size)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.theme_type_variation = CandyThemeDefaults.PANEL_MARGIN
	_scroll_container.add_child(margin)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_list)

	_context_menu = PopupMenu.new()
	_context_menu.add_item(CandyLocale.t("Edit Insert"), ContextId.EDIT)
	_context_menu.add_item(CandyLocale.t("Delete Insert"), ContextId.DELETE)
	_context_menu.add_separator()
	_context_menu.add_item(CandyLocale.t("Options"), ContextId.PANEL_SETTINGS)
	_context_menu.add_item(CandyLocale.t(ACTION_BUTTONS), ContextId.BUTTONS)
	_context_menu.id_pressed.connect(_on_context_id)
	add_child(_context_menu)

	_editor = CandyInsertEditor.new()
	add_child(_editor)

	_settings = CandyInsertsPanelSettings.new()
	_settings.categories_changed.connect(func(categories: Array):
		_categories = categories
		_rebuild())
	_settings.layout_changed.connect(func(options: CandyButtonLayoutOptions):
		_layout = options.layout
		_columns = options.columns
		_min_width = options.min_width
		_alignment = options.button_alignment
		_scroll = options.scroll
		_rebuild())
	_settings.reference_changed.connect(func(reference: String):
		_reference = reference
		_rebuild())  #/ The color tags' tooltips name it
	_settings.visibility_changed.connect(func():
		if not _settings.visible:
			set_area_size_limits(_settings.min_size_fields.get_limits()))
	add_child(_settings)

	_delete_confirm = ConfirmationDialog.new()
	_delete_confirm.title = CandyLocale.t("Delete Insert")
	_delete_confirm.ok_button_text = CandyLocale.t("Delete")
	_delete_confirm.confirmed.connect(_on_delete_confirmed)
	add_child(_delete_confirm)

	CandyInserts.inserts_changed.connect(_rebuild)
	CandyInserts.insert_deleted.connect(_on_insert_deleted)

	if _pending_state.is_empty():
		_categories = _default_categories()
	else:
		_apply_state(_pending_state)
	_rebuild()


#* The new panel's categories:
func _default_categories() -> Array:
	var result: Array = []
	var by_name: Dictionary = {}
	for entry in CandyInserts.BBCODE_INSERTS:
		var category_name := str(entry[1])
		if not by_name.has(category_name):
			by_name[category_name] = {"name": category_name, "folded": not result.is_empty(), "inserts": []}
			result.append(by_name[category_name])
		by_name[category_name]["inserts"].append(str(entry[0]))
	var symbols: Array = []
	for entry in CandyInserts.SYMBOL_INSERTS:
		symbols.append(str(entry[0]))
	result.append({"name": CandyInserts.SYMBOLS_CATEGORY, "folded": false, "inserts": symbols})
	var menus: Array = []
	for menu in CandySpeechInsertMenus.DEFAULT_MENUS:
		menus.append(CandySpeechInsertMenus.id_of(str(menu)))
	result.append({"name": CandySpeechInsertMenus.CATEGORY, "folded": false, "inserts": menus})
	return result


#& Buttons

#* Rebuild the buttons:
func _rebuild() -> void:
	if _list == null:
		return
	CandyButtonLayoutOptions.apply_scroll(_scroll_container, _scroll)
	update_minimum_size()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	for i in _categories.size():
		var category: Dictionary = _categories[i]
		var folded := CandyVariantFile.to_bool(category.get("folded", false), false)

		var header := CandyFoldHeader.new(str(category["name"]), folded)
		_list.add_child(header)

		var body := VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.visible = not folded
		_list.add_child(body)
		header.fold_toggled.connect(_on_fold_toggled.bind(i, body))

		#Ł Each separator starts a new grid:
		var items: Array = []
		var grid := _add_grid(body, items)
		for id in category["inserts"]:
			if CandyListSeparators.is_separator(id):
				var line := HSeparator.new()
				body.add_child(line)
				items.append({"node": line, "separator": true})
				grid = _add_grid(body, items)
				continue
			if CandyListRowBreaks.is_row_break(id):
				#? An empty grid is hidden, so a row break with no button before it leaves no gap.
				grid = _add_grid(body, items)
				continue
			if CandySpeechInsertMenus.is_menu(id):
				var menu_button := _speech_menus.make_button(str(id))
				CandyButtonLayoutOptions.fit_button(menu_button, _layout, _min_width, true)
				grid.add_child(menu_button)
				continue
			var insert := CandyInserts.get_insert(str(id))
			if insert.is_empty():
				continue  #/ Deleted, or its file couldn't be read
			var button := CandyShortcutButton.new()
			button.text = str(insert["label"])
			if insert["type"] == CandyInserts.TYPE_NATIVE:
				button.text = CandyLocale.t(str(insert["label"]))
			button.tooltip_text = _describe(insert)
			button.action_id = CandyShortcuts.INSERT_PREFIX + str(id)
			button.focus_mode = Control.FOCUS_NONE  #/ Keeps the focus on the text field
			CandyButtonLayoutOptions.fit_button(button, _layout, _min_width, true)
			button.pressed.connect(_on_insert_pressed.bind(str(id)))
			button.gui_input.connect(_on_insert_gui_input.bind(str(id), button))
			#? Its right-click menu is the insert's, not the Area's.
			button.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
			grid.add_child(button)
			style_button(button, insert)
		for item in items:
			if not bool(item["separator"]):
				item["shown"] = item["node"].get_child_count() > 0
		CandyListSeparators.update_visibility(items)


#* Add a grid of buttons at the end of body, listed in items:
func _add_grid(body: VBoxContainer, items: Array) -> Container:
	var grid := CandyButtonLayoutOptions.make_container(_layout, _columns, _alignment)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	items.append({"node": grid, "separator": false})
	return grid


func _on_fold_toggled(folded: bool, index: int, body: Control) -> void:
	if index >= _categories.size():
		return
	_categories[index]["folded"] = folded
	body.visible = not folded


#* A button's tooltip:
func _describe(insert: Dictionary) -> String:
	var lines: PackedStringArray = []
	var parts := [[CandyLocale.t("Left: \"%s\""), "left"], [CandyLocale.t("Middle: \"%s\""), "middle"],
		[CandyLocale.t("Right: \"%s\""), "right"]]
	for part in parts:
		var value := str(insert[part[1]])
		if value != "":
			lines.append(str(part[0]) % value)
	if CandyInserts.uses_color(str(insert["id"])):
		lines.append(CandyLocale.t("{token}: the color of the Color Selector with reference \"{reference}\"").format({
			"token": CandyInserts.COLOR_TOKEN, "reference": _reference}))
	if insert["type"] == CandyInserts.TYPE_NATIVE:
		lines.append(CandyLocale.t("Built in"))
	else:
		lines.append(CandyLocale.t("Right-click to edit or delete"))
	return "\n".join(lines)


func _on_insert_pressed(id: String) -> void:
	CandyInserts.apply(id, _reference)


#* Give a button the insert's colors (unset ones follow the theme):
static func style_button(button: Button, insert: Dictionary) -> void:
	#Ł Clear earlier overrides (also styles the insert editor's preview):
	for key in FONT_COLOR_KEYS:
		button.remove_theme_color_override(key)
	button.remove_theme_color_override("font_outline_color")
	button.remove_theme_constant_override("outline_size")
	for state in BUTTON_STATES:
		button.remove_theme_stylebox_override(state)

	var text_value = insert.get("text_color", "")
	var background_value = insert.get("background_color", "")
	var text_outline_value = insert.get("text_outline_color", "")
	var button_outline_value = insert.get("button_outline_color", "")
	var has_background := CandySpeechEditorSettings.has_color(background_value)
	var has_border := CandySpeechEditorSettings.has_color(button_outline_value)

	if CandySpeechEditorSettings.has_color(text_value):
		var text_color := CandySpeechEditorSettings.to_color(text_value, Color.WHITE)
		for key in FONT_COLOR_KEYS:
			button.add_theme_color_override(key, text_color)

	if CandySpeechEditorSettings.has_color(text_outline_value):
		button.add_theme_color_override("font_outline_color",
			CandySpeechEditorSettings.to_color(text_outline_value, Color.BLACK))
		button.add_theme_constant_override("outline_size", TEXT_OUTLINE_SIZE)

	if not has_background and not has_border:
		return
	var border_color := CandySpeechEditorSettings.to_color(button_outline_value, Color.BLACK)
	var background := CandySpeechEditorSettings.to_color(background_value, FALLBACK_BUTTON_COLOR)
	for state in BUTTON_STATES:
		var box: StyleBoxFlat
		var base := button.get_theme_stylebox(state, "Button")
		if base is StyleBoxFlat:
			box = base.duplicate() as StyleBoxFlat
		else:
			box = StyleBoxFlat.new()
			box.bg_color = FALLBACK_BUTTON_COLOR
			box.set_content_margin_all(4)
		if has_background:
			box.draw_center = true
			box.bg_color = background
			if state == "hover":
				box.bg_color = background.lightened(0.15)
			elif state == "pressed" or state == "hover_pressed":
				box.bg_color = background.darkened(0.15)
		if has_border:
			box.set_border_width_all(BORDER_WIDTH)
			box.border_color = border_color
		button.add_theme_stylebox_override(state, box)


#& Context menu

func _on_insert_gui_input(event: InputEvent, id: String, button: Button) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return
	_context_id = id
	var is_builtin := CandyInserts.is_native(id)
	_context_menu.set_item_disabled(_context_menu.get_item_index(ContextId.EDIT), is_builtin)
	_context_menu.set_item_disabled(_context_menu.get_item_index(ContextId.DELETE), is_builtin)
	CandyPopups.popup_at_point(_context_menu,
		Vector2i(button.get_screen_position() + button.get_local_mouse_position()), self)
	button.accept_event()


func _on_context_id(id: int) -> void:
	if id == ContextId.PANEL_SETTINGS:
		open_settings()
		return
	if id == ContextId.BUTTONS:
		run_area_action(CandyLocale.t(ACTION_BUTTONS))
		return
	if not CandyInserts.has_insert(_context_id) or CandyInserts.is_native(_context_id):
		return
	match id:
		ContextId.EDIT:
			_editor.open_edit(_context_id)
		ContextId.DELETE:
			var insert := CandyInserts.get_insert(_context_id)
			var question := CandyLocale.t("Delete the insert \"%s\"?\nIt will be removed from every Inserts panel in every profile of this user.")
			if insert["type"] == CandyInserts.TYPE_PROFILE:
				question = CandyLocale.t("Delete the insert \"%s\"?\nIt will be removed from every Inserts panel in this profile.")
			_delete_confirm.dialog_text = question % insert["label"]
			_delete_confirm.reset_size()
			_delete_confirm.popup_centered()


func _on_delete_confirmed() -> void:
	var problem := CandyInserts.delete_insert(_context_id)
	if problem != "":
		push_warning("CandyInsertsPanel: %s" % problem)


func _on_insert_deleted(id: String) -> void:
	for category in _categories:
		category["inserts"].erase(id)


#& Area menu

func has_settings() -> bool:
	return true


func open_settings() -> void:
	_open_settings_page(CandyInsertsPanelSettings.PAGE_OPTIONS)


func get_area_actions() -> PackedStringArray:
	return PackedStringArray([CandyLocale.t(ACTION_BUTTONS), CandyLocale.t(ACTION_CREATE_INSERT)])


func run_area_action(action: String) -> void:
	if action == CandyLocale.t(ACTION_BUTTONS):
		_open_settings_page(CandyInsertsPanelSettings.PAGE_BUTTONS)
	elif action == CandyLocale.t(ACTION_CREATE_INSERT):
		_editor.open_create()


#* Open a settings page (both load the minimum size, since closing either saves it):
func _open_settings_page(page: String) -> void:
	_settings.min_size_fields.visible = fills_area
	_settings.min_size_fields.set_limits(area_size_limits())
	_settings.open(_categories, _layout, _columns, _min_width, _alignment, _scroll, _reference, page)


#* With scrolling off, at least as big as the buttons:
func _get_minimum_size() -> Vector2:
	if _scroll or _scroll_container == null:
		return Vector2.ZERO
	return _scroll_container.get_combined_minimum_size()			#/ So the Area and its splits can't shrink past them


#& Panel state

func get_state() -> Dictionary:
	if _list == null:
		return _pending_state
	return {
		"categories": _categories.duplicate(true),
		"layout": _layout,
		"columns": _columns,
		"min_button_width": _min_width,
		"alignment": _alignment,
		"scroll": _scroll,
		"reference": _reference,
	}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _list != null:
		_apply_state(state)
		_rebuild()


func _apply_state(state: Dictionary) -> void:
	_layout = CandyButtonLayoutOptions.read_layout(state)
	_columns = clampi(int(state.get("columns", DEFAULT_COLUMNS)), 1, CandyButtonLayoutOptions.MAX_COLUMNS)
	_min_width = CandyButtonLayoutOptions.read_min_width(state)
	_alignment = CandyButtonLayoutOptions.read_alignment(state)
	_scroll = CandyButtonLayoutOptions.read_scroll(state)
	_reference = str(state.get("reference", CandyInserts.DEFAULT_REFERENCE)).strip_edges()
	if _reference == "":
		_reference = CandyInserts.DEFAULT_REFERENCE
	_categories = []
	var categories = state.get("categories", [])
	if not categories is Array:
		return
	var seen := {}
	for entry in categories:
		if not entry is Dictionary:
			continue
		var ids: Array = []
		var stored = entry.get("inserts", [])
		if stored is Array:
			for id in stored:
				#% Once per panel, even in a hand-edited layout:
				if not seen.has(str(id)):
					seen[str(id)] = true
					ids.append(str(id))
		_categories.append({
			"name": str(entry.get("name", "Category")),
			"folded": CandyVariantFile.to_bool(entry.get("folded", false), false),
			"inserts": ids,
		})
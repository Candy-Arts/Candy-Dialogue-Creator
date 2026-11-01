#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorColorsPage
extends CandySettingsPage

const COLUMNS_KEY := "navigator_colors_columns"
const OPEN_KEY := "navigator_colors_open"
const NAME_WIDTH := 220
const USE_CATEGORY_WIDTH := 64
const SWATCH_SIZE := Vector2(44, 24)
const PREVIEW_FONT_SIZE := 14
const NOTE_WIDTH := 600
const KEY_SHORT := {"text": "Text", "outline": "Outline", "bg": "Back", "border": "Border", "frame": "Frame"}		#/ translatable: navigator color column
#^ Size columns, shown or hidden like a state's:
const BORDER_COLUMN := "border_size"
const FRAME_COLUMN := "frame_width"
const SIZE_COLUMNS := [BORDER_COLUMN, FRAME_COLUMN]
#^ Minimum border field width (the theme can widen it, see _fit_border_column()):
const BORDER_FIELD_WIDTH := 88
#^ Room on a column's right, before the next column's line:
const COLUMN_PADDING := 12

var _indent_fields: Dictionary = {}  #/ Kind -> SpinBox
var _color_rows: Array = []           #/ { level, name, preview, check, swatches: { state: { key: picker } }, widths: { side: SpinBox }, frame: SpinBox, groups: { column: Control } }
var _header_groups: Dictionary = {}   #/ Column -> [Control], in the column titles
var _column_buttons: Dictionary = {}  #/ Column -> Button
var _side_labels: Array = []          #/ Left, Top, Right, Bottom, in the column titles
var _field_width := float(BORDER_FIELD_WIDTH)
var _saved_menu: CandyLayoutMenu
#^ Colors last saved or loaded, offered again by the save dialog:
var _last_saved := {}
var _color_menu: CandyOverrideMenu


func build() -> void:
	#? Fixed width, or the note spreads across every column.
	var note := add_note(CandyLocale.t("How conversations, blocks and each command look in the Dialogue Navigator. Ctrl+click a color to paste."))
	note.custom_minimum_size.x = NOTE_WIDTH
	note.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var save_load := MenuButton.new()
	save_load.text = CandyLocale.t("Save / Load")
	save_load.flat = false
	save_load.tooltip_text = CandyLocale.t("Save every color, size and indent of this page, or load saved ones.")
	save_load.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_custom(save_load)
	_saved_menu = CandyLayoutMenu.new()
	_saved_menu.save_label = CandyLocale.t("Save Colors...")
	_saved_menu.load_label = CandyLocale.t("Load Colors")
	_saved_menu.save_title = CandyLocale.t("Save Colors")
	_saved_menu.empty_label = CandyLocale.t("No saved colors")
	_saved_menu.setup(CandyLayoutLibrary.NAVIGATOR_COLORS, "", _capture_saved, _apply_saved)
	_saved_menu.suggest = func() -> Dictionary: return _last_saved
	_saved_menu.saved.connect(func(saved_name: String, level: String): _last_saved = {"name": saved_name, "level": level})
	_saved_menu.loaded.connect(func(saved_name: String, level: String): _last_saved = {"name": saved_name, "level": level})
	add_child(_saved_menu)
	var popup := save_load.get_popup()
	_saved_menu.add_items(popup, 0)
	popup.id_pressed.connect(func(id: int): _saved_menu.handle_id(id))
	CandyPopups.attach_button_popup(save_load)

	_color_menu = CandyOverrideMenu.new()
	add_child(_color_menu)

	var toggles := HBoxContainer.new()
	add_custom(toggles)
	var shown := Label.new()
	shown.text = CandyLocale.t("Show")
	shown.theme_type_variation = CandyThemeDefaults.NOTE
	toggles.add_child(shown)
	var border_button := Button.new()
	border_button.toggle_mode = true
	border_button.text = CandyLocale.t("Border size")
	border_button.tooltip_text = CandyLocale.t("The width of the border on each side.")
	border_button.focus_mode = Control.FOCUS_NONE
	border_button.toggled.connect(func(pressed: bool): _set_column_shown(BORDER_COLUMN, pressed))
	toggles.add_child(border_button)
	_column_buttons[BORDER_COLUMN] = border_button
	var frame_button := Button.new()
	frame_button.toggle_mode = true
	frame_button.text = CandyLocale.t("Frame width")
	frame_button.tooltip_text = CandyLocale.t("The width of the frame, the outline around the row.")
	frame_button.focus_mode = Control.FOCUS_NONE
	frame_button.toggled.connect(func(pressed: bool): _set_column_shown(FRAME_COLUMN, pressed))
	toggles.add_child(frame_button)
	_column_buttons[FRAME_COLUMN] = frame_button
	for state in CandyNavigatorColors.STATES:
		if state == "normal":
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.text = CandyLocale.t(CandyNavigatorColors.STATE_LABELS[state])
		button.tooltip_text = CandyLocale.t(CandyNavigatorColors.STATE_TOOLTIPS[state])
		button.focus_mode = Control.FOCUS_NONE
		button.toggled.connect(func(pressed: bool): _set_column_shown(state, pressed))
		toggles.add_child(button)
		_column_buttons[state] = button

	add_custom(_build_indents())
	add_custom(_build_titles())
	for kind in CandyNavigatorColors.HEADERS:
		_add_header(kind)
	add_separator()
	for category in CandyNavigatorColors.categories():
		_add_category(category)
	_apply_columns()


func _ready() -> void:
	super._ready()
	#Ł Redraw the column lines when the layout moves:
	sort_children.connect(queue_redraw)
	resized.connect(queue_redraw)
	_fit_border_column.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_fit_border_column.call_deferred()


func refresh() -> void:
	super.refresh()
	_refresh_rows()


#* Draw a line left of each shown column:
func _draw() -> void:
	var line_style = get_theme_stylebox(&"separator", &"VSeparator")
	var color := Color(1, 1, 1, 0.25)
	var thickness := 1.0
	if line_style is StyleBoxLine:
		color = line_style.color
		thickness = maxf(1.0, float(line_style.thickness))
	var gap := float(get_theme_constant(&"separation", CandyThemeDefaults.ROOMY_HBOX))
	var origin := get_global_rect().position
	for column in _all_columns():
		var title: Control = _header_groups.get(column, [null])[0]
		if title == null or not title.is_visible_in_tree():
			continue
		var top_left := title.get_global_rect().position - origin
		var x := roundf(top_left.x - gap * 0.5)
		draw_line(Vector2(x, top_left.y), Vector2(x, size.y), color, thickness)


#& Layout

#* Build the text indent fields:
func _build_indents() -> Control:
	var line := HBoxContainer.new()
	var title := Label.new()
	title.text = CandyLocale.t("Text indent")
	title.tooltip_text = CandyLocale.t("Where the text starts in each kind of row, in pixels from its left edge.")
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.theme_type_variation = CandyThemeDefaults.NOTE
	line.add_child(title)
	for kind in CandyNavigatorColors.INDENT_KINDS:
		var label := Label.new()
		label.text = CandyLocale.t(CandyNavigatorColors.INDENT_LABELS[kind])
		line.add_child(label)
		var field := SpinBox.new()
		field.min_value = CandyNavigatorColors.min_text_indent(kind)
		field.max_value = CandyNavigatorColors.MAX_TEXT_INDENT
		field.step = 1
		field.select_all_on_focus = true
		if kind == "line":
			field.tooltip_text = CandyLocale.t("Where a line's text starts, in pixels from the row's left edge.")
		else:
			field.tooltip_text = CandyLocale.t("Where the text starts, in pixels from the row's left edge. The fold arrow sits right before it.")
		field.value_changed.connect(func(value: float): _set_text_indent(kind, int(value)))
		CandyOverrideMenu.add_to_number(field, func(): _reset_value(_indent_key(kind)),
			func() -> bool: return draft.has_value(_indent_key(kind)))
		line.add_child(field)
		_indent_fields[kind] = field
	return line


func _build_titles() -> Control:
	var box := VBoxContainer.new()
	box.theme_type_variation = CandyThemeDefaults.FLUSH_VBOX
	var states_row := _row_frame()
	var keys_row := _row_frame()
	box.add_child(states_row)
	box.add_child(keys_row)

	states_row.add_child(_fixed(_title(CandyLocale.t("Name"), ""), NAME_WIDTH))
	states_row.add_child(_fixed(_title(CandyLocale.t("Category"), CandyLocale.t("Tick to use the category's colors.")), USE_CATEGORY_WIDTH))
	keys_row.add_child(_fixed(Control.new(), NAME_WIDTH))
	keys_row.add_child(_fixed(Control.new(), USE_CATEGORY_WIDTH))

	var border_title := _title(CandyLocale.t("Border size"), CandyLocale.t("The width of the border on each side, in every state."))
	border_title.custom_minimum_size.x = _border_group_width()
	var sides := HBoxContainer.new()
	sides.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	for side in CandyNavigatorColors.SIDES:
		var side_label := Label.new()
		side_label.text = CandyLocale.t(CandyNavigatorColors.SIDE_LABELS[side])
		side_label.theme_type_variation = CandyThemeDefaults.BREADCRUMB
		side_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		side_label.custom_minimum_size.x = _field_width
		sides.add_child(side_label)
		_side_labels.append(side_label)
	states_row.add_child(border_title)
	keys_row.add_child(sides)
	_header_groups[BORDER_COLUMN] = [border_title, sides]

	var frame_title := _title(CandyLocale.t("Frame width"), CandyLocale.t("The width of the frame, the outline around the row, in every state."))
	frame_title.custom_minimum_size.x = _frame_group_width()
	var frame_under := Control.new()
	frame_under.custom_minimum_size.x = _frame_group_width()
	states_row.add_child(frame_title)
	keys_row.add_child(frame_under)
	_header_groups[FRAME_COLUMN] = [frame_title, frame_under]

	for state in CandyNavigatorColors.STATES:
		var state_title := _title(CandyLocale.t(CandyNavigatorColors.STATE_LABELS[state]), CandyLocale.t(CandyNavigatorColors.STATE_TOOLTIPS[state]))
		state_title.custom_minimum_size.x = _group_width()
		var keys := HBoxContainer.new()
		keys.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
		for key in CandyNavigatorColors.KEYS:
			var key_label := Label.new()
			key_label.text = CandyLocale.t(KEY_SHORT[key], "navigator color column")
			key_label.tooltip_text = CandyLocale.t(CandyNavigatorColors.KEY_LABELS[key])
			key_label.mouse_filter = Control.MOUSE_FILTER_PASS
			key_label.theme_type_variation = CandyThemeDefaults.BREADCRUMB
			key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			key_label.custom_minimum_size.x = SWATCH_SIZE.x
			keys.add_child(key_label)
		states_row.add_child(state_title)
		keys_row.add_child(keys)
		_header_groups[state] = [state_title, keys]
	return box


func _add_category(category: String) -> void:
	var open_state = draft.get_value(OPEN_KEY, {})
	var open: bool = open_state is Dictionary and bool(open_state.get(category, false))

	var header := _row_frame()
	add_custom(header)
	var body := VBoxContainer.new()
	body.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	body.visible = open
	add_custom(body)

	var fold := Button.new()
	fold.flat = true
	fold.theme_type_variation = CandyThemeDefaults.FLAT_BUTTON
	fold.focus_mode = Control.FOCUS_NONE
	fold.tooltip_text = CandyLocale.t("Show or hide this category's commands")
	fold.custom_minimum_size.x = 24
	var name_cell := HBoxContainer.new()
	name_cell.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	name_cell.add_child(fold)
	var row := _add_preview_row("category", category, header, name_cell, NAME_WIDTH - 24 - 2)
	header.add_child(_fixed(Control.new(), USE_CATEGORY_WIDTH))
	_add_swatches(row, header)

	var filled := [false]
	var show_body := func(visible_now: bool) -> void:
		body.visible = visible_now
		if visible_now:
			fold.text = "-"
		else:
			fold.text = "+"
		if visible_now and not filled[0]:
			filled[0] = true
			for type in CandyNavigatorColors.categories()[category]:
				_add_command(type, body)
			_apply_columns()
			_refresh_rows()
			_fit_border_column()
	show_body.call(open)
	fold.pressed.connect(func():
		var now := not body.visible
		show_body.call(now)
		var state = draft.get_value(OPEN_KEY, {})
		if not state is Dictionary:
			state = {}
		state = state.duplicate()
		state[category] = now
		draft.set_value(OPEN_KEY, state))


#* Add a conversation or block row (colors start from the theme's):
func _add_header(kind: String) -> void:
	var line := _row_frame()
	add_custom(line)
	var name_cell := HBoxContainer.new()
	name_cell.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	var indent := Control.new()
	indent.custom_minimum_size.x = 24
	name_cell.add_child(indent)
	var row := _add_preview_row("header", kind, line, name_cell, NAME_WIDTH - 24 - 2)
	row["preview"].tooltip_text = CandyLocale.t("Their colors start from the theme's.")
	line.add_child(_fixed(Control.new(), USE_CATEGORY_WIDTH))
	_add_swatches(row, line)


func _add_command(type: String, parent: Control) -> void:
	var line := _row_frame()
	parent.add_child(line)
	var name_cell := HBoxContainer.new()
	name_cell.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	var indent := Control.new()
	indent.custom_minimum_size.x = 24
	name_cell.add_child(indent)
	var row := _add_preview_row("command", type, line, name_cell, NAME_WIDTH - 24 - 2)

	var check := CheckBox.new()
	check.tooltip_text = CandyLocale.t("Use the category's colors.")
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(pressed: bool): _set_uses_category(type, pressed))
	var check_cell := CenterContainer.new()
	check_cell.add_child(check)
	line.add_child(_fixed(check_cell, USE_CATEGORY_WIDTH))
	row["check"] = check
	_add_swatches(row, line)


#* Add a row's name cell, a preview drawn like a Navigator line:
func _add_preview_row(level: String, row_name: String, line: Control, name_cell: HBoxContainer, preview_width: int) -> Dictionary:
	var preview := CandyNavigatorPreviewRow.new()
	preview.custom_minimum_size.x = preview_width
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := CandyLocale.t(row_name)
	if level == "command":
		label = CandyLocale.command_title(CandySchemas.get_title(row_name))
	elif level == "header":
		label = CandyLocale.t(CandyNavigatorColors.HEADER_LABELS[row_name])
	preview.tooltip_text = row_name
	preview.set_meta(&"label", label)
	name_cell.add_child(preview)
	line.add_child(_fixed(name_cell, NAME_WIDTH))
	var row := {"level": level, "name": row_name, "preview": preview, "check": null, "swatches": {}, "widths": {}, "groups": {}}
	_color_rows.append(row)
	return row


#* Add a row's border sizes, frame width, then each state's colors:
func _add_swatches(row: Dictionary, line: Control) -> void:
	var border_group := HBoxContainer.new()
	border_group.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	border_group.custom_minimum_size.x = _border_group_width()
	for side in CandyNavigatorColors.SIDES:
		var field := SpinBox.new()
		field.min_value = 0
		field.max_value = CandyNavigatorColors.MAX_BORDER_WIDTH
		field.step = 1
		field.custom_minimum_size.x = _field_width
		field.select_all_on_focus = true
		field.tooltip_text = CandyLocale.t("%s border, in pixels.") % CandyLocale.t(CandyNavigatorColors.SIDE_LABELS[side])
		field.value_changed.connect(func(value: float): _set_border(row, side, int(value)))
		CandyOverrideMenu.add_to_number(field, func(): _reset_value(_border_key(row, side)),
			func() -> bool: return draft.has_value(_border_key(row, side)))
		border_group.add_child(field)
		row["widths"][side] = field
	line.add_child(border_group)
	row["groups"][BORDER_COLUMN] = border_group

	var frame_group := HBoxContainer.new()
	frame_group.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
	frame_group.custom_minimum_size.x = _frame_group_width()
	var frame_field := SpinBox.new()
	frame_field.min_value = 0
	frame_field.max_value = CandyNavigatorColors.MAX_FRAME_WIDTH
	frame_field.step = 1
	frame_field.custom_minimum_size.x = _field_width
	frame_field.select_all_on_focus = true
	frame_field.tooltip_text = CandyLocale.t("Frame width, in pixels.")
	frame_field.value_changed.connect(func(value: float): _set_frame_width(row, int(value)))
	CandyOverrideMenu.add_to_number(frame_field, func(): _reset_value(_frame_key(row)),
		func() -> bool: return draft.has_value(_frame_key(row)))
	frame_group.add_child(frame_field)
	row["frame"] = frame_field
	line.add_child(frame_group)
	row["groups"][FRAME_COLUMN] = frame_group

	for state in CandyNavigatorColors.STATES:
		var group := HBoxContainer.new()
		group.theme_type_variation = CandyThemeDefaults.COMPACT_HBOX
		group.custom_minimum_size.x = _group_width()
		row["swatches"][state] = {}
		for key in CandyNavigatorColors.KEYS:
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size = SWATCH_SIZE
			picker.flat = true
			picker.edit_alpha = true
			picker.focus_mode = Control.FOCUS_NONE
			picker.tooltip_text = CandyLocale.t("{state}: {color}. Right-click to copy, paste or remove it. Ctrl+click to paste.").format({
				"state": CandyLocale.t(CandyNavigatorColors.STATE_LABELS[state]), "color": CandyLocale.t(CandyNavigatorColors.KEY_LABELS[key])})
			picker.color_changed.connect(func(color: Color): _set_color(row, state, key, color))
			_color_menu.add_to_color(picker, func(color: Color): _set_color(row, state, key, color),
				func(): _reset_value(_key(row, state, key)),
				func() -> bool: return draft.has_value(_key(row, state, key)))
			group.add_child(picker)
			row["swatches"][state][key] = picker
		line.add_child(group)
		row["groups"][state] = group


func _row_frame() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.theme_type_variation = CandyThemeDefaults.ROOMY_HBOX
	return line


func _fixed(control: Control, width: int) -> Control:
	control.custom_minimum_size.x = width
	return control


func _title(text: String, tooltip: String) -> Label:
	var label := Label.new()
	label.text = text
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	return label


func _group_width() -> int:
	return int(SWATCH_SIZE.x) * CandyNavigatorColors.KEYS.size() + _inner_gaps(CandyNavigatorColors.KEYS.size()) + COLUMN_PADDING


func _border_group_width() -> int:
	return int(_field_width) * CandyNavigatorColors.SIDES.size() + _inner_gaps(CandyNavigatorColors.SIDES.size()) + COLUMN_PADDING


func _frame_group_width() -> int:
	return int(_field_width) + COLUMN_PADDING


#* Get a column's width (and its row groups'):
func _column_width(column: String) -> int:
	match column:
		BORDER_COLUMN:
			return _border_group_width()
		FRAME_COLUMN:
			return _frame_group_width()
	return _group_width()


func _all_columns() -> Array:
	return SIZE_COLUMNS + CandyNavigatorColors.STATES


#* Get the spacing between count controls side by side:
func _inner_gaps(count: int) -> int:
	return get_theme_constant(&"separation", CandyThemeDefaults.COMPACT_HBOX) * (count - 1)


#* Size the border and frame columns to their fields as the theme draws them:
func _fit_border_column() -> void:
	if _color_rows.is_empty() or not is_inside_tree():
		return
	var probe: SpinBox = _color_rows[0]["widths"]["left"]
	#? get_minimum_size() excludes the custom minimum size set below.
	_field_width = maxf(float(BORDER_FIELD_WIDTH), probe.get_minimum_size().x)
	for label in _side_labels:
		label.custom_minimum_size.x = _field_width
	for row in _color_rows:
		for side in CandyNavigatorColors.SIDES:
			row["widths"][side].custom_minimum_size.x = _field_width
		row["frame"].custom_minimum_size.x = _field_width
		for column in _all_columns():
			row["groups"][column].custom_minimum_size.x = _column_width(column)
	for column in _all_columns():
		#Ł Title and sub-titles:
		for control in _header_groups[column]:
			control.custom_minimum_size.x = _column_width(column)
	queue_redraw()


#& Columns

func _columns() -> Dictionary:
	var stored = draft.get_value(COLUMNS_KEY, {})
	if stored is Dictionary:
		return stored
	return {}


func _set_column_shown(column: String, shown: bool) -> void:
	var columns := _columns().duplicate()
	columns[column] = shown
	draft.set_value(COLUMNS_KEY, columns)
	_apply_columns()


#* Show the chosen columns:
func _apply_columns() -> void:
	var columns := _columns()
	for column in _all_columns():
		var shown: bool = column == "normal" or bool(columns.get(column, SIZE_COLUMNS.has(column)))	#/ Normal always, sizes unless hidden, other states when shown
		if _column_buttons.has(column):
			_column_buttons[column].set_pressed_no_signal(shown)
		for control in _header_groups.get(column, []):
			control.visible = shown
		for row in _color_rows:
			row["groups"][column].visible = shown
	queue_redraw()


#& Values

#* Get the Theme page's theme's colors:
func _colors() -> Dictionary:
	return CandyTheme.overrides_of(draft.get_dictionary(CandyNavigatorColors.SETTING), _theme_id())


func _theme_id() -> String:
	return str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))


#* Get the colors' draft key: "navigator_colors/<theme id>":
func _setting_path() -> String:
	return "/".join([CandyNavigatorColors.SETTING, _theme_id()])


#* Get what Save writes (see CandyLayoutLibrary):
func _capture_saved() -> Dictionary:
	return {CandyNavigatorColors.SETTING: _colors()}


#* Replace the theme's colors (and edits) with loaded ones:
func _apply_saved(data: Dictionary) -> void:
	var colors = data.get(CandyNavigatorColors.SETTING)
	if not colors is Dictionary:
		push_warning("CandyNavigatorColorsPage: the loaded file holds no Navigator colors")
		return
	draft.replace_dictionary(_setting_path(), colors)
	_refresh_rows()


func _states_of(row: Dictionary, colors: Dictionary) -> Dictionary:
	if row["level"] == "header":
		return CandyNavigatorColors.for_header(row["name"], colors, self)
	if row["level"] == "category":
		return CandyNavigatorColors.for_category(row["name"], colors, self)
	return CandyNavigatorColors.for_command(row["name"], colors, self)


#* Refresh every row's swatches, checkbox and preview from the draft:
func _refresh_rows() -> void:
	var colors := _colors()
	var indents := CandyNavigatorColors.text_indents(colors)
	for kind in _indent_fields:
		_indent_fields[kind].set_value_no_signal(float(indents[kind]))
	for row in _color_rows:
		var states := _states_of(row, colors)
		#? Conversations and blocks show their fold arrow.
		var kind := "line"
		if row["level"] == "header":
			kind = row["name"]
		row["preview"].show_colors(str(row["preview"].get_meta(&"label")), states, PREVIEW_FONT_SIZE,
			int(indents[kind]), row["level"] == "header")
		if row["check"] != null:
			row["check"].set_pressed_no_signal(CandyNavigatorColors.uses_category(row["name"], colors))
		for state in CandyNavigatorColors.STATES:
			for key in CandyNavigatorColors.KEYS:
				row["swatches"][state][key].color = states[state][key]
		for side in CandyNavigatorColors.SIDES:
			row["widths"][side].set_value_no_signal(float(states["widths"][side]))
		row["frame"].set_value_no_signal(float(states["frame_width"]))


#* Get a row's draft key:
func _row_path(row: Dictionary) -> String:
	if row["level"] == "header":
		return "/".join([_setting_path(), row["name"]])	#/ "navigator_colors/<theme id>/block"
	var level := "categories"
	if row["level"] == "command":
		level = "commands"
	return "/".join([_setting_path(), level, row["name"]])	#/ "navigator_colors/<theme id>/commands/Jump"


func _key(row: Dictionary, state: String, color_key: String) -> String:
	return "/".join([_row_path(row), state, color_key])


func _border_key(row: Dictionary, side: String) -> String:
	return "/".join([_row_path(row), "border_width", side])


func _frame_key(row: Dictionary) -> String:
	return "/".join([_row_path(row), "frame_width"])


func _indent_key(kind: String) -> String:
	return "/".join([_setting_path(), CandyNavigatorColors.TEXT_INDENT_KEY, kind])


func _set_color(row: Dictionary, state: String, color_key: String, color: Color) -> void:
	_take_own_look(row)
	draft.set_value(_key(row, state, color_key), color)
	_refresh_rows()


func _set_border(row: Dictionary, side: String, width: int) -> void:
	_take_own_look(row)
	draft.set_value(_border_key(row, side), width)
	_refresh_rows()


func _set_frame_width(row: Dictionary, width: int) -> void:
	_take_own_look(row)
	draft.set_value(_frame_key(row), width)
	_refresh_rows()


#* Give a command its own look, keeping what it showed, then untick Category:
func _take_own_look(row: Dictionary) -> void:
	if row["level"] != "command":
		return
	var colors := _colors()
	if not CandyNavigatorColors.uses_category(row["name"], colors):
		return
	var shown := CandyNavigatorColors.for_command(row["name"], colors, self)
	for each_state in CandyNavigatorColors.STATES:
		for key in CandyNavigatorColors.KEYS:
			draft.set_value(_key(row, each_state, key), shown[each_state][key])
	for side in CandyNavigatorColors.SIDES:
		draft.set_value(_border_key(row, side), int(shown["widths"][side]))
	draft.set_value(_frame_key(row), int(shown["frame_width"]))
	_set_uses_category(row["name"], false)


#* Remove a color, size or indent override:
func _reset_value(key: String) -> void:
	draft.erase_value(key)
	_refresh_rows()


func _set_text_indent(kind: String, indent: int) -> void:
	draft.set_value(_indent_key(kind), indent)
	_refresh_rows()


func _set_uses_category(type: String, uses: bool) -> void:
	draft.set_value("/".join([_setting_path(), "commands", type, "use_category"]), uses)
	_refresh_rows()

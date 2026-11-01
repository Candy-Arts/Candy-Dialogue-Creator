#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySettingsPage
extends VBoxContainer

const LABEL_WIDTH := 200

var page_id: String = ""
var page_title: String = ""
var page_category: String = ""
#^ Pending edits, set by the window before build():
var draft: CandySettingsDraft

var _rows: Array = []      #/ { key, control, kind }
#^ Where new rows go - the page, or an open section's body:
var _container: Control


func _ready() -> void:
	if _container == null:
		_container = self


func _init() -> void:
	theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	_container = self


#* Override - create the rows:
func build() -> void:
	pass


#* Push current values into the controls (whenever the page is shown):
func refresh() -> void:
	for row in _rows:
		var value = draft.get_value(row["key"], row["default"])
		match row["kind"]:
			"text":
				row["control"].text = str(value)
			"multiline":
				row["control"].text = str(value)
			"toggle":
				row["control"].set_pressed_no_signal(_to_bool(value))
			"number":
				row["control"].set_value_no_signal(float(str(value)))
			"choice":
				_select_value(row["control"], str(value))
			"color":
				row["control"].color = draft.get_color(row["key"])
			"path":
				row["control"].text = str(value)


#* Start a foldable section, holding the rows added until end_section():
func begin_section(title: String, state_key: String = "", start_collapsed: bool = false) -> VBoxContainer:
	var body := VBoxContainer.new()
	body.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX

	var header := Button.new()
	header.toggle_mode = true
	header.focus_mode = Control.FOCUS_NONE
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_container.add_child(header)
	_container.add_child(body)

	var open := not start_collapsed
	if state_key != "":			#/ Remembers whether it was open
		open = bool(draft.get_value(state_key, not start_collapsed))
	header.set_pressed_no_signal(open)
	body.visible = open
	#? "+" / "-", not arrows the default font may lack.
	header.text = _section_label(title, open)
	header.toggled.connect(func(pressed: bool):
		body.visible = pressed
		header.text = _section_label(title, pressed)
		if state_key != "":
			draft.set_value(state_key, pressed))

	_container = body
	return body


func end_section() -> void:
	_container = self


#* Add a control of the page's own:
func add_custom(control: Control) -> Control:
	_container.add_child(control)
	return control


#* Add a list inside a CandyListBox, and return the box:
func add_list_box(list: Control) -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = CandyThemeDefaults.LIST_BOX
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	_container.add_child(box)
	return box


#* Add a line of explanation:
func add_note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = CandyThemeDefaults.NOTE
	_container.add_child(label)
	return label


func _section_label(title: String, open: bool) -> String:
	if open:
		return "-  " + title
	return "+  " + title


#& Row helpers

func add_heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	_container.add_child(label)
	return label


func add_separator() -> void:
	_container.add_child(HSeparator.new())


func add_info(label_text: String, value_text: String) -> void:
	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row(label_text, value, "")


func add_text(key: String, label_text: String, tooltip: String = "", default_value: String = "") -> LineEdit:
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(text: String): _write(key, text))
	edit.focus_exited.connect(func(): _write(key, edit.text))
	_row(label_text, edit, tooltip)
	_track(key, edit, "text", default_value)
	return edit


func add_multiline(key: String, label_text: String, tooltip: String = "", height: int = 80) -> TextEdit:
	var edit := TextEdit.new()
	edit.custom_minimum_size.y = height
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.focus_exited.connect(func(): _write(key, edit.text))
	_row(label_text, edit, tooltip)
	_track(key, edit, "multiline", "")
	return edit


func add_toggle(key: String, label_text: String, tooltip: String = "", default_value: bool = false) -> CheckBox:
	var check := CheckBox.new()
	check.toggled.connect(func(pressed: bool): _write(key, pressed))
	_row(label_text, check, tooltip)
	_track(key, check, "toggle", default_value)
	return check


func add_number(key: String, label_text: String, min_value: float, max_value: float,
		step: float = 1.0, tooltip: String = "", default_value: Variant = 0) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value_changed.connect(func(value: float): _write(key, _number(value, step)))
	_row(label_text, spin, tooltip)
	_track(key, spin, "number", default_value)
	return spin


#* Add a choice:
#? options: [ { "label": "Left to right", "value": "LtR" }, ... ] (see fill_choice())
func add_choice(key: String, label_text: String, options: Array, tooltip: String = "",
		default_value: String = "") -> OptionButton:
	var button := OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill_choice(button, options)
	button.item_selected.connect(func(index: int): _write(key, str(button.get_item_metadata(index))))
	_row(label_text, button, tooltip)
	_track(key, button, "choice", default_value)
	return button


#* Replace a choice's items:
func fill_choice(button: OptionButton, options: Array) -> void:
	button.clear()
	for option in options:
		var index := button.item_count
		if option.has("separator"):			#/ { "separator": "Group" }: an unpickable header
			button.add_separator(str(option["separator"]))
			continue
		button.add_item(str(option.get("label", option.get("value", ""))))
		button.set_item_metadata(index, str(option.get("value", "")))
		button.get_popup().set_item_indent(index, int(option.get("indent", 0)))			#/ "indent": 1 (or more) puts an item under one


func add_color(key: String, label_text: String, tooltip: String = "") -> ColorPickerButton:
	var button := ColorPickerButton.new()
	button.custom_minimum_size.x = 120
	button.color_changed.connect(func(color: Color): draft.set_value(key, var_to_str(color)))
	_row(label_text, button, tooltip)
	_track(key, button, "color", Color.WHITE)
	return button


#* Add a folder path, with Browse and Show in file manager buttons:
#? base_key: the setting the path is relative to ("project_path" for Candy DE folders, "" for absolute).
func add_path(key: String, label_text: String, tooltip: String = "",
		base_key: String = "", default_value: String = "") -> LineEdit:
	return _path_row(key, label_text, tooltip, base_key, default_value, false, PackedStringArray())


func _path_row(key: String, label_text: String, tooltip: String, base_key: String,
		default_value: String, pick_file: bool, filters: PackedStringArray) -> LineEdit:
	var row := HBoxContainer.new()
	_container.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	row.add_child(label)

	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.tooltip_text = tooltip
	edit.text_submitted.connect(func(text: String): draft.set_value(key, text))
	edit.focus_exited.connect(func(): draft.set_value(key, edit.text))
	row.add_child(edit)

	var browse := Button.new()
	browse.text = "..."
	browse.tooltip_text = CandyLocale.t("Browse for a folder")
	browse.focus_mode = Control.FOCUS_NONE
	browse.pressed.connect(func(): _browse(key, edit, base_key, pick_file, filters))
	row.add_child(browse)

	var reveal := Button.new()
	reveal.text = "↗"
	reveal.tooltip_text = CandyLocale.t("Show in file manager")
	reveal.focus_mode = Control.FOCUS_NONE
	reveal.pressed.connect(func(): _reveal(resolve_path(edit.text, base_key), pick_file))
	row.add_child(reveal)

	_track(key, edit, "path", default_value)
	return edit


#* Get a value's absolute path (joined onto its base setting when relative):
func resolve_path(value: String, base_key: String) -> String:
	if value == "" or base_key == "" or value.is_absolute_path():
		return value
	var base := str(draft.get_value(base_key, ""))
	if base == "":
		return value
	return base.path_join(value)


#* Add a file path (as add_path()):
func add_file(key: String, label_text: String, tooltip: String = "",
		base_key: String = "", filters: PackedStringArray = PackedStringArray(),
		default_value: String = "") -> LineEdit:
	return _path_row(key, label_text, tooltip, base_key, default_value, true, filters)


#* Add a read-only value:
func add_display(key: String, label_text: String, tooltip: String = "") -> LineEdit:
	var edit := LineEdit.new()
	edit.editable = false
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row(label_text, edit, tooltip)
	_track(key, edit, "text", "")
	return edit


#* Add a row with one action button:
func add_button(label_text: String, button_text: String, handler: Callable,
		tooltip: String = "") -> Button:
	var button := Button.new()
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	_row(label_text, button, tooltip)
	return button


func _browse(key: String, edit: LineEdit, base_key: String, pick_file: bool = false,
		filters: PackedStringArray = PackedStringArray()) -> void:
	var dialog := FileDialog.new()
	if pick_file:
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.filters = filters
		dialog.title = CandyLocale.t("Choose a file")
	else:
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		dialog.title = CandyLocale.t("Choose a folder")
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	var current := resolve_path(edit.text, base_key)
	if current != "" and DirAccess.dir_exists_absolute(current):
		dialog.current_dir = current
	elif base_key != "":
		var base := str(draft.get_value(base_key, ""))
		if DirAccess.dir_exists_absolute(base):
			dialog.current_dir = base

	dialog.file_selected.connect(func(path: String):
		edit.text = _store_path(key, path, base_key)
		dialog.queue_free())
	dialog.dir_selected.connect(func(path: String):
		edit.text = _store_path(key, path, base_key)
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


#* Store a path, relative to its base when under it:
func _store_path(key: String, path: String, base_key: String) -> String:
	var stored := path
	if base_key != "":
		var base := str(draft.get_value(base_key, ""))
		if base != "" and path.begins_with(base):
			stored = path.substr(base.length()).lstrip("/\\")			#/ Keeps a profile portable if the project moves
	draft.set_value(key, stored)
	return stored


func _reveal(path: String, is_file: bool = false) -> void:
	if path == "":
		return
	if is_file:
		if not FileAccess.file_exists(path):
			push_warning("CandySettings: file does not exist: %s" % path)
			return
		OS.shell_show_in_file_manager(path, false)
		return
	if not DirAccess.dir_exists_absolute(path):
		push_warning("CandySettings: folder does not exist: %s" % path)
		return
	OS.shell_show_in_file_manager(path, true)


#& Internals

func _row(label_text: String, control: Control, tooltip: String) -> void:
	var row := HBoxContainer.new()
	_container.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(label)

	control.tooltip_text = tooltip
	row.add_child(control)


func _track(key: String, control: Control, kind: String, default_value: Variant) -> void:
	_rows.append({"key": key, "control": control, "kind": kind, "default": default_value})


#* Write a value, keeping its stored type ("250" stays a string):
func _write(key: String, value: Variant) -> void:
	var current = draft.get_value(key, null)
	if current is String and not value is String:
		value = str(value)
	elif current is bool and not value is bool:
		value = _to_bool(value)
	draft.set_value(key, value)


#* Convert a number - int for a whole step, float otherwise:
func _number(value: float, step: float) -> Variant:
	if step < 1.0:
		return value
	return int(value)


func _to_bool(value: Variant) -> bool:
	if value is bool:
		return value
	if value is String:
		return value == "1" or value.to_lower() == "true"
	return bool(value)


func _select_value(button: OptionButton, value: String) -> void:
	for i in button.item_count:
		if str(button.get_item_metadata(i)) == value:
			button.select(i)
			return
	button.select(-1)
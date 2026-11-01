#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyColorSelectorPanel
extends CandyPanel

const MODES := ["hex", "rgb1", "rgb255"]
const MODE_LABELS := {"hex": "Hex", "rgb1": "0-1", "rgb255": "0-255"}	#/ translatable
const MODE_TOOLTIPS := {
	"hex": "Hexadecimal. Click for RGB values from 0 to 1.",	#/ translatable
	"rgb1": "RGB values from 0 to 1. Click for RGB values from 0 to 255.",	#/ translatable
	"rgb255": "RGB values from 0 to 255. Click for hexadecimal.",	#/ translatable
}
const FORMATS := ["code", "color"]
const FORMAT_LABELS := {"code": "Code", "color": "Color()"}	#/ translatable
const FORMAT_TOOLTIPS := {
	"code": "Just the color code. Click for GDScript's Color().",	#/ translatable
	"color": "GDScript's Color(), or Color8() for 0-255 values. Click for the code alone.",	#/ translatable
}
const DEFAULT_COLOR := Color(1, 1, 1, 1)
const DECIMALS := 3

var _color: Color = DEFAULT_COLOR
var _mode: String = "hex"
var _format: String = "code"
var _scroll: bool = true
var _single_row: bool = false
#^ "" until the panel claims one in _ready():
var _reference: String = ""
var _pending_state: Dictionary = {}

var _scroll_container: ScrollContainer
var _top_row: HBoxContainer
var _bottom_row: HBoxContainer
var _picker: ColorPickerButton
var _mode_button: Button
var _format_button: Button
var _color_text: RichTextLabel
var _settings_dialog: AcceptDialog
var _scroll_check: CheckBox
var _single_row_check: CheckBox
var _min_size_fields: CandyMinSizeFields
var _reference_edit: LineEdit
var _reference_error: Label


func _ready() -> void:
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scroll_container)
	#? Without scrolling, the contents' size is the panel's minimum size.
	_scroll_container.minimum_size_changed.connect(update_minimum_size)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(root)

	_top_row = HBoxContainer.new()
	root.add_child(_top_row)

	#? CandyColorSwatchButton - the whole button shows the color.
	_picker = CandyColorSwatchButton.new()
	_picker.edit_alpha = true
	_picker.focus_mode = Control.FOCUS_NONE
	_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker.custom_minimum_size.x = 40
	_picker.tooltip_text = CandyLocale.t("Pick a color")
	_picker.color_changed.connect(func(color: Color):
		_color = color
		CandyInserts.set_reference_color(self, _color)
		_update_text())
	_top_row.add_child(_picker)

	_mode_button = _make_button(_top_row, _on_mode_pressed)
	_format_button = _make_button(_top_row, _on_format_pressed)

	_bottom_row = HBoxContainer.new()
	root.add_child(_bottom_row)

	var insert_button := _make_button(_bottom_row, _on_insert_pressed)
	insert_button.text = "↓"
	insert_button.tooltip_text = CandyLocale.t("Insert at the caret of the focused text field")
	var copy_button := _make_button(_bottom_row, _on_copy_pressed)
	copy_button.text = CandyLocale.t("C", "Copy button")
	copy_button.tooltip_text = CandyLocale.t("Copy to the clipboard")

	#? A RichTextLabel, so the text can be selected; one line, clipped like a Label.
	_color_text = RichTextLabel.new()
	_color_text.bbcode_enabled = false
	_color_text.selection_enabled = true
	_color_text.context_menu_enabled = true
	_color_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_color_text.scroll_active = false
	_color_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_color_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_color_text.theme_changed.connect(_update_text_height)
	_bottom_row.add_child(_color_text)

	_update_text_height()
	_build_settings_dialog()

	if not _pending_state.is_empty():
		_apply_state(_pending_state)
	_claim_reference(_reference)
	_refresh()


#* Hold the reference only while in a window:
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			#% Coming back (_ready() makes the first claim):
			if _picker != null:
				_claim_reference(_reference)
		#? On exit too - a layout rebuild frees dropped panels later, and a new Color Selector would get the next reference.
		NOTIFICATION_EXIT_TREE, NOTIFICATION_PREDELETE:
			CandyInserts.release_color_reference(self)


#* Claim wanted as the reference, or the lowest free one if empty or taken:
func _claim_reference(wanted: String) -> void:
	var reference := wanted.strip_edges()
	if reference == "" or not CandyInserts.claim_color_reference(reference, self, _color):
		reference = CandyInserts.free_color_reference(self)
		CandyInserts.claim_color_reference(reference, self, _color)
	_reference = reference


#* Make a button that never takes focus, so the target text field keeps it:
func _make_button(parent: Control, handler: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func _refresh() -> void:
	_apply_rows()
	_apply_scroll()
	_picker.color = _color
	_mode_button.text = CandyLocale.t(str(MODE_LABELS[_mode]))
	_mode_button.tooltip_text = CandyLocale.t(str(MODE_TOOLTIPS[_mode]))
	_format_button.text = CandyLocale.t(str(FORMAT_LABELS[_format]))
	_format_button.tooltip_text = CandyLocale.t(str(FORMAT_TOOLTIPS[_format]))
	_update_text()


func _update_text() -> void:
	_color_text.text = _text()
	_color_text.tooltip_text = _color_text.text


#* Set the text's height to one line (fit_content would stop clipping):
func _update_text_height() -> void:
	var font := _color_text.get_theme_font("normal_font")
	var font_size := _color_text.get_theme_font_size("normal_font_size")
	_color_text.custom_minimum_size.y = font.get_height(font_size)


#& Text

#* The color in the current mode and format:
func _text() -> String:
	var code := _code(_mode)
	if _format == "color":
		if _mode == "hex":
			return "Color(\"%s\")" % code
		if _mode == "rgb255":
			return "Color8(%s)" % code
		return "Color(%s)" % code
	return code


func _code(mode: String) -> String:
	var opaque := is_equal_approx(_color.a, 1.0)
	if mode == "hex":
		return "#" + _color.to_html(not opaque)
	var values: PackedStringArray = []
	var channels := [_color.r, _color.g, _color.b]
	if not opaque:
		channels.append(_color.a)
	for channel in channels:
		if mode == "rgb255":
			values.append(str(roundi(float(channel) * 255.0)))
		else:
			values.append(String.num(snappedf(float(channel), 0.001), DECIMALS))
	return ", ".join(values)


#& Buttons

func _on_mode_pressed() -> void:
	_mode = str(MODES[(MODES.find(_mode) + 1) % MODES.size()])
	_refresh()


func _on_format_pressed() -> void:
	_format = str(FORMATS[(FORMATS.find(_format) + 1) % FORMATS.size()])
	_refresh()


func _on_insert_pressed() -> void:
	CandyInserts.apply_text(_text(), "", "")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(_color_text.text)


#& Rows, scrolling and settings

#* Move picker, mode and format - top row, or after the color text when single row:
func _apply_rows() -> void:
	var target := _top_row
	if _single_row:
		target = _bottom_row
	for control: Control in [_picker, _mode_button, _format_button]:
		if control.get_parent() != target:
			control.reparent(target)
	_top_row.visible = not _single_row



func _apply_scroll() -> void:
	var scroll_mode := ScrollContainer.SCROLL_MODE_AUTO
	if not _scroll:
		scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll_container.scroll_horizontal = 0
		_scroll_container.scroll_vertical = 0
	_scroll_container.horizontal_scroll_mode = scroll_mode
	_scroll_container.vertical_scroll_mode = scroll_mode
	update_minimum_size()


#* With scrolling off, keep the panel at least as big as its contents:
func _get_minimum_size() -> Vector2:
	if _scroll or _scroll_container == null:
		return Vector2.ZERO
	return _scroll_container.get_combined_minimum_size()


func _build_settings_dialog() -> void:
	_settings_dialog = AcceptDialog.new()
	_settings_dialog.title = CandyLocale.t("Options")
	_settings_dialog.ok_button_text = CandyLocale.t("Close")
	add_child(_settings_dialog)

	var box := VBoxContainer.new()
	_settings_dialog.add_child(box)

	var reference_row := HBoxContainer.new()
	box.add_child(reference_row)
	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	reference_label.tooltip_text = CandyLocale.t("Inserts panels with this reference take their color tags' color from this panel.")
	reference_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	reference_row.add_child(reference_label)
	_reference_edit = LineEdit.new()
	_reference_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reference_edit.tooltip_text = reference_label.tooltip_text
	_reference_edit.text_changed.connect(func(_typed: String): _check_reference())
	reference_row.add_child(_reference_edit)
	_reference_error = Label.new()
	_reference_error.theme_type_variation = CandyThemeDefaults.ERROR
	box.add_child(_reference_error)

	_single_row_check = CheckBox.new()
	_single_row_check.text = CandyLocale.t("Single row")
	_single_row_check.tooltip_text = CandyLocale.t("Everything on one row: insert, copy, the color text, the color picker, then the mode and format buttons.")
	_single_row_check.toggled.connect(func(pressed: bool):
		_single_row = pressed
		_apply_rows())
	box.add_child(_single_row_check)

	_scroll_check = CheckBox.new()
	_scroll_check.text = CandyLocale.t("Scroll when the contents don't fit")
	_scroll_check.tooltip_text = CandyLocale.t("Off: the panel can't be made smaller than its contents.")
	_scroll_check.toggled.connect(func(pressed: bool):
		_scroll = pressed
		_apply_scroll())
	box.add_child(_scroll_check)

	_min_size_fields = CandyMinSizeFields.new()
	box.add_child(_min_size_fields)

	#Ł On close - claim a usable reference, drop any other:
	_settings_dialog.visibility_changed.connect(func():
		if _settings_dialog.visible:
			return
		if _check_reference():
			_claim_reference(_reference_edit.text)
		set_area_size_limits(_min_size_fields.get_limits()))


#* Whether the typed reference can be this panel's (shows why not):
func _check_reference() -> bool:
	var reference := _reference_edit.text.strip_edges()
	var problem := ""
	if reference == "":
		problem = CandyLocale.t("Type a reference.")
	elif CandyInserts.color_reference_taken(reference, self):
		problem = CandyLocale.t("Another Color Selector already has the reference \"%s\".") % reference
	_reference_error.text = problem
	_reference_error.visible = problem != ""
	return problem == ""


#* Options, from the Area's + menu or a tab's right-click menu:
func has_settings() -> bool:
	return true


func open_settings() -> void:
	_single_row_check.set_pressed_no_signal(_single_row)
	_scroll_check.set_pressed_no_signal(_scroll)
	_reference_edit.text = _reference
	_check_reference()
	_min_size_fields.visible = fills_area
	_min_size_fields.set_limits(area_size_limits())
	_settings_dialog.reset_size()
	_settings_dialog.popup_centered()


#& Panel state

func get_state() -> Dictionary:
	if _picker == null:
		return _pending_state
	return {"color": var_to_str(_color), "mode": _mode, "format": _format, "scroll": _scroll,
		"single_row": _single_row, "reference": _reference}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _picker != null:
		_apply_state(state)
		_refresh()


func _apply_state(state: Dictionary) -> void:
	_color = CandySpeechEditorSettings.to_color(state.get("color", ""), DEFAULT_COLOR)
	_mode = str(state.get("mode", "hex"))
	if not MODES.has(_mode):
		_mode = "hex"
	_scroll = CandyVariantFile.to_bool(state.get("scroll", true), true)
	_single_row = CandyVariantFile.to_bool(state.get("single_row", false), false)
	_format = str(state.get("format", "code"))
	if not FORMATS.has(_format):
		_format = "code"
	_reference = str(state.get("reference", ""))
	#% A loaded layout changes a panel in use - claim its reference now:
	if _picker != null and _picker.is_inside_tree():
		_claim_reference(_reference)
	CandyInserts.set_reference_color(self, _color)
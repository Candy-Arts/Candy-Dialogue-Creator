#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyButtonLayoutOptions
extends VBoxContainer

signal changed

const LAYOUT_COLUMNS := "columns"
const LAYOUT_FLOW := "flow"
const MAX_COLUMNS := 8
const DEFAULT_MIN_WIDTH := 100
const MAX_MIN_WIDTH := 1000
const ALIGN_LEFT := "left"
const ALIGN_CENTER := "center"
const ALIGN_RIGHT := "right"
#^ [value, label], in the dropdown's order:
const ALIGNMENTS := [[ALIGN_LEFT, "Left"], [ALIGN_CENTER, "Centered"], [ALIGN_RIGHT, "Right"]]      #/ translatable

const LABEL_WIDTH := 170

var layout: String = LAYOUT_COLUMNS
var columns: int = 2
var min_width: int = DEFAULT_MIN_WIDTH
var button_alignment: String = ALIGN_LEFT
var scroll: bool = true
var fill_height: bool = false

var _layout_button: OptionButton
var _columns_spin: SpinBox
var _min_width_spin: SpinBox
var _alignment_button: OptionButton
var _scroll_check: CheckBox
var _fill_check: CheckBox


func _init() -> void:
	_layout_button = OptionButton.new()
	_layout_button.add_item(CandyLocale.t("Columns"))
	_layout_button.set_item_metadata(0, LAYOUT_COLUMNS)
	_layout_button.set_item_tooltip(0, CandyLocale.t("A fixed number of columns. Buttons stretch to fill the width."))
	_layout_button.add_item(CandyLocale.t("Flow"))
	_layout_button.set_item_metadata(1, LAYOUT_FLOW)
	_layout_button.set_item_tooltip(1, CandyLocale.t("Buttons sit side by side and wrap to the next row when they run out of space."))
	_layout_button.item_selected.connect(func(index: int):
		layout = str(_layout_button.get_item_metadata(index))
		_update_enabled()
		changed.emit())
	_add_row(CandyLocale.t("Layout"), _layout_button)

	_columns_spin = SpinBox.new()
	_columns_spin.min_value = 1
	_columns_spin.max_value = MAX_COLUMNS
	_columns_spin.tooltip_text = CandyLocale.t("Columns layout only.")
	_columns_spin.value_changed.connect(func(value: float):
		columns = int(value)
		changed.emit())
	_add_row(CandyLocale.t("Columns"), _columns_spin)

	_min_width_spin = SpinBox.new()
	_min_width_spin.min_value = 0
	_min_width_spin.max_value = MAX_MIN_WIDTH
	_min_width_spin.step = 5
	_min_width_spin.suffix = CandyLocale.t("px")
	_min_width_spin.tooltip_text = CandyLocale.t("Flow layout only. A button with a longer label is wider.")
	_min_width_spin.value_changed.connect(func(value: float):
		min_width = int(value)
		changed.emit())
	_add_row(CandyLocale.t("Minimum button width"), _min_width_spin)

	_alignment_button = OptionButton.new()
	for i in ALIGNMENTS.size():
		_alignment_button.add_item(CandyLocale.t(str(ALIGNMENTS[i][1])))
		_alignment_button.set_item_metadata(i, ALIGNMENTS[i][0])
	_alignment_button.tooltip_text = CandyLocale.t("Flow layout only. Where each row of buttons sits in the panel.")
	_alignment_button.item_selected.connect(func(index: int):
		button_alignment = str(_alignment_button.get_item_metadata(index))
		changed.emit())
	_add_row(CandyLocale.t("Alignment"), _alignment_button)

	_scroll_check = CheckBox.new()
	_scroll_check.text = CandyLocale.t("Scroll when the buttons don't fit")
	_scroll_check.tooltip_text = CandyLocale.t("Off: the panel can't be made smaller than its buttons.")
	_scroll_check.toggled.connect(func(pressed: bool):
		scroll = pressed
		changed.emit())
	add_child(_scroll_check)

	_fill_check = CheckBox.new()
	_fill_check.text = CandyLocale.t("Fill the panel's height")
	_fill_check.tooltip_text = CandyLocale.t("Columns layout only. The buttons grow taller to fill the panel, every row the same height.")
	_fill_check.toggled.connect(func(pressed: bool):
		fill_height = pressed
		changed.emit())
	#? Only for the panels that ask for it (offer_fill()).
	_fill_check.visible = false
	add_child(_fill_check)


#* Show the Fill option (the panel lays its buttons out with apply_fill()):
func offer_fill() -> void:
	_fill_check.visible = true


func _add_row(label_text: String, field: Control) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	row.add_child(field)


#* Show values without emitting changed:
func set_values(p_layout: String, p_columns: int, p_min_width: int, p_alignment: String,
		p_scroll: bool, p_fill_height: bool = false) -> void:
	fill_height = p_fill_height
	_fill_check.set_pressed_no_signal(fill_height)
	layout = p_layout
	columns = p_columns
	min_width = p_min_width
	button_alignment = p_alignment
	scroll = p_scroll
	_scroll_check.set_pressed_no_signal(scroll)
	if layout == LAYOUT_FLOW:
		_layout_button.select(1)
	else:
		_layout_button.select(0)
	_columns_spin.set_value_no_signal(columns)
	_min_width_spin.set_value_no_signal(min_width)
	for i in ALIGNMENTS.size():
		if ALIGNMENTS[i][0] == button_alignment:
			_alignment_button.select(i)
	_update_enabled()


func _update_enabled() -> void:
	_columns_spin.editable = layout == LAYOUT_COLUMNS
	_min_width_spin.editable = layout == LAYOUT_FLOW
	_alignment_button.disabled = layout != LAYOUT_FLOW
	_fill_check.disabled = layout != LAYOUT_COLUMNS


#& Helpers for panels

static func read_layout(state: Dictionary) -> String:
	if str(state.get("layout", LAYOUT_COLUMNS)) == LAYOUT_FLOW:
		return LAYOUT_FLOW
	return LAYOUT_COLUMNS


static func read_min_width(state: Dictionary) -> int:
	return clampi(int(state.get("min_button_width", DEFAULT_MIN_WIDTH)), 0, MAX_MIN_WIDTH)


static func read_alignment(state: Dictionary) -> String:
	var value := str(state.get("alignment", ALIGN_LEFT))
	if value == ALIGN_CENTER or value == ALIGN_RIGHT:
		return value
	return ALIGN_LEFT


static func read_scroll(state: Dictionary) -> bool:
	return CandyVariantFile.to_bool(state.get("scroll", true), true)


static func read_fill_height(state: Dictionary) -> bool:
	return CandyVariantFile.to_bool(state.get("fill_height", false), false)


#* Make the buttons fill the height, or not: the content, each grid and its buttons expand down:
#? A grid's share is its number of rows, so every row is as tall. Columns layout only.
static func apply_fill(content: Array, grids: Array, fill: bool) -> void:
	var flag := Control.SIZE_FILL
	if fill:
		flag = Control.SIZE_EXPAND_FILL
	for control: Control in content:
		control.size_flags_vertical = flag
	for grid: Container in grids:
		grid.size_flags_vertical = flag
		if grid is GridContainer:
			grid.size_flags_stretch_ratio = maxf(1.0, ceilf(float(grid.get_child_count()) / float(grid.columns)))
		for button in grid.get_children():
			if button is Control:
				button.size_flags_vertical = flag


#* Switch a panel's ScrollContainer between scrolling and fitting its content:
static func apply_scroll(scroll_container: ScrollContainer, p_scroll: bool) -> void:
	if p_scroll:
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		#? The panel passes the content's size on in _get_minimum_size().
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.scroll_vertical = 0


static func make_container(p_layout: String, p_columns: int, p_alignment: String) -> Container:
	if p_layout == LAYOUT_FLOW:
		var flow := HFlowContainer.new()
		match p_alignment:
			ALIGN_CENTER:
				flow.alignment = FlowContainer.ALIGNMENT_CENTER
			ALIGN_RIGHT:
				flow.alignment = FlowContainer.ALIGNMENT_END
			_:
				flow.alignment = FlowContainer.ALIGNMENT_BEGIN
		return flow
	var grid := GridContainer.new()
	grid.columns = clampi(p_columns, 1, MAX_COLUMNS)
	return grid


#* Size a button for the layout:
static func fit_button(button: Button, p_layout: String, p_min_width: int, clip: bool = false) -> void:
	if p_layout == LAYOUT_FLOW:
		button.custom_minimum_size.x = p_min_width
		button.size_flags_horizontal = Control.SIZE_FILL
		button.clip_text = false			#/ A flow button is as wide as its label
	else:
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = clip
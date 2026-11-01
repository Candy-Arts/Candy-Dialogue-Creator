#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsPage
extends VBoxContainer

#^ Any click in the page (the view tracks the last one used):
signal activated
#^ A link of the page, its header or its footer was clicked:
signal link_clicked(target: String)
#^ The text width changed, once the resizing pauses:
signal content_width_changed

const MIN_TEXT_MARGIN := 24
const MARKER_WIDTH := 4
#^ Widest the text gets; the margins take the rest:
const MAX_TEXT_WIDTH := 900
const FONT_SIZE_NAMES: Array[StringName] = [&"normal_font_size", &"bold_font_size", &"italics_font_size",
	&"bold_italics_font_size", &"mono_font_size"]
const SCROLL_BAR_STYLES: Array[StringName] = [&"scroll", &"scroll_focus", &"grabber", &"grabber_highlight",
	&"grabber_pressed"]
#^ Seconds the text width stays the same before content_width_changed:
const WIDTH_SETTLE_TIME := 0.15

var current_page := ""
#^ The widths of the header's, the footer's and the text's images that follow the text width, and the text width they were sized for (CandyDocsView):
var header_image_widths: Array[int] = []
var header_sized_for := 0
var footer_image_widths: Array[int] = []
var footer_sized_for := 0
var body_image_widths: Array[int] = []
var body_sized_for := 0
var history: Array[String] = []
var history_index := -1

var back_button: Button
var forward_button: Button
var close_button: Button

var _bar: PanelContainer
var _marker: ColorRect
var _reader: Control
var _background_rect: ColorRect
var _texture_rect: TextureRect
var _column: VBoxContainer
var _scroll_box: ScrollContainer
var _content_box: VBoxContainer
var _header_holder: PanelContainer
var _header_background: ColorRect
var _header_texture_rect: TextureRect
var _header_label: RichTextLabel
var _header_box := StyleBoxEmpty.new()
var _label: RichTextLabel
var _label_box := StyleBoxEmpty.new()
#^ Pushes a scrolling footer to the bottom of a short page:
var _footer_spacer: Control
var _footer_holder: PanelContainer
var _footer_background: ColorRect
var _footer_texture_rect: TextureRect
var _footer_label: RichTextLabel
var _footer_box := StyleBoxEmpty.new()
#^ Whether the header and footer scroll with the page (the database's choice):
var _header_scrolls := true
var _footer_scrolls := true
var _width_timer: Timer
var _last_width := 0


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(240, 0)
	theme_type_variation = CandyThemeDefaults.FLUSH_VBOX

	_bar = PanelContainer.new()
	_bar.theme_type_variation = CandyThemeDefaults.DOCS_TOOLBAR
	add_child(_bar)
	var bar_row := HBoxContainer.new()
	_bar.add_child(bar_row)
	#? The page's color from the page list, when two pages show.
	_marker = ColorRect.new()
	_marker.custom_minimum_size = Vector2(MARKER_WIDTH, 0)
	_marker.visible = false
	bar_row.add_child(_marker)
	back_button = _add_button(bar_row, CandyLocale.t("Back"))
	forward_button = _add_button(bar_row, CandyLocale.t("Forward"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_child(spacer)
	close_button = _add_button(bar_row, CandyLocale.t("Close this page"))
	close_button.visible = false

	_reader = Control.new()
	_reader.clip_contents = true
	_reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reader.resized.connect(_update_margins)
	add_child(_reader)
	_background_rect = ColorRect.new()
	_reader.add_child(_background_rect)
	_texture_rect = TextureRect.new()
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reader.add_child(_texture_rect)
	#? Header and footer in the scroll container, or around it in the column (set_header_scrolls(), set_footer_scrolls()).
	_column = VBoxContainer.new()
	_column.theme_type_variation = CandyThemeDefaults.FLUSH_VBOX
	_reader.add_child(_column)
	_scroll_box = ScrollContainer.new()
	_scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.add_child(_scroll_box)
	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#? Fills the page's height when the text is shorter, so _footer_spacer can push the footer down.
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.theme_type_variation = CandyThemeDefaults.FLUSH_VBOX
	_scroll_box.add_child(_content_box)
	var header := _add_band(_header_box, CandyThemeDefaults.DOCS_HEADER)
	_header_holder = header["holder"]
	_header_background = header["background"]
	_header_texture_rect = header["texture_rect"]
	_header_label = header["label"]
	_label = _make_label(_label_box)
	_content_box.add_child(_label)
	_label.resized.connect(_on_label_resized)
	_footer_spacer = Control.new()
	_footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_footer_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	_content_box.add_child(_footer_spacer)
	var footer := _add_band(_footer_box, CandyThemeDefaults.DOCS_FOOTER)
	_footer_holder = footer["holder"]
	_footer_background = footer["background"]
	_footer_texture_rect = footer["texture_rect"]
	_footer_label = footer["label"]
	_width_timer = Timer.new()
	_width_timer.one_shot = true
	_width_timer.wait_time = WIDTH_SETTLE_TIME
	_width_timer.timeout.connect(content_width_changed.emit)
	add_child(_width_timer)
	for control: Control in [_background_rect, _texture_rect, _column]:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for control: Control in [_bar, _scroll_box, _header_label, _label, _footer_label]:
		control.gui_input.connect(_on_gui_input)


#* Add a header or footer to the scrolled content, hidden until shown. Returns { "holder", "background", "texture_rect", "label" }:
#? PanelContainer stacks the background and image behind the text.
func _add_band(box: StyleBox, type_variation: StringName) -> Dictionary:
	var holder := PanelContainer.new()
	holder.theme_type_variation = type_variation
	holder.visible = false
	_content_box.add_child(holder)
	var background := ColorRect.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(background)
	var band_texture_rect := TextureRect.new()
	band_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(band_texture_rect)
	var band_label := _make_label(box)
	holder.add_child(band_label)
	return {"holder": holder, "background": background, "texture_rect": band_texture_rect, "label": band_label}


#* Make a selectable, copyable page label:
func _make_label(box: StyleBox) -> RichTextLabel:
	var text_label := RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.selection_enabled = true
	text_label.context_menu_enabled = true
	text_label.focus_mode = Control.FOCUS_CLICK
	#? Links are underlined by the view ([u]), so linked images aren't.
	text_label.meta_underlined = false
	text_label.add_theme_stylebox_override(&"normal", box)
	text_label.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	text_label.meta_clicked.connect(func(meta: Variant) -> void: link_clicked.emit(str(meta)))
	return text_label


func _add_button(row: HBoxContainer, tooltip: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.theme_type_variation = CandyThemeDefaults.FLAT_BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tooltip
	row.add_child(button)
	return button


#* Emit activated on a click:
func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:	#/ Not the mouse wheel, which also reports presses
		activated.emit()


#& History

#* Add a page after the current one, dropping the pages ahead:
func record(page_id: String) -> void:
	history = history.slice(0, history_index + 1)
	history.append(page_id)
	history_index = history.size() - 1


func clear_history() -> void:
	history.clear()
	history_index = -1
	update_buttons()


func can_go_back() -> bool:
	return history_index > 0


func can_go_forward() -> bool:
	return history_index < history.size() - 1


func update_buttons() -> void:
	back_button.disabled = not can_go_back()
	forward_button.disabled = not can_go_forward()


#& Display

func show_text(bbcode: String) -> void:
	_label.text = bbcode
	_scroll_box.set_deferred(&"scroll_vertical", 0)


#* Show new text for the same page, keeping the scroll:
func update_text(bbcode: String) -> void:
	var scroll := _scroll_box.scroll_vertical
	_label.text = bbcode
	_scroll_box.set_deferred(&"scroll_vertical", scroll)


#* Show a message instead of a page:
func show_message(bbcode: String) -> void:
	current_page = ""
	show_text(bbcode)
	update_buttons()


#* Show the header with this text, or hide it:
func show_header(bbcode: String, shown: bool) -> void:
	_header_holder.visible = shown
	if shown:
		_header_label.text = bbcode


#* Make the header scroll with the page, or stay fixed above it:
func set_header_scrolls(scrolls: bool) -> void:
	_header_scrolls = scrolls
	var wanted_parent: Node = _column
	if _header_scrolls:
		wanted_parent = _content_box
	if _header_holder.get_parent() != wanted_parent:
		_header_holder.get_parent().remove_child(_header_holder)
		wanted_parent.add_child(_header_holder)
	wanted_parent.move_child(_header_holder, 0)


#* Show the footer with this text, or hide it:
func show_footer(bbcode: String, shown: bool) -> void:
	_footer_holder.visible = shown
	if shown:
		_footer_label.text = bbcode


#* Make the footer scroll with the page (after the text), or stay fixed below it:
func set_footer_scrolls(scrolls: bool) -> void:
	_footer_scrolls = scrolls
	var wanted_parent: Node = _column
	if _footer_scrolls:
		wanted_parent = _content_box
	if _footer_holder.get_parent() != wanted_parent:
		_footer_holder.get_parent().remove_child(_footer_holder)
		wanted_parent.add_child(_footer_holder)
	wanted_parent.move_child(_footer_holder, -1)


#* Show the close button (while another page is open beside):
func set_closable(closable: bool) -> void:
	close_button.visible = closable


#* Set the page's color in the bar (transparent hides it):
func set_marker(color: Color) -> void:
	_marker.visible = color.a > 0.0
	_marker.color = color


#* Text width, for images wider than it:
func content_width() -> int:
	return int(_label.size.x - _label_box.content_margin_left - _label_box.content_margin_right)


#* Wait for the width to settle (the height changes with every new text, and is ignored):
func _on_label_resized() -> void:
	var width := content_width()
	#% Not in the tree yet (the label enters it before the timer) - the page is drawn once it is:
	if not _width_timer.is_inside_tree():
		return
	if width == _last_width:
		return
	_last_width = width
	_width_timer.start()


func _update_margins() -> void:
	var margin := maxi(MIN_TEXT_MARGIN, int((_reader.size.x - MAX_TEXT_WIDTH) / 2.0))
	_label_box.content_margin_left = margin
	_label_box.content_margin_right = margin
	_label_box.content_margin_top = 20
	_label_box.content_margin_bottom = 20
	_header_box.content_margin_left = margin
	_header_box.content_margin_right = margin
	_header_box.content_margin_top = 12
	_header_box.content_margin_bottom = 4
	_footer_box.content_margin_left = margin
	_footer_box.content_margin_right = margin
	_footer_box.content_margin_top = 4
	_footer_box.content_margin_bottom = 12


#* Set the text size in pixels (0 = the theme's):
func set_font_size(size_value: int) -> void:
	for text_label: RichTextLabel in [_label, _header_label, _footer_label]:
		for font_name in FONT_SIZE_NAMES:
			if size_value > 0:
				text_label.add_theme_font_size_override(font_name, size_value)
			else:
				text_label.remove_theme_font_size_override(font_name)
	_update_margins()


#* Set the font of [code] text:
func set_mono_font(font: Font) -> void:
	for text_label: RichTextLabel in [_label, _header_label, _footer_label]:
		text_label.add_theme_font_override(&"mono_font", font)


#* Apply the page's colors and background (CandyDocsLook.resolve_style()):
func apply_style(style: Dictionary) -> void:
	var text_color: Color = style["text_color"]
	_background_rect.color = style["background_color"]
	var texture: Texture2D = style["texture"]
	_texture_rect.texture = texture
	_texture_rect.visible = texture != null
	_texture_rect.modulate.a = style["opacity"]
	_set_fit(_texture_rect, style["texture_mode"])
	_set_label_colors(_label, text_color, style["own_text"])
	_apply_band_style(style, "header", _header_background, _header_texture_rect, _header_label)
	_apply_band_style(style, "footer", _footer_background, _footer_texture_rect, _footer_label)
	_set_scroll_bar_look(style, text_color)


#* Apply a header's or footer's background and text color (transparent ones are the page's):
#? band - "header" or "footer", the start of its style keys.
func _apply_band_style(style: Dictionary, band: String, background: ColorRect, band_texture_rect: TextureRect, band_label: RichTextLabel) -> void:
	var band_texture: Texture2D = style[band + "_texture"]
	background.color = style[band + "_background_color"]
	band_texture_rect.texture = band_texture
	band_texture_rect.visible = band_texture != null
	_set_fit(band_texture_rect, style[band + "_texture_mode"])
	var band_text_color: Color = style[band + "_text_color"]
	if band_text_color.a == 0.0:
		band_text_color = style["text_color"]
	_set_label_colors(band_label, band_text_color, style["own_text"])


func _set_fit(rect: TextureRect, mode: String) -> void:
	match mode:
		"Tile":
			rect.stretch_mode = TextureRect.STRETCH_TILE
		"Stretch":
			rect.stretch_mode = TextureRect.STRETCH_SCALE
		_:
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


#* Set a label's text and table colors:
func _set_label_colors(text_label: RichTextLabel, text_color: Color, own_text: bool) -> void:
	text_label.add_theme_color_override(&"default_color", text_color)
	text_label.add_theme_color_override(&"table_border", Color(text_color, 0.35))
	text_label.add_theme_color_override(&"table_odd_row_bg", Color(text_color, 0.06))
	text_label.add_theme_color_override(&"table_even_row_bg", Color(text_color, 0.0))
	#% The documentation's own text color: remove Candy DC's text outline:
	if own_text:
		text_label.add_theme_constant_override(&"outline_size", 0)
	else:
		text_label.remove_theme_constant_override(&"outline_size")


#* Style the scroll bar - Candy DC's, or the documentation's (own_scroll_bar):
func _set_scroll_bar_look(style: Dictionary, text_color: Color) -> void:
	var bar_node := _scroll_box.get_v_scroll_bar()
	if not style["own_scroll_bar"]:
		for style_name in SCROLL_BAR_STYLES:
			bar_node.remove_theme_stylebox_override(style_name)
		return
	#Ł Make transparent colors from the text color (hover / pressed from the grabber's):
	var track: Color = style["scroll_bar_color"]
	if track.a == 0.0:
		track = Color(text_color, 0.08)
	var grabber: Color = style["scroll_grabber_color"]
	var hover: Color = style["scroll_grabber_hover_color"]
	var pressed: Color = style["scroll_grabber_pressed_color"]
	if grabber.a == 0.0:
		grabber = Color(text_color, 0.35)
		if hover.a == 0.0:
			hover = Color(text_color, 0.5)
		if pressed.a == 0.0:
			pressed = Color(text_color, 0.65)
	if hover.a == 0.0:
		hover = grabber.lerp(text_color, 0.25)
	if pressed.a == 0.0:
		pressed = grabber.lerp(text_color, 0.45)
	var width: int = style["scroll_bar_width"]
	var radius: int = style["scroll_bar_radius"]
	bar_node.add_theme_stylebox_override(&"scroll", _scroll_bar_box(track, width, radius))
	bar_node.add_theme_stylebox_override(&"scroll_focus", _scroll_bar_box(track, width, radius))
	bar_node.add_theme_stylebox_override(&"grabber", _scroll_bar_box(grabber, width, radius))
	bar_node.add_theme_stylebox_override(&"grabber_highlight", _scroll_bar_box(hover, width, radius))
	bar_node.add_theme_stylebox_override(&"grabber_pressed", _scroll_bar_box(pressed, width, radius))


#* Make a scroll bar box:
func _scroll_bar_box(color: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	#? The margins give the bar its width.
	box.content_margin_left = width / 2.0
	box.content_margin_right = width - width / 2.0
	return box

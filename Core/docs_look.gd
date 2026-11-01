#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsLook

const DOCUMENTATION := "documentation"
const CANDY_DC := "candy_dc"
const LOOKS := [DOCUMENTATION, CANDY_DC]
#^ The View menu's name for each look:
const LOOK_LABELS := {
	DOCUMENTATION: "The Documentation's Look",  #/ translatable
	CANDY_DC: "Candy DC's Look",  #/ translatable
}
const LOOK_TOOLTIPS := {
	DOCUMENTATION: "Each documentation as its authors styled it.",  #/ translatable
	CANDY_DC: "Everything follows the theme of Settings > Theme.",  #/ translatable
}
const DEFAULT_LOOK := DOCUMENTATION

const TEXTURE_MODES: Array[String] = ["Cover", "Stretch", "Tile"]
const COLOR_KEYS: Array[String] = ["background_color", "text_color", "link_color", "code_color", "header_background_color", "header_text_color", "footer_background_color", "footer_text_color"]
#^ The page's scroll bar colors (transparent = made from the text color, see CandyDocsPage):
const SCROLL_BAR_COLOR_KEYS: Array[String] = ["scroll_bar_color", "scroll_grabber_color", "scroll_grabber_hover_color", "scroll_grabber_pressed_color"]
const SCROLL_BAR_WIDTH := 10
const SCROLL_BAR_RADIUS := 4
#^ The page list's second page color, in the documentation's look, when its theme gives none:
const SECOND_PAGE_COLOR := Color(0.88, 0.52, 0.18)
#^ How much of the accent color marks the second page, in Candy DC's look:
const SECOND_PAGE_ALPHA := 0.35
#^ WCAG contrast colored text gets with the page, in Candy DC's look:
const CONTRAST := 4.5
#^ The page when the theme has no flat color to read:
const FALLBACK_DARK := Color(0.12, 0.13, 0.16)
const FALLBACK_LIGHT := Color(0.98, 0.98, 0.98)

#^ Each Godot editor color ("editor:<name>") as a key of candy_style():
const EDITOR_COLORS := {
	"font_color": "text_color",
	"accent_color": "link_color",
	"base_color": "background_color",
	"dark_color_1": "background_color",
	"dark_color_2": "background_color",
	"dark_color_3": "background_color",
	"success_color": "code_color",
	"warning_color": "code_color",
}

#^ Theme type of the view's icon colors, when a documentation's theme gives them:
#? button_icon, tree_icon, tree_arrow.
const COLORS := &"CandyDocs"

const BUTTON_TYPES: Array[String] = ["Button", "OptionButton", "MenuButton"]
const TEXT_TYPES: Array[String] = ["Button", "OptionButton", "MenuButton", "CheckBox", "Label", "LineEdit", "Tree", "ItemList", "PopupMenu"]

static var _font_cache: Dictionary = {}
static var _icon_cache: Dictionary = {}


#& Candy DC's look

#* Get the page's colors from Candy DC's theme:
#? control: one themed by Candy DC, not a documentation.
static func candy_style(control: Control) -> Dictionary:
	var text := control.get_theme_color(&"default_color", &"RichTextLabel")
	var background := _flat_color(control, &"normal", &"TextEdit")
	if background.a == 0.0:
		background = _flat_color(control, &"panel", &"Tree")
	if background.a == 0.0:
		background = FALLBACK_LIGHT
		if text.get_luminance() > 0.5:
			background = FALLBACK_DARK
	background.a = 1.0
	var accent := _type_color(control, &"font_color", CandyThemeDefaults.HIGHLIGHT, text)
	var code := _type_color(control, &"font_color", CandyThemeDefaults.WARNING, text)
	return {
		"background_color": background,
		"text_color": text,
		"link_color": CandyBBCodeEdit.contrasting(accent, background, CONTRAST),
		"code_color": CandyBBCodeEdit.contrasting(code, background, CONTRAST),
		"accent_color": accent,
	}


#* Get a flat stylebox's color (transparent if not flat):
static func _flat_color(control: Control, style_name: StringName, type_name: StringName) -> Color:
	var box := control.get_theme_stylebox(style_name, type_name) as StyleBoxFlat
	if box == null:
		return Color.TRANSPARENT
	return box.bg_color


#* Get a Candy variation's color, or fallback:
static func _type_color(control: Control, color_name: StringName, type_name: StringName, fallback: Color) -> Color:
	if control.has_theme_color(color_name, type_name):
		return control.get_theme_color(color_name, type_name)
	return fallback


#& Documentation themes

#* List every documentation theme ({ "title", "style", "theme" }), by id:
static func themes() -> Dictionary:
	var found: Dictionary = {}
	for folder: String in [CandyDocs.BUILTIN_THEMES_FOLDER, CandyDocs.USER_THEMES_FOLDER]:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		for file_name in DirAccess.get_files_at(folder):
			if file_name.get_extension().to_lower() != "json":
				continue
			var data := CandyDocsLibrary.read_json(folder.path_join(file_name))
			if not data.is_empty():
				found[file_name.get_basename()] = data
	return found


#* Get the theme a database names, or an empty one:
static func named_theme(database: Dictionary) -> Dictionary:
	if database.is_empty():
		return {}
	var found: Variant = themes().get(str(database["theme_name"]), {})
	if found is Dictionary:
		return found
	return {}


#* Get a database's `theme` block in the documentation's look (named theme, its own over it):
static func _theme_block(database: Dictionary) -> Dictionary:
	var merged: Dictionary = {}
	var named := named_theme(database)
	if named.get("theme") is Dictionary:
		merged = named["theme"].duplicate()
	if not database.is_empty():
		merged.merge(database["theme"], true)
	return merged


#& The page

#* Get the colors and background to show a database's pages with:
static func resolve_style(database: Dictionary, look: String, control: Control) -> Dictionary:
	var candy := candy_style(control)
	var style := {
		"background_color": candy["background_color"],
		"text_color": candy["text_color"],
		"link_color": candy["link_color"],
		"code_color": candy["code_color"],
		"header_background_color": Color.TRANSPARENT,
		"header_text_color": Color.TRANSPARENT,			#/ Transparent: the page's
		"footer_background_color": Color.TRANSPARENT,
		"footer_text_color": Color.TRANSPARENT,
		"texture_path": "",
		"texture_mode": "Cover",
		"header_texture_path": "",
		"header_texture_mode": "Cover",
		"footer_texture_path": "",
		"footer_texture_mode": "Cover",
		"opacity": 1.0,
		"own_scroll_bar": false,			#/ Scroll bar drawn from SCROLL_BAR_COLOR_KEYS, scroll_bar_width and scroll_bar_radius, not Candy DC's
		"own_text": false,			#/ Text colors are the documentation's (no Candy DC text outline)
		"scroll_bar_width": SCROLL_BAR_WIDTH,
		"scroll_bar_radius": SCROLL_BAR_RADIUS,
	}
	for key in SCROLL_BAR_COLOR_KEYS:
		style[key] = Color.TRANSPARENT
	if look == DOCUMENTATION and not database.is_empty():
		var theme_style: Dictionary = {}
		var named := named_theme(database)
		if named.get("style") is Dictionary:
			theme_style = named["style"]
		var own: Dictionary = database["style"]
		for source: Dictionary in [theme_style, own]:
			_apply_colors(style, source, candy)
			_apply_scroll_bar(style, source, candy)
		style["own_scroll_bar"] = not theme_style.is_empty() or not own.is_empty()
		style["own_text"] = style["own_scroll_bar"]
		var database_path := str(database["path"])
		style["texture_path"] = _inside(str(own.get("background_texture", "")), database_path)
		var mode := str(own.get("background_texture_mode", ""))
		if TEXTURE_MODES.has(mode):
			style["texture_mode"] = mode
		for band in ["header", "footer"]:
			style[band + "_texture_path"] = _inside(str(own.get(band + "_background_texture", "")), database_path)
			var band_mode := str(own.get(band + "_background_mode", ""))
			if TEXTURE_MODES.has(band_mode):
				style[band + "_texture_mode"] = band_mode
		var opacity := str(own.get("background_opacity", ""))
		if opacity.is_valid_float():
			style["opacity"] = clampf(float(opacity), 0.0, 1.0)
	style["texture"] = CandyDocsLibrary.load_texture(str(style["texture_path"]))			#/ Texture2D or null
	style["header_texture"] = CandyDocsLibrary.load_texture(str(style["header_texture_path"]))			#/ Texture2D or null
	style["footer_texture"] = CandyDocsLibrary.load_texture(str(style["footer_texture_path"]))			#/ Texture2D or null
	return style


static func _apply_colors(style: Dictionary, source: Dictionary, candy: Dictionary) -> void:
	for key in COLOR_KEYS:
		var text := str(source.get(key, ""))
		if not text.is_empty():
			style[key] = parse_color(text, style[key], candy)


static func _apply_scroll_bar(style: Dictionary, source: Dictionary, candy: Dictionary) -> void:
	for key in SCROLL_BAR_COLOR_KEYS:
		var text := str(source.get(key, ""))
		if not text.is_empty():
			style[key] = parse_color(text, style[key], candy)
	var width := str(source.get("scroll_bar_width", ""))
	if width.is_valid_int():
		style["scroll_bar_width"] = clampi(int(width), 2, 32)
	var radius := str(source.get("scroll_bar_radius", ""))
	if radius.is_valid_int():
		style["scroll_bar_radius"] = clampi(int(radius), 0, 16)


#* Get a database's file path, if inside its folder ("" otherwise):
static func _inside(file_path: String, database_path: String) -> String:
	if file_path.is_empty() or database_path.is_empty():
		return ""
	var resolved := database_path.path_join(file_path).simplify_path()
	if not CandyDocsLibrary.is_inside(resolved, database_path) or not FileAccess.file_exists(resolved):
		return ""
	return resolved


#* Parse a theme or database color ("#rrggbb", a name, or "editor:<name>"):
static func parse_color(text: String, fallback: Color, candy: Dictionary) -> Color:
	if text.begins_with("editor:"):
		var key := str(EDITOR_COLORS.get(text.substr(7), ""))
		if candy.has(key):
			return candy[key]
		return fallback
	return Color.from_string(text, fallback)


#* Get a database tag's color on a page:
static func tag_color(tag: Dictionary, style: Dictionary, look: String) -> Color:
	var background: Color = style["background_color"]
	var text := str(tag.get("color", ""))
	if background.get_luminance() < 0.5 and not str(tag.get("dark_color", "")).is_empty():
		text = str(tag["dark_color"])
	if text.is_empty():
		return Color.TRANSPARENT
	var color := Color.from_string(text, Color.TRANSPARENT)
	if color.a > 0.0 and look == CANDY_DC:
		color = CandyBBCodeEdit.contrasting(color, background, CONTRAST)
	return color


#* Get the page list's second page color:
static func second_page_color(database: Dictionary, look: String, control: Control) -> Color:
	var candy := candy_style(control)
	if look != DOCUMENTATION or database.is_empty():
		return Color(candy["accent_color"], SECOND_PAGE_ALPHA)
	var text := str(_theme_block(database).get("second_page_color", ""))
	if text.is_empty():
		return SECOND_PAGE_COLOR
	return parse_color(text, SECOND_PAGE_COLOR, candy)


#* Get black or white, whichever reads on color:
static func contrast_color(color: Color) -> Color:
	if color.get_luminance() > 0.5:
		return Color(0.05, 0.05, 0.05)
	return Color(0.97, 0.97, 0.97)


#& The controls around the page

#* Get the Theme for the view's content in the documentation's look:
static func resolve_theme(database: Dictionary, look: String, control: Control) -> Theme:
	if look != DOCUMENTATION or database.is_empty():
		return null			#/ Candy DC's theme
	var block := _theme_block(database)
	if block.is_empty():
		return null			#/ Nothing asked: Candy DC's theme
	return build_theme(block, str(database["path"]), candy_style(control))


#* Build a Theme from a `theme` block:
#? What it leaves out is Candy DC's.
static func build_theme(own: Dictionary, base_path: String, candy: Dictionary) -> Theme:
	var theme := Theme.new()
	theme.set_type_variation(CandyThemeDefaults.DOCS_SIDEBAR, &"PanelContainer")
	theme.set_type_variation(CandyThemeDefaults.DOCS_TOOLBAR, &"PanelContainer")
	var accent := _own_color(own, "accent_color", candy)
	var text := _own_color(own, "text_color", candy)
	var button := _own_color(own, "button_color", candy)
	var hover := _own_color(own, "hover_color", candy)
	var pressed := _own_color(own, "pressed_color", candy)
	var field := _own_color(own, "field_color", candy)
	var border := _own_color(own, "border_color", candy)
	var sidebar := _own_color(own, "sidebar_color", candy)
	var toolbar := _own_color(own, "toolbar_color", candy)			#/ The bar over a page
	var list_color := _own_color(own, "list_color", candy)			#/ The page list
	var icon_color := _own_color(own, "icon_color", candy)			#/ The bars' icons
	var list_icon_color := _own_color(own, "list_icon_color", candy)			#/ The page list's icons
	var arrow_color := _own_color(own, "arrow_color", candy)			#/ Its fold arrows; list_icon_color when left out
	var border_width := 0
	if str(own.get("border_width", "")).is_valid_int():
		border_width = clampi(int(own["border_width"]), 0, 4)
	var radius := 3
	if str(own.get("corner_radius", "")).is_valid_int():
		radius = clampi(int(own["corner_radius"]), 0, 16)
	if border.a == 0.0:
		border_width = 0
	if sidebar.a > 0.0:
		theme.set_stylebox("panel", CandyThemeDefaults.DOCS_SIDEBAR, _box(sidebar, 6, 6, 0))
	if toolbar.a > 0.0:
		theme.set_stylebox("panel", CandyThemeDefaults.DOCS_TOOLBAR, _box(toolbar, 6, 3, 0))
	#Ł Menus and tooltips need their own panel, or their text has the wrong background:
	var popup_color := field
	for candidate: Color in [sidebar, toolbar, button]:
		if popup_color.a == 0.0:
			popup_color = candidate
	if popup_color.a > 0.0:
		theme.set_stylebox("panel", "PopupMenu", _box(popup_color, 4, 4, radius, border, border_width))
		theme.set_stylebox("panel", "PopupPanel", _box(popup_color, 8, 8, radius, border, border_width))
		theme.set_stylebox("panel", "TooltipPanel", _box(popup_color, 4, 2, mini(radius, 4), border, mini(border_width, 1)))
	var tree_color := list_color
	if tree_color.a == 0.0:
		tree_color = sidebar
	if tree_color.a == 0.0:
		tree_color = field
	if tree_color.a > 0.0:
		theme.set_stylebox("panel", "Tree", _box(tree_color, 4, 4, radius, border, border_width))
		theme.set_stylebox("focus", "Tree", StyleBoxEmpty.new())
	if field.a > 0.0:
		theme.set_stylebox("normal", "LineEdit", _box(field, 6, 4, radius, border, border_width))
		theme.set_stylebox("focus", "LineEdit", _box(field.lightened(0.1), 6, 4, radius, border, border_width))
	if button.a > 0.0:
		if hover.a == 0.0:
			hover = button.lightened(0.15)
		if pressed.a == 0.0:
			pressed = accent
		if pressed.a == 0.0:
			pressed = button.darkened(0.2)
		for type in BUTTON_TYPES:
			theme.set_stylebox("normal", type, _box(button, 6, 4, radius, border, border_width))
			theme.set_stylebox("hover", type, _box(hover, 6, 4, radius, border, border_width))
			theme.set_stylebox("pressed", type, _box(pressed, 6, 4, radius, border, border_width))
			theme.set_stylebox("hover_pressed", type, _box(pressed.lightened(0.1), 6, 4, radius, border, border_width))
			theme.set_stylebox("disabled", type, _box(Color(button, 0.5), 6, 4, radius, border, border_width))
			theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	if accent.a > 0.0:
		var on_accent := contrast_color(accent)
		theme.set_stylebox("selected", "Tree", _box(accent, 2, 2, 2))
		theme.set_stylebox("selected_focus", "Tree", _box(accent, 2, 2, 2))
		theme.set_color("font_selected_color", "Tree", on_accent)
		theme.set_stylebox("hover", "PopupMenu", _box(accent, 2, 2, 2))
		theme.set_color("font_hover_color", "PopupMenu", on_accent)
	if pressed.a > 0.0:
		var on_pressed := contrast_color(pressed)
		for type in BUTTON_TYPES:
			theme.set_color("font_pressed_color", type, on_pressed)
			theme.set_color("font_hover_pressed_color", type, on_pressed)
	if text.a > 0.0:
		for type in TEXT_TYPES:
			theme.set_color("font_color", type, text)
			#? Candy DC's text outline is made for its own colors.
			theme.set_constant("outline_size", type, 0)
		for type in BUTTON_TYPES:
			theme.set_color("font_hover_color", type, text)
			theme.set_color("font_focus_color", type, text)
		theme.set_color("font_hovered_color", "Tree", text)
		theme.set_color("font_placeholder_color", "LineEdit", Color(text, 0.5))
		theme.set_color("caret_color", "LineEdit", text)
		theme.set_color("clear_button_color", "LineEdit", text)
		#Ł Inner scroll bars (the page list's): Candy DC's are made for its backgrounds:
		for type in ["VScrollBar", "HScrollBar"]:
			theme.set_stylebox("scroll", type, _box(Color(text, 0.08), 4, 4, radius))
			theme.set_stylebox("scroll_focus", type, _box(Color(text, 0.08), 4, 4, radius))
			theme.set_stylebox("grabber", type, _box(Color(text, 0.35), 4, 4, radius))
			theme.set_stylebox("grabber_highlight", type, _box(Color(text, 0.5), 4, 4, radius))
			theme.set_stylebox("grabber_pressed", type, _box(Color(text, 0.65), 4, 4, radius))
	#Ł Drop-down arrows, which Candy DC's theme draws in its Icons color:
	var arrow_on_button := icon_color
	if arrow_on_button.a == 0.0:
		arrow_on_button = text
	if arrow_on_button.a > 0.0:
		var arrow := recolored(&"OptionButton", &"arrow", arrow_on_button)
		if arrow != null:
			theme.set_icon("arrow", "OptionButton", arrow)
	#Ł The view's icon colors:
	if icon_color.a > 0.0:
		theme.set_color("button_icon", COLORS, icon_color)
	if list_icon_color.a > 0.0:
		theme.set_color("tree_icon", COLORS, list_icon_color)
	if arrow_color.a > 0.0:
		theme.set_color("tree_arrow", COLORS, arrow_color)
	var font := _load_font(str(own.get("font", "")), base_path)			#/ Font files are inside base_path
	if font != null:
		for type in TEXT_TYPES:
			theme.set_font("font", type, font)
		theme.set_font("normal_font", "RichTextLabel", font)
	var bold_font := _load_font(str(own.get("bold_font", "")), base_path)
	if bold_font != null:
		theme.set_font("bold_font", "RichTextLabel", bold_font)
	var own_mono_font := _load_font(str(own.get("mono_font", "")), base_path)
	if own_mono_font != null:
		theme.set_font("mono_font", "RichTextLabel", own_mono_font)
	var font_size := str(own.get("font_size", ""))
	if font_size.is_valid_int():
		for type in TEXT_TYPES:
			theme.set_font_size("font_size", type, clampi(int(font_size), 8, 40))
	return theme


#* Get a theme block's color for key (transparent if none):
static func _own_color(own: Dictionary, key: String, candy: Dictionary) -> Color:
	return parse_color(str(own.get(key, "")), Color.TRANSPARENT, candy)


static func _box(color: Color, margin_x := 6, margin_y := 4, radius := 3, border := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if border_width > 0:
		box.border_color = border
		box.set_border_width_all(border_width)
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = margin_y
	box.content_margin_bottom = margin_y
	return box


#* Get a Godot (or CandyIcons) icon recolored (null if no such icon):
static func recolored(type_name: StringName, icon_name: StringName, color: Color) -> Texture2D:
	var key := "%s/%s/%s" % [type_name, icon_name, color.to_html()]
	if _icon_cache.has(key):
		return _icon_cache[key]
	var source := CandyThemeDefaults.default_icon(type_name, icon_name)
	if source == null or source.get_image() == null:
		return source
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, Color(color, image.get_pixel(x, y).a * color.a))
	_icon_cache[key] = ImageTexture.create_from_image(image)
	return _icon_cache[key]


#* Get a system monospace font for [code] when the documentation brings none:
static func mono_font() -> Font:
	if not _font_cache.has("monospace"):
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(["monospace", "Consolas", "Menlo", "DejaVu Sans Mono", "Courier New"])
		_font_cache["monospace"] = system_font
	return CandyTheme.with_fallbacks(_font_cache["monospace"])


#* Load a font file inside the database folder, or null:
static func _load_font(font_path: String, base_path: String) -> Font:
	var resolved := _inside(font_path, base_path)
	if resolved.is_empty():
		return null
	if not _font_cache.has(resolved):
		var font := FontFile.new()
		if font.load_dynamic_font(resolved) != OK:
			return null
		_font_cache[resolved] = font
	return CandyTheme.with_fallbacks(_font_cache[resolved])

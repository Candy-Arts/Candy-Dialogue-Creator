#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyThemeDefaults

const BACKGROUND := &"CandyBackground"
const PANEL_FRAME := &"CandyPanelFrame"
const WIDGET_FRAME := &"CandyWidgetFrame"
const LIST_BOX := &"CandyListBox"
const TAG_BOX := &"CandyTagBox"
const SETTINGS_LIST := &"CandySettingsList"
const WIDGET_LIST := &"CandyWidgetList"
const NOTE := &"CandyNote"
const ERROR := &"CandyError"
const WARNING := &"CandyWarning"
const HIGHLIGHT := &"CandyHighlight"
const SECTION_TITLE := &"CandySectionTitle"
const EDITOR_TITLE := &"CandyEditorTitle"
const BREADCRUMB := &"CandyBreadcrumb"
const CARD_TITLE := &"CandyCardTitle"
const APP_TITLE := &"CandyAppTitle"
const COUNTER := &"CandyCounter"
const COMPACT_VBOX := &"CandyCompactVBox"
const COMPACT_HBOX := &"CandyCompactHBox"
const FLUSH_VBOX := &"CandyFlushVBox"
const FLUSH_HBOX := &"CandyFlushHBox"
const ROOMY_VBOX := &"CandyRoomyVBox"
const ROOMY_HBOX := &"CandyRoomyHBox"
const ROOMY_GRID := &"CandyRoomyGrid"
const INDENT := &"CandyIndent"
const PANEL_MARGIN := &"CandyPanelMargin"
const PAGE_MARGIN := &"CandyPageMargin"
const SCROLL_GAP := &"CandyScrollGap"
const SPEECH_EDITOR := &"CandySpeechEditor"
const ADVANCED_SPEECH_EDITOR := &"CandyAdvancedSpeechEditor"
const TAG_POPUP := &"CandyTagPopup"
const TAG_POPUP_EDIT := &"CandyTagPopupEdit"
const LOCKED_LINE_EDIT := &"CandyLockedLineEdit"
const LOCKED_TEXT_EDIT := &"CandyLockedTextEdit"
const SPEECH_VIEWER := &"CandySpeechViewer"
const NEWS := &"CandyNews"
const FLAT_BUTTON := &"CandyFlatButton"
const FLAT_OPTION_BUTTON := &"CandyFlatOptionButton"
const FLAT_MENU_BAR := &"CandyFlatMenuBar"
const FILTER_BUTTON := &"CandyFilterButton"
const EDITOR_TAB := &"CandyEditorTab"
const HELP_BUTTON := &"CandyHelpButton"
#^ The + after the Dialogue Editor's tabs:
const EDITOR_TAB_ADD := &"CandyEditorTabAdd"
#^ Edit Layout mode's Area buttons over a layout, in window layouts and in the Dialogue Editor:
const AREA_BUTTON_WINDOW := &"CandyAreaButtonWindow"
const AREA_BUTTON_EDITOR := &"CandyAreaButtonEditor"
const MEDIA_PREVIEW := &"CandyMediaPreview"
const DOCS_SIDEBAR := &"CandyDocsSidebar"
const DOCS_TOOLBAR := &"CandyDocsToolbar"
const DOCS_HEADER := &"CandyDocsHeader"
const DOCS_FOOTER := &"CandyDocsFooter"

#^ Text padding in the tag popup, inside the popup's own:
const TAG_POPUP_EDIT_MARGIN := 2.0
#^ Speech Viewer box padding:
const SPEECH_VIEWER_MARGIN := 4.0
#^ News box padding and border width:
const NEWS_MARGIN := 8.0
const NEWS_BORDER_WIDTH := 1
#^ Landing screen card titles:
#? Fixed: the landing screen shows before a profile (and its theme options) is open.
const CARD_TITLE_FONT_SIZE := 20
#^ Counters' text outline width (its color is a profile setting):
const COUNTER_OUTLINE_SIZE := 1
#^ UI text outline width, as insert buttons' (colors: Text page options):
const TEXT_OUTLINE_SIZE := 4
#^ Types the Text outline option colors:
#? The Speech Editor and Viewer, and the news, are left out.
const TEXT_OUTLINE_TYPES := [&"Label", &"Button", &"OptionButton", &"MenuButton", &"CheckBox",
	&"CheckButton", &"ColorPickerButton", &"MenuBar", &"LineEdit", &"TextEdit", &"Tree", &"ItemList",
	&"PopupMenu", &"TooltipLabel", &"ProgressBar", &"FoldableContainer", &"TabContainer", &"TabBar",
	&"RichTextLabel"]

const NAVIGATOR := &"CandyNavigator"
const AREA_SPLIT := &"CandyAreaSplit"
const AREA_HOST := &"CandyAreaHost"
const AREA_OUTLINE := &"CandyAreaOutline"
const TAB_STRIP := &"CandyTabStrip"
const ICONS := &"CandyIcons"

#^ CandyIcons icons taken from Godot's default theme: [icon, type]:
const ICON_SOURCES := {
	&"clear": [&"close", &"TabBar"],
	&"remove": [&"close", &"TabBar"],
	&"move_up": [&"up", &"SpinBox"],
	&"move_down": [&"down", &"SpinBox"],
}
#^ CandyIcons icons Godot lacks:
#? White on 16×16 like Godot's, so the Icons option tints them alike.
const ICON_SVGS := {
	#? Speaker with two sound waves
	&"volume": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M1.5 6h3l4-3.5v11l-4-3.5h-3z\" fill=\"#fff\"/><path d=\"M11 5.5a3.5 3.5 0 0 1 0 5M13 3.5a6.5 6.5 0 0 1 0 9\" fill=\"none\" stroke=\"#fff\" stroke-width=\"1.5\" stroke-linecap=\"round\"/></svg>",
	#? Fast-forward
	&"position": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M1.25 3.5v9L8 8zM8 3.5v9L14.75 8z\" fill=\"#fff\"/></svg>",
	#? Left and right arrow heads
	&"back": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M10 3 5 8l5 5\" fill=\"none\" stroke=\"#fff\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></svg>",
	&"forward": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M6 3l5 5-5 5\" fill=\"none\" stroke=\"#fff\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></svg>",
	#? Sheet with a folded corner
	&"page": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M3.5 1.75h5.5l3.5 3.5v9h-9z\" fill=\"none\" stroke=\"#fff\" stroke-width=\"1.5\" stroke-linejoin=\"round\"/><path d=\"M5.75 8.25h4.5M5.75 11h4.5\" fill=\"none\" stroke=\"#fff\" stroke-width=\"1.25\" stroke-linecap=\"round\"/></svg>",
	#? Folder
	&"folder": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><path d=\"M1.5 3h4.75l1.5 1.75h6.75v8.75h-13z\" fill=\"#fff\"/></svg>",
	#? Wireframe globe - a page on the web
	&"globe": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><g fill=\"none\" stroke=\"#fff\" stroke-width=\"1.25\"><circle cx=\"8\" cy=\"8\" r=\"6.5\"/><ellipse cx=\"8\" cy=\"8\" rx=\"2.75\" ry=\"6.5\"/><path d=\"M1.5 8h13M2.6 4.75h10.8M2.6 11.25h10.8\"/></g></svg>",
	#? Bulleted list - a pop-up of fields
	&"fields": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><g fill=\"#fff\"><circle cx=\"3\" cy=\"4\" r=\"1.4\"/><circle cx=\"3\" cy=\"8\" r=\"1.4\"/><circle cx=\"3\" cy=\"12\" r=\"1.4\"/></g><path d=\"M6.5 4h7M6.5 8h7M6.5 12h7\" fill=\"none\" stroke=\"#fff\" stroke-width=\"1.5\" stroke-linecap=\"round\"/></svg>",
	#? Exclamation mark - unread news
	&"unread": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\"><rect x=\"6.25\" y=\"1\" width=\"3.5\" height=\"9.5\" rx=\"1.75\" fill=\"#fff\"/><circle cx=\"8\" cy=\"13.5\" r=\"2\" fill=\"#fff\"/></svg>",
}
#^ ICON_SVGS, once drawn:
static var _svg_icons: Dictionary = {}

#^ Each variation and its base type:
const VARIATIONS := {
	BACKGROUND: &"Panel",
	PANEL_FRAME: &"PanelContainer",
	WIDGET_FRAME: &"PanelContainer",
	LIST_BOX: &"PanelContainer",
	TAG_BOX: &"PanelContainer",
	SETTINGS_LIST: &"ScrollContainer",
	WIDGET_LIST: &"ScrollContainer",
	NOTE: &"Label",
	ERROR: &"Label",
	WARNING: &"Label",
	HIGHLIGHT: &"Label",
	SECTION_TITLE: &"Label",
	EDITOR_TITLE: &"Label",
	BREADCRUMB: &"Label",
	CARD_TITLE: &"Label",
	APP_TITLE: &"Label",
	COUNTER: &"Label",
	COMPACT_VBOX: &"VBoxContainer",
	COMPACT_HBOX: &"HBoxContainer",
	FLUSH_VBOX: &"VBoxContainer",
	FLUSH_HBOX: &"HBoxContainer",
	ROOMY_VBOX: &"VBoxContainer",
	ROOMY_HBOX: &"HBoxContainer",
	ROOMY_GRID: &"GridContainer",
	INDENT: &"MarginContainer",
	PANEL_MARGIN: &"MarginContainer",
	PAGE_MARGIN: &"MarginContainer",
	SCROLL_GAP: &"MarginContainer",
	SPEECH_EDITOR: &"TextEdit",
	ADVANCED_SPEECH_EDITOR: &"TextEdit",
	TAG_POPUP: &"PopupPanel",
	TAG_POPUP_EDIT: &"TextEdit",
	LOCKED_LINE_EDIT: &"LineEdit",
	LOCKED_TEXT_EDIT: &"TextEdit",
	SPEECH_VIEWER: &"RichTextLabel",
	NEWS: &"RichTextLabel",
	FLAT_BUTTON: &"Button",
	FLAT_OPTION_BUTTON: &"OptionButton",
	FLAT_MENU_BAR: &"MenuBar",
	FILTER_BUTTON: &"Button",
	EDITOR_TAB: &"Button",
	HELP_BUTTON: &"Button",
	AREA_BUTTON_WINDOW: &"Button",
	AREA_BUTTON_EDITOR: &"Button",
	EDITOR_TAB_ADD: &"Button",
	MEDIA_PREVIEW: &"PopupPanel",
	DOCS_SIDEBAR: &"PanelContainer",
	DOCS_TOOLBAR: &"PanelContainer",
	DOCS_HEADER: &"PanelContainer",
	DOCS_FOOTER: &"PanelContainer",
}

#^ Items CandyFilterButton and CandyEditorTab take from the Button (see add_inverted()):
const INVERTED_STYLES := {&"normal": &"pressed", &"pressed": &"normal",
	&"hover": &"hover_pressed", &"hover_pressed": &"hover"}
const INVERTED_COLORS := {&"font_color": &"font_pressed_color", &"font_pressed_color": &"font_color",
	&"font_hover_color": &"font_hover_pressed_color", &"font_hover_pressed_color": &"font_hover_color",
	&"icon_normal_color": &"icon_pressed_color", &"icon_pressed_color": &"icon_normal_color",
	&"icon_hover_color": &"icon_hover_pressed_color", &"icon_hover_pressed_color": &"icon_hover_color"}

#^ CandyEditorTab's open tab styles, filled with open_tab:
const EDITOR_TAB_OPEN_STYLES := [&"pressed", &"hover_pressed"]

#^ Each Area button type and the CandyAreaOutline color it's filled with (see add_area_buttons()):
const AREA_BUTTON_FILLS := {AREA_BUTTON_WINDOW: &"window", AREA_BUTTON_EDITOR: &"editor"}
const AREA_BUTTON_STYLES := [&"normal", &"hover", &"pressed", &"hover_pressed"]
const AREA_BUTTON_FONT_COLORS := [&"font_color", &"font_hover_color", &"font_pressed_color",
	&"font_hover_pressed_color", &"font_focus_color"]
#^ The fill, lighter while hovered and darker while pressed; the border, darker still:
const AREA_BUTTON_HOVER_LIGHTEN := 0.25
const AREA_BUTTON_PRESSED_DARKEN := 0.15
const AREA_BUTTON_BORDER_DARKEN := 0.4
#^ Fill luminance above which the text is black rather than white:
const AREA_BUTTON_DARK_TEXT_ABOVE := 0.5

#^ CandyHelpButton's styleboxes, from the Button's (see add_round()):
const ROUND_STYLES := [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]
#^ Corner radius larger than any button:
#? StyleBoxFlat scales it down, so a square button becomes a circle.
const ROUND_RADIUS := 1024
#^ Corner segments for a smooth circle:
const ROUND_CORNER_DETAIL := 16
#^ Padding around the ?:
const HELP_BUTTON_MARGIN := 1.0


#^ Types Godot styles apart from their base type, which the options don't style:
#? Godot looks up base types in a theme before the next theme: a CheckBox would take
#? this theme's Button background instead of Godot's own empty one.
const OWN_STYLE_TYPES := [&"CheckBox", &"CheckButton", &"LinkButton"]

#^ Types whose focus outline is drawn on their border:
#? Godot's sits 2px outside, showing the border as a second outline.
const FOCUS_ON_BORDER_TYPES := [&"Button", &"OptionButton", &"MenuButton", &"ColorPickerButton",
	&"LineEdit", &"TextEdit", &"Tree", &"ItemList"]


#* Declare the variations and set the fixed values, on an empty theme:
static func add_structure(theme: Theme) -> void:
	for variation in VARIATIONS:
		theme.set_type_variation(variation, VARIATIONS[variation])
	theme.set_constant(&"separation", FLUSH_VBOX, 0)
	theme.set_constant(&"separation", FLUSH_HBOX, 0)
	theme.set_font_size(&"font_size", CARD_TITLE, CARD_TITLE_FONT_SIZE)
	theme.set_constant(&"outline_size", COUNTER, COUNTER_OUTLINE_SIZE)
	theme.set_color(&"font_outline_color", COUNTER, Color(0, 0, 0, 0))
	for type_name in TEXT_OUTLINE_TYPES:
		theme.set_constant(&"outline_size", type_name, TEXT_OUTLINE_SIZE)
	theme.set_constant(&"title_outline_size", &"Window", TEXT_OUTLINE_SIZE)
	for type_name in [SPEECH_EDITOR, SPEECH_VIEWER, NEWS, APP_TITLE]:
		theme.set_constant(&"outline_size", type_name, 0)
	theme.set_color(&"font_color", APP_TITLE, Color.BLACK)

	#Ł Box for the options to color (Godot's ScrollContainer panel is empty):
	theme.set_stylebox(&"panel", WIDGET_LIST, StyleBoxFlat.new())

	#Ł Plain box - the widget gives it its background color:
	var viewer_box := StyleBoxFlat.new()
	viewer_box.bg_color = Color.WHITE
	viewer_box.set_content_margin_all(SPEECH_VIEWER_MARGIN)
	theme.set_stylebox(&"normal", SPEECH_VIEWER, viewer_box)

	#Ł Flat -the popup is the box:
	var popup_edit_box := StyleBoxEmpty.new()
	popup_edit_box.set_content_margin_all(TAG_POPUP_EDIT_MARGIN)
	for style_name in [&"normal", &"focus", &"read_only"]:
		theme.set_stylebox(style_name, TAG_POPUP_EDIT, popup_edit_box)

	var news_box := StyleBoxFlat.new()
	news_box.bg_color = Color.WHITE
	news_box.border_color = Color.BLACK
	news_box.set_border_width_all(NEWS_BORDER_WIDTH)
	news_box.set_content_margin_all(NEWS_MARGIN)
	theme.set_stylebox(&"normal", NEWS, news_box)
	theme.set_color(&"default_color", NEWS, Color.BLACK)

	#Ł No box - only a documentation's own theme gives one:
	for type_name in [DOCS_SIDEBAR, DOCS_TOOLBAR, DOCS_HEADER, DOCS_FOOTER]:
		theme.set_stylebox(&"panel", type_name, StyleBoxEmpty.new())

	#Ł Untinted icons, for themes without an Icons color:
	for icon_name in ICON_SOURCES.keys() + ICON_SVGS.keys():
		var source := default_icon(ICONS, icon_name)
		if source != null:
			theme.set_icon(icon_name, ICONS, source)

	var fallback := ThemeDB.get_default_theme()
	for type_name in OWN_STYLE_TYPES:
		for style_name in fallback.get_stylebox_list(type_name):
			theme.set_stylebox(style_name, type_name, fallback.get_stylebox(style_name, type_name))

	for type_name in FOCUS_ON_BORDER_TYPES:
		if not fallback.has_stylebox(&"focus", type_name):
			continue
		var focus := fallback.get_stylebox(&"focus", type_name).duplicate() as StyleBoxFlat
		if focus == null:
			continue
		focus.set_expand_margin_all(0.0)
		theme.set_stylebox(&"focus", type_name, focus)


#* Give CandyFilterButton and CandyEditorTab the Button's looks, pressed and normal swapped:
#! Call once the rest of the theme is built.
static func add_inverted(theme: Theme) -> void:
	var fallback := ThemeDB.get_default_theme()
	for type_name: StringName in [FILTER_BUTTON, EDITOR_TAB]:
		for item in INVERTED_STYLES:
			#% Keep items the theme gives:
			if theme.has_stylebox(item, type_name):
				continue
			var source: StringName = INVERTED_STYLES[item]
			var style: StyleBox = null
			if theme.has_stylebox(source, &"Button"):
				style = theme.get_stylebox(source, &"Button")
			elif fallback.has_stylebox(source, &"Button"):
				style = fallback.get_stylebox(source, &"Button")
			if style == null:
				continue
			#% CandyEditorTab's open tab filled with open_tab, if set:
			if type_name == EDITOR_TAB and EDITOR_TAB_OPEN_STYLES.has(item) and theme.has_color(&"open_tab", EDITOR_TAB):
				var flat := style.duplicate() as StyleBoxFlat
				if flat != null:
					flat.bg_color = theme.get_color(&"open_tab", EDITOR_TAB)
					style = flat
			theme.set_stylebox(item, type_name, style)
		for item in INVERTED_COLORS:
			if theme.has_color(item, type_name):
				continue
			var source: StringName = INVERTED_COLORS[item]
			#% CandyEditorTab swaps backgrounds only (pressed text for the open tab):
			if type_name == EDITOR_TAB:
				source = item
			if theme.has_color(source, &"Button"):
				theme.set_color(item, type_name, theme.get_color(source, &"Button"))
			elif fallback.has_color(source, &"Button"):
				theme.set_color(item, type_name, fallback.get_color(source, &"Button"))


#* Give CandyHelpButton the Button's styleboxes, round with little padding:
#! Call once the rest of the theme is built.
static func add_round(theme: Theme) -> void:
	var fallback := ThemeDB.get_default_theme()
	for item in ROUND_STYLES:
		#% Keep styleboxes the theme gives:
		if theme.has_stylebox(item, HELP_BUTTON):
			continue
		var source: StyleBox = null
		if theme.has_stylebox(item, &"Button"):
			source = theme.get_stylebox(item, &"Button")
		elif fallback.has_stylebox(item, &"Button"):
			source = fallback.get_stylebox(item, &"Button")
		if source == null:
			continue
		var round_box := source.duplicate() as StyleBox
		round_box.set_content_margin_all(HELP_BUTTON_MARGIN)
		var flat := round_box as StyleBoxFlat
		if flat != null:
			flat.set_corner_radius_all(ROUND_RADIUS)
			flat.corner_detail = maxi(flat.corner_detail, ROUND_CORNER_DETAIL)
		theme.set_stylebox(item, HELP_BUTTON, round_box)


#* Give CandyEditorTabAdd the Button's look, its normal background CandyEditorTab's add_tab color:
#! Call once the rest of the theme is built.
static func add_tab_button(theme: Theme) -> void:
	if theme.has_stylebox(&"normal", EDITOR_TAB_ADD) or not theme.has_color(&"add_tab", EDITOR_TAB):
		return
	var source: StyleBox = null
	if theme.has_stylebox(&"normal", &"Button"):
		source = theme.get_stylebox(&"normal", &"Button")
	else:
		source = ThemeDB.get_default_theme().get_stylebox(&"normal", &"Button")
	var flat := source.duplicate() as StyleBoxFlat
	if flat == null:
		return
	flat.bg_color = theme.get_color(&"add_tab", EDITOR_TAB)
	theme.set_stylebox(&"normal", EDITOR_TAB_ADD, flat)


#* Give the Area buttons the Button's shape, filled with their frames' color:
#? So they stand out over the layout in every theme, with text that reads on the fill.
#! Call once the rest of the theme is built.
static func add_area_buttons(theme: Theme) -> void:
	var fallback := ThemeDB.get_default_theme()
	for type_name: StringName in AREA_BUTTON_FILLS:
		var fill_name: StringName = AREA_BUTTON_FILLS[type_name]
		if not theme.has_color(fill_name, AREA_OUTLINE):
			continue
		var fill := theme.get_color(fill_name, AREA_OUTLINE)

		#@ Step 1 - Styleboxes:
		for item in AREA_BUTTON_STYLES:
			#% Keep styleboxes the theme gives:
			if theme.has_stylebox(item, type_name):
				continue
			var source: StyleBox = null
			if theme.has_stylebox(item, &"Button"):
				source = theme.get_stylebox(item, &"Button")
			elif fallback.has_stylebox(item, &"Button"):
				source = fallback.get_stylebox(item, &"Button")
			var box := StyleBoxFlat.new()
			if source is StyleBoxFlat:
				box = source.duplicate() as StyleBoxFlat
			elif source != null:
				for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
					box.set_content_margin(side, source.get_content_margin(side))
			box.bg_color = _area_button_fill(fill, item)
			box.border_color = fill.darkened(AREA_BUTTON_BORDER_DARKEN)
			box.set_border_width_all(maxi(1, box.border_width_left))
			theme.set_stylebox(item, type_name, box)

		#@ Step 2 - Text, black or white, whichever reads on the fill:
		var text := Color.WHITE
		if fill.get_luminance() > AREA_BUTTON_DARK_TEXT_ABOVE:
			text = Color.BLACK
		for item in AREA_BUTTON_FONT_COLORS:
			if not theme.has_color(item, type_name):
				theme.set_color(item, type_name, text)
		#Ł No text outline (the Text outline option's), which would blur it:
		if not theme.has_constant(&"outline_size", type_name):
			theme.set_constant(&"outline_size", type_name, 0)


static func _area_button_fill(fill: Color, style_name: StringName) -> Color:
	match style_name:
		&"hover":
			return fill.lightened(AREA_BUTTON_HOVER_LIGHTEN)
		&"pressed", &"hover_pressed":
			return fill.darkened(AREA_BUTTON_PRESSED_DARKEN)
	return fill


#* An Area button type, for frames of a CandyAreaOutline color ("window" or "editor"):
static func area_button_type(color_name: StringName) -> StringName:
	for type_name: StringName in AREA_BUTTON_FILLS:
		if AREA_BUTTON_FILLS[type_name] == color_name:
			return type_name
	return AREA_BUTTON_WINDOW


#* Give RichTextLabel its fonts (normal, bold, italics), for its variations:
#! Call once the rest of the theme is built.
static func add_rich_text_fonts(theme: Theme) -> void:
	var fallback := ThemeDB.get_default_theme()
	var own: PackedStringArray = theme.get_font_list(&"RichTextLabel")
	for item in fallback.get_font_list(&"RichTextLabel"):
		#% Keep fonts the theme gives:
		if own.has(item):
			continue
		var font: Font = fallback.get_font(item, &"RichTextLabel")
		#% Made from the default font, if any:
		if theme.default_font != null:
			var variation := font as FontVariation
			if variation != null:
				var made := variation.duplicate() as FontVariation
				made.base_font = theme.default_font
				font = made
			else:
				font = theme.default_font
		theme.set_font(item, &"RichTextLabel", font)


#* RichTextLabel's normal, bold, italics and bold italics fonts made from font, as Godot's own theme makes them:
#? { item name: Font }. Bold and italics are font made bolder or slanted.
static func rich_text_fonts(font: Font) -> Dictionary:
	var fallback := ThemeDB.get_default_theme()
	var result := {}
	for item: StringName in [&"normal_font", &"bold_font", &"italics_font", &"bold_italics_font"]:
		var made: Font = font
		var variation := fallback.get_font(item, &"RichTextLabel") as FontVariation
		if variation != null:
			var copy := variation.duplicate() as FontVariation
			copy.base_font = font
			made = copy
		result[item] = made
	return result


#* Put the window background behind everything in parent (else the clear color shows through):
static func add_background(parent: Node) -> Panel:
	var background := Panel.new()
	background.name = "Background"
	background.theme_type_variation = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)
	parent.move_child(background, 0)
	return background


#* The base type of a Candy variation, or the type itself:
static func base_type(type_name: StringName) -> StringName:
	return VARIATIONS.get(type_name, type_name)


#* Godot's default icon for a type, or null:
static func default_icon(type_name: StringName, icon_name: StringName) -> Texture2D:
	var fallback := ThemeDB.get_default_theme()
	#? Variations use their base type.
	var source_type := base_type(type_name)
	var source_name := icon_name
	#% CandyIcons icons - their ICON_SVGS or ICON_SOURCES:
	if type_name == ICONS and ICON_SVGS.has(icon_name):
		return _svg_icon(icon_name)
	if type_name == ICONS:
		var source: Array = ICON_SOURCES.get(icon_name, [])
		if source.size() < 2:
			return null
		source_name = source[0]
		source_type = source[1]
	if not fallback.has_icon(source_name, source_type):
		return null
	return fallback.get_icon(source_name, source_type)


#* Draw an ICON_SVGS icon, once:
static func _svg_icon(icon_name: StringName) -> Texture2D:
	if _svg_icons.has(icon_name):
		return _svg_icons[icon_name]
	var image := Image.new()
	if image.load_svg_from_string(str(ICON_SVGS[icon_name])) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_svg_icons[icon_name] = texture
	return texture


#* A variation's stylebox, as a control of it inside `control` would get it:
static func variation_stylebox(control: Control, style_name: StringName, variation: StringName) -> StyleBox:
	if control.has_theme_stylebox(style_name, variation):
		return control.get_theme_stylebox(style_name, variation)
	#? A lookup by type name doesn't fall back to the base type.
	return control.get_theme_stylebox(style_name, base_type(variation))

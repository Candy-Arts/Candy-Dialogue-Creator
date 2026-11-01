#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorColors

const SETTING := "navigator_colors"
#^ Defaults under the setting (see the header):
const DEFAULTS_FILE := "res://Defaults/navigator_colors.txt"
#^ Row kinds that aren't commands, and their theme background color:
const HEADERS := ["conversation", "block"]
const HEADER_LABELS := {"conversation": "Conversations", "block": "Blocks"}	#/ translatable
const HEADER_BG := {"conversation": &"conversation_bg", "block": &"block_bg"}
#^ In Settings' order:
const STATES := ["normal", "hover", "pressed", "selected", "secondary"]
const STATE_LABELS := {
	"normal": "Normal",	#/ translatable
	"hover": "Hovered",	#/ translatable
	"selected": "Selected",	#/ translatable
	"pressed": "Clicked",	#/ translatable
	"secondary": "Also selected",	#/ translatable
}
const STATE_TOOLTIPS := {
	"normal": "How a line looks.",	#/ translatable
	"hover": "Under the mouse.",	#/ translatable
	"selected": "The line the Dialogue Editor shows.",	#/ translatable
	"pressed": "While it's being clicked.",	#/ translatable
	"secondary": "The other selected lines, when several are selected.",	#/ translatable
}
const KEYS := ["text", "outline", "bg", "border", "frame"]
const SIDES := ["left", "top", "right", "bottom"]
const SIDE_LABELS := {"left": "Left", "top": "Top", "right": "Right", "bottom": "Bottom"}	#/ translatable
const BORDER_WIDTH := 1
const MAX_BORDER_WIDTH := 16
const FRAME_WIDTH := 1
const MAX_FRAME_WIDTH := 8
const KEY_LABELS := {"text": "Text", "outline": "Text outline", "bg": "Background", "border": "Border",	#/ translatable
	"frame": "Frame (an outline around the row, outside the border)"}	#/ translatable
#^ Where each row kind's text starts, from its left edge:
#? Conversations and blocks: at least the fold arrow's width.
const TEXT_INDENT_KEY := "text_indent"
const INDENT_KINDS := ["conversation", "block", "line"]
const INDENT_LABELS := {"conversation": "Conversations", "block": "Blocks", "line": "Lines"}	#/ translatable
const DEFAULT_TEXT_INDENTS := {"conversation": 18, "block": 18, "line": 12}
const MAX_TEXT_INDENT := 64
#* What the user set, for the current theme:
static func user_colors() -> Dictionary:
	return CandyTheme.overrides_of(CandyProfiles.get_setting(SETTING, {}), CandyTheme.current_theme_id())


#^ Defaults entry under every row's own:
const ALL_ROWS := "all"
#^ Category of commands whose schema has none:
const NO_CATEGORY := "Other"	#/ translatable

const HOVER_LIGHTEN := 0.18
const PRESS_DARKEN := 0.22
const SECONDARY_OUTLINE_ALPHA := 0.5
#^ When a schema gives no colors:
const FALLBACK_TEXT := Color(0.9, 0.9, 0.9, 1)
const FALLBACK_BG := Color(0, 0, 0, 0.5)

#^ DEFAULTS_FILE, read once:
static var _defaults: Dictionary = {}
static var _defaults_read := false


#* A command's category:
static func category_of(type: String) -> String:
	var category := CandySchemas.get_category(type)
	if category == "":
		return NO_CATEGORY
	return category


#* Every category and its commands, sorted - { category = [type, ...] }:
static func categories() -> Dictionary:
	var result: Dictionary = {}
	var names: Array = []
	for type in CandySchemas.line_types():
		var category := category_of(type)
		if not result.has(category):
			result[category] = []
			names.append(category)
		result[category].append(type)
	names.sort_custom(func(a: String, b: String) -> bool:
		if (a == NO_CATEGORY) != (b == NO_CATEGORY):
			return b == NO_CATEGORY
		return a.naturalnocasecmp_to(b) < 0)
	var sorted: Dictionary = {}
	for category in names:
		sorted[category] = result[category]
	return sorted


#* The defaults (see the header):
static func defaults() -> Dictionary:
	var from_theme: Dictionary = CandyTheme.navigator_colors()
	if not from_theme.is_empty():
		return from_theme
	if not _defaults_read:
		_defaults = CandyVariantFile.read(DEFAULTS_FILE)
		_defaults_read = true
	return _defaults


#* Whether a command uses its category's colors:
static func uses_category(type: String, colors: Dictionary) -> bool:
	var command := _stored(colors, "commands", type)
	if command.has("use_category"):
		return bool(command["use_category"])
	return CandySchemas.get_colors(type).is_empty()


#* A command's colors in every state: { state: { key: Color } }:
#? colors: the user's colors.
static func for_command(type: String, colors: Dictionary, theme_source: Control) -> Dictionary:
	if uses_category(type, colors):
		return for_category(category_of(type), colors, theme_source)
	var stored := _stored(colors, "commands", type)
	return _resolve(_normal_from_schema(CandySchemas.get_colors(type), theme_source), stored, theme_source)


#* One line's colors, with its "navigator_text_field" color as text:
static func for_line(line: Dictionary, command_states: Dictionary) -> Dictionary:
	var type := CandyDialogue.line_type(line)
	var field := CandySchemas.get_navigator_text_field(type)
	if field == "":
		return command_states			#/ Unchanged: lines share it
	#? "Color(1, 0.5, 0, 1)" or "#ff8000".
	var value := str(CandyDialogue.line_data(line).get(field, "")).strip_edges()
	var text_color: Color
	var parsed = str_to_var(value)
	if parsed is Color:
		text_color = parsed
	elif Color.html_is_valid(value):
		text_color = Color.html(value)
	else:
		return command_states			#/ Unchanged: lines share it
	#Ł Only states showing Normal's text take the line's color:
	var normal_text = command_states.get("normal", {}).get("text")
	var states := command_states.duplicate(true)
	for state in STATES:
		if states.get(state) is Dictionary and states[state].get("text") == normal_text:
			states[state]["text"] = text_color
	return states


static func for_category(category: String, colors: Dictionary, theme_source: Control) -> Dictionary:
	var stored := _stored(colors, "categories", category)
	return _resolve(category_normal(category, theme_source), stored, theme_source)


#* A conversation or block row's colors in every state:
static func for_header(kind: String, colors: Dictionary, theme_source: Control) -> Dictionary:
	var normal := {
		"text": Color(0.92, 0.92, 0.95, 1),
		"outline": Color.TRANSPARENT,
		"bg": Color(0.2, 0.2, 0.25, 1),
		"border": Color.TRANSPARENT,
		"frame": Color.TRANSPARENT,
	}
	if theme_source != null:
		normal["text"] = theme_source.get_theme_color(&"header_text", CandyThemeDefaults.NAVIGATOR)
		normal["bg"] = theme_source.get_theme_color(HEADER_BG.get(kind, &"block_bg"), CandyThemeDefaults.NAVIGATOR)
	return _resolve(normal, _stored(colors, "", kind), theme_source)


#* Each row kind's text indent (setting, over the defaults, over DEFAULT_TEXT_INDENTS):
static func text_indents(colors: Dictionary) -> Dictionary:
	var stored := _over(_dict(defaults().get(TEXT_INDENT_KEY, {})), _dict(colors.get(TEXT_INDENT_KEY, {})))
	var result := {}
	for kind in INDENT_KINDS:
		var indent := int(stored.get(kind, DEFAULT_TEXT_INDENTS[kind]))
		result[kind] = clampi(indent, min_text_indent(kind), MAX_TEXT_INDENT)
	return result


#* A row kind's minimum indent (room for the fold arrow):
static func min_text_indent(kind: String) -> int:
	if kind == "line":
		return 0
	return int(CandyNavigatorRow.ARROW_WIDTH)


#* A category's normal colors: the pair most of its commands' schemas use:
static func category_normal(category: String, theme_source: Control) -> Dictionary:
	var counts: Dictionary = {}
	var best := ""
	var best_colors: Dictionary = {}
	for type in categories().get(category, []):
		var schema_colors := CandySchemas.get_colors(type)
		if schema_colors.is_empty():
			continue
		var key := var_to_str(schema_colors)
		counts[key] = int(counts.get(key, 0)) + 1
		if best == "" or counts[key] > counts[best]:
			best = key
			best_colors = schema_colors
	return _normal_from_schema(best_colors, theme_source)


#& Internals

#* What a row stores, over its defaults:
#? level: "commands", "categories", or "" for a conversation / block (row_name is then its kind).
static func _stored(colors: Dictionary, level: String, row_name: String) -> Dictionary:
	var base := defaults()
	var every_row := _dict(base.get(ALL_ROWS, {}))
	var top := colors
	if level != "":
		base = _dict(base.get(level, {}))
		top = _dict(top.get(level, {}))
	return _over(_over(every_row, _dict(base.get(row_name, {}))), _dict(top.get(row_name, {})))


#* Deep-merge top over base (neither is changed):
static func _over(base: Dictionary, top: Dictionary) -> Dictionary:
	if top.is_empty():
		return base
	var result := base.duplicate(true)
	for key in top:
		if result.get(key) is Dictionary and top[key] is Dictionary:
			result[key] = _over(result[key], top[key])
		else:
			result[key] = top[key]
	return result


static func _normal_from_schema(schema_colors: Dictionary, theme_source: Control) -> Dictionary:
	var bg := _color(schema_colors.get("BG"), FALLBACK_BG)
	if theme_source != null:
		var base := theme_source.get_theme_color(&"line_base", CandyThemeDefaults.NAVIGATOR)
		if base.a > 0.0:
			bg = base.blend(bg)
	return {
		"text": _color(schema_colors.get("Text"), FALLBACK_TEXT),
		"outline": Color.TRANSPARENT,
		"bg": bg,
		"border": Color.TRANSPARENT,
		"frame": Color.TRANSPARENT,
	}


#* Stored colors over the defaults, state by state:
static func _resolve(default_normal: Dictionary, stored: Dictionary, theme_source: Control) -> Dictionary:
	var normal := default_normal.duplicate()
	_apply_stored(normal, stored.get("normal", {}))

	var outline := Color(1, 1, 1, 0.85)
	if theme_source != null:
		outline = theme_source.get_theme_color(&"selected_outline", CandyThemeDefaults.NAVIGATOR)

	var result: Dictionary = {"normal": normal, "widths": _widths(stored.get("border_width", {})),
		"frame_width": _frame_width(stored.get("frame_width"))}
	for state in STATES:
		if state == "normal":
			continue
		#? Built on the resolved normal.
		var look := normal.duplicate()
		match state:
			"hover":
				look["bg"] = _lightened(normal["bg"], HOVER_LIGHTEN)
			"pressed":
				look["bg"] = normal["bg"].darkened(PRESS_DARKEN)
				look["frame"] = outline
			"selected":
				look["frame"] = outline
			"secondary":
				look["frame"] = Color(outline, outline.a * SECONDARY_OUTLINE_ALPHA)
		_apply_stored(look, stored.get(state, {}))
		result[state] = look
	return result


static func _widths(stored: Variant) -> Dictionary:
	var widths: Dictionary = {}
	for side in SIDES:
		widths[side] = BORDER_WIDTH
		if stored is Dictionary and stored.has(side):
			widths[side] = clampi(int(stored[side]), 0, MAX_BORDER_WIDTH)
	return widths


static func _frame_width(stored: Variant) -> int:
	if stored is int or stored is float:
		return clampi(int(stored), 0, MAX_FRAME_WIDTH)
	return FRAME_WIDTH


static func _apply_stored(look: Dictionary, stored: Variant) -> void:
	if not stored is Dictionary:
		return
	for key in KEYS:
		if stored.has(key):
			look[key] = _color(stored[key], look[key])


#* Lighten, and make more opaque, so hovering shows on see-through rows:
static func _lightened(color: Color, amount: float) -> Color:
	var lighter := color.lightened(amount)
	lighter.a = minf(1.0, color.a + (1.0 - color.a) * amount)
	return lighter


static func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


#* Read a color, as Color or string (hand-edited files):
static func _color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parsed = str_to_var(value)
		if parsed is Color:
			return parsed
	return fallback

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

#^ An insert was added, edited or deleted, or the files reloaded:
signal inserts_changed
#^ An insert was deleted (panels drop it from their state):
signal insert_deleted(id: String)

const TYPE_NATIVE := "native"
const TYPE_USER := "user"
const TYPE_PROFILE := "profile"

const USER_FILE := "user_inserts.txt"
const PROFILE_FILE := "profile_inserts.txt"

#^ The method other controls take inserts with:
const INSERT_METHOD := &"insert_around"

const BBCODE_CATEGORY := "BBCode"
const SYMBOLS_CATEGORY := "Symbols"

const KEY_ID := "Id"
const KEY_LEFT := "Before"
const KEY_MIDDLE := "Middle"
const KEY_RIGHT := "After"
const KEY_TEXT_COLOR := "Text Color"
const KEY_BACKGROUND_COLOR := "Background Color"
const KEY_TEXT_OUTLINE_COLOR := "Text Outline Color"
const KEY_BUTTON_OUTLINE_COLOR := "Button Outline Color"
const KNOWN_KEYS := [KEY_ID, KEY_LEFT, KEY_MIDDLE, KEY_RIGHT, KEY_TEXT_COLOR,
	KEY_BACKGROUND_COLOR, KEY_TEXT_OUTLINE_COLOR, KEY_BUTTON_OUTLINE_COLOR]

#^ id, category, label, left, right (categories are 1.1's BBCode button groups):
const BBCODE_INSERTS := [
	["native_bold", BBCODE_CATEGORY, "B", "[b]", "[/b]"],
	["native_italic", BBCODE_CATEGORY, "I", "[i]", "[/i]"],
	["native_underline", BBCODE_CATEGORY, "U", "[u]", "[/u]"],
	["native_strikethrough", BBCODE_CATEGORY, "S", "[s]", "[/s]"],

	["native_left", "BBCode Alignment", "☰⭰", "[left]", "[/left]"],
	["native_center", "BBCode Alignment", "Ξ", "[center]", "[/center]"],
	["native_right", "BBCode Alignment", "⭲☰", "[right]", "[/right]"],
	["native_fill", "BBCode Alignment", "☰", "[fill]", "[/fill]"],

	["native_color", "BBCode Colors", "Color", "[color=" + COLOR_TOKEN + "]", "[/color]"],
	["native_bg_color", "BBCode Colors", "BG Color", "[bgcolor=" + COLOR_TOKEN + "]", "[/bgcolor]"],
	["native_fg_color", "BBCode Colors", "FG Color", "[fgcolor=" + COLOR_TOKEN + "]", "[/fgcolor]"],
	["native_outline_color", "BBCode Colors", "OL Color", "[outline_color=" + COLOR_TOKEN + "]", "[/outline_color]"],

	["native_font", "BBCode Font", "Font", "[font=]", "[/font]"],
	["native_font_size", "BBCode Font", "Font Size", "[font_size=]", "[/font_size]"],
	["native_outline_size", "BBCode Font", "Outline Size", "[outline_size=]", "[/outline_size]"],

	["native_wave", "BBCode Effects", "Wave", "[wave]", "[/wave]"],
	["native_shake", "BBCode Effects", "Shake", "[shake]", "[/shake]"],
	["native_tornado", "BBCode Effects", "Tornado", "[tornado]", "[/tornado]"],
	["native_fade", "BBCode Effects", "Fade", "[fade]", "[/fade]"],
	["native_pulse", "BBCode Effects", "Pulse", "[pulse]", "[/pulse]"],
	["native_rainbow", "BBCode Effects", "Rainbow", "[rainbow]", "[/rainbow]"],

	["native_indent", "BBCode Formatting", "Indent", "[indent]", "[/indent]"],
	["native_paragraph", "BBCode Formatting", "Paragraph", "[p]", "[/p]"],
	["native_code", "BBCode Formatting", "Code", "[code]", "[/code]"],
	["native_break", "BBCode Formatting", "Break", "[br]", ""],
	["native_h_line", "BBCode Formatting", "H Line", "[hr]", ""],
	["native_char", "BBCode Formatting", "Char", "[char=]", ""],

	["native_lb", "BBCode Other", "[", "[lb]", ""],
	["native_rb", "BBCode Other", "]", "[rb]", ""],
	["native_u_list", "BBCode Other", "U List", "[ul]", "[/ul]"],
	["native_o_list", "BBCode Other", "O List", "[ol]", "[/ol]"],
	["native_table", "BBCode Other", "Table", "[table=]", "[/table]"],
	["native_cell", "BBCode Other", "Cell", "[cell]", "[/cell]"],

	["native_hint", "BBCode Data", "Hint", "[hint=]", "[/hint]"],
	["native_url", "BBCode Data", "URL", "[url=]", "[/url]"],
	["native_image", "BBCode Data", "Image", "[img=]", "[/img]"],
]
#^ The built-in inserts' categories and the BBCODE_INSERTS labels that are words, for the translation
#^ template (translated where shown):
const NATIVE_INSERT_WORDS := [
	"BBCode", "Symbols", "BBCode Alignment", "BBCode Colors", "BBCode Font", "BBCode Effects",	#/ translatable
	"BBCode Formatting", "BBCode Other", "BBCode Data",	#/ translatable
	"Color", "BG Color", "FG Color", "OL Color", "Font", "Font Size", "Outline Size",	#/ translatable
	"Wave", "Shake", "Tornado", "Fade", "Pulse", "Rainbow",	#/ translatable
	"Indent", "Paragraph", "Code", "Break", "H Line", "Char",	#/ translatable
	"U List", "O List", "Table", "Cell", "Hint", "URL", "Image",	#/ translatable
]

#^ Replaced by the linked Color Selector's color when typed:
const COLOR_TOKEN := "{color}"
#^ COLOR_TOKEN's color when no Color Selector has the reference:
const UNLINKED_COLOR := Color(1, 1, 1, 1)
#^ A new Inserts panel's reference, and the first a Color Selector tries:
const DEFAULT_REFERENCE := "1"

#^ id, then the "symbols" setting keys for left, middle and right ("" = empty):
const SYMBOL_INSERTS := [
	["native_expression", "expression", "", ""],
	["native_vardict", "vardict", "", ""],
	["native_role", "role", "", ""],
	["native_text_variable", "text_var_start", "", "text_var_end"],
	["native_substitution", "substitution_start", "separator", "substitution_end"],
	["native_text_event", "text_event_start", "", "text_event_end"],
	["native_lexicon_escape", "lexicon_escape_start", "", "lexicon_escape_end"],
]

var _inserts: Dictionary = {}   #/ id -> insert
var _order: Array = []          #/ ids: natives, then user, then profile, in file order
var _extra_keys: Dictionary = {}  #/ id -> file keys this version doesn't know
#^ Files that exist but couldn't be read, never written (a hand typo won't cost every insert):
var _unreadable: Dictionary = {}  #/ type -> true
var _loaded := false

#^ The last focused control taking inserts, in any window:
var _text_target: Control = null

#^ Color Selectors' colors: reference -> { "owner": instance id, "color": Color }:
var _reference_colors: Dictionary = {}


func _ready() -> void:
	CandyProfiles.profile_opened.connect(_on_profile_opened)
	CandyProfiles.profile_closed.connect(_on_profile_closed)
	CandyProfiles.settings_changed.connect(_on_setting_changed)

	#? Every window has its own focus owner.
	get_tree().root.gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)


#& Queries

func is_loaded() -> bool:
	return _loaded


func has_insert(id: String) -> bool:
	return _inserts.has(id)


#* Get a copy of an insert ({} if none):
func get_insert(id: String) -> Dictionary:
	if not _inserts.has(id):
		return {}
	return _inserts[id].duplicate()


func is_native(id: String) -> bool:
	return _inserts.has(id) and _inserts[id]["type"] == TYPE_NATIVE


func all_ids() -> Array:
	return _order.duplicate()


#* List category names in display order (natives first, then the files'):
func categories() -> Array:
	var result: Array = []
	for id in _order:
		var category := str(_inserts[id]["category"])
		if not result.has(category):
			result.append(category)
	return result


func ids_in_category(category: String) -> Array:
	var result: Array = []
	for id in _order:
		if _inserts[id]["category"] == category:
			result.append(id)
	return result


#* Check whether another insert of type uses label in category:
func label_taken(type: String, category: String, label: String, except_id: String = "") -> bool:
	for id in _order:
		if id == except_id:
			continue
		var insert: Dictionary = _inserts[id]
		if insert["type"] == type and insert["category"] == category and insert["label"] == label:			#/ Labels are the keys inside a category in the files
			return true
	return false


func file_path(type: String) -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	if type == TYPE_USER:
		return CandyProfiles.user_dir(CandyProfiles.current_user).path_join(USER_FILE)
	if type == TYPE_PROFILE:
		return CandyProfiles.current_profile_dir().path_join(PROFILE_FILE)
	return ""


func file_name(type: String) -> String:
	if type == TYPE_USER:
		return USER_FILE
	return PROFILE_FILE


#& Editing

#* Create an insert, or update the one data["id"] names:
func save_insert(data: Dictionary) -> String:
	if not _loaded:
		return CandyLocale.t("No project profile is open.")
	var type := str(data.get("type", TYPE_USER))
	if type != TYPE_USER and type != TYPE_PROFILE:
		return CandyLocale.t("Unknown insert type.")
	if _unreadable.has(type):
		return CandyLocale.t("%s couldn't be read, so it won't be overwritten. Fix or remove the file first.") % file_name(type)

	var id := str(data.get("id", ""))
	var previous_type := ""
	if id != "" and _inserts.has(id):
		if _inserts[id]["type"] == TYPE_NATIVE:
			return CandyLocale.t("Built-in inserts can't be edited.")
		previous_type = str(_inserts[id]["type"])
		if previous_type != type and _unreadable.has(previous_type):
			return CandyLocale.t("%s couldn't be read, so it won't be overwritten.") % file_name(previous_type)
	else:
		id = _new_id()

	var category := str(data.get("category", "")).strip_edges()
	var label := str(data.get("label", "")).strip_edges()
	if category == "":
		return CandyLocale.t("The category can't be empty.")
	if label == "":
		return CandyLocale.t("The label can't be empty.")
	if label_taken(type, category, label, id):
		return CandyLocale.t("{file} already has an insert called \"{label}\" in \"{category}\".").format(
			{"file": file_name(type), "label": label, "category": category})

	var insert := {
		"id": id,
		"type": type,
		"category": category,
		"label": label,
		"left": str(data.get("left", "")),
		"middle": str(data.get("middle", "")),
		"right": str(data.get("right", "")),
		"text_color": str(data.get("text_color", "")),
		"background_color": str(data.get("background_color", "")),
		"text_outline_color": str(data.get("text_outline_color", "")),
		"button_outline_color": str(data.get("button_outline_color", "")),
	}

	if _inserts.has(id) and previous_type == type:
		_inserts[id] = insert  #/ Keeps its place in the file
	else:
		if _inserts.has(id):
			_order.erase(id)
		_inserts[id] = insert
		_order.insert(_last_index_of_type(type) + 1, id)

	_write_file(type)
	if previous_type != "" and previous_type != type:
		_write_file(previous_type)
	inserts_changed.emit()
	return ""			#/ Success


func delete_insert(id: String) -> String:
	if not _inserts.has(id):
		return ""
	var type := str(_inserts[id]["type"])
	if type == TYPE_NATIVE:
		return CandyLocale.t("Built-in inserts can't be deleted.")
	if _unreadable.has(type):
		return CandyLocale.t("%s couldn't be read, so it won't be overwritten.") % file_name(type)
	_inserts.erase(id)
	_order.erase(id)
	_extra_keys.erase(id)
	_write_file(type)
	insert_deleted.emit(id)
	inserts_changed.emit()
	return ""


#& Typing inserts

#* Type an insert into the focused field (false if nowhere to type):
#? Wraps the selection (Middle, if set, replacing each space inside); without one, the caret ends between Left and Right.
func apply(id: String, reference: String = DEFAULT_REFERENCE) -> bool:
	if not _inserts.has(id):
		return false
	var insert: Dictionary = _inserts[id]
	var color := _color_code(reference)
	return apply_text(str(insert["left"]).replace(COLOR_TOKEN, color),
		str(insert["middle"]).replace(COLOR_TOKEN, color),
		str(insert["right"]).replace(COLOR_TOKEN, color))


#* Check whether an insert's text holds COLOR_TOKEN:
func uses_color(id: String) -> bool:
	if not _inserts.has(id):
		return false
	var insert: Dictionary = _inserts[id]
	for part in ["left", "middle", "right"]:
		if str(insert[part]).contains(COLOR_TOKEN):
			return true
	return false


#& Linked colors

#* Make selector (a Color Selector) the holder of reference, giving up its previous one:
func claim_color_reference(reference: String, selector: Object, color: Color) -> bool:
	if color_reference_taken(reference, selector):
		return false			#/ Another live Color Selector holds it
	release_color_reference(selector)
	_reference_colors[reference] = {"owner": selector.get_instance_id(), "color": color}
	return true


func release_color_reference(selector: Object) -> void:
	var owner_id := selector.get_instance_id()
	for reference in _reference_colors.keys():
		if int(_reference_colors[reference]["owner"]) == owner_id:
			_reference_colors.erase(reference)


#* Update the color a Color Selector publishes:
func set_reference_color(selector: Object, color: Color) -> void:
	var owner_id := selector.get_instance_id()
	for reference in _reference_colors:
		if int(_reference_colors[reference]["owner"]) == owner_id:
			_reference_colors[reference]["color"] = color


#* Check whether a live Color Selector other than except holds reference:
func color_reference_taken(reference: String, except: Object = null) -> bool:
	if not _reference_colors.has(reference):
		return false
	var owner_id := int(_reference_colors[reference]["owner"])
	if except != null and owner_id == except.get_instance_id():
		return false
	if not is_instance_id_valid(owner_id):
		_reference_colors.erase(reference)
		return false
	return true


#* Get the lowest numbered reference no other Color Selector holds:
func free_color_reference(selector: Object) -> String:
	var number := int(DEFAULT_REFERENCE)
	while color_reference_taken(str(number), selector):
		number += 1
	return str(number)


#* Get the color of reference's Color Selector, or null:
func reference_color(reference: String) -> Variant:
	if not color_reference_taken(reference):
		return null
	return _reference_colors[reference]["color"]


#* Get a reference's color as BBCode, "#ff8800" or "#ff880080":
func _color_code(reference: String) -> String:
	var color = reference_color(reference)
	if not color is Color:
		color = UNLINKED_COLOR
	return "#" + (color as Color).to_html(not is_equal_approx((color as Color).a, 1.0))


#* Type Left/Middle/Right text like an insert (for panels building it, the Color Selector):
func apply_text(left: String, middle: String, right: String) -> bool:
	return apply_text_to(_focused_text_control(), left, middle, right)


#* Get the control inserts would be typed into now, or null:
#? For controls opening a menu first (Speech Inserts widget): keep it before the menu opens,
#? then type with apply_text_to().
func text_target() -> Control:
	return _focused_text_control()


#* Type Left/Middle/Right text into target (false if null or gone):
func apply_text_to(target: Control, left: String, middle: String, right: String) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return false
	if target is LineEdit:
		_apply_to_line_edit(target as LineEdit, left, middle, right)
		return true
	if target is TextEdit:
		_apply_to_text_edit(target as TextEdit, left, middle, right)
		return true
	if target.has_method(INSERT_METHOD):
		target.call(INSERT_METHOD, left, middle, right)
		return true
	return false


func _focused_text_control() -> Control:
	if not is_instance_valid(_text_target):
		_text_target = null
		return null
	if not _text_target.is_inside_tree() or not _text_target.has_focus():
		return null
	if _text_target is LineEdit and not (_text_target as LineEdit).editable:
		return null
	if _text_target is TextEdit and not (_text_target as TextEdit).editable:
		return null
	if _text_target.get(&"editable") == false:
		return null
	return _text_target


func _wrap(selected: String, left: String, middle: String, right: String) -> String:
	var inner := selected
	if middle != "":
		inner = selected.replace(" ", middle)
	return left + inner + right


func _apply_to_line_edit(edit: LineEdit, left: String, middle: String, right: String) -> void:
	if edit.has_selection():
		var from := edit.get_selection_from_column()
		var to := edit.get_selection_to_column()
		var wrapped := _wrap(edit.text.substr(from, to - from), left, middle, right)
		edit.deselect()
		edit.delete_text(from, to)
		edit.caret_column = from
		edit.insert_text_at_caret(wrapped)
	else:
		edit.insert_text_at_caret(left)
		var caret := edit.caret_column
		edit.insert_text_at_caret(right)
		edit.caret_column = caret
	#? LineEdit only emits this for typing; listeners expect it on any edit.
	edit.text_changed.emit(edit.text)


func _apply_to_text_edit(edit: TextEdit, left: String, middle: String, right: String) -> void:
	edit.begin_complex_operation()  #/ One undo step
	edit.remove_secondary_carets()
	if edit.has_selection(0):
		var wrapped := _wrap(edit.get_selected_text(0), left, middle, right)
		edit.delete_selection(0)
		edit.insert_text_at_caret(wrapped, 0)
	else:
		edit.insert_text_at_caret(left, 0)
		var line := edit.get_caret_line(0)
		var column := edit.get_caret_column(0)
		edit.insert_text_at_caret(right, 0)
		edit.set_caret_line(line)
		edit.set_caret_column(column)
	edit.end_complex_operation()


func _on_node_added(node: Node) -> void:
	#? Popups (menus) never hold a text field worth typing into.
	if node is Window and not node is Popup:
		var window := node as Window
		if not window.gui_focus_changed.is_connected(_on_focus_changed):
			window.gui_focus_changed.connect(_on_focus_changed)


func _on_focus_changed(control: Control) -> void:
	if control is LineEdit or control is TextEdit or control.has_method(INSERT_METHOD):
		_text_target = control


#& Loading

func _on_profile_opened(_user: String, _profile: String) -> void:
	reload()


func _on_profile_closed() -> void:
	_inserts.clear()
	_order.clear()
	_extra_keys.clear()
	_unreadable.clear()
	_loaded = false
	inserts_changed.emit()


func _on_setting_changed(key: String) -> void:
	if key == "symbols" and _loaded:
		_add_symbol_inserts()
		inserts_changed.emit()


func reload() -> void:
	_inserts.clear()
	_order.clear()
	_extra_keys.clear()
	_unreadable.clear()
	_add_bbcode_inserts()
	_add_symbol_inserts()
	for type in [TYPE_USER, TYPE_PROFILE]:
		if _read_file(type):
			_write_file(type)  #/ Store the ids given to 1.1 inserts
	_loaded = true
	inserts_changed.emit()


func _add_bbcode_inserts() -> void:
	for entry in BBCODE_INSERTS:
		_add_native(str(entry[0]), str(entry[1]), str(entry[2]), str(entry[3]), "", str(entry[4]))


#* Add or refresh the symbol inserts (an existing id keeps its place):
func _add_symbol_inserts() -> void:
	var symbols = CandyProfiles.get_setting("symbols", {})
	if not symbols is Dictionary:
		symbols = {}
	for entry in SYMBOL_INSERTS:
		var left := _symbol(symbols, str(entry[1]))
		var middle := _symbol(symbols, str(entry[2]))
		var right := _symbol(symbols, str(entry[3]))
		var parts: Array = []
		for part in [left, middle, right]:
			if part != "":
				parts.append(part)
		var label := " ".join(parts)
		if label == "":
			label = CandyLocale.t("(no symbol set)")
		_add_native(str(entry[0]), SYMBOLS_CATEGORY, label, left, middle, right)


func _symbol(symbols: Dictionary, key: String) -> String:
	if key == "":
		return ""
	return str(symbols.get(key, ""))


func _add_native(id: String, category: String, label: String, left: String, middle: String, right: String) -> void:
	if not _order.has(id):
		_order.append(id)
	_inserts[id] = {
		"id": id,
		"type": TYPE_NATIVE,
		"category": category,
		"label": label,
		"left": left,
		"middle": middle,
		"right": right,
		"text_color": "",
		"background_color": "",
		"text_outline_color": "",
		"button_outline_color": "",
	}


#* Read an insert file:
func _read_file(type: String) -> bool:
	var path := file_path(type)
	if path == "" or not FileAccess.file_exists(path):
		return false
	var data = _parse(FileAccess.get_file_as_string(path))
	if data == null:
		_unreadable[type] = true
		push_warning("CandyInserts: can't read %s. It won't be overwritten." % path)
		return false

	var changed := false
	for category in data:
		var entries = data[category]
		if not entries is Dictionary:
			continue
		for label in entries:
			var entry = entries[label]
			if not entry is Dictionary:
				continue
			var id := str(entry.get(KEY_ID, ""))
			if id == "" or _inserts.has(id):
				id = _new_id()
				changed = true
			_inserts[id] = {
				"id": id,
				"type": type,
				"category": str(category),
				"label": str(label),
				"left": str(entry.get(KEY_LEFT, "")),
				"middle": str(entry.get(KEY_MIDDLE, "")),
				"right": str(entry.get(KEY_RIGHT, "")),
				"text_color": _color_string(entry.get(KEY_TEXT_COLOR, "")),
				"background_color": _color_string(entry.get(KEY_BACKGROUND_COLOR, "")),
				"text_outline_color": _color_string(entry.get(KEY_TEXT_OUTLINE_COLOR, "")),
				"button_outline_color": _color_string(entry.get(KEY_BUTTON_OUTLINE_COLOR, "")),
			}
			_order.append(id)
			var extra := {}
			for key in entry:
				if not KNOWN_KEYS.has(str(key)):
					extra[key] = entry[key]
			if not extra.is_empty():
				_extra_keys[id] = extra
	return changed			#/ Ids were given: the file should be saved


#* Parse an insert file, skipping its "#" header lines (neither parser accepts them):
func _parse(text: String) -> Variant:
	var body: PackedStringArray = []
	for line in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			body.append(line)
	var joined := "\n".join(body).strip_edges()
	if joined == "":
		return {}
	var data = str_to_var(joined)
	if data is Dictionary:
		return data
	data = JSON.parse_string(joined)
	if data is Dictionary:
		return data
	return null


func _color_string(value: Variant) -> String:
	if value is Color:
		return var_to_str(value)
	return str(value)


func _write_file(type: String) -> bool:
	var path := file_path(type)
	if path == "" or _unreadable.has(type):
		return false

	var data := {}
	for id in _order:
		var insert: Dictionary = _inserts[id]
		if insert["type"] != type:
			continue
		var category := str(insert["category"])
		if not data.has(category):
			data[category] = {}
		#Ł Before and After first; other keys only when set:
		var entry := {KEY_LEFT: insert["left"], KEY_RIGHT: insert["right"]}
		if insert["middle"] != "":
			entry[KEY_MIDDLE] = insert["middle"]
		if insert["text_color"] != "":
			entry[KEY_TEXT_COLOR] = insert["text_color"]
		if insert["background_color"] != "":
			entry[KEY_BACKGROUND_COLOR] = insert["background_color"]
		if insert["text_outline_color"] != "":
			entry[KEY_TEXT_OUTLINE_COLOR] = insert["text_outline_color"]
		if insert["button_outline_color"] != "":
			entry[KEY_BUTTON_OUTLINE_COLOR] = insert["button_outline_color"]
		if _extra_keys.has(id):
			for key in _extra_keys[id]:
				entry[key] = _extra_keys[id][key]
		entry[KEY_ID] = id
		data[category][insert["label"]] = entry

	var header: PackedStringArray = [
		"# Exported By: Candy Dialogue Creator",
		"# Creator Version: %s" % CandyProfiles.VERSION,
	]
	if type == TYPE_USER:
		header.append("# Type: User Inserts")
		header.append("# User: %s" % CandyProfiles.current_user)
	else:
		header.append("# Type: Profile Inserts")
		header.append("# User: %s" % CandyProfiles.current_user)
		header.append("# Profile: %s" % CandyProfiles.current_profile)

	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CandyInserts: can't write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string("\n".join(header) + "\n\n" + CandyVariantFile.stringify(data) + "\n")
	return true


func _last_index_of_type(type: String) -> int:
	var result := -1
	for i in _order.size():
		var insert_type := str(_inserts[_order[i]]["type"])
		if insert_type == type:
			result = i
		elif type == TYPE_USER and insert_type == TYPE_NATIVE:
			result = maxi(result, i)  #/ User inserts follow the natives
		elif type == TYPE_PROFILE and insert_type != TYPE_PROFILE:
			result = maxi(result, i)  #/ Profile inserts come last
	return result


func _new_id() -> String:
	var id := ""
	while id == "" or _inserts.has(id):
		id = "%x%08x" % [int(Time.get_unix_time_from_system()), randi()]
	return id
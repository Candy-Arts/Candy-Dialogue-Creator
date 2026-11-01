#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends SceneTree

#? Run: godot --headless --path . -s res://Tools/build_translation_template.gd
#! Never names a class whose script uses an autoload: a -s script compiles before they exist.

const OUTPUT := "res://Translations/candy_dc.pot"
const VERSION_SCRIPT := "res://Core/profiles.gd"
const LOCALE_SCRIPT := "res://Core/locale.gd"
#^ Folders left out of the scan:
const SKIPPED_FOLDERS := [".godot", ".Screenshots", "addons", "Tools"]
#^ The calls that translate, and the line marker for literals that can't be in a call:
const CALL_T := "CandyLocale.t("
const CALL_TN := "CandyLocale.tn("
const LINE_MARKER := "#/ translatable"
#^ Data files, and the keys whose text is shown (and translated where it's shown):
const DATA_FOLDERS := ["res://Line_Schemas", "res://Theme_Options"]
const DATA_FILES := ["res://Defaults/line_meta.txt"]
const TEXT_KEYS := ["title", "label", "tooltip", "values", "category", "category_tooltip", "text", "missing",
	"missing_path", "others", "modes_text", "empty", "empty_label", "none", "reference", "folder_label",
	"entry_label", "entry_type_hint", "entry_prefix", "no_default", "page", "section", "column"]
#^ The keys holding a field's checks, and the keys that hold values (not text) in a check's settings:
const CHECK_KEYS := ["checks", "entry_checks"]
const CHECK_VALUE_KEYS := ["values"]
#^ Scene properties CandyLocale.translate_scene() translates:
const SCENE_PROPERTIES := ["text", "tooltip_text", "placeholder_text"]

var _entries: Array = []          #/ { msgid, plural, context, refs: [] }, in order found
var _index: Dictionary = {}       #/ "context\u0004msgid" -> entry


func _init() -> void:
	_build.call_deferred()


func _build() -> void:
	#Ł The entry where a translation names its own language (CandyLocale.language_name()):
	var locale_constants: Dictionary = load(LOCALE_SCRIPT).get_script_constant_map()
	_add(locale_constants["LANGUAGE_NAME_TEXT"], "", locale_constants["LANGUAGE_NAME_CONTEXT"], LOCALE_SCRIPT.trim_prefix("res://"))
	_entries[0]["comment"] = "The name of your language, written in your language (Français, Deutsch, 日本語...). The Language setting lists it by this name."
	#@ Step 1 - Scripts:
	for path in _files_under("res://", ["gd"]):
		_scan_script(path)
	#@ Step 2 - Scenes:
	for path in _files_under("res://", ["tscn"]):
		_scan_scene(path)
	#@ Step 3 - Data files:
	var data_files: Array = DATA_FILES.duplicate()
	for folder: String in DATA_FOLDERS:
		data_files.append_array(_files_under(folder, ["txt"]))
	for path: String in data_files:
		var data: Variant = str_to_var(FileAccess.get_file_as_string(path))
		_scan_data(data, "", path.trim_prefix("res://"))
	#@ Step 4 - Godot's own texts:
	_scan_godot_texts()
	#@ Step 5 - Write:
	var error := _write()
	if error == OK:
		print("Translation template: %d texts written to %s." % [_entries.size(), OUTPUT])
	else:
		printerr("Translation template: couldn't write %s (%s)." % [OUTPUT, error_string(error)])
	quit()


#& Scripts

func _scan_script(path: String) -> void:
	var source := FileAccess.get_file_as_string(path)
	var ref := path.trim_prefix("res://")
	#Ł Calls:
	for call_text: String in [CALL_T, CALL_TN]:
		var from := 0
		while true:
			var at := source.find(call_text, from)
			if at == -1:
				break
			from = at + call_text.length()
			#% Examples in comments:
			var line_start := source.rfind("\n", at) + 1
			if _comment_start(source.substr(line_start, at - line_start)) != -1:
				continue
			var args := _call_arguments(source, from)
			var line := source.count("\n", 0, at) + 1
			_add_call(call_text, args, "%s:%d" % [ref, line])
	#Ł Marked lines:
	var lines := source.split("\n")
	for i in lines.size():
		var code := lines[i]
		var marker := _comment_start(code)
		if marker == -1 or not code.substr(marker).begins_with(LINE_MARKER):
			continue
		#Ł "#/ translatable: context" gives the literals a context:
		var context := ""
		var rest := code.substr(marker + LINE_MARKER.length()).strip_edges()
		if rest.begins_with(":"):
			context = rest.substr(1).strip_edges()
		for literal in _line_literals(code.left(marker)):
			_add(literal, "", context, "%s:%d" % [ref, i + 1])


#* Add the texts of a call, when its arguments are literals:
func _add_call(call_text: String, args: Array, ref: String) -> void:
	if args.is_empty():
		return
	var first: Variant = _literal(args[0])
	if first == null:
		return
	if call_text == CALL_T:
		var context := ""
		if args.size() > 1 and _literal(args[1]) != null:
			context = _literal(args[1])
		_add(first, "", context, ref)
		return
	if args.size() < 2 or _literal(args[1]) == null:
		return
	var plural_context := ""
	if args.size() > 3 and _literal(args[3]) != null:
		plural_context = _literal(args[3])
	_add(first, _literal(args[1]), plural_context, ref)


#* Split a call's arguments, from just after its "(" to its ")":
func _call_arguments(source: String, from: int) -> Array:
	var args: Array = []
	var depth := 0
	var start := from
	var i := from
	while i < source.length():
		var c := source[i]
		if c == "\"" or c == "'":
			i = _string_end(source, i)
			continue
		if c == "#":
			var line_end := source.find("\n", i)
			if line_end == -1:
				break
			i = line_end
			continue
		if c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			if depth == 0:
				args.append(source.substr(start, i - start).strip_edges())
				return args
			depth -= 1
		elif c == "," and depth == 0:
			args.append(source.substr(start, i - start).strip_edges())
			start = i + 1
		i += 1
	return args


#* The index just past the string literal starting at i:
func _string_end(source: String, i: int) -> int:
	var quote := source[i]
	var j := i + 1
	while j < source.length():
		if source[j] == "\\":
			j += 2
			continue
		if source[j] == quote:
			return j + 1
		j += 1
	return j


#* The value of an argument that is one plain string literal, or null:
func _literal(arg: String) -> Variant:
	if arg.length() < 2 or not arg.begins_with("\"") or _string_end(arg, 0) != arg.length():
		return null
	return _unescape(arg.substr(1, arg.length() - 2))


#* The plain literals of a line of code that aren't dictionary keys:
func _line_literals(code: String) -> Array:
	var found: Array = []
	var i := 0
	while i < code.length():
		var c := code[i]
		if c == "#":
			break
		if c == "\"":
			var end := _string_end(code, i)
			var prefixed := i > 0 and (code[i - 1] == "&" or code[i - 1] == "^" or code[i - 1] == "r")
			var is_key := code.substr(end).strip_edges().begins_with(":")
			if not prefixed and not is_key:
				var text := _unescape(code.substr(i + 1, end - i - 2))
				if _has_letters(text):
					found.append(text)
			i = end
			continue
		i += 1
	return found


#* Where a line's comment starts (its first # outside strings), or -1:
func _comment_start(code: String) -> int:
	var i := 0
	while i < code.length():
		if code[i] == "\"" or code[i] == "'":
			i = _string_end(code, i)
			continue
		if code[i] == "#":
			return i
		i += 1
	return -1


func _unescape(text: String) -> String:
	return text.c_unescape()


#& Scenes

#* The texts of a scene's nodes (text, tooltip_text, placeholder_text):
func _scan_scene(path: String) -> void:
	var source := FileAccess.get_file_as_string(path)
	var ref := path.trim_prefix("res://")
	var lines := source.split("\n")
	var i := 0
	while i < lines.size():
		var line := lines[i]
		for property: String in SCENE_PROPERTIES:
			var prefix := property + " = \""
			if not line.begins_with(prefix):
				continue
			#Ł The value can go on over several lines:
			var value := line.substr(prefix.length() - 1)
			var first_line := i
			while not _is_closed(value) and i + 1 < lines.size():
				i += 1
				value += "\n" + lines[i]
			var text := _unescape(value.substr(1, _string_end(value, 0) - 2))
			if _has_letters(text):
				_add(text, "", "", "%s:%d" % [ref, first_line + 1])
		i += 1


#* Whether the string literal value starts with is closed:
func _is_closed(value: String) -> bool:
	var j := 1
	while j < value.length():
		if value[j] == "\\":
			j += 2
			continue
		if value[j] == "\"":
			return true
		j += 1
	return false


#& Data files

#? in_check: inside a field check's settings, where "values" lists the values a check accepts, not help text.
func _scan_data(data: Variant, key: String, ref: String, in_check := false) -> void:
	if data is Dictionary:
		for item_key in data:
			var inner := in_check or CHECK_KEYS.has(str(item_key))
			_scan_data(data[item_key], str(item_key), ref, inner)
	elif data is Array:
		for item in data:
			_scan_data(item, key, ref, in_check)
	elif data is String and TEXT_KEYS.has(key) and _has_letters(data):
		if in_check and CHECK_VALUE_KEYS.has(key):
			return
		_add(data, "", "", ref)


#& Godot's own texts

#* The texts Godot writes in the controls CandyLocale lets it translate (see CandyLocale._on_node_added()):
func _scan_godot_texts() -> void:
	var ref := "Godot"
	var holder := Control.new()
	root.add_child(holder)
	var line_edit := LineEdit.new()
	var text_edit := TextEdit.new()
	var file_dialog := FileDialog.new()
	var color_picker := ColorPicker.new()
	var confirmation := ConfirmationDialog.new()
	for node: Node in [line_edit, text_edit, file_dialog, color_picker, confirmation]:
		holder.add_child(node)
	var texts: Array = []
	for menu: PopupMenu in [line_edit.get_menu(), text_edit.get_menu()]:
		_menu_texts(menu, texts)
	for node: Node in [file_dialog, color_picker]:
		_node_texts(node, texts)
	texts.append(confirmation.get_ok_button().text)
	texts.append(confirmation.get_cancel_button().text)
	texts.append(confirmation.title)
	var accept := AcceptDialog.new()
	texts.append(accept.title)
	accept.free()
	for text: String in texts:
		if _has_letters(text) and not text.contains("://"):
			_add(text, "", "", ref)
	holder.queue_free()


func _menu_texts(menu: PopupMenu, texts: Array) -> void:
	for i in menu.item_count:
		texts.append(menu.get_item_text(i))
		texts.append(menu.get_item_tooltip(i))
	for child in menu.get_children(true):
		if child is PopupMenu:
			_menu_texts(child, texts)


#* The texts of node and all its children, internal ones included (Godot's dialogs are made of them):
func _node_texts(node: Node, texts: Array) -> void:
	for child: Node in _all_nodes(node, []):
		if child is Window:
			texts.append(child.title)
		if child is AcceptDialog:
			texts.append(child.dialog_text)
		if child is Label or child is Button or child is LineEdit:
			texts.append(child.text)
		if child is LineEdit:
			texts.append(child.placeholder_text)
		if child is Control:
			texts.append(child.tooltip_text)
		if child is OptionButton:
			for i in child.item_count:
				texts.append(child.get_item_text(i))
		if child is PopupMenu:
			_menu_texts(child, texts)


func _all_nodes(node: Node, found: Array) -> Array:
	found.append(node)
	for child in node.get_children(true):
		_all_nodes(child, found)
	return found


#& Writing

func _add(msgid: String, plural: String, context: String, ref: String) -> void:
	if msgid == "":
		return
	var key := context + "\u0004" + msgid
	if not _index.has(key):
		var entry := {"msgid": msgid, "plural": plural, "context": context, "refs": [], "comment": ""}
		_index[key] = entry
		_entries.append(entry)
	var found: Dictionary = _index[key]
	if found["plural"] == "" and plural != "":
		found["plural"] = plural
	if not found["refs"].has(ref):
		found["refs"].append(ref)


func _write() -> int:
	DirAccess.make_dir_recursive_absolute(OUTPUT.get_base_dir())
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string("# Candy Dialogue Creator - translation template.\n")
	file.store_string("# Built by Tools/build_translation_template.gd: don't edit it, run the tool again.\n")
	file.store_string("# Keep placeholders as they are: %s, %d, {name}, ‹name›, {role}... and BBCode tags ([b]...[/b]).\n")
	file.store_string("msgid \"\"\nmsgstr \"\"\n")
	file.store_string("\"Project-Id-Version: Candy Dialogue Creator %s\\n\"\n" % _version())
	file.store_string("\"MIME-Version: 1.0\\n\"\n")
	file.store_string("\"Content-Type: text/plain; charset=UTF-8\\n\"\n")
	file.store_string("\"Content-Transfer-Encoding: 8-bit\\n\"\n")
	#? English's, which a translation tool replaces with the language's.
	file.store_string("\"Plural-Forms: nplurals=2; plural=(n != 1);\\n\"\n")
	for entry: Dictionary in _entries:
		file.store_string("\n")
		if entry["comment"] != "":
			file.store_string("#. %s\n" % entry["comment"])
		file.store_string("#: %s\n" % " ".join(PackedStringArray(entry["refs"].slice(0, 6))))
		if entry["context"] != "":
			file.store_string("msgctxt %s\n" % _po_string(entry["context"]))
		file.store_string("msgid %s\n" % _po_string(entry["msgid"]))
		if entry["plural"] != "":
			file.store_string("msgid_plural %s\n" % _po_string(entry["plural"]))
			file.store_string("msgstr[0] \"\"\nmsgstr[1] \"\"\n")
		else:
			file.store_string("msgstr \"\"\n")
	file.close()
	return OK


#* A PO string, split after each line break:
func _po_string(text: String) -> String:
	var escaped := text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\t", "\\t")
	if not escaped.contains("\n"):
		return "\"%s\"" % escaped
	var parts := escaped.split("\n")
	var result := "\"\""
	for i in parts.size():
		var part := parts[i]
		if i < parts.size() - 1:
			part += "\\n"
		if part != "":
			result += "\n\"%s\"" % part
	return result


#& Helpers

func _version() -> String:
	var source := FileAccess.get_file_as_string(VERSION_SCRIPT)
	var at := source.find("const VERSION := \"")
	if at == -1:
		return ""
	var start := at + "const VERSION := \"".length()
	return source.substr(start, source.find("\"", start) - start)


func _has_letters(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code > 127:
			return true
	return false


func _files_under(folder: String, extensions: Array) -> Array:
	var found: Array = []
	for file_name in DirAccess.get_files_at(folder):
		if extensions.has(file_name.get_extension().to_lower()):
			found.append(folder.path_join(file_name))
	for sub_folder in DirAccess.get_directories_at(folder):
		if SKIPPED_FOLDERS.has(sub_folder) or sub_folder.begins_with("."):
			continue
		found.append_array(_files_under(folder.path_join(sub_folder), extensions))
	return found

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySymbolsPage
extends CandySettingsPage

const ROOT_KEY := "project_path"
const SCRIPT_KEY := "symbol_script_path"
const SYMBOLS_KEY := "symbols"
const CANDY_REF_SCRIPT_KEY := "candy_ref_script_path"
#^ CandyRef_Shortcuts.gd's symbols - [{ "kind", "symbol", "target" | "keys" + "entries" }] (CandySymbolUpdater):
const CANDY_REF_KEY := "candy_ref_symbols"
const LEGACY_OPEN_KEY := "settings_symbols_legacy_open"
#^ Plain Array - PackedStringArray(...) isn't a constant expression:
const GD_FILTER := ["*.gd ; GDScript"]
const SYMBOL_EDIT_WIDTH := 90

#^ [label, key under "symbols", variable in Candy_Properties.gd]:
const SYMBOLS := [
	["Expression",		#/ translatable
		"expression", "candy_ref_symbol"],
	["Variable dictionary",		#/ translatable
		"vardict", "vardict_symbol"],
	["Role",		#/ translatable
		"role", "role_symbol"],
	["Text variable start",		#/ translatable
		"text_var_start", "text_var_start_symbol"],
	["Text variable end",		#/ translatable
		"text_var_end", "text_var_end_symbol"],
	["Substitution start",		#/ translatable
		"substitution_start", "substitution_start_symbol"],
	["Substitution end",		#/ translatable
		"substitution_end", "substitution_end_symbol"],
	["Separator",		#/ translatable
		"separator", "separator_symbol"],
	["Text event start",		#/ translatable
		"text_event_start", "text_event_start_symbol"],
	["Text event end",		#/ translatable
		"text_event_end", "text_event_end_symbol"],
	["Lexicon escape start",		#/ translatable
		"lexicon_escape_start", "lexicon_escape_start_symbol"],
	["Lexicon escape end",		#/ translatable
		"lexicon_escape_end", "lexicon_escape_end_symbol"],
]

#^ 1.1 symbols - [label, settings key]:
const LEGACY_SYMBOLS := [
	["Singleton",		#/ translatable
		"singleton_symbol"],
	["Node",		#/ translatable
		"node_symbol"],
	["Variable dictionary",		#/ translatable
		"vardict_symbol"],
	["Super singleton",		#/ translatable
		"super_singleton_symbol"],
	["Super node",		#/ translatable
		"super_node_symbol"],
	["Super variable dictionary",		#/ translatable
		"super_vardict_symbol"],
	["Role",		#/ translatable
		"role_symbol"],
	["Text variable start",		#/ translatable
		"text_var_symbol_start"],
	["Text variable end",		#/ translatable
		"text_var_symbol_end"],
	["Substitution start",		#/ translatable
		"substitution_symbol"],
	["Separator",		#/ translatable
		"separator_symbol"],
	["Variable file",		#/ translatable
		"file_var_symbol"],
]

var _status: Label
#^ The CandyRef symbols' rows, rebuilt from the draft:
var _candy_ref_box: VBoxContainer


func build() -> void:
	add_heading(CandyLocale.t("Scripts"))
	add_file(SCRIPT_KEY, CandyLocale.t("Candy Properties"), CandyLocale.t("Candy_Properties.gd in your project. Also set on the Paths page."), ROOT_KEY,
		PackedStringArray(GD_FILTER))
	add_file(CANDY_REF_SCRIPT_KEY, CandyLocale.t("CandyRef Shortcuts"), CandyLocale.t("CandyRef_Shortcuts.gd in your project."), ROOT_KEY,
		PackedStringArray(GD_FILTER))
	add_button("", CandyLocale.t("Update from scripts"), _import,
		CandyLocale.t("Read the 1.2 symbols out of Candy_Properties.gd, and the shortcut and lookup symbols out of CandyRef_Shortcuts.gd."))
	_status = add_note(" ")

	add_separator()
	add_heading(CandyLocale.t("Symbols"))
	for symbol in SYMBOLS:
		add_text(_key(str(symbol[1])), CandyLocale.t(str(symbol[0])), CandyLocale.t("Read from var %s") % str(symbol[2]))

	add_separator()
	add_heading(CandyLocale.t("CandyRef symbols"))
	_candy_ref_box = VBoxContainer.new()
	_candy_ref_box.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	add_custom(_candy_ref_box)

	add_separator()
	begin_section(CandyLocale.t("1.1 symbols"), LEGACY_OPEN_KEY, true)
	add_note(CandyLocale.t("Used when converting dialogues written with Candy DC 1.1. Enter them by hand: they are not imported, because 1.1 and 1.2 use some of the same variable names for different things."))
	for symbol in LEGACY_SYMBOLS:
		add_text(str(symbol[1]), CandyLocale.t(str(symbol[0])))
	end_section()


func refresh() -> void:
	super()
	_build_candy_ref_rows()


func _import() -> void:
	var lines := PackedStringArray()
	lines.append(_import_properties())
	lines.append(_import_candy_ref())
	refresh()
	_set_status("\n".join(lines))


#* Read Candy_Properties.gd's symbols, and say how it went:
func _import_properties() -> String:
	var script_path := resolve_path(str(draft.get_value(SCRIPT_KEY, "")), ROOT_KEY)
	if script_path == "":
		return CandyLocale.t("Candy Properties: set the path to Candy_Properties.gd first.")
	if not FileAccess.file_exists(script_path):
		return CandyLocale.t("Candy Properties: no file at %s") % script_path

	var found := 0
	var missing: Array = []
	for symbol in SYMBOLS:
		var value := CandyProjectScripts.read_string(script_path, str(symbol[2]))
		if value == "":
			missing.append(str(symbol[2]))
			continue
		draft.set_value(_key(str(symbol[1])), value)
		found += 1
	if missing.is_empty():
		return CandyLocale.t("Candy Properties: imported %d symbols.") % found
	return CandyLocale.t("Candy Properties: imported {count} symbols. Not found: {missing}").format({"count": found, "missing": ", ".join(missing)})


#* Read CandyRef_Shortcuts.gd's symbols (they replace the listed ones), and say how it went:
func _import_candy_ref() -> String:
	var script_path := resolve_path(str(draft.get_value(CANDY_REF_SCRIPT_KEY, "")), ROOT_KEY)
	if script_path == "":
		return CandyLocale.t("CandyRef Shortcuts: set the path to CandyRef_Shortcuts.gd first.")
	var tables := CandySymbolUpdater.read_candy_ref_script(script_path)
	#% Nothing changes unless both tables were read:
	if str(tables["problem"]) != "":
		return CandyLocale.t("CandyRef Shortcuts: %s Nothing was imported from it.") % tables["problem"]
	var entries := CandySymbolUpdater.entries_of(tables)
	draft.set_value(CANDY_REF_KEY, entries)
	return CandyLocale.t("CandyRef Shortcuts: imported %d symbols.") % entries.size()


#* One row per CandyRef symbol - what it reads, and its symbol:
func _build_candy_ref_rows() -> void:
	if _candy_ref_box == null:
		return
	for child in _candy_ref_box.get_children():
		child.queue_free()
	var entries = draft.get_value(CANDY_REF_KEY, [])
	if not entries is Array or entries.is_empty():
		var none := Label.new()
		none.text = CandyLocale.t("None imported.")
		none.theme_type_variation = CandyThemeDefaults.NOTE
		_candy_ref_box.add_child(none)
		return
	for i in entries.size():
		var entry = entries[i]
		if not entry is Dictionary:
			continue
		var row := HBoxContainer.new()
		_candy_ref_box.add_child(row)
		var label := Label.new()
		label.text = CandySymbolUpdater.entry_label(entry)
		var table := CandySymbolUpdater.SHORTCUTS
		if str(entry.get("kind", "")) == CandySymbolUpdater.KIND_LOOKUP:
			table = CandySymbolUpdater.LOOKUPS
		label.tooltip_text = CandyLocale.t("From %s in CandyRef_Shortcuts.gd.") % table
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(label)
		var edit := LineEdit.new()
		edit.text = str(entry.get("symbol", ""))
		edit.custom_minimum_size.x = SYMBOL_EDIT_WIDTH
		edit.tooltip_text = CandyLocale.t("The symbol, as in CandyRef_Shortcuts.gd.")
		edit.text_submitted.connect(func(text: String): _set_candy_ref_symbol(i, text))
		edit.focus_exited.connect(func(): _set_candy_ref_symbol(i, edit.text))
		row.add_child(edit)


func _set_candy_ref_symbol(index: int, symbol: String) -> void:
	var entries = draft.get_value(CANDY_REF_KEY, [])
	if not entries is Array or index >= entries.size():
		return
	entries = entries.duplicate(true)
	if str(entries[index].get("symbol", "")) == symbol.strip_edges():
		return
	entries[index]["symbol"] = symbol.strip_edges()
	draft.set_value(CANDY_REF_KEY, entries)


func _key(symbol_name: String) -> String:
	return "%s/%s" % [SYMBOLS_KEY, symbol_name]


func _set_status(message: String) -> void:
	if _status == null:
		return
	if message == "":
		_status.text = " "
	else:
		_status.text = message

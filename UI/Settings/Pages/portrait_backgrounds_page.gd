#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitBackgroundsPage
extends CandySettingsPage

const NAME_WIDTH := 160
const IMAGE_FILTERS := ["*.png, *.jpg, *.jpeg, *.webp, *.svg, *.bmp, *.tga ; Images"]
#^ Each list's texts:
const KIND_TEXTS := {
	CandyPortraitBackgrounds.ACTORS: {
		"title": "Actors",		#/ translatable
		"add": "Add Actors",		#/ translatable
		"add_tooltip": "Add the actors of the Data page that aren't listed here.",		#/ translatable
		"remove": "Remove Actors",		#/ translatable
		"remove_tooltip": "Remove the actors the Data page doesn't have any more, with their backgrounds.",		#/ translatable
		"add_one": "Add Actor",		#/ translatable
		"add_one_tooltip": "Add an actor by name",		#/ translatable
		"remove_one_tooltip": "Remove this actor and its background",		#/ translatable
		"none": "No actors yet.",		#/ translatable
		"all_listed": "Every actor of the Data page is listed already.",		#/ translatable
		"all_kept": "Every actor listed here is on the Data page.",		#/ translatable
	},
	CandyPortraitBackgrounds.ROLES: {
		"title": "Roles",		#/ translatable
		"add": "Add Roles",		#/ translatable
		"add_tooltip": "Add the roles of the Data page that aren't listed here.",		#/ translatable
		"remove": "Remove Roles",		#/ translatable
		"remove_tooltip": "Remove the roles the Data page doesn't have any more, with their backgrounds.",		#/ translatable
		"add_one": "Add Role",		#/ translatable
		"add_one_tooltip": "Add a role by name",		#/ translatable
		"remove_one_tooltip": "Remove this role and its background",		#/ translatable
		"none": "No roles yet.",		#/ translatable
		"all_listed": "Every role of the Data page is listed already.",		#/ translatable
		"all_kept": "Every role listed here is on the Data page.",		#/ translatable
	},
}
#^ The Data page's kind for each list:
const DATA_KINDS := {CandyPortraitBackgrounds.ACTORS: "Actors", CandyPortraitBackgrounds.ROLES: "Roles"}

var _data: Dictionary = {}
var _lists: Dictionary = {}    #/ Kind -> VBoxContainer
var _confirm: ConfirmationDialog
var _pending_action: Callable
var _message: AcceptDialog
var _name_prompt: CandyNamePrompt
var _file_dialog: FileDialog
var _file_target: LineEdit


func build() -> void:
	add_note(CandyLocale.t("A background color or texture for each actor and role, shown behind their portraits in every Portrait Preview instead of the widget's own. A texture is shown rather than a color. The lists only change when you use the buttons below, never on their own."))

	var sync := HBoxContainer.new()
	add_custom(sync)
	for kind in [CandyPortraitBackgrounds.ACTORS, CandyPortraitBackgrounds.ROLES]:
		sync.add_child(_button(_text(kind, "add"), _ask_add.bind(kind), _text(kind, "add_tooltip")))
	for kind in [CandyPortraitBackgrounds.ACTORS, CandyPortraitBackgrounds.ROLES]:
		sync.add_child(_button(_text(kind, "remove"), _ask_remove.bind(kind), _text(kind, "remove_tooltip")))

	for kind in [CandyPortraitBackgrounds.ACTORS, CandyPortraitBackgrounds.ROLES]:
		add_separator()
		var header := HBoxContainer.new()
		add_custom(header)
		var heading := Label.new()
		heading.text = _text(kind, "title")
		heading.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(heading)
		header.add_child(_button("+", _ask_name.bind(kind), _text(kind, "add_one_tooltip")))
		var list := VBoxContainer.new()
		add_custom(list)
		_lists[kind] = list

	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(func():
		if _pending_action.is_valid():
			_pending_action.call())
	add_child(_confirm)
	_message = AcceptDialog.new()
	add_child(_message)
	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(IMAGE_FILTERS)
	_file_dialog.file_selected.connect(func(path: String):
		if _file_target != null and is_instance_valid(_file_target):
			_file_target.text = path
			_file_target.text_changed.emit(path))
	add_child(_file_dialog)


func refresh() -> void:
	super.refresh()
	_data = {CandyPortraitBackgrounds.ACTORS: {}, CandyPortraitBackgrounds.ROLES: {}}
	var stored = draft.get_value(CandyPortraitBackgrounds.SETTING, {})
	if stored is Dictionary:
		for kind in _data:
			if stored.get(kind) is Dictionary:
				_data[kind] = stored[kind].duplicate(true)
	_rebuild()


func _button(text: String, handler: Callable, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


#& Rows

func _rebuild() -> void:
	for kind in _lists:
		var list: VBoxContainer = _lists[kind]
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
		var names: Array = _data[kind].keys()
		names.sort_custom(func(a, b) -> bool: return str(a).naturalnocasecmp_to(str(b)) < 0)
		if names.is_empty():
			var empty := Label.new()
			empty.text = _text(kind, "none")
			empty.theme_type_variation = CandyThemeDefaults.NOTE
			list.add_child(empty)
		for entry_name in names:
			list.add_child(_entry_row(kind, str(entry_name)))


func _entry_row(kind: String, entry_name: String) -> HBoxContainer:
	var entry: Dictionary = _data[kind][entry_name]
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = entry_name
	label.custom_minimum_size.x = NAME_WIDTH
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = entry_name
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)

	var stored_color = entry.get("color", "")
	var uses_color := stored_color is Color
	var use_color := CheckBox.new()
	use_color.text = CandyLocale.t("Color")
	use_color.tooltip_text = CandyLocale.t("Use the color on the right (a texture is shown instead when there is one).")
	use_color.button_pressed = uses_color
	row.add_child(use_color)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(44, 24)
	picker.edit_alpha = true
	picker.disabled = not uses_color
	if uses_color:
		picker.color = stored_color
	else:
		picker.color = Color(0.2, 0.2, 0.24, 1)
	row.add_child(picker)
	use_color.toggled.connect(func(on: bool):
		picker.disabled = not on
		if on:
			_set_entry(kind, entry_name, "color", picker.color)
		else:
			_set_entry(kind, entry_name, "color", ""))
	picker.color_changed.connect(func(color: Color):
		if use_color.button_pressed:
			_set_entry(kind, entry_name, "color", color))

	var texture := LineEdit.new()
	texture.text = str(entry.get("texture", ""))
	texture.placeholder_text = CandyLocale.t("No texture")
	texture.tooltip_text = CandyLocale.t("An image on disk, shown behind the portraits instead of the color. Empty for none.")
	texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture.text_changed.connect(func(text: String): _set_entry(kind, entry_name, "texture", text.strip_edges()))
	row.add_child(texture)
	row.add_child(_button("...", func():
		_file_target = texture
		if texture.text.strip_edges() != "":
			_file_dialog.current_path = texture.text.strip_edges()
		_file_dialog.popup_centered_ratio(0.6), CandyLocale.t("Pick an image")))

	row.add_child(_button("✕", func():
		_data[kind].erase(entry_name)
		_save()
		_rebuild(), _text(kind, "remove_one_tooltip")))
	return row


func _set_entry(kind: String, entry_name: String, key: String, value: Variant) -> void:
	if not _data[kind].has(entry_name):
		return
	_data[kind][entry_name][key] = value
	_save()


func _save() -> void:
	draft.set_value(CandyPortraitBackgrounds.SETTING, _data.duplicate(true))


#& Adding and removing

#* Get the Data page's actors or roles, as in this window's draft:
func _data_page_names(kind: String) -> Array:
	var scripts := draft.get_dictionary(CandyProjectDataPage.SCRIPTS_KEY)
	var entry = scripts.get(DATA_KINDS[kind], {})
	var names: Array = []
	if not entry is Dictionary:
		return names
	for value in CandyProjectScripts.split_list(str(entry.get("Data", ""))):
		var entry_name := _clean_name(kind, str(value))
		if entry_name != "" and not names.has(entry_name):
			names.append(entry_name)
	return names


#* Clean a name - trimmed, roles without the role symbol:
func _clean_name(kind: String, value: String) -> String:
	var entry_name := value.strip_edges()
	var role_symbol := str(draft.get_value("symbols/role", ""))
	if kind == CandyPortraitBackgrounds.ROLES and role_symbol != "" and entry_name.begins_with(role_symbol):
		entry_name = entry_name.substr(role_symbol.length()).strip_edges()
	return entry_name


func _ask_add(kind: String) -> void:
	var missing: Array = []
	for entry_name in _data_page_names(kind):
		if not _data[kind].has(entry_name):
			missing.append(entry_name)
	if missing.is_empty():
		_tell(CandyLocale.t("Nothing to add"), _text(kind, "all_listed"))
		return
	var question := CandyLocale.tn("Add %d actor from the Data page?", "Add %d actors from the Data page?", missing.size()) % missing.size()
	if kind == CandyPortraitBackgrounds.ROLES:
		question = CandyLocale.tn("Add %d role from the Data page?", "Add %d roles from the Data page?", missing.size()) % missing.size()
	_ask(_text(kind, "add"), question + "\n" + _names_text(missing),
		func():
			for entry_name in missing:
				_data[kind][entry_name] = {"color": "", "texture": ""}
			_save()
			_rebuild())


func _ask_remove(kind: String) -> void:
	var kept := _data_page_names(kind)
	var extra: Array = []
	for entry_name in _data[kind]:
		if not kept.has(str(entry_name)):
			extra.append(str(entry_name))
	if extra.is_empty():
		_tell(CandyLocale.t("Nothing to remove"), _text(kind, "all_kept"))
		return
	extra.sort_custom(func(a, b) -> bool: return str(a).naturalnocasecmp_to(str(b)) < 0)
	var question := CandyLocale.tn("Remove %d actor the Data page doesn't have? Its color and texture will be lost.", "Remove %d actors the Data page doesn't have? Their colors and textures will be lost.", extra.size()) % extra.size()
	if kind == CandyPortraitBackgrounds.ROLES:
		question = CandyLocale.tn("Remove %d role the Data page doesn't have? Its color and texture will be lost.", "Remove %d roles the Data page doesn't have? Their colors and textures will be lost.", extra.size()) % extra.size()
	_ask(_text(kind, "remove"), question + "\n" + _names_text(extra),
		func():
			for entry_name in extra:
				_data[kind].erase(entry_name)
			_save()
			_rebuild())


func _ask_name(kind: String) -> void:
	_name_prompt.prompt(_text(kind, "add_one"), "",
		func(typed: String) -> String:
			var entry_name := _clean_name(kind, typed)
			if entry_name == "":
				return CandyLocale.t("Type a name.")
			if _data[kind].has(entry_name):
				return CandyLocale.t("\"%s\" is listed already.") % entry_name
			return "",
		func(typed: String):
			_data[kind][_clean_name(kind, typed)] = {"color": "", "texture": ""}
			_save()
			_rebuild())


func _ask(dialog_title: String, text: String, action: Callable) -> void:
	_pending_action = action
	_confirm.title = dialog_title
	_confirm.dialog_text = text
	_confirm.reset_size()
	_confirm.popup_centered()


func _tell(dialog_title: String, text: String) -> void:
	_message.title = dialog_title
	_message.dialog_text = text
	_message.reset_size()
	_message.popup_centered()


#* Get one of a list's texts, translated:
func _text(kind: String, key: String) -> String:
	return CandyLocale.t(str(KIND_TEXTS[kind][key]))


#* List names - "Alice, Bob, Carl", past ten "... and 4 more":
func _names_text(names: Array) -> String:
	var shown: Array = names.slice(0, 10)
	var text := ", ".join(PackedStringArray(shown))
	if names.size() > shown.size():
		text = CandyLocale.t("{names} and {count} more").format({"names": text, "count": names.size() - shown.size()})
	return text

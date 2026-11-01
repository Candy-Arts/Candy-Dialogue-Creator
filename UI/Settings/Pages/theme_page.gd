#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyThemeSettingsPage
extends CandySettingsPage

#^ Minimum list height (the page scrolls in a smaller window):
const MIN_LIST_HEIGHT := 200
#^ Where more themes can be downloaded (Candy Arts' repository, like the news):
#? A web page, so by the repository's name: GitHub's pages have no address by ID.
const MORE_THEMES_URL := "https://github.com/Candy-Arts/Candy-Arts/tree/main/RESOURCES/Candy%20Dialogue%20Creator/Themes"

var _list: Tree
#^ Folded categories, kept over a Reload (see CandyTreeFolds):
var _folds: Dictionary = {}
#^ Filling or selecting from code (not a user choice):
var _updating := false


func build() -> void:
	#? Take the whole height, for the list to reach the window's bottom.
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columns := HBoxContainer.new()
	columns.theme_type_variation = CandyThemeDefaults.ROOMY_HBOX
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_custom(columns)

	_container = _add_column(columns)
	add_heading(CandyLocale.t("Your themes"))
	var folder_label := Label.new()
	folder_label.text = CandyLocale.t("Themes folder")
	add_custom(folder_label)
	var buttons := HBoxContainer.new()
	add_custom(buttons)
	_add_folder_button(buttons, CandyLocale.t("Open"), _open_folder, CandyLocale.t("Opens the folder your own themes go in."))
	_add_folder_button(buttons, CandyLocale.t("Reload"), _reload, CandyLocale.t("Finds the themes again, after adding or changing a file."))
	var more := _add_folder_button(buttons, CandyLocale.t("Get More"), _open_more_themes, CandyLocale.t("Opens Candy Arts' themes page in your browser."))
	#? Its icon follows the theme, like CandyIconButton's (now too: it's already in the tree).
	var update_icon := func() -> void:
		if more.has_theme_icon(&"globe", CandyThemeDefaults.ICONS):
			more.icon = more.get_theme_icon(&"globe", CandyThemeDefaults.ICONS)
		else:
			more.icon = null
	more.theme_changed.connect(update_icon)
	update_icon.call()

	columns.add_child(VSeparator.new())

	_container = _add_column(columns)
	add_heading(CandyLocale.t("Theme"))
	_list = Tree.new()
	_list.hide_root = true
	_list.select_mode = Tree.SELECT_SINGLE
	_list.custom_minimum_size.y = MIN_LIST_HEIGHT
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_theme_selected)
	_list.gui_input.connect(_on_list_input)
	add_custom(_list)
	_container = self
	_fill_list()


#* Add a column (the two share the width):
func _add_column(columns: HBoxContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(column)
	return column


#* Add a button under "Themes folder":
func _add_folder_button(parent: Control, button_text: String, handler: Callable, tooltip: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


#* Show the chosen theme in the list:
func refresh() -> void:
	super()
	_select_chosen()


#* Get the draft's theme:
func _chosen_id() -> String:
	return str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))


#* Fill the list:
func _fill_list() -> void:
	_updating = true
	CandyTreeFolds.remember(_list, _folds)
	_list.clear()
	var root := _list.create_item()
	var category := ""
	var parent := root
	for entry in CandyTheme.theme_list():
		if entry["category"] != category:
			category = entry["category"]
			parent = _list.create_item(root)
			parent.set_text(0, category)
			parent.set_selectable(0, false)
			parent.set_metadata(0, "")			#/ "" for a category, else a theme's id
			#? New categories start folded.
			parent.collapsed = true
		var label := str(entry["name"])
		if entry["source"] != "Built-in":
			var source := str(entry["source"])
			if source == "User":
				source = CandyLocale.t("User")
			label += " (%s)" % source
		var item := _list.create_item(parent)
		item.set_text(0, label)
		item.set_metadata(0, str(entry["id"]))
	CandyTreeFolds.restore(_list, _folds)
	_updating = false
	_select_chosen()


#* Select the chosen theme, unfolding its category:
func _select_chosen() -> void:
	var item := _find_item(_chosen_id())
	_updating = true
	if item == null:
		_list.deselect_all()
	else:
		var parent := item.get_parent()
		if parent != null and parent != _list.get_root():
			parent.collapsed = false
		item.select(0)
		_list.scroll_to_item(item)
	_updating = false


#* Find a theme's item, or null:
func _find_item(theme_id: String) -> TreeItem:
	var item := _list.get_root()
	while item != null:
		if str(item.get_metadata(0)) == theme_id and theme_id != "":
			return item
		item = item.get_next_in_tree()
	return null


func _on_theme_selected() -> void:
	if _updating:
		return
	var item := _list.get_selected()
	if item == null or str(item.get_metadata(0)) == "":
		return
	_write(CandyTheme.THEME_SETTING, str(item.get_metadata(0)))
	CandyThemeOptionsPage.preview_draft(draft)


#* Fold or unfold a category on a click anywhere on its row:
func _on_list_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var item := _list.get_item_at_position(click.position)
	if item == null or item.get_child_count() == 0:
		return
	item.collapsed = not item.collapsed
	#? The Tree only does it on the arrow.
	_list.accept_event()


func _open_folder() -> void:
	OS.shell_open(CandyTheme.user_themes_folder())


func _open_more_themes() -> void:
	OS.shell_open(MORE_THEMES_URL)


#* Reload themes from disk and rebuild the theme:
func _reload() -> void:
	CandyTheme.reload()
	_fill_list()
	CandyThemeOptionsPage.preview_draft(draft)

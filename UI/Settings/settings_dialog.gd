#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySettingsDialog
extends AcceptDialog

const LAST_PAGE_SETTING := "settings_last_page"

var _tree: Tree
var _scroll: ScrollContainer
var _content: MarginContainer
var _notice: Label
var _draft := CandySettingsDraft.new()
var _pages: Dictionary = {}       #/ id -> CandySettingsPage
var _current: CandySettingsPage


func _init() -> void:
	title = CandyLocale.t("Settings")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(860, 580)

	var root := HBoxContainer.new()
	add_child(root)

	_tree = Tree.new()
	_tree.custom_minimum_size.x = 220
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.allow_reselect = true
	_tree.item_selected.connect(_on_item_selected)
	root.add_child(_tree)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)

	_notice = Label.new()
	_notice.text = CandyLocale.t("Open a project profile to edit its settings.")
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notice.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_notice.visible = false
	right.add_child(_notice)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#? Wide pages scroll sideways.
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right.add_child(_scroll)

	_content = MarginContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#? Fill the window, so a page can reach its bottom (the Theme page's list).
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.theme_type_variation = CandyThemeDefaults.PAGE_MARGIN
	_scroll.add_child(_content)

	#? Save however the window closes (button, Escape, title bar).
	visibility_changed.connect(_on_visibility_changed)


func open() -> void:
	_draft.clear()
	_build_tree()

	var has_profile := CandyProfiles.is_profile_open()
	_notice.visible = not has_profile
	_content.visible = has_profile
	if has_profile:
		_select_page(str(CandyProfiles.get_setting(LAST_PAGE_SETTING, "")))
	popup_centered()


func _on_visibility_changed() -> void:
	if not visible:
		_draft.apply()


#& Left-hand tree

func _notification(what: int) -> void:
	#Ł Recolor (a custom color doesn't follow the theme), deferred (the tree still caches the previous theme's color):
	if what == NOTIFICATION_THEME_CHANGED and _tree != null:
		_color_categories.call_deferred()


func _build_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()

	for category in CandySettingsPages.CATEGORIES:
		var pages = CandySettingsPages.entries_in(category)
		if pages.is_empty():
			continue
		var group := _tree.create_item(root)
		group.set_text(0, CandyLocale.t(category))
		group.set_selectable(0, false)
		for entry in pages:
			var item := _tree.create_item(group)
			item.set_text(0, CandyLocale.t(str(entry["title"])))
			item.set_metadata(0, str(entry["id"]))
	_color_categories()


#* Color the categories with the theme's section title color:
func _color_categories() -> void:
	var root := _tree.get_root()
	if root == null:
		return
	var color := _tree.get_theme_color(&"font_color", CandyThemeDefaults.SECTION_TITLE)
	for group in root.get_children():
		group.set_custom_color(0, color)


func _select_page(id: String) -> void:
	var item := _find_item(id)
	if item == null:
		item = _first_page_item()
	if item == null:
		return
	item.select(0)
	_show_page(str(item.get_metadata(0)))


func _find_item(id: String) -> TreeItem:
	if id == "":
		return null
	var group: TreeItem = null
	if _tree.get_root() != null:
		group = _tree.get_root().get_first_child()
	while group != null:
		var item := group.get_first_child()
		while item != null:
			if str(item.get_metadata(0)) == id:
				return item
			item = item.get_next()
		group = group.get_next()
	return null


func _first_page_item() -> TreeItem:
	var group: TreeItem = null
	if _tree.get_root() != null:
		group = _tree.get_root().get_first_child()
	if group != null:
		return group.get_first_child()
	return null


func _on_item_selected() -> void:
	var item := _tree.get_selected()
	if item != null and item.get_metadata(0) != null:
		_show_page(str(item.get_metadata(0)))


#& Pages

func _show_page(id: String) -> void:
	var previous := _current
	if _current != null:
		_current.visible = false

	#Ł Build each page once and keep it (instant return, edits survive):
	if not _pages.has(id):
		var page = CandySettingsPages.create(id)
		if page == null:
			return
		page.draft = _draft
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content.add_child(page)
		page.build()
		_pages[id] = page

	_current = _pages[id]
	_current.visible = true
	_current.refresh()
	#Ł Start another page at its top (the pages share one scroll):
	if _current != previous:
		_scroll.scroll_vertical = 0
		_scroll.scroll_horizontal = 0
	_draft.set_value(LAST_PAGE_SETTING, id)
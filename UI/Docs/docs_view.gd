#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsView
extends Control

#^ Something get_state() returns changed:
signal state_changed

#^ Links of the view's own messages:
const LINK_DOWNLOAD := "docs:download"
const LINK_FOLDER := "docs:folder"
const PAGE_LINK := "page:"
#^ Links to the image viewer, on images shrunk to fit the page:
const IMAGE_LINK := "image:"
#^ Room the image viewer leaves around the image (its title bar and Close button):
const IMAGE_DIALOG_MARGIN := Vector2i(48, 96)
const MAX_PAGES := 2
const SIDEBAR_WIDTH := 260
const ABOUT_TITLE := "About"		#/ translatable
const ABOUT_FOLD_KEY := "about"
const MAX_TEXT_SIZE := 40
const MIN_TEXT_SIZE := 8
const ARROW_ICONS: Array[StringName] = [&"arrow", &"arrow_collapsed", &"arrow_collapsed_mirrored"]

var _look: String = CandyDocsLook.DEFAULT_LOOK
var _text_size := 0
var _sidebar_width := 0
var _database_id := ""
var _versions: Dictionary = {}      #/ database id -> the version picked last
var _languages: Dictionary = {}     #/ database id -> the language picked last
var _last_pages: Dictionary = {}    #/ "database/version/language" -> page id
var _folded: Dictionary = {}        #/ database id -> { fold key: true }
var _pending_state: Dictionary = {}

var _database: Dictionary = {}
var _version := ""
var _language := ""
var _version_languages: Array[String] = []
var _version_data: Dictionary = {}
#^ The pages' colors (CandyDocsLook.resolve_style()), set by _apply_look():
var _style: Dictionary = {}

#^ The pages shown, in order, and the one used last:
var _pages: Array[CandyDocsPage] = []
var _active_page: CandyDocsPage = null

var _image_cache: Dictionary = {}
#^ The widths of the images _prepare_body() sizes by the text width, while it runs:
var _image_widths: Array[int] = []
var _page_items: Dictionary = {}
var _marked_items: Array[TreeItem] = []
#^ True while the page list is built, so folds aren't taken for the user's:
var _building_tree := false
var _selection_color := Color.TRANSPARENT
var _selection_font_color := Color.TRANSPARENT
var _second_page_color := Color.TRANSPARENT
var _look_pending := false
var _built := false

var _root: VBoxContainer
var _body: HSplitContainer
var _sidebar: PanelContainer
var _search_edit: LineEdit
var _database_picker: OptionButton
var _version_picker: OptionButton
var _language_picker: OptionButton
var _tree: Tree
var _status_row: HBoxContainer
var _status_label: Label
var _status_button: Button
var _status_dismiss: CandyIconButton
var _pages_split: HSplitContainer

var _link_dialog: ConfirmationDialog
var _pending_link := ""
var _image_dialog: AcceptDialog
var _image_scroll: ScrollContainer
var _image_view: TextureRect

var _image_regex := RegEx.create_from_string("\\[img([^\\]]*)\\]([^\\[]*)\\[/img\\]")
var _url_regex := RegEx.create_from_string("\\[url(=[^\\]]*)?\\]")
#^ Counts the images given a path of their own:
static var _image_counter := 0


func _ready() -> void:
	_build()
	_build_dialogs()
	_apply_state(_pending_state)
	_open_page()
	_built = true
	CandyDocs.library_changed.connect(_reload)
	CandyDocs.status_changed.connect(_update_status)
	CandyProfiles.settings_changed.connect(_on_setting_changed)
	_reload()
	_update_status()


func _notification(what: int) -> void:
	#% Candy DC's theme changed:
	if what == NOTIFICATION_THEME_CHANGED and _built and not _look_pending:
		_look_pending = true
		_refresh_look.call_deferred()


func _build() -> void:
	#? The documentation's theme goes on _root, so the view's dialogs stay Candy DC's.
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_body = HSplitContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.dragged.connect(func(offset: int) -> void:
		_sidebar_width = offset
		state_changed.emit())
	_root.add_child(_body)

	_sidebar = PanelContainer.new()
	_sidebar.theme_type_variation = CandyThemeDefaults.DOCS_SIDEBAR
	_sidebar.custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)
	_body.add_child(_sidebar)
	var sidebar_box := VBoxContainer.new()
	_sidebar.add_child(sidebar_box)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = CandyLocale.t("Search pages")
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(func(_text: String) -> void: _rebuild_tree())
	sidebar_box.add_child(_search_edit)
	_database_picker = _add_picker(sidebar_box, CandyLocale.t("Database"), _on_database_picked)
	_database_picker.clip_text = true
	var picker_row := HBoxContainer.new()
	sidebar_box.add_child(picker_row)
	_version_picker = _add_picker(picker_row, CandyLocale.t("Version"), _on_version_picked)
	_language_picker = _add_picker(picker_row, CandyLocale.t("Language"), _on_language_picked)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_tree_selected)
	_tree.item_collapsed.connect(_on_item_collapsed)
	sidebar_box.add_child(_tree)

	_status_row = HBoxContainer.new()
	_status_row.visible = false
	sidebar_box.add_child(_status_row)
	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_row.add_child(_status_label)
	_status_button = Button.new()
	_status_button.text = CandyLocale.t("Update")
	_status_button.tooltip_text = CandyLocale.t("Download the updated documentation from GitHub.")
	_status_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_status_button.pressed.connect(CandyDocs.download)
	_status_row.add_child(_status_button)
	_status_dismiss = CandyIconButton.new(&"remove", CandyThemeDefaults.ICONS, "x", CandyLocale.t("Hide this message"))
	_status_dismiss.flat = true
	_status_dismiss.theme_type_variation = CandyThemeDefaults.FLAT_BUTTON
	_status_dismiss.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_status_dismiss.pressed.connect(CandyDocs.clear_status)
	_status_row.add_child(_status_dismiss)

	_pages_split = HSplitContainer.new()
	_pages_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_pages_split)


func _add_picker(parent: Control, tooltip: String, handler: Callable) -> OptionButton:
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.fit_to_longest_item = false
	picker.tooltip_text = tooltip
	picker.item_selected.connect(handler)
	parent.add_child(picker)
	return picker


#& Pages shown

#* Add a page to the right of the others, styled like them:
func _open_page() -> CandyDocsPage:
	var page := CandyDocsPage.new()
	_pages_split.add_child(page)
	_pages.append(page)
	if _active_page == null:
		_active_page = page
	page.back_button.pressed.connect(_go_back.bind(page))
	page.forward_button.pressed.connect(_go_forward.bind(page))
	page.close_button.pressed.connect(_close_page.bind(page))
	page.activated.connect(_set_active.bind(page))
	page.link_clicked.connect(_on_link_clicked.bind(page))
	page.content_width_changed.connect(_on_content_width_changed.bind(page))
	page.update_buttons()
	if not _style.is_empty():
		_style_page(page)
	#Ł Same width for both pages:
	_pages_split.split_offset = 0
	_update_pages()
	return page


func _close_page(page: CandyDocsPage) -> void:
	if _pages.size() < 2 or not _pages.has(page):
		return
	_pages.erase(page)
	page.queue_free()
	if _active_page == page:
		_active_page = _pages[0]
	_update_pages()


#* Back to the first page only, with no history:
func _single_page() -> void:
	while _pages.size() > 1:
		_close_page(_pages[_pages.size() - 1])
	_active_page = _pages[0]
	_active_page.clear_history()


#* The page beside `page`, opened if needed:
func _other_page(page: CandyDocsPage) -> CandyDocsPage:
	if _pages.size() < MAX_PAGES:
		return _open_page()
	return _pages[1 - _pages.find(page)]


#* Open a page of the database in `page`, or beside it:
func _open_from(page_id: String, page: CandyDocsPage, beside: bool) -> void:
	if not is_instance_valid(page) or not _pages.has(page):
		return
	if beside:
		navigate(page_id, _other_page(page))
	else:
		navigate(page_id, page)


func _set_active(page: CandyDocsPage) -> void:
	if _active_page == page:
		return
	_active_page = page
	_sync_tree()


#* Update close buttons and color markers for the number of pages:
func _update_pages() -> void:
	var split := _pages.size() > 1
	for page in _pages:
		page.set_closable(split)
		if split:
			page.set_marker(_page_color(page))
		else:
			page.set_marker(Color.TRANSPARENT)
	_sync_tree()


#* A page's color in the page list (the selection color, or the second page's):
func _page_color(page: CandyDocsPage) -> Color:
	if _pages.find(page) > 0:
		return _second_page_color
	return _selection_color


#* Text color over a page's mark (transparent: the list's own):
func _page_font_color(page: CandyDocsPage) -> Color:
	if _pages.find(page) > 0:
		if _second_page_color.a < 0.75:
			return Color.TRANSPARENT
		return CandyDocsLook.contrast_color(_second_page_color)
	return _selection_font_color


#* Whether Ctrl (Cmd on macOS) is held, to open beside:
func _beside_held() -> bool:
	if OS.get_name() == "macOS":
		return Input.is_key_pressed(KEY_META)
	return Input.is_key_pressed(KEY_CTRL)


#& Databases

#* Show CandyDocs' databases again, on the one that was open:
func _reload() -> void:
	_image_cache.clear()
	var databases := CandyDocs.databases()
	_database_picker.clear()
	for database in databases:
		_database_picker.add_item(str(database["title"]))
	#% No database - hide the sidebar and show how to get the documentation:
	_sidebar.visible = not databases.is_empty()
	if databases.is_empty():
		_single_page()
		_database = {}
		_version = ""
		_language = ""
		_version_picker.clear()
		_language_picker.clear()
		_version_data = {}
		_apply_look()
		_show_message(_active_page, _empty_message())
		return
	var index := 0
	for candidate in databases.size():
		if databases[candidate]["id"] == _database_id:
			index = candidate
	_database_picker.select(index)
	_select_database(index)


#* The message with no database (how to get the documentation, download status):
func _empty_message() -> String:
	var message := "[center][b]%s[/b][/center]\n\n" % CandyLocale.t("No documentation yet.") \
		+ CandyLocale.t("[url={download}]Download the documentation[/url] of Candy Dialogue Engine and Candy Dialogue Creator. It comes from Candy Arts' official GitHub repository; no data is sent beyond the request for the files.").format({"download": LINK_DOWNLOAD}) \
		+ "\n\n" \
		+ CandyLocale.t("Documentation for anything else is a database folder (one holding a [code]database.json[/code]) dropped in the [url={folder}]documentation folder[/url].").format({"folder": LINK_FOLDER})
	if not CandyDocs.status_text.is_empty():
		message += "\n\n[b]%s[/b]" % CandyDocs.status_text.replace("[", "[lb]")
	return message


#* Show a message of the view's own in a page, in the page's colors:
func _show_message(page: CandyDocsPage, bbcode: String) -> void:
	page.show_message(_prepare_body(bbcode, "", page))


func _select_database(index: int) -> void:
	_single_page()
	_database = CandyDocs.databases()[index]
	_database_id = str(_database["id"])
	_version_picker.clear()
	_language_picker.clear()
	var versions: Array = _database["versions"]
	for version: String in versions:
		_version_picker.add_item(version)
	if versions.is_empty():
		_version = ""
		_language = ""
		_version_data = {}
		_apply_look()
		_show_message(_active_page, "[center][b]%s[/b][/center]\n\n%s" % [_database["title"], CandyLocale.t("This database has no version folder yet.")])
		return
	#Ł The project's installed version, else the one picked last, else the newest:
	var pick := 0
	var hinted := CandyDocsLibrary.hinted_version(_database, str(CandyProfiles.get_setting("project_path", "")))
	var remembered := str(_versions.get(_database_id, ""))
	if not hinted.is_empty():
		pick = versions.find(hinted)
	elif versions.has(remembered):
		pick = versions.find(remembered)
	_version_picker.select(pick)
	_select_version(pick)


func _select_version(index: int) -> void:
	_single_page()
	_version = str(_database["versions"][index])
	_language_picker.clear()
	_version_languages = CandyDocsLibrary.languages(_database, _version)
	for language in _version_languages:
		_language_picker.add_item(CandyDocsLibrary.prettify(language))
	if _version_languages.is_empty():
		_language = ""
		_version_data = {}
		_apply_look()
		_show_message(_active_page, "[center][b]%s %s[/b][/center]\n\n%s" % [_database["title"], _version, CandyLocale.t("This version has no language folder yet.")])
		return
	var pick := CandyDocsLibrary.pick_language(_database, _version_languages, str(_languages.get(_database_id, "")))
	if pick < 0:
		pick = 0
	_language_picker.select(pick)
	_select_language(pick)


func _select_language(index: int) -> void:
	_single_page()
	_language = _version_languages[index]
	_version_data = CandyDocsLibrary.load_version(_database, _version, _language)
	_search_edit.text = ""
	_apply_look()
	var pages: Dictionary = _version_data["pages"]
	var start := str(_last_pages.get(_page_key(), ""))
	if not pages.has(start):
		start = str(_database["home"])
	if not pages.has(start):
		start = str(_version_data["first"])
	if start.is_empty():
		_show_message(_active_page, "[center][b]%s %s (%s)[/b][/center]\n\n%s" % [_database["title"], _version, CandyDocsLibrary.prettify(_language), CandyLocale.t("This language has no pages yet.")])
		return
	navigate(start, _active_page)


func _page_key() -> String:
	return "%s/%s/%s" % [_database_id, _version, _language]


func _on_database_picked(index: int) -> void:
	_select_database(index)
	state_changed.emit()


#* Remember the version the user picked:
func _on_version_picked(index: int) -> void:
	_versions[_database_id] = str(_database["versions"][index])			#/ Only picks: the project's installed version decides otherwise
	_select_version(index)
	state_changed.emit()


#* Remember the language the user picked:
func _on_language_picked(index: int) -> void:
	_languages[_database_id] = _version_languages[index]			#/ Only picks: the database's default language applies otherwise
	_select_language(index)
	state_changed.emit()


#* Reload when the project path changes (its installed version may differ):
func _on_setting_changed(key: String) -> void:
	if key == "project_path" and not _database.is_empty() and not _database["version_hint"].is_empty():
		_reload()


#& Navigation

#* Show a page of the database in `page` (by default the one used last):
func navigate(page_id: String, page: CandyDocsPage = null, record := true) -> void:
	if page == null:
		page = _active_page
	var pages: Dictionary = _version_data.get("pages", {})
	if not pages.has(page_id):
		_show_message(page, "[b]%s[/b] [code]%s[/code]" % [CandyLocale.t("Page not found:"), page_id.replace("[", "[lb]")])
		_sync_tree()
		return
	page.current_page = page_id
	if record:
		page.record(page_id)
	if str(_last_pages.get(_page_key(), "")) != page_id:
		_last_pages[_page_key()] = page_id
		state_changed.emit()
	_render(page)
	page.update_buttons()
	_sync_tree(page)


func _go_back(page: CandyDocsPage) -> void:
	_set_active(page)
	if page.can_go_back():
		page.history_index -= 1
		navigate(page.history[page.history_index], page, false)


func _go_forward(page: CandyDocsPage) -> void:
	_set_active(page)
	if page.can_go_forward():
		page.history_index += 1
		navigate(page.history[page.history_index], page, false)


#* Follow a link - a page of the database, or a web page after confirmation:
func _on_link_clicked(target: String, page: CandyDocsPage) -> void:
	if page.current_page.is_empty() and target == LINK_DOWNLOAD:			#/ The view's own links only work in its messages
		CandyDocs.download()
	elif page.current_page.is_empty() and target == LINK_FOLDER:
		OS.shell_open(CandyDocs.databases_folder())
	elif target.begins_with(PAGE_LINK):
		var beside := _beside_held()
		if not beside:
			_set_active(page)
		_open_from(target.substr(PAGE_LINK.length()).strip_edges(), page, beside)
	elif target.to_lower().begins_with("https://") or target.to_lower().begins_with("http://"):			#/ Nothing else (files, programs) opens
		_pending_link = target
		_link_dialog.dialog_text = CandyLocale.t("Open this link in your browser?") + "\n\n" + target
		_link_dialog.popup_centered()
	elif target.begins_with(IMAGE_LINK):
		_show_image(target.substr(IMAGE_LINK.length()))


#* Open the image viewer on an image of the pages (its virtual path, see _image_tag()):
func _show_image(virtual_path: String) -> void:
	for cached: Dictionary in _image_cache.values():
		if cached["path"] != virtual_path:
			continue
		var texture: Texture2D = cached["texture"]
		_image_dialog.title = str(cached["file"]).get_file()
		_image_view.texture = texture
		_image_scroll.scroll_horizontal = 0
		_image_scroll.scroll_vertical = 0
		_image_dialog.popup_centered_clamped(Vector2i(texture.get_size()) + IMAGE_DIALOG_MARGIN, 0.9)
		return


#& A page's text

#* Show a page's current page from its file, from the top or keeping the scroll:
func _render(page: CandyDocsPage, keep_scroll := false) -> void:
	var pages: Dictionary = _version_data.get("pages", {})
	if not pages.has(page.current_page):
		return
	var entry: Dictionary = pages[page.current_page]
	var file := FileAccess.open(str(entry["file"]), FileAccess.READ)
	if file == null:
		page.show_text("[b]%s[/b] [code]%s[/code]" % [CandyLocale.t("Could not read"), entry["file"]])
		return
	var parsed := CandyDocsLibrary.parse_page(file.get_as_text())
	_image_widths = []
	var shown := _prepare_body(str(parsed["body"]), str(entry["file"]).get_base_dir(), page)
	page.body_image_widths = _image_widths
	page.body_sized_for = page.content_width()
	if keep_scroll:
		page.update_text(shown)
	else:
		page.show_text(shown)


#* Show the database's header above the page (CandyDocsLibrary.header_file()):
func _render_header(page: CandyDocsPage) -> void:
	var file_path := ""
	if not _database.is_empty() and not _version.is_empty() and not _language.is_empty():
		file_path = CandyDocsLibrary.header_file(_database, _version, _language)
	var file: FileAccess = null
	if not file_path.is_empty():
		file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		page.header_image_widths = []
		page.show_header("", false)
		return
	page.set_header_scrolls(CandyVariantFile.to_bool(_database.get("header_scrolls", true), true))
	var parsed := CandyDocsLibrary.parse_page(file.get_as_text())
	_image_widths = []
	page.show_header(_prepare_body(str(parsed["body"]), file_path.get_base_dir(), page), true)
	page.header_image_widths = _image_widths
	page.header_sized_for = page.content_width()


#* Show the database's footer below the page (CandyDocsLibrary.footer_file()):
func _render_footer(page: CandyDocsPage) -> void:
	var file_path := ""
	if not _database.is_empty() and not _version.is_empty() and not _language.is_empty():
		file_path = CandyDocsLibrary.footer_file(_database, _version, _language)
	var file: FileAccess = null
	if not file_path.is_empty():
		file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		page.footer_image_widths = []
		page.show_footer("", false)
		return
	page.set_footer_scrolls(CandyVariantFile.to_bool(_database.get("footer_scrolls", true), true))
	var parsed := CandyDocsLibrary.parse_page(file.get_as_text())
	_image_widths = []
	page.show_footer(_prepare_body(str(parsed["body"]), file_path.get_base_dir(), page), true)
	page.footer_image_widths = _image_widths
	page.footer_sized_for = page.content_width()


#* Draw the header, the footer and the text again when the new width changes how an image is sized (_image_tag()):
func _on_content_width_changed(page: CandyDocsPage) -> void:
	var width := page.content_width()
	if _sizes_change(page.header_image_widths, page.header_sized_for, width):
		_render_header(page)
	if _sizes_change(page.footer_image_widths, page.footer_sized_for, width):
		_render_footer(page)
	if not page.current_page.is_empty() and _sizes_change(page.body_image_widths, page.body_sized_for, width):
		_render(page, true)


#* Whether an image of these widths goes from its own width to the text's, or back:
func _sizes_change(image_widths: Array[int], old_width: int, new_width: int) -> bool:
	for image_width in image_widths:
		if (image_width > old_width) != (image_width > new_width):
			return true
	return false


#* Turn a page's BBCode into what the label shows:
func _prepare_body(text: String, page_dir: String, page: CandyDocsPage) -> String:
	var out := ""
	var cursor := 0
	#@ Step 1 - Remove the tags that load a file (CandyRemoteBBCode), except the images, which _image_tag() loads in step 4:
	for found in _image_regex.search_all(text):
		out += CandyRemoteBBCode.without_resources(text.substr(cursor, found.get_start() - cursor))
		out += found.get_string()
		cursor = found.get_end()
	out += CandyRemoteBBCode.without_resources(text.substr(cursor))
	#@ Step 2 - Color and underline links, color [code]:
	var tags := _resolved_tags()
	var link_color: Color = _style["link_color"]
	if tags.has("url") and tags["url"]["color"].a > 0.0:
		link_color = tags["url"]["color"]
	var code_color: Color = _style["code_color"]
	if tags.has("code") and tags["code"]["color"].a > 0.0:
		code_color = tags["code"]["color"]
	out = _url_regex.sub(out, "[color=#%s][u][url$1]" % link_color.to_html(false), true)
	out = out.replace("[/url]", "[/url][/u][/color]")
	out = out.replace("[code]", "[color=#%s][code]" % code_color.to_html(false))
	out = out.replace("[/code]", "[/code][/color]")
	#@ Step 3 - Apply the database's tags (CandyDocsLibrary):
	for tag_name: String in tags:
		if CandyDocsLibrary.RESTYLED_TAGS.has(tag_name):
			continue
		var tag: Dictionary = tags[tag_name]
		var opening := ""
		var closing := ""
		var color: Color = tag["color"]
		if color.a > 0.0:
			opening += "[color=#%s]" % color.to_html(false)
			closing = "[/color]" + closing
		if tag["bold"]:
			opening += "[b]"
			closing = "[/b]" + closing
		if tag["italic"]:
			opening += "[i]"
			closing = "[/i]" + closing
		out = out.replace("[%s]" % tag_name, opening).replace("[/%s]" % tag_name, closing)
	#@ Step 4 - Load the images, last so a link around one doesn't color or underline it:
	var shown := ""
	cursor = 0
	for found in _image_regex.search_all(out):
		var before := out.substr(0, found.get_start())
		var in_link := _url_regex.search_all(before).size() > before.count("[/url]")
		shown += out.substr(cursor, found.get_start() - cursor)
		shown += _image_tag(found.get_string(1), found.get_string(2).strip_edges(), page_dir, page, in_link)
		cursor = found.get_end()
	return shown + out.substr(cursor)


#* The open database's tags as pages show them:
func _resolved_tags() -> Dictionary:
	var resolved: Dictionary = {}
	var tags: Dictionary = _database.get("tags", {})
	for tag_name: String in tags:
		var tag: Dictionary = tags[tag_name]
		resolved[tag_name] = {
			"color": CandyDocsLook.tag_color(tag, _style, _look),
			"bold": str(tag.get("bold", "0")) == "1",
			"italic": str(tag.get("italic", "0")) == "1",
		}
	return resolved			#/ { name: { "color": Color (transparent: none), "bold": bool, "italic": bool } }


#* An `[img]` tag for a file of the database, linked to the image viewer when shrunk (in_link: inside a link already):
func _image_tag(options: String, source: String, page_dir: String, page: CandyDocsPage, in_link: bool) -> String:
	var resolved := _resolve_image(source, page_dir)
	if resolved.is_empty():
		return "[i](%s)[/i]" % (CandyLocale.t("image not found: %s") % source.get_file().replace("[", "[lb]"))
	#Ł The label only loads resources - read the file and give it a virtual path:
	if not _image_cache.has(resolved):
		var loaded := CandyDocsLibrary.load_texture(resolved)
		if loaded == null:
			return "[i](%s)[/i]" % (CandyLocale.t("image could not be read: %s") % source.get_file().replace("[", "[lb]"))
		_image_counter += 1
		var virtual_path := "candydocs://image_%d.png" % _image_counter
		loaded.take_over_path(virtual_path)
		_image_cache[resolved] = {"path": virtual_path, "texture": loaded, "file": resolved}
	var cached: Dictionary = _image_cache[resolved]
	var texture: Texture2D = cached["texture"]
	var sized := options.contains("width") or options.contains("height") or options.begins_with("=")
	var shrunk := false
	if not sized:
		_image_widths.append(texture.get_width())
		if texture.get_width() > page.content_width():
			options += " width=100%"
			shrunk = true
	else:
		shrunk = _shown_width(options, texture, page) < texture.get_width()
	var tag := "[img%s]%s[/img]" % [options, cached["path"]]
	#% Shrunk, and not in a link already - a click shows it whole:
	if shrunk and not in_link:
		return "[url=%s%s]%s[/url]" % [IMAGE_LINK, cached["path"], tag]
	return tag


#* The width an `[img]` with size options shows texture at:
func _shown_width(options: String, texture: Texture2D, page: CandyDocsPage) -> float:
	var width := ""
	var height := ""
	#¦ 1. [img=WxH] or [img=W]:
	if options.begins_with("="):
		var sizes := options.substr(1).strip_edges().split(" ")[0].split("x")
		width = sizes[0]
		if sizes.size() > 1:
			height = sizes[1]
	#¦ 2. [img width=W height=H]:
	else:
		for option in options.strip_edges().split(" ", false):
			if option.begins_with("width="):
				width = option.substr(6)
			elif option.begins_with("height="):
				height = option.substr(7)
	var shown_width := _image_length(width, page.content_width())
	if shown_width >= 0.0:
		return shown_width
	var shown_height := _image_length(height, page.content_width())
	#% Height only - the width keeps the image's proportions:
	if shown_height >= 0.0:
		return texture.get_width() * shown_height / texture.get_height()
	return texture.get_width()


#* An `[img]` width or height in pixels (percent_of is 100%), or -1 when not set:
func _image_length(value: String, percent_of: float) -> float:
	value = value.strip_edges().trim_prefix("\"").trim_suffix("\"")
	if value.ends_with("%") and value.trim_suffix("%").is_valid_float():
		return percent_of * value.trim_suffix("%").to_float() / 100.0
	if value.is_valid_float() and value.to_float() > 0.0:
		return value.to_float()
	return -1.0


#* The file an `[img]` source points at, or "" if none inside the database's folder:
func _resolve_image(source: String, page_dir: String) -> String:
	if _database.is_empty() or source.contains("://") or source.is_absolute_path():
		return ""
	var database_path := str(_database["path"])
	for folder: String in [page_dir, database_path.path_join(_version).path_join(_language), database_path.path_join(_version), database_path]:
		var candidate := folder.path_join(source).simplify_path()
		if CandyDocsLibrary.is_inside(candidate, database_path) and FileAccess.file_exists(candidate):
			return candidate
	return ""


#& Page list

func _rebuild_tree() -> void:
	_marked_items.clear()
	_tree.clear()
	_page_items.clear()
	var root := _tree.create_item()
	if _version_data.is_empty():
		return
	var query := _search_edit.text.strip_edges().to_lower()
	_building_tree = true
	if query.is_empty():
		_add_nodes(root, _version_data["tree"])
		_add_about(root)
	else:
		_add_matches(root, query)
	_building_tree = false
	_sync_tree()


#* Add the page tree's nodes:
func _add_nodes(parent: TreeItem, nodes: Array) -> void:
	for node: Dictionary in nodes:
		var item := _tree.create_item(parent)
		item.set_text(0, str(node["title"]))
		if node["kind"] == "page":
			item.set_metadata(0, node["id"])
			item.set_icon(0, _icon(&"page", &"tree_icon"))
			_page_items[node["id"]] = item
			if node.has("children"):			#/ Opens like any page
				_add_nodes(item, node["children"])
				_set_fold_key(item, "page:" + str(node["id"]))
		else:
			item.set_icon(0, _icon(&"folder", &"tree_icon"))
			_add_nodes(item, node["children"])
			_set_fold_key(item, "category:" + str(node["id"]))


#* Add the About pages, last, in their own category:
func _add_about(root: TreeItem) -> void:
	var about: Array = _version_data.get("about", [])
	if about.is_empty():
		return
	var pages: Dictionary = _version_data["pages"]
	var category := _tree.create_item(root)
	category.set_text(0, CandyLocale.t(ABOUT_TITLE))
	category.set_icon(0, _icon(&"folder", &"tree_icon"))
	for page_id: String in about:
		var item := _tree.create_item(category)
		item.set_text(0, str(pages[page_id]["title"]))
		item.set_metadata(0, page_id)
		item.set_icon(0, _icon(&"page", &"tree_icon"))
		_page_items[page_id] = item
	_set_fold_key(category, ABOUT_FOLD_KEY)


#* Name a foldable item, and fold it if it was left folded:
func _set_fold_key(item: TreeItem, key: String) -> void:
	item.set_meta(&"fold_key", key)
	var keys: Variant = _folded.get(_database_id, {})
	item.collapsed = keys is Dictionary and keys.has(key)


func _add_matches(root: TreeItem, query: String) -> void:
	var pages: Dictionary = _version_data["pages"]
	var titles: Array[String] = []
	var bodies: Array[String] = []
	for page_id: String in pages:
		var page: Dictionary = pages[page_id]
		if page.get("about", false):
			continue
		if str(page["title"]).to_lower().contains(query):
			titles.append(page_id)
		elif str(page["search"]).contains(query):
			bodies.append(page_id)
	titles.sort()
	bodies.sort()
	for page_id in titles + bodies:
		var page: Dictionary = pages[page_id]
		var item := _tree.create_item(root)
		item.set_text(0, str(page["title"]))
		item.set_metadata(0, page_id)
		item.set_icon(0, _icon(&"page", &"tree_icon"))
		item.set_tooltip_text(0, _snippet(str(page["search"]), query))
		_page_items[page_id] = item


func _snippet(text: String, query: String) -> String:
	var found_at := text.find(query)
	if found_at < 0:
		return ""
	var start := maxi(0, found_at - 40)
	return "..." + text.substr(start, 100).replace("\n", " ") + "..."


#* Remember which categories of the open database are folded:
func _on_item_collapsed(item: TreeItem) -> void:
	if _building_tree or _database.is_empty() or not item.has_meta(&"fold_key"):
		return
	var key := str(item.get_meta(&"fold_key"))
	var keys: Dictionary = {}
	if _folded.get(_database_id) is Dictionary:
		keys = _folded[_database_id]
	if item.collapsed:
		keys[key] = true
	else:
		keys.erase(key)
	_folded[_database_id] = keys
	state_changed.emit()


#* Mark each shown page's item in its page's color, and scroll to `scroll_page`'s:
func _sync_tree(scroll_page: CandyDocsPage = null) -> void:
	for item in _marked_items:
		item.clear_custom_bg_color(0)
		item.clear_custom_color(0)
	_marked_items.clear()
	#? The page used last is marked last, so it wins when both show the same page.
	var ordered: Array[CandyDocsPage] = []
	for page in _pages:
		if page != _active_page:
			ordered.append(page)
	if _active_page != null:
		ordered.append(_active_page)
	for page in ordered:
		if not _page_items.has(page.current_page):
			continue
		var item: TreeItem = _page_items[page.current_page]
		item.set_custom_bg_color(0, _page_color(page))
		var font_color := _page_font_color(page)
		if font_color.a > 0.0:
			item.set_custom_color(0, font_color)
		_marked_items.append(item)
	if scroll_page != null and _page_items.has(scroll_page.current_page):
		_tree.scroll_to_item(_page_items[scroll_page.current_page])


#* Open the clicked page in the first page (with Ctrl, the second):
func _on_tree_selected() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	#? Once the Tree is done selecting.
	#? Cleared after each click, so a selected page can be clicked again.
	_tree.deselect_all.call_deferred()
	var page_id: Variant = item.get_metadata(0)
	if page_id == null:			#/ A folder: stays selectable (the Tree folds unselectable items on click) but does nothing
		return
	_open_from(str(page_id), _pages[0], _beside_held())


#& Look

#* Candy DC's theme changed (see _notification()):
func _refresh_look() -> void:
	_look_pending = false
	_apply_look()
	_render_pages()
	if _database.is_empty():
		_show_message(_active_page, _empty_message())


#* Apply the view's look (CandyDocsLook): theme, page colors, icons, page list:
func _apply_look() -> void:
	_style = CandyDocsLook.resolve_style(_database, _look, self)
	_root.theme = CandyDocsLook.resolve_theme(_database, _look, self)
	_second_page_color = CandyDocsLook.second_page_color(_database, _look, self)
	for page in _pages:
		_style_page(page)
	_apply_arrow_icons()
	_apply_selection_look()
	_rebuild_tree()
	_update_pages()


func _style_page(page: CandyDocsPage) -> void:
	var mono := CandyDocsLook.mono_font()
	if _root.theme != null and _root.theme.has_font(&"mono_font", &"RichTextLabel"):
		mono = _root.theme.get_font(&"mono_font", &"RichTextLabel")
	page.apply_style(_style)
	page.set_font_size(_text_size)
	page.set_mono_font(mono)
	page.back_button.icon = _icon(&"back", &"button_icon")
	page.forward_button.icon = _icon(&"forward", &"button_icon")
	page.close_button.icon = _icon(&"remove", &"button_icon")
	_render_header(page)
	_render_footer(page)


#* Render every page again, keeping the scroll (colors are in the text):
func _render_pages() -> void:
	for page in _pages:
		if not page.current_page.is_empty():
			_render(page, true)


#* One of Candy DC's icons (CandyIcons), recolored if the documentation's theme gives `color_name`:
func _icon(icon_name: StringName, color_name: StringName) -> Texture2D:
	if not _tree.has_theme_color(color_name, CandyDocsLook.COLORS):
		return _tree.get_theme_icon(icon_name, CandyThemeDefaults.ICONS)
	var color := _tree.get_theme_color(color_name, CandyDocsLook.COLORS)
	return CandyDocsLook.recolored(CandyThemeDefaults.ICONS, icon_name, color)


#* Color the fold arrows - the documentation's arrow color, else its icon color, else the theme's:
func _apply_arrow_icons() -> void:
	var color_name := &"tree_icon"
	if _tree.has_theme_color(&"tree_arrow", CandyDocsLook.COLORS):
		color_name = &"tree_arrow"
	for arrow_name in ARROW_ICONS:
		if _tree.has_theme_color(color_name, CandyDocsLook.COLORS):
			_tree.add_theme_icon_override(arrow_name,
				CandyDocsLook.recolored(&"Tree", arrow_name, _tree.get_theme_color(color_name, CandyDocsLook.COLORS)))
		else:
			_tree.remove_theme_icon_override(arrow_name)


#* Hide the Tree's selection, and read its color for the page marks:
func _apply_selection_look() -> void:
	for box_name: StringName in [&"selected", &"selected_focus"]:
		_tree.remove_theme_stylebox_override(box_name)
	var box := _tree.get_theme_stylebox(&"selected") as StyleBoxFlat
	if box != null:
		_selection_color = box.bg_color
	else:
		_selection_color = Color(CandyDocsLook.candy_style(self)["accent_color"], CandyDocsLook.SECOND_PAGE_ALPHA)
	_selection_font_color = Color.TRANSPARENT
	if _selection_color.a >= 0.75:
		_selection_font_color = _tree.get_theme_color(&"font_selected_color")
	#Ł Hide it - pages are marked by _page_color(), since the selection shows one only:
	for box_name: StringName in [&"selected", &"selected_focus"]:
		_tree.add_theme_stylebox_override(box_name, StyleBoxEmpty.new())


#& Status

#* Update the status line - download progress, the last result, or an available update:
func _update_status() -> void:
	if not _built:
		return
	if _database.is_empty():
		_show_message(_active_page, _empty_message())
	var text := CandyDocs.status_text
	var update_waits := CandyDocs.has_downloads() and not CandyDocs.updates_waiting().is_empty()
	if text.is_empty() and update_waits:
		text = CandyLocale.t("Updated documentation is available.")
	_status_label.text = text
	_status_label.theme_type_variation = CandyThemeDefaults.NOTE
	if CandyDocs.status_failed:
		_status_label.theme_type_variation = CandyThemeDefaults.ERROR
	_status_row.visible = not text.is_empty()
	_status_button.visible = update_waits and not CandyDocs.is_busy()
	_status_dismiss.visible = not CandyDocs.is_busy() and not CandyDocs.status_text.is_empty()


#& Options

#* The current look (one of CandyDocsLook.LOOKS):
func look() -> String:
	return _look


func set_look(new_look: String) -> void:
	if not CandyDocsLook.LOOKS.has(new_look) or new_look == _look:
		return
	_look = new_look
	_apply_look()
	_render_pages()
	if _database.is_empty():
		_show_message(_active_page, _empty_message())
	state_changed.emit()


#* Make the text larger (1) or smaller (-1):
func step_text_size(step: int) -> void:
	var current := _text_size
	if current <= 0:
		current = get_theme_font_size(&"normal_font_size", &"RichTextLabel")
	_set_text_size(clampi(current + step, MIN_TEXT_SIZE, MAX_TEXT_SIZE))


#* Back to the theme's text size:
func reset_text_size() -> void:
	_set_text_size(0)


func _set_text_size(value: int) -> void:
	if value == _text_size:
		return
	_text_size = value
	for page in _pages:
		page.set_font_size(_text_size)
	state_changed.emit()


#* Clamp a text size (0 = the theme's):
func _valid_text_size(value: int) -> int:
	if value <= 0:
		return 0
	return clampi(value, MIN_TEXT_SIZE, MAX_TEXT_SIZE)


func _build_dialogs() -> void:
	_link_dialog = ConfirmationDialog.new()
	_link_dialog.title = CandyLocale.t("Open Link")
	_link_dialog.confirmed.connect(func() -> void: OS.shell_open(_pending_link))
	add_child(_link_dialog)
	#Ł The image viewer - an image shrunk to fit the page, at its own size:
	_image_dialog = AcceptDialog.new()
	_image_dialog.ok_button_text = CandyLocale.t("Close")
	add_child(_image_dialog)
	_image_scroll = ScrollContainer.new()
	_image_dialog.add_child(_image_scroll)
	_image_view = TextureRect.new()
	_image_view.stretch_mode = TextureRect.STRETCH_KEEP
	_image_scroll.add_child(_image_view)


#& State

#* What the view shows and how (shape at the top):
func get_state() -> Dictionary:
	if not _built:
		return _pending_state
	return {"look": _look, "text_size": _text_size, "sidebar_width": _sidebar_width,
		"database": _database_id, "versions": _versions, "languages": _languages,
		"pages": _last_pages, "folded": _folded}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _built:
		_apply_state(state)
		_reload()


func _apply_state(state: Dictionary) -> void:
	_look = str(state.get("look", CandyDocsLook.DEFAULT_LOOK))
	if not CandyDocsLook.LOOKS.has(_look):
		_look = CandyDocsLook.DEFAULT_LOOK
	_text_size = _valid_text_size(int(str(state.get("text_size", 0)).to_float()))
	_sidebar_width = int(str(state.get("sidebar_width", 0)).to_float())
	_body.split_offset = _sidebar_width
	_database_id = str(state.get("database", ""))
	_versions = _dictionary(state.get("versions"))
	_languages = _dictionary(state.get("languages"))
	_last_pages = _dictionary(state.get("pages"))
	_folded = _dictionary(state.get("folded"))


func _dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySettingsPages

#^ Category display order (empty categories aren't shown):
const CATEGORIES := ["General", "Project", "Dialogue", "UI", "Shortcuts", "Theme"]		#/ translatable

static var _entries: Array = []
static var _defaults_registered: bool = false


static func register(id: String, title: String, category: String, source: Variant) -> void:
	for entry in _entries:
		if entry["id"] == id:
			entry["title"] = title
			entry["category"] = category
			entry["source"] = source
			return
	_entries.append({"id": id, "title": title, "category": category, "source": source})


static func entries() -> Array:
	ensure_defaults()
	return _entries


#* Get a category's pages, in registration order:
static func entries_in(category: String) -> Array:
	var result: Array = []
	for entry in entries():
		if str(entry["category"]) == category:
			result.append(entry)
	return result


static func create(id: String) -> CandySettingsPage:
	for entry in entries():
		if entry["id"] != id:
			continue
		var page = _instantiate(entry["source"])
		if page is CandySettingsPage:
			page.page_id = id
			page.page_title = str(entry["title"])
			page.page_category = str(entry["category"])
			return page
		if page != null:
			page.free()
		push_warning("CandySettingsPages: '%s' did not produce a CandySettingsPage" % id)
		return null
	return null


static func _instantiate(source: Variant) -> Node:
	if source is String:
		source = load(source)
	if source is PackedScene:
		return source.instantiate()
	if source is Script:
		return source.new()
	if source is Callable:
		return source.call()
	return null


static func ensure_defaults() -> void:
	if _defaults_registered:
		return
	_defaults_registered = true
	_register_defaults()


static func _register_defaults() -> void:
	register("general",
			"General", "General", CandyGeneralSettingsPage)		#/ translatable
	register("counters",
			"Counters", "General", CandyCountersSettingsPage)		#/ translatable
	register("save_load",
			"Save/Load", "General", CandySaveLoadSettingsPage)		#/ translatable
	register("project_paths",
			"Paths", "Project", CandyProjectPathsPage)		#/ translatable
	register("project_data",
			"Data", "Project", CandyProjectDataPage)		#/ translatable
	register("symbols",
			"Symbols", "Project", CandySymbolsPage)		#/ translatable
	register("languages_tags",
			"Languages & Tags", "Dialogue", CandyLanguagesTagsPage)		#/ translatable
	register("variations",
			"Variations", "Dialogue", CandyVariationsPage)		#/ translatable
	register("editor",
			"Editor", "UI", CandyEditorSettingsPage)		#/ translatable
	register("layouts",
			"Layouts", "UI", CandyLayoutsSettingsPage)		#/ translatable
	register("navigator_colors",
			"Navigator Colors", "UI", CandyNavigatorColorsPage)		#/ translatable
	register("navigator_modes",
			"Navigator Custom Mode", "UI", CandyNavigatorModesPage)		#/ translatable
	register("portrait_backgrounds",
			"Portrait Backgrounds", "UI", CandyPortraitBackgroundsPage)		#/ translatable
	register("language",
			"Language", "UI", CandyLanguageSettingsPage)		#/ translatable
	#Ł One page per shortcut group (a mod's actions can add one):
	var groups: Array = CandyShortcuts.GROUPS.duplicate()
	for action in CandyShortcuts.actions():
		if not groups.has(str(action["group"])):
			groups.append(str(action["group"]))
	for group in groups:
		var shortcut_id := "shortcuts_" + str(group).to_snake_case().replace("&", "and")
		register(shortcut_id, str(group), "Shortcuts", CandyShortcutsPage.for_group.bind(str(group)))
	register("theme",
			"Theme", "Theme", CandyThemeSettingsPage)		#/ translatable
	#Ł One page per page the theme options name:
	for page in CandyTheme.option_pages():
		var id := "theme_" + str(page).to_snake_case().replace("&", "and")
		register(id, str(page), "Theme", CandyThemeOptionsPage.for_page.bind(str(page)))
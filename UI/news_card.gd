#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNewsCard
extends PanelContainer

const CONTENT := "Margin/Content"
const REFRESH_TEXT := "Refresh"      #/ translatable
#^ How long Refresh shows the check's result:
const RESULT_SECONDS := 2.5
const RESULT_TEXTS := {
	CandyNews.Result.UPDATED: "Updated",      #/ translatable
	CandyNews.Result.UNCHANGED: "Up to date",      #/ translatable
	CandyNews.Result.FAILED: "Couldn't refresh",      #/ translatable
	CandyNews.Result.NO_SOURCE: "No news source",      #/ translatable
}
const CHECKING_TEXT := "Checking..."      #/ translatable
#^ Refresh's result when only some of the news could be downloaded:
const PARTLY_TEXT := "Partly refreshed"      #/ translatable
const NEW_ITEM_TOOLTIP := "You're reading this news for the first time."      #/ translatable
const UNREAD_AHEAD_TOOLTIP := "There's news you haven't read further on."      #/ translatable

@onready var _refresh_at_startup: CheckBox = get_node(CONTENT + "/TitleRow/RefreshAtStartup")
@onready var _refresh_button: Button = get_node(CONTENT + "/TitleRow/Refresh")
@onready var _text: RichTextLabel = get_node(CONTENT + "/Text")
@onready var _previous_button: Button = get_node(CONTENT + "/NavRow/Previous")
@onready var _next_button: Button = get_node(CONTENT + "/NavRow/Next")
#^ Unread marks - beside the title (the item shown is new), beside Next (unread items further on):
@onready var _new_item_mark: TextureRect = get_node(CONTENT + "/TitleRow/NewItem")
@onready var _unread_ahead_mark: TextureRect = get_node(CONTENT + "/NavRow/UnreadAhead")

var _news: CandyNews
var _items: Array = []						#/ [{id, text}]
var _index: int = 0
#^ The item shown was unread when it was first seen:
var _showing_new := false
#^ Check counter, so an older check's result doesn't reset a newer one's:
var _check_count: int = 0


func _ready() -> void:
	_news = CandyNews.new()
	_news.refreshed.connect(_on_refreshed)
	add_child(_news)

	_refresh_at_startup.set_pressed_no_signal(_news.refresh_at_startup())
	_refresh_at_startup.toggled.connect(_news.set_refresh_at_startup)
	_refresh_button.pressed.connect(_refresh)
	_previous_button.pressed.connect(_show_item.bind(-1))
	_next_button.pressed.connect(_show_item.bind(1))
	_text.meta_clicked.connect(_on_meta_clicked)
	_fit_refresh_button()
	_update_icons()

	#? An item counts as read once it's on screen, not while the landing screen is hidden.
	visibility_changed.connect(_mark_shown_item)
	_load_items()
	if _news.refresh_at_startup():
		_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _refresh_button != null:
		_fit_refresh_button()
		_update_icons()


func _refresh() -> void:
	if _news.is_busy():
		return
	_check_count += 1
	_refresh_button.text = CandyLocale.t(CHECKING_TEXT)
	_refresh_button.disabled = true
	_news.refresh()


func _on_refreshed(result: CandyNews.Result) -> void:
	_refresh_button.disabled = false
	_refresh_button.text = CandyLocale.t(str(RESULT_TEXTS.get(result, REFRESH_TEXT)))
	#? The failures, if any, in Refresh's tooltip:
	_refresh_button.tooltip_text = _news.problem
	if _news.problem != "" and result != CandyNews.Result.FAILED:
		_refresh_button.text = CandyLocale.t(PARTLY_TEXT)
	var check := _check_count
	get_tree().create_timer(RESULT_SECONDS).timeout.connect(func():
		if check == _check_count and not _news.is_busy():
			_refresh_button.text = CandyLocale.t(REFRESH_TEXT))
	if result == CandyNews.Result.UPDATED:
		_load_items()
	elif _items.is_empty():
		_show_placeholder(result)


#* Load the items, from the first:
func _load_items() -> void:
	_items = _news.items()
	_index = 0
	if _items.is_empty():
		_show_placeholder(-1)
	else:
		_show_item(0)


#* Show an item (step -1 = Previous, 1 = Next, 0 = current):
func _show_item(step: int) -> void:
	if _items.is_empty():
		return
	var new_index := clampi(_index + step, 0, _items.size() - 1)
	if new_index != _index or step == 0:
		_showing_new = false
	_index = new_index
	_text.text = CandyRemoteBBCode.without_resources(_items[_index]["text"])
	_previous_button.disabled = _index == 0
	_next_button.disabled = _index >= _items.size() - 1
	_mark_shown_item()


#* Show the no-news text:
func _show_placeholder(result: int) -> void:
	_showing_new = false
	_update_marks()
	_previous_button.disabled = true
	_next_button.disabled = true
	if not _news.has_source():
		_text.text = CandyLocale.t("No news source is set.")
	elif result == CandyNews.Result.FAILED:
		_text.text = _news.problem
	#? -1 = no check yet.
	elif result == -1 and not _news.refresh_at_startup():
		_text.text = CandyLocale.t("Press Refresh to download the news.")
	else:
		_text.text = CandyLocale.t("No news yet.")
		if _news.problem != "":
			_text.text += "\n" + _news.problem


#& Unread news

#* Remember the item shown as read, if it's on screen:
func _mark_shown_item() -> void:
	if is_visible_in_tree() and _index < _items.size():
		if _news.mark_read(_items[_index]["id"]):
			_showing_new = true
	_update_marks()


func _update_marks() -> void:
	_set_mark(_new_item_mark, _showing_new, CandyLocale.t(NEW_ITEM_TOOLTIP))
	var ahead := false
	var ids: PackedStringArray = _news.read_ids()
	for later in range(_index + 1, _items.size()):
		if not ids.has(_items[later]["id"]):
			ahead = true
			break
	_set_mark(_unread_ahead_mark, ahead, CandyLocale.t(UNREAD_AHEAD_TOOLTIP))


#* Hidden marks stay transparent rather than invisible, so the rows don't shift:
func _set_mark(mark: TextureRect, shown: bool, tooltip: String) -> void:
	if shown:
		mark.modulate.a = 1.0
		mark.tooltip_text = tooltip
	else:
		mark.modulate.a = 0.0
		mark.tooltip_text = ""


func _update_icons() -> void:
	var icon := get_theme_icon(&"unread", CandyThemeDefaults.ICONS)
	_new_item_mark.texture = icon
	_unread_ahead_mark.texture = icon


#* Open web links only:
func _on_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://") or url.begins_with("http://"):
		OS.shell_open(url)


#* Fit the Refresh button to its widest text, so the row doesn't move:
func _fit_refresh_button() -> void:
	var font := _refresh_button.get_theme_font(&"font")
	var font_size := _refresh_button.get_theme_font_size(&"font_size")
	var widest := 0.0
	for text in [REFRESH_TEXT, CHECKING_TEXT, PARTLY_TEXT] + RESULT_TEXTS.values():
		widest = maxf(widest, font.get_string_size(CandyLocale.t(str(text)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var box := _refresh_button.get_theme_stylebox(&"normal")
	_refresh_button.custom_minimum_size.x = ceilf(widest + box.get_minimum_size().x)

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Control


#* Apply the theme before any child is ready, so the first Areas are built with it:
func _enter_tree() -> void:
	theme = CandyTheme.theme
	CandyLocale.claim(self)


func _ready() -> void:
	var win := get_window()
	win.title = "Candy Dialogue Creator"
	win.min_size = Vector2i(640, 400)

	CandyProfiles.profile_opened.connect(_on_profile_opened)
	CandyProfiles.profile_closed.connect(_on_profile_closed)


func _on_profile_opened(user: String, profile: String) -> void:
	get_window().title = CandyLocale.t("Candy Dialogue Creator — {user} / {profile}").format({"user": user, "profile": profile})


func _on_profile_closed() -> void:
	get_window().title = "Candy Dialogue Creator"
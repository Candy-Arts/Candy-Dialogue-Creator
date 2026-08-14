extends PanelContainer




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#% Update the text to the latest version:
	$"Menu/VBox/RichTextLabel".text = "Candy Dialogue Creator\nOriginally created by Candy Arts.\n\nCandy Dialogue Creator is a standalone application for creating dialogues compatible with Candy Dialogue Engine.\n\nCandy Dialogue Creator is published under the MIT License and is free to use, distribute and modify, for any purposes, including commercial projects.\n\nDialogues created with Candy Dialogue Creator are not considered modifications or derivative works, and are not subject to the MIT License or any Candy Arts proprietary licenses.\n\nPlease provide feedback or report any issues on GitHub!\nSee our website for news, anouncements and more products.\n\n[font_size=12]Candy Dialogue Creator v" + globals.dc_version + " Official Release\nCreated by CANDY ARTS\nwww.candy-arts.com\nCopyright © 2026 Candy Arts[/font_size]"


#* Close the menu:
func _on_close_pressed() -> void:
	self.visible = false
	globals.editor_state = "Main"


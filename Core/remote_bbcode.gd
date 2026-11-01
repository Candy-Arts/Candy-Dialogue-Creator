#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyRemoteBBCode

static var _font_regex: RegEx = null
static var _dropcap_font_regex: RegEx = null
static var _image_regex: RegEx = null


#* Strip the tags that load a file:
static func without_resources(text: String) -> String:
	if _font_regex == null:
		_font_regex = RegEx.create_from_string("\\[font[= ][^\\]]*\\]")
		_dropcap_font_regex = RegEx.create_from_string("(\\[dropcap[^\\]]*?)\\s+font=[^\\s\\]]*")
		_image_regex = RegEx.create_from_string("\\[img[^\\]]*\\][^\\[]*\\[/img\\]")
	var out := _image_regex.sub(text, "", true)
	out = out.replace("[img", "[lb]img")
	out = _font_regex.sub(out, "", true)
	out = out.replace("[/font]", "")
	out = _dropcap_font_regex.sub(out, "$1", true)
	return out

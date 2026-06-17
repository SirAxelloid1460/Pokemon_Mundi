extends LineEdit

func _on_text_changed(new_text: String) -> void:
	text = new_text.to_upper()
	caret_column = text.length()

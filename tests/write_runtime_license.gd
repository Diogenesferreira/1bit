extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	var file := FileAccess.open("res://build/GODOT-LICENSE.txt", FileAccess.WRITE)
	file.store_string(Engine.get_license_text())
	file.store_string("\n\nTHIRD-PARTY COMPONENTS\n\n")
	file.store_string(JSON.stringify(Engine.get_copyright_info(), "\t"))
	file.store_string("\n\nTHIRD-PARTY LICENSES\n\n")
	file.store_string(JSON.stringify(Engine.get_license_info(), "\t"))
	file.close()
	quit()

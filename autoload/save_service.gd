extends Node

const SAVE_PATH := "user://ilha_digital_profile.json"

func _ready() -> void:
	# Os testes nunca carregam nem alteram a conta pessoal.
	if "--test" in OS.get_cmdline_user_args():
		return
	if FileAccess.file_exists(SAVE_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if data is Dictionary:
			PlayerProfile.restore(data)
	PlayerProfile.changed.connect(save_profile)

func save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		push_warning("Não foi possível salvar a conta: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(PlayerProfile.to_dictionary()))
	file.close()
	var result := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if result != OK:
		push_warning("Não foi possível concluir o salvamento: %s" % result)

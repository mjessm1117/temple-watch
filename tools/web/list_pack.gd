extends SceneTree

func _initialize() -> void:
    var path := OS.get_cmdline_user_args()[0]
    if not ProjectSettings.load_resource_pack(path):
        push_error("Could not open pack: " + path)
        quit(1)
        return
    _walk("res://")
    quit()

func _walk(dir_path: String) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        var full := dir_path.path_join(name)
        if dir.current_is_dir():
            _walk(full)
        else:
            var file := FileAccess.open(full, FileAccess.READ)
            if file != null:
                print(str(file.get_length()) + "\t" + full)
        name = dir.get_next()
    dir.list_dir_end()

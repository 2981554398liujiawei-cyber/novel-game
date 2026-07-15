extends Control

func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    if "--smoke-test" in args:
        print("SMOKE_TEST_OK")
        get_tree().quit(0)

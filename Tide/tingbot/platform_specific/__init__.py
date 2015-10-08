import platform

if platform.system() == 'Darwin':
    from osx import fixup_env, fixup_window, register_button_callback
else:
    from pi import fixup_env, fixup_window, register_button_callback

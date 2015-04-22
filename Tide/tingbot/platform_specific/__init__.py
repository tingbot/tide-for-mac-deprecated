import platform
from . import osx, pi

if platform.system() == 'Darwin':
    fixup_window = osx.fixup_window
    fixup_env = osx.fixup_env
else:
    fixup_window = lambda: None
    fixup_env = pi.fixup_env

import os


def fixup_env():
    os.environ["SDL_FBDEV"] = "/dev/fb1"

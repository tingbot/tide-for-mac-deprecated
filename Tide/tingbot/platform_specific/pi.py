import os


def fixup_env():
    os.environ["SDL_FBDEV"] = "/dev/fb1"

def fixup_window():
    import pygame.mouse
    pygame.mouse.set_visible(0)

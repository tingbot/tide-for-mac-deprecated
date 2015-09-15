import os


def fixup_env():
    import evdev
    os.environ["SDL_FBDEV"] = "/dev/fb1"

    mouse_path = None

    for device_path in evdev.list_devices():
        device = evdev.InputDevice(device_path)
        if device.name == "ADS7846 Touchscreen":
            mouse_path = device_path

    if mouse_path:
        os.environ["SDL_MOUSEDRV"] = "TSLIB"
        os.environ["SDL_MOUSEDEV"] = mouse_path
    else:
        print 'Mouse input device not found in /dev/input. Touch support not available.'

def fixup_window():
    import pygame.mouse
    pygame.mouse.set_visible(0)

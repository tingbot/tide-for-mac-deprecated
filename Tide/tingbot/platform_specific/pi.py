import os
import RPi.GPIO as GPIO


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

button_callback = None

def register_button_callback(callback):
    global button_callback
    ensure_button_setup()
    button_callback = callback

button_setup_done = False

def ensure_button_setup():
    global button_setup_done
    if not button_setup_done:
        button_setup()
    button_setup_done = True

button_pins = (11, 16, 18, 12)
button_pin_to_index = {
    11: 0,
    16: 1,
    18: 2,
    12: 3
}

def button_setup():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)

    for button_pin in button_pins:
        GPIO.setup(button_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
        GPIO.add_event_detect(button_pin, GPIO.BOTH, bouncetime=200, callback=GPIO_callback)

def GPIO_callback(pin):
    button_index = button_pin_to_index[pin]
    action = 'down' if GPIO.input(pin) else 'up'

    if button_callback is not None:
        button_callback(button_index, action)

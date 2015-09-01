import RPi.GPIO as GPIO
from .utils import CallbackList

class Button(object):
    def __init__(self, pin):
        self.pin = pin
        self.callbacks = CallbackList()

    def event(self):
        if GPIO.input(self.pin):
            self.was_pressed = True

    def run_callbacks_if_was_pressed(self):
        if self.was_pressed:
            self.callbacks()
            self.was_pressed = False

buttons = {
    'left': Button(11),
    'right': Button(12),
    'midleft': Button(16),
    'midright': Button(18),
}

class press(object):
    def __init__(self, button_name):
        ensure_setup()

        if button_name not in buttons:
            raise RuntimeError('Unknown button name "%s"' % button_name)

        self.button = buttons[button_name]

    def __call__(self, f):
        self.button.callbacks.add(f)
        return f

is_setup = False


def ensure_setup():
    global is_setup
    if not is_setup:
        setup()
    is_setup = True


def setup():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)

    for button in buttons.values():
        GPIO.setup(button.pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
        GPIO.add_event_detect(button.pin, GPIO.BOTH, bouncetime=200, callback=button.event)

    from .run_loop import main_run_loop
    main_run_loop.add_wait_callback(wait)


def wait():
    for button in buttons.values():
        button.run_callbacks_if_was_pressed()

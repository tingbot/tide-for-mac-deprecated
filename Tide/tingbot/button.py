import RPi.GPIO as GPIO
from .utils import CallbackList

class Button(object):
    def __init__(self, pin):
        self.pin = pin
        self.callbacks = CallbackList()

buttons = {
    'left': Button(11),
    'right': Button(12),
}

class press(object):
    def __init__(self, button_name):
        ensure_setup()

        if button_name not in buttons:
            raise RuntimeError('Unkown button name "%s"' % button_name)

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
        GPIO.add_event_detect(button.pin, GPIO.RISING, bouncetime=50)

    from .run_loop import main_run_loop
    main_run_loop.add_wait_callback(wait)


def wait():
    for button in buttons.values():
        if GPIO.event_detected(button.pin):
            button.callbacks()

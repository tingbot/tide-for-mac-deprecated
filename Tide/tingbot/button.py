from .utils import CallbackList

class Button(object):
    def __init__(self):
        self.callbacks = CallbackList()
        self.was_pressed = False

    def press(self):
        self.was_pressed = True

    def run_callbacks_if_was_pressed(self):
        if self.was_pressed:
            self.callbacks()
            self.was_pressed = False

buttons = {
    'left': Button(),
    'right': Button(),
    'midleft': Button(),
    'midright': Button(),
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
    from platform_specific import register_button_callback
    register_button_callback(button_callback)

    from .run_loop import main_run_loop
    main_run_loop.add_wait_callback(wait)

def button_callback(button_index, action):
    button_names = ('left', 'midleft', 'midright', 'right')
    button_name = button_names[button_index]
    button = buttons[button_name]

    if action == 'down':
        button.press()

def wait():
    for button in buttons.values():
        button.run_callbacks_if_was_pressed()

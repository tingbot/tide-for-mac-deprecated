from . import platform_specific, input

from .graphics import screen, Surface, Image
from .run_loop import main_run_loop, every
from .input import touch
from .button import press

platform_specific.fixup_env()


def run(loop=None):
    if loop is not None:
        every(seconds=1.0/30)(loop)

    main_run_loop.add_after_action_callback(screen.update_if_needed)

    main_run_loop.add_wait_callback(input.poll)
    # in case screen updates happen in input.poll...
    main_run_loop.add_wait_callback(screen.update_if_needed)

    main_run_loop.run()

__all__ = ['run', 'screen', 'Surface', 'Image', 'every', 'touch', 'press']

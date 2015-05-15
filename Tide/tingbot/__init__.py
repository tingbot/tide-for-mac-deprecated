from . import platform_specific, input

from .graphics import screen
from .run_loop import main_run_loop, every

platform_specific.fixup_env()


def run():
    main_run_loop.add_wait_callback(input.check_for_quit_event)
    main_run_loop.add_after_action_callback(screen.after_loop)

    main_run_loop.run()

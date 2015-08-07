import sys, operator, time, traceback
from .utils import Struct, CallbackList
from . import error

class Timer(Struct):
    pass


class every(object):
    def __init__(self, hours=0, minutes=0, seconds=0):
        self.period = (hours * 60 + minutes) * 60 + seconds

    def __call__(self, f):
        timer = Timer(name=f.__name__, action=f, period=self.period, repeating=True, next_fire_time=None)

        main_run_loop.schedule(timer)

        return f


class RunLoop(object):
    def __init__(self):
        self.timers = []
        self._wait_callbacks = CallbackList()
        self._before_action_callbacks = CallbackList()
        self._after_action_callbacks = CallbackList()

    def schedule(self, timer):
        if timer.next_fire_time is None:
            if timer.repeating:
                # if it's repeating, and it's never been called, call it now
                timer.next_fire_time = 0
            else:
                # call it after 'period'
                timer.next_fire_time = time.time() + self.period

        self.timers.append(timer)
        self.timers.sort(key=operator.attrgetter('next_fire_time'), reverse=True)

    def run(self):
        while True:
            start_time = time.time()
            next_timer = self.timers.pop()

            try:
                self._wait(next_timer.next_fire_time)

                self._before_action_callbacks()
                next_timer.action()
                self._after_action_callbacks()
            except Exception as e:
                self._error(e)
            finally:
                if next_timer.repeating:
                    next_timer.next_fire_time = start_time + next_timer.period
                    self.schedule(next_timer)

    def add_wait_callback(self, callback):
        self._wait_callbacks.add(callback)

    def add_before_action_callback(self, callback):
        self._before_action_callbacks.add(callback)

    def add_after_action_callback(self, callback):
        self._after_action_callbacks.add(callback)

    def _wait(self, until):
        self._wait_callbacks()

        while time.time() < until:
            time.sleep(0.001)
            self._wait_callbacks()

    def _error(self, exception):
        sys.stderr.write('\n' + str(exception) + '\n')

        traceback.print_exc()

        error.error_screen(sys.exc_info())
        time.sleep(0.5)


main_run_loop = RunLoop()

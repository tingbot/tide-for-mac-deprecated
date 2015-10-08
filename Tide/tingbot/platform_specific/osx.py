import os
from Cocoa import *
from Quartz import *
import objc
from ..utils import cached_property


class BackgroundImageView(NSImageView):
    def mouseDownCanMoveWindow(self):
        return True


class TingbotButton(NSView):
    def initWithFrame_buttonIndex_(self, frame, button_index):
        self = super(TingbotButton, self).initWithFrame_(frame)
        self.button_index = button_index
        self.is_down = False
        return self

    def drawRect_(self, rect):
        fill_rect = self.frame().copy()
        fill_rect.origin = CGPointZero

        NSColor.colorWithWhite_alpha_(0.3, 1.0).set()

        if self.is_down:
            fill_rect.size.height /= 2

        NSRectFill(fill_rect)

    def mouseDown_(self, event):
        self.is_down = True
        self.setNeedsDisplay_(True)

        if button_callback is not None:
            button_callback(self.button_index, 'down')

    def mouseUp_(self, event):
        self.is_down = False
        self.setNeedsDisplay_(True)

        if button_callback is not None:
            button_callback(self.button_index, 'up')


class WindowController(object):
    def __init__(self):
        app = NSApplication.sharedApplication()

        self.screen_window = app.windows()[0]

        self.screen_window.setStyleMask_(0)
        self.screen_window.setHasShadow_(False)

        frame = self.screen_window.frame()
        frame.origin = self.image_window.frame().origin
        frame.origin.x += 61
        frame.origin.y += 72
        self.screen_window.setFrame_display_(frame, False)

        self.image_window.makeKeyAndOrderFront_(None)
        self.image_window.addChildWindow_ordered_(self.screen_window, 1)

        def window_did_close(notification):
            app.terminate_(None)

        NSNotificationCenter.defaultCenter().addObserverForName_object_queue_usingBlock_(
            "NSWindowDidCloseNotification",
            self.image_window,
            None,
            window_did_close)

    @cached_property
    def image_window(self):
        rect = NSRect()
        rect.origin = self.screen_window.frame().origin
        rect.size.width = 470
        rect.size.height = 353

        view_rect = rect
        view_rect.origin = CGPointZero

        image_view = BackgroundImageView.alloc().initWithFrame_(view_rect)
        image = NSImage.alloc().initWithContentsOfFile_(os.path.join(os.path.dirname(__file__), 'bot.png'))
        image_view.setImage_(image)

        content_view = NSView.alloc().initWithFrame_(view_rect)

        for button in self.buttons:
            content_view.addSubview_(button)

        content_view.addSubview_(image_view)

        image_window = NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
            rect,
            0,
            2,
            False)

        image_window.setContentView_(content_view)
        image_window.setOpaque_(False)
        image_window.setBackgroundColor_(NSColor.clearColor())
        image_window.setHasShadow_(True)
        image_window.setMovableByWindowBackground_(True)

        image_window.setReleasedWhenClosed_(False)

        return image_window

    @cached_property
    def buttons(self):
        buttons = []
        xPositions = (60, 100, 320, 360)

        for i in xrange(0, 4):
            frame = CGRectMake(xPositions[i], 340, 22, 12)
            b = TingbotButton.alloc().initWithFrame_buttonIndex_(frame, i)
            buttons.append(b)

        return buttons


window_controller = None

def fixup_window():
    SDL_QuartzWindow = objc.lookUpClass('SDL_QuartzWindow')

    class SDL_QuartzWindow(objc.Category(SDL_QuartzWindow)):
        def canBecomeKeyWindow(self):
            return True

        def canBecomeMainWindow(self):
            return True

        def acceptsFirstResponder(self):
            return True

        def becomeFirstResponder(self):
            return True

        def resignFirstResponder(self):
            return True

    global window_controller
    window_controller = WindowController()


def fixup_env():
    from pygame import sdlmain_osx

    icon_file = os.path.join(os.path.dirname(__file__), 'simulator-icon.png')
    with open(icon_file) as f:
        icon_data = f.read()

    sdlmain_osx.InstallNSApplication(icon_data)

    NSUserDefaults.standardUserDefaults().setBool_forKey_(True, 'ApplePersistenceIgnoreState')

button_callback = None


def register_button_callback(callback):
    '''
    callback(button_index, action)
        button_index is a zero-based index that identifies which button has been pressed
        action is either 'down', or 'up'.

    The callback might not be called on the main thread.

    Currently only 'down' is implemented.
    '''
    global button_callback
    button_callback = callback

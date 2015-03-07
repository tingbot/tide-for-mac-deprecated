import os

def fixup_window():
    from Cocoa import NSApplication, NSWindow, NSImageView, NSImage, NSRect, NSColor

    app = NSApplication.sharedApplication()

    screen_window = app.windows()[0]

    screen_window.setStyleMask_(0)
    screen_window.setHasShadow_(False)

    # screen_window.setMovableByWindowBackground_(True)

    rect = NSRect()
    rect.size.width = 482
    rect.size.height = 333

    image_window = NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
        rect, 
        1+2+4+32768,
        2,
        False)

    view = NSImageView.alloc().init()
    image = NSImage.alloc().initWithContentsOfFile_(os.path.join(os.path.dirname(__file__), 'bot.png'))

    view.setImage_(image)
    image_window.setContentView_(view)
    image_window.setOpaque_(False)
    image_window.setAlphaValue_(1.0)
    image_window.setBackgroundColor_(NSColor.clearColor())
    image_window.setHasShadow_(True)
    # image_window.setMovable_(True)
    image_window.setMovableByWindowBackground_(True)
    
    image_window.setTitlebarAppearsTransparent_(True)
    image_window.makeKeyAndOrderFront_(None)

    image_window.addChildWindow_ordered_(screen_window, 1)
    image_window.setReleasedWhenClosed_(False)

    frame = screen_window.frame()
    frame.origin = image_window.frame().origin
    frame.origin.x += 64
    frame.origin.y += 65
    screen_window.setFrame_display_(frame, False)
    
    from Cocoa import NSNotificationCenter
    
    def window_did_close(notification):
        app.terminate_(None)

    NSNotificationCenter.defaultCenter().addObserverForName_object_queue_usingBlock_(
        "NSWindowDidCloseNotification",
        image_window,
        None,
        window_did_close)

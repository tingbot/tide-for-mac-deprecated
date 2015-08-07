import os
import pygame.image, pygame.transform, pygame.font
from . import graphics

sad_tingbot_string = '''
#########################
#                       #
#                       #
#   #################   #
#  #                 #  #
#  #                 #  #
#  #   # #     # #   #  #
#  #    #       #    #  #
#  #   # #     # #   #  #
#  #                 #  #
#  #      #  #       #  #
#  #       ##        #  #
#  #                 #  #
#  #      #####      #  #
#  #     #     ##    #  #
#  #             #   #  #
#  #                 #  #
#   #################   #
#                       #
#                       #
#########################
#                       #
#  ##                   #
#   #                   #
#                       #
#########################
'''.replace('\n', '')


def sad_tingbot_image():
    result = pygame.image.fromstring(sad_tingbot_string, (25, 26), 'P')
    result.set_palette_at(ord('#'), (0,0,0))
    result.set_palette_at(ord(' '), (255,255,255))

    result = pygame.transform.scale(result, (50, 52))

    return result


def error_screen(exc_info):
    surface = pygame.display.get_surface()
    if not surface:
        return

    screen = graphics.Surface(surface)

    screen.fill(color='black')

    image = graphics.Image(surface=sad_tingbot_image())

    screen.image(image, xy=(320/2, 85), align='center')

    line1 = type(exc_info[1]).__name__
    frame = get_app_frame(exc_info[2])
    filename = os.path.basename(frame.f_code.co_filename)
    line2 = '%s:%i' % (filename, frame.f_lineno)

    font = os.path.join(os.path.dirname(__file__), '04B_03__.TTF')

    screen.text(line1, xy=(320/2, 135), color='white', align='center', font=font, font_size=16)
    screen.text(line2, xy=(320/2, 155), color='white', align='center', font=font, font_size=16)

    pygame.display.update()


def get_app_frame(traceback):
    stack = []

    while traceback:
        stack.append(traceback)
        traceback = traceback.tb_next

    # stack now contains all the tracebacks up to the frame where the exception was raised

    # loop starting from the most recent call
    for traceback in reversed(stack):
        frame = traceback.tb_frame

        filename = frame.f_code.co_filename

        is_library_code = '/lib/' in filename or '/tingbot/' in filename or '/site-packages/' in filename

        if not is_library_code:
            return frame

    # if the whole stack is library code, return the most recent frame
    return stack[-1].tb_frame

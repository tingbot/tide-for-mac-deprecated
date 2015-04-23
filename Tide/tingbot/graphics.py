import pygame
import numbers
import operator
import itertools
import os
from . import platform_specific

color_map = {
    'white': (255,255,255),
    'black': (0,0,0),
}

def _xy_add(t1, t2):
    return (t1[0] + t2[0], t1[1] + t2[1])

def _xy_subtract(t1, t2):
    return (t1[0] - t2[0], t1[1] - t2[1])

def _xy_multiply(t1, t2):
    return (t1[0] * t2[0], t1[1] * t2[1])

def _color(identifier_or_tuple):
    try:
        return color_map[identifier_or_tuple]
    except KeyError:
        return identifier_or_tuple

def _scale(scale):
    """ Given a numeric input, return a 2-tuple with the number repeated.
        Given a 2-tuple input, return the input

    >>> _scale(2)
    (2, 2)
    >>> _scale((1, 2,))
    (1, 2)
    >>> _scale('nonsense')
    Traceback (most recent call last):
        ...
    TypeError: argument should be a number or a tuple
    >>> _scale((1,2,3))
    Traceback (most recent call last):
        ...
    ValueError: scale should be a 2-tuple
    """
    if isinstance(scale, tuple):
        if len(scale) != 2:
            raise ValueError('scale should be a 2-tuple')
        return scale
    elif isinstance(scale, numbers.Real):
        return (scale, scale)
    else:
        raise TypeError('argument should be a number or a tuple')


def _anchor(align):
    mapping = {
        'topleft': (0, 0),
        'left': (0, 0.5),
        'bottomleft': (0, 1),
        'top': (0.5, 0),
        'center': (0.5, 0.5),
        'bottom': (0.5, 1),
        'topright': (1, 0),
        'right': (1, 0.5),
        'bottomright': (1, 1),
    }

    return mapping[align]

class Surface(object):
    def __init__(self, surface):
        if not surface:
            raise TypeError()

        self.surface = surface

    @property
    def size(self):
        return self.surface.get_size()

    def fill(self, color):
        self.surface.fill(_color(color))

    def text(self, string, xy, color, align='topleft', font=None, font_size=32):
        if font is None:
            font = os.path.join(os.path.dirname(__file__), '04B_03__.TTF')
        font = pygame.font.Font(font, font_size)
        text_image = Image(surface=font.render(string, 1, _color(color)))

        self.image(text_image, xy, align=align)

    def rectangle(self, xy, size, color, align='topleft'):
        if len(size) != 2:
            raise ValueError('size should be a 2-tuple')

        anchor_offset = _xy_multiply(_anchor(align), size)
        xy = _xy_subtract(xy, anchor_offset)
    
        self.surface.fill(_color(color), xy+size)

    def image(self, image, xy, scale=1, align='topleft'):
        scale = _scale(scale)
        image_dimensions = image.size

        if scale != (1, 1):
            image_dimensions = _xy_multiply(image_dimensions, scale)
            image = pygame.transform.smoothscale(image, image_dimensions)

        anchor_offset = _xy_multiply(_anchor(align), image_dimensions)
        xy = _xy_subtract(xy, anchor_offset)

        self.surface.blit(image.surface, xy)


class Screen(Surface):
    def __init__(self):
        pygame.init()
        pygame.font.init()

        surface = pygame.display.set_mode((320, 240))

        platform_specific.fixup_window()

        super(Screen, self).__init__(surface)

    def update(self):
        pygame.display.update()

        self.needs_update = False

    def before_loop(self):
        self.needs_update = True

    def after_loop(self):
        if self.needs_update:
            self.update()


class Image(Surface):
    def __init__(self, surface=None, size=None):
        surface = surface or pygame.Surface(size)
        super(Image, self).__init__(surface)

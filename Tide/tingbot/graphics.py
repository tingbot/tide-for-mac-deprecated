import pygame
import numbers
import operator
import itertools
import os, time
from . import platform_specific
from .utils import cached_property

# colors from http://clrs.cc/
color_map = {
    'aqua': (127, 219, 255),
    'blue': (0, 116, 217),
    'navy': (0, 31, 63),
    'teal': (57, 204, 204),
    'green': (46, 204, 64),
    'olive': (61, 153, 112),
    'lime': (1, 255, 112),
    'yellow': (255, 220, 0),
    'orange': (255, 133, 27),
    'red': (255, 65, 54),
    'fuchsia': (240, 18, 190),
    'purple': (177, 13, 201),
    'maroon': (133, 20, 75),
    'white': (255, 255, 255),
    'silver': (221, 221, 221),
    'gray': (170, 170, 170),
    'grey': (170, 170, 170),
    'black': (0, 0, 0),
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

def _font(font, font_size, antialias):
    pygame.font.init()
    if font is None:
        font = os.path.join(os.path.dirname(__file__), 'Geneva.ttf')
        if antialias is None:
            antialias = (font_size < 9 or 17 < font_size)

    if antialias is None:
        antialias = True

    return pygame.font.Font(font, font_size), antialias

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

def _xy_from_align(align, surface_size):
    return _xy_multiply(surface_size, _anchor(align))

def _topleft_from_aligned_xy(xy, align, size, surface_size):
    if xy is None:
        xy = _xy_from_align(align, surface_size)

    anchor_offset = _xy_multiply(_anchor(align), size)
    return _xy_subtract(xy, anchor_offset)


class Surface(object):
    def __init__(self, surface=None):
        if surface is None:
            if not hasattr(self, '_create_surface'):
                raise TypeError('surface must not be nil')
        else:
            self.surface = surface

    @cached_property
    def surface(self):
        ''' this function is only called once if a surface is not set in the constructor '''
        surface = self._create_surface()

        if not surface:
            raise TypeError('_create_surface should return a pygame Surface')

        return surface

    @property
    def size(self):
        return self.surface.get_size()

    def fill(self, color):
        self.surface.fill(_color(color))

    def text(self, string, xy=None, color='grey', align='center', font=None, font_size=32, antialias=None):
        font, antialias = _font(font, font_size, antialias)
        string = str(string)

        if antialias is None:
            antialias

        text_image = Image(surface=font.render(string, antialias, _color(color)))

        self.image(text_image, xy, align=align)

    def rectangle(self, xy=None, size=(100, 100), color='grey', align='center'):
        if len(size) != 2:
            raise ValueError('size should be a 2-tuple')

        xy = _topleft_from_aligned_xy(xy, align, size, self.size)

        self.surface.fill(_color(color), xy+size)

    def image(self, image, xy=None, scale=1, align='center'):
        scale = _scale(scale)
        image_size = image.size

        surface = image.surface

        if scale != (1, 1):
            image_size = _xy_multiply(image_size, scale)
            image_size = tuple(int(d) for d in image_size)
            try:
                surface = pygame.transform.smoothscale(surface, image_size)
            except ValueError:
                surface = pygame.transform.scale(surface, image_size)

        xy = _topleft_from_aligned_xy(xy, align, image_size, self.size)

        self.surface.blit(surface, xy)


class Screen(Surface):
    def _create_surface(self):
        pygame.init()
        surface = pygame.display.set_mode((320, 240))
        platform_specific.fixup_window()
        return surface

    def update(self):
        pygame.display.update()
        self.needs_update = False

    def fill(self, *args, **kwargs):
        super(Screen, self).fill(*args, **kwargs)
        self.needs_update = True

    def text(self, *args, **kwargs):
        super(Screen, self).text(*args, **kwargs)
        self.needs_update = True

    def rectangle(self, *args, **kwargs):
        super(Screen, self).rectangle(*args, **kwargs)
        self.needs_update = True

    def image(self, *args, **kwargs):
        super(Screen, self).image(*args, **kwargs)
        self.needs_update = True

    def after_loop(self):
        if self.needs_update:
            self.update()


screen = Screen()


class Image(Surface):
    @classmethod
    def load(cls, filename):
        # if it's a gif, load it using the special GIFImage class
        _, extension = os.path.splitext(filename)
        if extension.lower() == '.gif':
            return GIFImage(filename=filename)

        pygame.init()
        surface = pygame.image.load(filename)
        surface = surface.convert_alpha()

        return cls(surface)

    def __init__(self, surface=None, size=None):
        pygame.init()
        surface = surface or pygame.Surface(size)
        super(Image, self).__init__(surface)


class GIFImage(Surface):
    def __init__(self, filename):
        pygame.init()
        from PIL import Image as PILImage
        self.frames = self._get_frames(PILImage.open(filename))
        self.total_duration = sum(f[1] for f in self.frames)

    def _get_frames(self, pil_image):
        result = []

        pal = pil_image.getpalette()
        base_palette = []
        for i in range(0, len(pal), 3):
            rgb = pal[i:i+3]
            base_palette.append(rgb)

        all_tiles = []
        try:
            while 1:
                if not pil_image.tile:
                    pil_image.seek(0)
                if pil_image.tile:
                    all_tiles.append(pil_image.tile[0][3][0])
                pil_image.seek(pil_image.tell()+1)
        except EOFError:
            pil_image.seek(0)

        all_tiles = tuple(set(all_tiles))

        while 1:
            try:
                duration = pil_image.info["duration"] * 0.001
            except KeyError:
                duration = 0.1

            if all_tiles:
                if all_tiles in ((6,), (7,)):
                    pal = pil_image.getpalette()
                    palette = []
                    for i in range(0, len(pal), 3):
                        rgb = pal[i:i+3]
                        palette.append(rgb)
                elif all_tiles in ((7, 8), (8, 7)):
                    pal = pil_image.getpalette()
                    palette = []
                    for i in range(0, len(pal), 3):
                        rgb = pal[i:i+3]
                        palette.append(rgb)
                else:
                    palette = base_palette
            else:
                palette = base_palette

            pygame_image = pygame.image.fromstring(pil_image.tostring(), pil_image.size, pil_image.mode)
            pygame_image.set_palette(palette)

            if "transparency" in pil_image.info:
                pygame_image.set_colorkey(pil_image.info["transparency"])

            result.append([pygame_image, duration])
            try:
                pil_image.seek(pil_image.tell()+1)
            except EOFError:
                break

        return result

    @property
    def surface(self):
        current_time = time.time()

        if not hasattr(self, 'start_time'):
            self.start_time = current_time

        gif_time = (current_time - self.start_time) % self.total_duration

        frame_time = 0

        for surface, duration in self.frames:
            frame_time += duration

            if frame_time >= gif_time:
                return surface

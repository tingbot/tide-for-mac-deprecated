import pygame
import sys
from collections import namedtuple
from .utils import call_with_optional_arguments

mouse_down = False
hit_areas = []
active_hit_areas = []

HitArea = namedtuple('HitArea', ('rect', 'callback'))

def poll():
    if not pygame.display.get_init():
        return

    for event in pygame.event.get():
        if event.type == pygame.MOUSEBUTTONDOWN:
            mouse_down(pygame.mouse.get_pos())

        elif event.type == pygame.MOUSEMOTION:
            mouse_move(pygame.mouse.get_pos())

        elif event.type == pygame.MOUSEBUTTONUP:
            mouse_up(pygame.mouse.get_pos())

        elif event.type == pygame.KEYDOWN:
            command_down = (event.mod & 1024) or (event.mod & 2048)

            if event.key == 113 and command_down:
                sys.exit()

        elif event.type == pygame.QUIT:
            sys.exit()

def mouse_down(pos):
    for hit_area in hit_areas:
        if hit_area.rect.collidepoint(pos):
            active_hit_areas.append(hit_area)
            call_with_optional_arguments(hit_area.callback, xy=pos, action='down')

def mouse_move(pos):
    for hit_area in active_hit_areas:
        call_with_optional_arguments(hit_area.callback, xy=pos, action='move')

def mouse_up(pos):
    for hit_area in active_hit_areas:
        call_with_optional_arguments(hit_area.callback, xy=pos, action='up')

    active_hit_areas[:] = []

class touch(object):
    def __init__(self, xy, size=(50, 50), align='center'):
        from .graphics import _topleft_from_aligned_xy, screen

        topleft = _topleft_from_aligned_xy(xy=xy, align=align, size=size, surface_size=screen.size)

        self.rect = pygame.Rect(topleft, size)

    def __call__(self, f):
        hit_areas.append(HitArea(self.rect, f))
        return f

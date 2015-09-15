import pygame
import sys
from collections import namedtuple

mouse_down = False
hit_areas = []
active_hit_areas = []

HitArea = namedtuple('HitArea', ('rect', 'callback'))

def check_for_quit_event():
    if not pygame.display.get_init():
        return

    for event in pygame.event.get():
        if event.type == pygame.MOUSEBUTTONDOWN:
            mouse_down(pygame.mouse.get_pos())

        elif event.type == pygame.MOUSEMOTION:
            mouse_move(pygame.mouse.get_pos())

        elif event.type == pygame.MOUSEBUTTONUP:
            mouse_up(pygame.mouse.get_pos())

        elif event.type == pygame.QUIT:
            sys.exit()

def mouse_down(pos):
    for hit_area in hit_areas:
        if hit_area.rect.collidepoint(pos):
            active_hit_areas.append(hit_area)

    mouse_move(pos)

def mouse_move(pos):
    for hit_area in active_hit_areas:
        hit_area.callback(pos)

def mouse_up(pos):
    active_hit_areas[:] = []

class touch(object):
    def __init__(self, xy, size=(50, 50), align='center'):
        from .graphics import _topleft_from_aligned_xy, screen

        topleft = _topleft_from_aligned_xy(xy=xy, align=align, size=size, surface_size=screen.size)

        self.rect = pygame.Rect(topleft, size)

    def __call__(self, f):
        hit_areas.append(HitArea(self.rect, f))
        return f

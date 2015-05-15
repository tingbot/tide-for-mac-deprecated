import pygame
import sys


def check_for_quit_event():
    if not pygame.display.get_init():
        return

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            sys.exit()

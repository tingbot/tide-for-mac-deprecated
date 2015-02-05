import pygame
import sys

class Input(object):
    def loop(self):
        self.check_for_quit_event()

    def during_wait(self):
        self.check_for_quit_event()

    def check_for_quit_event(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT: sys.exit()


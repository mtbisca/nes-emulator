import pygame
import numpy as np
from ppu.sprites_group import Sprites_Group
from ppu.color_handler import ColorHandler

chrsize = 0

        
class PPU:

    def __init__(self, pattern_tables, mirror, scale_size):
        # initializing ppu memory
        self.VRAM = np.zeros(0x10000, dtype=np.uint8)
        self.VRAM[:0x2000] = pattern_tables
        self.SPR_RAM = np.zeros(0x0100, dtype=np.uint8)
        self.scale_size = scale_size

        self.sprite_palettes = []
        self.bg_palettes = []

        # add this address for every write in ppu
        self.address_mirror = 0x400 << mirror
        self.width = 256
        self.height = 224
        self.color = (1,1,1)

        pygame.init()
        self.all_sprites = Sprites_Group()
        # self.all_sprites.set_all_positions(((0,0),(50,0), (0,50), (50,50), (25,25)))
        self.screen = pygame.display.set_mode((self.scale_size*self.width, self.scale_size*self.height))
        self.pic = pygame.surface.Surface((self.width, self.width))
        self.all_sprites.draw(self.pic)
        self.screen.blit(pygame.transform.scale(self.pic, (self.scale_size * self.width, self.scale_size * self.height)), (0, 0))

        self.update()

    def update(self):
        # pygame.event.pump()
        # event = pygame.event.wait()
        # if event.type == pygame.QUIT:
        #     pygame.display.quit()
        #     return False
        self.color_handler = ColorHandler(self.VRAM)
        self.pic = pygame.surface.Surface((self.width, self.width))
        # Update parts of PPU
        self.update_sprites()

        # Rescale screen and update
        self.screen.blit(pygame.transform.scale(self.pic, (self.scale_size * self.width, self.scale_size * self.height)), (0, 0))
        pygame.display.update()

    def update_sprites(self):
        sprites_data = np.reshape(self.SPR_RAM, (64, 4))
        self.all_sprites.update_sprites(self.VRAM[0x0:0x1000], self.VRAM[0x3f10:0x3f20], sprites_data, self.color_handler)
        self.all_sprites.draw(self.pic)

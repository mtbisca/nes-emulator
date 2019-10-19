import pygame
import numpy as np

chrsize = 0

        
class PPU:
    

    def __init__(self, pattern_table, mirror, size):

        #initializing ppu memory
        self.VRAM = np.zeros(0x10000)
        self.init_memory()

        self.sprite_palettes = []
        self.bg_palettes = []

        #chr-rom size
        self.chrsize = len(pattern_table)

        #add this address for every write in ppu
        self.address_mirror = 0x400 << mirror
        self.width = 256
        self.height = 224
        self.color = (1,1,1)

        pygame.init()
        self.screen = pygame.display.set_mode((size*self.width, size*self.height))
        self.fake_screen = pygame.display.set_mode((self.width, self.height))
        self.screen.blit(pygame.transform.scale(self.fake_screen, (size*self.width, size*self.height)))
        self.pic = pygame.surface.Surface((50, 50))
        self.pic.fill((0, 0, 0))
        # self.screen = pygame.display.set_mode((self.width, self.height))
        self.screen.fill(self.color)
        pygame.draw.rect(self.screen, (255, 0, 0), (0, 0, 50, 50))
        pygame.display.flip()

    
    def init_memory(self):
        for i in range(chrsize):
            self.VRAM[i] = pattern_table[i]

    def load_palettes(self):
        self.bg_palettes = np.array_split(self.VRAM[0X3F00:0x3F10], 4)
        self.sprite_palettes = np.array_split(self.VRAM[0X3F10:0x3F20], 4)
    
    def load_attribute_table(self):
        pass
    

    def update(self):
        pygame.event.pump()
        event = pygame.event.wait()
        if event.type == pygame.QUIT:
            pygame.display.quit()


        pygame.display.flip()

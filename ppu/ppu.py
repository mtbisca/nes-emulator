import pygame

chrsize = 0

        
class PPU:
    
    def __init__(self, chr, mirror):

        #initializing ppu memory
        self.VRAM = [0] * 0x10000
        self.initMemory()

        #chr-rom size
        self.chrsize = len(chr)

        #add this address for every write in ppu
        self.address_mirror = 0x400 << mirror
        self.width = 256
        self.height = 240
        self.color = (1,1,1)

        pygame.init()
        self.screen = pygame.display.set_mode((self.width, self.height))
        self.screen.fill(self.color)
        pygame.display.flip()

    
    def initMemory(self):
        for i in range(chrsize):
            self.VRAM[i] = chr[i]

        

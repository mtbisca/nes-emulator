import pygame

chrsize = 0

        
class ppu:
    
    def __init__(self, chr, mirror):
        self.VRAM = [0] * 0x10000
        self.initMemory()
        self.chrsize = len(chr)

        #add this address for every write in ppu
        self.address_mirror = 0x400 << mirror
        print(self.VRAM)
        print(self.address_mirror)
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

        

import pygame
import numpy as np
from ppu.sprites_group import Sprites_Group

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

        # Flags controlling PPU operation
        # TODO: check if there's a default configuration of these flags
        self.nametable_address = None
        self.increment_address = None
        self.sprite_pattern_table_address = None
        self.background_pattern_table_address = None
        self.sprite_size = None
        self.master_slave = None
        self.nmi_at_vblank = None

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

    def write_ppuctrl(self, value):
        """
        7  bit  0
        ---- ----
        VPHB SINN
        |||| ||||
        |||| ||++- Base nametable address
        |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
        |||| |+--- VRAM address increment per CPU read/write of PPUDATA
        |||| |     (0: add 1, going across; 1: add 32, going down)
        |||| +---- Sprite pattern table address for 8x8 sprites
        ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
        |||+------ Background pattern table address (0: $0000; 1: $1000)
        ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
        |+-------- PPU master/slave select
        |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
        +--------- Generate an NMI at the start of the
                   vertical blanking interval (0: off; 1: on)
        """
        index = value & 3
        if index == 0:
            self.nametable_address = 0x2000
        elif index == 1:
            self.nametable_address = 0x2400
        elif index == 2:
            self.nametable_address = 0x2800
        elif index == 3:
            self.nametable_address = 0x2C00

        remaining_value = value >> 2
        if remaining_value & 1:
            self.increment_address = 32
        else:
            self.increment_address = 1

        remaining_value >>= 1
        if remaining_value & 1:
            self.sprite_pattern_table_address = 0x1000
        else:
            self.sprite_pattern_table_address = 0x0000

        remaining_value >>= 1
        if remaining_value & 1:
            self.background_pattern_table_address = 0x1000
        else:
            self.background_pattern_table_address = 0x0000

        remaining_value >>= 1
        if remaining_value & 1:
            self.sprite_size = (8, 16)
        else:
            self.sprite_size = (8, 8)

        remaining_value >>= 1
        if remaining_value & 1:
            self.master_slave = 1
        else:
            self.master_slave = 0

        remaining_value >>= 1
        if remaining_value & 1:
            self.nmi_at_vblank = 1
        else:
            self.nmi_at_vblank = 0

    def load_palettes(self):
        self.bg_palettes = np.array_split(self.VRAM[0X3F00:0x3F10], 4)
        self.sprite_palettes = np.array_split(self.VRAM[0X3F10:0x3F20], 4)
    
    def load_attribute_table(self):
        pass

    def update(self):
        # pygame.event.pump()
        # event = pygame.event.wait()
        # if event.type == pygame.QUIT:
        #     pygame.display.quit()
        #     return False

        self.pic = pygame.surface.Surface((self.width, self.width))
        # Update parts of PPU
        self.update_sprites()

        # Rescale screen and update
        self.screen.blit(pygame.transform.scale(self.pic, (self.scale_size * self.width, self.scale_size * self.height)), (0, 0))
        pygame.display.update()

    def update_sprites(self):
        sprites_data = np.reshape(self.SPR_RAM, (64, 4))
        self.all_sprites.update_sprites(self.VRAM[0x0:0x1000], self.VRAM[0x3f10:0x3f20], sprites_data)
        self.all_sprites.draw(self.pic)


import pygame
import numpy as np
from ppu.sprites_group import SpritesGroup
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

        # Flags controlling PPU operation
        # TODO: check if there's a default configuration of these flags
        self.nametable_address = None
        self.increment_address = None
        self.sprite_pattern_table = 0
        self.background_pattern_table = None
        self.sprite_size = [8,8]
        self.master_slave = None
        self.nmi_at_vblank = 1

        # Flags controlling the rendering of sprites and background, as well as
        # color effects
        # TODO: check if there's a default configuration of these flags
        self.greyscale = None
        self.clipping_background_on_left = None
        self.clipping_sprites_on_left = None
        self.show_background = None
        self.show_sprites = False
        self.red_emphasis = None
        self.green_emphasis = None
        self.blue_emphasis = None

        self.first_write = True

        self.sprite_overflow = 0
        self.sprite_0_hit = 0
        self.vblank = 1

        # add this address for every write in ppu
        self.address_mirror = 0x400 << mirror
        self.width = 256
        self.height = 224
        self.color = (1,1,1)

        pygame.init()
        self.all_sprites = SpritesGroup(self.sprite_size)
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
        self.sprite_pattern_table = remaining_value & 1

        remaining_value >>= 1
        self.background_pattern_table = remaining_value & 1

        remaining_value >>= 1
        if remaining_value & 1:
            self.sprite_size = (8, 8)
        else:
            self.sprite_size = (8, 16)

        remaining_value >>= 1
        if remaining_value & 1:
            self.master_slave = 1
        else:
            self.master_slave = 0

        remaining_value >>= 1
        if remaining_value & 1:
            self.nmi_at_vblank = True
        else:
            self.nmi_at_vblank = False

    def write_ppumask(self, value):
        """
        7  bit  0
        ---- ----
        BGRs bMmG
        |||| ||||
        |||| |||+- Greyscale (0: normal color, 1: produce a greyscale display)
        |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
        |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
        |||| +---- 1: Show background
        |||+------ 1: Show sprites
        ||+------- Emphasize red
        |+-------- Emphasize green
        +--------- Emphasize blue
        """
        if value & 1:
            self.greyscale = True
        else:
            self.greyscale = False

        remaining_value = value >> 1
        if remaining_value & 1:
            self.clipping_background_on_left = True
        else:
            self.clipping_background_on_left = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.clipping_sprites_on_left = True
        else:
            self.clipping_sprites_on_left = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.show_background = True
        else:
            self.show_background = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.show_sprites = True
        else:
            self.show_sprites = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.red_emphasis = True
        else:
            self.red_emphasis = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.green_emphasis = True
        else:
            self.green_emphasis = False

        remaining_value >>= 1
        if remaining_value & 1:
            self.blue_emphasis = True
        else:
            self.blue_emphasis = False

    def read_ppustatus(self):
        """
        7  bit  0
        ---- ----
        VSO. ....
        |||| ||||
        |||+-++++- Least significant bits previously written into a PPU register
        |||        (due to register not being updated for this address)
        ||+------- Sprite overflow. The intent was for this flag to be set
        ||         whenever more than eight sprites appear on a scanline, but a
        ||         hardware bug causes the actual behavior to be more complicated
        ||         and generate false positives as well as false negatives; see
        ||         PPU sprite evaluation. This flag is set during sprite
        ||         evaluation and cleared at dot 1 (the second dot) of the
        ||         pre-render line.
        |+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
        |          a nonzero background pixel; cleared at dot 1 of the pre-render
        |          line.  Used for raster timing.
        +--------- Vertical blank has started (0: not in vblank; 1: in vblank).
                   Set at dot 1 of line 241 (the line *after* the post-render
                   line); cleared after reading $2002 and at dot 1 of the
                   pre-render line.
        """
        value = 0
        value |= self.vblank
        value <<= 1
        value |= self.sprite_0_hit
        value <<= 1
        value |= self.sprite_overflow
        value <<= 5
        self.vblank = 1

        return value

    def write_oamaddr(self):
        pass

    def write_scroll(self, value):
        if self.first_write:
            self.ppu_scroll_x = value
            self.first_write = False
        else:
            self.ppu_scroll_y = value
            self.first_write = True

    def write_address(self, value):
        pass

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
        self.color_handler = ColorHandler(self.VRAM)
        self.pic = pygame.surface.Surface((self.width, self.width))
        # Update parts of PPU
        pattern_table_map = np.split(self.VRAM[0x0:0x2000], 2)
        if self.show_sprites:
            self.update_sprites(pattern_table_map)

        # Rescale screen and update
        self.screen.blit(pygame.transform.scale(self.pic, (self.scale_size * self.width, self.scale_size * self.height)), (0, 0))
        pygame.display.update()
        return

    def update_sprites(self, pattern_table_map):
        sprites_data = np.reshape(self.SPR_RAM, (64, 4))
        self.all_sprites.update_sprites(pattern_table_map, sprites_data, self.color_handler, self.sprite_pattern_table)
        self.all_sprites.draw(self.pic)

    def write_spr_ram_dma(self, ram):
        self.SPR_RAM[:] = ram
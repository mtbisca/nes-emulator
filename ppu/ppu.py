import pygame
import numpy as np
from ppu.sprites_group import SpritesGroup
from ppu.color_handler import ColorHandler
from ppu.background import Background
from enum import Enum

class Mirroring(Enum):
    HORIZONTAL = 0
    VERTICAL = 1


class PPU:

    def __init__(self, pattern_tables, mirroring_type, scale_size):
        # initializing ppu memory
        self.VRAM = np.zeros(0x10000, dtype=np.uint8)
        self.VRAM[:0x2000] = pattern_tables
        self.tiles_map = self.make_tile_map(pattern_tables)
        self.SPR_RAM = np.zeros(0x0100, dtype=np.uint8)
        self.scale_size = scale_size

        self.buffer = 0

        self.sprite_palettes = []
        self.bg_palettes = []

        # Flags controlling PPU operation
        self.nametable_address = None
        self.increment_address = None
        self.sprite_pattern_table = None
        self.all_sprites = None
        self.background_pattern_table = None
        self.master_slave = None
        self.nmi_at_vblank = 1

        # Flags controlling the rendering of sprites and background, as well as
        # color effects
        self.greyscale = None
        self.clipping_background_on_left = None
        self.clipping_sprites_on_left = None
        self.show_background = None
        self.show_sprites = False
        self.red_emphasis = None
        self.green_emphasis = None
        self.blue_emphasis = None

        # $2005 and $2006 share a common write toggle, so that the first write
        # has one behaviour, and the second write has another.
        # After the second write, the toggle is reset to the first write
        # behaviour. This toggle may be manually reset by reading $2002
        self.first_write = True
        self.oam_addr = 0

        self.sprite_overflow = 0
        self.sprite_0_hit = 0
        self.vblank = 1

        # PPU internal registers
        self.curr_vram_address = 0
        self.tmp_vram_address = 0  # address of the top left onscreen tile
        self.fine_x_scroll = 0

        self.mirroring_type = Mirroring(mirroring_type)
        self.width = 256
        self.height = 224
        self.color = (1, 1, 1)

        self.should_update = True

        pygame.init()
        self.screen = pygame.display.set_mode(
            (self.scale_size * self.width, self.scale_size * self.height))
        self.background = Background()

    def make_tile_map(self, full_pattern_table):
        tiles_map = []
        for index in range(0x200):
            low_bytes = full_pattern_table[index * 16:
                                           (index * 16) + 8]
            high_bytes = full_pattern_table[(index * 16) + 8:
                                            (index + 1) * 16]

            low_bytes = np.reshape(np.unpackbits(low_bytes, axis=0), (8, 8))
            high_bytes = np.reshape(np.unpackbits(high_bytes, axis=0), (8, 8))

            # Contains indexes to the frame palette
            tile = (high_bytes << 1) | low_bytes
            tiles_map.append(tile.transpose())
        return np.array(tiles_map)

    #######################   WRITE FUNCTIONS   #######################

    # Register 0x2000
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

        7  bit  0
        ---- ----
        .... ..YX
               ||
               |+- 1: Add 256 to the X scroll position
               +-- 1: Add 240 to the Y scroll position
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
            self.all_sprites = SpritesGroup(sprite_size=(8, 16))
        else:
            self.all_sprites = SpritesGroup(sprite_size=(8, 8))

        remaining_value >>= 1
        self.master_slave = remaining_value & 1

        remaining_value >>= 1
        self.nmi_at_vblank = bool(remaining_value & 1)

        # Insert the two least significant bits into bits 10-11
        # http://wiki.nesdev.com/w/index.php/PPU_scrolling#Register_controls
        self.tmp_vram_address &= 0b111001111111111
        self.tmp_vram_address |= (index << 10)

    # Register 0x2001
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

    # Register 0x2003
    def write_oamaddr(self, value):
        self.oam_addr = value

    # Register 0x2004
    def write_oamdata(self, value):
        self.SPR_RAM[self.oam_addr] = value
        self.oam_addr = (self.oam_addr + 1) & 0xFF

    # Register 0x2005
    def write_scroll(self, value):
        if self.first_write is True:
            # tmp_vram_address: ....... ...HGFED = d: HGFED...
            # fine_x_scroll:                 CBA = d: .....CBA
            self.tmp_vram_address &= 0b111111111100000
            self.tmp_vram_address |= value >> 3
            self.fine_x_scroll = value & 0b111
        else:
            # tmp_vram_address: CBA..HG FED..... = d: HGFEDCBA
            self.tmp_vram_address &= 0b000110000011111
            self.tmp_vram_address |= (value & 0b111) << 12
            self.tmp_vram_address |= (value & 0b11111000) << 2
        self.first_write = not self.first_write

    # Register 0x2006
    def write_address(self, value):
        if self.first_write is True:
            # tmp_vram_address: .FEDCBA ........ = d: ..FEDCBA
            # tmp_vram_address: X...... ........ = 0
            self.tmp_vram_address &= 0b000000011111111
            self.tmp_vram_address |= (value & 0b111111) << 8
            self.curr_vram_address = np.uint16((value & 0xFF) << 8)
        else:
            # tmp_vram_address: ....... HGFEDCBA = d: HGFEDCBA
            self.tmp_vram_address &= 0b111111100000000
            self.tmp_vram_address |= value
            self.curr_vram_address = self.tmp_vram_address
        self.first_write = not self.first_write

    # Register 0x2007
    def write_data(self, value):

        address = self.curr_vram_address & 0b11111111111111

        # Write in the pattern table
        if address < 0x2000:
            self.VRAM[address] = value

        # Write in the nametable with mirroring
        elif address < 0x3000:
            if self.mirroring_type == Mirroring.VERTICAL:
                if address > 0x2800:
                    self.VRAM[address - 0x800] = value
                else:
                    self.VRAM[address] = value
            elif self.mirroring_type == Mirroring.HORIZONTAL:
                if address < 0x2400 or (0x2800 <= address < 0x2C00):
                    self.VRAM[address] = value
                else:
                    self.VRAM[address - 0x400] = value

        # Write in the memory with mirroring
        # 0x3000-0x3EFF mirrors 0x2000-0x2EFF
        elif address < 0x3F00:
            self.VRAM[address & 0x2EFF] = value
        # TODO: check if necessary
        elif address == 0x3F10:
            self.VRAM[0x3F00] = value
        elif address == 0x3F14:
            self.VRAM[0x3F04] = value
        elif address == 0x3F18:
            self.VRAM[0x3F08] = value
        elif address == 0x3F1C:
            self.VRAM[0x3F0C] = value
        # 0x3F20-0x3FFF mirrors 0x3F00-0x3F1F
        elif 0x3F20 <= address < 0x4000:
            self.VRAM[address & 0x3F1F] = value

        # 0x4000-0x10000 mirrors 0x0000-0x3FFF
        else:
            self.VRAM[address & 0x3FFF] = value

        self.curr_vram_address += self.increment_address

    #######################   READ FUNCTIONS   #######################
    # Register 0x2002
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
        self.first_write = True

        return value

    # Register 0x2007
    def read_data(self):
        value = 0
        address = self.curr_vram_address & 0b11111111111111

        # Read from pattern table
        if address < 0x2000:
            value = self.buffer
            self.buffer = self.VRAM[address % 0x800]

        # Read from nametable
        elif address < 0x3000:
            value = self.buffer
            if self.mirroring_type == Mirroring.VERTICAL:
                if address > 0x2800:
                    self.buffer = self.VRAM[address - 0x800]
                else:
                    self.buffer = self.VRAM[address]
            elif self.mirroring_type == Mirroring.HORIZONTAL:
                if address < 0x2400 or (0x2800 <= address < 0x2C00):
                    self.buffer = self.VRAM[address]
                else:
                    self.buffer = self.VRAM[address - 0x400]

        # Read from the memory
        # 0x3000-0x3EFF mirrors 0x2000-0x2EFF
        elif address < 0x3F00:
            value = self.buffer
            self.buffer = self.VRAM[address & 0x2EFF]
        elif address < 0x3F20:
            value = self.buffer
            self.buffer = self.VRAM[address]
        # 0x3F20-0x3FFF mirrors 0x3F00-0x3F1F
        elif address < 0x4000:
            value = self.VRAM[address]
            self.buffer = self.VRAM[address & 0x3F1F]
        return value

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
        if not self.should_update:
            self.should_update = True
            return
        else:
            self.should_update = False
        self.color_handler = ColorHandler(self.VRAM)
        self.pic = pygame.surface.Surface((self.width, self.width))
        # Update parts of PPU
        # pattern_table_map = np.split(self.VRAM[0x0:0x2000], 2)
        pattern_table_map = np.split(self.tiles_map, 2)

        if self.show_background:
            self.update_background(pattern_table_map)

        if self.show_sprites:
            self.update_sprites(pattern_table_map)

        # Rescale screen and update
        self.screen.blit(pygame.transform.scale(self.pic, (
        self.scale_size * self.width, self.scale_size * self.height)), (0, 0))
        pygame.display.update()
        return

    def update_background(self, pattern_table_map):
        attribute_table_address = self.nametable_address + 0x3C0
        self.background.update_background(
            pattern_table_map[self.background_pattern_table],
            self.VRAM[self.nametable_address:attribute_table_address],
            self.VRAM[attribute_table_address:attribute_table_address + 0x40],
            self.color_handler,
            self.pic)

    def update_sprites(self, pattern_table_map):
        sprites_data = np.reshape(self.SPR_RAM, (64, 4))
        self.all_sprites.update_sprites(pattern_table_map, sprites_data,
                                        self.color_handler,
                                        self.sprite_pattern_table)
        self.all_sprites.draw(self.pic)

    def write_spr_ram_dma(self, ram):
        self.SPR_RAM[:] = ram

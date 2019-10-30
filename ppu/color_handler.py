import numpy as np
import pygame

class ColorHandler:
    def __init__(self, ppu_VRAM):
        self.ppu_VRAM = ppu_VRAM
        self.bg_palettes = np.array_split(self.ppu_VRAM[0x3F00:0x3F10], 4)
        self.sprite_palettes = np.array_split(self.ppu_VRAM[0x3F10:0X3F20], 4)
        # self.sprite_palettes = [[0x15,0x0B,0x30,0x0A],[0x00,0x04,0x14,0x0F],[0x00,0x17,0x27,0x0F],[0x15,0x0B,0x30,0x0A]]

    def set_color_to_sprite(self, sprite_array, palette_index):
        return self.set_color_to_block(sprite_array, self.sprite_palettes[palette_index])

    def set_color_to_bg_block(self, bg_block_array, palette_index):
        return self.set_color_to_block(bg_block_array, self.bg_palettes[palette_index])

    def set_color_to_block(self, block_array, palette):
        index_to_sys_palette = np.vectorize(lambda pix: palette[pix] if pix < 4 else 0)
        sys_palette_to_rgb = np.vectorize(lambda pix: self.sys_palette_to_rgb(pix))
        colored_block = np.dstack(sys_palette_to_rgb(index_to_sys_palette(block_array)))
        return pygame.surfarray.make_surface(colored_block)

    # OLD CODE: might need it (TODO: delete if unecessary)
    # def set_color_to_bg_block(self, block, block_index, palette_index):
    #     attr_table_base_addr = 0x23C0 + (0x0400 * nametable_index)
    #     attr_byte = self.VRAM[nametable_index + block_index]

    #     bottom_right_palette = attr_byte & 0b11000000
    #     bottom_left_palette = attr_byte & 0b00110000
    #     top_right_palette = attr_byte & 0b00001100
    #     top_left_palette = attr_byte & 0b00000011

    #     top_left_box = block[:8, :8]
    #     top_right_box = block[:8, 8:16]
    #     bottom_left_box = block[8:16, :8]
    #     bottom_right_box = block[8:16, 8:16]

    #     block[:8, :8] = self.set_rgb_colors(top_left_box, self.bg_palettes[top_left_palette])
    #     block[:8, 8:16] = self.set_rgb_colors(top_right_box, self.bg_palettes[top_right_palette])
    #     block[8:16, :8] = self.set_rgb_colors(bottom_left_box, self.bg_palettes[bottom_left_palette])
    #     block[8:16, 8:16] = self.set_rgb_colors(bottom_right_box, self.bg_palettes[bottom_right_palette])
        
    #     print(block)
    #     return pygame.pixelcopy.make_surface(block)

    def sys_palette_to_rgb(self, pixel):
        return system_palette[pixel]
    
system_palette = [(0x75, 0x75, 0x75),
                        (0x27, 0x1B, 0x8F),
                        (0x00, 0x00, 0xAB),
                        (0x47, 0x00, 0x9F),
                        (0x8F, 0x00, 0x77),
                        (0xAB, 0x00, 0x13),
                        (0xA7, 0x00, 0x00),
                        (0x7F, 0x0B, 0x00),
                        (0x43, 0x2F, 0x00),
                        (0x00, 0x47, 0x00),
                        (0x00, 0x51, 0x00),
                        (0x00, 0x3F, 0x17),
                        (0x1B, 0x3F, 0x5F),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0xBC, 0xBC, 0xBC),
                        (0x00, 0x73, 0xEF),
                        (0x23, 0x3B, 0xEF),
                        (0x83, 0x00, 0xF3),
                        (0xBF, 0x00, 0xBF),
                        (0xE7, 0x00, 0x5B),
                        (0xDB, 0x2B, 0x00),
                        (0xCB, 0x4F, 0x0F),
                        (0x8B, 0x73, 0x00),
                        (0x00, 0x97, 0x00),
                        (0x00, 0xAB, 0x00),
                        (0x00, 0x93, 0x3B),
                        (0x00, 0x83, 0x8B),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0xFF, 0xFF, 0xFF),
                        (0x3F, 0xBF, 0xFF),
                        (0x5F, 0x97, 0xFF),
                        (0xA7, 0x8B, 0xFD),
                        (0xF7, 0x7B, 0xFF),
                        (0xFF, 0x77, 0xB7),
                        (0xFF, 0x77, 0x63),
                        (0xFF, 0x9B, 0x3B),
                        (0xF3, 0xBF, 0x3F),
                        (0x83, 0xD3, 0x13),
                        (0x4F, 0xDF, 0x4B),
                        (0x58, 0xF8, 0x98),
                        (0x00, 0xEB, 0xDB),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0xFF, 0xFF, 0xFF),
                        (0xAB, 0xE7, 0xFF),
                        (0xC7, 0xD7, 0xFF),
                        (0xD7, 0xCB, 0xFF),
                        (0xFF, 0xC7, 0xFF),
                        (0xFF, 0xC7, 0xDB),
                        (0xFF, 0xBF, 0xB3),
                        (0xFF, 0xDB, 0xAB),
                        (0xFF, 0xE7, 0xA3),
                        (0xE3, 0xFF, 0xA3),
                        (0xAB, 0xF3, 0xBF),
                        (0xB3, 0xFF, 0xCF),
                        (0x9F, 0xFF, 0xF3),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00),
                        (0x00, 0x00, 0x00)]

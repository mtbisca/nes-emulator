import numpy as np
import pygame
from numba import jit

class ColorHandler:
    def __init__(self, ppu_VRAM):
        self.ppu_VRAM = ppu_VRAM
        self.bg_palettes = np.array_split(self.ppu_VRAM[0x3F00:0x3F10], 4)
        self.sprite_palettes = np.array_split(self.ppu_VRAM[0x3F10:0X3F20], 4)

    def set_color_to_sprite(self, sprite_array, palette_index):
        palette = self.sprite_palettes[palette_index]
        sprite_surface = pygame.surfarray.make_surface(self.set_color_to_block(sprite_array, palette))
        sprite_surface.set_colorkey(self.sys_palette_to_rgb(palette[0]))
        return sprite_surface

    def set_color_to_bg_block(self, bg_block_array, palette_index):
        return self.set_color_to_block(bg_block_array, self.bg_palettes[palette_index])

    def set_color_to_block(self, block_array, palette):
        color_translator = [self.sys_palette_to_rgb(color) for color in palette]
        colored_block = np.copy(block_array)
        # color_translator = np.vectorize(lambda pix: self.sys_palette_to_rgb(palette[pix]) if pix < 4 else self.sys_palette_to_rgb(0))

        # # colored_block = np.dstack(color_translator(block_array))
        return fast_color(color_translator, block_array)


    def sys_palette_to_rgb(self, pixel):
        return system_palette[pixel]

@jit(nopython=True)
def fast_color(color_translator, block_array):
    colored_block = np.zeros((block_array.shape[0], block_array.shape[1], 3))
    for i in range(block_array.shape[0]):
        for j in range(block_array.shape[1]):
            pixel = block_array[i][j]
            if pixel > 3:
                pixel = 0 
            colored_block[i][j][:] = color_translator[pixel]
    return colored_block # dstack


c_code = """ 
    for(int i = 0; i < block_rows; i++) {
        for(int j = 0; j < block_cols; j++) {
            int pixel = block_array[i][j];
            colored_block[i][j] = pixel < 4 ? color_translator[pixel] : color_translator[0]; 
        }
    }
"""
    
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
                        (0x80, 0x80, 0x80),
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
                        

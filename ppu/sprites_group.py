from ppu.nes_sprite import NESSprite
import numpy as np
import pygame


class SpritesGroup():

    def __init__(self, sprite_size):
        self.sprites = {}

        self.sprite_size = sprite_size

        if self.sprite_size == (8, 16):
            self.update_sprites = self.update_sprites_rect
        else:
            self.update_sprites = self.update_sprites_square

        for key in range(64):
            self.sprites[key] = NESSprite(width=self.sprite_size[0],
                                          height=self.sprite_size[1],
                                          color=(0, 255, 0))

        self.group = pygame.sprite.Group()
        for sprite in self.sprites.values():
            self.group.add(sprite)

    def draw(self, surface):
        self.group.draw(surface)

    def set_all_positions(self, positions):
        for key in self.sprites:
            self.set_position(key, positions[key])

    def set_position(self, key, position):
        sprite = self.sprites[key]
        sprite.rect.x = position[0]
        sprite.rect.y = position[1]

    def set_surface(self, key, surface):
        sprite = self.sprites[key]
        sprite.image = surface

    def get_tile(self, bytes):
        bits = np.unpackbits(bytes, axis=0)
        bits_grids = bits.reshape((2, 8, 8))
        tile = (bits_grids[1] << 1) | bits_grids[0]
        return np.transpose(tile)


    def update_sprites_square(self, pattern_table_map, sprite_data, color_handler, pattern_table_flag):
        for key in range(64):
            data = sprite_data[key]
            # tile = self.get_tile(pattern_table_map[pattern_table_flag][data[1] * 16 : (data[1] + 1) * 16])
            tile = pattern_table_map[pattern_table_flag][data[1]]
            palette_index = data[2] & 0b11
            self.set_position(key, (data[3], data[0]))
            booly = (data[2] & 0b10000000) > 0
            boolx = (data[2] & 0b01000000) > 0
            surface = pygame.transform.flip(color_handler.set_color_to_sprite(tile, palette_index), boolx, booly)
            self.set_surface(key, surface)

    def update_sprites_rect(self, pattern_table_map, sprite_data, color_handler, pattern_table_flag):
        for key in range(64):
            data = sprite_data[key]
            table = data[1] & 1
            index = data[1] & 0b11111110
            tile1 = pattern_table_map[table][index]
            tile2 = pattern_table_map[table][index+1]
            tile = np.concatenate((tile1, tile2), axis=1)
            palette_index = data[2] & 0b11
            self.set_position(key, (data[3], data[0]))
            booly = (data[2] & 0b10000000) > 0
            boolx = (data[2] & 0b01000000) > 0
            surface = pygame.transform.flip(color_handler.set_color_to_sprite(tile, palette_index), boolx, booly)
            self.set_surface(key, surface)





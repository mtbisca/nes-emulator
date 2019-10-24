from ppu.nes_sprite import NES_Sprite
import numpy as np
import pygame

class Sprites_Group():

    def __init__(self):
        self.sprites = {}

        for key in range(64):
            self.sprites[key] = NES_Sprite((0, 255, 0))

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

    def update_sprites(self, sprite_tiles, sprite_palettes, sprite_data, color_handler):
        tile_map = np.reshape(sprite_tiles, (64, 8, 8))

        for key in range(64):
            data = sprite_data[key]
            tile = tile_map[data[1]]
            palette_index = data[2] & 0b11
            self.set_position(key, (data[3], data[0]))
            surface = color_handler.set_color_to_sprite(tile, palette_index)
            self.set_surface(key, surface)




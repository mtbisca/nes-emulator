from ppu.nes_sprite import NESSprite
import numpy as np
import pygame


class SpritesGroup():

    def __init__(self, sprite_size):
        self.sprites = {}

        for key in range(64):
            self.sprites[key] = NESSprite(width=sprite_size[0],
                                          height=sprite_size[1],
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

    # TODO
    def get_colors(self, tile, palette):
        image = pygame.Surface((8, 8))
        image.fill((255, 0, 0))
        return image

    def update_sprites(self, sprite_tiles, sprite_palettes, sprite_data):
        tile_map = np.reshape(sprite_tiles, (64, 8, 8))
        palettes_map = np.reshape(sprite_palettes, (4, 4))

        for key in range(64):
            data = sprite_data[key]
            tile = tile_map[data[1]]
            palette = palettes_map[data[2] & 0b11]
            self.set_position(key, (data[3], data[0]))
            # TODO
            surface = self.get_colors(tile, palette)
            self.set_surface(key, surface)




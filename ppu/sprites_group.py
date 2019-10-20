from ppu.nes_sprite import NES_Sprite
import pygame

class Sprites_Group():

    def __init__(self):
        self.sprites = {0: NES_Sprite((255,0,0)),
                        1: NES_Sprite((0,255,0)),
                        2: NES_Sprite((0,0,255)),
                        3: NES_Sprite((255,0,255)),
                        4: NES_Sprite((255,255,0))}

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

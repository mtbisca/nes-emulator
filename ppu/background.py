import numpy as np
import pygame


class Background:
    def __init__(self):
        self.background_table = np.empty((256, 240, 3), dtype=int)

    def get_palette_index(self, nametable_row, nametable_col, attribute_table):
        block_row = nametable_row // 4
        block_col = nametable_col // 4

        attr_index = np.ravel_multi_index((block_row, block_col), (8, 8))

        shift_value = 0
        shift_value += 4 if nametable_row % 4 >= 2 else 0  # 0 = top, 1 = bottom
        shift_value += 2 if nametable_col % 4 >= 2 else 0  # 0 = left, 1 = right

        palette_index = (attribute_table[attr_index] & (
                    3 << shift_value)) >> shift_value
        return palette_index

    def update_background(self, pattern_table, nametable, attribute_table,
                          color_handler, pic):
        for idx in range(0, len(nametable), 2):
            # low_bytes = pattern_table[pattern_table_index * 16:
            #                           (pattern_table_index * 16) + 8]
            # high_bytes = pattern_table[(pattern_table_index * 16) + 8:
            #                            (pattern_table_index + 1) * 16]
            #
            # low_bytes = np.reshape(np.unpackbits(low_bytes, axis=0), (8, 8))
            # high_bytes = np.reshape(np.unpackbits(high_bytes, axis=0), (8, 8))
            #
            # # Contains indexes to the frame palette
            # tile = (high_bytes << 1) | low_bytes
            nametable_row = idx // 32

            if nametable_row % 2 > 0:
                continue

            nametable_col = idx % 32

            superior_tiles = np.concatenate((pattern_table[nametable[idx]],
                                             pattern_table[nametable[idx + 31]]),
                                            axis=1)
            inferior_tiles = np.concatenate((pattern_table[nametable[idx + 1]],
                                             pattern_table[nametable[idx + 32]]),
                                            axis=1)
            tiles = np.concatenate((superior_tiles, inferior_tiles), axis=0)

            palette_index = self.get_palette_index(nametable_row,
                                                   nametable_col,
                                                   attribute_table)

            x_coord = nametable_col * 8
            y_coord = nametable_row * 8
            self.background_table[x_coord:x_coord + 16,
            y_coord:y_coord + 16] = color_handler.set_color_to_bg_block(tiles,
                                                                        palette_index)
        pic.blit(pygame.surfarray.make_surface(self.background_table), (0, 0))

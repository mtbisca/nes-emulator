import numpy as np


class Background:
    def __init__(self):
        self.blocks = np.empty((8, 8), dtype=object)

    def _create_blocks(self, attribute_table):
        len_attribute_table = attribute_table.shape[0]
        attribute_table = np.reshape(np.unpackbits(attribute_table),
                                     (len_attribute_table, 8))
        row = 0
        for idx, byte in enumerate(attribute_table):
            block = list()
            for bit_number in range(0, 8, 2):
                palette_idx = (byte[bit_number] << 1) | byte[bit_number + 1]
                block.append(palette_idx)
            column = idx % 8
            if column == 0 and row > 0:
                row += 1
            self.blocks[row][column] = np.array(block)

    def update_background(self, pattern_table, nametable, attribute_table):
        self._create_blocks(attribute_table)
        row = 0
        for idx, pattern_table_index in enumerate(nametable):
            low_bytes = pattern_table[pattern_table_index * 16:
                                      (pattern_table_index + 1) * 8]
            high_bytes = pattern_table[(pattern_table_index + 1) * 8:
                                       (pattern_table_index + 1) * 16]

            low_bytes = np.reshape(np.unpackbits(low_bytes, axis=0), (8, 8))
            high_bytes = np.reshape(np.unpackbits(high_bytes, axis=0), (8, 8))

            # Contains indexes to the frame palette
            tile = (high_bytes << 1) | low_bytes

            column = idx % 32
            if column == 0 and row > 0:
                row += 1
            block_coord = (row // 4, column // 4)
            if column % 4 < 2:
                if row % 4 < 2:
                    quad_number = 0
                else:
                    quad_number = 2
            else:
                if row % 4 < 2:
                    quad_number = 1
                else:
                    quad_number = 3

            palette_index = self.blocks[block_coord[0]][block_coord[1]][quad_number]

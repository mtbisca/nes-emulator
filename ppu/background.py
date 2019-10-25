import numpy as np


class Background:
    def __init__(self):
        pass

    def update_background(self, nametable, pattern_table):
        for pattern_table_index in nametable:
            low_bytes = pattern_table[pattern_table_index * 16:
                                      (pattern_table_index + 1) * 8]
            high_bytes = pattern_table[(pattern_table_index + 1) * 8:
                                       (pattern_table_index + 1) * 16]

            low_bytes = np.reshape(np.unpackbits(low_bytes, axis=0), (8, 8))
            high_bytes = np.reshape(np.unpackbits(high_bytes, axis=0), (8, 8))

            # Contains indexes to the frame palette
            tile = (high_bytes << 1) + low_bytes

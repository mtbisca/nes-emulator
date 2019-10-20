import sys
import numpy as np
from cpu.main import CPU
from ppu.ppu import PPU

def main(rom_path):
    rom = np.fromfile(rom_path, dtype=np.uint8)
    header = rom[:0x10]
    cpu_mem = np.zeros(0x8000, dtype=np.uint8)
    if (header[0x04] == 1):
        cpu_mem[:0x4000] = rom[0x10:0x4010]
        cpu_mem[0x4000:] = rom[0x10:0x4010]
    elif (header[0x04] == 2):
        cpu_mem = rom[0x10:0x8010]

    ppu_mem = rom[0x8010:0xa010]
    ppu = PPU(ppu_mem, header[0x6] & 1, 4)

    cpu = CPU(cpu_mem)
    np.seterr(over='ignore')
    cpu.run()

    # while (True):
    #     ppu.update()


if __name__ == "__main__":
    main(sys.argv[1])
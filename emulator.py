import sys
import numpy as np
from cpu.main import CPU
from ppu.ppu import PPU

def main(rom_path):
    rom = np.fromfile(rom_path, dtype=np.uint8)
    header = rom[:0x10]

    # iNES rom format should start with NES followed by MS-DOS end-of-file
    if header[0x0] != 0x4E or header[0x1] != 0x45 or header[0x2] != 0x53 or \
            header[0x3] != 0x1A:
        raise RuntimeError("Emulator only supports ROMs in the iNes format.")

    cpu_mem = np.zeros(0x8000, dtype=np.uint8)

    nrof_rom_banks = header[0x04]
    if nrof_rom_banks == 1:
        cpu_mem[:0x4000] = rom[0x10:0x4010]
        cpu_mem[0x4000:] = rom[0x10:0x4010]
        final = 0x4010
    elif nrof_rom_banks == 2:
        cpu_mem = rom[0x10:0x8010]
        final = 0x8010
    else:
        raise RuntimeError("Emulator does not support more than 2 ROM banks.")

    ppu_mem = rom[final : final + 0x2000]
    ppu = PPU(ppu_mem, mirroring_type=header[0x6] & 1, scale_size=4)

    cpu = CPU(cpu_mem, ppu)
    np.seterr(over='ignore')
    cpu.run()

    while (True):
        ppu.update()


if __name__ == "__main__":
    main(sys.argv[1])
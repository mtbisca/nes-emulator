import numpy as np
import sys
import time


class CPU:
    def __init__(self, rom_path):
        self.rom = np.fromfile(rom_path, np.uint8)

        # Internal RAM has 2KB
        self.ram = np.zeros(2*1024, dtype=np.uint8)

        # Counter registers
        self.pc = np.uint16(0)
        self.sp = np.uint16(0)

        self.addr = None
        self.data = None

        # Data registers
        self.a = np.uint8(0)
        self.x = np.uint8(0)
        self.y = np.uint8(0)

        # Flags (p register equivalent)
        self.carry = 0
        self.zero = 0
        self.interrupt_disable = 0
        self.decimal_mode = 0
        self.break_cmd = 0
        self.overflow = 0
        self.negative = 0

        self.running = True

        self.instructions = {
            0x00: self.brk,
            0x18: self.clc,
            0x24: self.bit_zero_page,
            0x2C: self.bit_absolute,
            0x90: self.bcc,
            0xB0: self.bcs,
            0xF0: self.beq,
            0xD0: self.bne,
            0x10: self.bpl,
            0x30: self.bmi,
            0x50: self.bvc,
            0x70: self.bvs,
            0x0A: self.asl_accumulator,
            0x06: self.asl_zero_page,
            0x16: self.asl_zero_page_x,
            0x0E: self.asl_absolute,
            0x1E: self.asl_absolute_x,
            0xA9: self.lda_immediate,
            0xA5: self.lda_zero_page,
            0xB5: self.lda_zero_page_x,
            0xAD: self.lda_absolute,
            0xBD: self.lda_absolute_x,
            0xB9: self.lda_absolute_y,
            0xA1: self.lda_indexed_indirect,
            0xB1: self.lda_indirect_indexed,
            0xA2: self.ldx_immediate,
            0xA6: self.ldx_zero_page,
            0xB6: self.ldx_zero_page_y,
            0xAE: self.ldx_absolute,
            0xBE: self.ldx_absolute_y,
            0xA0: self.ldy_immediate,
            0xA4: self.ldy_zero_page,
            0xB4: self.ldy_zero_page_x,
            0xAC: self.ldy_absolute,
            0xBC: self.ldy_absolute_x,
            0x85: self.sta_zero_page,
            0x95: self.sta_zero_page_x,
            0x8D: self.sta_absolute,
            0x9D: self.sta_absolute_x,
            0x99: self.sta_absolute_y,
            0x81: self.sta_indexed_indirect,
            0x91: self.sta_indirect_indexed,
            0x86: self.stx_zero_page,
            0x96: self.stx_zero_page_y,
            0x8E: self.stx_absolute,
            0x84: self.sty_zero_page,
            0x94: self.sty_zero_page_x,
            0x8C: self.sty_absolute,
            0xAA: self.tax,
            0xA8: self.tay,
            0xBA: self.tsx,
            0x8A: self.txa,
            0x9A: self.txs,
            0x98: self.tya,
            0x38: self.sec,
            0xF8: self.sed,
            0x78: self.sei
        }

    # Set flags
    def set_zero_and_neg(self, register):
        if register == 0:
            self.zero = 1
        else:
            self.zero = 0
        if register & 10000000:
            self.negative = 1
        else:
            self.negative = 0

    def get_bytes(self, size):
        position = self.pc + 1
        data = self.rom[position:position + size]
        self.pc += np.uint16(size)
        return data

    # Addressing Modes
    def absolute_address(self):
        data = self.get_bytes(2)
        return (data[0] << 8) + data[1]

    def relative_address(self):
        """
        Add offset to PC to cause a branch to a new location
        """
        offset = self.get_bytes(1)[0]
        self.pc += offset

    def indexed_indirect(self):
        value = self.get_bytes(1)[0]
        location = value + self.x
        return (self.rom[location] << 8) + self.rom[location + 1]

    def indirect_indexed(self):
        location = self.get_bytes(1)[0]
        return (self.rom[location] << 8) + self.rom[location + 1] + self.y

    # Instructions
    def brk(self):
        """
        Force Interrupt
        """
        # TODO: implement BRK properly
        pass
        # self.running = False

    def clc(self):
        """
        Clear Carry Flag
        """
        self.carry = 0

    def bit(self, address):
        """
        Bit Test
        """
        memory_value = self.ram[address]
        if (self.a & memory_value) == np.uint8(0):
            self.zero = 1
        else:
            self.zero = 0

        # Set V to bit 6 of the memory value
        self.overflow = (memory_value >> 6) & 1

        # Set N to bit 7 of the memory value
        self.negative = memory_value >> 7

    def bit_zero_page(self):
        address = self.get_bytes(1)[0]
        self.bit(address)

    def bit_absolute(self):
        address = self.absolute_address()
        self.bit(address)

    def bcc(self):
        """
        Branch if Carry Clear
        """
        if self.carry == 0:
            self.relative_address()

    def bcs(self):
        """
        Branch if Carry Set
        """
        if self.carry == 1:
            self.relative_address()

    def beq(self):
        """
        Branch if Equal
        """
        if self.zero == 1:
            self.relative_address()

    def bne(self):
        """
        Branch if Not Equal
        """
        if self.zero == 0:
            self.relative_address()

    def bpl(self):
        """
        Branch if Positive
        """
        if self.negative == 0:
            self.relative_address()

    def bmi(self):
        """
        Branch if Minus
        """
        if self.negative == 1:
            self.relative_address()

    def bvc(self):
        """
        Branch if Overflow Clear
        """
        if self.overflow == 0:
            self.relative_address()

    def bvs(self):
        """
        Branch if Overflow Set
        """
        if self.overflow == 1:
            self.relative_address()

    def adc(self):
        """
        Add with Carry
        """
        pass

    def asl(self, value_to_shift):
        """
        Arithmetic Shift Left
        """
        # Set C to contents of old bit 7
        self.carry = value_to_shift >> 7
        # Shift all the bits one bit left
        result = value_to_shift << 1
        # Set N if bit 7 of the result is set
        self.negative = value_to_shift >> 7

        return result

    def asl_accumulator(self):
        self.a = self.asl(self.a)

    def asl_zero_page(self):
        address = self.get_bytes(1)[0]
        value = self.asl(self.ram[address])
        self.ram[address] = value

    def asl_zero_page_x(self):
        address = self.get_bytes(1)[0] + self.x
        value = self.asl(self.ram[address])
        self.ram[address] = value

    def asl_absolute(self):
        address = self.absolute_address()
        value = self.asl(self.ram[address])
        self.ram[address] = value

    def asl_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.asl(self.ram[address])
        self.ram[address] = value

    def lda_immediate(self):
        self.a = self.get_bytes(1)[0]
        self.set_zero_and_neg(self.a)

    def ldx_immediate(self):
        self.x = self.get_bytes(1)[0]
        self.set_zero_and_neg(self.x)

    def ldy_immediate(self):
        self.y = self.get_bytes(1)[0]
        self.set_zero_and_neg(self.y)

    def lda_zero_page(self):
        address = self.get_bytes(1)[0]
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def ldx_zero_page(self):
        address = self.get_bytes(1)[0]
        self.x = self.rom[address]
        self.set_zero_and_neg(self.x)

    def ldy_zero_page(self):
        address = self.get_bytes(1)[0]
        self.y = self.rom[address]
        self.set_zero_and_neg(self.y)

    def lda_zero_page_x(self):
        address = self.get_bytes(1)[0] + self.x
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def ldx_zero_page_y(self):
        address = self.get_bytes(1)[0] + self.y
        self.x = self.rom[address]
        self.set_zero_and_neg(self.x)

    def ldy_zero_page_x(self):
        address = self.get_bytes(1)[0] + self.x
        self.y = self.rom[address]
        self.set_zero_and_neg(self.y)

    def lda_absolute(self):
        address = self.absolute_address()
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def ldx_absolute(self):
        address = self.absolute_address()
        self.x = self.rom[address]
        self.set_zero_and_neg(self.x)

    def ldy_absolute(self):
        address = self.absolute_address()
        self.y = self.rom[address]
        self.set_zero_and_neg(self.y)

    def lda_absolute_x(self):
        address = self.absolute_address() + self.x
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def lda_absolute_y(self):
        address = self.absolute_address() + self.y
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def ldx_absolute_y(self):
        address = self.absolute_address() + self.y
        self.x = self.rom[address]
        self.set_zero_and_neg(self.x)

    def ldy_absolute_x(self):
        address = self.absolute_address() + self.x
        self.y = self.rom[address]
        self.set_zero_and_neg(self.y)

    def lda_indexed_indirect(self):
        address = self.indexed_indirect()
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def lda_indirect_indexed(self):
        address = self.indirect_indexed()
        self.a = self.rom[address]
        self.set_zero_and_neg(self.a)

    def rts(self):
        pass

    def sbc(self):
        pass

    def sec(self):
        self.carry = 1

    def sed(self):
        self.decimal_mode = 1

    def sei(self):
        self.interrupt_disable = 1

    def sta(self):
        pass

    def stx(self):
        pass

    def sty(self):
        pass

    def tax(self):
        self.x = self.a
        self.set_carry_and_neg(self.x)

    def tay(self):
        self.y = self.a
        self.set_carry_and_neg(self.y)

    def tsx(self):
        self.x = self.sp
        self.set_carry_and_neg(self.x)

    def txa(self):
        self.a = self.x
        self.set_carry_and_neg(self.a)

    def txs(self):
        self.sp = self.x

    def tya(self):
        self.a = self.y
        self.set_carry_and_neg(self.a)

    def _hex_format(self, value, leading_zeros):
        format_string = "{0:0%sX}" % leading_zeros
        return ("0x" + format_string.format(int(value))).lower()

    def _bin_format(self, value):
        return "{0:08b}".format(value)

    def _get_p(self):
        return (self.negative << 7 |
                self.overflow << 6 |
                1 << 5 |  # assumes bit 5 is always set TODO check if this is correct
                self.break_cmd << 4 |
                self.decimal_mode << 3 |
                self.interrupt_disable << 2 |
                self.zero << 1 |
                self.carry)

    def print_state(self):
        print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s |" % \
              (self._hex_format(self.pc, 4),
               self._hex_format(self.a, 2),
               self._hex_format(self.x, 2),
               self._hex_format(self.y, 2),
               self._hex_format(self.sp, 4),
               self._bin_format(self._get_p())))

    def print_state_ls(self):
        print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s | MEM[%s] = %s |" % \
              (self._hex_format(self.pc, 4),
               self._hex_format(self.a, 2),
               self._hex_format(self.x, 2),
               self._hex_format(self.y, 2),
               self._hex_format(self.sp, 4),
               self._bin_format(self._get_p()),
               self._hex_format(self.addr, 4),
               self._hex_format(self.data, 2)))

    def run(self):
        while self.running:
            rom_byte = self.rom[self.pc]
            self.execute(opcode=rom_byte)
            self.print_state()
            time.sleep(0.02)

    def execute(self, opcode):
        # Being used in order to ignore invalid opcodes
        def does_nothing():
            return "nothing"

        # TODO: switch does_nothing for None when only valid opcodes are being read
        instruction = self.instructions.get(opcode, does_nothing)
        instruction()
        self.pc += np.uint16(1)


def main(rom_path):
    cpu = CPU(rom_path)
    cpu.run()


if __name__ == "__main__":
    main(sys.argv[1])

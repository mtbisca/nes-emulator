import numpy as np
import sys
import time


class CPU:
    def __init__(self, rom_path):
        self.mem = np.zeros(0x10000, dtype=np.uint8)
        self.mem[0x4020:] = np.resize(np.fromfile(rom_path, dtype=np.uint8), (49120))

        # Counter registers
        self.pc = np.uint16(0x4020)
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
            0: self.brk,
            24: self.clc,
            36: self.bit_zero_page,
            44: self.bit_absolute,
            144: self.bcc,
            176: self.bcs,
            240: self.beq,
            208: self.bne,
            16: self.bpl,
            48: self.bmi,
            80: self.bvc,
            112: self.bvs,
            10: self.asl_accumulator,
            6: self.asl_zero_page,
            22: self.asl_zero_page_x,
            14: self.asl_absolute,
            30: self.asl_absolute_x,
            169: self.lda_immediate,
            160: self.ldy_immediate,
            162: self.ldx_immediate,
            165: self.lda_zero_page,
            166: self.ldx_zero_page,
            164: self.ldy_zero_page,
            182: self.lda_zero_page_x,
            183: self.ldx_zero_page_y,
            181: self.ldy_zero_page_x,
            173: self.lda_absolute,
            174: self.ldx_absolute,
            172: self.ldy_absolute,
            189: self.lda_absolute_x,
            185: self.lda_absolute_y,
            190: self.ldx_absolute_y,
            188: self.ldy_absolute_x,
            161: self.lda_indexed_indirect,
            177: self.lda_indirect_indexed
        }

    # Set flags
    def set_carry_and_neg(self, register):
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
        data = self.mem[position:position + size]
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
        return (self.mem[location] << 8) + self.mem[location + 1]

    def indirect_indexed(self):
        location = self.get_bytes(1)[0]
        return (self.mem[location] << 8) + self.mem[location + 1] + self.y

    # Instructions
    def brk(self):
        """
        Force Interrupt
        """
        # TODO: implement BRK properly
        # pass
        self.running = False

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
        self.set_carry_and_neg(self.a)

    def ldx_immediate(self):
        self.x = self.get_bytes(1)[0]
        self.set_carry_and_neg(self.x)

    def ldy_immediate(self):
        self.y = self.get_bytes(1)[0]
        self.set_carry_and_neg(self.y)

    def lda_zero_page(self):
        address = self.get_bytes(1)[0]
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def ldx_zero_page(self):
        address = self.get_bytes(1)[0]
        self.x = self.mem[address]
        self.set_carry_and_neg(self.x)

    def ldy_zero_page(self):
        address = self.get_bytes(1)[0]
        self.y = self.mem[address]
        self.set_carry_and_neg(self.y)

    def lda_zero_page_x(self):
        address = self.get_bytes(1)[0] + self.x
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def ldx_zero_page_y(self):
        address = self.get_bytes(1)[0] + self.y
        self.x = self.mem[address]
        self.set_carry_and_neg(self.x)

    def ldy_zero_page_x(self):
        address = self.get_bytes(1)[0] + self.x
        self.y = self.mem[address]
        self.set_carry_and_neg(self.y)

    def lda_absolute(self):
        address = self.absolute_address()
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def ldx_absolute(self):
        address = self.absolute_address()
        self.x = self.mem[address]
        self.set_carry_and_neg(self.x)

    def ldy_absolute(self):
        address = self.absolute_address()
        self.y = self.mem[address]
        self.set_carry_and_neg(self.y)

    def lda_absolute_x(self):
        address = self.absolute_address() + self.x
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def lda_absolute_y(self):
        address = self.absolute_address() + self.y
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def ldx_absolute_y(self):
        address = self.absolute_address() + self.y
        self.x = self.mem[address]
        self.set_carry_and_neg(self.x)

    def ldy_absolute_x(self):
        address = self.absolute_address() + self.x
        self.y = self.mem[address]
        self.set_carry_and_neg(self.y)

    def lda_indexed_indirect(self):
        address = self.indexed_indirect()
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

    def lda_indirect_indexed(self):
        address = self.indirect_indexed()
        self.a = self.mem[address]
        self.set_carry_and_neg(self.a)

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
            rom_byte = self.mem[self.pc]
            self.execute(opcode=rom_byte)
            self.print_state()
            time.sleep(0.0000002)

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

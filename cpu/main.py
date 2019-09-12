import numpy as np
import sys
import time

running = 1


class CPU:
    def __init__(self, rom_path):
        self.rom = np.fromfile(rom_path, np.uint8)

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

        self.running = 1

        self.instructions = {
            0: self.brk,
            169: self.lda_imediate,
            160: self.ldy_imediate,
            162: self.ldx_imediate,
            165: self.lda_zero_page,
            166: self.ldx_zero_page,
            164: self.ldy_zero_page
        }

    ###
    ### Functions of each OP code
    ###
    def brk(self):
        self.running = 0

    def set_carry_and_neg(self, register):
        if(register == 0):
            self.zero = 1
        else:
            self.zero = 0
        if(register & 10000000):
            self.negative = 1
        else:
            self.negative = 0

    def look_up(self, value):
        first = self.pc+1
        data = self.rom[first:first+value]
        self.pc += np.uint16(value)
        return data

    def zero_page_address_reg(self, page, register):
        return (page << 8) + register

    def absolute_address(self, high, low):
        return (high << 8) + low


    def absolute_address_reg(self, high, low, register):
        return (high << 8) + low + register


    def indexed_indirect(self, value):
        location = value + self.x
        return (self.rom[location] << 8) + self.rom[location+1]

    def indirect_indexed(self, location):
        return (self.rom[location] << 8) + self.rom[location+1] + self.y

    def lda_imediate(self):
        self.a = self.look_up(1)[0]
        self.set_carry_and_neg(self.a)

    def ldx_imediate(self):
        self.x = self.look_up(1)[0]
        self.set_carry_and_neg(self.x)

    def ldy_imediate(self):
        self.y = self.look_up(1)[0]
        self.set_carry_and_neg(self.y)

    def lda_zero_page(self):
        address = self.look_up(1)[0]
        self.a = self.rom[address]
        self.set_carry_and_neg(self.a)

    def ldx_zero_page(self):
        address = self.look_up(1)[0]
        self.x = self.rom[address]
        self.set_carry_and_neg(self.x)

    def ldy_zero_page(self):
        address = self.look_up(1)[0]
        self.y = self.rom[address]
        self.set_carry_and_neg(self.y)

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
                1 << 5 |                # assumes bit 5 is always set TODO check if this is correct
                self.break_cmd << 4 |
                self.decimal_mode << 3 |
                self.interrupt_disable << 2 |
                self.zero << 1  |
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
        while (self.running):
            # feach instruction
            instruction = self.rom[self.pc]
            # print op code for debuging
            self.execute(opcode=instruction)
            # test op code function
            self.print_state()

            # tmporizing
            time.sleep(1)

    def execute(self, opcode):
        def does_nothing():
            return "nothing"

        instruction = self.instructions.get(opcode, does_nothing)
        instruction()
        self.pc += np.uint8(1)


def main(rom_path):
    cpu = CPU(rom_path)
    # cpu.run()
    cpu.sec()
    cpu.sed()
    cpu.sei()
    cpu.print_state()


if __name__ == "__main__":
    main(sys.argv[1])

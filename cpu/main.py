import numpy as np
import sys
import time

running = 1


class CPU:
    def __init__(self):
        # Counter registers
        # Numpy uint16 simulates 16 bits of the registers)
        self.pc = np.uint16(0)
        self.sp = np.uint16(0)

        # State register
        self.p = 0

        self.addr = None
        self.data = None

        # Data registers
        self.a = np.uint8(0)
        self.x = np.uint8(0)
        self.y = np.uint8(0)

        self.running = 1

        ###
        ### Dictionary of OP codes
        ###
        # self.intructions = {
        #     0: zero,
        #     1: one,
        #     2: two
        #  }

    ###
    ### Functions of each OP code
    ###
    def zero(self):
        print("zero")
        self.running = 0

    def one(self):
        print("o")
        return "one"

    def two(self):
        print("t")
        return "two"


    ###
    ### Dictionary of OP codes
    ###
    instructions = {
        0: zero,
        1: one,
        2: two
     }

    def _hex_format(self, value, leading_zeros):
        format_string = "{0:0%sX}" % leading_zeros
        return ("0x" + format_string.format(int(value))).lower()

    def _bin_format(self, value):
        return "{0:08b}".format(value)

    def print_state(self):
        print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s |" % \
                (self._hex_format(self.pc, 4),
                 self._hex_format(self.a, 2),
                 self._hex_format(self.x, 2),
                 self._hex_format(self.y, 2),
                 self._hex_format(self.sp, 4),
                 self._bin_format(self.p)))

    def print_state_ls(self):
    	print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s | MEM[%s] = %s |" % \
        		(self._hex_format(self.pc, 4),
        		 self._hex_format(self.a, 2),
        		 self._hex_format(self.x, 2),
        		 self._hex_format(self.y, 2),
        		 self._hex_format(self.sp, 4),
        		 self._bin_format(self.p),
        		 self._hex_format(self.addr, 4),
        	     self._hex_format(self.data, 2)))

    def execute(self, opcode):
        def nothing(self):
            print("n")
            return "nothing"
        instruction = self.instructions.get(opcode, nothing)
        instruction(self)
        self.pc += np.uint8(1)


def main(argv):
     mem = np.fromfile(sys.argv[1], np.uint8)
     cpu = CPU()
     # print_state(2, 2, 2, 2, 2, 2)
     while (cpu.running):
          # feach instruction
          instruction = mem[cpu.pc]
          # print op code for debuging
          cpu.execute(opcode=instruction)
          # test op code function
          cpu.print_state()
          #move PC

          # tmporizing
          time.sleep(1)

if __name__ == "__main__":
    main(sys.argv[1:])

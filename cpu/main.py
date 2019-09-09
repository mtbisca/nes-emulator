import numpy as np
import sys
import time


class CPU:
    def __init__(self):
        # Counter registers
        # Numpy uint16 simulates 16 bits of the registers)
        self.pc = np.uint16(0)
        self.sp = np.uint16(0)

        # State register
        self.p = None

        self.addr = None
        self.data = None

        # Data registers
        self.a = np.uint16(0)
        self.x = np.uint16(0)
        self.y = np.uint16(0)

        def _hex_format(value, leading_zeros):
            format_string = "{0:0%sX}" % leading_zeros
            return ("0x" + format_string.format(int(value))).lower()

        def _bin_format(value):
            return "{0:08b}".format(value)

        def print_state():
            print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s |" % \
                    (_hex_format(self.pc, 4),
                     _hex_format(self.a, 2),
                     _hex_format(self.x, 2),
                     _hex_format(self.y, 2),
                     _hex_format(self.sp, 4),
                     _bin_format(self.p)))

        def print_state_ls():
        	print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s | MEM[%s] = %s |" % \
            		(_hex_format(self.pc, 4),
            		 _hex_format(self.a, 2),
            		 _hex_format(self.x, 2),
            		 _hex_format(self.y, 2),
            		 _hex_format(self.sp, 4),
            		 _bin_format(self.p),
            		 _hex_format(self.addr, 4),
            	     _hex_format(self.data, 2)))

        def execute(opcode):
            instruction = instruction.get(opcode, does_nothing)
            instruction()
            self.pc += np.uint16(1)


###
### Functions of each OP code
###
def zero():
    return "zero"

def one():
    return "one"

def two():
    return "two"

def nothing():
    return "nothing"

###
### Dictionary of OP codes
###
switcher = {
     0: zero,
     1: one,
     2: two
}


def run(argument):
    # Get the function from switcher dictionary
    func = switcher.get(argument, nothing)
    # Execute the function of the OP code
    return func()


def main(argv):
     mem = np.fromfile(sys.argv[1], np.uint8)
     print_state(2, 2, 2, 2, 2, 2)
     while (1):
          # feach instruction
          instruction = mem[PC]
          # print op code for debuging
          print(instruction)
          # test op code function
          print(run(instruction))
          #move PC
          PC = PC + np.uint16(1)

          # tmporizing
          time.sleep(1)

if __name__ == "__main__":
    main(sys.argv[1:])

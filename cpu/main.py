import numpy as np
import sys
import time

running = 1


class CPU:
    def __init__(self, arg):
        self.mem = np.fromfile(arg, np.uint8)
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
    ### Functions of each OP code
    ###
    def zero(self):
        self.running = 0

    def ld_absolute(self):
        self.pc += np.uint16(1)
        return np.uint8(self.mem[self.pc])

    def lda_absolute(self):
        self.a = self.ld_absolute()
    
    def ldx_absolute(self):
        self.x = self.ld_absolute()
    
    def ldy_absolute(self):
        self.y = self.ld_absolute()



    ###
    ### Dictionary of OP codes
    ###
    instructions = {
        0: zero,
        169: lda_absolute,
        160: ldy_absolute,
        162: ldx_absolute
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

    def run(self):
         while (self.running):
            # feach instruction
            instruction = self.mem[self.pc]
            # print op code for debuging
            self.execute(opcode=instruction)
            # test op code function
            self.print_state()

            # tmporizing
            time.sleep(1)

    def execute(self, opcode):
        def nothing(self):
            return "nothing"
        instruction = self.instructions.get(opcode, nothing)
        instruction(self)
        self.pc += np.uint8(1)


def main(argv):
     
     cpu = CPU(argv[0])
     cpu.run()

if __name__ == "__main__":
    main(sys.argv[1:])

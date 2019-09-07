import numpy as np
import sys
import time


###
### Indicate Registers (use numpy uint16 tosimulate 16 bits of the registers)###
###
A = np.uint16(0)
Y = np.uint16(0)
X = np.uint16(0)
PC = np.uint16(0)


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

def hex_format(value, leading_zeros):
    format_string = "{0:0%sX}" % leading_zeros
    return ("0x" + format_string.format(int(value))).lower()

def bin_format(value):
    return "{0:08b}".format(value)

def print_state(a, x, y, sp, pc, p):
    print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s |" % \
    (hex_format(pc, 4),
     hex_format(a, 2),
     hex_format(x, 2),
     hex_format(y, 2),
     hex_format(sp, 4),
     bin_format(p)))

def print_state_ls(a, x, y, sp, pc, p, addr, data):
	print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s | MEM[%s] = %s |" % \
		(hex_format(pc, 4),
		hex_format(a, 2),
		hex_format(x, 2),
		hex_format(y, 2),
		hex_format(sp, 4),
		bin_format(p),
		hex_format(addr, 4),
	     hex_format(data, 2)))


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

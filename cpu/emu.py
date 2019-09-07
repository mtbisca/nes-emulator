import numpy as np
import sys
import time

mem = np.fromfile(sys.argv[1], np.uint8)
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


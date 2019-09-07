import sys

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
    print_state(2, 2, 2, 2, 2, 2)

if __name__ == "__main__":
    main(sys.argv[1:])

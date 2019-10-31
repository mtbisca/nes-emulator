import numpy as np
import sys
import time
from cpu.controls import CONTROL
import pygame


class CPU:
    def __init__(self, cpu_mem, ppu_ref):
        self.mem = np.zeros(0x10000, dtype=np.uint8)
        # rom = np.fromfile(rom_path, dtype=np.uint8)
        # rom = rom[0x10:]
        self.mem[0x8000:] = cpu_mem

        self.ppu_ref = ppu_ref


        self.readControls = 0
        self.firstWrite = 0
        self.timeControl = 0
        self.keys = np.zeros(255, dtype = np.uint8)

        # Counter registers
        self.pc = np.uint16(self.get_reset_address())
        self.sp = np.uint16(0x01FD)

        # Data registers
        self.a = np.uint8(0)
        self.x = np.uint8(0)
        self.y = np.uint8(0)

        # Flags (p register equivalent)
        # NV-BDIZC
        # 00110100
        self.negative = 0
        self.overflow = 0
        self.break_cmd = 1
        self.decimal_mode = 0
        self.interrupt_disable = 1
        self.zero = 0
        self.carry = 0

        self.running = True

        self.nmi_activated = False
        self.on_nmi = False

        # Interruption Trigger Flags
        self.trigger_irq = False
        self.trigger_nmi = False

        self.IRQ_HANDLER_ADDRESS = 0xFFFE
        self.NMI_HANDLER_ADDRESS = 0XFFFA

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
            0x69: self.adc_immediate,
            0x65: self.adc_zero_page,
            0x75: self.adc_zero_page_x,
            0x6D: self.adc_absolute,
            0x7D: self.adc_absolute_x,
            0x79: self.adc_absolute_y,
            0x61: self.adc_indirect_x,
            0x71: self.adc_indirect_y,
            0x29: self.and_immediate,
            0x25: self.and_zero_page,
            0x35: self.and_zero_page_x,
            0x2D: self.and_absolute,
            0x3D: self.and_absolute_x,
            0x39: self.and_absolute_y,
            0x21: self.and_indirect_x,
            0x31: self.and_indirect_y,
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
            0xE9: self.sbc_immediate,
            0xE5: self.sbc_zero_page,
            0xF5: self.sbc_zero_page_x,
            0xED: self.sbc_absolute,
            0xFD: self.sbc_absolute_x,
            0xF9: self.sbc_absolute_y,
            0xE1: self.sbc_indirect_x,
            0xF1: self.sbc_indirect_y,
            0xAA: self.tax,
            0xA8: self.tay,
            0xBA: self.tsx,
            0x8A: self.txa,
            0x9A: self.txs,
            0x98: self.tya,
            0x38: self.sec,
            0xF8: self.sed,
            0x78: self.sei,
            0xD8: self.cld,
            0x58: self.cli,
            0xB8: self.clv,
            0xC9: self.cmp_imediate,
            0xC5: self.cmp_zero_page,
            0xD5: self.cmp_zero_page_x,
            0xCD: self.cmp_absolute,
            0xDD: self.cmp_absolute_x,
            0xD9: self.cmp_absolute_y,
            0xC1: self.cmp_indexed_indirect,
            0xD1: self.cmp_indirect_indexed,
            0xE0: self.cpx_immediate,
            0xE4: self.cpx_zero_page,
            0xEC: self.cpx_absolute,
            0xC0: self.cpy_immediate,
            0xC4: self.cpy_zero_page,
            0xCC: self.cpy_absolute,
            0xCA: self.dex,
            0x88: self.dey,
            0xC6: self.dec_zero_page,
            0xD6: self.dec_zero_page_x,
            0xCE: self.dec_absolute,
            0xDE: self.dec_absolute_x,
            0xE6: self.inc_zero_page,
            0xF6: self.inc_zero_page_x,
            0xEE: self.inc_absolute,
            0xFE: self.inc_absolute_x,
            0xE8: self.inx,
            0xC8: self.iny,
            0x48: self.pha,
            0x08: self.php,
            0x68: self.pla,
            0x28: self.plp,
            0x20: self.jsr,
            0xEA: self.nop,
            0x4A: self.lsr_accumulator,
            0x46: self.lsr_zero_page,
            0x56: self.lsr_zero_page_x,
            0x4E: self.lsr_absolute,
            0x5E: self.lsr_absolute_x,
            0x2A: self.rol_accumulator,
            0x26: self.rol_zero_page,
            0x36: self.rol_zero_page_x,
            0x2E: self.rol_absolute,
            0x3E: self.rol_absolute_x,
            0x6A: self.ror_accumulator,
            0x66: self.ror_zero_page,
            0x76: self.ror_zero_page_x,
            0x6E: self.ror_absolute,
            0x7E: self.ror_absolute_x,
            0x49: self.eor_immediate,
            0x45: self.eor_zero_page,
            0x55: self.eor_zero_page_x,
            0x4D: self.eor_absolute,
            0x5D: self.eor_absolute_x,
            0x59: self.eor_absolute_y,
            0x41: self.eor_indirect_x,
            0x51: self.eor_indirect_y,
            0x4C: self.jmp_absolute,
            0x6C: self.jmp_indirect,
            0x60: self.rts,
            0x40: self.rti, 
            0x09: self.ora_immediate, 
            0x05: self.ora_zero_page,
            0x15: self.ora_zero_page_x,
            0x0D: self.ora_absolute,
            0x1D: self.ora_absolute_x,
            0x19: self.ora_absolute_y,
            0x01: self.ora_indexed_indirect,
            0x11: self.ora_indirect_indexed
        }

    def get_reset_address(self):
        return self.mem[0xfffc] | self.mem[0xfffd] << 8

    def get_bytes(self, size):
        position = self.pc + 1
        data = self.mem[position:position + size]
        self.pc += np.uint16(size)
        return data

    # Set flags
    def set_zero_and_neg(self, register):
        if register == 0:
            self.zero = 1
        else:
            self.zero = 0
        self.set_negative_to_bit_7(register)

    def set_negative_to_bit_7(self, value):
        self.negative = value >> 7

    # Addressing Modes
    def immediate(self):
        return self.get_bytes(1)[0]

    def zero_page(self):
        return self.get_bytes(1)[0]

    def zero_page_x(self):
        return np.uint8(self.zero_page() + self.x)
    
    def zero_page_y(self):
        return np.uint8(self.zero_page() + self.y)

    def absolute_address(self):
        data = self.get_bytes(2)
        return (data[1] << 8) + data[0]

    def relative_address(self):
        offset = self.get_bytes(1)[0]
        return np.int8(offset)

    def indexed_indirect(self):
        value = self.get_bytes(1)[0]
        location = np.uint8(value + self.x)
        return self.mem[location] + (self.mem[np.uint8(location + 1)] << 8)

    def indirect_indexed(self):
        location = self.get_bytes(1)[0]
        return self.mem[location] + (self.mem[np.uint8(location + 1)] << 8) + self.y

    def indirect(self):
        data = self.get_bytes(2)
        location = np.uint16((data[1] << 8) + data[0])
        return location

        #write value in mem[address]
    def write_memory(self, address, value):

        #Write memory in zero page
        if address < 0x2000:
            address = address % 0x800
            self.mem[address] = value

        #Write memory in ppu flags
        elif address < 0x4000:
            address = address % 0x2008
            self.mem[address] = value
            if address == 0x2000:
                self.ppu_ref.write_ppuctrl(value)
                self.nmi_activated = (value & 0b10000000) > 0
            elif address == 0x2001:
                self.ppu_ref.write_ppumask(value)
            elif address == 0x2003:
                self.ppu_ref.write_oamaddr(value)

            elif address == 0x2004:
                self.ppu_ref.write_oamdata(value)

            elif address == 0x2005:
                self.ppu_ref.write_scroll(value)

            elif address == 0x2006:
                self.ppu_ref.write_address(value)

            elif address == 0x2007:
                self.ppu_ref.write_data(value)

                

        elif address == 0x4014:
            self.mem[address] = value
            dma_address = np.uint16((value << 8) + self.mem[0x2003])
            self.ppu_ref.write_spr_ram_dma(self.mem[dma_address : dma_address + 0x0100])
        #Flag for ordering controls
        elif address == 0x4016:
            if self.firstWrite == 0:
                if value == 1:
                    self.firstWrite = 1
            elif self.firstWrite == 1:
                if value == 0:
                    self.readControls = 1
                    self.timeControl = 0
        else:
            self.mem[address] = value

            
    def read_memory(self ,address):
        value = 0x00
        if address < 0x2000:
            address = address % 0x800
            value = self.mem[address]
        elif address < 0x4000:
            address = address % 0x2008
            if address == 0x2002:
                value = self.ppu_ref.read_ppustatus()
            elif address == 0x2004:
                value = self.ppu_ref.read_oamdata()
            elif address == 0x2007:
                value = self.ppu_ref.read_data()
            else:
                value = self.mem[address]
        elif address == 0x4016:
            if self.readControls == 1:
                if self.timeControl == 0:
                    value = self.keys[pygame.K_e]
                elif self.timeControl == 1:
                    value = self.keys[pygame.K_r]
                elif self.timeControl == 2:
                    value = self.keys[pygame.K_SPACE]
                elif self.timeControl == 3:
                    value = self.keys[pygame.K_RETURN]
                elif self.timeControl == 4:
                    value = self.keys[pygame.K_w]
                elif self.timeControl == 5:
                    value = self.keys[pygame.K_s]
                elif self.timeControl == 6:
                    value = self.keys[pygame.K_a]
                elif self.timeControl == 7:
                    value = self.keys[pygame.K_d]
                    
                
                self.timeControl += 1
                if self.timeControl == 8:
                    self.readControls = 0
                    self.firstWrite = 0
        else:
            value = self.mem[address]

        return value
    # Instructions
    def brk(self):
        """
        Force Interrupt
        """
        # self.break_cmd = True
        # self.pc += 1
        # self.trigger_irq = True
        self.running = False
        return None, 2

    def clc(self):
        """
        Clear Carry Flag
        """
        self.carry = 0
        return None, 2

    def bit(self, address):
        """
        Bit Test
        """
        memory_value = self.read_memory(address)
        
        if (self.a & memory_value) == np.uint8(0):
            self.zero = 1
        else:
            self.zero = 0

        # Set V to bit 6 of the memory value
        self.overflow = (memory_value >> 6) & 1
        self.set_negative_to_bit_7(memory_value)

    def bit_zero_page(self):
        address = self.zero_page()
        self.bit(address)
        return address, 3

    def bit_absolute(self):
        address = self.absolute_address()
        self.bit(address)
        return address, 4

    def bcc(self):
        """
        Branch if Carry Clear
        """
        offset = self.relative_address()
        if self.carry == 0:
            self.pc += offset
            return None, 3
        return None, 2

    def bcs(self):
        """
        Branch if Carry Set
        """
        offset = self.relative_address()
        if self.carry == 1:
            self.pc += offset
            return None, 3
        return None, 2

    def beq(self):
        """
        Branch if Equal
        """
        offset = self.relative_address()
        if self.zero == 1:
            self.pc += offset
            return None, 3
        return None, 2

    def bne(self):
        """
        Branch if Not Equal
        """
        offset = self.relative_address()
        if self.zero == 0:
            self.pc += offset
            return None, 3
        return None, 2

    def bpl(self):
        """
        Branch if Positive
        """
        offset = self.relative_address()
        if self.negative == 0:
            self.pc += offset
            return None, 3
        return None, 2

    def bmi(self):
        """
        Branch if Minus
        """
        offset = self.relative_address()
        if self.negative == 1:
            self.pc += offset
            return None, 3
        return None, 2

    def bvc(self):
        """
        Branch if Overflow Clear
        """
        offset = self.relative_address()
        if self.overflow == 0:
            self.pc += offset
            return None, 3
        return None, 2

    def bvs(self):
        """
        Branch if Overflow Set
        """
        offset = self.relative_address()
        if self.overflow == 1:
            self.pc += offset
            return None, 3
        return None, 2

    def adc(self, value):
        """
        Add with Carry
        """
        total = np.uint32(self.a) + value + self.carry
        self.overflow = 1 if ~(self.a ^ value) & (self.a ^ total) & 0x80 > 0 else 0
        if total > np.iinfo(np.uint8).max:
            self.a = np.uint8(total - np.iinfo(np.uint8).max - 1)
            self.carry = 1
        else:
            self.carry = 0
            self.a = np.uint8(total)
        self.set_zero_and_neg(self.a)

    def adc_immediate(self):
        value = self.immediate()
        self.adc(value)
        return None, 2

    def adc_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.adc(value)
        return address, 3

    def adc_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.adc(value)
        return address, 4

    def adc_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.adc(value)
        return address, 4

    def adc_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.adc(value)
        return address, 4

    def adc_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.adc(value)
        return address, 4

    def adc_indirect_x(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.adc(value)
        return address, 6

    def adc_indirect_y(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.adc(value)
        return address, 5

    def logical_and(self, value):
        """
        Bitwise AND of the operand with the accumulator
        :param value: operand of one byte
        """
        self.a = self.a & value
        self.set_zero_and_neg(self.a)

    def and_immediate(self):
        value = self.immediate()
        self.logical_and(value)
        return None, 2

    def and_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 3

    def and_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 4

    def and_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 4

    def and_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 4

    def and_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 4

    def and_indirect_x(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 6

    def and_indirect_y(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.logical_and(value)
        return address, 5

    def asl(self, value_to_shift):
        """
        Arithmetic Shift Left
        """
        # Set C to contents of old bit 7
        self.carry = value_to_shift >> 7
        # Shift all the bits one bit left
        result = value_to_shift << np.uint8(1)
        self.set_zero_and_neg(result)

        return result

    def asl_accumulator(self):
        self.a = self.asl(self.a)
        return None, 2

    def asl_zero_page(self):
        address = self.zero_page()
        value_memory = self.read_memory(address)
        value = self.asl(value_memory)
        self.write_memory(address, value)
        return address, 5

    def asl_zero_page_x(self):
        address = self.zero_page_x()
        value_memory = self.read_memory(address)
        value = self.asl(value_memory)
        self.write_memory(address, value)
        return address, 6

    def asl_absolute(self):
        address = self.absolute_address()
        value_memory = self.read_memory(address)
        value = self.asl(value_memory)
        self.write_memory(address, value)
        return address, 6

    def asl_absolute_x(self):
        address = self.absolute_address() + self.x
        value_memory = self.read_memory(address)
        value = self.asl(value_memory)
        self.write_memory(address, value)
        return address, 7

    def lda_immediate(self):
        self.a = self.immediate()
        self.set_zero_and_neg(self.a)
        return None, 2

    def ldx_immediate(self):
        self.x = self.immediate()
        self.set_zero_and_neg(self.x)
        return None, 2

    def ldy_immediate(self):
        self.y = self.immediate()
        self.set_zero_and_neg(self.y)
        return None, 2

    def lda_zero_page(self):
        address = self.zero_page()
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 3

    def ldx_zero_page(self):
        address = self.zero_page()
        self.x = self.read_memory(address)
        self.set_zero_and_neg(self.x)
        return address, 3

    def ldy_zero_page(self):
        address = self.zero_page()
        self.y = self.read_memory(address)
        self.set_zero_and_neg(self.y)
        return address, 3

    def lda_zero_page_x(self):
        address = self.zero_page_x()
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 4

    def ldx_zero_page_y(self):
        address = self.zero_page_y()
        self.x = self.read_memory(address)
        self.set_zero_and_neg(self.x)
        return address, 4

    def ldy_zero_page_x(self):
        address = self.zero_page_x()
        self.y = self.read_memory(address)
        self.set_zero_and_neg(self.y)
        return address, 4

    def lda_absolute(self):
        address = self.absolute_address()
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 4

    def ldx_absolute(self):
        address = self.absolute_address()
        self.x = self.read_memory(address)

        self.set_zero_and_neg(self.x)
        return address, 4

    def ldy_absolute(self):
        address = self.absolute_address()
        self.y = self.read_memory(address)

        self.set_zero_and_neg(self.y)
        return address, 4

    def lda_absolute_x(self):
        address = self.absolute_address() + self.x
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 4

    def lda_absolute_y(self):
        address = self.absolute_address() + self.y
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 4

    def ldx_absolute_y(self):
        address = self.absolute_address() + self.y
        self.x = self.read_memory(address)
        self.set_zero_and_neg(self.x)
        return address, 4

    def ldy_absolute_x(self):
        address = self.absolute_address() + self.x
        self.y = self.read_memory(address)
        self.set_zero_and_neg(self.y)
        return address, 4

    def lda_indexed_indirect(self):
        address = self.indexed_indirect()
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 6

    def lda_indirect_indexed(self):
        address = self.indirect_indexed()
        self.a = self.read_memory(address)
        self.set_zero_and_neg(self.a)
        return address, 5

    def push_to_stack(self, value):
        self.mem[self.sp] = value
        self.sp -= np.uint16(1)
        if self.sp < 0x0100:
            self.sp = 0x01ff - (0x0ff - self.sp)

    def pull_from_stack(self):
        self.sp += np.uint16(1)
        if self.sp > 0x01ff:
            self.sp = 0x0100 + (self.sp - 0x01ff)
        value = self.mem[self.sp]
        return value

    def pha(self):
        self.push_to_stack(self.a)
        return self.sp+1, 3

    def php(self):
        self.push_to_stack(self.get_p())
        return self.sp+1, 3

    def pla(self):
        self.a = self.pull_from_stack()
        self.set_zero_and_neg(self.a)
        return self.sp, 4

    def plp(self):
        self.set_p(self.pull_from_stack())
        return self.sp, 4

    def jsr(self):
        address = self.absolute_address()
        self.push_pc_to_stack()
        self.pc = np.uint16(address - 1)
        return None, 6

    def nop(self):
        return None, 2

    def lsr(self, value):
        self.carry = value & 1
        shift_value = value >> 1
        self.set_zero_and_neg(shift_value)
        return np.uint8(shift_value)

    def lsr_accumulator(self):
        self.a = self.lsr(self.a)
        return None, 2

    def lsr_zero_page(self):
        address = self.zero_page()
        memory = self.read_memory(address)
        value = self.lsr(memory)
        self.write_memory(address, value)
        return address, 5

    def lsr_zero_page_x(self):
        address = self.zero_page_x()
        memory = self.read_memory(address)
        value = self.lsr(memory)
        self.write_memory(address, value)
        return address, 6

    def lsr_absolute(self):
        address = self.absolute_address()
        memory = self.read_memory(address)
        value = self.lsr(memory)
        self.write_memory(address, value)
        return address, 6

    def lsr_absolute_x(self):
        address = self.absolute_address() + self.x
        memory = self.read_memory(address)
        value = self.lsr(memory)
        self.write_memory(address, value)
        return address, 7

    def rol(self, value):
        temp_carry = (value & 10000000) >> 7
        shift_value = value << 1
        shift_value = np.uint8(shift_value | self.carry)
        self.carry = temp_carry
        self.set_zero_and_neg(shift_value)
        return shift_value

    def ror(self, value):
        temp_carry = value & 1
        shift_value = value >> 1
        shift_value = np.uint8(shift_value | (self.carry << 7))
        self.carry = temp_carry
        self.set_zero_and_neg(shift_value)
        return shift_value

    def rol_accumulator(self):
        self.a = self.rol(self.a)
        return None, 2

    def rol_zero_page(self):
        address = self.zero_page()
        value_memory = self.read_memory((address))
        value = self.rol(value_memory)
        self.write_memory(address, value)
        return address, 5

    def rol_zero_page_x(self):
        address = self.zero_page_x()
        value_memory = self.read_memory((address))
        value = self.rol(value_memory)
        self.write_memory(address, value)
        return address, 6

    def rol_absolute(self):
        address = self.absolute_address()
        value_memory = self.read_memory((address))
        value = self.rol(value_memory)
        self.write_memory(address, value)
        return address, 6

    def rol_absolute_x(self):
        address = self.absolute_address() + self.x
        value_memory = self.read_memory((address))
        value = self.rol(value_memory)
        self.write_memory(address, value)
        return address, 7

    def ror_accumulator(self):
        self.a = self.ror(self.a)
        return None, 2

    def ror_zero_page(self):
        address = self.zero_page()
        value_memory = self.read_memory((address))
        value = self.ror(value_memory)
        self.write_memory(address, value)
        return address, 5

    def ror_zero_page_x(self):
        address = self.zero_page_x()
        value_memory = self.read_memory((address))
        value = self.ror(value_memory)
        self.write_memory(address, value)
        return address, 6

    def ror_absolute(self):
        address = self.absolute_address()
        value_memory = self.read_memory((address))
        value = self.ror(value_memory)
        self.write_memory(address, value)
        return address, 6

    def ror_absolute_x(self):
        address = self.absolute_address() + self.x
        value_memory = self.read_memory((address))
        value = self.ror(value_memory)
        self.write_memory(address, value)
        return address, 7

    def rti(self):
        """
        Return from Interrupt
        """
        self.plp() 
        self.pull_pc_from_stack()
        self.on_nmi = False
        return None, 6

    def rts(self):
        """
        Return from Subroutine
        """
        self.pull_pc_from_stack()
        return None, 6

    def sbc(self, value):
        """
        Subtract with Carry
        """
        return self.adc(value ^ 0xFF)

    def sbc_immediate(self):
        value = self.immediate()
        self.sbc(value)
        return None, 2

    def sbc_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.sbc(value)
        return address, 3

    def sbc_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.sbc(value)
        return address, 4

    def sbc_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.sbc(value)
        return address, 4

    def sbc_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.sbc(value)
        return address, 4

    def sbc_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.sbc(value)
        return address, 4

    def sbc_indirect_x(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.sbc(value)
        return address, 6

    def sbc_indirect_y(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.sbc(value)
        return address, 5

    def sec(self):
        """
        Set Carry Flag
        """
        self.carry = 1
        return None, 2

    def sed(self):
        """
        Set Decimal Flag
        """
        self.decimal_mode = 1
        return None, 2

    def sei(self):
        """
        Set Interrupt Disable
        """
        self.interrupt_disable = 1
        return None, 2


    def sta_absolute(self):
        """
        Store Accumulator - Absolute
        """
        address = self.absolute_address()
        self.write_memory(address, self.a)
        #address_mirror = self.verify_mirror(address)
        #self.mem[address_mirror] = self.a
        return address, 4

    def sta_absolute_x(self):
        """
        Store Accumulator - Absolute, X
        """
        address = self.absolute_address() + self.x
        self.write_memory(address, self.a)
        return address, 5

    def sta_absolute_y(self):
        """
        Store Accumulator - Absolute, Y
        """
        address = self.absolute_address() + self.y
        self.write_memory(address, self.a)
        return address, 5

    def sta_zero_page(self):
        """
        Store Accumulator - Zero Page
        """
        address = self.zero_page()
        self.write_memory(address, self.a)
        return address, 3

    def sta_zero_page_x(self):
        """
        Store Accumulator - Zero Page, X
        """
        address = self.zero_page_x()
        self.write_memory(address, self.a)
        return address, 4

    def sta_indexed_indirect(self):
        """
        Store Accumulator - (Indirect, X)
        """
        address = self.indexed_indirect()
        self.write_memory(address, self.a)
        return address, 6

    def sta_indirect_indexed(self):
        """
        Store Accumulator - (Indirect, X)
        """
        address = self.indirect_indexed()
        self.write_memory(address, self.a)
        return address, 6

    def stx_absolute(self):
        """
        Store X Register - Absolute
        """
        address = self.absolute_address()
        self.write_memory(address, self.x)
        return address, 4

    def stx_zero_page(self):
        """
        Store X Register - Zero Page
        """
        address = self.zero_page()
        self.write_memory(address, self.x)
        return address, 3

    def stx_zero_page_y(self):
        """
        Store X Register - Zero Page, Y
        """
        address = self.zero_page_y()
        self.write_memory(address, self.x)
        return address, 4

    def sty_absolute(self):
        """
        Store Y Register - Absolute
        """
        address = self.absolute_address()
        self.write_memory(address, self.y)
        return address, 4

    def sty_zero_page(self):
        """
        Store Y Register - Zero Page
        """
        address = self.zero_page()
        self.write_memory(address, self.y)
        return address, 3

    def sty_zero_page_x(self):
        """
        Store Y Register - Zero Page, X
        """
        address = self.zero_page_x()
        self.write_memory(address, self.y)
        return address, 4

    def tax(self):
        """
        Transfer Accumulator to X
        """
        self.x = self.a
        self.set_zero_and_neg(self.x)
        return None, 2

    def tay(self):
        """
        Transfer Accumulator to Y
        """
        self.y = self.a
        self.set_zero_and_neg(self.y)
        return None, 2

    def tsx(self):
        """
        Transfer Stack Pointer to X
        """
        self.x = self.sp & 0xFF
        self.set_zero_and_neg(self.x)
        return None, 2

    def txa(self):
        """
        Transfer X to Accumulator
        """
        self.a = self.x
        self.set_zero_and_neg(self.a)
        return None, 2

    def txs(self):
        """
        Transfer X to Stack Pointer
        """
        self.sp = 0x0100 + self.x 
        return None, 2

    def tya(self):
        """
        Transfer Y to Accumulator
        """
        self.a = self.y
        self.set_zero_and_neg(self.a)
        return None, 2

    def cld(self):
        """
        Clear Decimal mode Flag
        """
        self.decimal_mode = 0
        return None, 2

    def cli(self):
        """
        Clear interrupt Disable Flag
        """
        self.interrupt_disable = 0
        return None, 2

    def clv(self):
        """
        Clear Carry Flag
        """
        self.overflow = 0
        return None, 2

    def cmp_if(self, a, b):
        if a >= b:
            self.carry = 1
        else:
            self.carry = 0
        self.set_zero_and_neg(a - b)

    """
        Compare a and immediate
    """

    def cmp_imediate(self):
        self.cmp_if(self.a, self.immediate())
        return None, 2

    def cmp_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 3

    def cmp_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 4

    def cmp_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 4

    def cmp_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 4

    def cmp_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 4

    def cmp_indexed_indirect(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 6

    def cmp_indirect_indexed(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.cmp_if(self.a, value)
        return address, 5

    "Compare x"

    def cpx_immediate(self):
        self.cmp_if(self.x, self.immediate())
        
        return None, 2

    def cpx_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.cmp_if(self.x, value)
        return address, 3

    def cpx_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.cmp_if(self.x, value)
        return address, 4

    "Compare y"

    def cpy_immediate(self):
        self.cmp_if(self.y, self.immediate())
        return None, 2

    def cpy_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.cmp_if(self.y, value)
        return address, 3

    def cpy_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.cmp_if(self.y, value)
        return address, 4

    "Decrement 1 in value held at memory[adress]"

    def dec_zero_page(self):
        address = self.zero_page()
        value = np.uint8(0)
        value = self.read_memory(address)
        value -= 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 5

    def dec_zero_page_x(self):
        address = self.zero_page_x()
        value = np.uint8(0)
        value = self.read_memory(address)
        value -= 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 6

    def dec_absolute(self):
        address = self.absolute_address()
        value = np.uint8(0)
        value = self.read_memory(address)
        value -= 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 6

    def dec_absolute_x(self):
        address = self.absolute_address() + self.x
        value = np.uint8(0)
        value = self.read_memory(address)
        value -= 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 7

    def dex(self):
        """
        Decrement x
        """
        self.x -= np.uint8(1)
        self.set_zero_and_neg(self.x)
        return None, 2

    def dey(self):
        """
        Decrement y
        """
        self.y -= np.uint8(1)
        self.set_zero_and_neg(self.y)
        return None, 2

    "Increment 1 in value held at memory[adress]"

    def inc_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        value += 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 5

    def inc_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        value += 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 6

    def inc_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        value += 1
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 6

    def inc_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        value += np.uint(1)
        self.write_memory(address, value)
        self.set_zero_and_neg(value)
        return address, 7

    def inx(self):
        """
        Increment 1 in x
        """
        self.x += np.uint8(1)
        self.set_zero_and_neg(self.x)
        return None, 2

    def iny(self):
        """
        Increment 1 in y
        """
        self.y += np.uint8(1)
        self.set_zero_and_neg(self.y)
        return None, 2

    def logical_eor(self, value):
        """
        Bitwise XOR of the operand with the accumulator
        :param value: operand of one byte
        """
        self.a = self.a ^ value
        self.set_zero_and_neg(self.a)

    def eor_immediate(self):
        value = self.immediate()
        self.logical_eor(value)
        return None, 2

    def eor_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 3

    def eor_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 4

    def eor_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 4

    def eor_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 4

    def eor_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 4

    def eor_indirect_x(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 6

    def eor_indirect_y(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.logical_eor(value)
        return address, 5

    def ora(self, value):
        self.a = np.uint8(value | self.a)
        self.set_zero_and_neg(self.a)

    def ora_immediate(self):
        value = self.immediate()
        self.ora(value)
        return None, 2

    def ora_zero_page(self):
        address = self.zero_page()
        value = self.read_memory(address)
        self.ora(value)
        return address, 3

    def ora_zero_page_x(self):
        address = self.zero_page_x()
        value = self.read_memory(address)
        self.ora(value)
        return address, 4

    def ora_absolute(self):
        address = self.absolute_address()
        value = self.read_memory(address)
        self.ora(value)
        return address, 4

    def ora_absolute_x(self):
        address = self.absolute_address() + self.x
        value = self.read_memory(address)
        self.ora(value)
        return address, 4

    def ora_absolute_y(self):
        address = self.absolute_address() + self.y
        value = self.read_memory(address)
        self.ora(value)
        return address, 4

    def ora_indexed_indirect(self):
        address = self.indexed_indirect()
        value = self.read_memory(address)
        self.ora(value)
        return address, 6

    def ora_indirect_indexed(self):
        address = self.indirect_indexed()
        value = self.read_memory(address)
        self.ora(value)
        return address, 5

    def jmp_absolute(self):
        address = self.absolute_address()
        self.pc = np.uint16(address - 1)
        return None, 3

    def jmp_indirect(self):
        address = self.indirect()
        value_memory1 = self.read_memory(address)
        value_memory2 = self.read_memory(address + 1)
        self.pc = np.uint16(value_memory1 + (value_memory2 << 8)) - 1
        return None, 5
    def trigger_interruption(self, read_address):
        """
        Triggers Interruption by pushing PC and P to the stack and
        transfering control flow to given address
        """
        self.push_pc_to_stack()
        self.php()
        self.pc = (self.mem[read_address + 1] << 8) + self.mem[read_address]
    
    def push_pc_to_stack(self):
        low = self.pc & 0x00FF
        big = self.pc >> 8
        self.push_to_stack(big)
        self.push_to_stack(low)
    
    def pull_pc_from_stack(self):
        low = self.pull_from_stack()
        big = self.pull_from_stack()
        self.pc = low | (big << 8)

    def hex_format(self, value, leading_zeros):
        format_string = "{0:0%sX}" % leading_zeros
        return ("0x" + format_string.format(int(value))).lower()

    def bin_format(self, value):
        return "{0:08b}".format(value)

    def get_p(self):
        return (self.negative << 7 |
                self.overflow << 6 |
                1 << 5 |  # assumes bit 5 is always set TODO check if this is correct
                self.break_cmd << 4 |
                self.decimal_mode << 3 |
                self.interrupt_disable << 2 |
                self.zero << 1 |
                self.carry)

    def set_p(self, value):
        self.negative = value >> 7 & 1
        self.overflow = value >> 6 & 1
        self.break_cmd = value >> 4 & 1
        self.decimal_mode = value >> 3 & 1
        self.interrupt_disable = value >> 2 & 1
        self.zero = value >> 1 & 1
        self.carry = value & 1

    def print_state(self):
        print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s |" % \
              (self.hex_format(self.pc, 4),
               self.hex_format(self.a, 2),
               self.hex_format(self.x, 2),
               self.hex_format(self.y, 2),
               self.hex_format(self.sp, 4),
               self.bin_format(self.get_p())))

    def print_state_ls(self, address):
        value = self.read_memory(address)
        print("| pc = %s | a = %s | x = %s | y = %s | sp = %s | p[NV-BDIZC] = %s | MEM[%s] = %s |" % \
              (self.hex_format(self.pc, 4),
               self.hex_format(self.a, 2),
               self.hex_format(self.x, 2),
               self.hex_format(self.y, 2),
               self.hex_format(self.sp, 4),
               self.bin_format(self.get_p()),
               self.hex_format(address, 4),
               self.hex_format(value, 2)))

    def run(self):
        sleep_time = 0
        run_count = 0 # instructions count
        start = time.time() # timer start
        cycles = 0 # cycles accumulated so far
        while self.running:
            if self.trigger_irq:
                self.trigger_interruption(self.IRQ_HANDLER_ADDRESS)
                self.interrupt_disable = 1
                self.trigger_irq = False
            elif self.trigger_nmi:
                self.trigger_interruption(self.NMI_HANDLER_ADDRESS)
                self.trigger_nmi = False

            mem_byte = self.mem[self.pc]
            cycles = cycles + self.execute(opcode=mem_byte)
            run_count = run_count + 1


            pygame.event.poll()
            self.keys = pygame.key.get_pressed()
            if self.keys[pygame.K_ESCAPE]:
                pygame.display.quit()
                exit()
            # every some instructions calculate sleep fraction
            if (run_count == 80):
                end = time.time()
                sleep_time += 0.0559*cycles - (end - start)
                if self.nmi_activated and not(self.on_nmi):
                    self.ppu_ref.update()
                    self.trigger_nmi = True
                    self.on_nmi = True
                start = time.time()
                run_count = 0
                cycles = 0


            # if total sleep so far is grater than the minimum required by the system sleep this time
            if sleep_time > 0.001:

                sleep_time = 0


    def execute(self, opcode):
        # Being used in order to ignore invalid opcodes
        def does_nothing():
            return "nothing"

        instruction = self.instructions.get(opcode, does_nothing)
        address, cycle = instruction()
        if opcode != 0x40:  # do not add 1 to pc when running an RTI
            self.pc += np.uint16(1)
        #if address is None and opcode != 0:
        #   self.print_state()
        #elif opcode != 0:
        #   self.print_state_ls(address)
        return cycle


def main(rom_path):
    cpu = CPU(rom_path)
    # np.seterrcall(cpu.error_handler)
    np.seterr(over='ignore')
    cpu.run()


if __name__ == "__main__":
    main(sys.argv[1])

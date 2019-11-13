import pyaudio
import numpy as np
import math

from scipy import signal

class APU:
    def __init__(self):
        p = pyaudio.PyAudio()

        #APU flags enables ports
        self.stream_square1 = 0
        self.stream_square2 = 0
        self.stream_triangle = 0
        self.stream_noise = 0
        self.stream_DMC = 0


        #
        self.volume = 0
        self.frequency = 44100
        self.length = 1
        self.rate = 2092


    #register 0x4015 : APU ports
    def apu_port(self,value):
        self.stream_square1 = value &1
        self.stream_square2 = value &2
        self.stream_triangle = value &4
        self.stream_noise = value &8
        self.stream_DMC = value &16

    #register 0x4000 : Square channel 1
    #Duty(2bits), Length Counter (1bit), Constant Volume(1bit), Volume (4 bits
    def square_wave1_volume(self, value):
        if self.stream_square1:
            volume = value & 0x0F
            const_volume = (value >> 4) & 0x1
            lenght_counter = (value>>5) & 0x1
            duty = (value>>6) & 0x2

    #register 0x4001: Square channel 1
    #APU sweep
    def square_wave1_sweep(self,value):
        if self.stream_square1:
            shift = value & 0x7
            negate = (value >> 3) & 1
            period = (value >> 4) & 3
            period = (value >> 7) & 1

    #register 0x4002: Square channel 1
    #Period (Low 8 bits)
    def square_wave1_periodL(self,value):
        if self.stream_square1:
            timerL = value
    
    #register 0x4003: Square channel 1
    # Length counter load (5 bits) - Period (hight 3 bits)
    def square_wave1_periodH(self, value):
        if self.stream_square1:
            timerH = value & 0x7
            lengt_counter = (value >> 3 ) & 0x1F

    def play_square1(self):
        if self.stream_square1:
            # generate samples, note conversion to float32 array
            tone = (np.sin(2*np.pi*np.arange(int(fs*duration))*f/fs)).astype(np.float32)


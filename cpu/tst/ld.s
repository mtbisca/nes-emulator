.org $4020
LDA #$02
PHA
LSR
PHA
LDA clrmem
JSR clrmem
NOP
NOP
NOP

.org $C000
clrmem:
    PLA
    PLA
    PLA
    PLA
    brk
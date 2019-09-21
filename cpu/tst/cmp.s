.org $C000

; Author: tokumaru
; http://forums.nesdev.com/viewtopic.php?%20p=58138#58138
;----------------------------------------------------------------
; constants
;----------------------------------------------------------------
PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

   .enum $0000

   carLeft                 .dsw 1
  carRight                .dsw 1
  carTop                  .dsw 1
  carBottom               .dsw 1

   ;NOTE: declare variables using the DSB and DSW directives, like this:

   ;MyVariable0 .dsb 1
   ;MyVariable1 .dsb 3

   .ende

   ;NOTE: you can also split the variable declarations into individual pages, like this:

   ;.enum $0100
   ;.ende

   ;.enum $0200
   ;.ende

;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

   .db "NES", $1a ;identification of the iNES header
   .db PRG_COUNT ;number of 16KB PRG-ROM pages
   .db $01 ;number of 8KB CHR-ROM pages
   .db $00|MIRRORING ;mapper 0 and mirroring
   .dsb 9, $00 ;clear the remaining bytes

;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

   .base $10000-(PRG_COUNT*$4000)


Reset:
 ;Testing compare immediate: Negative = 1, zero = 0
LDA #128

;Compare with same number: Carry = 1, Zero = 1, Negative = 0
CMP #128

;Compare with lower number: Carry = 1, Zero = 0, Negative = 0
CMP #127

;Compare with higher number: Carry = 0, Zero = 0, Negative = 1
CMP #129

;Testing compare Zero Page: Store 9 in zero page 01
                                ;10 in zero page 02
                                ;11 in zero page 03
LDA #$9
STA $01
LDA #$11
STA $03
LDA #$10
STA $02

;Same number
CMP $02
;Lower Number
CMP $01
;Higher Number
CMP $03

brk

NMI:

   ;NOTE: NMI code goes here

IRQ:

   ;NOTE: IRQ code goes here

;----------------------------------------------------------------
; interrupt vectors
;----------------------------------------------------------------

   .org $fffa

   .dw NMI
   .dw Reset
   .dw IRQ

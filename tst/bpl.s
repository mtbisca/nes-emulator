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

    .ende

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
  LDA #$75
  BPL Done
  LDA #$00
Done:
  BRK

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

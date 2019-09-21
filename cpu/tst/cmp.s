.org $4020

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
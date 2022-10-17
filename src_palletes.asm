;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_PALLETES.ASM
;; -Fixed pallete data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "RODATA"

PalleteData:
    ; BG palette data
    .byte $0F,$30,$10,$00
    .byte $0F,$17,$1A,$29
    .byte $0F,$30,$10,$00
    .byte $0F,$06,$10,$00
    
    ; SPR palette data
    .byte $0F,$30,$10,$00
    .byte $0F,$24,$0F,$20
    .byte $0F,$30,$10,$00
    .byte $0F,$06,$10,$00
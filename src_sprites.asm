;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_SPRITES.ASM
;; -Fixed sprite data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "RODATA"
	
vPadInitY = $67
	
SprP1:
    .byte $00+vPadInitY,$03,$00,$0F
    .byte $08+vPadInitY,$04,$00,$0F
    .byte $0C+vPadInitY,$04,$00,$0F
    .byte $10+vPadInitY,$04,$00,$0F
    .byte $18+vPadInitY,$05,$00,$0F
	
SprP2:
    .byte $00+vPadInitY,$03,%01000000,$E8
    .byte $08+vPadInitY,$04,%01000000,$E8
    .byte $0C+vPadInitY,$04,%01000000,$E8
    .byte $10+vPadInitY,$04,%01000000,$E8
    .byte $18+vPadInitY,$05,%01000000,$E8
	
SprBall:
    ; Draw behind background
    .byte $78,$06,%00100000,$78
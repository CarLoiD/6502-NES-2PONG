;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_STRINGS.ASM
;; -Fixed string text data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "RODATA"

StrPlayer1Wins:
	.byte "P1",$00,"WINS",$5F ; P1 WINS!

StrPlayer2Wins:
	.byte "P2",$00,"WINS",$5F ; P2 WINS!

StrPressStart:
	.asciiz "PRESS START" ; PRESS START
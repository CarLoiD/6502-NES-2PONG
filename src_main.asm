;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_MAIN.ASM
;; -Main game routine/console setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NES header

.segment "HEADER"
	.byte $4E, $45, $53, $1A    ; iNES Header
	.byte 2                     ; 32KB PRG code (2x16KB)
	.byte 1                     ;  8KB CHR data (1x8KB)
	.byte $01, $00              ; Mapper 0, v-mirror (1) h-mirror (0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc. segments

.segment "VECTORS"
	.addr NMI
	.addr RESET
	.addr 0		; No IRQ/BRK

.segment "CHARS"
	.incbin "bin_graphics.chr"

.segment "STARTUP"
.segment "CODE"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Source includes

.include "src_defines.asm"
.include "src_macros.asm"
.include "src_interrupts.asm"
.include "src_strings.asm"
.include "src_palletes.asm"
.include "src_sprites.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Code aliases

;; prefix: a -> address, v -> value

vBallMoveDelay  = $01
vBallWaitDelay	= $1F
vScoreToWin		= $09

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Zero Page data aliases

aDbgCounter		= $00
aPad0Buttons	= $01
aTmpCounterHi	= $02
aTmpCounterLo	= $03
aFrameCounterHi	= $04
aFrameCounterLo	= $05
aScrollX		= $06
aScrollY		= $07
aPlayer1Vel		= $08
aPlayer1Dir		= $09
aPlayer2Vel		= $0A
aPlayer2Dir		= $0B
aBallVelX		= $0C
aBallDirH		= $0D
aGameScoreP1	= $0E
aGameScoreP2	= $0F
aGameMode		= $10 ; (VS_MODE, END)
aPlayerTimerHi	= $11
aPlayerTimerLo	= $12
aBallTimer		= $14
aBallDirV		= $15
aBallVelY		= $16
aBallPosX		= $17
aBallPosY		= $18
aGameWinner		= $19
aPlayer1YPos	= $1A
aPlayer2YPos	= $1B

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Game code

VersusModeInit:
	LDA #vBallMoveDelay-1
	STA aBallTimer
	
	LDA SprBall+0 ; Init Y pos
	STA aBallPosY
	LDA SprBall+3 ; Init X Position
	STA aBallPosX
	
	LDA SprP1+0
	STA aPlayer1YPos
	LDA SprP2+0
	STA aPlayer2YPos

	JSR WaitVblank     ; Make sure PPU is ready
	
	; Ready the PPU for receiving pallete data
	LDA sPPUStatus

	LDA #$3F
	STA sPPUVramAddr
	LDA #$00
	STA sPPUVramAddr

	LDX #$00

@LoadPallete:
	LDA PalleteData, X
	STA sPPUVramData
	INX						; x index + 1
	CPX #$20				; x index < 32 ?
	BNE @LoadPallete 

@PreDrawGraphics:
	; Draw field elements
	JSR DrawDottedLines
	JSR DrawField
	JSR InitBallSpr
	JSR InitPlayer1Spr
	JSR InitPlayer2Spr
	
@EnableRendering:	
	CLI				; Enable IRQs

	LDA #%10010000	; Enable NMI, Sprite and BG table set
	STA sPPUControl
	LDA #%00011110	; Enable Sprites/BG
	STA sPPUMask

VersusModeUpdate:
	LDX aGameMode ; Check for a state change
	CPX #$01
	BEQ @GotoEndMode
	JMP @ProcessVersusMode
	
@GotoEndMode:
	JMP EndModeInit

@ProcessVersusMode:
	LDA aPad0Buttons
	AND #sPadRight
	CMP #sPadRight
	BNE @BtnCheckLeft

	;; Right pad0 button pressed
	
	JMP @AfterBtnCheck

@BtnCheckLeft:
	LDA aPad0Buttons
	AND #sPadLeft
	CMP #sPadLeft
	BNE @BtnNotPressed

	;; Left pad0 button pressed

	JMP @AfterBtnCheck

@BtnNotPressed:

@AfterBtnCheck: 
	LDX aBallTimer
	CPX #vBallMoveDelay
	BNE @SkipBallUpdate
	LDA #$00				; Zero timer
	STA aBallTimer
	
	; Y Position
	LDA $0228
	STA aBallPosY

	; X Position
	
	LDA aBallDirH
	CMP #$00
	BEQ @BallSubtractDirH
	BNE @BallAddDirH

@BallSubtractDirH:	
	LDA $022B
	SEC
	SBC #$02
	STA aBallPosX
	JMP @CheckCollisions
	
@BallAddDirH:
	LDA $022B
	CLC
	ADC #$02
	STA aBallPosX

@CheckCollisions:
	LDX aBallPosX
	CPX #$00
	BEQ @P2Score
	BCC @P2Score
	
	CPX #$F8
	BCS @P1Score
	BEQ @P1Score
	
	JMP @SkipBallUpdate

@P2Score:
	JSR RestartBallPos
	JSR FlipBallDirH
	INC aGameScoreP2
	JMP @SkipBallUpdate

@P1Score:
	JSR RestartBallPos
	JSR FlipBallDirH
	INC aGameScoreP1
	
@SkipBallUpdate:

@CheckScore:
	LDX aGameScoreP1
	CPX #vScoreToWin
	BEQ @ScoreP1Win
	
	LDX aGameScoreP2
	CPX #vScoreToWin
	BEQ @ScoreP2Win
	
	JMP @SkipScoreCheck

@ScoreP1Win:
	LDA #$01
	STA aGameWinner
	JMP @SomeoneWins

@ScoreP2Win:
	LDA #$02
	STA aGameWinner

@SomeoneWins:
	LDA #$01
	STA aGameMode	; END
	LDA #$F8		; Hide the ball
	STA aBallPosX

@SkipScoreCheck:
	JMP VersusModeUpdate	;; Repeat itself

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndModeInit:
	
EndModeUpdate:
	JMP EndModeUpdate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Subroutines

UpdatePad0Data:
	LDA #$01
	STA sPad0Addr
	LDA #$00
	STA sPad0Addr

	LDX #$08
@Loop:
	LDA sPad0Addr
	LSR A
	ROL aPad0Buttons
	DEX
	BNE @Loop

	RTS

ObjAttrDMATransfer:
	; Transfer OAM
	LDA #$02
	STA sPPUObjAttrDma
	RTS

WaitVblank:
	BIT sPPUStatus
	BPL WaitVblank
	RTS

SetNametablePtrJmp01:
	LDA #%10010000
	STA sPPUControl
	RTS

SetNametablePtrJmp32:
	LDA #%10010100
	STA sPPUControl
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PLAYER 1

InitPlayer1Spr:
	CLC
	LDX #$00

@Loop:
	LDA SprP1, X
	STA $0200, X
	INX
	CPX #$14
	BNE @Loop

	RTS
	
UpdatePlayer1Spr:
	CLC
	
	LDA aPlayer1YPos
	LDX #$00
	LDY #$00

@Loop:
	STA $0200, Y
	ADC #$08
	INY				; Y=Y+4
	INY
	INY
	INY
	INX				; ++X
	CPX #$05		; 5 chars
	BNE @Loop
	
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PLAYER 2

InitPlayer2Spr:
	CLC
	LDX #$00
	
@Loop:
	LDA SprP2, X
	STA $0214, X
	INX
	CPX #$14
	BNE @Loop
	
	RTS

UpdatePlayer2Spr:
	CLC
	
	LDA aPlayer2YPos
	LDX #$00
	LDY #$00

@Loop:
	STA $0214, Y
	ADC #$08
	INY				; Y=Y+4
	INY
	INY
	INY
	INX				; ++X
	CPX #$05		; 5 chars
	BNE @Loop

	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BALL

InitBallSpr:
	CLC
	LDX #$00
	
	; Y Position
	LDA SprBall, X
	STA $0228, X
	INX
	
	; Tile ID
	LDA SprBall, X
	STA $0228, X
	INX
	
	; Props
	LDA SprBall, X
	STA $0228, X
	INX

	; X Position
	LDA SprBall, X
	STA $0228, X
	
	RTS

UpdateBallSpr:
	LDA aBallPosX
	STA $022B ; X position
	LDA aBallPosY
	STA $0228 ; Y position
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartBallPos:	
	LDA #$78
	STA aBallPosX ; X position
	STA aBallPosY ; Y position
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


FlipBallDirH:
	LDA aBallDirH
	EOR #$01
	STA aBallDirH
	RTS

FlipBallDirV:
	LDA aBallDirV
	EOR #$01
	STA aBallDirV
	RTS
	
	
DrawWinner:
	; X contains the winner
	LDX aGameWinner
	CPX #$02	; Did player 2 wins?
	BEQ @DrawP2Wins
	CPX #$01
	BEQ @DrawP1Wins	; Player 1 wins..
	JMP @PostDraw	; [DEBUG] if none, error?
	
	JSR SetNametablePtrJmp01
	
@DrawP1Wins:
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$86
	STA sPPUVramAddr
	
	LDX #$00
	
@LoopP1:
	LDA StrPlayer1Wins, X
	STA sPPUVramData
	INX
	CPX #$08
	BNE @LoopP1
	
	JMP @PostDraw

@DrawP2Wins:
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$91
	STA sPPUVramAddr
	
	LDX #$00
	
@LoopP2:
	LDA StrPlayer2Wins, X
	STA sPPUVramData
	INX
	CPX #$08
	BNE @LoopP2
	
@PostDraw:
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MISC DRAW

DrawDottedLines:
	; This will use the hw feature of
	;incrementing the ptr by 32 each write
	JSR SetNametablePtrJmp32
	
	; Set VRAM address at $200F
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$2F
	STA sPPUVramAddr
	
	LDA #$10	; Dotted tile
	LDX #$00
@Loop:
	STA sPPUVramData
	INX
	CPX #$1C
	BNE @Loop
	
	; Reset to +1 ptr increase every vram write
	JSR SetNametablePtrJmp01
	RTS
	
DrawField:
	JSR SetNametablePtrJmp01
	
	; Draw first the top and bottom lines
	
	; TOP
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$00
	STA sPPUVramAddr
	
	LDA #$01	; Blank white tile
	LDX #$00

@Loop1:
	STA sPPUVramData
	INX
	CPX #$20
	BNE @Loop1
	
	; BOTTOM
	LDA sPPUStatus
	LDA #$23
	STA sPPUVramAddr
	LDA #$A0
	STA sPPUVramAddr
	
	LDA #$01	; Blank white tile
	LDX #$00
	
@Loop2:
	STA sPPUVramData
	INX
	CPX #$20
	BNE @Loop2
	
	; Now the left and right lines
	; This uses the advance by 32 vram ptr
	JSR SetNametablePtrJmp32
	
	; LEFT
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$20
	STA sPPUVramAddr
	
	LDA #$01
	LDX #$00

@Loop3:
	STA sPPUVramData
	INX
	CPX #$1C
	BNE @Loop3
	
	; RIGHT
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$3F
	STA sPPUVramAddr
	
	LDA #$01
	LDX #$00

@Loop4:
	STA sPPUVramData
	INX
	CPX #$1C
	BNE @Loop4
	
	RTS


DrawScore:
	CLC
	JSR SetNametablePtrJmp01
	
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$6D
	STA sPPUVramAddr
	
	LDA aGameScoreP1
	ADC #$30
	STA sPPUVramData
	
	LDA sPPUStatus
	LDA #$20
	STA sPPUVramAddr
	LDA #$71
	STA sPPUVramAddr
	
	LDA aGameScoreP2
	ADC #$30
	STA sPPUVramData
	
	
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_INTERRUPTS.ASM
;; -Interrupt routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET

RESET:
    SEI                     ; Disable IRQs
    CLD                     ; Disable decimal mode
    
    LDX #$40          
    STX $4017               ; Disable APU frame IRQ
    
    LDX #$FF                ; Set up stack
    TXS
    
    INX                     ; x = 0
    STX sPPUControl         ; Turn off the PPU
    STX sPPUMask
    STX $4010
    
    JSR WaitVblank

@ClearRAM:
    LDA #$00
    STA $0000, X    ; Zero page
    STA $0100, X
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    LDA #$F0			
    STA $0200, X    ; PPU OAM attribute buffer 
    INX
    BNE @ClearRAM
    
    LDA #$00
    STA aScrollX
    STA aScrollY
    JMP VersusModeInit
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NMI

NMI:
    JSR UpdatePad0Data
    
    ; FrameCount++
    CLC
    LDA aFrameCounterLo
    ADC #$01
    STA aFrameCounterLo
    LDA aFrameCounterHi
    ADC #$00
    STA aFrameCounterHi
    
    ; PlayerTimer++
    CLC
    LDA aPlayerTimerLo
    ADC #$01
    STA aPlayerTimerLo
    LDA aPlayerTimerHi
    ADC #$00
    STA aPlayerTimerHi
    
    ; BallTimer++
    INC aBallTimer
    
    JSR DrawScore
    JSR DrawWinner
    
    ; Reset sPPUScrol
    LDA aScrollX
    STA sPPUScroll
    LDA aScrollY
    STA sPPUScroll
    
    JSR UpdatePlayer1Spr
    JSR UpdatePlayer2Spr
    JSR UpdateBallSpr
    
    JSR ObjAttrDMATransfer
    RTI
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
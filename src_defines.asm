;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SRC_DEFINES.ASM
;; -Aliases for easy handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PPU
sPPUControl         = $2000
sPPUMask            = $2001
sPPUStatus          = $2002
sPPUSprAddr         = $2003
sPPUSprData         = $2004
sPPUScroll          = $2005
sPPUVramAddr        = $2006
sPPUVramData        = $2007
sPPUObjAttrDma      = $4014

;; PAD
;; (A, B, START, SELECT, U, D, L, R)
sPadRight           = %00000001
sPadLeft            = %00000010
sPadDown            = %00000100
sPadUp              = %00001000
sPadSelect          = %00010000
sPadStart           = %00100000
sPadB               = %01000000
sPadA               = %10000000

sPad0Addr           = $4016
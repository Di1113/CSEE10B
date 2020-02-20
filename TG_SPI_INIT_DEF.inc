;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             TG_SPI_INIT_DEF.inc                            ;
;                            Hardware Include File                           ;
;                                 Teaser Game                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware definitions for Teaser Game's SPI 
; initialization:
;   SPCR_INIT -> SPI Control Register 
;   SPSR_INIT -> SPI Status Register 
;
; Revision History of TGINIT.inc:
;     5/15/19  Di Hu      initial revision
;     5/17/19  Di Hu      modified prescaling option for TIMER0_ON
;     5/26/19  Di Hu      modified Timer0's control register
;     5/31/19  Di Hu      added PortB and Timer1's configuration for speaker
;
; Revision History:
;     6/5/19   Di Hu      - seperated out from initial TGINIT.inc file
;                         - changed filename from TGSPIINIT to TG_SPI_INIT_DEF


; SPI control register (SPCR) definition
.EQU    SPCR_INIT  = 0b01010001     ;initializing SPCR for writing a byte
                    ;  0-------      SPIE not enabled 
                    ;  -1------      SPI operations enabled
                    ;  --0-----      MSB is transmitted first  
                    ;  ---1----      Master mode selected
                    ;  ----0---      SCK is low when idle 
                    ;  -----0--      data is sampled on the leading edges
                    ;  ------10      f_osc/32s

.EQU    SPSR_INIT  = 0b00000001     ;f_osc/32s

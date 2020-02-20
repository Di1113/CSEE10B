;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_IO_INIT_DEF.inc                            ;
;                            Hardware Include File                           ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware definitions for Teaser Game's I/O ports init:
;   OUTDATA -> Port C and Port D's Data Direction Registers
;   SPKMASK, SPI_DD_INIT -> Port B's Data Direction Register
;   SSHIGH  -> Port B's Data Register 
;
; Revision History of TGINIT.inc:
;     5/15/19  Di Hu      initial revision
;     5/17/19  Di Hu      modified prescaling option for TIMER0_ON
;     5/26/19  Di Hu      modified Timer0's control register
;     5/31/19  Di Hu      added PortB and Timer1's configuration for speaker
;
; Revision History:
;     6/5/19   Di Hu      - seperated out from initial TGINIT.inc file
;                         - changed filename from TGIOINIT to TG_IO_INIT_DEF


; I/O port definitions
.EQU    OUTDATA    = 0b11111111     ;set data direction of pins all output
.EQU    SPKMASK    = 0b00100000     ;speaker bit is set to output
.EQU    SSHIGH     = 0b00000001     ;SS bit high for Port B for idle state
.EQU    SPI_DD_INIT= 0b00000111     ;Set MOSI, SCK, SS bits for data direction
                    ;  -----1--      MOSI set to output 
                    ;  ------1-      SCK set to output
                    ;  -------1      SS set to output
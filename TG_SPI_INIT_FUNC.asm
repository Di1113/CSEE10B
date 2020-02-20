;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_SPI_INIT_FUNC                              ;
;                        SPI Initialization Function                         ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the Teaser Game board's
; SPI by configuring SPI Control Register and SPI Status Register. 
; The public function(s) included are:
;    InitSPI    - initialize SPI configurations
;
; Revision History of TGINIT.asm:
;     5/17/19   Di Hu      initial revision
;     5/31/19   Di Hu      added Port B and Timer1's configuration for speaker
;     6/5/19    Di Hu      initalized ports other than Port B, Port C, Port D
;
; Revision History:
;     6/5/19    Di Hu      - seperated out from initial TGINIT.asm file;
;                          - changed filename from TGSPIINIT to TG_SPI_INIT_FUNC

; local include files
;.include  "TG_SPI_INIT_DEF.inc"



.cseg

; InitSPI
;
; Description:       This function initializes SPI via SPCR(Control Register). 
;
; Operation:         This function configures SPI to enable SPI operations, allow
;                    MSB to be transimitted first, be in Master mode, let SCK be 
;                    low when idle, sample data on the leading edge, and set SPI
;                    clock to have prescalar f_osc/16. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            SPI is initialized.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Limitation:        None.
;
; Known Bugs:        None. 
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 2, 2019

InitSPI:
                                        ;setup SPI
        LDI     R16, SPCR_INIT          ;set the SPI control register 
        OUT     SPCR, R16
        LDI     R16, SPSR_INIT          ;set the SPI status register 
        OUT     SPSR, R16


EndInitSPI:                             ;done initializing the SPI - return
        RET

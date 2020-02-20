;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_IO_INIT_FUNC                               ;
;                        I/O Initialization Function                         ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the Teaser Game board's
; I/O Ports by configuring their Data Direction Registers and Port Data 
; Registers.  The public function(s) included are:
;    InitPorts  - initialize the I/O ports
;
; Revision History of TGINIT.asm:
;     5/17/19   Di Hu      initial revision
;     5/31/19   Di Hu      added Port B and Timer1's configuration for speaker
;     6/5/19    Di Hu      initialized ports other than Port B, Port C, Port D
;
; Revision History:
;     6/5/19    Di Hu      - separated out from initial TGINIT.asm file
;                          - changed filename from TGIOINIT to TG_IO_INIT_FUNC


; local include files
;.include  "TGIOINIT.inc"

.cseg




; InitPorts
;
; Description:       This procedure initializes the I/O ports for the system.
;                    Port B    - Speaker and SD card communication SPI mode
;                    Port C, D - LED displays
;                    Port E    - Switches
;                    Port A, F, G - not used 
;
; Operation:         Port C and Port D's pins are all set as output in the
;                    Data Direction Registers, and all cleared in the Port Data
;                    registers. MOSI, SCK and SS bits are set as output in 
;                    Port B's Data Direction Register, SS bit is set as high
;                    in Port B's Data Register.  
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            The I/O ports are initialized and all outputs are turned
;                    off.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16
; Stack Depth:       0 bytes
;
; Author:            Di Hu
; Last Modified:     Jun 5, 2019

InitPorts:
                                        ;initialize I/O port directions
        LDI     R16, OUTDATA            ;initialize Port C and Port D to all outputs
        OUT     DDRC, R16
        OUT     DDRD, R16
        CLR     R16                     ;and all outputs are low (off)
        OUT     PORTC, R16
        OUT     PORTD, R16

        STS     DDRA, R16               ;clear all I/O ports that don't need
        STS     DDRE, R16               ;   initializing state 
        STS     DDRF, R16
        STS     DDRG, R16
        STS     PORTA, R16
        STS     PORTE, R16
        STS     PORTF, R16
        STS     PORTG, R16

        LDI     R16, SPI_DD_INIT        ;initialize MOSI, SCK and SS bits as output
        ORI     R16, SPKMASK            ;initialize speaker bit as output
        OUT     DDRB, R16               
        LDI     R16, SSHIGH             ;initialize Port B with SS pulled high
        OUT     PORTB, R16              


EndInitPorts:                           ;done so return
        RET
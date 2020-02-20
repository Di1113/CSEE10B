;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  TG_TMAIN                                  ;
;                            Teaser Game Main Loop                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program runs the Teaser Game main loop logic. It first
;                   sets up the stack and calls all the initialization functions
;                   to initializes Timer 0, Timer 1, I/O ports, SPI, switch 
;                   debounce buffers, LED Mux buffers, SD card and then starts
;                   the game. The game is in an infinite start-over-start loop
;                   (only exit the loop when power is off). The game is over 
;                   when the game is in win/lose states, or two reset states  
;                   and would start the game again after the game-over state is
;                   over. When game is not over, user can play Teaser Game on 
;                   the 3x3 grid by pressing any 'On' switch, and 4-digit LED 
;                   display would update move count till the game is over. 
;                   See description in Teaser Game Functional Specification for
;                   specific game rules.     
;
; Operation:        This program is table driven, each entry starts with the 
;                   function to call next and then compares the stateFlag 
;                   returned by the function to the second column in the table, 
;                   and add offset to the table pointer based on the compare 
;                   result to access next entry. Buffer 'stateFlag' is reserved 
;                   for main loop functions to return states when the function 
;                   is done. Only WaitToGetKeyState and CheckGameOver function
;                   have multiple possible flags to return, other functions in
;                   the table clear stateFlag's value. 
;
; Local Variables:  None.
; Shared Variables: stateFlag - read - for comparing with the compare value in
;                             the table and load the table offset accordingly.
; Global Variables: None.
;
; Input:            Switch Status. Press switches on 3x3 grid to play the game; 
;                   press "Manual Reset" switch to manually reset the board; 
;                   press "Random Reset" switch to randomly reset the board.
;
; Output:           The program shows move count on the 4-digit LED, show 
;                   switches' on/off state with their LED lights, and plays 
;                   sound through speaker when an illegal move is made, the 
;                   game is won or lost. 
;
; User Interface:   Clickable switches, any switch in the 3x3 grid being
;                   pressed may change the game states, any two reset switches
;                   being pressed will reset the game. Random reset will reset
;                   game with an initial pseudo-random game states. Manual 
;                   reset allows user to toggle any switches in the grid after
;                   first pressed "Manual Reset" and starts the game with the 
;                   user-defined states after the second press.
;
; Error Handling:   Illegal moves(pressing two or more switches in the same row
;                   simultaneously, or pressing a switch with off state) would  
;                   trigger an illegal-move-warning sound, and the game state  
;                   would remain unchanged. 
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      The game state cannot be stored. This program only supports
;                   Ver 2.x SDHC card communication. Ver 1.x and Ver 2.x SD 
;                   Cards are not supported. 
;
; Revision History:
;    6/9/19  Di Hu                     Initial Revision 


;set the device
.device ATMEGA64




;get the definitions for the device
.include  "m64def.inc"

;include all the .inc files since all .asm files are needed here (no linker)
.include  "TG_SWITCH_DEF.inc"
.include  "TG_DISP_DEF.inc"
.include  "TG_IO_INIT_DEF.inc"
.include  "TG_SPI_INIT_DEF.inc"
.include  "TG_TIMER_INIT_DEF.inc"
.include  "TG_SOUND_DEF.inc"
.include  "TG_SDCARD_DEF.inc"
.include  "TG_GAME_DEF.inc"


.cseg




;setup the vector area

.org    $0000

    JMP Start       ;reset vector
    JMP PC          ;external interrupt 0
    JMP PC          ;external interrupt 1
    JMP PC          ;external interrupt 2
    JMP PC          ;external interrupt 3
    JMP PC          ;external interrupt 4
    JMP PC          ;external interrupt 5
    JMP PC          ;external interrupt 6
    JMP PC          ;external interrupt 7
    JMP PC          ;timer 2 compare match
    JMP PC          ;timer 2 overflow
    JMP PC          ;timer 1 capture
    JMP PC          ;timer 1 compare match A
    JMP PC          ;timer 1 compare match B
    JMP PC          ;timer 1 overflow
    JMP Timer0CompareHandler            ;timer 0 compare match
    JMP PC          ;timer 0 overflow
    JMP PC          ;SPI transfer complete
    JMP PC          ;UART 0 Rx complete
    JMP PC          ;UART 0 Tx empty
    JMP PC          ;UART 0 Tx complete
    JMP PC          ;ADC conversion complete
    JMP PC          ;EEPROM ready
    JMP PC          ;analog comparator
    JMP PC          ;timer 1 compare match C
    JMP PC          ;timer 3 capture
    JMP PC          ;timer 3 compare match A
    JMP PC          ;timer 3 compare match B
    JMP PC          ;timer 3 compare match C
    JMP PC          ;timer 3 overflow
    JMP PC          ;UART 1 Rx complete
    JMP PC          ;UART 1 Tx empty
    JMP PC          ;UART 1 Tx complete
    JMP PC          ;Two-wire serial interface
    JMP PC          ;store program memory ready




; start of the actual program

Start:                          ;start the CPU after a reset
    LDI 	R16, LOW(TopOfStack);initialize the stack pointer
    OUT 	SPL, R16
    LDI 	R16, HIGH(TopOfStack)
    OUT 	SPH, R16
    RCALL   InitTimer0          ;init Timer 0 for interrupts
    RCALL   InitTimer1          ;init Timer 1 for playing sound 
    RCALL   InitPorts           ;init Port B, Port C, Port D
    RCALL   InitSPI             ;init SPI for SD card communication
    RCALL   DebounceInit        ;init buffers for switch functions
    RCALL   InitLEDMux          ;clear all LEDs
    RCALL   InitSDCard          ;init Ver 2.x SDHC cards
	SEI                         ;turn on interrupts 
	

	RCALL 	RandomReset 		;init 9 game switches randomly 
    
GameOn:  
    LDI     ZL, LOW(2 * TGMainLoopTable)      ;point to the start of the table 
    LDI     ZH, HIGH(2 * TGMainLoopTable)

CheckCFA: 
    LPM     R19, Z+             ;load first byte 
    LPM     R18, Z+             ;now Z points to the Compare Value 
    PUSH    ZL              
    PUSH    ZH 
    LDI     R21, HIGH(CFA)
    LDI     R20, LOW(CFA)
    CP      R21, R19 
    CPC     R20, R18 
    BREQ    CheckFlagAgain 
    ;BRNE    CallFunctionToGetFlag

CallFunctionToGetFlag: 
    MOV     ZL, R18             ;R17|R16: function addr to call 
    MOV     ZH, R19 
    ICALL   
    ;RJMP    CheckStateFlag 

CheckStateFlag: 
    LDS     R18, stateFlag 
    POP     ZH
    POP     ZL                              ;now Z points to the Compare Value 
    LPM     R19, Z+             
    CP      R18, R19 
    BRGE    GENextStep 
    ;BRLT    LENextStep

LENextStep:
    ADIW    Z, 1
    ;RJMP    GoToNextStep

GENextStep: 
    ;RJMP    GoToNextStep

GoToNextStep: 
    LPM     R18, Z 
    LDI     R19, ML_TAB_RSIZE
    MUL     R18, R19
    LDI     ZL, LOW(2 * TGMainLoopTable)      ;point to the start of the table 
    LDI     ZH, HIGH(2 * TGMainLoopTable)
    ADD     ZL, R0
    ADC     ZH, R1 
    RJMP    CheckCFA

CheckFlagAgain:
    LDS     R18, stateFlag 
    POP     ZH
    POP     ZL 
    LPM     R19, Z+ 
    CP      R18, R19 
    BRGE    GENextStep 
    BRLT    LENextStep   




    RJMP    GameOn              ;should never reach here, if did, restart game


; TGMainLoopTable
; 
; Description:      This table contains the values of arguments for running 
;                   Teaser Game main loop logic. Each entry consists of total
;                   6 bytes, including two bytes of program address of the 
;                   function to call, one byte of compare flag for functions' 
;                   returned flag to compare with, and two bytes of next step 
;                   offset which one of two is loaded to Pointer Z depending on
;                   the compare result, and one padding byte at the end for 
;                   having even bytes at each row. 
;
; Author:           Di Hu
; Last Modified:    June 8, 2019
;

TGMainLoopTable:
;                                                            >=      < 
;                                                    Compare Next    Next
;   Function to call                                 value   step    step   Padding    Step
.DB HIGH(GameStart),         LOW(GameStart),         0,      1,      1,      0       ; 0       
.DB HIGH(WaitToGetKeyState), LOW(WaitToGetKeyState), 1,      2,      3,      0       ; 1          
.DB HIGH(MakeMove),          LOW(MakeMove),          0,      4,      5,      0       ; 2       
.DB HIGH(CFA),               LOW(CFA),               0,      5,      6,      0       ; 3       
.DB HIGH(CheckGameOver),     LOW(CheckGameOver),     0,      1,      11,     0       ; 4       
.DB HIGH(IllegalMoveWarning),LOW(IllegalMoveWarning),0,      1,      1,      0       ; 5       
.DB HIGH(CFA),               LOW(CFA),               0xFF,   7,      8,      0       ; 6       
.DB HIGH(RandomReset),       LOW(RandomReset),       0,      0,      0,      0       ; 7       
.DB HIGH(ManualReset),       LOW(ManualReset),       0,      0,      7,      0       ; 8   
.DB HIGH(GameOverLost),      LOW(GameOverLost),      0,      7,      7,      0       ; 9   
.DB HIGH(GameOverWon),       LOW(GameOverWon),       0,      7,      7,      0       ; 10      
.DB HIGH(CFA),               LOW(CFA),               0xFD,   9,      10,     0       ; 11       
 
; Function CFA : Check the returned flag again 








;the data segment


.dseg


; the stack - 128 bytes
			.BYTE   127
TopOfStack: .BYTE   1       ;top of the stack




; since don't have a linker, include all the .asm files

.include "div.asm"
.include "segtable.asm"
.include "TG_GAME_FUNC.asm"
.include "TG_UTIL_FUNC.asm"
.include "TG_SOUND_FUNC.asm"
.include "TG_SDCARD_FUNC.asm"
.include "TG_DISP_FUNC.asm"
.include "TG_IO_INIT_FUNC.asm"
.include "TG_SPI_INIT_FUNC.asm"
.include "TG_TIMER_INIT_FUNC.asm"
.include "TG_SWITCH_FUNC.asm"
.include "TG_IRQ.asm"

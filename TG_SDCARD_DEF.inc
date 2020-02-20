;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              TG_SDCARD_DEF.inc                             ;
;                            SD Card Include File                            ;
;                                Teaser Game                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the hardware, software definitions for Teaser Game's 
; SD card routines to send commands, receive responses, write data, read data 
; etc. 
;
; Revision History:
;     6/1/19   Di Hu             initial revision
;     6/5/19   Di Hu             changed filename from TGSDCARD to 
;                                TG_SDCARD_DEF



; Hardware definitions
.EQU    ILLEGAL_CMD_MASK = 0b00000100   ;Check is Illegal Command bit is set
.EQU    COMMAND_BYTES = 6               ;total 6 bytes in a command 
.EQU    MSB_MASK = 0b10000000           ;read the Most Significant Bit 
.EQU    SS_BIT = 0                      ;Slave select bit is 0 in PortB

; Software definitions
.EQU    FF_BYTE = 0xFF                  ;All-ones byte 
.EQU    NINE_BYTES_COUNTER = 9          ;used for report timeout error in
                                        ;   WaitToGetResponse

; SD card initialization definitions
.EQU    BYTES_FOR_MANY  = 10            ;wait for more than 75 clocks
.EQU    WAIT_FOR_ONEMS  = 16            
                        ; wait for 1 ms ((8 mhz / 64) / 1000) * 1 ms / 8 bits
.EQU    R1_SIZE = 1                     ;if expecting R1, byte size is 1 
.EQU    R3R7_SIZE = 5                   ;if expecting R3 or R7, byte size is 4 
.EQU    CMD0_CRC = 0x95                 ;CRC in CMD0 argument
.EQU    CMD8_CRC = 0x87                 ;CRC in CMD8 argument for Ver 2.x SDHC
.EQU    CMD8_PAT = 0xAA                 ;check pattern in CMD8 argument
.EQU    CMD8_VOL = 0x01                 ;voltage accepted in CMD8 argument
.EQU    ILL_CMD  = 0x04                 ;Illegal Command bit in R1
.EQU    OCR_VOL  = 0xFC                 ;check voltage range in OCR
.EQU    CMD41_HCS= 0x40                 ;HCS bit in CMD41 argument; support HC
.EQU    IDLE_ST  = 0x01                 ;In Idle State bit in R1
.EQU    CCS_R3   = 0x40                 ;CCS bit in R3(in OCR) 
.EQU    CHK_RS   = 0xFF                 ;check response again instead new cmd
.EQU	CHK_RS_OFFSET = 6				;skip 6 bytes of offset in the table
.EQU    V1_RD    = -1                   ;Version 1.x card ready
.EQU    V2_SD_RD = -2                   ;Version 2.x SD card ready
.EQU    V2_SDHC_RD = -3                 ;Version 2.x SDHC card ready
.EQU    NON_COMP_CARD = -4              ;Error Non-Compatible Card 
.EQU    SD_TAB_RSIZE = 22               ;SDInitTable's row size is 22
.EQU    RESP_SIZE = 5                   ;response size is 5 for mask and cmp
.EQU    MATCH_OFFSET = 2                ;add offset in table if match response
.EQU    ERROR_TRUE = 1                  ;indicates error occured 
.EQU    ERROR_FALSE = 0                 ;indicates no error occured 

; SD card write data definitions
.EQU    BLOCK_BYTES_L = 0x00            ;total 512 bytes in one SD card block
.EQU    BLOCK_BYTES_H = 0x02
.EQU    START_BLOCK_TOKEN = 0xFE        ;first data byte in SD transmission  
.EQU    WRITE_RESPONSE_MASK = 0b00001110 ;bits to check for error is set 
.EQU    WRITE_DATA_ACCEPTED = 0b00000100 ;data sent is accepted 
; Count for 250 ms = ((8 mhz / 32) / 1000 ) * 250 ms / 8 bits = 7812.5 bytes
.EQU    WAIT_BUSY_CNT_L     = 0b10000101
.EQU    WAIT_BUSY_CNT_H     = 0b00011110 ;counts for 7813 bytes  
.EQU    CMD24 = 0b01011000              ;command 24 for writing single block
.EQU    R1_ERROR_MASK = 0b11111110      ;don't care idle state bit 

; SD card read data definitions
; Count for 100 ms = ((8 mhz / 32) / 1000 ) * 100 ms / 8 bits = 3125 bytes
.EQU    WAIT_DATA_COUNTER_L = 0b00110101         ;Count 3125 bytes for 100 ms  
.EQU    WAIT_DATA_COUNTER_H = 0b00001100 
.EQU    CMD17 = 0b01010001				;command 17 for reading single block

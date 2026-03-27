LIST P=16F84A
    INCLUDE <P16F84A.INC>
    __CONFIG _HS_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

    CBLOCK 0x0C
    RX_REG
    BIT_COUNT
    DELAY_REG1
    DELAY_REG2
    ENDC

    ORG 0x00
    GOTO INICIO

INICIO
    BSF     STATUS, RP0
    MOVLW   B'00000100'     
    MOVWF   TRISA
    CLRF    TRISB           
    BCF     STATUS, RP0

    CALL    INIT_LCD        

MAIN_LOOP
    BTFSC   PORTA, 2        
    GOTO    MAIN_LOOP

    CALL    DELAY_52US      
    MOVLW   D'8'
    MOVWF   BIT_COUNT
RX_LOOP
    CALL    DELAY_104US     
    BCF     STATUS, C
    BTFSC   PORTA, 2
    BSF     STATUS, C
    RRF     RX_REG, F
    DECFSZ  BIT_COUNT, F
    GOTO    RX_LOOP

    CALL    DELAY_104US     

    MOVF    RX_REG, W
    CALL    SEND_CHAR_LCD
    
    GOTO    MAIN_LOOP

INIT_LCD
    CALL    RETARDO_15MS
    MOVLW   0x38            
    CALL    SEND_CMD_LCD
    MOVLW   0x0C            
    CALL    SEND_CMD_LCD
    MOVLW   0x01            
    CALL    SEND_CMD_LCD
    MOVLW   0x06            
    CALL    SEND_CMD_LCD
    RETURN

SEND_CMD_LCD
    MOVWF   PORTB
    BCF     PORTA, 0        
    BSF     PORTA, 1        
    NOP
    BCF     PORTA, 1        
    CALL    RETARDO_15MS
    RETURN

SEND_CHAR_LCD
    MOVWF   PORTB
    BSF     PORTA, 0        
    BSF     PORTA, 1        
    NOP
    BCF     PORTA, 1        
    CALL    DELAY_104US
    RETURN

DELAY_104US
    MOVLW   D'33'
    MOVWF   DELAY_REG1
L_104
    DECFSZ  DELAY_REG1, F
    GOTO    L_104
    RETURN

DELAY_52US
    MOVLW   D'16'
    MOVWF   DELAY_REG1
L_52
    DECFSZ  DELAY_REG1, F
    GOTO    L_52
    RETURN

RETARDO_15MS
    MOVLW   D'15'
    MOVWF   DELAY_REG2
L_15MS_OUTER
    MOVLW   D'249'
    MOVWF   DELAY_REG1
L_15MS_INNER
    NOP
    DECFSZ  DELAY_REG1, F
    GOTO    L_15MS_INNER
    DECFSZ  DELAY_REG2, F
    GOTO    L_15MS_OUTER
    RETURN

    END
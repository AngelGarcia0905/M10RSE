LIST P=16F84A
    INCLUDE <P16F84A.INC>
    __CONFIG _HS_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

    CBLOCK 0x0C
    CONT_TIEMPO
    MORSE_DATA      
    TX_REG
    BIT_COUNT
    DELAY_REG1
    DELAY_REG2
    DELAY_REG3      
    ENDC

    ORG 0x00
    GOTO INICIO

INICIO
    BSF     STATUS, RP0
    MOVLW   B'00000001'     
    MOVWF   TRISA
    CLRF    TRISB           
    BCF     STATUS, RP0
    
    CLRF    PORTB
    BSF     PORTB, 0        ; Estado IDLE del Serial (5V)
    
    MOVLW   B'00000001'     ; Bit centinela inicial
    MOVWF   MORSE_DATA

ESPERA_SEÑAL
    BTFSC   PORTA, 0
    GOTO    INICIA_PULSO
    GOTO    ESPERA_SEÑAL

INICIA_PULSO
    BSF     PORTB, 1        ; LED Rojo y Buzzer encendidos
    BSF     PORTB, 4        
    CLRF    CONT_TIEMPO

MIDE_ALTO
    CALL    RETARDO_10MS
    INCF    CONT_TIEMPO, F
    BTFSC   PORTA, 0
    GOTO    MIDE_ALTO

    BCF     PORTB, 1        ; Apaga indicadores
    BCF     PORTB, 4        

    MOVLW   D'60'           ; Umbral de 600ms para RAYA
    SUBWF   CONT_TIEMPO, W
    BTFSC   STATUS, C
    GOTO    ES_RAYA

ES_PUNTO
    BCF     STATUS, C       ; Bit 0 para Punto
    GOTO    GUARDA_BIT

ES_RAYA
    BSF     STATUS, C       ; Bit 1 para Raya

GUARDA_BIT
    RLF     MORSE_DATA, F   

    CLRF    CONT_TIEMPO
MIDE_BAJO
    CALL    RETARDO_10MS
    INCF    CONT_TIEMPO, F
    BTFSC   PORTA, 0
    GOTO    INICIA_PULSO    

    MOVLW   D'60'           ; Umbral fin de letra
    SUBWF   CONT_TIEMPO, W
    BTFSS   STATUS, C
    GOTO    MIDE_BAJO       

    BSF     PORTB, 2        ; LED Verde (Fin Letra)
    CALL    RETARDO_200MS   
    BCF     PORTB, 2
    
    MOVF    MORSE_DATA, W
    CALL    TABLA_MORSE
    MOVWF   TX_REG
    
    CALL    SEND_UART       ; Envía el caracter al PIC 2
    
    MOVLW   B'00000001'     ; Reinicia registro
    MOVWF   MORSE_DATA
    
MIDE_PALABRA
    CALL    RETARDO_10MS
    INCF    CONT_TIEMPO, F
    BTFSC   PORTA, 0
    GOTO    INICIA_PULSO    
    
    MOVLW   D'180'          ; Umbral fin de palabra
    SUBWF   CONT_TIEMPO, W
    BTFSS   STATUS, C
    GOTO    MIDE_PALABRA
    
    BSF     PORTB, 3        ; LED Azul (Fin Palabra)
    CALL    RETARDO_200MS   
    BCF     PORTB, 3
    
    MOVLW   A' '            ; Envía espacio
    MOVWF   TX_REG
    CALL    SEND_UART
    GOTO    ESPERA_SEÑAL

; --- TABLA DE TRADUCCIÓN EXTENDIDA (Basada en tu imagen) ---
TABLA_MORSE
    ADDWF   PCL, F
    RETLW   '?' ; 0
    RETLW   '?' ; 1 
    RETLW   'e' ; 2
    RETLW   't' ; 3
    RETLW   'i' ; 4
    RETLW   'a' ; 5
    RETLW   'n' ; 6
    RETLW   'm' ; 7
    RETLW   's' ; 8
    RETLW   'u' ; 9
    RETLW   'r' ; 10
    RETLW   'w' ; 11
    RETLW   'd' ; 12
    RETLW   'k' ; 13
    RETLW   'g' ; 14
    RETLW   'o' ; 15
    RETLW   'h' ; 16
    RETLW   'v' ; 17
    RETLW   'f' ; 18
    RETLW   '?' ; 19 
    RETLW   'l' ; 20
    RETLW   '?' ; 21 
    RETLW   'p' ; 22
    RETLW   'j' ; 23
    RETLW   'b' ; 24
    RETLW   'x' ; 25
    RETLW   'c' ; 26
    RETLW   'y' ; 27
    RETLW   'z' ; 28
    RETLW   'q' ; 29
    RETLW   '?' ; 30 
    RETLW   '?' ; 31 
    RETLW   '5' ; 32 (.....)
    RETLW   '4' ; 33 (....-)
    RETLW   '?' ; 34 
    RETLW   '3' ; 35 (...--)
    RETLW   '?' ; 36 
    RETLW   '?' ; 37 
    RETLW   '?' ; 38 
    RETLW   '2' ; 39 (..---)
    RETLW   '?' ; 40 
    RETLW   '?' ; 41 
    RETLW   '?' ; 42 
    RETLW   '?' ; 43 
    RETLW   '?' ; 44 
    RETLW   '?' ; 45 
    RETLW   '?' ; 46 
    RETLW   '1' ; 47 (.----)
    RETLW   '6' ; 48 (-....)
    RETLW   '?' ; 49 
    RETLW   '?' ; 50 
    RETLW   '?' ; 51 
    RETLW   '?' ; 52 
    RETLW   '?' ; 53 
    RETLW   '?' ; 54 
    RETLW   '?' ; 55 
    RETLW   '7' ; 56 (--...)
    RETLW   '?' ; 57 
    RETLW   '?' ; 58 
    RETLW   '?' ; 59 
    RETLW   '8' ; 60 (---..)
    RETLW   '?' ; 61 
    RETLW   '9' ; 62 (----.)
    RETLW   '0' ; 63 (-----)

; --- RUTINAS DE COMUNICACIÓN Y TIEMPO ---
SEND_UART
    BCF     PORTB, 0        
    CALL    DELAY_104US
    MOVLW   D'8'
    MOVWF   BIT_COUNT
TX_LOOP
    RRF     TX_REG, F
    BTFSC   STATUS, C
    BSF     PORTB, 0
    BTFSS   STATUS, C
    BCF     PORTB, 0
    CALL    DELAY_104US
    DECFSZ  BIT_COUNT, F
    GOTO    TX_LOOP
    BSF     PORTB, 0        
    CALL    DELAY_104US
    RETURN

DELAY_104US
    MOVLW   D'33'
    MOVWF   DELAY_REG1
L_104
    DECFSZ  DELAY_REG1, F
    GOTO    L_104
    RETURN

RETARDO_10MS
    MOVLW   D'10'
    MOVWF   DELAY_REG2
L_10MS_OUTER
    MOVLW   D'249'
    MOVWF   DELAY_REG1
L_10MS_INNER
    NOP
    DECFSZ  DELAY_REG1, F
    GOTO    L_10MS_INNER
    DECFSZ  DELAY_REG2, F
    GOTO    L_10MS_OUTER
    RETURN

RETARDO_200MS
    MOVLW   D'20'
    MOVWF   DELAY_REG3
L_200MS
    CALL    RETARDO_10MS
    DECFSZ  DELAY_REG3, F
    GOTO    L_200MS
    RETURN

    END
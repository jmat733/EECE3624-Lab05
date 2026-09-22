

/**************************************************************************
 *    File: Lab05.asm
 *  Lab Name: Pardon the Interruption...
 *    Author: Dr. Greg Nordstrom
 *   Created: 02/19/2021
 * Processor: ATmega128A (on the ReadyAVR board)
 *
 * Modified by: Jake Matthews
 * Modified on: 9/22/26
 *
 * This program blinks the "BOOT" LED at a reate of 1-15Hz which is adjustable
 * The joystick controls whether it blinks faster or slower
 * and the blink rate is displayed in 4 bit binary on LEDs 0-3
 *************************************************************************/
 .def BlinkFreq = R20       ; holds current blink rate (1-15 Hz)
.equ BlinkFreqMin = 1
.equ BlinkFreqMax = 15
.equ InitialBlinkFreq = BlinkFreqMin

 /*********
 * Interrupt Jump Table
 *********/
.org 0x0000                 ; next instruction address is 0x0000
                            ; (the location of the reset vector)
rjmp main                   ; allow reset to run this program

.org 0x0004
rjmp int1_isr               ; INT1

.org 0x0008
rjmp int3_isr               ; INT3

/**********
* Main code
**********/
    .org 0x0020             
main:                       ; jump here on reset
    ldi R16, HIGH(RAMEND)   ; initialize stack (default RAMEND = 0x10FF)
    out SPH, R16
    ldi R16, low(RAMEND)
    out SPL, R16

    /* Additional Setup before Main Loop */

    ldi BlinkFreq, InitialBlinkFreq
    
    LDI  R16,(1<<DDA7)      ; Set the mask to make Port A.7 an output
    OUT  DDRA,R16           ; Load bitmask to PORTA register

    LDI  R16,0x0F           ; for the bit blink display
    OUT  DDRC,R16
    
    mov R16, BlinkFreq    ; Copy current blink rate to a working register
    com R16               ; Invert all the bits (0s become 1s, 1s become 0s)
    out PORTC, R16

    ; Configure joystick pins as inputs
    cbi DDRB, DDB1
    cbi DDRB, DDB3

    ; Enable internal pull-up resistors on PB1 and PB3
    sbi PORTB, PORTB1
    sbi PORTB, PORTB3

    ; Configure interrupt pins PD1 and PD3 as inputs
    cbi DDRD, 1
    cbi DDRD, 3

    ; Configure INT1 and INT3 for rising-edge interrupts
    LDI R16, (1<<ISC11) | (1<<ISC10) | (1<<ISC31) | (1<<ISC30)
    STS EICRA, R16

    ; Enable INT1 and INT3
    LDI R16, (1<<INT1) | (1<<INT3)
    OUT EIMSK, R16          

    ; Enable global interrupts
    SEI
mainLoop:
    CBI  PORTA, PORTA7      ; turn BOOT LED on (active low) by clearing PORTA.7

    ; kill some time
    ldi R16, 16
    sub R16, BlinkFreq      ; R16 is outer loop counter
outer_loop1:
    ldi R24, low(0xFFFF)    ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)   ; loop count by loading registers separately
    inner_loop1:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop1    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop1        ; loop back if R16 isn't zero

    sbi PORTA, PORTA7       ; turn BOOT LED off (active low) by setting PORTA.7

    ; kill some more time
    ldi R16, 16             ; R16 is outer loop counter
    sub R16, BlinkFreq
outer_loop2:
    ldi R24, low(0xFFFF)    ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)   ; loop count by loading registers separately
    inner_loop2:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop2    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop2        ; loop back if R16 isn't zero

    rjmp mainLoop           ; play it again, Sam...

/**********
* ISR code
**********/
.org 0x0200                 ; Load the ISR code higher than main code
int1_isr:                   ; INT1 = PD1 = DOWN
    push R16                ; Save working register
    in R16, SREG            ; Save Status Register (SREG)
    push R16

    cpi BlinkFreq, BlinkFreqMin
    breq int1_done

    dec BlinkFreq
    mov R16, BlinkFreq    ; Copy current blink rate to a working register
    com R16               ; Invert all the bits (0s become 1s, 1s become 0s)
    out PORTC, R16

int1_done:
    pop R16                 ; Restore Status Register (SREG)
    out SREG, R16
    pop R16                 ; Restore working register
    reti


int3_isr:                   ; INT3 = PD3 = UP
    push R16                ; Save working register
    in R16, SREG            ; Save Status Register (SREG)
    push R16

    cpi BlinkFreq, BlinkFreqMax
    breq int3_done

    inc BlinkFreq
    mov R16, BlinkFreq    ; Copy current blink rate to a working register
    com R16               ; Invert all the bits (0s become 1s, 1s become 0s)
    out PORTC, R16

int3_done:
    pop R16                 ; Restore Status Register (SREG)
    out SREG, R16
    pop R16                 ; Restore working register
    reti
; da65 V2.18 - Ubuntu 2.19-1
; Created:    2021-10-11 14:35:45
; Input file: ap_6502.prg
; Page:       1


        .setcpu "6502"

L8956           := $8956
L9BD2           := $9BD2
LFFD2           := $FFD2
        ;; set interrupt, we can't be interrupted in this block
        ;; like a mutex
        sei
        ;; patching in our own tokenizer routine to $0304
        lda     #$49
        sta     $0304
        lda     #$03
        sta     $0305
        ;; clear interrupt
        cli
        rts

        ;; start of our tokenizer

        ;; line number during GOSUB, GOTO, and RUN
        ;; $a7 and $a8 are RS-232 input stuff
        lda     $14
        sta     $A7
        lda     $15
        sta     $A8

        ;; $FF00: don't know what's here
        lda     #$00
        sta     $FF00

        ldx     #$1F
        ;; reverse mode switch + ...
        ;; some sort of setup?
make_text_reversed:  lda     $C7,x
        sta     $03E3,x
        dex
        bpl     make_text_reversed

        ;; write #$13 (home), put cursor in upper left corner
        lda     #$13
        jsr     LFFD2

        ;; i don't know what this is
        lda     #$12
        jsr     L9BD2

        ;; some places to store data in zero page?
        ldy     #$00

        ;; b4 = current character index
        sty     $B4

        ;; b0 = are we in a quoted string
        sty     $B0

        ;; 0 -> 255
        dey
process_character:  inc     $B4

        ;; 255 -> 0
        ;; y = current character position
next_character:  iny

        ;; load a character from input buffer
        ;; where what you type goes before committing
        lda     $0200,y

        ;; if result is 0 (null), finish the line
        beq     done_with_line
        cmp     #$22
        bne     its_not_a_quote

        ;; push current character onto stack
        pha

        ;; toggle are we in a string
        lda     $B0
        eor     #$FF
        sta     $B0

        ;; pull current character
        pla
        ;; push character
its_not_a_quote:  pha
        ;; is this character a space
        ;; spaces aren't significant unless we're in quotes
        cmp     #$20
        ;; no, keep going
        bne     count_this_character
        ;; are we in a quote
        lda     $B0
        bne     count_this_character
        ;; is the character in here a 0? then get the next character
        pla
        bne     next_character
count_this_character:  pla
        ;; load current char index
        ldx     $B4
repeatedly_process:  clc
        ;; take the Character part...
        lda     $A7
        ;; load this character from input buffer
        ;; this can set the carry bit
        ;; so if this overflows, we want to know
        adc     $0200,y
        ;; store it in $a7
        sta     $A7

        ;; load a8
        lda     $A8
        ;; we put the # of overflows in here
        adc     #$00
        sta     $A8

        ;; count down number of times
        dex

        ;; if not zero, keep going
        bne     repeatedly_process
        ;; if done, go to the next character
        beq     process_character
        ;; get the continually added char
done_with_line:  lda     $A7
        ;; xor it with the number of overflows
        eor     $A8
        ;; push it onto the stack
        pha
        ;; take 0-15...
        and     #$0F
        ;; and stick it in y
        tay

        ;; $03d3 is the end part of the data and defined what
        ;; characters there are
        lda     $03D3,y
        ;; print that character to the screen
        jsr     LFFD2

        ;; pull from the stack...
        pla
        ;; shift it four bits to make it 0-15
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ;; and stick it in y
        tay

        ;; same printing
        lda     $03D3,y
        jsr     LFFD2

        ldx     #$1F
reverse_it_again:  lda     $03E3,x
        sta     $C7,x
        dex
        bpl     reverse_it_again

        lda     #$92
        jsr     LFFD2

        ;; run the original tokenizer
        jmp     L8956

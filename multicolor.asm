*  Multicolor mode

       idt 'multicolor'

       def sload, sfirst, slast, start

       jmp  start

workspace:
       equ  >8300
keymode:
       equ >8374
key_pressed:
       equ >8375
pdt:
       equ >0800            ; address of pattern descriptor table
video_mode:
       equ >83d4            ; copy of VDP register 1
one_key:
       equ 49
two_key:
       equ 50
three_key:
       equ 51
right_key:
       equ 68
up_key:
       equ 69
left_key:
       equ 83
down_key:
       equ 88

start:
       lwpi workspace       ; load memory area for the registers

       clr @keymode         ; standard keyboard scan

       li r0, >0711         ; prepare to make the screen black on black
       blwp @vwtr           ; write the color byte to vdp register 7
       li r0, >01f0         ; prepare to write >f0 to vdp register 1
       blwp @vwtr           ; set the computer in text mode

       clr r0               ; start at screen position 0
       li r7, 6             ; six 128-byte segments to write
       clr r5               ; register 5 will hold the value to be
                            ; written on the screen
segment_loop:
       li r3, 4             ; four lines in each 128-byte segment
line_loop:
       li r4, 32            ; 32 characters on each line
       movb r5, r1          ; more values to be written to the screen
                            ; for the VSBW routine
column_loop:
       blwp @vsbw           ; writes the value to the screen
       inc r0               ; increase by 1 the value to be written to
                            ; the screen
       dec r4               ; decrease number of bytes remaining to be
                            ; written on that line
       jne column_loop      ; if not the end of the line, stay on loop
       dec r3               ; decrease number of lines remaining in the
                            ; 128-byte segment
       jne line_loop        ; if there are still lines left in the segment
                            ; go for them
       ai r5, >2000         ; the numbering of the next segment starts at
                            ; a value 32 greater than previous one
       dec r7               ; decrease number of 128-byte segments left
       jne segment_loop     ; if there are still segments, go for them

clear_screen:
       li r0, pdt
       clr r1               ; the color to be written is >00 (transparent)
!      blwp @vsbw           ; write the color to the table
       inc r0               ; increment position in the table
       ci r0, >0e00         ; has the end of the table been reached?
       jne -!               ; if not, stay on the clearing loop

       li r0, >01e8         ; prepare to write >e8 to VDP register 1
       blwp @vwtr           ; set the computer in multicolor mode
       swpb r0              ; prepare to write >e8 to video_mode
       movb r0, @video_mode ; move the left byte of r0 to video_mode
       li r3, 32            ; column of the initial square
       li r4, 24            ; row of the initial square
       li r5, >0001         ; black is the initial screen color
       li r14, >9000        ; initial block color

scan_loop:
       limi 2               ; enables interrupts like FCTN = (QUIT)
       limi 0               ; disables VDP interrupts again
       li r13, 2000         ; delay loop
!      dec r13              ; decrease r13
       jne -!               ; if not zero, loop again
       blwp @kscan          ; scan the keyboard
       clr r1               ; prepare r1 to receive the ASCII of the
                            ; key pressed
       mov @key_pressed, r1 ; move the ASCII code of the key pressed
                            ; into the right byte of r1
       ci r1, left_key      ; has the S been pressed?
       jeq go_left          ; if so, jump to go_left
       ci r1, right_key     ; has the D been pressed?
       jeq go_right         ; if so, jump to go_right
       ci r1, up_key        ; has the E been pressed?
       jeq go_up            ; if so, jump to go_up
       ci r1, down_key      ; has the X been pressed?
       jeq go_down          ; if so, jump to go_down
       ci r1, one_key       ; has the 1 been pressed?
       jeq change_screen    ; if so, jump to change_screen
       ci r1, two_key       ; has the 2 been pressed?
       jeq change_block     ; if so, jump to change_block
       ci r1, three_key     ; has the 3 been pressed?
       jeq clear_screen     ; if so, jump to clear_screen
       jmp scan_loop        ; otherwise, keep scanning the keyboard

go_left:
       dec r3               ; decrease column of block
       ci r3, -1            ; has it passed column 0? Block out of
                            ; screen
       jne color_block      ; if not, color the block
       clr r3               ; block out of screen; reset position
       jmp color_block      ; then, color it
go_right:
       inc r3               ; increase column of the block
       ci r3, 64            ; has it passed column 63? Block out of
                            ; screen
       jlt color_block      ; if not, color the block
       li r3, 63            ; block out of screen; reset position
       jmp color_block      ; then, color it

go_up:
       dec r4               ; decrese block's row value
       ci r4, -1            ; is it past the top row 0?
       jne color_block      ; if not, color the block
       clr r4               ; block out of screen; reset row
       jmp color_block      ; then, color it

go_down:
       inc r4               ; increase row of the block
       ci r4, 48            ; has it passed bottom row 47? Block
                            ; out of screen
       jlt color_block      ; if not, color the block
       li r4, 47            ; block out of screen; reset row
       jmp color_block      ; then, color it

change_screen:
       ci r5, >000f         ; are we already at last color (white?)
       jne inc_screen_color ; if not, jump to the updating instruction
       clr r5               ; set color screen to 0 (transparent)
inc_screen_color:
       inc r5
       mov r5, r0           ; move color to r0 for VWTR
       ai r0, >0700         ; write >07 to the left byte of r0, so the color
                            ; byte (right byte) gets written to VDP reg 7
       blwp @vwtr           ; write the new screen color to VDP register 7
       li r13, 20000        ; prepare for the delay loop
!      dec r13              ; decrease the delay counter
       jne -!               ; loop until it becomes zero
       jmp scan_loop        ; screen color changed, return to kscan loop

change_block:
       ai r14, >1000        ; add 1 to the current color code.
                            ; if the old code is >f, is reset to >0
       li r13, 20000        ; prepare for the delay loop
!      dec r13              ; decrease the delay counter
       jne -!               ; loop until it becomes zero

color_block:
       li r15, 2            ; load 2 to r15. r3 must be divided by 2
       mov r3, r7           ; move the block column to r7 for the division
       clr r6               ; prepare r6 for the division.
       div r15, r6          ; divide r6r7 (000000xx) by r15. r6 will hold
                            ; the quotient and r7 the remainder
       li r15, 8            ; load 8 to r15. r4 must be divided by 8
       mov r4, r9           ; prepare to divide the block row by 8
       clr r8               ; clear r8 for the division
       div r15, r8          ; execute the division. quotient stays in r8
                            ; whereas the remainder in r9
       sla r6, 3            ; multiply the column quotient by 8 (shift
                            ; left by three positions)
       sla r8, 8            ; multiply the row quotient by 256
       a r6, r8             ; add both results onto r8
       a r8, r9             ; add the row remainder and store everything in
                            ; r9
       ai r9, pdt           ; add the position of the byte that controls the
                            ; the color of the block in VDP memory where the
                            ; pattern table begins
       mov r9, r0           ; move the value to r0 for the VSBR routine
       clr r1               ; the value read from the table is placed in r1
       blwp @vsbr           ; read the color byte from the table
       mov r1, r10          ; store the read color in r10

       ci r7, 0             ; check the remainder of the column block to
                            ; determine if left or right digit of byte must
                            ; be changed
       jeq left_digit       ; if the reminder is 0, the left digit must be
                            ; changed
       andi r10, >f000      ; right digit has to be changed. Clear it first
       srl r14, 4           ; the new color has to be written to the second
                            ; digit of r10. As it's right now stored in first
                            ; digit, let's shift it.
       ab r14, r10          ; write the new color into the right digit of r10
       sla r14, 4           ; in the meantime, restore the color in r14 to
                            ; its original position
set_color_to_pdt:
       mov r10, r1          ; move the new color byte into r1 to write it
                            ; back to the table
       blwp @vsbw           ; write it to the table. r0 is still loaded with
                            ; the right address
       jmp scan_loop        ; go and read the next keyboard input
left_digit:
       andi r10, >0f00      ; left digit has to be changed. Clear it first
       ab r14, r10          ; write the new color into the left digit of r10
       jmp set_color_to_pdt ; go write the new color to the pattern table
       
       copy "kscan_ea.asm"
       copy "vsbr_ea.asm"
       copy "vsbw_ea.asm"
       copy "vwtr_ea.asm"

       end

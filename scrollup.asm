*  Scroll Up

       idt 'scrollup'

       def begin
       ref vmbr, vmbw

begin:
       lwpi workspace

       li   r0, 748         ; position on screen to display the text
       li   r1, t_message   ; position in ram for the text to be displayed
       li   r2, s#t_message ; message length
       blwp @vmbw           ; display the text

start:
       clr  r0              ; start from position 0
       li   r1, buffer_1    ; place where the line read from VDP RAM will be stored
       li   r2, 32          ; buffer length
       blwp @vmbr           ; read the line into buffer_1

       li   r0, 32          ; position where to read first line to move
       li   r1, buffer_2    ; store it at buffer_2
       li   r2, 32          ; buffer length
loop:
       blwp @vmbr           ; read the line
       ai   r0, -32         ; move printing pos one line up
       blwp @vmbw           ; print the line
       ai   r0, 64          ; move reading pos two lines down: the next
                            ; line which has to be moved up
       ci   r0, 748         ; past the last line?
       jlt  loop            ; no; then keep looping

       li   r0, 736         ; print top line at the bottom
       li   r1, buffer_1    ; load position of buffer where line is stored
       blwp @vmbw           ; print the line
       jmp  start           ; jump back to restart scrolling sequence

workspace:
       equ  >8300

t_message:
       text 'Hello, world!'
buffer_1:
       bss  32              ; buffer where to store the top line when read
buffer_2:
       bss  32              ; buffer where to store each line when moved up

       copy "vmbr_ea.asm"
       copy "vmbw_ea.asm"

       end

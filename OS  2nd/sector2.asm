bits 16
org 0x0000

_start:
	mov ax, cs
	mov ds, ax
	xor bx, bx
	jmp sector2

clear_screen:
	mov ax, 0600h
	mov bh, 17h
	mov cx, 00
	mov dx, 184Fh
	int 10h
	nop
	ret 

clear_screen_black:
	mov ax, 0x13
	int 0x10
	ret

display_string:
	pusha
next_char:
	cld
	lodsb
	or al, al
	jz .exit
	call display_character
	jmp next_char
.exit:
	popa
	ret

display_color_string:
	pusha
	mov ah, 0x0E
	;mov bl, 0x50	;color
.next_char:
	lodsb
	or al, al
	jz .exit
	add bl, 1
	int 0x10
	jmp .next_char
.exit:
	popa
	ret

display_character:
	pusha
	mov ah, 0x0E
	mov bh, 0x00
	mov bl, 0x07
	int 0x10
	popa
	ret

get_a_char:
	; if you put push/pop it is going to have a bug
	mov ah, 00h
	int 16h
	ret 

back_space_function:
	pusha
	dec bh
	int 10h
	mov si, space ; hmmm hex has terminatation symbol which does not look good when it prints out...
	call display_string
	dec bh
	int 10h
	popa
	ret

mov_cursor:
	pusha
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0B	;y
	mov dl, 0x0D	;x
	int 10h
	popa
	ret

 mov_cursor2:
	pusha
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0D
	mov dl, 0x0B
	int 10h
	popa
	ret

mov_cursor_top_left:
	pusha
	mov ah, 2
	mov bh, 0
	mov dh, 0
	mov dl, 0
	int 10h
	popa
	ret

mov_cursor_new:
	pusha
	mov ah, 4
	mov bh, 0
	mov dh, 0
	mov dl, 0
	int 10h
	popa
	ret


sector2: ; welcome screen
	
	call clear_screen_black
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0B	;y
	mov dl, 0x0D	;x
	int 10h
	mov si, welcome
	mov bl, 0x50
	call display_color_string


	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0D
	mov dl, 0x0B
	int 10h
	mov si, press
	call display_string

 	call get_a_char

 	call clear_screen_black

login_phase: ;user login
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0B	;y
	mov dl, 0x06	;x
	int 10h
	mov si, login
	mov bl, 0x50
	call display_color_string


ready:
	lea bx, [password]
	mov cx, 0

input_loop:

	call get_a_char

	cmp al, 0Dh
	je input_done

back_space:
	cmp al, 08h
	jne skip
	cmp cx, 0
	jle input_loop ; do nothing

	call back_space_function
	dec cx
	jmp input_loop

skip:
	stosb ; store al in di and inc di
	inc cx ; for count

	pusha
	mov si, ast
	mov bl, 0x40
	call display_color_string
	popa
	
	jmp input_loop

input_done:
	sub di, cx

verify_size:
	cmp cx, 3
	jne error

verify_character:
	cmp cx, 0
	je valid

 	mov dl, [bx]
	mov al, [di]
	cmp al, dl
	jne error
	inc bx
	inc di
	dec cx

	jmp verify_character

error:
	call clear_screen_black

	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0C	;y
	mov dl, 0x06	;x
	int 10h
	mov bl, 0x30
	mov si, incorrect
	call display_color_string
	jmp login_phase

valid:	
	mov ax, cs
	mov ds, ax
	mov ax, 0x7F00
	mov es, ax


	call clear_screen_black
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x03	;y
	mov dl, 0x02	;x
	int 10h
	mov si, login
	mov bl, 0x40
	mov si, correct
	call display_color_string

	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0C	;y
	mov dl, 0x06	;x
	int 10h
	mov bl, 0x30
	mov si, cont
	call display_string

	call get_a_char

	call clear_screen_black
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x06	;y
	mov dl, 0x00	;x
	int 10h

.read_next_sector:
	mov ah, 0x02 ; read sector function

	mov al, 0x01 ; sectors to read count
	mov ch, 0x00 ; cylinder
	mov cl, 0x03 ; sector number to read
	mov dh, 0x00 ; head number
	mov dl, 0x00
	int 0x13



	jnc success
	mov si, fail
	call display_string

	cli
	jmp .read_next_sector

success:
	lgdt [gdt_pointer]
	mov eax, cr0
	or eax,0x1
	mov cr0, eax
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	jmp _sector3

gdt_start:
	dq 0x0

gdt_code:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10011010b
	db 11001111b
	db 0x0
gdt_data:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0
gdt_end:

gdt_pointer:
	dw gdt_end - gdt_start
	dd gdt_start

disk:
	db 0x0
	CODE_SEG equ gdt_code - gdt_start
	DATA_SEG equ gdt_data - gdt_start


.data:

fail: db "ERROR", 0
password: db "csc", 0
welcome:	db "Welcome to My OS",0   ; Our actual message to print
press:	db "<<< Press any key >>>", 0
login:	db "Password: ", 0
incorrect: db "Wrong password...", 0

ast: db '*', 0
space: db ' ', 0

times 1020 - ($-$$) db 0


bits 32
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_sector3:
;bits 32
;.data:
;message: db "Register = %08X", 10, 0

;section .text
;global caliculate
;extern printf

caliculate:
	;mov eax, 0xDEADBEEF
	;push eax
	;push message
	;call printf
	;add esp, 8

print_primes:
	mov bl, 0x30
	mov si, prime
	call display_color_string
	
	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x0D	;y
	mov dl, 0x13	;x
	int 10h
;d


times 1530 - ($-$$) db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
next_sector:
	mov ah, 0x02 ; read sector function

	mov al, 0x01 ; sectors to read count
	mov ch, 0x00 ; cylinder
	mov cl, 0x04 ; sector number to read
	mov dh, 0x00 ; head number
	mov dl, 0x00
	int 0x13

	jnc _sector4
	mov si, fail
	call display_string
	
	jmp next_sector


_sector4:
	mov bl, 0x40
	mov si, end
	call display_color_string

	mov ah, 0x02
	mov bh, 0x00
	mov dh, 0x12	;y
	mov dl, 0x06	;x
	int 10h

	mov bl, 0x40
	mov si, terminate
	call display_color_string

	call get_a_char
	call clear_screen_black



resetdisk:
	mov ah, 0x00  ; reset function
	mov dl, 0x00  ; drive
	int 0x13   ; disk int
	jc resetdisk

	xor ax, ax
	mov ax, 0x7E00;read a sector into 0x7E00:0
	mov es, ax
	xor bx, bx
	
.read_disk:
	mov ah, 0x02

	mov al, 0x04	;num of sectors to read
	mov ch,	0x00	;a track number, low eight bits of cylinder num? Cylinder is a group of track with a same radious
					;must be 0 here
	mov cl, 0x02	;sector number to read...sector number bits 0 -5, 6-7 are hard dosl only
	mov dh,	0x00	;head number
	mov dl, 0x00	;drive number (bit 7 set for hard disk)
	

	int 0x13

	jmp sector2
cli
hlt

cont:	db "Press any key to continue...", 0
correct db "You successfully logged in!!!", 0
prime db "2, 3, 5, 7, 11, 13, 17, 19, 23, 27, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71", 0
end: db "END", 0

terminate:	db "Press any key to terminate...", 0

times 2040 - ($-$$) db 0
bits 16
org 0x7C00

boot:
	xor ax, ax
	mov ds, ax
	mov es, ax

.reset:
	mov ah, 0	;reset function
	int 0x13	;call bios
	jc 	.reset	;check carry flag is whether set or not

;int 0x13, ah 02h - reading sectors into memory

	xor ax, ax
	mov ax, 0x7E00;read a sector into 0x7E00:0
	mov es, ax
	xor bx, bx
.read_disk:
	mov ah, 0x02

	mov al, 0x05	;num of sectors to read
	mov ch,	0x00	;a track number, low eight bits of cylinder num? Cylinder is a group of track with a same radious
					;must be 0 here
	mov cl, 0x02	;sector number to read...sector number bits 0 -5, 6-7 are hard dosl only
	mov dh,	0x00	;head number
	mov dl, 0x00	;drive number (bit 7 set for hard disk)
	

	int 0x13
	
	jnc success
	mov si, fail
	call print

	jmp .read_disk

print:
	pusha

	lodsb
	or al, al	;terminate?
	jz print_done
	mov ah, 0x0E
	int 0x10
	jmp print

print_done:
	popa
	ret

fail: db "ERROR", 0
back: db "Come Back.", 0
success:
	jmp 0x7E00:0x00


times 510 - ($-$$) db 0
dw	0xAA55

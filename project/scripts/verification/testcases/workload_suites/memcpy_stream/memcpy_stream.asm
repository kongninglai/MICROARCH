; memcpy_stream
;
; Dominant behavior modeled:
;   libc/file-buffer style streaming copy followed by a checksum pass.
;
; Memory layout:
;   DS 0x0200: source at offset 0x000, checksum result at offset 0x040
;   ES 0x0400: destination at offset 0x080
;   SS 0x0b00: stack starts at offset 0x100
;
; Expected final result:
;   DS:[0x040] = 0x30b90e21

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000

cld
mov esi, 0x00000000
mov edi, 0x00000080
mov ecx, 0x00000010
call memcpy64_stream

mov esi, 0x00000080
mov ecx, 0x00000010
mov eax, 0x00000000
call checksum_es_dwords
mov [ebx + 0x40], eax
hlt

memcpy64_stream:
push esi
push edi
rep movsd
pop edi
pop esi
ret

checksum_es_dwords:
push esi
push ecx
.checksum_loop:
add eax, es:[esi]
add esi, 0x04
add ecx, -1
jne .checksum_loop
pop ecx
pop esi
ret

; long_stream_verify
;
; Longer stream workload:
;   1. copy 256 bytes from DS:[0x000] to ES:[0x100]
;   2. checksum the copied ES buffer
;   3. verify the copy with REPE CMPSD
;
; Expected:
;   DS:[0x110] = 0x00000820  ; sum of dwords 1..64
;   DS:[0x114] = 0x00000000  ; compare matched

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
mov edi, 0x00000100
mov ecx, 0x00000040
call copy_dwords

mov esi, 0x00000100
mov ecx, 0x00000040
mov eax, 0x00000000
call checksum_es
mov [ebx + 0x110], eax

mov esi, 0x00000000
mov edi, 0x00000100
mov ecx, 0x00000040
call compare_dwords
mov [ebx + 0x114], eax
hlt

copy_dwords:
rep movsd
ret

checksum_es:
add eax, es:[esi]
add esi, 0x04
add ecx, -1
jne checksum_es
ret

compare_dwords:
repe cmpsd
mov eax, 0x00000000
jne .mismatch
ret
.mismatch:
mov eax, 0x00000001
ret

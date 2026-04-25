; histogram_count
;
; Counts zero-valued dword records in a small event stream.
; Expected: DS:[0x40] = 5

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
mov ecx, 0x00000010
mov edx, 0x00000000
call count_zero_dwords
mov [ebx + 0x40], edx
hlt

count_zero_dwords:
mov eax, [esi]
add eax, 0x00000000
jne .not_zero
add edx, 0x01
.not_zero:
add esi, 0x04
add ecx, -1
jne count_zero_dwords
ret

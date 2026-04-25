; binary_search
;
; Binary search for key 19 in a sorted 16-dword table.
; Expected: DS:[0x40] = 9

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000000
cld

mov edx, 0x00000000
mov ecx, 0x0000000f
mov edi, 0x00000013
mov eax, 0xffffffff
call binary_search_16
mov [ebx + 0x40], eax
hlt

binary_search_16:
mov esi, edx
add esi, ecx
sar esi, 1
mov ebp, esi
sal ebp, 2
mov ebp, [ebx + ebp + 0x00]
add ebp, 0x00
sbb ebp, edi
jne .not_equal
mov eax, esi
ret
.not_equal:
jnbe .greater
mov edx, esi
add edx, 1
jmp binary_search_16
.greater:
mov ecx, esi
add ecx, -1
jmp binary_search_16

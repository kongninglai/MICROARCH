; page_stride_probe
;
; Strided loads near the end of the mapped DS page using SIB addressing.
; Expected: DS:[0x40] = 10

mov edx, 0x00000200
mov ds, dx
mov edx, 0x00000400
mov es, dx
mov edx, 0x00000b00
mov ss, dx
mov esp, 0x00000100
mov ebx, 0x00000f00
cld

mov esi, 0x00000000
mov ecx, 0x00000004
mov eax, 0x00000000
call stride_sum
mov [ebx - 0x0ec0], eax
hlt

stride_sum:
add eax, [ebx + esi * 4 + 0x00]
add esi, 0x04
add ecx, -1
jne stride_sum
ret
